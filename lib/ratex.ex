defmodule Ratex do
  @moduledoc """
  This library provides an Elixir wrapper around the Rust
  [RaTeX](https://github.com/erweixin/RaTeX) library. This allows you
  render SVGs and PNGs of mathematical expressions right in Elixir.
  """

  alias Ratex.Error
  alias Ratex.Native
  alias Ratex.Options

  @all_opts [
    font_size: [
      doc: "The base font size in pixels.",
      type: :float,
      default: 32.0
    ],
    pixel_ratio: [
      doc: "The device pixel ratio for retina rasters.",
      type: :float,
      default: 2.0
    ],
    color: [
      doc: "The color of the glpyhs as hexadecimal (e.g. `#112233`).",
      type: :string,
      default: "#000000"
    ],
    inline: [
      doc: "Render the expression as inline text as opposed to display.",
      type: :boolean,
      default: false
    ],
    unicode_font_path: [
      doc:
        "The absolute path to a TTF font file for non-ASCII text that may be used inside of an `\\\\text{...}` expression. If a font path is not provided the underlying RaTeX Rust library will attempt to use the platform fallback.",
      type: :string
    ]
  ]

  @png_opts @all_opts
  @svg_opts Keyword.delete(@all_opts, :pixel_ratio)

  @type png_opts() :: unquote(NimbleOptions.option_typespec(@png_opts))

  @type svg_opts() :: unquote(NimbleOptions.option_typespec(@svg_opts))

  @doc """
  Generate a PNG binary of a given LaTeX math expression.

  ## Options

    #{NimbleOptions.docs(@png_opts)}
  """
  @spec render_png(expression :: String.t(), opts :: png_opts()) :: {:ok, binary()} | {:error, term()}
  def render_png(expression, opts \\ []) do
    with {:ok, opts} <- validate_opts(opts, @png_opts) do
      Native.render_png(expression, Options.new(opts))
    end
  end

  @doc """
  Same as `render_png/2` but raises on error.
  """
  @spec render_png!(expression :: String.t(), opts :: png_opts()) :: binary()
  def render_png!(expression, opts \\ []) do
    case render_png(expression, opts) do
      {:ok, png} ->
        png

      {:error, reason} ->
        raise "Ratex render failed: #{inspect(reason)}"
    end
  end

  @doc """
  Generate an SVG of a given LaTeX math expression.

  ## Options

    #{NimbleOptions.docs(@svg_opts)}
  """
  @spec render_svg(expression :: String.t(), opts :: svg_opts()) :: {:ok, binary()} | {:error, term()}
  def render_svg(expression, opts \\ []) do
    with {:ok, opts} <- validate_opts(opts, @svg_opts) do
      Native.render_svg(expression, Options.new(opts))
    end
  end

  @doc """
  Same as `render_svg/2` but raises on failure.
  """
  @spec render_svg!(expression :: String.t(), opts :: svg_opts()) :: binary()
  def render_svg!(expression, opts \\ []) do
    case render_svg(expression, opts) do
      {:ok, svg} ->
        svg

      {:error, reason} ->
        raise "Ratex render failed: #{inspect(reason)}"
    end
  end

  defp validate_opts(opts, schema) do
    case NimbleOptions.validate(opts, schema) do
      {:ok, _validated_opts} = result ->
        result

      {:error, %NimbleOptions.ValidationError{} = error} ->
        message = Exception.message(error)
        {:error, Error.new(:option_error, message)}
    end
  end
end
