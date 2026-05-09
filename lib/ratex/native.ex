defmodule Ratex.Native do
  @moduledoc false

  version = Mix.Project.config()[:version]

  use RustlerPrecompiled,
    otp_app: :ratex,
    crate: :ratex_nif,
    base_url: "https://github.com/akoutmos/ratex/releases/download/v#{version}",
    force_build: System.get_env("RUSTLER_FORCE_BUILD") in ["1", "true"],
    targets:
      Enum.uniq([
        "aarch64-apple-darwin",
        "aarch64-unknown-linux-gnu",
        "x86_64-apple-darwin",
        "x86_64-unknown-linux-gnu",
        "x86_64-pc-windows-msvc"
      ]),
    version: version

  @doc false
  def render_png(_expression, _opts), do: :erlang.nif_error(:nif_not_loaded)
  def render_svg(_expression, _opts), do: :erlang.nif_error(:nif_not_loaded)
end
