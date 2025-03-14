defmodule SolanaBubblegum.Types do
  @moduledoc """
  Type definitions for the SolanaBubblegum library.
  """

  defmodule TreeConfig do
    @moduledoc """
    Configuration for a Merkle tree used in compressed NFTs.
    """
    defstruct [:max_depth, :max_buffer_size, :public]

    @type t :: %__MODULE__{
      max_depth: non_neg_integer(),
      max_buffer_size: non_neg_integer(),
      public: boolean()
    }
  end

  defmodule Creator do
    @moduledoc """
    Creator information for an NFT.
    """
    defstruct [:address, :verified, :share]

    @type t :: %__MODULE__{
      address: String.t(),
      verified: boolean(),
      share: non_neg_integer()
    }
  end

  defmodule MetadataArgs do
    @moduledoc """
    Metadata arguments for an NFT.
    """
    defstruct [
      :name,
      :symbol,
      :uri,
      :seller_fee_basis_points,
      :primary_sale_happened,
      :is_mutable,
      :edition_nonce,
      :creators,
      :collection,
      :uses
    ]

    @type t :: %__MODULE__{
      name: String.t(),
      symbol: String.t(),
      uri: String.t(),
      seller_fee_basis_points: non_neg_integer(),
      primary_sale_happened: boolean(),
      is_mutable: boolean(),
      edition_nonce: non_neg_integer() | nil,
      creators: [Creator.t()],
      collection: String.t() | nil,
      uses: non_neg_integer() | nil
    }
  end
end
