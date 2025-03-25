defmodule WebDashboard.Router do
  @moduledoc """
  Simple HTTP router for the web dashboard.
  """

  @doc """
  Handles incoming HTTP requests and routes them to the appropriate handler.
  """
  def call(conn, _opts) do
    route(conn.method, conn.path_info, conn)
  end

  @doc """
  Plug initialization callback.
  """
  def init(opts), do: opts

  # Routes for different HTTP methods and paths
  defp route("GET", [], conn) do
    # Dashboard home page
    render_page(conn, "dashboard", %{
      page_title: "Dashboard"
    })
  end

  defp route("GET", ["accounts"], conn) do
    # Accounts page
    render_page(conn, "accounts", %{
      page_title: "Accounts"
    })
  end

  defp route("GET", ["accounts", id], conn) do
    # Account details page
    render_page(conn, "account_details", %{
      page_title: "Account Details"
    })
  end

  defp route("GET", ["transactions"], conn) do
    # Transactions page
    render_page(conn, "transactions", %{
      page_title: "Transactions"
    })
  end

  defp route("GET", ["portfolio"], conn) do
    # Portfolio page
    render_page(conn, "portfolio", %{
      page_title: "Portfolio"
    })
  end

  defp route("GET", ["performance"], conn) do
    # Performance metrics page
    render_page(conn, "performance", %{
      page_title: "Performance Metrics"
    })
  end

  defp route("GET", ["wallets"], conn) do
    # Wallets page
    render_page(conn, "wallets", %{
      page_title: "Wallet Management"
    })
  end

  defp route("POST", ["wallets", "register"], conn) do
    # Simplified wallet registration without actual implementation
    conn
    |> put_resp_header("location", "/wallets")
    |> put_resp_content_type("text/html")
    |> send_resp(302, "")
  end

  # API endpoints
  defp route("GET", ["api", "accounts"], conn) do
    # Return mock accounts data
    send_json_resp(conn, 200, [])
  end

  defp route("GET", ["api", "accounts", id], conn) do
    # Return mock account data
    send_json_resp(conn, 200, %{id: id, name: "Mock Account"})
  end

  defp route("GET", ["api", "transactions"], conn) do
    # Return mock transactions data
    send_json_resp(conn, 200, [])
  end

  defp route("GET", ["api", "balances"], conn) do
    # Return mock balances data
    send_json_resp(conn, 200, [])
  end

  defp route("GET", ["api", "performance", "roi"], conn) do
    # Get ROI data from PortfolioManager.API
    period = Map.get(conn.query_params, "period", "monthly")
    period_atom = String.to_existing_atom(period)

    case PortfolioManager.API.calculate_roi(period_atom) do
      {:ok, roi} -> send_json_resp(conn, 200, %{period: period, roi: roi})
      {:error, reason} -> send_json_resp(conn, 500, %{error: reason})
    end
  end

  defp route("GET", ["api", "performance", "volatility"], conn) do
    # Get volatility data from PortfolioManager.API
    period = Map.get(conn.query_params, "period", "monthly")
    period_atom = String.to_existing_atom(period)

    case PortfolioManager.API.calculate_volatility(period_atom) do
      {:ok, volatility} -> send_json_resp(conn, 200, %{period: period, volatility: volatility})
      {:error, reason} -> send_json_resp(conn, 500, %{error: reason})
    end
  end

  defp route("GET", ["api", "performance", "sharpe"], conn) do
    # Get Sharpe ratio data from PortfolioManager.API
    period = Map.get(conn.query_params, "period", "monthly")
    period_atom = String.to_existing_atom(period)

    case PortfolioManager.API.calculate_sharpe_ratio(period_atom) do
      {:ok, sharpe} -> send_json_resp(conn, 200, %{period: period, sharpe_ratio: sharpe})
      {:error, reason} -> send_json_resp(conn, 500, %{error: reason})
    end
  end

  defp route("GET", ["api", "performance", "drawdown"], conn) do
    # Get maximum drawdown data from PortfolioManager.API
    period = Map.get(conn.query_params, "period", "monthly")
    period_atom = String.to_existing_atom(period)

    case PortfolioManager.API.calculate_max_drawdown(period_atom) do
      {:ok, drawdown} -> send_json_resp(conn, 200, %{period: period, max_drawdown: drawdown})
      {:error, reason} -> send_json_resp(conn, 500, %{error: reason})
    end
  end

  defp route("GET", ["api", "performance", "allocation"], conn) do
    # Get asset allocation data from PortfolioManager.API
    case PortfolioManager.API.calculate_asset_allocation() do
      {:ok, allocation} -> send_json_resp(conn, 200, allocation)
      {:error, reason} -> send_json_resp(conn, 500, %{error: reason})
    end
  end

  defp route("GET", ["api", "performance", "report"], conn) do
    # Get comprehensive performance report from PortfolioManager.API
    period = Map.get(conn.query_params, "period", "monthly")
    period_atom = String.to_existing_atom(period)

    case PortfolioManager.API.generate_performance_report(period_atom) do
      {:ok, report} -> send_json_resp(conn, 200, report)
      {:error, reason} -> send_json_resp(conn, 500, %{error: reason})
    end
  end

  defp route("GET", ["static", file], conn) do
    # Static files (CSS, JS)
    file_path = Path.join(["priv", "static", file])
    content_type = get_content_type(file)

    if File.exists?(file_path) do
      conn
      |> put_resp_header("content-type", content_type)
      |> send_file(200, file_path)
    else
      send_resp(conn, 404, "File not found")
    end
  end

  # Catch-all route
  defp route(_method, _path, conn) do
    send_resp(conn, 404, "Not found")
  end

  # Helper functions
  defp render_page(conn, template, assigns) do
    content = WebDashboard.Templates.render(template, assigns)
    layout = WebDashboard.Templates.render_layout(content, assigns)

    conn
    |> put_resp_header("content-type", "text/html; charset=utf-8")
    |> send_resp(200, layout)
  end

  defp send_json_resp(conn, status, data) do
    # Simple JSON encoding without relying on Jason
    json_string = simple_json_encode(data)

    conn
    |> put_resp_header("content-type", "application/json; charset=utf-8")
    |> send_resp(status, json_string)
  end

  # Simple JSON encoder for basic data types
  defp simple_json_encode(data) when is_map(data) do
    pairs =
      for {key, value} <- data do
        "\"#{key}\":#{simple_json_encode(value)}"
      end

    "{#{Enum.join(pairs, ",")}}"
  end

  defp simple_json_encode(data) when is_list(data) do
    "[#{Enum.map_join(data, ",", &simple_json_encode/1)}]"
  end

  defp simple_json_encode(data) when is_binary(data),
    do: "\"#{String.replace(data, "\"", "\\\"")}\""

  defp simple_json_encode(data) when is_number(data), do: "#{data}"
  defp simple_json_encode(true), do: "true"
  defp simple_json_encode(false), do: "false"
  defp simple_json_encode(nil), do: "null"

  defp get_content_type(file) do
    case Path.extname(file) do
      ".css" -> "text/css"
      ".js" -> "application/javascript"
      ".png" -> "image/png"
      ".jpg" -> "image/jpeg"
      ".svg" -> "image/svg+xml"
      _ -> "text/plain"
    end
  end

  # HTTP response helpers
  defp put_resp_header(conn, key, value) do
    headers = Map.get(conn, :resp_headers, [])
    Map.put(conn, :resp_headers, [{key, value} | headers])
  end

  defp put_resp_content_type(conn, content_type) do
    put_resp_header(conn, "content-type", content_type)
  end

  defp send_resp(conn, status, body) do
    conn
    |> Map.put(:status, status)
    |> Map.put(:resp_body, body)
  end

  defp send_file(conn, status, path) do
    body = File.read!(path)
    send_resp(conn, status, body)
  end
end
