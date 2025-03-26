defmodule WebDashboard.Components.JSCommands do
  alias Phoenix.LiveView.JS

  @doc """
  Hides the element identified by the given selector.
  """
  def hide(js \\ %{}, selector) do
    JS.hide(js, to: selector)
  end
end
