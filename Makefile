# Makefile for the Recette Project
# ---------------------------------
# Defines common tasks for running, building, and deploying the app.

# Use bash for all shell commands
SHELL := /bin/bash

# Default command: show the help message
.DEFAULT_GOAL := help

# Phony targets don't represent actual files
.PHONY: help run-dev deploy-dev release

help:
	@echo "Recette Project Commands:"
	@echo "  make help           Show this help message."
	@echo "  make run-dev        Run the Flutter app in debug mode with the dev API."
	@echo "  make deploy-dev     Deploy the backend function to the 'dev' environment."
	@echo "  make release        Start the versioned release process for the app and backend."

run-dev:
	@echo "Running Flutter app in debug mode (connecting to dev API)..."
	@flutter run --dart-define=API_URL=https://recette-api-dev-us-central1-fdf64.cloudfunctions.net \
	--dart-define-from-file=.env

deploy-dev:
	@echo "Deploying backend to the 'dev' environment..."
	@(cd backend && sh deploy-dev.sh)

release:
	@echo "Starting versioned release process..."
	@sh release.sh