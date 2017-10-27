defmodule ExampleTest do
  @moduledoc """
  This is a very simple Phoenix that serves as an integration
  test for Hyperbuffs.

  We create a protobuf definitio, a view, controller, router
  and endpoint. We start the Phoenix app and run tests similar
  to controller tests in Phoenix apps.
  """
  use ExUnit.Case, async: true
  use Phoenix.ConnTest

  # Require Protobuf definitions
  Code.require_file("./test/example/example.pb.exs")

  defmodule ExampleView do
    use Hyperbuffs.View
  end

  defmodule ExampleController do
    use Phoenix.Controller
    use Hyperbuffs.Controller

    @spec ping(Conn.t, %Defs.PingRequest{}) :: %Defs.PongResponse{}
    def ping(_conn, %Defs.PingRequest{ping: ping}) do
      Defs.PongResponse.new(pong: %Defs.Pong{payload: ping.payload})
    end

    @spec status(Conn.t, %Defs.StatusRequest{}) :: %Defs.StatusResponse{}
    def status(_conn, %Defs.StatusRequest{}) do
      Defs.StatusResponse.new(status: %Defs.Status{status: "green"})
    end
  end

  defmodule ExampleRouter do
    use Phoenix.Router
    use Hyperbuffs.Router

    pipeline :api do
      plug Plug.Parsers, parsers: [:json, Plug.Parsers.Protobuf], pass: ["multipart/mixed", "application/json"], json_decoder: Poison
      plug :accepts, ~w(json proto)
    end

    scope "/" do
      pipe_through :api

      service ExampleController, Defs.ExampleService
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

      conn = post(conn, "/ping", "{\"ping\": {\"payload\": \"abc\"}}")
      json = json_response(conn, 200)

      assert json["pong"]["payload"] == "abc"
    end

    test "proto in / out" do
      conn = build_conn()
        |> put_req_header("content-type", "application/x-protobuf")
        |> put_req_header("accept", "application/x-protobuf")

      conn = post conn, "/ping", Defs.PingRequest.encode(Defs.PingRequest.new(ping: Defs.Ping.new(payload: "abc")))
      pong_response = conn
        |> response(200)
        |> Defs.PongResponse.decode

      assert pong_response.pong.payload == "abc"
    end
  end

  describe "/status" do
    test "json out" do
      conn = build_conn()
        |> put_req_header("accept", "application/json")

      conn = get conn, "/status"
      json = json_response(conn, 200)

      assert json["status"]["status"] == "green"
    end

    test "proto out" do
      conn = build_conn()
        |> put_req_header("accept", "application/x-protobuf")

      conn = get conn, "/status"
      status = conn
        |> response(200)
        |> Defs.StatusResponse.decode

      assert status.status.status == "green"
    end
  end
end