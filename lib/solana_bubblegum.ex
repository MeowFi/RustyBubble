defmodule SolanaBubblegum do
  @moduledoc """
  SolanaBubblegum provides an Elixir interface to the Metaplex mpl-bubblegum Rust crate,
  enabling Elixir developers to construct and send compressed NFT transactions on Solana.

  This library bridges the Metaplex mpl-bubblegum Rust crate to Elixir using Rustler,
  allowing Elixir applications to interact with compressed NFTs on the Solana blockchain.
  """

  alias SolanaBubblegum.{Bubblegum, Types}
  alias Types.MetadataArgs

  @default_rpc_url "https://api.devnet.solana.com"

  @doc """
  Creates a new Merkle tree configuration for compressed NFTs.

  ## Parameters

  * `payer_keypair_bs58` - Base58 encoded keypair of the payer
  * `max_depth` - Maximum depth of the Merkle tree
  * `max_buffer_size` - Maximum buffer size for the Merkle tree
  * `canopy_depth` - Canopy depth for the Merkle tree
  * `public` - Whether the tree is public or not
  * `options` - Optional keyword list with additional parameters:
    * `:rpc_url` - URL of the Solana RPC endpoint (defaults to Devnet)

  ## Returns

  * `{:ok, %{tree_pubkey: String.t(), signature: String.t()}}` - On success
  * `{:error, reason}` - On failure

  ## Examples

      # Example with a valid keypair
      iex> {:error, _reason} = SolanaBubblegum.create_tree_config(
      ...>   "4Xkh4QFN7eX7crQNpbPsKdVmSGCgvwoMQZi3J6QBfvZJM9L5jcUNTZ5cEFcXa9U5L87Csc3KQZqXaBgEn6YmYVhW",
      ...>   14,
      ...>   64,
      ...>   10,
      ...>   true
      ...> )

  """
  @spec create_tree_config(
          payer_keypair_bs58 :: String.t(),
          max_depth :: non_neg_integer(),
          max_buffer_size :: non_neg_integer(),
          canopy_depth :: non_neg_integer(),
          public :: boolean(),
          options :: keyword()
        ) :: {:ok, map()} | {:error, String.t()}
  def create_tree_config(payer_keypair_bs58, max_depth, max_buffer_size, canopy_depth, public, options \\ []) do
    rpc_url = Keyword.get(options, :rpc_url, @default_rpc_url)
    
    case Bubblegum.create_tree_config(
           payer_keypair_bs58,
           max_depth,
           max_buffer_size,
           canopy_depth,
           public,
           rpc_url
         ) do
      {:error, reason} -> {:error, reason}
      result -> parse_json_result(result)
    end
  end

  @doc """
  Mints a new compressed NFT to a collection.

  ## Parameters

  * `payer_keypair_bs58` - Base58 encoded keypair of the payer
  * `tree_pubkey` - Public key of the Merkle tree
  * `collection_pubkey` - Public key of the collection
  * `metadata_args` - Metadata for the NFT
  * `options` - Optional keyword list with additional parameters:
    * `:rpc_url` - URL of the Solana RPC endpoint (defaults to Devnet)

  ## Returns

  * `{:ok, %{signature: String.t()}}` - On success
  * `{:error, reason}` - On failure

  ## Examples

      # Example with a valid keypair and metadata
      iex> metadata = %SolanaBubblegum.Types.MetadataArgs{
      ...>   name: "My NFT",
      ...>   symbol: "MNFT",
      ...>   uri: "https://arweave.net/metadata.json",
      ...>   seller_fee_basis_points: 500,
      ...>   primary_sale_happened: false,
      ...>   is_mutable: true,
      ...>   edition_nonce: nil,
      ...>   creators: [
      ...>     %SolanaBubblegum.Types.Creator{
      ...>       address: "Gh9ZwEmdLJ8DscKNTkTqPbNwLNNBjuSzaG9Vp2KGtKJr",
      ...>       verified: false,
      ...>       share: 100
      ...>     }
      ...>   ],
      ...>   collection: "Gh9ZwEmdLJ8DscKNTkTqPbNwLNNBjuSzaG9Vp2KGtKJr",
      ...>   uses: nil
      ...> }
      iex> {:error, _reason} = SolanaBubblegum.mint_to_collection(
      ...>   "4Xkh4QFN7eX7crQNpbPsKdVmSGCgvwoMQZi3J6QBfvZJM9L5jcUNTZ5cEFcXa9U5L87Csc3KQZqXaBgEn6YmYVhW",
      ...>   "Gh9ZwEmdLJ8DscKNTkTqPbNwLNNBjuSzaG9Vp2KGtKJr",
      ...>   "Gh9ZwEmdLJ8DscKNTkTqPbNwLNNBjuSzaG9Vp2KGtKJr",
      ...>   metadata
      ...> )

  """
  @spec mint_to_collection(
          payer_keypair_bs58 :: String.t(),
          tree_pubkey :: String.t(),
          collection_pubkey :: String.t(),
          metadata_args :: MetadataArgs.t(),
          options :: keyword()
        ) :: {:ok, map()} | {:error, String.t()}
  def mint_to_collection(payer_keypair_bs58, tree_pubkey, collection_pubkey, metadata_args, options \\ []) do
    rpc_url = Keyword.get(options, :rpc_url, @default_rpc_url)
    
    case Bubblegum.mint_to_collection_v1(
           payer_keypair_bs58,
           tree_pubkey,
           collection_pubkey,
           metadata_args,
           rpc_url
         ) do
      {:error, reason} -> {:error, reason}
      result -> parse_json_result(result)
    end
  end

  @doc """
  Transfers a compressed NFT to a new owner.

  ## Parameters

  * `payer_keypair_bs58` - Base58 encoded keypair of the payer
  * `tree_pubkey` - Public key of the Merkle tree
  * `leaf_owner` - Public key of the current owner
  * `new_owner` - Public key of the new owner
  * `asset_id` - Asset ID of the NFT
  * `options` - Optional keyword list with additional parameters:
    * `:rpc_url` - URL of the Solana RPC endpoint (defaults to Devnet)

  ## Returns

  * `{:ok, %{signature: String.t()}}` - On success
  * `{:error, reason}` - On failure

  ## Examples

      # Example with valid keypair and addresses
      iex> {:error, _reason} = SolanaBubblegum.transfer(
      ...>   "4Xkh4QFN7eX7crQNpbPsKdVmSGCgvwoMQZi3J6QBfvZJM9L5jcUNTZ5cEFcXa9U5L87Csc3KQZqXaBgEn6YmYVhW",
      ...>   "Gh9ZwEmdLJ8DscKNTkTqPbNwLNNBjuSzaG9Vp2KGtKJr",
      ...>   "Gh9ZwEmdLJ8DscKNTkTqPbNwLNNBjuSzaG9Vp2KGtKJr",
      ...>   "HXtBm8XZbxaTt41uqaKhwUAa6Z1aPyvJdsZVENiWsetg",
      ...>   "Gh9ZwEmdLJ8DscKNTkTqPbNwLNNBjuSzaG9Vp2KGtKJr"
      ...> )

  """
  @spec transfer(
          payer_keypair_bs58 :: String.t(),
          tree_pubkey :: String.t(),
          leaf_owner :: String.t(),
          new_owner :: String.t(),
          asset_id :: String.t(),
          options :: keyword()
        ) :: {:ok, map()} | {:error, String.t()}
  def transfer(payer_keypair_bs58, tree_pubkey, leaf_owner, new_owner, asset_id, options \\ []) do
    rpc_url = Keyword.get(options, :rpc_url, @default_rpc_url)
    
    case Bubblegum.transfer(
           payer_keypair_bs58,
           tree_pubkey,
           leaf_owner,
           new_owner,
           asset_id,
           rpc_url
         ) do
      {:error, reason} -> {:error, reason}
      result -> parse_json_result(result)
    end
  end

  # Helper function to parse JSON results from the NIF
  defp parse_json_result(json_string) do
    case Jason.decode(json_string) do
      {:ok, result} -> {:ok, atomize_keys(result)}
      {:error, _} -> {:error, "Failed to parse JSON result: #{json_string}"}
    end
  end

  # Helper function to convert string keys to atoms
  defp atomize_keys(map) when is_map(map) do
    Map.new(map, fn {k, v} -> {String.to_atom(k), v} end)
  end
end
