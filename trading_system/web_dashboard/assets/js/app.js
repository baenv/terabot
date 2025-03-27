// Import Phoenix LiveView hooks
import { Socket } from 'phoenix';
import { LiveSocket } from 'phoenix_live_view';

// Import any custom hooks/modules here
import JSCommands from './hooks/commands';

// Define hooks for LiveView
const Hooks = {
  JSCommands,
}

// Set up LiveView socket
const csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute("content")
const liveSocket = new LiveSocket("/live", Socket, {
  params: { _csrf_token: csrfToken },
  hooks: Hooks,
})

// Connect to the LiveView socket
liveSocket.connect()

// Expose liveSocket on window for the LiveReload and console debugging
window.liveSocket = liveSocket 
