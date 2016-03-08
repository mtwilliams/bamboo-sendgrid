# Bamboo Using Sendgrid

:bamboo: A SendGrid adapter for [Paul Smith's great emailer.](https://github.com/paulcsmith/bamboo)

## Usage

TODO

## Testing

TODO

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed as:

  1. Add bamboo\_using\_sendgrid to your list of dependencies in `mix.exs`:

        def deps do
          [{:bamboo\_using\_sendgrid, "~> 0.0.0"}]
        end

  2. Ensure bamboo\_using\_sendgrid is started before your application:

        def application do
          [applications: [:sendgrid\_with\_bamboo]]
        end

