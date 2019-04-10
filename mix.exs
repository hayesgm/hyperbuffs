defmodule Hyperbuffs.Mixfile do
  use Mix.Project

  def project do
    [app: :hyperbuffs,
     version: "0.2.3",
     elixir: "~> 1.7",
     description: description(),
     package: package(),
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     elixirc_paths: elixirc_paths(Mix.env),
     deps: deps()]
  end
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_),     do: ["lib"]

  # Configuration for the OTP application
  #
  # Type "mix help compile.app" for more information
  def application do
    [applications: [:logger],]
  end

  # Dependencies can be Hex packages:
  #
  #   {:mydep, "~> 0.3.0"}
  #
  # Or git/path repositories:
  #
  #   {:mydep, git: "https://github.com/elixir-lang/mydep.git", tag: "0.1.0"}
  #
  # Type "mix help deps" for more examples and options
  defp deps do
    [
      {:phoenix, "~> 1.4.3"},
      {:plug_protobufs, "~> 0.1.4"},
      {:ex_doc, "~> 0.19.1", only: :dev},
      {:protobuf_ex, "~> 0.6.0"},
      {:jason, "~> 1.1.2"}
    ]
  end

  defp description do
    """ 
    Hyperbuffs is an Elixir library which strongly connects Phoenix to Protobuf definitions. Based on content negotiation from incoming requests, your controllers will seamlessly accept and respond in either JSON or Protobuf.
    """ 
  end

  defp package do
    [
      maintainers: ["Geoffrey Hayes", "Fahim Zahur"],
      licenses: ["MIT"], 
      links: %{"GitHub" => "https://github.com/hayesgm/hyperbuffs"}
    ]
  end
end
