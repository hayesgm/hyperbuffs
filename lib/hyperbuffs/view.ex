defmodule HyperBuffs.View do

  def render("proto", definition, params) do
    proto = struct(definition, Map.delete(params, :__struct__))
    definition.encode(proto)
  end

  def render("json", definition, params) do
    # Build proto so we can eliminate keys
    # TODO: There's probably a faster way of doing this
    proto = struct(definition, Map.delete(params, :__struct__))

    Map.delete(proto, :__struct__)
  end

  @doc """
  Defines stub view methods for each of the `defs` passed
  in. As our proto objects define the view templates themselves,
  this is a convenience method for generating the JSON and Proto
  views.

  Example:

  ```elixir
  def MyView do
    use HyperBuffs.View
  end
  ```
  """
  defmacro __using__(opts) do
    quote do
      def render("protobuf." <> format, %{protobuf: protobuf, params: params}) do
        HyperBuffs.View.render(format, protobuf, params)
      end
    end
  end

end