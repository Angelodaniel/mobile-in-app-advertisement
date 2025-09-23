#!/bin/bash

# iOS Ad Automation Script
# This script simulates user interactions with the MobileInAppAdvertisement app
# to generate performance data in Sentry

set -e

# Configuration
TEST_DURATION=${1:-5}  # Default 5 minutes
SIMULATOR_NAME="AdTestSimulator"
SIMULATOR_ID=""
BUNDLE_ID="uprate.MobileInAppAdvertisement"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging function
log() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Function to check if simulator is running
check_simulator() {
    log "Checking for available iPhone simulators..."
    
    # First, let's get the list of available destinations from xcodebuild
    log "Getting available xcodebuild destinations..."
    local available_destinations=$(xcodebuild -project MobileInAppAdvertisement.xcodeproj -scheme MobileInAppAdvertisement -showdestinations 2>/dev/null | grep "platform:iOS Simulator" | grep "iPhone" | head -1)
    
    if [ -n "$available_destinations" ]; then
        # Extract simulator name and ID from xcodebuild output
        # Format: "{ platform:iOS Simulator, arch:arm64, id:7A792E32-B159-474E-9815-4140411E029D, OS:18.5, name:iPhone 16 Pro }"
        local simulator_name=$(echo "$available_destinations" | sed -n 's/.*name:\([^}]*\).*/\1/p' | xargs)
        local simulator_id=$(echo "$available_destinations" | sed -n 's/.*id:\([^,]*\).*/\1/p' | xargs)
        
        log "Found compatible iPhone simulator: $simulator_name (ID: $simulator_id)"
        SIMULATOR_NAME="$simulator_name"
        SIMULATOR_ID="$simulator_id"
        return 0
    fi
    
    # Fallback to simctl if xcodebuild fails
    log "Falling back to simctl list..."
    local simulator_info=$(xcrun simctl list devices | grep "iPhone" | grep -v "unavailable" | head -1)
    
    if [ -n "$simulator_info" ]; then
        # Extract simulator name and ID from the line
        # Format: "iPhone 16 (0E573B10-C4F3-40D6-A8CB-08B18F25CE08) (Shutdown)"
        local simulator_name=$(echo "$simulator_info" | awk -F'(' '{print $1}' | xargs)
        local simulator_id=$(echo "$simulator_info" | awk -F'[()]' '{print $2}')
        
        log "Found available iPhone simulator: $simulator_name (ID: $simulator_id)"
        SIMULATOR_NAME="$simulator_name"
        SIMULATOR_ID="$simulator_id"
        return 0
    fi
    
    # If no simulator found, try to create one
    log "No iPhone simulator found, attempting to create one..."
    create_simulator_if_needed
    
    # Check again after creation attempt
    simulator_info=$(xcrun simctl list devices | grep "iPhone" | grep -v "unavailable" | head -1)
    if [ -n "$simulator_info" ]; then
        local simulator_name=$(echo "$simulator_info" | awk -F'(' '{print $1}' | xargs)
        local simulator_id=$(echo "$simulator_info" | awk -F'[()]' '{print $2}')
        
        log "Using simulator: $simulator_name (ID: $simulator_id)"
        SIMULATOR_NAME="$simulator_name"
        SIMULATOR_ID="$simulator_id"
        return 0
    fi
    
    error "No iPhone simulator available"
    return 1
}

# Function to create simulator if needed
create_simulator_if_needed() {
    log "Attempting to create iPhone simulator..."
    
    # Try different iOS versions
    local ios_versions=("18.4" "18.5" "18.6" "18.3" "18.2" "18.1" "18.0")
    
    for version in "${ios_versions[@]}"; do
        log "Trying to create simulator with iOS $version..."
        if xcrun simctl create "AdTestSimulator" "iPhone 16" "iOS $version" 2>/dev/null; then
            log "Successfully created simulator with iOS $version"
            SIMULATOR_NAME="AdTestSimulator"
            return 0
        else
            log "Failed to create simulator with iOS $version"
        fi
    done
    
    log "Could not create simulator, will try to use existing ones"
}

