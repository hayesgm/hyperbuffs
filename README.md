# Hyperbuffs

Hyperbuffs is an Elixir library which strongly connects Phoenix to Protobuf definitions. Based on content negotiation from incoming requests, your controllers will seamlessly accept and respond in either JSON or Protobuf (you can even accept one and return another). The goal is that your controller definitions are strongly typed and you give clients the option of how the data is encoded.

To use Hyperbuffs, you will define your services with a desired RPC schema and connect those to your routes.

```protobuf
service ExampleService {
  rpc ping (Ping) returns (Pong) {
    option (google.api.http) = { post: "/ping" };
  }

  rpc status (StatusRequest) returns (StatusResponse) {
    option (google.api.http) = { get: "/status" };
  }
}
```

```elixir
  service ExampleService, ExampleController
```

and your controllers will speak Protobuf:

```elixir
  defmodule ExampleController do

    # Our actions now take a protobuf and return a protobuf
    @spec create(%Plug.Conn{}, %Defs.Ping{}) :: %Defs.Pong
    def create(_conn, %Defs.Ping{payload: payload}) do
      Defs.Pong.new(payload: payload)
    end
  end
```

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed as:

  1. Add `hyperbuffs` to your list of dependencies in `mix.exs`:

    ```elixir
    def deps do
      [{:hyperbuffs, "~> 0.2.1"}]
    end
    ```

  2. Install `protoc-gen-elixir` from `protobuf-ex`:

    ```bash
    cd ~
    git clone https://github.com/hayesgm/protobuf-ex.git
    cd protobuf-ex
    mix escript.install
    ```

  3. Add the following to your controllers, views and router:

    `lib/my_app.ex`

    ```elixir
    defmodule MyApp do
      # ...
      def controller do
        quote do
          use Phoenix.Controller, namespace: MyApp
          use Hyperbuffs.Controller # <- add this
          # ...
        end
      end

      def view do
        quote do
          use Phoenix.View, root: "lib/my_app/templates",
                            namespace: MyApp
          use Hyperbuffs.View # <- add this
          # ...
        end
      end

      def router do
        quote do
          use Phoenix.Router
          use Hyperbuffs.Router # <- add this
          # ...
        end
      end
    end
    ```

    *or*, add Hyperbuffs to each controller, view and router:

    `page_controller.ex`

    ```elixir
    def MyApp.PageController do
      use MyApp, :controller
      use Hyperbuffs.Controller

    end
    ```

    `page_view.ex`

    ```elixir
    def MyApp.PageView do
      use MyApp, :view
      use Hyperbuffs.View

    end
    ```

    `router.ex`

    ```elixir
    defmodule API.Router do
      use API, :router
      use Hyperbuffs.Router

    end
    ```

  4. Add `protobufs` mime type to your config:

    `mix.exs`

    defp deps do
      # ...
      {:mime, "~> 1.1"}
    end

    `config.exs`

    ```elixir
    config :mime, :types, %{
      "application/x-protobuf" => ["proto"]
    }
    ```

  5. After adding that, you'll need to recompile `mime`:

    ```bash
    mix deps.clean mime --build
    mix deps.get
    ```

## Getting Started

To use Hyperbuffs, you'll need to define some protobufs, add the service definitions to your routes, and then build your controller actions to take and return protobufs. The following walks through an example of this.

  1. Add your protobuf definitions, e.g.:

    `priv/proto/services.proto`

    ```elixir
    syntax = "proto3";

    import "annotations.proto";

    package MyApp;

    service PingService {
      rpc ping (Ping) returns (Pong) {
        option (google.api.http) = { get: "/ping" };
      }
    }

    message Ping {}
    message Pong {
      uint32 timestamp = 1;
    }
    ```

  2. Generate your protobuf definitions (replace `my_app` with your app or package name)

  ```bash
  mkdir ./lib/my_app/proto
  ```

  ```bash
  protoc --proto_path="./priv/proto" --proto_path="./deps/hyperbuffs/priv/proto" --elixir_out="./lib/my_app/proto" ./priv/proto/**
  ```

  Note: for an umbrella app, this would be:

  ```bash
  protoc --proto_path="./priv/proto" --proto_path="../../deps/hyperbuffs/priv/proto" --elixir_out="./lib/my_app/proto" ./priv/proto/**
  ```

  2. Add proto config to your desired routes:

    ```elixir
    defmodule MyApp.Router do
      use MyApp, :router

      # Add this section if you want to allow protobuf inputs and responses
      pipeline :api do
        plug Plug.Parsers, parsers: [Plug.Parsers.Protobuf] # allows Protobuf input
        plug :accepts, ["json", "proto"] # allows for Protobuf response
      end

      scope "/" do
        pipe_through :api

        service MyApp.PingService, StatusController
      end
    end
    ```

  3. Build your actions in your controller:

    ```elixir
    defmodule MyApp.StatusController do
      use MyApp, :controller

      @doc """
      Responds Pong to Ping.

      ## Examples

          iex> MyApp.StatusController.ping(%Plug.Conn{}, %MyApp.Ping{})
          %MyApp.Pong{timestamp: 1508114537}
      """
      @spec ping(Plug.Conn.t, %MyApp.Ping{}) :: %MyApp.Pong{}
      def ping(_conn, _ping) do
        MyApp.Pong.new(timestamp: :os.system_time(:seconds))
      end
    end
    ```

  4. Make sure you have a view for your controller:

    ```elixir
    defmodule MyApp.StatusView do
      use MyApp, :view

    end
    ```

  5. That's all, run your app and view the endpoint.

    ```bash
    $ mix phx.server
    $ curl localhost:4000/ping
    {"timestamp":1509119708}
    ```

### Actions

Actions in Hyperbuffs try to follow an RPC model where you have a declared input and you return a declared output. Hyperbuffs will ensure that the input and output can be either JSON or Protobufs based on the `Content-Type` and `Accept` headers respectively.

That said, you still have access to `conn` and can render traditionally as well. Here's a few examples:

```elixir
  @spec my_action(Plug.Conn.t, %{}) :: Plug.Conn.t | %{} | {Plug.Conn.t, %{}}
  def my_action(conn, req=%Defs.SomeReq{}) do
    # Return just a protobuf
    Defs.SomeResp.new(msg: "Hi #{req.name}")
  end

  def my_action(conn, req=%Defs.SomeReq{}) do
    # Return a conn and a protobuf to be rendered
    {
      conn |> put_resp_header("X-Req-Id", 5)
      Defs.SomeResp.new(msg: "Hi #{req.name}")
    }
  end

  def my_action(conn, req=%Defs.SomeReq{}) do
    # Return just a conn
    conn
    |> Hyperbuffs.View.render_proto Defs.SomeResp.new(msg: "Hi #{req.name}")
  end
```

## Contributing

 * For bugs, please open an issue with steps to reproduce.
 * For smaller feature requests, please either create an issue, or fork and create a PR.
 * For larger feature requests, please create an issue before starting work so we can discuss the design decisions.
