#!/bin/bash

# Start API Only
# Usage: ./start_api.sh

echo "🚀 Starting Flask API Server..."

cd assets/models
PORT=5001 python3 app.py
