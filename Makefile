# Makefile for Android Docker ARM64 project

.PHONY: help build start stop restart logs shell install-whatsapp clean

help:
	@echo "Android Docker Multi-Architecture"
	@echo "========================================"
	@echo ""
	@echo "Available commands:"
	@echo "  make build            - Build the Docker image"
	@echo "  make start            - Start the container"
	@echo "  make stop             - Stop the container"
	@echo "  make restart          - Restart the container"
	@echo "  make logs             - View container logs"
	@echo "  make shell            - Access container shell"
	@echo "  make clean            - Stop and remove containers and volumes"
	@echo ""
	@echo "Access URLs:"
	@echo "  Web UI: http://localhost:6080"
	@echo "  VNC: vnc://localhost:5900"
	@echo ""

build:
	@echo "Building Docker image..."
	docker-compose build

start:
	@echo "Starting container..."
	docker-compose up -d
	@echo ""
	@echo "Container started! Access at:"
	@echo "  Web UI: http://localhost:6080"
	@echo "  VNC: vnc://localhost:5900"
	@echo ""
	@echo "To view logs: make logs"

stop:
	@echo "Stopping container..."
	docker-compose down

restart:
	@echo "Restarting container..."
	docker-compose restart

logs:
	docker-compose logs -f

shell:
	docker exec -it android-emulator bash

clean:
	@echo "Stopping and removing containers and volumes..."
	docker-compose down -v
	@echo "Cleanup complete!"
