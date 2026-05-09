defmodule Ratex.Error do
  @moduledoc """
  Structured error type for Ratex compiler errors.

  ## Error Types

    - `:option_error` - The provided options for a given function were malformed
  """

  @type error_type :: :option_error

  @type t :: %__MODULE__{
          type: error_type(),
          message: String.t()
        }

  defexception [:type, :message]

  @doc false
  def new(type, message) do
    %__MODULE__{type: type, message: message}
  end

  @impl true
  def message(%__MODULE__{message: message}) do
    message
  end
end
