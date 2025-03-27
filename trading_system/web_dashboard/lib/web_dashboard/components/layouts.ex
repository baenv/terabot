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
    <!DOCTYPE html>
    <html lang="en" class="h-full bg-gray-100">
      <head>
        <meta charset="utf-8" />
        <meta name="viewport" content="width=device-width, initial-scale=1" />
        <meta name="csrf-token" content={Phoenix.Controller.get_csrf_token()} />
        <title>Terabot Trading System - <%= assigns[:page_title] || "Dashboard" %></title>
        <link rel="stylesheet" href="/assets/app.css" />
        <script defer type="text/javascript" src="/assets/app.js"></script>
      </head>
      <body class="h-full font-sans antialiased">
        <div class="flex h-screen overflow-hidden">
          <!-- Sidebar -->
          <div class="hidden md:flex md:w-64 md:flex-col">
            <div class="flex flex-col flex-grow pt-5 overflow-y-auto bg-gray-900">
              <div class="flex items-center flex-shrink-0 px-4">
                <span class="text-xl font-semibold text-white">Terabot Trading</span>
              </div>
              <div class="mt-5 flex-1 flex flex-col">
                <nav class="flex-1 px-2 space-y-1">
                  <a href="/" class="group flex items-center px-2 py-2 text-sm font-medium rounded-md text-white bg-gray-800">
                    Dashboard
                  </a>
                  <a href="/accounts" class="group flex items-center px-2 py-2 text-sm font-medium rounded-md text-gray-300 hover:bg-gray-700 hover:text-white">
                    Accounts
                  </a>
                  <a href="/transactions" class="group flex items-center px-2 py-2 text-sm font-medium rounded-md text-gray-300 hover:bg-gray-700 hover:text-white">
                    Transactions
                  </a>
                  <a href="/portfolio" class="group flex items-center px-2 py-2 text-sm font-medium rounded-md text-gray-300 hover:bg-gray-700 hover:text-white">
                    Portfolio
                  </a>
                  <a href="/orders" class="group flex items-center px-2 py-2 text-sm font-medium rounded-md text-gray-300 hover:bg-gray-700 hover:text-white">
                    Orders
                  </a>
                  <a href="/wallets" class="group flex items-center px-2 py-2 text-sm font-medium rounded-md text-gray-300 hover:bg-gray-700 hover:text-white">
                    Wallets
                  </a>
                </nav>
              </div>
            </div>
          </div>

          <!-- Main content -->
          <div class="flex flex-col flex-1 overflow-hidden">
            <!-- Top navigation bar -->
            <div class="relative z-10 flex-shrink-0 flex h-16 bg-white shadow">
              <button type="button" class="px-4 border-r border-gray-200 text-gray-500 focus:outline-none focus:ring-2 focus:ring-inset focus:ring-indigo-500 md:hidden">
                <span class="sr-only">Open sidebar</span>
                <svg class="h-6 w-6" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke="currentColor" aria-hidden="true">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 6h16M4 12h16M4 18h16" />
                </svg>
              </button>
              <div class="flex-1 px-4 flex justify-between">
                <div class="flex-1 flex">
                  <h1 class="text-xl font-semibold text-gray-900 flex items-center">
                    <%= assigns[:page_title] || "Dashboard" %>
                  </h1>
                </div>
                <div class="ml-4 flex items-center md:ml-6">
                  <button type="button" class="bg-white p-1 rounded-full text-gray-400 hover:text-gray-500 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500">
                    <span class="sr-only">View notifications</span>
                    <svg class="h-6 w-6" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke="currentColor" aria-hidden="true">
                      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 17h5l-1.405-1.405A2.032 2.032 0 0118 14.158V11a6.002 6.002 0 00-4-5.659V5a2 2 0 10-4 0v.341C7.67 6.165 6 8.388 6 11v3.159c0 .538-.214 1.055-.595 1.436L4 17h5m6 0v1a3 3 0 11-6 0v-1m6 0H9" />
                    </svg>
                  </button>
                  <div class="ml-3 relative">
                    <button type="button" class="max-w-xs bg-white flex items-center text-sm rounded-full focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500">
                      <span class="sr-only">Open account menu</span>
                      <div class="h-8 w-8 rounded-full bg-gray-200 flex items-center justify-center">
                        <svg class="h-5 w-5 text-gray-600" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke="currentColor" aria-hidden="true">
                          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z" />
                        </svg>
                      </div>
                    </button>
                  </div>
                </div>
              </div>
            </div>

            <!-- Main content area -->
            <main class="flex-1 relative overflow-y-auto focus:outline-none">
              <%= @inner_content %>
            </main>
          </div>
        </div>
      </body>
    </html>
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
