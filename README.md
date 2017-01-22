# HyperBuffs

HyperBuffs is an Elixir library which strongly connects Phoenix to Protobuf definitions. Based on content negotiation from incoming requests, your controllers will seamlessly accept and respond in either JSON or Protobuf (you can even accept one and return another). The goal is that your controller definitions are strongly typed and you give clients the option of how the data is encoded.

To use HyperBuffs, you will define your routes with a desired schema, e.g.

```elixir
  post "/users", HomeController, :create, private: [req: Defs.Ping, resp: Defs.Pong]
```

and your controllers will speak Protobufs:

```elixir
  defmodule HomeController do
    def create(_conn, ping=%Defs.Ping{}) do
      Defs.Pong.new(payload: ping.payload)
    end
  end
```

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed as:

  1. Add `hyperbuffs` to your list of dependencies in `mix.exs`:

    ```elixir
    def deps do
      [{:hyperbuffs, "~> 0.1.0"}]
    end
    ```

  2. Add the following to your controllers and views:

    `web/controllers/page_controller.ex`

    ```elixir
    def MyApp.PageController do
      use MyApp.Web, :controller
      use HyperBuffs.Controller

    end
    ```

    `web/views/page_view.ex`

    ```elixir
    def MyApp.PageView do
      use MyApp.Web, :view
      use HyperBuffs.View, defs: []

    end
    ```

    *or*, to add HyperBuffs to all of your controllers:

    `lib/web.ex`

    ```elixir
    defmodule MyApp.Web do
      # ...
      def controller do
        quote do
          # ...
          use HyperBuffs.Controller # <- add this
        end
      end

      def view do
        quote do
          # ...
          use HyperBuffs.View, defs: [] # <- add this and your defs
        end
      end
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

To use HyperBuffs, you'll need to define some protobufs, add the proto definitions to your routes, and then rebuild your requests to take and return protobufs. The following walks through an example of this.

  1. Add your protobuf definitions, e.g.:

    `lib/defs.ex`

    ```elixir
    defmodule Defs do
      use Protobuf, from: Path.wildcard(Path.expand("../definitions/**/*.proto", __DIR__))
    end
    ```

    `definitions/example.proto`

    ```protobuf
    syntax = "proto3";

    message NameTag {
      string name = 1;
    }

    message Loudspeaker {
      string greeting = 1;
    }
    ```

  2. Add proto config to your desired routes:

    ```elixir
    defmodule MyApp.Router do
      plug Plug.Parsers, parsers: [Plug.Parsers.Protobuf] # allows Protobuf input
      plug :accepts, ["json", "proto"] # allows for Protobuf response

      get "/hello_world", private: [resp: Defs.Loudspeaker]
      post "/hello", private: [req: Defs.NameTag, resp: Defs.Loudspeaker]
    end
    ```

  3. Build your actions in your controller:

    ```elixir
    defmodule MyApp.HomeController do
      use MyApp.Web, :controller

      def hello_world(_conn) do
        Defs.Loudspeaker.new(greeting: "Hello world!")
      end

      def hello(_conn, name_tag) do
        Defs.Loudspeaker.new(greeting: "Hello #{name_tag.name}!")
      end
    end
    ```

## Request and Response

### Routes

HyperBuffs is based around building strong types into your route definitions. The ultimate goal of this project is to be able to generate our route definitions from a proto file itself, so we want those routes to be as declarative as possible.

```elixir
  # Get with just output defined
  get "/abc", MyController, :abc, private: [resp: Defs.ProtoOut]

  # Post with input and output
  post "/abc", MyController, :abc, private: [req: Defs.ProtoIn, resp: Defs.ProtoOut]

  # Post with just output defined
  post "/abc", MyController, :abc, private: [req: :none, resp: Defs.ProtoOut]
```

Note: to be less intrusive, when defining routes, we differentiate between `:none` and not passing `req` or `resp`. If you do not define `req` or `resp` then HyperBuffs will ignore this route and it will follow Phoenix's standard processing (e.g. passing a `params` hash).

### Actions

Actions in HyperBuffs try to follow an RPC model where you have a declared input and you return a declared output. HyperBuffs will ensure that the input and output can be either JSON or Protobufs based on the Content-Type and Accept headers respectively.

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
    |> HyperBuffs.View.render_proto Defs.SomeResp.new(msg: "Hi #{req.name}")
  end
```

## Contributing

 * For bugs, please open an issue with steps to reproduce.
 * For smaller feature requests, please either create an issue, or fork and create a PR.
 * For larger feature requests, please create an issue before starting work so we can discuss the design decisions.
