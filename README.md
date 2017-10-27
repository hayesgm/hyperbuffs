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
      [{:hyperbuffs, "~> 0.2.0"}]
    end
    ```

  2. Add the following to your controllers, views and router:

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

  3. Add `protobufs` mime type to your config:

    ```elixir
    config :mime, :types, %{
      "application/x-protobuf" => ["proto"]
    }
    ```

  4. After adding that, you'll need to recompile `mime`:

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

    message NameTag {
      string name = 1;
    }

    message Loudspeaker {
      string greeting = 1;
    }

    service HelloService {
      rpc hello (NameTag) returns (Loudspeaker) {
        option (google.api.http) = { post: "/hello" };
      }
    }
    ```

  2. Generate your protobuf definitions

  ```bash
  protoc --proto_path="./priv/proto" --elixir_out="./lib/defs" "./priv/proto"
  ```

  2. Add proto config to your desired routes:

    ```elixir
    defmodule MyApp.Router do
      use Phoenix.Router
      use Hyperbuffs.Router # <-- Add Hyperbuffs router

      pipeline :api do
        plug Plug.Parsers, parsers: [Plug.Parsers.Protobuf] # allows Protobuf input
        plug :accepts, ["json", "proto"] # allows for Protobuf response
      end

      scope "/" do
        pipe_through :api

        service HelloService, HelloController
      end
    end
    ```

  3. Build your actions in your controller:

    ```elixir
    defmodule MyApp.HelloController do
      use MyApp.Web, :controller
      use Hyperbuffs.Controller # <-- add this

      def hello(_conn, name_tag) do
        Defs.Loudspeaker.new(greeting: "Hello #{name_tag.name}!!!")
      end
    end
    ```

  4. Add protobuf definitions to your view:

    ```elixir
    defmodule MyApp.HomeView do
      use MyApp.Web, :view
      use Hyperbuffs.View # <-- add this
    end
    ```

### Actions

Actions in Hyperbuffs try to follow an RPC model where you have a declared input and you return a declared output. Hyperbuffs will ensure that the input and output can be either JSON or Protobufs based on the Content-Type and Accept headers respectively.

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
