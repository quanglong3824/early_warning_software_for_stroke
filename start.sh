#!/bin/bash

# Script to start both Flutter app and Flask API simultaneously
# Usage: ./start.sh

echo "🚀 Starting Early Warning Software for Stroke..."
echo "================================================"

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Function to cleanup on exit
cleanup() {
    echo -e "\n${YELLOW}⚠️  Shutting down services...${NC}"
    kill $FLASK_PID 2>/dev/null
    kill $FLUTTER_PID 2>/dev/null
    echo -e "${GREEN}✅ Services stopped${NC}"
    exit 0
}

# Set trap to cleanup on Ctrl+C
trap cleanup SIGINT SIGTERM

# Check if Flutter is installed
if ! command -v flutter &> /dev/null; then
    echo -e "${YELLOW}⚠️  Flutter not found in PATH${NC}"
    echo "Trying to use ~/development/flutter/bin/flutter..."
    FLUTTER_CMD="$HOME/development/flutter/bin/flutter"
    if [ ! -f "$FLUTTER_CMD" ]; then
        echo -e "${RED}❌ Flutter not found. Please install Flutter first.${NC}"
        exit 1
    fi
else
    FLUTTER_CMD="flutter"
fi

# Check if Python3 is installed
if ! command -v python3 &> /dev/null; then
    echo -e "${RED}❌ Python3 not found. Please install Python3 first.${NC}"
    exit 1
fi

echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}📦 Starting Flask API on port 5001...${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# Ensure port 5001 is free
if lsof -ti :5001 >/dev/null; then
    echo -e "${YELLOW}⚠️  Port 5001 is in use. Killing process...${NC}"
    lsof -ti :5001 | xargs kill -9
    echo -e "${GREEN}✅ Port 5001 freed${NC}"
fi

# Start Flask API and colorize output
cd assets/models
PORT=5001 python3 app.py 2>&1 | ../../flask_colorizer.sh &
FLASK_PID=$!
cd ../..

# Wait for Flask to start
sleep 5

echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}📱 Starting Flutter Web App...${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# Start Flutter and colorize output
$FLUTTER_CMD run -d web-server 2>&1 | ./flutter_colorizer.sh &
FLUTTER_PID=$!

echo ""
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}🎉 All services are starting!${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "📊 ${BLUE}Service Information:${NC}"
echo -e "   • Flask API:    http://localhost:5001"
echo -e "   • Flutter App:  Will show URL above when ready"
echo ""
echo -e "⚠️  ${YELLOW}Press Ctrl+C to stop all services${NC}"
echo ""

# Keep script running and wait for both processes
wait $FLASK_PID $FLUTTER_PID
