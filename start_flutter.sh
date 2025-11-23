#!/bin/bash

# Start Flutter App Only
# Usage: ./start_flutter.sh [device]
# Example: ./start_flutter.sh web-server
#          ./start_flutter.sh chrome

DEVICE=${1:-web-server}

echo "🚀 Starting Flutter App on $DEVICE..."
flutter run -d $DEVICE
