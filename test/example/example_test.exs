defmodule ExampleTest do
  @moduledoc """
  This is a very simple Phoenix that serves as an integration
  test for HyperBuffs.

  We create a protobuf definitio, a view, controller, router
  and endpoint. We start the Phoenix app and run tests similar
  to controller tests in Phoenix apps.
  """
  use ExUnit.Case, async: true
  use Phoenix.ConnTest

  defmodule Defs do
    use Protobuf, """
      message Ping {
        string payload = 1;
      }

      message Pong {
        string payload = 1;
      }
    """
  end

  defmodule ExampleView do
    use HyperBuffs.View, defs: [Defs.Pong]
  end

  defmodule ExampleController do
    use Phoenix.Controller
    use HyperBuffs.Controller

    @spec ping(Conn.t, %Defs.Ping{}) :: %Defs.Ping{}
    def ping(_conn, ping=%Defs.Ping{}) do
      Defs.Pong.new(payload: ping.payload)
    end
  end

  defmodule ExampleRouter do
    use Phoenix.Router
    pipeline :api do
      plug Plug.Parsers, parsers: [:json, Plug.Parsers.Protobuf], pass: ["multipart/mixed", "application/json"], json_decoder: Poison
      plug :accepts, ~w(json proto)
    end

    scope "/" do
      pipe_through :api

      post "/ping", ExampleController, :ping, private: %{req: Defs.Ping, resp: Defs.Pong}
    end
  end

  defmodule ExampleEndpoint do
    use Phoenix.Endpoint, otp_app: :example_app

    plug ExampleRouter
  end

  setup_all do
    Application.put_env(:phoenix, :format_encoders, [])
    Application.put_env(:phoenix, :filter_parameters, [])
    ExampleEndpoint.start_link()

    :ok
  end

  @endpoint ExampleEndpoint

  describe "/ping" do
    test "json in / out" do
      conn = build_conn()
        |> put_req_header("content-type", "application/json")
        |> put_req_header("accept", "application/json")

      conn = post(conn, "/ping", "{\"payload\": \"abc\"}")
      json = json_response(conn, 200)

      assert json["payload"] == "abc"
    end

    test "proto in / out" do
      conn = build_conn()
        |> put_req_header("content-type", "application/x-protobuf")
        |> put_req_header("accept", "application/x-protobuf")

      conn = post conn, "/ping", Defs.Ping.encode(Defs.Ping.new(payload: "abc"))
      pong = conn
        |> response(200)
        |> Defs.Pong.decode

      assert pong.payload == "abc"
    end
  end
end