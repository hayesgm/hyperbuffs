defmodule HyperBuffs.View do

  @doc """
  Defines stub view methods for each of the `defs` passed
  in. As our proto objects define the view templates themselves,
  this is a convenience method for generating the JSON and Proto
  views.

  # TODO: Add test cases for service defs

  Example:

  ```elixir
  def MyView do
    use HyperBuffs.View, defs: [Defs.MyProto], service: Defs.ExampleService
  end
  ```

  ```elixir
  def MyView do
    use HyperBuffs.View, services: [Defs.ExampleService1, Defs.ExampleService2]
  end
  ```
  """
  defmacro __using__(opts) do
    IO.inspect(["opts", opts])
    services = case Keyword.get(opts, :service) do
      nil -> []
      service -> [service]
    end ++ Keyword.get(opts, :services, [])

    IO.inspect(["Services", services])

    # Extract defs from rpc struct
    defs = for service <- services do
      quote bind_quoted: [service: service] do
        for {_name, _request, response, _opts} <- service.rpcs do
          case response do
            {:stream, response} -> response
            response -> response
          end
        end
      end
    end

    for definitions <- defs do
      quote bind_quoted: [definitions: definitions] do
        for definition <- definitions do
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

end