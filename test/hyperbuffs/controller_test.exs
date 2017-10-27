defmodule HyperBuffs.ControllerTest do
  use ExUnit.Case, async: true

  setup_all do
    Application.put_env(:phoenix, :format_encoders, [])
  end

  defmodule MyDef do
    use Protobuf, syntax: :proto3

    @type t :: %__MODULE__{
      name: String.t
    }
    defstruct [:name]

    field :name, 1, type: :string
  end

  defmodule TestController do
    use Phoenix.Controller
    use HyperBuffs.Controller

    def foo(conn, proto=%{__struct__: _struct}) do
      %{conn | private: conn.private |> Map.put(:call, :proto) |> Map.put(:args, [conn, proto])}
    end

    def foo(conn, params=%{}) do
      %{conn | private: conn.private |> Map.put(:call, :params) |> Map.put(:args, [conn, params])}
    end

    def foo(conn) do
      %{conn | private: conn.private |> Map.put(:call, :base) |> Map.put(:args, [conn])}
    end

    def bar_1(conn, _params=%{}) do
      %{conn | private: conn.private |> Map.put(:type, :just_conn)}
    end

    def bar_2(conn, _params=%{}) do
      {%{conn | private: conn.private |> Map.put(:type, :conn_plus_def)}, %MyDef{name: "G"}}
    end

    def bar_3(_conn, _params=%{}) do
      %MyDef{name: "Just def"}
    end
  end

  defmodule TestView do
    def render(type, %{protobuf: protobuf, params: params}) do
      "Type: #{type}, Protobuf: #{inspect protobuf}, Params: #{params.__struct__}"
    end
  end

  def build_conn(params, method \\ :foo, resp \\ nil) do
    Plug.Test.conn(:get, "/foo", Enum.into(params, %{}))
      |> Plug.Conn.put_private(:phoenix_controller, TestController)
      |> Plug.Conn.put_private(:phoenix_action, method)
      |> Plug.Conn.put_private(:resp, resp)
      |> Phoenix.Controller.put_view(TestView)
  end

  describe "proper action calls" do
    test "for a normal conn" do
      conn = build_conn(name: "G")

      next_conn = TestController.action(conn, nil)

      assert next_conn.private[:call] == :params
      assert next_conn.private[:args] == [conn, %{"name" => "G"}]
    end

    test "for a conn with [req: :none]" do
      conn =
        build_conn(name: "G")
        |> Plug.Conn.put_private(:req, :none)

      next_conn = TestController.action(conn, nil)

      assert next_conn.private[:call] == :base
      assert next_conn.private[:args] == [conn]
    end

    test "for a conn with [req: MyDef]" do
      conn =
        build_conn(name: "G")
        |> Plug.Conn.put_private(:req, MyDef)

      next_conn = TestController.action(conn, nil)

      assert next_conn.private[:call] == :proto
      assert next_conn.private[:args] == [conn, %MyDef{name: "G"}]
    end

    test "for a conn with [req: MyDef] and proto" do
      proto = %MyDef{name: "G"}

      conn =
        build_conn(%{"_protobuf" => proto})
        |> Plug.Conn.put_private(:req, MyDef)

      next_conn = TestController.action(conn, nil)

      assert next_conn.private[:call] == :proto
      assert next_conn.private[:args] == [conn, proto]
    end
  end

  describe "proper output building" do
    test "for a regular conn result" do
      conn =
        build_conn([name: "G"], :bar_1)

      next_conn = TestController.action(conn, nil)

      assert next_conn.private[:type] == :just_conn
      assert next_conn.resp_body == nil
    end

    test "for a conn and def" do
      conn =
        build_conn([name: "G", _format: "other"], :bar_2)

      next_conn = TestController.action(conn, nil)

      assert next_conn.private[:type] == :conn_plus_def
      assert next_conn.resp_body ==
        "Type: protobuf.other, " <>
        "Protobuf: nil, " <>
        "Params: Elixir.HyperBuffs.ControllerTest.MyDef"
    end

    test "for a def only" do
      conn =
        build_conn([name: "G", _format: "other"], :bar_3)

      next_conn = TestController.action(conn, nil)

      assert next_conn.private[:type] == nil
      assert next_conn.resp_body ==
        "Type: protobuf.other, " <>
        "Protobuf: nil, " <>
        "Params: Elixir.HyperBuffs.ControllerTest.MyDef"
    end

    test "for a def with protobuf only" do
      conn =
        build_conn([name: "G", _format: "other"], :bar_3, MyDef)

      next_conn = TestController.action(conn, nil)

      assert next_conn.private[:type] == nil
      assert next_conn.resp_body ==
        "Type: protobuf.other, " <>
        "Protobuf: HyperBuffs.ControllerTest.MyDef, " <>
        "Params: Elixir.HyperBuffs.ControllerTest.MyDef"
    end
  end

  describe "render_proto/2" do
    test "it calls render function" do
      conn = HyperBuffs.Controller.render_proto(build_conn([_format: "other"]), %MyDef{name: "G"})

      assert conn.resp_body ==
        "Type: protobuf.other, " <>
        "Protobuf: nil, " <>
        "Params: Elixir.HyperBuffs.ControllerTest.MyDef"
    end
  end
end