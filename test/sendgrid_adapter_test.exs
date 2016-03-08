defmodule Bamboo.SendgridAdapterTest do
  use ExUnit.Case

  alias Bamboo.Email

  alias Bamboo.SendgridEmail
  alias Bamboo.SendgridAdapter

  alias Bamboo.Test.MockSendgrid

  @config_with_no_credentials %{adapter: SendgridAdapter}
  @config_with_malformed_api_key %{adapter: SendgridAdapter, api_key: 123}
  @config_with_valid_api_key %{adapter: SendgridAdapter, api_key: "VALID_API_KEY"}
  @config_with_invalid_api_key %{adapter: SendgridAdapter, api_key: "INVALID_API_KEY"}
  @config_with_malformed_username_and_password %{adapter: SendgridAdapter, username: 123, password: 123}
  @config_with_valid_username_and_password %{adapter: SendgridAdapter, username: "VALID_USERNAME", password: "VALID_PASSWORD"}
  @config_with_invalid_username_and_password %{adapter: SendgridAdapter, username: "INVALID_USERNAME", password: "INVALID_PASSWORD"}

  @email Email.new_email(from: "john@doe.com",
                         to: "jane@doe.com",
                         subject: "Who are you?",
                         text_body: "Who who, who who?")
         |> Bamboo.Mailer.normalize_addresses

  setup do
    MockSendgrid.start_server(self)

    on_exit fn ->
      MockSendgrid.shutdown
    end

    :ok
  end

  test "raises if no credentials are provided" do
    assert_raise ArgumentError, ~r/You did not provide any credentials\./, fn ->
      SendgridAdapter.deliver(@email, @config_with_no_credentials)
    end
  end

  test "raises if a malformed API key are provided" do
    assert_raise ArgumentError, ~r/You provided a malformed API key\./, fn ->
      SendgridAdapter.deliver(@email, @config_with_malformed_api_key)
    end
  end

  test "raises if a malformed username and password are provided" do
    assert_raise ArgumentError, ~r/You provided a malformed username and\/or password\./, fn ->
      SendgridAdapter.deliver(@email, @config_with_malformed_username_and_password)
    end
  end

  test "succeeds if a valid api key is used" do
    SendgridAdapter.deliver(@email, @config_with_valid_api_key)
  end

  test "raises if an invalid api key is used" do
    assert_raise SendgridAdapter.ApiError, fn ->
      SendgridAdapter.deliver(@email, @config_with_invalid_api_key)
    end
  end

  test "succeeds if a valid username and password are used" do
    SendgridAdapter.deliver(@email, @config_with_valid_username_and_password)
  end

  test "raises if an invalid username and/or password is used" do
    assert_raise SendgridAdapter.ApiError, fn ->
      SendgridAdapter.deliver(@email, @config_with_invalid_username_and_password)
    end
  end

  test "deliver/2 sends to the right url" do
    SendgridAdapter.deliver(@email, @config_with_valid_api_key)
    assert_receive {:mock, :ok, %{request_path: "/mail.send.json"}}
  end

  test "deliver/2 sends headers, sender, recipients, subject, and body" do
    flunk "Test not written yet."
  end

  test "deliver/2 correctly formats recipients" do
    @email
    |> Map.put(:to, [{"John Cena", "jonny@cena.com"}])
    |> Map.put(:cc, [{"Big Sister", "cc@nsa.gov"}])
    |> Map.put(:bcc, [{"Big Brother", "bcc@nsa.gov"}])
    |> SendgridAdapter.deliver(@config_with_valid_api_key)

    assert_receive({:mock, :ok, %{params: %{
      "toname" => ["John Cena"],
      "to" => ["jonny@cena.com"],
      "ccname" => ["Big Sister"],
      "cc" => ["cc@nsa.gov"],
      "bccname" => ["Big Brother"],
      "bcc" => ["bcc@nsa.gov"]
    }}})
  end
end
