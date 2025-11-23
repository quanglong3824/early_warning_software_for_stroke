#!/bin/bash

# Start App - Run Flask API and Flutter App together
# Usage: ./start_app.sh [device]
# Example: ./start_app.sh web-server
#          ./start_app.sh chrome

echo "🚀 Starting Early Warning Software for Stroke..."
echo "================================================"

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Get device argument (default to web-server)
DEVICE=${1:-web-server}

echo -e "${BLUE}📱 Target device: $DEVICE${NC}"
echo ""

# Function to cleanup on exit
cleanup() {
    echo ""
    echo -e "${YELLOW}🛑 Stopping services...${NC}"
    kill $API_PID 2>/dev/null
    kill $FLUTTER_PID 2>/dev/null
    echo -e "${GREEN}✅ Services stopped${NC}"
    exit 0
}

# Trap Ctrl+C
trap cleanup INT TERM

# Start Flask API
echo -e "${BLUE}🔧 Starting Flask API Server...${NC}"
cd assets/models
PORT=5001 python3 app.py > ../../api.log 2>&1 &
API_PID=$!
cd ../..

# Wait for API to start
echo "⏳ Waiting for API to start..."
sleep 3

# Check if API is running
if curl -s http://localhost:5001/health > /dev/null 2>&1; then
    echo -e "${GREEN}✅ Flask API is running on http://localhost:5001${NC}"
else
    echo -e "${YELLOW}⚠️  Flask API may not be ready yet (will use fallback)${NC}"
fi

echo ""

# Start Flutter App
echo -e "${BLUE}📱 Starting Flutter App on $DEVICE...${NC}"
flutter run -d $DEVICE &
FLUTTER_PID=$!

echo ""
echo -e "${GREEN}================================================${NC}"
echo -e "${GREEN}✅ App is starting!${NC}"
echo -e "${GREEN}================================================${NC}"
echo ""
echo "📍 Flask API: http://localhost:5001"
echo "📍 API Logs: api.log"
echo ""
echo "Press Ctrl+C to stop all services"
echo ""

# Wait for Flutter process
wait $FLUTTER_PID

# Cleanup when Flutter exits
cleanup
