// JS Commands hook for Phoenix LiveView
const JSCommands = {
  mounted() {
    this.handleEvent("js-exec", ({ commands }) => {
      commands.forEach(([command, args]) => {
        this[command]?.(...args)
      })
    })
  },

  // Add command handlers here
  copyToClipboard(text) {
    navigator.clipboard.writeText(text)
  },

  showNotification(message, type = "info") {
    // Simple notification handling
    const notification = document.createElement("div")
    notification.className = `notification notification-${type}`
    notification.textContent = message
    document.body.appendChild(notification)
    
    // Auto remove after 3 seconds
    setTimeout(() => {
      notification.remove()
    }, 3000)
  }
}

export default JSCommands 
