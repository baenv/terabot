// tailwind.config.js
const plugin = require('tailwindcss/plugin')

module.exports = {
  content: [
    './js/**/*.js',
    '../lib/*_web/**/*.*ex',
    '../lib/*_web.ex',
    '../lib/web_dashboard/**/*.ex',
    '../lib/web_dashboard/**/*.heex',
    '../lib/web_dashboard/**/*.eex'
  ],
  theme: {
    extend: {
      colors: {
        brand: {
          50: '#f0f9ff',
          100: '#e0f2fe',
          200: '#bae6fd',
          300: '#7dd3fc',
          400: '#38bdf8',
          500: '#0ea5e9',
          600: '#0284c7',
          700: '#0369a1',
          800: '#075985',
          900: '#0c4a6e',
        }
      }
    },
  },
  plugins: [
    require('@tailwindcss/forms'),
    plugin(({ addVariant }) => {
      addVariant('phx-no-feedback', ['&.phx-no-feedback', '.phx-no-feedback &']);
      addVariant('phx-click-loading', ['&.phx-click-loading', '.phx-click-loading &']);
      addVariant('phx-submit-loading', ['&.phx-submit-loading', '.phx-submit-loading &']);
      addVariant('phx-change-loading', ['&.phx-change-loading', '.phx-change-loading &']);
    })
  ]
} 
