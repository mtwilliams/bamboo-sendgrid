# SendGrid Adapter for Bamboo

:bamboo: A SendGrid adapter for [Paul Smith's great emailer.](https://github.com/paulcsmith/bamboo)

## Usage

Refer to `lib/bamboo/adapters/sendgrid_adapter.ex` or run `h Bamboo.SendgridAdapter`.

## Testing

TODO

## Installation

  1. Add `bamboo_sendgrid` to your list of dependencies in `mix.exs`:

    ```elixir
    def deps do
      [{:bamboo_sendgrid, "~> 0.1"}]
    end
    ```

  2. Ensure `bamboo_sendgrid` is started before your application:

    ```elixir
    def application do
      [applications: [:bamboo_sendgrid]]
    end
    ```
