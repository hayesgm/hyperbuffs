defmodule Hyperbuffs.ViewTest do
  use ExUnit.Case, async: true

  defmodule Simple do
    defstruct [name: ""]

    def encode(simple) do
      %{"encoded" => simple}
    end
  end

  defmodule TestView do
    use Hyperbuffs.View
  end

  describe "use TestView" do
    test "render proto" do
      assert TestView.render("protobuf.proto", %{protobuf: Simple, params: %Simple{name: "Bob"}})
        == %{"encoded" => %Hyperbuffs.ViewTest.Simple{name: "Bob"}}
    end

    test "render json" do
      assert TestView.render("protobuf.json", %{protobuf: Simple, params: %Simple{name: "Bob"}})
        == %{name: "Bob"}
    end
  end
end