# TravelBuddy Makefile
# Automates common development tasks with environment-specific configurations

.PHONY: help setup run-dev run-staging run-prod build-dev build-staging build-prod clean format format-check

# Default target
help:
	@echo "TravelBuddy Development Commands"
	@echo "================================="
	@echo "setup          - Initial project setup (copy config templates)"
	@echo "run-dev        - Run app in development mode"
	@echo "run-staging    - Run app in staging mode"
	@echo "run-prod       - Run app in production mode"
	@echo "build-dev      - Build APK for development"
	@echo "build-staging  - Build APK for staging"
	@echo "build-prod     - Build APK for production"
	@echo "format         - Format all Dart files"
	@echo "format-check   - Check if Dart files are formatted"
	@echo "clean          - Clean build artifacts"
	@echo "gen            - Run code generation (build_runner)"

# Initial setup - copy example configs
setup:
	@echo "Setting up TravelBuddy..."
	@if [ ! -f config/dev.json ]; then \
		cp config/dev.json.example config/dev.json; \
		echo "Created config/dev.json - Please update with your credentials"; \
	fi
	@if [ ! -f config/staging.json ]; then \
		cp config/staging.json.example config/staging.json; \
		echo "Created config/staging.json - Please update with your credentials"; \
	fi
	@if [ ! -f config/prod.json ]; then \
		cp config/prod.json.example config/prod.json; \
		echo "Created config/prod.json - Please update with your credentials"; \
	fi
	@echo "Setup complete! Update your config/*.json files with actual credentials."

# Run commands with environment-specific configs
run-dev:
	@echo "Running in DEVELOPMENT mode..."
	@flutter run --dart-define-from-file=config/dev.json

run-staging:
	@echo "Running in STAGING mode..."
	@flutter run --dart-define-from-file=config/staging.json

run-prod:
	@echo "Running in PRODUCTION mode..."
	@flutter run --dart-define-from-file=config/prod.json --release

# Build commands
build-dev:
	@echo "Building APK for DEVELOPMENT..."
	@flutter build apk --dart-define-from-file=config/dev.json

build-staging:
	@echo "Building APK for STAGING..."
	@flutter build apk --dart-define-from-file=config/staging.json

build-prod:
	@echo "Building APK for PRODUCTION..."
	@flutter build apk --dart-define-from-file=config/prod.json --release

# Code generation
gen:
	@echo "Running code generation..."
	@dart run build_runner build --delete-conflicting-outputs

# Format code
format:
	@echo "Formatting Dart files..."
	@dart format .

# Check formatting
format-check:
	@echo "Checking Dart file formatting..."
	@dart format --output=none --set-exit-if-changed .

# Clean
clean:
	@echo "Cleaning build artifacts..."
	@flutter clean
	@rm -rf .dart_tool/
	@rm -rf build/
