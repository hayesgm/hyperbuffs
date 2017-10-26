defmodule HyperBuffs.ViewTest do
  use ExUnit.Case, async: true

  defmodule Simple do
    defstruct [name: ""]

    def encode(simple) do
      %{"encoded" => simple}
    end
  end

  defmodule TestView do
    use HyperBuffs.View, defs: [Simple]
  end

  describe "use TestView" do
    test "render proto" do
      assert TestView.render("Elixir.HyperBuffs.ViewTest.Simple.proto", %Simple{name: "Bob"})
        == %{"encoded" => %HyperBuffs.ViewTest.Simple{name: "Bob"}}
    end

    test "render json" do
      assert TestView.render("Elixir.HyperBuffs.ViewTest.Simple.json", %Simple{name: "Bob"})
        == %{name: "Bob"}
    end
  end
end