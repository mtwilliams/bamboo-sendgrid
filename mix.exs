defmodule BambooUsingSendgrid.Mixfile do
  use Mix.Project

  def project do
    [app: :bamboo_using_sendgrid,
     name: "Bamboo Using Sendgrid",
     version: version,
     elixir: "~> 1.2",
     description: "A SendGrid adapter for Bamboo.",
     homepage_url: "https://github.com/mtwilliams/bamboo-using-sendgrid",
     source_url: "https://github.com/mtwilliams/bamboo-using-sendgrid",
     deps_path: "_deps",
     lockfile: "mix.lock",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     package: package,
     deps: deps,
     aliases: aliases]
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
     licenses: ["Public Domain"]]
  end

  defp deps do
    [bamboo:    "~> 0.3.0",
     httpoison: "~> 0.8"]
  end

  defp aliases do
    []
  end
end
