defmodule Ratex.MixProject do
  use Mix.Project

  def project do
    [
      app: :ratex,
      name: "Ratex",
      version: project_version(),
      elixir: "~> 1.16",
      start_permanent: Mix.env() == :prod,
      source_url: "https://github.com/akoutmos/ratex",
      homepage_url: "https://hex.pm/packages/ratex",
      description: "Render LaTeX equations as PNG & SVG files",
      elixirc_paths: elixirc_paths(Mix.env()),
      test_coverage: [tool: ExCoveralls],
      dialyzer: [
        plt_add_apps: [:mix],
        plt_file: {:no_warn, "priv/plts/dialyzer.plt"}
      ],
      package: package(),
      deps: deps(),
      docs: docs(),
      aliases: aliases()
    ]
  end

  defp project_version do
    "VERSION"
    |> File.read!()
    |> String.trim()
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  def cli do
    [
      preferred_envs: [
        coveralls: :test,
        "coveralls.detail": :test,
        "coveralls.post": :test,
        "coveralls.html": :test,
        "coveralls.github": :test
      ]
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      # Production deps
      {:rustler_precompiled, "~> 0.4"},
      {:rustler, ">= 0.0.0", optional: true},
      {:nimble_options, "~> 1.1"},

      # Dev deps
      {:doctor, "~> 0.21", only: :dev},
      {:ex_doc, "~> 0.34", only: :dev},
      {:credo, "~> 1.7", only: :dev},
      {:dialyxir, "~> 1.4", only: :dev, runtime: false},

      # Test deps
      {:excoveralls, "~> 0.18", only: :test, runtime: false},
      {:ecto, "~> 3.8", only: :test}
    ]
  end

  defp docs do
    livebooks =
      __DIR__
      |> Path.join("livebooks")
      |> File.ls!()
      |> Enum.map(fn livebook ->
        Path.join("livebooks", livebook)
      end)
      |> Enum.sort()

    [
      main: "readme",
      source_ref: "master",
      logo: "guides/images/logo.png",
      extras: [
        "README.md" | livebooks
      ],
      groups_for_extras: [
        General: ["README.md", "CHANGELOG.md"],
        Livebooks: Path.wildcard("livebooks/*.livemd")
      ]
    ]
  end

  defp package do
    [
      name: "ratex",
      files:
        ~w(lib livebooks mix.exs README.md LICENSE CHANGELOG.md guides native/ratex_nif/.cargo native/ratex_nif/src native/ratex_nif/Cargo.* VERSION checksum-*.exs),
      licenses: ["MIT"],
      maintainers: ["Alex Koutmos"],
      links: %{
        "GitHub" => "https://github.com/akoutmos/ratex",
        "Sponsor" => "https://github.com/sponsors/akoutmos"
      }
    ]
  end

  defp aliases do
    [
      docs: ["docs", &copy_files/1]
    ]
  end

  defp copy_files(_) do
    # Set up directory structure
    File.mkdir_p!("./doc/guides/images")

    # Copy over image files
    "./guides/images/"
    |> File.ls!()
    |> Enum.each(fn image_file ->
      File.cp!("./guides/images/#{image_file}", "./doc/guides/images/#{image_file}")
    end)
  end
end
