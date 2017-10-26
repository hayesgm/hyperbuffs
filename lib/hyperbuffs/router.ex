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

  def service(controller, service, opts \\ []) do
    for rpc <- service.rpcs do
      {name, request, response, service_opts} = service

      request = case request do
        {:stream, request} -> raise "Streaming is not currently supported"
        _ -> request
      end

      response = case response do
        {:stream, response} -> raise "Streaming is not currently supported"
        _ -> response
      end

      pattern = Enum.find(service_opts ++ opts, fn {k, v} ->
        Enum.member?(k, [:get, :put, :post, :delete, :patch])
      end)

      case pattern do
        nil -> raise "Service or router definition must include keyword for action, one of: :get, :put, :post, :delete, :patch"
        {action, path} ->
          apply(action, controller, private: %{req: request, resp: response})
      end
    end
  end

end