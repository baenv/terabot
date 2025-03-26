defmodule WebDashboard.Router do
  use Plug.Router

  plug :match
  plug :dispatch
  plug Plug.Parsers, parsers: [:json],
                    pass: ["application/json"],
                    json_decoder: Jason

  get "/" do
    conn
    |> put_resp_content_type("text/html")
    |> send_resp(200, """
    <!DOCTYPE html>
    <html>
      <head>
        <title>Terabot Trading Dashboard</title>
        <style>
          body { font-family: Arial, sans-serif; padding: 20px; }
          h1 { color: #333; }
        </style>
      </head>
      <body>
        <h1>Terabot Trading Dashboard</h1>
        <p>Welcome to the simplified trading dashboard.</p>
      </body>
    </html>
    """)
  end

  get "/api/status" do
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, Jason.encode!(%{status: "running"}))
  end

  match _ do
    send_resp(conn, 404, "Not found")
  end
end
