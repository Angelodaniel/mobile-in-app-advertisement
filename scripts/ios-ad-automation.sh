#!/bin/bash

# iOS Ad Automation Script
# This script simulates user interactions with the MobileInAppAdvertisement app
# to generate performance data in Sentry

set -e

# Configuration
TEST_DURATION=${1:-5}  # Default 5 minutes
AD_SCENARIOS=${2:-both}  # working, failing, or both
SIMULATOR_NAME="AdTestSimulator"
BUNDLE_ID="com.angelodevoer.MobileInAppAdvertisement"

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
    # First try to find any iPhone simulator that's available
    local available_simulator=$(xcrun simctl list devices | grep "iPhone" | grep -v "unavailable" | head -1 | awk -F'[()]' '{print $2}')
    
    if [ -n "$available_simulator" ]; then
        log "Found available iPhone simulator: $available_simulator"
        SIMULATOR_NAME="$available_simulator"
        return 0
    fi
    
    # If no simulator found, try to create one
    log "No iPhone simulator found, attempting to create one..."
    create_simulator_if_needed
    
    # Check again after creation attempt
    available_simulator=$(xcrun simctl list devices | grep "iPhone" | grep -v "unavailable" | head -1 | awk -F'[()]' '{print $2}')
    if [ -n "$available_simulator" ]; then
        log "Using simulator: $available_simulator"
        SIMULATOR_NAME="$available_simulator"
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

# Function to check if app is installed
check_app() {
    if ! xcrun simctl listapps "$SIMULATOR_NAME" | grep -q "$BUNDLE_ID"; then
        error "App $BUNDLE_ID is not installed on simulator"
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
    
    # Test banner ad (should load automatically)
    log "Testing banner ad..."
    sleep 3  # Wait for banner to load
    
    # Test interstitial ad
    log "Testing interstitial ad..."
    tap_element 200 300 "Load Interstitial button"
    sleep 3  # Wait for ad to load
    tap_element 200 350 "Show Interstitial button"
    sleep 5  # Wait for ad to show and dismiss
    
    # Test rewarded ad
    log "Testing rewarded ad..."
    tap_element 200 400 "Load Rewarded button"
    sleep 3  # Wait for ad to load
    tap_element 200 450 "Show Rewarded button"
    sleep 8  # Wait for video to complete
    
    success "Working ads test completed"
}

# Function to test failing ads scenario
test_failing_ads() {
    log "Testing failing ads scenario..."
    
    # Toggle to failing ads
    log "Switching to failing ads..."
    tap_element 300 100 "Failing ads toggle"
    sleep 2
    
    # Test banner ad (should fail to load)
    log "Testing failing banner ad..."
    sleep 3  # Wait for banner to attempt loading
    
    # Test interstitial ad (should fail)
    log "Testing failing interstitial ad..."
    tap_element 200 300 "Load Interstitial button"
    sleep 3  # Wait for ad to fail loading
    # Don't try to show since it failed to load
    
    # Test rewarded ad (should fail)
    log "Testing failing rewarded ad..."
    tap_element 200 400 "Load Rewarded button"
    sleep 3  # Wait for ad to fail loading
    # Don't try to show since it failed to load
    
    success "Failing ads test completed"
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
    local scenarios=$2
    local end_time=$(($(date +%s) + duration_minutes * 60))
    
    log "Starting continuous test for $duration_minutes minutes"
    log "Testing scenarios: $scenarios"
    
    local cycle=1
    while [ $(date +%s) -lt $end_time ]; do
        log "Starting test cycle $cycle"
        
        # Reset app state
        xcrun simctl terminate "$SIMULATOR_NAME" "$BUNDLE_ID" 2>/dev/null || true
        sleep 2
        xcrun simctl launch "$SIMULATOR_NAME" "$BUNDLE_ID"
        sleep 5
        
        # Run test scenarios
        case $scenarios in
            "working")
                test_working_ads
                ;;
            "failing")
                test_failing_ads
                ;;
            "both")
                test_working_ads
                test_failing_ads
                ;;
        esac
        
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

# Function to generate performance report
generate_report() {
    log "Generating performance report..."
    
    # Take final screenshot
    xcrun simctl io "$SIMULATOR_NAME" screenshot /tmp/final_screenshot.png
    
    # Get app logs
    xcrun simctl spawn "$SIMULATOR_NAME" log show --predicate 'process == "MobileInAppAdvertisement"' --last 10m > /tmp/app_logs.txt 2>/dev/null || true
    
    # Create report
    cat > /tmp/automation_report.txt << EOF
iOS Ad Automation Report
========================
Test Duration: $TEST_DURATION minutes
Ad Scenarios: $AD_SCENARIOS
Test Completed: $(date)
Simulator: $SIMULATOR_NAME
Bundle ID: $BUNDLE_ID

Check your Sentry dashboard for detailed performance metrics:
- Ad lifecycle transactions
- Performance spans
- Error tracking
- Battery impact data
- User interaction metrics

Screenshots and logs saved to:
- /tmp/final_screenshot.png
- /tmp/app_logs.txt
EOF

    log "Report generated: /tmp/automation_report.txt"
    cat /tmp/automation_report.txt
}

# Main execution
main() {
    log "Starting iOS Ad Automation Script"
    log "Test Duration: $TEST_DURATION minutes"
    log "Ad Scenarios: $AD_SCENARIOS"
    
    # Pre-flight checks
    if ! check_simulator; then
        error "Simulator check failed"
        exit 1
    fi
    
    if ! check_app; then
        error "App check failed"
        exit 1
    fi
    
    # Run the test
    run_continuous_test "$TEST_DURATION" "$AD_SCENARIOS"
    
    # Generate report
    generate_report
    
    success "iOS Ad Automation completed successfully!"
}

# Handle script interruption
trap 'log "Script interrupted. Cleaning up..."; generate_report; exit 130' INT TERM

# Run main function
main "$@"
