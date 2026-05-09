defmodule Ratex.Options do
  @moduledoc """
  This struct is used to encapsulate all of the rendering options that the Ratex
  library supports. This struct is serialized via Rustler and passed directly
  to the NIF library.
  """

  @type t :: %__MODULE__{
          font_size: float(),
          pixel_ratio: float() | nil,
          color: String.t(),
          inline: boolean(),
          unicode_font_path: String.t() | nil
        }

  @keys [
    :font_size,
    :pixel_ratio,
    :color,
    :inline,
    :unicode_font_path
  ]

  @enforce_keys @keys
  defstruct @keys

  @doc """
  Create a new options struct from a list/map.
  """
  def new(opts) do
    struct(__MODULE__, opts)
  end
end
