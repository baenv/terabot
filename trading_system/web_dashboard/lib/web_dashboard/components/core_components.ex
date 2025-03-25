defmodule WebDashboard.CoreComponents do
  @moduledoc """
  Core UI components for the Terabot Trading System web dashboard.
  """
  use Phoenix.Component
  import Phoenix.HTML
  alias Phoenix.LiveView.JS

  @doc """
  Renders a table with generic styling.
  """
  attr :id, :string, required: true
  attr :rows, :list, required: true
  attr :row_id, :any, default: nil, doc: "the function for generating the row id"
  attr :row_click, :any, default: nil, doc: "the function for handling row clicks"
  attr :row_item, :any, default: &Function.identity/1, doc: "the function for mapping each row before calling the :col and :action slots"

  slot :col, required: true do
    attr :label, :string
    attr :class, :string
  end

  slot :action, doc: "the slot for showing user actions in the last table column"

  def table(assigns) do
    assigns =
      with %{rows: %Phoenix.LiveView.LiveStream{}} <- assigns do
        assign(assigns, row_id: assigns.row_id || fn {id, _item} -> id end)
      end

    ~H"""
    <div class="overflow-y-auto px-4 sm:overflow-visible sm:px-0">
      <table class="w-[40rem] mt-6 sm:w-full">
        <thead class="text-sm text-left leading-6 text-zinc-500">
          <tr>
            <th :for={col <- @col} class={["p-0 pb-4 pr-6 font-normal", col[:class]]}>
              <%= col[:label] %>
            </th>
            <th class="relative p-0 pb-4"><span class="sr-only">Actions</span></th>
          </tr>
        </thead>
        <tbody
          id={@id}
          phx-update={match?(%Phoenix.LiveView.LiveStream{}, @rows) && "stream"}
          class="relative divide-y divide-zinc-100 border-t border-zinc-200 text-sm leading-6 text-zinc-700"
        >
          <tr :for={row <- @rows} id={@row_id && @row_id.(row)} class="group hover:bg-zinc-50">
            <td
              :for={{col, i} <- Enum.with_index(@col)}
              phx-click={@row_click && @row_click.(row)}
              class={["relative p-0", i == 0 && "font-semibold text-zinc-900"]}
            >
              <div class="block py-4 pr-6">
                <span class="absolute -inset-y-px right-0 -left-4 group-hover:bg-zinc-50 sm:rounded-l-xl" />
                <span class={["relative", col[:class]]}>
                  <%= render_slot(col, @row_item.(row)) %>
                </span>
              </div>
            </td>
            <td :if={@action != []} class="relative w-14 p-0">
              <div class="relative whitespace-nowrap py-4 text-right text-sm font-medium">
                <span class="absolute -inset-y-px -right-4 left-0 group-hover:bg-zinc-50 sm:rounded-r-xl" />
                <span
                  :for={action <- @action}
                  class="relative ml-4 font-semibold leading-6 text-zinc-900 hover:text-zinc-700"
                >
                  <%= render_slot(action, @row_item.(row)) %>
                </span>
              </div>
            </td>
          </tr>
        </tbody>
      </table>
    </div>
    """
  end

  @doc """
  Renders a data list.
  """
  slot :inner_block, required: true
  slot :title, required: true
  slot :subtitle, required: true
  slot :actions

  def header(assigns) do
    ~H"""
    <header class="flex items-center justify-between gap-6">
      <div>
        <h1 class="text-lg font-semibold leading-8 text-zinc-800">
          <%= render_slot(@title) %>
        </h1>
        <p class="mt-2 text-sm leading-6 text-zinc-600">
          <%= render_slot(@subtitle) %>
        </p>
      </div>
      <div class="flex-none"><%= render_slot(@actions) %></div>
    </header>
    """
  end

  @doc """
  Renders a button.
  """
  attr :type, :string, default: nil
  attr :class, :string, default: nil
  attr :rest, :global, include: ~w(disabled form name value)

  slot :inner_block, required: true

  def button(assigns) do
    ~H"""
    <button
      type={@type}
      class={[
        "phx-submit-loading:opacity-75 rounded-lg bg-zinc-900 hover:bg-zinc-700 py-2 px-3",
        "text-sm font-semibold leading-6 text-white active:text-white/80",
        @class
      ]}
      {@rest}
    >
      <%= render_slot(@inner_block) %>
    </button>
    """
  end

  @doc """
  Renders a modal.
  """
  attr :id, :string, required: true
  attr :show, :boolean, default: false
  attr :on_cancel, JS, default: %JS{}
  slot :inner_block, required: true

  def modal(assigns) do
    ~H"""
    <div
      id={@id}
      phx-mounted={@show && show_modal(@id)}
      phx-remove={hide_modal(@id)}
      data-cancel={JS.exec(@on_cancel, "phx-remove")}
      class="relative z-50 hidden"
    >
      <div id={"#{@id}-bg"} class="bg-zinc-50/90 fixed inset-0 transition-opacity" aria-hidden="true" />
      <div
        class="fixed inset-0 overflow-y-auto"
        aria-labelledby={"#{@id}-title"}
        aria-describedby={"#{@id}-description"}
        role="dialog"
        aria-modal="true"
        tabindex="0"
      >
        <div class="flex min-h-full items-center justify-center">
          <div class="w-full max-w-3xl p-4 sm:p-6 lg:py-8">
            <.focus_wrap
              id={"#{@id}-container"}
              phx-window-keydown={JS.exec("data-cancel", to: "##{@id}")}
              phx-key="escape"
              phx-click-away={JS.exec("data-cancel", to: "##{@id}")}
              class="shadow-zinc-700/10 ring-zinc-700/10 relative hidden rounded-2xl bg-white p-14 shadow-lg ring-1 transition"
            >
              <div class="absolute top-6 right-5">
                <button
                  phx-click={JS.exec("data-cancel", to: "##{@id}")}
                  type="button"
                  class="-m-3 flex-none p-3 opacity-20 hover:opacity-40"
                  aria-label="close"
                >
                  <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor" class="h-5 w-5">
                    <path stroke-linecap="round" stroke-linejoin="round" d="M6 18L18 6M6 6l12 12" />
                  </svg>
                </button>
              </div>
              <%= render_slot(@inner_block) %>
            </.focus_wrap>
          </div>
        </div>
      </div>
    </div>
    """
  end

  defp show_modal(js \\ %JS{}, id) do
    js
    |> JS.show(to: "##{id}")
    |> JS.show(
      to: "##{id}-bg",
      transition: {"transition-all transform ease-out duration-300", "opacity-0", "opacity-100"}
    )
    |> show_modal_content(id)
  end

  defp show_modal_content(js \\ %JS{}, id) do
    js
    |> JS.show(
      to: "##{id}-container",
      transition: {"transition-all transform ease-out duration-300", "opacity-0 translate-y-4 sm:translate-y-0 sm:scale-95", "opacity-100 translate-y-0 sm:scale-100"}
    )
    |> JS.add_class("overflow-hidden", to: "body")
    |> JS.focus_first(to: "##{id}-content")
  end

  defp hide_modal(js \\ %JS{}, id) do
    js
    |> JS.hide(
      to: "##{id}-bg",
      transition: {"transition-all transform ease-in duration-200", "opacity-100", "opacity-0"}
    )
    |> JS.hide(
      to: "##{id}-container",
      transition: {"transition-all transform ease-in duration-200", "opacity-100 translate-y-0 sm:scale-100", "opacity-0 translate-y-4 sm:translate-y-0 sm:scale-95"}
    )
    |> JS.hide(to: "##{id}", transition: {"block", "block", "hidden"})
    |> JS.remove_class("overflow-hidden", to: "body")
    |> JS.pop_focus()
  end

  @doc """
  Renders flash notices.
  """
  attr :flash, :map, required: true
  attr :kind, :atom, values: [:info, :error], doc: "used for styling"
  attr :rest, :global, doc: "the arbitrary HTML attributes to add to the flash container"

  slot :inner_block, doc: "the optional inner block that renders the flash message"

  def flash(assigns) do
    ~H"""
    <div
      :if={msg = render_slot(@inner_block) || Phoenix.Flash.get(@flash, @kind)}
      id="flash"
      class={[
        "fixed top-2 right-2 w-80 sm:w-96 z-50 rounded-lg p-3 ring-1",
        @kind == :info && "bg-emerald-50 text-emerald-800 ring-emerald-500 fill-cyan-900",
        @kind == :error && "bg-rose-50 text-rose-900 shadow-md ring-rose-500 fill-rose-900"
      ]}
      role="alert"
      phx-click={JS.push("lv:clear-flash", value: %{key: @kind}) |> JS.remove_class("fade-in-scale")}
      phx-hook="Flash"
      {@rest}
    >
      <p class="flex items-center gap-1.5 text-sm font-semibold leading-6">
        <svg :if={@kind == :info} class="h-4 w-4" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor">
          <path stroke-linecap="round" stroke-linejoin="round" d="M9 12.75L11.25 15 15 9.75M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
        </svg>
        <svg :if={@kind == :error} class="h-4 w-4" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor">
          <path stroke-linecap="round" stroke-linejoin="round" d="M12 9v3.75m9-.75a9 9 0 11-18 0 9 9 0 0118 0zm-9 3.75h.008v.008H12v-.008z" />
        </svg>
        <%= msg %>
      </p>
    </div>
    """
  end

  @doc """
  Renders a simple form.
  """
  attr :for, :any, required: true, doc: "the datastructure for the form"
  attr :as, :any, default: nil, doc: "the server side parameter to collect all input under"
  attr :rest, :global, include: ~w(autocomplete name rel action enctype method novalidate target multipart)
  slot :inner_block, required: true
  slot :actions, doc: "the slot for form actions, such as a submit button"

  def simple_form(assigns) do
    ~H"""
    <.form :let={f} for={@for} as={@as} {@rest}>
      <div class="mt-10 space-y-8 bg-white">
        <%= render_slot(@inner_block, f) %>
        <div :for={action <- @actions} class="mt-2 flex items-center justify-between gap-6">
          <%= render_slot(action, f) %>
        </div>
      </div>
    </.form>
    """
  end

  @doc """
  Renders a label.
  """
  attr :for, :string, default: nil
  slot :inner_block, required: true

  def label(assigns) do
    ~H"""
    <label for={@for} class="block text-sm font-semibold leading-6 text-zinc-800">
      <%= render_slot(@inner_block) %>
    </label>
    """
  end

  @doc """
  Generates a generic error message.
  """
  slot :inner_block, required: true

  def error(assigns) do
    ~H"""
    <p class="mt-3 flex gap-3 text-sm leading-6 text-rose-600 phx-no-feedback:hidden">
      <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="currentColor" class="h-5 w-5 flex-none">
        <path
          fill-rule="evenodd"
          d="M2.25 12c0-5.385 4.365-9.75 9.75-9.75s9.75 4.365 9.75 9.75-4.365 9.75-9.75 9.75S2.25 17.385 2.25 12zm8.706-1.442c1.146-.573 2.437.463 2.126 1.706l-.709 2.836.042-.02a.75.75 0 01.67 1.34l-.04.022c-1.147.573-2.438-.463-2.127-1.706l.71-2.836-.042.02a.75.75 0 11-.671-1.34l.041-.022z"
          clip-rule="evenodd"
        />
      </svg>
      <%= render_slot(@inner_block) %>
    </p>
    """
  end

  @doc """
  Renders a flash group with standard styling.
  """
  attr :flash, :map, required: true

  def flash_group(assigns) do
    ~H"""
    <.flash kind={:info} flash={@flash} />
    <.flash kind={:error} flash={@flash} />
    """
  end

  @doc """
  Renders a card component.
  """
  attr :class, :string, default: nil
  slot :inner_block, required: true
  slot :title
  slot :subtitle
  slot :actions

  def card(assigns) do
    ~H"""
    <div class={["bg-white shadow rounded-lg p-6", @class]}>
      <div :if={@title != [] or @subtitle != [] or @actions != []} class="flex items-center justify-between mb-4">
        <div>
          <h3 :if={@title != []} class="text-lg font-medium text-gray-900">
            <%= render_slot(@title) %>
          </h3>
          <p :if={@subtitle != []} class="mt-1 text-sm text-gray-500">
            <%= render_slot(@subtitle) %>
          </p>
        </div>
        <div :if={@actions != []} class="flex-shrink-0">
          <%= render_slot(@actions) %>
        </div>
      </div>
      <%= render_slot(@inner_block) %>
    </div>
    """
  end

  @doc """
  Renders a stat card for dashboard metrics.
  """
  attr :label, :string, required: true
  attr :value, :string, required: true
  attr :change, :string, default: nil
  attr :change_type, :string, default: "neutral", values: ["increase", "decrease", "neutral"]
  attr :icon, :string, default: nil
  attr :class, :string, default: nil

  def stat_card(assigns) do
    ~H"""
    <div class={["bg-white overflow-hidden shadow rounded-lg", @class]}>
      <div class="p-5">
        <div class="flex items-center">
          <div class="flex-shrink-0">
            <div :if={@icon} class="flex items-center justify-center h-12 w-12 rounded-md bg-indigo-500 text-white">
              <span class="text-xl"><%= @icon %></span>
            </div>
          </div>
          <div class={["ml-5", !@icon && "ml-0"]}>
            <dl>
              <dt class="text-sm font-medium text-gray-500 truncate">
                <%= @label %>
              </dt>
              <dd class="mt-1 text-3xl font-semibold text-gray-900">
                <%= @value %>
              </dd>
            </dl>
          </div>
        </div>
      </div>
      <div :if={@change} class="bg-gray-50 px-5 py-3">
        <div class="text-sm">
          <span class={[
            "font-medium",
            @change_type == "increase" && "text-green-600",
            @change_type == "decrease" && "text-red-600",
            @change_type == "neutral" && "text-gray-500"
          ]}>
            <%= @change %>
          </span>
        </div>
      </div>
    </div>
    """
  end
end
