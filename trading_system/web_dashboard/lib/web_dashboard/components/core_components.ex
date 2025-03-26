defmodule WebDashboard.CoreComponents do
  @moduledoc """
  Core UI components for the WebDashboard.

  These components provide basic building blocks for the dashboard interface,
  including tables, cards, buttons, and form elements.
  """

  use Phoenix.Component
  alias Phoenix.LiveView.JS
  alias WebDashboard.Components.JSCommands

  @doc """
  Renders a table with headers and rows.

  ## Example
      <.table id="accounts" rows={@accounts}>
        <:col :let={account} label="Name"><%= account.name %></:col>
        <:col :let={account} label="Type"><%= account.type %></:col>
        <:col :let={account} label="Actions">
          <.button>View</.button>
        </:col>
      </.table>
  """
  attr :id, :string, required: true
  attr :rows, :list, required: true
  attr :class, :string, default: ""

  slot :col, required: true do
    attr :label, :string
    attr :class, :string
  end

  def table(assigns) do
    ~H"""
    <div class="overflow-y-auto px-4 sm:overflow-visible sm:px-0">
      <table class="w-[40rem] mt-11 sm:w-full">
        <thead class="text-sm text-left leading-6 text-zinc-500">
          <tr>
            <th :for={col <- @col} class={"p-0 pb-4 pr-6 font-normal #{col[:class]}"}>
              <%= col[:label] %>
            </th>
          </tr>
        </thead>
        <tbody class="relative divide-y divide-zinc-100 border-t border-zinc-200 text-sm leading-6 text-zinc-700">
          <tr :for={row <- @rows} id={"#{@id}-#{Phoenix.Param.to_param(row)}"} class="group hover:bg-zinc-50">
            <td :for={col <- @col} class={"relative p-0 py-4 pr-6 #{col[:class]}"}>
              <%= render_slot(col, row) %>
            </td>
          </tr>
        </tbody>
      </table>
    </div>
    """
  end

  @doc """
  Renders a header with title and optional subtitle.

  ## Example
      <.header>
        Dashboard
        <:subtitle>Real-time trading information</:subtitle>
      </.header>
  """
  slot :inner_block, required: true
  slot :subtitle

  def header(assigns) do
    ~H"""
    <header class="mb-6">
      <h1 class="text-lg font-semibold leading-8 text-zinc-800">
        <%= render_slot(@inner_block) %>
      </h1>
      <p :if={@subtitle} class="mt-2 text-sm leading-6 text-zinc-600">
        <%= render_slot(@subtitle) %>
      </p>
    </header>
    """
  end

  @doc """
  Renders a button.

  ## Example
      <.button>Send</.button>
      <.button phx-click="go" class="ml-2">Send</.button>
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
        "rounded-lg bg-zinc-900 px-3 py-2 hover:bg-zinc-700 text-sm font-semibold text-white active:text-white/80",
        @class
      ]}
      {@rest}
    >
      <%= render_slot(@inner_block) %>
    </button>
    """
  end

  @doc """
  Renders a modal dialog.

  ## Example
      <.modal id="confirm-modal">
        Are you sure?
        <:footer>
          <.button phx-click={JS.push("delete")} phx-value-id={@item.id}>
            Delete
          </.button>
        </:footer>
      </.modal>
  """
  attr :id, :string, required: true
  attr :show, :boolean, default: false
  attr :class, :string, default: nil

  slot :inner_block, required: true
  slot :title
  slot :footer

  def modal(assigns) do
    ~H"""
    <div
      id={@id}
      phx-mounted={@show && show_modal(@id)}
      phx-remove={hide_modal(@id)}
      class="relative z-50 hidden"
    >
      <div id={"#{@id}-bg"} class="fixed inset-0 bg-zinc-50/90 transition-opacity" aria-hidden="true" />
      <div
        class="fixed inset-0 overflow-y-auto"
        aria-labelledby={"#{@id}-title"}
        aria-describedby={"#{@id}-description"}
        role="dialog"
        aria-modal="true"
        tabindex="0"
      >
        <div class="flex min-h-full items-center justify-center">
          <div class={"w-full max-w-3xl p-4 sm:p-6 lg:py-8 #{@class}"}>
            <.custom_focus_wrap
              id={"#{@id}-container"}
              phx-mounted={@show && custom_focus_first(to: "##{@id} [autofocus]")}
              phx-window-keydown={hide_modal(@id)}
              phx-key="escape"
              phx-click-away={hide_modal(@id)}
              class="shadow-zinc-700/10 ring-zinc-700/10 relative hidden rounded-2xl bg-white p-14 shadow-lg ring-1 transition"
            >
              <div class="absolute top-6 right-5">
                <button
                  phx-click={hide_modal(@id)}
                  type="button"
                  class="-m-3 flex-none p-3 opacity-20 hover:opacity-40"
                  aria-label="close"
                >
                  &times;
                </button>
              </div>
              <div id={"#{@id}-content"}>
                <header :if={@title != []}>
                  <h2 id={"#{@id}-title"} class="text-lg font-semibold leading-8 text-zinc-800">
                    <%= render_slot(@title) %>
                  </h2>
                </header>
                <div id={"#{@id}-description"} class="mt-2 text-sm leading-6 text-zinc-600">
                  <%= render_slot(@inner_block) %>
                </div>
                <div :if={@footer != []} class="mt-6 flex items-center justify-end gap-6">
                  <%= render_slot(@footer) %>
                </div>
              </div>
            </.custom_focus_wrap>
          </div>
        </div>
      </div>
    </div>
    """
  end

  # JS Commands to show/hide modal
  def show_modal(js \\ %{}, id) when is_binary(id) do
    js
    |> JS.show(to: "##{id}")
    |> JS.show(to: "##{id}-bg", transition: {"transition-all transform ease-out duration-300", "opacity-0", "opacity-100"})
    |> show_modal_content(id)
  end

  defp show_modal_content(js, id) do
    js
    |> JS.show(to: "##{id}-content", transition: {"transition-all transform ease-out duration-300", "opacity-0 translate-y-4", "opacity-100 translate-y-0"})
  end

  def hide_modal(js \\ %{}, id) do
    js
    |> JS.hide(to: "##{id}-bg", transition: {"transition-all transform ease-in duration-200", "opacity-100", "opacity-0"})
    |> hide_modal_content(id)
  end

  defp hide_modal_content(js, id) do
    js
    |> JS.hide(to: "##{id}-content", transition: {"transition-all transform ease-in duration-200", "opacity-100 translate-y-0", "opacity-0 translate-y-4"})
    |> JS.hide(to: "##{id}", transition: {"block", "block", "hidden"})
  end

  @doc """
  Focuses the first element within a container.
  """
  def custom_focus_first(js \\ %{}, opts) do
    JS.dispatch(js, "focus-first", to: opts[:to])
  end

  @doc """
  A focus wrapper for handling modal content.
  """
  attr :id, :string, required: true
  attr :class, :string, default: nil
  attr :rest, :global

  slot :inner_block, required: true

  def custom_focus_wrap(assigns) do
    ~H"""
    <div id={@id} class={@class} tabindex="0" {@rest}>
      <%= render_slot(@inner_block) %>
    </div>
    """
  end

  @doc """
  Renders a flash notice.

  ## Examples
      <.flash kind={:info} flash={@flash} />
      <.flash kind={:info} phx-mounted={show("#flash")}>Welcome Back!</.flash>
  """
  attr :id, :string, default: "flash"
  attr :flash, :map, default: %{}
  attr :title, :string
  attr :kind, :atom, values: [:info, :error], default: :info
  attr :rest, :global

  slot :inner_block, required: false

  def flash(assigns) do
    ~H"""
    <div
      id={@id}
      role="alert"
      class={[
        "fixed top-2 right-2 w-80 sm:w-96 z-50 rounded-lg p-3 ring-1",
        @kind == :info && "bg-emerald-50 text-emerald-800 ring-emerald-500 fill-emerald-900",
        @kind == :error && "bg-rose-50 text-rose-900 shadow-md ring-rose-500 fill-rose-900"
      ]}
      {@rest}
    >
      <p :if={@title} class="flex items-center gap-1.5 text-sm font-semibold leading-6">
        <%= @title %>
      </p>
      <p class="mt-2 text-sm leading-5"><%= render_slot(@inner_block) || Phoenix.Flash.get(@flash, @kind) %></p>
      <button
        type="button"
        class="group absolute top-1 right-1 p-2"
        aria-label="close"
        phx-click={JS.push("lv:clear-flash") |> JS.remove_class("fade-in", to: "##{@id}") |> JSCommands.hide("##{@id}")}
      >
        &times;
      </button>
    </div>
    """
  end

  @doc """
  Renders a simple form.

  ## Examples
      <.simple_form for={@form} phx-change="validate" phx-submit="save">
        <.input field={@form[:name]} label="Name" />
        <:actions>
          <.button>Save</.button>
        </:actions>
      </.simple_form>
  """
  attr :for, :any, required: true
  attr :as, :any, default: nil
  attr :rest, :global, include: ~w(autocomplete)

  slot :inner_block, required: true
  slot :actions, doc: "the slot for form actions"

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
  Renders an error message.
  """
  slot :inner_block, required: true

  def error(assigns) do
    ~H"""
    <p class="mt-3 flex gap-3 text-sm leading-6 text-rose-600 phx-no-feedback:hidden">
      <%= render_slot(@inner_block) %>
    </p>
    """
  end

  @doc """
  Renders a card component.

  ## Example
      <.card title="Portfolio Overview">
        <p>Total Value: $10,000</p>
      </.card>
  """
  attr :class, :string, default: nil
  attr :title, :string, required: true

  slot :inner_block, required: true
  slot :actions

  def card(assigns) do
    ~H"""
    <div class={["bg-white rounded-lg shadow-md p-6", @class]}>
      <div class="flex justify-between items-center mb-4">
        <h3 class="text-lg font-semibold text-gray-900"><%= @title %></h3>
        <div class="flex space-x-2">
          <%= render_slot(@actions) %>
        </div>
      </div>
      <div>
        <%= render_slot(@inner_block) %>
      </div>
    </div>
    """
  end

  @doc """
  Renders a stat card with value, label, and optional change indicator.

  ## Example
      <.stat_card value="$45,231" label="Total Revenue" change="+2.5%" />
  """
  attr :value, :string, required: true
  attr :label, :string, required: true
  attr :change, :string, default: nil
  attr :change_type, :atom, values: [:positive, :negative, :neutral], default: :neutral
  attr :class, :string, default: nil

  def stat_card(assigns) do
    ~H"""
    <div class={["bg-white rounded-lg shadow-sm p-6", @class]}>
      <p class="text-sm font-medium text-gray-500 truncate"><%= @label %></p>
      <p class="mt-1 text-3xl font-semibold text-gray-900"><%= @value %></p>
      <%= if @change do %>
        <div class="flex items-center mt-2">
          <span class={[
            "text-sm font-medium",
            @change_type == :positive && "text-green-600",
            @change_type == :negative && "text-red-600",
            @change_type == :neutral && "text-gray-500"
          ]}>
            <%= @change %>
          </span>
        </div>
      <% end %>
    </div>
    """
  end
end
