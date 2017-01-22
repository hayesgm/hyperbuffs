defmodule HyperBuffs.View do

  @doc """
  Defines stub view methods for each of the `defs` passed
  in. As our proto objects define the view templates themselves,
  this is a convenience method for generating the JSON and Proto
  views.

  Example:

  ```elixir
  def MyView do
    use HyperBuffs.View, defs: [Defs.MyProto]
  end
  ```
  """
  defmacro __using__(opts) do
    for definition <- opts[:defs] do
      quote bind_quoted: [definition: definition] do
        def render(unquote("#{to_string(definition)}.proto"), params) do
          proto = struct(unquote(definition), Map.delete(params, :__struct__))
          unquote(definition).encode(proto)
        end

        def render(unquote("#{to_string(definition)}.json"), params) do
          # Build proto so we can eliminate keys
          # TODO: There's probably a faster way of doing this
          proto = struct(unquote(definition), Map.delete(params, :__struct__))

          Map.delete(proto, :__struct__)
        end
      end
    end
  end

end