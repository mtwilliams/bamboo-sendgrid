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

    def exception(%{params: params, response: response}) do
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
    params = convert_to_sendgrid_params(email) |> Poison.encode!
    case post!("/mail.send.json", headers(config), params) do
      %{status_code: 200} = response ->
        :ok
      response ->
        raise ApiError, %{params: params, response: response}
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
      headers: Poison.encode!(email.headers)
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

  @default_base_uri "https://api.sendgrid.com/api"

  defp base_uri do
    Application.get_env(:bamboo, :sendgrid_base_uri) || @default_base_uri
  end

  defp headers(config) do
    authorization =
      case authorization!(config) do
        {:basic, token}  -> "Basic #{token}"
        {:bearer, token} -> "Bearer #{token}"
      end

    %{"Content-Type"  => "application/json",
      "Authorization" => authorization}
  end

  defp authorization(config) do
    case config[:api_key] do
      api_key when is_binary(api_key) ->
        {:ok, :bearer, api_key}
      api_key when not(is_nil(api_key)) ->
        {:error, :malformed_api_key}
      _ ->
        case {config[:username], config[:password]} do
          {username, password} when is_binary(username) and is_binary(password) ->
            {:ok, :basic, Base.url_encode64("#{username}:#{password}")}
          {username, password} when not (is_nil(username) and is_nil(password)) ->
            {:error, :malformed_username_or_password}
          {nil, password} when not is_nil(password) ->
            {:error, :no_username}
          {username, nil} when not is_nil(username) ->
            {:error, :no_password}
          _ ->
            {:error, :no_credentials}
        end
    end
  end

  @reasons_to_humane %{
    no_credentials: "You did not provide any credentials.",
    malformed_api_key: "You provided a malformed API key.",
    no_username: "You did not provide a username.",
    no_password: "You did not provide a password.",
    malformed_username_or_password: "You provided a malformed username and/or password."
  }

  defp authorization!(config) do
    case authorization(config) do
      {:ok, type, token} ->
        {type, token}
      {:error, reason} ->
        # TODO(mtwilliams): Use edit distance to identify misspellings.
        raise ArgumentError, """
        You've misconfigured your Bamboo.SendgridAdapter!

        #{@reasons_to_humane[reason]}

        Here is the configuration that was passed in:

        #{inspect config, limit: :infinity}
        """
    end
  end

  defp options!(path, headers, params), do: HTTPoison.head!(base_uri <> path, headers, params: params)
  defp head!(path, headers, params), do: HTTPoison.head!(base_uri <> path, headers, params: params)
  defp get!(path, headers, params), do: HTTPoison.get!(base_uri <> path, headers, params: params)
  defp put!(path, headers, params), do: HTTPoison.post!(base_uri <> path, params, headers)
  defp post!(path, headers, params), do: HTTPoison.post!(base_uri <> path, params, headers)
  defp patch!(path, headers, params), do: HTTPoison.post!(base_uri <> path, params, headers)
  defp delete!(path, headers, params), do: HTTPoison.post!(base_uri <> path, headers, params: params)
end
