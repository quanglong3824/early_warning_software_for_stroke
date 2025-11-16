#!/bin/bash

# 🚀 SEWS - Build Commands Script
# Các lệnh build và setup nhanh cho dự án

echo "🚀 SEWS Build Commands"
echo "======================"
echo ""

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored text
print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_info() {
    echo -e "${YELLOW}ℹ️  $1${NC}"
}

# Check if Flutter is installed
if ! command -v flutter &> /dev/null; then
    print_error "Flutter is not installed!"
    exit 1
fi

print_success "Flutter is installed"

# Main menu
echo "Chọn một option:"
echo "1. Clean & Get Dependencies"
echo "2. Run on Device"
echo "3. Build Android APK (Debug)"
echo "4. Build Android APK (Release)"
echo "5. Build Android App Bundle"
echo "6. Build iOS (Debug)"
echo "7. Build iOS (Release)"
echo "8. Run Tests"
echo "9. Check Issues (flutter doctor)"
echo "10. Format Code"
echo "11. Analyze Code"
echo "12. Full Clean (Deep Clean)"
echo "0. Exit"
echo ""
read -p "Enter option: " option

case $option in
    1)
        print_info "Cleaning project..."
        flutter clean
        print_info "Getting dependencies..."
        flutter pub get
        print_success "Done!"
        ;;
    2)
        print_info "Running on device..."
        flutter run
        ;;
    3)
        print_info "Building Android APK (Debug)..."
        flutter build apk --debug
        print_success "APK built: build/app/outputs/flutter-apk/app-debug.apk"
        ;;
    4)
        print_info "Building Android APK (Release)..."
        flutter build apk --release
        print_success "APK built: build/app/outputs/flutter-apk/app-release.apk"
        ;;
    5)
        print_info "Building Android App Bundle..."
        flutter build appbundle --release
        print_success "App Bundle built: build/app/outputs/bundle/release/app-release.aab"
        ;;
    6)
        print_info "Building iOS (Debug)..."
        flutter build ios --debug
        print_success "iOS build completed!"
        ;;
    7)
        print_info "Building iOS (Release)..."
        flutter build ios --release
        print_success "iOS build completed!"
        ;;
    8)
        print_info "Running tests..."
        flutter test
        ;;
    9)
        print_info "Checking for issues..."
        flutter doctor -v
        ;;
    10)
        print_info "Formatting code..."
        flutter format .
        print_success "Code formatted!"
        ;;
    11)
        print_info "Analyzing code..."
        flutter analyze
        ;;
    12)
        print_info "Deep cleaning..."
        flutter clean
        rm -rf build/
        rm -rf ios/Pods/
        rm -rf ios/.symlinks/
        rm -rf ios/Flutter/Flutter.framework
        rm -rf ios/Flutter/Flutter.podspec
        rm -rf .dart_tool/
        print_info "Getting dependencies..."
        flutter pub get
        print_info "Installing iOS pods..."
        cd ios && pod install && cd ..
        print_success "Deep clean completed!"
        ;;
    0)
        print_info "Exiting..."
        exit 0
        ;;
    *)
        print_error "Invalid option!"
        exit 1
        ;;
esac
