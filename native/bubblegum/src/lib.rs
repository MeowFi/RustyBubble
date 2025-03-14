use rustler::{Encoder, Env, NifStruct, Term};
use mpl_bubblegum::{
    instructions::{
        CreateTreeConfigBuilder, MintToCollectionV1Builder, TransferBuilder,
    },
    types::{MetadataArgs, TokenProgramVersion, TokenStandard, Creator, Collection, Uses, UseMethod},
};
use solana_sdk::{
    commitment_config::CommitmentConfig,
    instruction::Instruction,
    pubkey::Pubkey,
    signature::{Keypair, Signature},
    signer::Signer,
    transaction::Transaction,
};
use solana_client::rpc_client::RpcClient;
use std::str::FromStr;
use thiserror::Error;

mod atoms {
    rustler::atoms! {
        ok,
        error
    }
}

#[derive(Debug, Error)]
pub enum BubblegumError {
    #[error("Invalid public key: {0}")]
    InvalidPublicKey(String),
    
    #[error("Invalid keypair: {0}")]
    InvalidKeypair(String),
    
    #[error("Solana client error: {0}")]
    SolanaClientError(String),
    
    #[error("Transaction error: {0}")]
    TransactionError(String),
    
    #[error("Serialization error: {0}")]
    SerializationError(String),
}

#[derive(NifStruct)]
#[module = "SolanaBubblegum.Types.TreeConfig"]
pub struct TreeConfig {
    pub max_depth: u32,
    pub max_buffer_size: u32,
    pub public: bool,
}

#[derive(NifStruct)]
#[module = "SolanaBubblegum.Types.Creator"]
pub struct CreatorNif {
    pub address: String,
    pub verified: bool,
    pub share: u8,
}

#[derive(NifStruct)]
#[module = "SolanaBubblegum.Types.MetadataArgs"]
pub struct MetadataArgsNif {
    pub name: String,
    pub symbol: String,
    pub uri: String,
    pub seller_fee_basis_points: u16,
    pub primary_sale_happened: bool,
    pub is_mutable: bool,
    pub edition_nonce: Option<u8>,
    pub creators: Vec<CreatorNif>,
    pub collection: Option<String>,
    pub uses: Option<u64>,
}

fn parse_pubkey(pubkey_str: &str) -> Result<Pubkey, BubblegumError> {
    Pubkey::from_str(pubkey_str).map_err(|e| BubblegumError::InvalidPublicKey(e.to_string()))
}

fn parse_keypair(keypair_bytes: &[u8]) -> Result<Keypair, BubblegumError> {
    let keypair = Keypair::from_bytes(keypair_bytes)
        .map_err(|e| BubblegumError::InvalidKeypair(e.to_string()))?;
    Ok(keypair)
}

fn convert_metadata_args(args: &MetadataArgsNif) -> Result<MetadataArgs, BubblegumError> {
    let creators = args.creators.iter().map(|c| {
        Creator {
            address: parse_pubkey(&c.address).unwrap(),
            verified: c.verified,
            share: c.share,
        }
    }).collect();
    
    let collection = if let Some(collection_str) = &args.collection {
        Some(Collection {
            key: parse_pubkey(collection_str).unwrap(),
            verified: false, // Will be verified by the program
        })
    } else {
        None
    };
    
    Ok(MetadataArgs {
        name: args.name.clone(),
        symbol: args.symbol.clone(),
        uri: args.uri.clone(),
        seller_fee_basis_points: args.seller_fee_basis_points,
        primary_sale_happened: args.primary_sale_happened,
        is_mutable: args.is_mutable,
        edition_nonce: args.edition_nonce,
        creators,
        collection,
        uses: args.uses.map(|uses| Uses {
            use_method: UseMethod::Multiple,
            remaining: uses,
            total: uses,
        }),
        token_program_version: TokenProgramVersion::Original,
        token_standard: Some(TokenStandard::NonFungible),
    })
}

