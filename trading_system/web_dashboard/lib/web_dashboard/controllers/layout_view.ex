defmodule WebDashboard.LayoutView do
  use Phoenix.Component

  def render("app.html", assigns) do
    ~H"""
    <main>
      <%= render_slot(@inner_block) %>
    </main>
    """
  end
end
