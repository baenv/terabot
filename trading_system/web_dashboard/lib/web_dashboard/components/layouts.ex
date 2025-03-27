defmodule WebDashboard.Layouts do
  @moduledoc """
  Provides layout components for the dashboard application.

  This module includes the main layout components used throughout the dashboard,
  including the app layout and root layout.
  """

  use Phoenix.Component

  # Add required imports
  import Phoenix.HTML
  import Phoenix.HTML.Form
  import Phoenix.LiveView.Helpers
  import Phoenix.Controller, only: [get_csrf_token: 0]
  import WebDashboard.Gettext

  alias Phoenix.LiveView.JS
  alias WebDashboard.CoreComponents

  # Define the path sigil
  def sigil_p(path, _opts) do
    path = if is_binary(path), do: String.trim(path, "/"), else: path
    "/#{path}"
  end

  # Embed all layouts in this folder for use with root/1, app/1, etc
  Phoenix.Template.embed_templates "layouts/*"

  @doc """
  Renders the app layout which displays flash messages.

  ## Example
      <.app_layout flash={@flash}>
        <%= @inner_content %>
      </.app_layout>
  """
  attr :flash, :map, default: %{}
  slot :inner_block, required: true

  def app_layout(assigns) do
    ~H"""
    <div class="relative">
      <CoreComponents.flash flash={@flash} id="flash" />
      <%= render_slot(@inner_block) %>
    </div>
    """
  end

  @doc """
  Renders the root layout with navigation sidebar, search, and main content area.

  ## Example
      <.root_layout current_page="dashboard">
        <div>Main content goes here</div>
      </.root_layout>
  """
  attr :current_page, :string, default: nil
  slot :inner_block, required: true

  def root_layout(assigns) do
    ~H"""
    <div class="flex h-screen overflow-hidden bg-gray-100">
      <!-- Sidebar -->
      <div class="hidden md:flex md:flex-shrink-0">
        <div class="flex flex-col w-64">
          <div class="flex flex-col flex-1 min-h-0 bg-gray-800">
            <div class="flex items-center h-16 flex-shrink-0 px-4 bg-gray-900">
              <div class="text-white text-xl font-semibold">Terabot Trading</div>
            </div>
            <div class="flex flex-col flex-1 overflow-y-auto">
              <nav class="flex-1 px-2 py-4 space-y-1">
                <%= nav_link("Dashboard", "/", @current_page == "dashboard") %>
                <%= nav_link("Accounts", "/accounts", @current_page == "accounts") %>
                <%= nav_link("Transactions", "/transactions", @current_page == "transactions") %>
                <%= nav_link("Portfolio", "/portfolio", @current_page == "portfolio") %>
                <%= nav_link("Orders", "/orders", @current_page == "orders") %>
                <%= nav_link("Wallets", "/wallets", @current_page == "wallets") %>
              </nav>
            </div>
          </div>
        </div>
      </div>

      <!-- Main content -->
      <div class="flex flex-col flex-1 overflow-hidden">
        <!-- Top navigation -->
        <div class="bg-white shadow-sm z-10">
          <div class="px-4 sm:px-6 lg:px-8">
            <div class="flex justify-between h-16">
              <div class="flex">
                <div class="flex-shrink-0 flex items-center">
                  <!-- Mobile menu button -->
                  <button type="button" class="md:hidden inline-flex items-center justify-center p-2 rounded-md text-gray-400 hover:text-gray-500 hover:bg-gray-100 focus:outline-none focus:ring-2 focus:ring-inset focus:ring-indigo-500">
                    <span class="sr-only">Open main menu</span>
                    <!-- Icon when menu is closed -->
                    <svg class="block h-6 w-6" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke="currentColor" aria-hidden="true">
                      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 6h16M4 12h16M4 18h16" />
                    </svg>
                  </button>
                </div>
                <div class="hidden md:ml-6 md:flex md:items-center md:space-x-4">
                  <!-- Current: "border-indigo-500 text-gray-900", Default: "border-transparent text-gray-500 hover:border-gray-300 hover:text-gray-700" -->
                  <div class="text-gray-900 inline-flex items-center px-1 pt-1 border-b-2 border-indigo-500 text-sm font-medium">
                    <%= page_title(@current_page) %>
                  </div>
                </div>
              </div>
              <div class="flex items-center">
                <div class="flex-shrink-0">
                  <button type="button" class="relative inline-flex items-center px-4 py-2 border border-transparent text-sm font-medium rounded-md text-white bg-indigo-600 shadow-sm hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500">
                    <span>Sync Data</span>
                  </button>
                </div>
                <div class="ml-4 flex items-center md:ml-6">
                  <!-- Settings button -->
                  <button type="button" class="bg-white p-1 rounded-full text-gray-400 hover:text-gray-500 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500">
                    <span class="sr-only">Settings</span>
                    <svg class="h-6 w-6" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke="currentColor" aria-hidden="true">
                      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M10.325 4.317c.426-1.756 2.924-1.756 3.35 0a1.724 1.724 0 002.573 1.066c1.543-.94 3.31.826 2.37 2.37a1.724 1.724 0 001.065 2.572c1.756.426 1.756 2.924 0 3.35a1.724 1.724 0 00-1.066 2.573c.94 1.543-.826 3.31-2.37 2.37a1.724 1.724 0 00-2.572 1.065c-.426 1.756-2.924 1.756-3.35 0a1.724 1.724 0 00-2.573-1.066c-1.543.94-3.31-.826-2.37-2.37a1.724 1.724 0 00-1.065-2.572c-1.756-.426-1.756-2.924 0-3.35a1.724 1.724 0 001.066-2.573c-.94-1.543.826-3.31 2.37-2.37.996.608 2.296.07 2.572-1.065z" />
                      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 12a3 3 0 11-6 0 3 3 0 016 0z" />
                    </svg>
                  </button>
                </div>
              </div>
            </div>
          </div>
        </div>

        <!-- Main content area -->
        <main class="flex-1 relative overflow-y-auto focus:outline-none">
          <div class="py-6">
            <div class="max-w-7xl mx-auto px-4 sm:px-6 md:px-8">
              <%= render_slot(@inner_block) %>
            </div>
          </div>
        </main>
      </div>
    </div>
    """
  end

  # Helper functions

  defp nav_link(title, path, is_active) do
    class = if is_active do
      "bg-gray-900 text-white group flex items-center px-2 py-2 text-sm font-medium rounded-md"
    else
      "text-gray-300 hover:bg-gray-700 hover:text-white group flex items-center px-2 py-2 text-sm font-medium rounded-md"
    end

    assigns = %{title: title, path: path, class: class}

    ~H"""
    <a href={@path} class={@class}>
      <%= @title %>
    </a>
    """
  end

  defp page_title("dashboard"), do: "Dashboard"
  defp page_title("accounts"), do: "Accounts"
  defp page_title("transactions"), do: "Transactions"
  defp page_title("portfolio"), do: "Portfolio"
  defp page_title("orders"), do: "Orders"
  defp page_title("wallets"), do: "Wallets"
  defp page_title(_), do: "Terabot Trading System"
end