fn send_transaction(
    client: &RpcClient,
    instructions: Vec<Instruction>,
    payer: &Keypair,
    signers: Vec<&Keypair>,
) -> Result<Signature, BubblegumError> {
    let recent_blockhash = client
        .get_latest_blockhash()
        .map_err(|e| BubblegumError::SolanaClientError(e.to_string()))?;
    
    let mut transaction = Transaction::new_with_payer(&instructions, Some(&payer.pubkey()));
    
    let mut all_signers = vec![payer];
    all_signers.extend(signers);
    
    transaction.sign(&all_signers, recent_blockhash);
    
    client
        .send_and_confirm_transaction_with_spinner(&transaction)
        .map_err(|e| BubblegumError::TransactionError(e.to_string()))
}

#[rustler::nif]
fn create_tree_config(
    env: Env,
    args: (String, u32, u32, u32, bool, String),
) -> Term {
    let (payer_keypair_bs58, max_depth, max_buffer_size, _canopy_depth, public, rpc_url) = args;
    
    // Decode the payer keypair
    let payer_bytes = match bs58::decode(payer_keypair_bs58).into_vec() {
        Ok(bytes) => bytes,
        Err(e) => return (atoms::error(), format!("Invalid bs58 encoding: {}", e)).encode(env),
    };
    
    let payer = match parse_keypair(&payer_bytes) {
        Ok(keypair) => keypair,
        Err(e) => return (atoms::error(), e.to_string()).encode(env),
    };
    
    // Create a new keypair for the tree
    let tree_keypair = Keypair::new();
    let tree_pubkey = tree_keypair.pubkey();
    
    // Connect to Solana
    let client = RpcClient::new_with_commitment(rpc_url, CommitmentConfig::confirmed());
    
    // Create the tree config instruction
    let create_tree_ix = CreateTreeConfigBuilder::new()
        .payer(payer.pubkey())
        .merkle_tree(tree_pubkey)
        .tree_creator(payer.pubkey())
        .max_depth(max_depth)
        .max_buffer_size(max_buffer_size)
        .public(public)
        .instruction();
    
    // Send the transaction
    match send_transaction(&client, vec![create_tree_ix], &payer, vec![&tree_keypair]) {
        Ok(signature) => {
            let tree_pubkey_str = tree_pubkey.to_string();
            let signature_str = signature.to_string();
            
            let result = Term::map_new(env);
            let ok_map = Term::map_new(env);
            
            let ok_map = ok_map.map_put("tree_pubkey".encode(env), tree_pubkey_str.encode(env)).unwrap();
            let ok_map = ok_map.map_put("signature".encode(env), signature_str.encode(env)).unwrap();
            
            result.map_put(atoms::ok().encode(env), ok_map).unwrap()
        },
        Err(e) => {
            let result = Term::map_new(env);
            let error_term = e.to_string().encode(env);
            result.map_put(atoms::error().encode(env), error_term).unwrap()
        },
    }
}

