defmodule HyperBuffs.Router do

  @doc """
  Adds a new router function `service` which allows you to specify that
  a given service should be routed for. That service must either include
  its own path definitions (e.g. post: "/v1/route"), or that must be included
  in the options passed to `service`.

  TODO: Routes for multiple services??
  """
  defmacro __using__(_opts) do
    quote do
      import HyperBuffs.Router, only: [service: 2, service: 3]
    end
  end

  @doc """
  Give a service, returns a list of routes.

  ## Examples

      iex> HyperBuffs.Router.get_routes_for_service(ExampleService, [])
      [
        {:post, "/my/path", ExampleRequest, ExampleRequest, []},
        {:get, "/other/path", ExampleRequest, ExampleRequest, []}
      ]
  """
  def get_routes_for_service(service, opts) do
    for rpc <- service.rpcs do
      {name, request, response, service_opts} = rpc |> IO.inspect

      request = case request do
        {:stream, request} -> raise "Streaming is not currently supported"
        _ -> request
      end

      response = case response do
        {:stream, response} -> raise "Streaming is not currently supported"
        _ -> response
      end

      pattern = Enum.find(service_opts ++ opts, fn {k, v} ->
        Enum.member?([:get, :put, :post, :delete, :patch], k)
      end)

      case pattern do
        nil -> raise "Service or router definition must include keyword for action, one of: :get, :put, :post, :delete, :patch"
        {action, path} ->
          {action, name, path, request, response}
      end
    end
  end

  defmacro generate_route(action, name, path, request, response, controller) do
    quote bind_quoted: [request: request, response: response, action: action, name: name, path: path, controller: controller] do
      match(action, path, controller, name, private: %{req: request, resp: response})
    end
  end

  defmacro service(controller, service, opts \\ []) do
    quote do
      routes = HyperBuffs.Router.get_routes_for_service(unquote(service), unquote(opts))

      for {action, name, path, request, response} <- routes do
        HyperBuffs.Router.generate_route(action, name, path, request, response, unquote(controller))
      end
    end
  end

end