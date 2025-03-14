defmodule SolanaBubblegumTest do
  use ExUnit.Case
  doctest SolanaBubblegum

  alias SolanaBubblegum.Types.{MetadataArgs, Creator}

  test "create_tree_config returns error with invalid keypair" do
    result = SolanaBubblegum.create_tree_config("invalid_keypair", 14, 64, 10, true)
    assert match?({:error, _}, result)
  end

  test "mint_to_collection returns error with invalid keypair" do
    metadata = %MetadataArgs{
      name: "Test NFT",
      symbol: "TNFT",
      uri: "https://arweave.net/metadata.json",
      seller_fee_basis_points: 500,
      primary_sale_happened: false,
      is_mutable: true,
      edition_nonce: nil,
      creators: [
        %Creator{
          address: "Gh9ZwEmdLJ8DscKNTkTqPbNwLNNBjuSzaG9Vp2KGtKJr",
          verified: false,
          share: 100
        }
      ],
      collection: "Gh9ZwEmdLJ8DscKNTkTqPbNwLNNBjuSzaG9Vp2KGtKJr",
      uses: nil
    }

    result = SolanaBubblegum.mint_to_collection("invalid_keypair", "tree_pubkey", "collection_pubkey", metadata)
    assert match?({:error, _}, result)
  end

  test "transfer returns error with invalid keypair" do
    result = SolanaBubblegum.transfer(
      "invalid_keypair",
      "tree_pubkey",
      "leaf_owner",
      "new_owner",
      "asset_id"
    )
    assert match?({:error, _}, result)
  end
end
