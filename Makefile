.PHONY: setup test clean build run format check deps update-deps docker-build docker-run init-shell init-db init-mix clean-db reset-db start stop migrate migrate.up migrate.down run-core run-portfolio run-collector run-order run-decision run-dashboard run-processor

# Default target
all: init-mix test

# Initialize devbox shell
init-shell:
	@if ! command -v devbox >/dev/null 2>&1; then curl -fsSL https://get.jetpack.io/devbox | bash; fi
	@devbox install
	@devbox shell

# Initialize the database and start the services
init-db:
	@ make stop || true
	@if [ -n "$$(ls -A ./data/dev 2>/dev/null)" ] || [ -n "$$(ls -A ./data/test 2>/dev/null)" ]; then \
		echo "Error: ./data/dev or ./data/test is not empty. Please run 'make clean-db' first."; \
		exit 1; \
	fi
	devbox run init-db
	@devbox services start
	@devbox services ls

# Clean the database
clean-db:
	@ make stop || true
	devbox run clean-db

# Reset the database and start the services
reset-db: clean-db init-db

# Start the services including the database
start:
	@devbox services start
	@devbox services ls

# Stop the services including the database
stop:
	@devbox services stop

# Initialize mix development environment
init-mix:
	cd trading_system/trading_system_main && mix local.hex --force
	cd trading_system/trading_system_main && mix local.rebar --force
	cd trading_system/trading_system_main && mix deps.get
	cd trading_system/trading_system_main && mix compile

# Run tests
test:
	cd trading_system/trading_system_main && mix test

# Run tests with coverage
test.coverage:
	cd trading_system/trading_system_main && mix test --cover

# Clean build artifacts
clean:
	cd trading_system/trading_system_main && mix clean
	cd trading_system/trading_system_main && rm -rf _build deps
	cd trading_system/core && mix clean && rm -rf _build deps
	cd trading_system/portfolio_manager && mix clean && rm -rf _build deps
	cd trading_system/data_collector && mix clean && rm -rf _build deps
	cd trading_system/order_manager && mix clean && rm -rf _build deps
	cd trading_system/decision_engine && mix clean && rm -rf _build deps
	cd trading_system/web_dashboard && mix clean && rm -rf _build deps

# Build release
build:
	cd trading_system/trading_system_main && mix release

# Run the application
run:
	cd trading_system/trading_system_main && mix run --no-halt

# Run with IEx console
run.console:
	cd trading_system/trading_system_main && iex -S mix

# Format code
format:
	cd trading_system/trading_system_main && mix format
	cd trading_system/core && mix format
	cd trading_system/portfolio_manager && mix format
	cd trading_system/data_collector && mix format
	cd trading_system/order_manager && mix format
	cd trading_system/decision_engine && mix format
	cd trading_system/web_dashboard && mix format

# Check code formatting
format.check:
	cd trading_system/trading_system_main && mix format --check-formatted
	cd trading_system/core && mix format --check-formatted
	cd trading_system/portfolio_manager && mix format --check-formatted
	cd trading_system/data_collector && mix format --check-formatted
	cd trading_system/order_manager && mix format --check-formatted
	cd trading_system/decision_engine && mix format --check-formatted
	cd trading_system/web_dashboard && mix format --check-formatted

# Run static code analysis
lint:
	cd trading_system/trading_system_main && mix credo
	cd trading_system/core && mix credo
	cd trading_system/portfolio_manager && mix credo
	cd trading_system/data_collector && mix credo
	cd trading_system/order_manager && mix credo
	cd trading_system/decision_engine && mix credo
	cd trading_system/web_dashboard && mix credo

# Get dependencies for all applications
deps:
	cd trading_system/trading_system_main && mix deps.get
	cd trading_system/core && mix deps.get
	cd trading_system/portfolio_manager && mix deps.get
	cd trading_system/data_collector && mix deps.get
	cd trading_system/order_manager && mix deps.get
	cd trading_system/decision_engine && mix deps.get
	cd trading_system/web_dashboard && mix deps.get

