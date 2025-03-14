defmodule SolanaBubblegum.Bubblegum do
  @moduledoc """
  Native implementation of the Metaplex Bubblegum compressed NFT operations.
  This module provides direct access to the Rust NIF functions.
  """

  use Rustler, otp_app: :solana_bubblegum, crate: "bubblegum"

  alias SolanaBubblegum.Types.MetadataArgs

  # NIF functions
  @doc """
  Creates a new Merkle tree configuration for compressed NFTs.

  ## Parameters
  - payer_keypair_bs58: Base58 encoded keypair of the payer
  - max_depth: Maximum depth of the Merkle tree
  - max_buffer_size: Maximum buffer size for the Merkle tree
  - canopy_depth: Depth of the canopy
  - public: Whether the tree is public
  - rpc_url: URL of the Solana RPC endpoint

  ## Returns
  - `{:ok, %{tree_pubkey: String.t(), signature: String.t()}}` on success
  - `{:error, reason}` on failure
  """
  @spec create_tree_config(
          {String.t(), non_neg_integer(), non_neg_integer(), non_neg_integer(), boolean(), String.t()}
        ) :: {:ok, map()} | {:error, String.t()}
  def create_tree_config(_args),
    do: :erlang.nif_error(:nif_not_loaded)

  @doc """
  Wrapper function for create_tree_config that takes individual arguments.
  """
  @spec create_tree_config(
          _payer_keypair_bs58 :: String.t(),
          _max_depth :: non_neg_integer(),
          _max_buffer_size :: non_neg_integer(),
          _canopy_depth :: non_neg_integer(),
          _public :: boolean(),
          _rpc_url :: String.t()
        ) :: {:ok, map()} | {:error, String.t()}
  def create_tree_config(payer_keypair_bs58, max_depth, max_buffer_size, canopy_depth, public, rpc_url) do
    create_tree_config({payer_keypair_bs58, max_depth, max_buffer_size, canopy_depth, public, rpc_url})
  end

  @doc """
  Mints a new compressed NFT to a collection.

  ## Parameters
  - payer_keypair_bs58: Base58 encoded keypair of the payer
  - tree_pubkey: Public key of the Merkle tree
  - collection_pubkey: Public key of the collection
  - metadata_args: Metadata for the NFT
  - rpc_url: URL of the Solana RPC endpoint

  ## Returns
  - `{:ok, %{signature: String.t()}}` on success
  - `{:error, reason}` on failure
  """
  @spec mint_to_collection_v1(
          {String.t(), String.t(), String.t(), MetadataArgs.t(), String.t()}
        ) :: {:ok, map()} | {:error, String.t()}
  def mint_to_collection_v1(_args),
    do: :erlang.nif_error(:nif_not_loaded)

  @doc """
  Wrapper function for mint_to_collection_v1 that takes individual arguments.
  """
  @spec mint_to_collection_v1(
          _payer_keypair_bs58 :: String.t(),
          _tree_pubkey :: String.t(),
          _collection_pubkey :: String.t(),
          _metadata_args :: MetadataArgs.t(),
          _rpc_url :: String.t()
        ) :: {:ok, map()} | {:error, String.t()}
  def mint_to_collection_v1(payer_keypair_bs58, tree_pubkey, collection_pubkey, metadata_args, rpc_url) do
    mint_to_collection_v1({payer_keypair_bs58, tree_pubkey, collection_pubkey, metadata_args, rpc_url})
  end

  @doc """
  Transfers a compressed NFT to a new owner.

  ## Parameters
  - payer_keypair_bs58: Base58 encoded keypair of the payer
  - tree_pubkey: Public key of the Merkle tree
  - leaf_owner: Public key of the current owner
  - new_owner: Public key of the new owner
  - asset_id: Asset ID of the NFT
  - rpc_url: URL of the Solana RPC endpoint

  ## Returns
  - `{:ok, %{signature: String.t()}}` on success
  - `{:error, reason}` on failure
  """
  @spec transfer(
          {String.t(), String.t(), String.t(), String.t(), String.t(), String.t()}
        ) :: {:ok, map()} | {:error, String.t()}
  def transfer(_args),
    do: :erlang.nif_error(:nif_not_loaded)

  @doc """
  Wrapper function for transfer that takes individual arguments.
  """
  @spec transfer(
          _payer_keypair_bs58 :: String.t(),
          _tree_pubkey :: String.t(),
          _leaf_owner :: String.t(),
          _new_owner :: String.t(),
          _asset_id :: String.t(),
          _rpc_url :: String.t()
        ) :: {:ok, map()} | {:error, String.t()}
  def transfer(payer_keypair_bs58, tree_pubkey, leaf_owner, new_owner, asset_id, rpc_url) do
    transfer({payer_keypair_bs58, tree_pubkey, leaf_owner, new_owner, asset_id, rpc_url})
  end
end
