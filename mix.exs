defmodule VerbNet.Mixfile do
  use Mix.Project

  def project do
    [
      app: :verbnet,
      version: "0.2.0",
      elixir: "~> 1.4",
      build_embedded: Mix.env == :prod,
      start_permanent: Mix.env == :prod,
      description: description(),
      package: package(),
      deps: deps(),

      # Docs.
      name: "VerbNet",
      source_url: "https://github.com/arpieb/verbnet",
      homepage_url: "https://github.com/arpieb/verbnet",
      docs: [
        main: "readme",
        extras: [
          "README.md",
        ]
      ]
     ]
  end

  # Configuration for the OTP application
  #
  # Type "mix help compile.app" for more information
  def application do
    # Specify extra applications you'll use from Erlang/Elixir
    [extra_applications: [:logger]]
  end

  # Dependencies can be Hex packages:
  #
  #   {:my_dep, "~> 0.3.0"}
  #
  # Or git/path repositories:
  #
  #   {:my_dep, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"}
  #
  # Type "mix help deps" for more examples and options
  defp deps do
    [
      {:ex_doc, "~> 0.14.5", only: :dev},
      {:erlsom, "~> 1.4"},
    ]
  end

  defp description do
    """
    This module provides a lookup interface into the VerbNet semantic mapping dataset for natural language processing (NLP) solutions.
    """
  end

  defp package do
    [
      files: [
        "lib",
        "mix.exs",
        "README*",
        "LICENSE*",
      ],
      maintainers: ["Robert Bates"],
      licenses: ["Apache 2.0"],
      links: %{
        "GitHub" => "https://github.com/arpieb/verbnet",
        "VerbNet" => "https://verbs.colorado.edu/~mpalmer/projects/verbnet.html",
      },
    ]
  end
end
