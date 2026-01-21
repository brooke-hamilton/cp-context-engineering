# Context Engineering Guide - Makefile

.PHONY: slides serve clean help

PORT := 8080
SLIDES_URL := http://localhost:$(PORT)/context-engineering-slides.html

# Default target
help:
	@echo "Available commands:"
	@echo "  make slides  - Start server and open slideshow in browser"
	@echo "  make serve   - Start HTTP server on port $(PORT)"
	@echo "  make clean   - Stop any running HTTP servers"
	@echo "  make help    - Show this help message"

# Start server and open slideshow in browser
# Note: To open in VS Code Simple Browser, use Command Palette > "Simple Browser: Show"
# and enter http://localhost:8080/context-engineering-slides.html
slides: serve
	@echo "Opening slideshow at $(SLIDES_URL)"
	@echo ""
	@echo "For VS Code: Command Palette (Ctrl+Shift+P) > 'Simple Browser: Show' > paste URL"
	@echo ""
	@xdg-open "$(SLIDES_URL)" 2>/dev/null || \
		open "$(SLIDES_URL)" 2>/dev/null || \
		start "$(SLIDES_URL)" 2>/dev/null || \
		echo "Open $(SLIDES_URL) in your browser"

# Start HTTP server in background (only if not already running)
serve:
	@if lsof -i:$(PORT) >/dev/null 2>&1; then \
		echo "Server already running on port $(PORT)"; \
	else \
		echo "Starting HTTP server on http://localhost:$(PORT)..."; \
		cd docs && python3 -m http.server $(PORT) & \
		sleep 1; \
	fi

# Stop any running HTTP servers on port 8080
clean:
	@echo "Stopping HTTP server..."
	@-pkill -f "python3 -m http.server $(PORT)" 2>/dev/null || true
	@-fuser -k $(PORT)/tcp 2>/dev/null || true
	@echo "Server stopped."
