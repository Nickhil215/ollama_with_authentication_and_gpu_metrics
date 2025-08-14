#!/bin/bash

# Ensure required environment variables are set
if [ -z "$OLLAMA_API_KEY" ]; then
    echo "OLLAMA_API_KEY is not set. Exiting."
    exit 1
fi

# Start ollama in the background
ollama serve &
OLLAMA_PID=$!

# Start caddy in the background
caddy run --config /etc/caddy/Caddyfile &
CADDY_PID=$!

# Start GPU metrics server in the background
uvicorn gpu_metrics:app --host 0.0.0.0 --port 8000 &
METRICS_PID=$!

# Function to check process status
check_process() {
    wait $1 2>/dev/null
    STATUS=$?
    if [ $STATUS -ne 0 ]; then
        echo "Process $2 ($1) exited with status $STATUS - will attempt restart"
        return $STATUS
    fi
}

# Handle shutdown signals
trap "kill $OLLAMA_PID $CADDY_PID $METRICS_PID; exit 0" SIGTERM SIGINT

# Wait for all services to start and monitor them
while true; do
    if ! ps -p $OLLAMA_PID > /dev/null; then
        echo "Ollama service is not running, checking for exit status"
        check_process $OLLAMA_PID "Ollama"
        echo "Starting Ollama now"
        ollama serve &
        OLLAMA_PID=$!
    fi
    if ! ps -p $CADDY_PID > /dev/null; then
        echo "Caddy service is not running, checking for exit status"
        check_process $CADDY_PID "Caddy"
        echo "Starting Caddy now"
        caddy run --config /etc/caddy/Caddyfile &
        CADDY_PID=$!
    fi
    if ! ps -p $METRICS_PID > /dev/null; then
        echo "GPU Metrics service is not running, checking for exit status"
        check_process $METRICS_PID "GPU Metrics"
        echo "Starting GPU Metrics now"
        uvicorn gpu_metrics:app --host 0.0.0.0 --port 8000 &
        METRICS_PID=$!
    fi
    sleep 1
done