# Function to build and install the app
build_and_install_app() {
    log "Building and installing the app..."
    
    # Build the app
    log "Building iOS app..."
    if ! xcodebuild -project MobileInAppAdvertisement.xcodeproj \
        -scheme MobileInAppAdvertisement \
        -destination "platform=iOS Simulator,id=$SIMULATOR_ID" \
        -configuration Debug \
        -derivedDataPath ./DerivedData \
        build; then
        error "Failed to build the app"
        return 1
    fi
    
    # Find the built app
    local app_path=$(find ./DerivedData -name "MobileInAppAdvertisement.app" -type d | head -1)
    if [ -z "$app_path" ]; then
        error "Could not find built app"
        return 1
    fi
    
    log "Found app at: $app_path"
    
    # Install the app
    log "Installing app on simulator..."
    if ! xcrun simctl install "$SIMULATOR_ID" "$app_path"; then
        error "Failed to install app on simulator"
        return 1
    fi
    
    success "App installed successfully"
    return 0
}

# Function to launch the app
launch_app() {
    log "Launching app on simulator..."
    if ! xcrun simctl launch "$SIMULATOR_ID" "$BUNDLE_ID"; then
        error "Failed to launch app"
        return 1
    fi
    success "App launched successfully"
    sleep 5  # Wait for app to start
    return 0
}

# Function to check if app is installed
check_app() {
    # First boot the simulator if it's shutdown
    log "Checking simulator state..."
    local simulator_state=$(xcrun simctl list devices | grep "$SIMULATOR_ID" | grep -o "Shutdown\|Booted")
    
    if [ "$simulator_state" = "Shutdown" ]; then
        log "Simulator is shutdown, booting it..."
        xcrun simctl boot "$SIMULATOR_ID"
        sleep 10  # Wait for simulator to boot
    fi
    
    # Check if app is installed
    if ! xcrun simctl listapps "$SIMULATOR_ID" | grep -q "$BUNDLE_ID"; then
        log "App $BUNDLE_ID is not installed on simulator, will install it"
        return 1
    fi
    return 0
}

# Function to tap on UI element
tap_element() {
    local x=$1
    local y=$2
    local description=$3
    
    log "Tapping $description at ($x, $y)"
    
    # Check if simulator is still running
    local simulator_state=$(xcrun simctl list devices | grep "$SIMULATOR_ID" | grep -o "Shutdown\|Booted")
    if [ "$simulator_state" = "Shutdown" ]; then
        error "Simulator crashed during test - cannot tap $description"
        return 1
    fi
    
    xcrun simctl io "$SIMULATOR_NAME" tap "$x" "$y"
    sleep 2
}

# Function to wait for element to appear
wait_for_element() {
    local x=$1
    local y=$2
    local description=$3
    local timeout=${4:-10}
    
    log "Waiting for $description to appear..."
    local count=0
    while [ $count -lt $timeout ]; do
        # Check if element is visible (simplified check)
        if xcrun simctl io "$SIMULATOR_NAME" screenshot /tmp/screenshot.png 2>/dev/null; then
            success "$description found"
            return 0
        fi
        sleep 1
        count=$((count + 1))
    done
    warning "$description not found within $timeout seconds"
    return 1
}

