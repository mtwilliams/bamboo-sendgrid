defmodule Bamboo.SendgridAdapter do
  @moduledoc """
  Sends email using Sendgrid's JSON API.

  Use this adapter to send emails through Sendgrids's API. Requires that an API
  key or username and password are set in the config. See
  [Bamboo.SendgridEmail](Bamboo.SendgridEmail.html) for helpers that can be
  used by the SendgridAdapter to do things like categorizing.

  ## Example config

      # In config/config.exs, or config/prod.exs, etc.
      config :my_app, MyApp.Mailer,
        adapter: Bamboo.SendgridAdapter,
        # Use your API key...
        api_key: "..."
        # or a username and password combination.
        username: "...",
        password: "..."

      # Define a Mailer. Maybe in lib/my_app/mailer.ex
      defmodule MyApp.Mailer do
        use Bamboo.Mailer, otp_app: :my_app
      end

  """

  @behaviour Bamboo.Adapter

  defmodule ApiError do
    defexception [:message]

    def exception(%{params: params, response: response} = response) do
      %ApiError{message: """
      There was a problem sending the email through Sendgrid's API.

      Here's what we sent:

      #{inspect params, limit: :infinity}

      Here's the response:

      #{inspect response, limit: :infinity}
      """}
    end
  end

  def deliver(email, config) do
    params = convert_to_sendgrid_params(email)
    case post!("/mail.send.json", headers(config), params) do
      %{status_code: 200} = response ->
        raise ApiError, %{params: params, response: response}
      response ->
        response
    end
  end

  def handle_config(config) do
    authorization!(config)
    config
  end

  defp convert_to_sendgrid_params(email) do
    %{}
    |> add_headers(email)
    |> add_sender(email)
    |> add_recipients(email)
    |> add_subject(email)
    |> add_body(email)
  end

  defp add_headers(params, email) do
    Map.merge(params, %{
      headers: Poison.encode(email.headers)
    })
  end

  defp add_sender(params, email) do
    Map.merge(params, %{
      from: elem(email.from, 1),
      fromname: elem(email.from, 0)
    })
  end

  defp add_recipients(params, email) do
    params
    |> add_recipients_of_type(email.to, type: :to)
    |> add_recipients_of_type(email.cc, type: :cc)
    |> add_recipients_of_type(email.bcc, type: :bcc)
  end

  defp add_recipients_of_type(params, recipients, type: type) do
    names = Enum.filter(recipients, &(elem(&1, 0)))
    emails = Enum.filter(recipients, &(elem(&1, 0)))

    params
    |> Map.put(:"#{type}", emails)
    |> Map.put(:"#{type}name", names)
  end

  defp add_subject(params, email) do
    Map.merge(params, %{
      subject: email.subject
    })
  end

  defp add_body(params, email) do
    Map.merge(params, %{
      text: email.text_body,
      html: email.html_body
    })
  end

  @base "https://api.sendgrid.com/api"

  defp headers(config) do
    authorization =
      case authorization(config) do
        {:basic, token}  ->  "Basic #{token}"
        {:bearer, token} -> "Bearer #{token}"
      end

    %{"Content-Type"  => "application/json",
      "Authorization" => authorization}
  end

  defp authorization(config) do
    case config[:api_key] do
      api_key when is_binary(api_key) ->
        {:bearer, api_key}
      _ ->
        case {config[:username], config[:password]} do
          {username, password} when is_binary(username) and is_binary(password) ->
            {:basic, Base.url_encode64("#{username}:#{password}")}
          _ ->
            nil
        end
    end
  end

  defp authorization!(config) do
    case authorization(config) do
      nil ->
        # TODO(mtwilliams): Use edit distance to identify misspellings.
        raise ArgumentError, """
        You failed to provide credentials for your Sendgrid adapter!

        Here is the configuration that was passed in:

        #{inspect config, limit: :infinity}
        """
      authorization ->
        authorization
    end
  end

  defp options!(path, headers, params), do: HTTPoison.head!(@base <> path, headers, params: params)
  defp head!(path, headers, params), do: HTTPoison.head!(@base <> path, headers, params: params)
  defp get!(path, headers, params), do: HTTPoison.get!(@base <> path, headers, params: params)
  defp put!(path, headers, params), do: HTTPoison.post!(@base <> path, params, headers)
  defp post!(path, headers, params), do: HTTPoison.post!(@base <> path, params, headers)
  defp patch!(path, headers, params), do: HTTPoison.post!(@base <> path, params, headers)
  defp delete!(path, headers, params), do: HTTPoison.post!(@base <> path, headers, params: params)
end
