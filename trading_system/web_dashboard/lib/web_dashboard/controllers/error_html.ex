defmodule WebDashboard.ErrorHTML do
  use Phoenix.Component

  # If you want to customize your error pages,
  # uncomment the embed_templates/1 call below
  # and add pages to the error directory:
  #
  #   * lib/web_dashboard/controllers/error_html/404.html.heex
  #   * lib/web_dashboard/controllers/error_html/500.html.heex
  #
  # embed_templates "error_html/*"

  # The default is to render a template named after the status code.
  # For example, a 404 error would render the template "404.html" in your app layout.
  # By default, Phoenix returns a generic "Internal Server Error" message.
  def render(template, _assigns) do
    Phoenix.Controller.status_message_from_template(template)
  end
end
