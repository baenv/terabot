defmodule WebDashboard.ErrorView do
  use Phoenix.Component

  # By default, Phoenix returns the status message from
  # the template name. For example, "404.html" becomes
  # "Not Found".
  def render(template, _assigns) do
    case template do
      "404.html" -> "Not Found - The page you were looking for doesn't exist."
      "500.html" -> "Server Error - Sorry, something went wrong on our end."
      _ -> Phoenix.Controller.status_message_from_template(template)
    end
  end

  # JSON error handling
  def render("404.json", _assigns) do
    %{errors: %{detail: "Not Found"}}
  end

  def render("500.json", _assigns) do
    %{errors: %{detail: "Internal Server Error"}}
  end
end
