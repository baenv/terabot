.PHONY: setup test clean build run format check deps update-deps docker-build docker-run init-shell init-db init-mix clean-db reset-db start stop migrate migrate.up migrate.down

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
	cd trading_system && mix local.hex --force
	cd trading_system && mix local.rebar --force
	cd trading_system && mix deps.get
	cd trading_system && mix compile

# Run tests
test:
	cd trading_system && mix test

# Run tests with coverage
test.coverage:
	cd trading_system && mix test --cover

# Clean build artifacts
clean:
	cd trading_system && mix clean
	cd trading_system && rm -rf _build deps

# Build release
build:
	cd trading_system && mix release

# Run the application
run:
	cd trading_system && mix run --no-halt

# Run with IEx console
run.console:
	cd trading_system && iex -S mix

# Format code
format:
	cd trading_system && mix format

# Check code formatting
format.check:
	cd trading_system && mix format --check-formatted

# Run static code analysis
lint:
	cd trading_system && mix credo

# Get dependencies
deps:
	cd trading_system && mix deps.get

# Update dependencies
update-deps:
	cd trading_system && mix deps.update --all

# Check for outdated dependencies
deps.outdated:
	cd trading_system && mix hex.outdated

# Generate documentation
docs:
	cd trading_system && mix docs

# Get dependencies
deps.get:
	cd trading_system && mix deps.get

# Run database migrations
migrate: deps.get
	cd trading_system && mix ecto.migrate

# Run database migrations up
migrate.up: deps.get
	cd trading_system && mix ecto.migrate

# Run database migrations down
migrate.down:
	cd trading_system && mix ecto.rollback

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
	@echo "  deps          - Get dependencies"
	@echo "  update-deps   - Update dependencies"
	@echo "  deps.outdated - Check for outdated dependencies"
	@echo ""
	@echo "Documentation and Build:"
	@echo "  docs          - Generate documentation"
	@echo "  build         - Build release"
	@echo "  run           - Run the application"
	@echo "  run.console   - Run with IEx console"