#[rustler::nif]
fn mint_to_collection_v1(
    env: Env,
    args: (String, String, String, MetadataArgsNif, String),
) -> Term {
    let (payer_keypair_bs58, tree_pubkey_str, collection_pubkey_str, metadata_args, rpc_url) = args;
    
    // Decode the payer keypair
    let payer_bytes = match bs58::decode(payer_keypair_bs58).into_vec() {
        Ok(bytes) => bytes,
        Err(e) => return (atoms::error(), format!("Invalid bs58 encoding: {}", e)).encode(env),
    };
    
    let payer = match parse_keypair(&payer_bytes) {
        Ok(keypair) => keypair,
        Err(e) => return (atoms::error(), e.to_string()).encode(env),
    };
    
    // Parse the tree and collection pubkeys
    let tree_pubkey = match parse_pubkey(&tree_pubkey_str) {
        Ok(pubkey) => pubkey,
        Err(e) => return (atoms::error(), e.to_string()).encode(env),
    };
    
    let collection_pubkey = match parse_pubkey(&collection_pubkey_str) {
        Ok(pubkey) => pubkey,
        Err(e) => return (atoms::error(), e.to_string()).encode(env),
    };
    
    // Convert the metadata args
    let metadata = match convert_metadata_args(&metadata_args) {
        Ok(metadata) => metadata,
        Err(e) => return (atoms::error(), e.to_string()).encode(env),
    };
    
    // Connect to Solana
    let client = RpcClient::new_with_commitment(rpc_url, CommitmentConfig::confirmed());
    
    // Create the mint instruction
    let mint_ix = MintToCollectionV1Builder::new()
        .payer(payer.pubkey())
        .merkle_tree(tree_pubkey)
        .tree_creator_or_delegate(payer.pubkey())
        .collection_mint(collection_pubkey)
        .collection_authority(payer.pubkey())
        .metadata(metadata)
        .instruction();
    
    // Send the transaction
    match send_transaction(&client, vec![mint_ix], &payer, vec![]) {
        Ok(signature) => {
            let signature_str = signature.to_string();
            
            let result = Term::map_new(env);
            let ok_map = Term::map_new(env);
            
            let ok_map = ok_map.map_put("signature".encode(env), signature_str.encode(env)).unwrap();
            
            result.map_put(atoms::ok().encode(env), ok_map).unwrap()
        },
        Err(e) => {
            let result = Term::map_new(env);
            let error_term = e.to_string().encode(env);
            result.map_put(atoms::error().encode(env), error_term).unwrap()
        },
    }
}

#[rustler::nif]
fn transfer(
    env: Env,
    args: (String, String, String, String, String, String),
) -> Term {
    let (payer_keypair_bs58, tree_pubkey_str, leaf_owner_str, new_owner_str, asset_id_str, rpc_url) = args;
    
    // Decode the payer keypair
    let payer_bytes = match bs58::decode(payer_keypair_bs58).into_vec() {
        Ok(bytes) => bytes,
        Err(e) => return (atoms::error(), format!("Invalid bs58 encoding: {}", e)).encode(env),
    };
    
    let payer = match parse_keypair(&payer_bytes) {
        Ok(keypair) => keypair,
        Err(e) => return (atoms::error(), e.to_string()).encode(env),
    };
    
    // Parse the pubkeys
    let tree_pubkey = match parse_pubkey(&tree_pubkey_str) {
        Ok(pubkey) => pubkey,
        Err(e) => return (atoms::error(), e.to_string()).encode(env),
    };
    
    let leaf_owner = match parse_pubkey(&leaf_owner_str) {
        Ok(pubkey) => pubkey,
        Err(e) => return (atoms::error(), e.to_string()).encode(env),
    };
    
    let new_owner = match parse_pubkey(&new_owner_str) {
        Ok(pubkey) => pubkey,
        Err(e) => return (atoms::error(), e.to_string()).encode(env),
    };
    
    let _asset_id = match parse_pubkey(&asset_id_str) {
        Ok(pubkey) => pubkey,
        Err(e) => return (atoms::error(), e.to_string()).encode(env),
    };
    
    // Connect to Solana
    let client = RpcClient::new_with_commitment(rpc_url, CommitmentConfig::confirmed());
    
    // Create the transfer instruction
    let transfer_ix = TransferBuilder::new()
        .merkle_tree(tree_pubkey)
        .leaf_owner(leaf_owner, false)
        .new_leaf_owner(new_owner)
        .instruction();
    
    // Send the transaction
    match send_transaction(&client, vec![transfer_ix], &payer, vec![]) {
        Ok(signature) => {
            let signature_str = signature.to_string();
            
            let result = Term::map_new(env);
            let ok_map = Term::map_new(env);
            
            let ok_map = ok_map.map_put("signature".encode(env), signature_str.encode(env)).unwrap();
            
            result.map_put(atoms::ok().encode(env), ok_map).unwrap()
        },
        Err(e) => {
            let result = Term::map_new(env);
            let error_term = e.to_string().encode(env);
            result.map_put(atoms::error().encode(env), error_term).unwrap()
        },
    }
}

rustler::init!("Elixir.SolanaBubblegum.Bubblegum", [
    create_tree_config,
    mint_to_collection_v1,
    transfer
]);
