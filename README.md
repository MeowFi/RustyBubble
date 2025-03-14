# SolanaBubblegum

An Elixir bridge to the Metaplex mpl-bubblegum Rust crate, enabling Elixir developers to construct and send compressed NFT transactions on Solana.

## Features

- Direct integration with the mpl-bubblegum crate
- Implementation of three core bubblegum instructions:
  1. `create_tree_config` - Create a new Merkle tree for compressed NFTs
  2. `mint_to_collection_v1` - Mint a new compressed NFT to a collection
  3. `transfer` - Transfer a compressed NFT to a new owner
- Transaction signing and submission to Solana devnet
- Comprehensive error handling with structured error messages

## Installation

Add `solana_bubblegum` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:solana_bubblegum, "~> 0.1.0"}
  ]
end
```

## Usage

### Creating a Merkle Tree

```elixir
# Base58 encoded keypair of the payer
payer_keypair_bs58 = "4Xkh4QFN7eX7crQNpbPsKdVmSGCgvwoMQZi3J6QBfvZJM9L5jcUNTZ5cEFcXa9U5L87Csc3KQZqXaBgEn6YmYVhW"

# Create a new Merkle tree
{:ok, result} = SolanaBubblegum.create_tree_config(
  payer_keypair_bs58,
  14,                # max_depth
  64,                # max_buffer_size
  10,                # canopy_depth
  true               # public
)

# The result contains the tree's public key and the transaction signature
%{
  tree_pubkey: "Gh9ZwEmdLJ8DscKNTkTqPbNwLNNBjuSzaG9Vp2KGtKJr",
  signature: "5QoP1dXWVKvM5eFQGC75qe7GqwVE9aQfkWxUHDUyRiWXB4V9hLiLcSUJR7Z1nbxZUjSPsaJzWzn9EeVMBPTrFRrM"
}

# You can also specify a custom RPC URL
{:ok, result} = SolanaBubblegum.create_tree_config(
  payer_keypair_bs58,
  14,
  64,
  10,
  true,
  rpc_url: "https://api.mainnet-beta.solana.com"
)
```

### Minting a Compressed NFT to a Collection

```elixir
# Create metadata for the NFT
metadata = %SolanaBubblegum.Types.MetadataArgs{
  name: "My Compressed NFT",
  symbol: "CNFT",
  uri: "https://arweave.net/metadata.json",
  seller_fee_basis_points: 500,  # 5%
  primary_sale_happened: false,
  is_mutable: true,
  edition_nonce: nil,
  creators: [
    %SolanaBubblegum.Types.Creator{
      address: "Gh9ZwEmdLJ8DscKNTkTqPbNwLNNBjuSzaG9Vp2KGtKJr",  # Creator's public key
      verified: false,
      share: 100          # Percentage share of royalties
    }
  ],
  collection: "Gh9ZwEmdLJ8DscKNTkTqPbNwLNNBjuSzaG9Vp2KGtKJr",  # Collection's public key
  uses: nil
}

# Mint the NFT
{:ok, result} = SolanaBubblegum.mint_to_collection(
  payer_keypair_bs58,
  "Gh9ZwEmdLJ8DscKNTkTqPbNwLNNBjuSzaG9Vp2KGtKJr",  # Tree public key
  "Gh9ZwEmdLJ8DscKNTkTqPbNwLNNBjuSzaG9Vp2KGtKJr",  # Collection public key
  metadata
)

# The result contains the transaction signature
%{
  signature: "5QoP1dXWVKvM5eFQGC75qe7GqwVE9aQfkWxUHDUyRiWXB4V9hLiLcSUJR7Z1nbxZUjSPsaJzWzn9EeVMBPTrFRrM"
}
```

### Transferring a Compressed NFT

```elixir
{:ok, result} = SolanaBubblegum.transfer(
  payer_keypair_bs58,
  "Gh9ZwEmdLJ8DscKNTkTqPbNwLNNBjuSzaG9Vp2KGtKJr",  # Tree public key
  "Gh9ZwEmdLJ8DscKNTkTqPbNwLNNBjuSzaG9Vp2KGtKJr",  # Current owner's public key
  "HXtBm8XZbxaTt41uqaKhwUAa6Z1aPyvJdsZVENiWsetg",  # New owner's public key
  "Gh9ZwEmdLJ8DscKNTkTqPbNwLNNBjuSzaG9Vp2KGtKJr"   # Asset ID of the NFT
)

# The result contains the transaction signature
%{
  signature: "5QoP1dXWVKvM5eFQGC75qe7GqwVE9aQfkWxUHDUyRiWXB4V9hLiLcSUJR7Z1nbxZUjSPsaJzWzn9EeVMBPTrFRrM"
}
```

## Error Handling

All functions return either `{:ok, result}` or `{:error, reason}`. Error messages are propagated from the Rust layer and provide detailed information about what went wrong.

```elixir
# Example of error handling
case SolanaBubblegum.create_tree_config(invalid_keypair, 14, 64, 10, true) do
  {:ok, result} ->
    IO.puts("Tree created successfully!")
    IO.inspect(result)
  
  {:error, reason} ->
    IO.puts("Failed to create tree: #{reason}")
end
```

## Keypair Handling

This library expects keypairs to be provided in Base58 encoded format. You can convert a Solana keypair file to Base58 using the Solana CLI:

```bash
solana-keygen pubkey /path/to/keypair.json  # Get the public key
cat /path/to/keypair.json | base58          # Convert to Base58
```

## Architecture

SolanaBubblegum uses Rustler to bridge between Elixir and Rust. The architecture consists of:

1. **Elixir Interface Layer**: Provides a clean, idiomatic Elixir API
2. **Rustler NIFs**: Native Implemented Functions that call into the Rust code
3. **Rust Implementation**: Core logic that interacts with the mpl-bubblegum crate

The data flow is:
- Elixir function call → Rustler NIF → Rust implementation → mpl-bubblegum → Solana blockchain

## Development

### Prerequisites

- Elixir 1.14 or later
- Rust 1.70 or later
- Solana CLI tools

### Building

```bash
mix deps.get
mix compile
```

### Testing

```bash
mix test
```

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request