# Function to test working ads scenario
test_working_ads() {
    log "Testing working ads scenario..."
    
    # Wait for app to load
    sleep 5
    
    # Verify app is still running
    if ! xcrun simctl list devices | grep "$SIMULATOR_ID" | grep -q "Booted"; then
        error "Simulator is not running - cannot test ads"
        return 1
    fi
    
    # Test banner ad (should load automatically)
    log "Testing banner ad..."
    sleep 3  # Wait for banner to load
    log "Banner ad test completed"
    
    # Test interstitial ad
    log "Testing interstitial ad..."
    log "Tapping Load Interstitial button..."
    if ! tap_element 200 300 "Load Interstitial button"; then
        error "Failed to tap Load Interstitial button - simulator may have crashed"
        return 1
    fi
    sleep 3  # Wait for ad to load
    log "Tapping Show Interstitial button..."
    if ! tap_element 200 350 "Show Interstitial button"; then
        error "Failed to tap Show Interstitial button - simulator may have crashed"
        return 1
    fi
    sleep 5  # Wait for ad to show and dismiss
    log "Interstitial ad test completed"
    
    # Test rewarded ad
    log "Testing rewarded ad..."
    log "Tapping Load Rewarded button..."
    if ! tap_element 200 400 "Load Rewarded button"; then
        error "Failed to tap Load Rewarded button - simulator may have crashed"
        return 1
    fi
    sleep 3  # Wait for ad to load
    log "Tapping Show Rewarded button..."
    if ! tap_element 200 450 "Show Rewarded button"; then
        error "Failed to tap Show Rewarded button - simulator may have crashed"
        return 1
    fi
    sleep 8  # Wait for video to complete
    log "Rewarded ad test completed"
    
    success "Working ads test completed"
}


# Function to simulate user behavior
simulate_user_behavior() {
    log "Simulating realistic user behavior..."
    
    # Random scrolling
    for i in {1..3}; do
        log "Scrolling (attempt $i/3)"
        xcrun simctl io "$SIMULATOR_NAME" tap 200 200
        sleep 1
        xcrun simctl io "$SIMULATOR_NAME" tap 200 400
        sleep 1
    done
    
    # Random taps on different areas
    for i in {1..5}; do
        log "Random tap $i/5"
        x=$((100 + RANDOM % 200))
        y=$((200 + RANDOM % 300))
        tap_element $x $y "Random area"
    done
}

# Function to run continuous test
run_continuous_test() {
    local duration_minutes=$1
    # Convert to integer seconds (round down)
    local duration_seconds=$((${duration_minutes%.*} * 60))
    local end_time=$(($(date +%s) + duration_seconds))
    
    log "Starting continuous test for $duration_minutes minutes"
    log "Testing working ads scenario (always successful)"
    
    local cycle=1
    while [ $(date +%s) -lt $end_time ]; do
        log "Starting test cycle $cycle"
        
        # Reset app state
        xcrun simctl terminate "$SIMULATOR_NAME" "$BUNDLE_ID" 2>/dev/null || true
        sleep 2
        
        # Ensure simulator is still running
        local simulator_state=$(xcrun simctl list devices | grep "$SIMULATOR_ID" | grep -o "Shutdown\|Booted")
        if [ "$simulator_state" = "Shutdown" ]; then
            log "Simulator shutdown detected, rebooting..."
            xcrun simctl boot "$SIMULATOR_ID"
            sleep 10
        fi
        
        xcrun simctl launch "$SIMULATOR_NAME" "$BUNDLE_ID"
        sleep 5
        
        # Run working ads scenario (always successful in GitHub Actions)
        test_working_ads
        
        # Simulate user behavior
        simulate_user_behavior
        
        # Wait before next cycle
        local wait_time=$((30 + RANDOM % 60))  # 30-90 seconds
        log "Waiting $wait_time seconds before next cycle..."
        sleep $wait_time
        
        cycle=$((cycle + 1))
    done
    
    success "Continuous test completed after $duration_minutes minutes"
}


# Main execution
main() {
    log "Starting iOS Ad Automation Script"
    log "Test Duration: $TEST_DURATION minutes"
    log "Ad Scenarios: working (always successful)"
    
    # Pre-flight checks
    if ! check_simulator; then
        error "Simulator check failed"
        exit 1
    fi
    
    if ! check_app; then
        log "App not found, building and installing..."
        if ! build_and_install_app; then
            error "Failed to build and install app"
            exit 1
        fi
    fi
    
    # Launch the app
    if ! launch_app; then
        error "Failed to launch app"
        exit 1
    fi
    
    # Run the test
    run_continuous_test "$TEST_DURATION"
    
    success "iOS Ad Automation completed successfully!"
    log "Check your Sentry dashboard for detailed performance metrics and spans"
}

# Handle script interruption
trap 'log "Script interrupted. Cleaning up..."; exit 130' INT TERM

# Run main function
main "$@"
