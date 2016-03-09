defmodule BambooSendgrid.Mixfile do
  use Mix.Project

  def project do
    [app: :bamboo_sendgrid,
     name: "Sendgrid for Bamboo",
     version: version,
     elixir: "~> 1.2",
     elixirc_paths: elixirc_paths(Mix.env),
     description: "A SendGrid adapter for Bamboo.",
     homepage_url: "https://github.com/mtwilliams/sendgrid-with-bamboo",
     source_url: "https://github.com/mtwilliams/sendgrid-with-bamboo",
     deps_path: "_deps",
     lockfile: "mix.lock",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     package: package,
     deps: deps,
     aliases: aliases,
     docs: docs]
  end

  def application do
    [env: [],
     applications: ~w(bamboo httpoison)a]
  end

  defp version do
    case System.cmd("git", ["describe", "--tags"], stderr_to_stdout: true) do
      {tag, 0} ->
        String.strip(tag)
      _ ->
        # HACK(mtwilliams): Default to `0.0.0`.
        "0.0.0"
    end
  end

  defp package do
    [maintainers: ["Michael Williams"],
     licenses: ["Public Domain"],
     links: %{"GitHub" => "https://github.com/mtwilliams/bamboo-sendgrid"}]
  end

  defp elixirc_paths(:test), do: elixirc_paths ++ ["test/mocks"]
  defp elixirc_paths(_), do: elixirc_paths
  defp elixirc_paths, do: ["lib"]

  defp deps do
    [{:bamboo,    "~> 0.3.0"},
     {:httpoison, "~> 0.8"},
     {:poison,    "~> 1.5"},

     # Testing
     {:plug,      "~> 1.0", only: :test},
     {:cowboy,    "~> 1.0", only: :test},

     # Documentation
     {:ex_doc,    "~> 0.10",  only: :docs},
     {:earmark,   "~> 0.1",   only: :docs},
     {:inch_ex,   ">= 0.0.0", only: :docs}]
  end

  defp aliases do
    []
  end

  defp docs do
    [main: "Bamboo.SendgridAdapter",
     canonical: "http://hexdocs.pm/bamboo-sendgrid",
     source_url: "https://github.com/mtwilliams/bamboo-sendgrid",
     source_ref: version]
  end
end
