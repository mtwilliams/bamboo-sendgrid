defmodule Bamboo.Test.MockSendgrid do
  use Plug.Router

  plug Plug.Parsers,
    parsers: [:urlencoded, :multipart, :json],
    pass: ["*/*"],
    json_decoder: Poison

  plug :match
  plug :dispatch

  def start_server(parent) do
    Agent.start_link(fn -> HashDict.new end, name: __MODULE__)
    Agent.update(__MODULE__, &HashDict.put(&1, :parent, parent))
    Application.put_env(:bamboo, :sendgrid_base_uri, "http://localhost:4001")
    Plug.Adapters.Cowboy.http __MODULE__, [], port: 4001
  end

  def shutdown do
    Plug.Adapters.Cowboy.shutdown __MODULE__
  end

  post "/mail.send.json" do
    case {req_is_authorized(conn), req_is_well_formed(conn)} do
      {true, true} ->
        conn = respond_with_success(conn)
        send(parent, {:mock, :ok, conn})
        conn
      {true, false} ->
        conn = respond_with_error(conn)
        send(parent, {:mock, :error, conn})
        conn
      {false, _} ->
        conn = respond_with_forbidden(conn)
        send(parent, {:mock, :error, conn})
        conn
    end
  end

  defp req_is_authorized(%Plug.Conn{} = conn) do
    case conn.req_headers do
      [{"authorization", authorization} | _] ->
        authorized(authorization)
      _ ->
        false
    end
  end

  defp authorized(<<"Basic ", token :: binary>>) do
    case Base.url_decode64(token) do
      {:ok, "VALID_USERNAME:VALID_PASSWORD"} -> true
      _ -> false
    end
  end

  defp authorized(<<"Bearer ", token :: binary>>) do
    case token do
      "VALID_API_KEY" -> true
      _ -> false
    end
  end

  defp req_is_well_formed(%Plug.Conn{} = conn) do
    Enum.all?([
      sender_is_well_formed(conn.params),
      recipients_are_well_formed(:to, conn.params),
      recipients_are_well_formed(:cc, conn.params),
      recipients_are_well_formed(:bcc, conn.params),
      subject_is_well_formed(conn.params),
      body_is_well_formed(conn.params)
    ])
  end

  defp sender_is_well_formed(%{} = email) do
    case {Map.get(email, "fromname"), Map.get(email, "from")} do
      {name, email} when is_binary(name) and is_binary(email) ->
        true
      {nil, email} when is_binary(email) ->
        true
      _ ->
        false
    end
  end

  defp recipients_are_well_formed(type, %{} = email) do
    names = Map.get(email, "#{type}name")
    emails = Map.get(email, Atom.to_string(type))
    case {names, emails} do
      {nil, nil} ->
        type != :to
      {[], []} ->
        type != :to
      {nil, emails} ->
        Enum.all?(emails, &is_binary/1)
      {names, emails} when is_list(names) and is_list(emails) ->
        if length(names) == length(emails) do
          Enum.all?(names, &(is_nil(&1) or is_binary(&1))) and Enum.all?(emails, &is_binary/1)
        else
          false
        end
      _ ->
        false
    end
  end

  defp subject_is_well_formed(%{} = email) do
    case Map.get(email, "subject") do
      subject when is_binary(subject) ->
        true
      _ ->
        false
    end
  end

  defp body_is_well_formed(%{} = email) do
    case {Map.get(email, "text"), Map.get(email, "html")} do
      {nil, nil} ->
        false
      {text, nil} when is_binary(text) ->
        true
      {nil, html} when is_binary(html) ->
        true
      {text, html} when is_binary(text) and is_binary(html) ->
        true
      _ ->
        false
    end
  end

  defp respond_with_success(conn) do
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, Poison.encode!(%{message: "success"}))
  end

  defp respond_with_error(conn) do
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(400, Poison.encode!(%{message: "error", errors: []}))
  end

  defp respond_with_forbidden(conn) do
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(403, Poison.encode!(%{message: "error", errors: []}))
  end

  defp parent do
    Agent.get(__MODULE__, fn(set) -> HashDict.get(set, :parent) end)
  end
end
