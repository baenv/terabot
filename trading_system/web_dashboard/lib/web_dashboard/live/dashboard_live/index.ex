defmodule WebDashboard.DashboardLive.Index do
  use Phoenix.LiveView

  def mount(_params, _session, socket) do
    {:ok, socket |> assign(:page_title, "Dashboard")}
  end
end
