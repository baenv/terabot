defmodule TradingSystemMain.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    # Start the simple health check server in a separate process
    spawn(fn -> start_health_check_server() end)

    children = [
      # Add your supervised children here
      # {TradingSystemMain.Worker, arg}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: TradingSystemMain.Supervisor]
    Supervisor.start_link(children, opts)
  end
  
  # Simple health check server implementation
  defp start_health_check_server do
    port = String.to_integer(System.get_env("PORT") || "4000")
    {:ok, socket} = :gen_tcp.listen(port, [:binary, active: false, reuseaddr: true])
    IO.puts("Health check API server started on port #{port}")
    accept_connections(socket)
  end
  
  defp accept_connections(socket) do
    {:ok, client} = :gen_tcp.accept(socket)
    spawn(fn -> handle_client(client) end)
    accept_connections(socket)
  end
  
  defp handle_client(client) do
    case :gen_tcp.recv(client, 0, 30000) do
      {:ok, request} ->
        {path, _headers} = parse_request(request)
        response = handle_request(path)
        :gen_tcp.send(client, response)
        :gen_tcp.close(client)
      {:error, _reason} ->
        :gen_tcp.close(client)
    end
  end
  
  defp parse_request(request) do
    [request_line | headers] = String.split(request, "\r\n")
    ["GET", path | _] = String.split(request_line, " ")
    {path, headers}
  end
  
  defp handle_request(path) do
    case path do
      "/api/health" ->
        # Check all applications
        apps = [:core, :data_collector, :data_processor, :decision_engine, :order_manager, :portfolio_manager, :trading_system_main]
        health_data = check_all_apps(apps)
        json_response(200, health_data)
        
      "/api/health/" <> app_name ->
        # Check specific application
        app_atom = String.to_atom(app_name)
        health_data = check_app_health(app_atom)
        json_response(200, health_data)
        
      _ ->
        # Not found
        json_response(404, %{error: "Not found"})
    end
  end
  
  defp check_all_apps(apps) do
    app_statuses = Enum.map(apps, fn app -> {app, check_app_health(app)} end) |> Enum.into(%{})
    
    %{
      status: :ok,
      timestamp: DateTime.utc_now() |> DateTime.to_iso8601(),
      applications: app_statuses
    }
  end
  
  defp check_app_health(app) do
    # Check if application is running
    is_running = case :application.which_applications() do
      apps when is_list(apps) ->
        Enum.any?(apps, fn {name, _, _} -> name == app end)
      _ -> false
    end
    
    # For Core app, also check database connection
    db_status = if app == :core do
      try do
        # Only try to query if Core is actually running
        if is_running do
          Core.Repo.query!("SELECT 1")
          :ok
        else
          :not_available
        end
      rescue
        _ -> :error
      end
    else
      :not_applicable
    end
    
    # Get version as proper string
    version = case Application.spec(app, :vsn) do
      nil -> "unknown"
      vsn when is_list(vsn) -> List.to_string(vsn)
      vsn -> to_string(vsn)
    end
    
    %{
      status: if(is_running, do: :ok, else: :error),
      details: %{
        running: is_running,
        database: db_status,
        version: version
      }
    }
  end
  
  defp json_response(status_code, data) do
    json = encode_json(data)
    status_line = case status_code do
      200 -> "HTTP/1.1 200 OK\r\n"
      404 -> "HTTP/1.1 404 Not Found\r\n"
      _ -> "HTTP/1.1 500 Internal Server Error\r\n"
    end
    
    status_line <>
    "Content-Type: application/json\r\n" <>
    "Content-Length: #{byte_size(json)}\r\n" <>
    "\r\n" <>
    json
  end
  
  defp encode_json(data) when is_map(data) do
    pairs = for {k, v} <- data, do: "\"#{k}\": #{encode_json(v)}"
    "{#{Enum.join(pairs, ", ")}}" 
  end
  
  defp encode_json(data) when is_list(data) do
    items = Enum.map(data, &encode_json/1)
    "[#{Enum.join(items, ", ")}]"
  end
  
  defp encode_json(data) when is_atom(data) do
    case data do
      nil -> "null"
      true -> "true"
      false -> "false"
      _ -> "\"#{data}\""
    end
  end
  
  defp encode_json(data) when is_binary(data) do
    escaped = String.replace(data, "\"", "\\\"")
    "\"#{escaped}\""
  end
  
  defp encode_json(data) when is_number(data) do
    "#{data}"
  end
end