# Update dependencies for all applications
update-deps:
	cd trading_system/trading_system_main && mix deps.update --all
	cd trading_system/core && mix deps.update --all
	cd trading_system/portfolio_manager && mix deps.update --all
	cd trading_system/data_collector && mix deps.update --all
	cd trading_system/order_manager && mix deps.update --all
	cd trading_system/decision_engine && mix deps.update --all
	cd trading_system/web_dashboard && mix deps.update --all

# Check for outdated dependencies
deps.outdated:
	cd trading_system/trading_system_main && mix hex.outdated
	cd trading_system/core && mix hex.outdated
	cd trading_system/portfolio_manager && mix hex.outdated
	cd trading_system/data_collector && mix hex.outdated
	cd trading_system/order_manager && mix hex.outdated
	cd trading_system/decision_engine && mix hex.outdated
	cd trading_system/web_dashboard && mix hex.outdated

# Generate documentation
docs:
	cd trading_system/trading_system_main && mix docs
	cd trading_system/core && mix docs
	cd trading_system/portfolio_manager && mix docs
	cd trading_system/data_collector && mix docs
	cd trading_system/order_manager && mix docs
	cd trading_system/decision_engine && mix docs
	cd trading_system/web_dashboard && mix docs

# Run database migrations (only in trading_system_main)
migrate: deps
	cd trading_system/core && mix ecto.migrate

# Run database migrations up (only in trading_system_main)
migrate.up: deps
	cd trading_system/core && mix ecto.migrate

# Run database migrations down (only in trading_system_main)
migrate.down:
	cd trading_system/core && mix ecto.rollback

# Run individual applications
run-core:
	cd trading_system/core && mix run --no-halt

run-portfolio:
	cd trading_system/portfolio_manager && mix run --no-halt

run-collector:
	cd trading_system/data_collector && mix run --no-halt

run-order:
	cd trading_system/order_manager && mix run --no-halt

run-decision:
	cd trading_system/decision_engine && mix run --no-halt

run-dashboard:
	cd trading_system/web_dashboard && mix run --no-halt

run-processor:
	cd trading_system/data_processor && mix run --no-halt

# Help target
help:
	@echo "Available targets:"
	@echo ""
	@echo "Development Environment:"
	@echo "  init-shell    - Install and enter devbox shell with required packages"
	@echo "  init-mix      - Initialize Elixir development environment"
	@echo "  all           - Run init-mix and tests (default target)"
	@echo ""
	@echo "Database Management:"
	@echo "  init-db       - Initialize and start database services"
	@echo "  clean-db      - Clean database files"
	@echo "  reset-db      - Reset database (clean and reinitialize)"
	@echo "  start         - Start database services"
	@echo "  stop          - Stop database services"
	@echo ""
	@echo "Testing and Quality:"
	@echo "  test          - Run tests"
	@echo "  test.coverage - Run tests with coverage"
	@echo "  format        - Format code"
	@echo "  format.check  - Check code formatting"
	@echo "  lint          - Run static code analysis"
	@echo ""
	@echo "Dependencies:"
	@echo "  deps          - Get dependencies for all applications"
	@echo "  update-deps   - Update dependencies for all applications"
	@echo "  deps.outdated - Check for outdated dependencies"
	@echo ""
	@echo "Running Applications:"
	@echo "  run           - Run the complete system"
	@echo "  run-core      - Run only the core application"
	@echo "  run-portfolio - Run only the portfolio manager"
	@echo "  run-collector - Run only the data collector"
	@echo "  run-order     - Run only the order manager"
	@echo "  run-decision  - Run only the decision engine"
	@echo "  run-dashboard - Run only the web dashboard"
	@echo "  run-processor - Run only the data processor"
	@echo "  run.console   - Run with IEx console"
	@echo ""
	@echo "Documentation and Build:"
	@echo "  docs          - Generate documentation"
	@echo "  build         - Build release"
