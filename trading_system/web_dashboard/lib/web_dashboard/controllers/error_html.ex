defmodule WebDashboard.ErrorHTML do
  use Phoenix.Component

  # If you want to customize your error pages,
  # uncomment the embed_templates/1 call below
  # and add pages to the error directory:
  #
  # Note: The templates are already embedded at error_html/*
  embed_templates "error_html/*"

  # The default is to render a template named after the status code.
  # For example, "404.html" becomes the template that is rendered
  # when a 404 error occurs.
  def render(template, _assigns) when is_binary(template) do
    case template do
      "404" <> _ -> render("404", %{})
      "500" <> _ -> render("500", %{})
      _ -> Phoenix.Controller.status_message_from_template(template)
    end
  end

  # By default, Phoenix returns the status message from the
  # template name. For example, "404.html" becomes
  # "Not Found".
  def render("404", _assigns) do
    "Not Found"
  end

  def render("500", _assigns) do
    "Internal Server Error"
  end

  def render(template, _) when is_binary(template) do
    Phoenix.Controller.status_message_from_template(template)
  end
end
