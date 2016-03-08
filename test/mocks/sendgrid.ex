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
        send(parent, {:mock, :ok})
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
    case conn.params do
      %{from: _, to: _} -> true
      _ -> false
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
