defmodule Hyperbuffs.Controller do

  @doc """
  Wraps the `action/2` method for your controller so that your action methods
  can accept and respond on speaking in Proto objects.

  Once you set private :req and :resp in your routes, Hyperbuffs will change
  the way we call your controller actions. See `call_action/3` below
  for details.

  Note: it's considered acceptable and appropriate to override `action/2`, as
        we are going.
  """
  defmacro __using__(_opts) do
    quote do
      import Hyperbuffs.Controller, only: [render_proto: 2]

      def action(conn, _options) do
        resp = Hyperbuffs.Controller.call_action(conn, action_name(conn), __MODULE__)

        case resp do
          next_conn=%Plug.Conn{} -> next_conn
          {next_conn=%Plug.Conn{}, resp} ->
            render_proto(next_conn, resp)
          resp ->
            render_proto(conn, resp)
        end
      end
    end
  end

  @doc """
  This function will call the appropriate action in `mod` based
  on the request configuration in `conn.private[:req]`.

  For Hyperbuffs, instead of taking [conn, params] as input to our
  actions, we base the action definitions off of our route definitions.

  This function is responsible calling the action with the following params:

   * If `conn.private[:req]` is nil, call `action(conn, params)` like normal
   * If `conn.private[:req]` is :none, call `action(conn)` with no params
   * If `conn.private[:req]` is a struct, call `action(conn, proto)` with proto from params

  Note: If params["_protobuf"] is set from PlugProtobufs, we will use that. Otherwise,
  we will create a new proto from the params themselves.
  """
  @spec call_action(Plug.Conn.t, atom(), atom()) :: Plug.Conn.t | struct() | {Plug.Conn.t, struct()}
  def call_action(conn=%Plug.Conn{private: private}, action_name, mod) do
    case private[:req] do
      nil ->
        # `action(conn, params)`
        apply(mod, action_name, [conn, conn.params])
      :none ->
        # `action(conn)`
        apply(mod, action_name, [conn])
      protobuf ->
        # `action(conn, proto)`

        # This can come from plug_protobufs or we can build it from params
        # TODO: What if params are unfetched?
        proto = conn.params["_protobuf"] || protobuf.from_params(conn.params)

        apply(mod, action_name, [conn, proto])
    end
  end

  @doc """
  Helper function to render a protobuf, since the proto itself
  specifies the template in its definition.

  For a protobuf named "Defs.MyProtobuf", this is the equivalent
  of calling `render(conn, Defs.MyProtobuf, MyProtobuf)`.

  It's expected that you then define in your view matching calls,
  such as: `render("Elixir.Defs.MyProtobuf.proto", proto)` and
  `render("Elixir.Defs.MyProtobuf.json", proto)`. See `Hyperbuffs.View`
  for helpers generating these view functions.
  """
  @spec render_proto(Plug.Conn.t, struct()) :: Plug.Conn.t
  def render_proto(conn, proto) do
    Phoenix.Controller.render(conn, :protobuf, %{protobuf: conn.private[:resp], params: proto})
  end
end
