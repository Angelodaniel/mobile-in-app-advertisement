#!/bin/bash

# Test Automation Script
# This script helps you test the automation setup locally

set -e

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

# Function to check prerequisites
check_prerequisites() {
    log "Checking prerequisites..."
    
    # Check if Xcode is installed
    if ! command -v xcodebuild &> /dev/null; then
        error "Xcode is not installed or not in PATH"
        return 1
    fi
    
    # Check if Ruby is installed
    if ! command -v ruby &> /dev/null; then
        error "Ruby is not installed"
        return 1
    fi
    
    # Check if Bundle is available
    if ! command -v bundle &> /dev/null; then
        error "Bundler is not installed. Run: gem install bundler"
        return 1
    fi
    
    # Check if Fastlane is available
    if ! bundle exec fastlane --version &> /dev/null; then
        warning "Fastlane not found in bundle. Installing dependencies..."
        bundle install
    fi
    
    success "Prerequisites check passed"
    return 0
}

# Function to test Fastlane setup
test_fastlane() {
    log "Testing Fastlane setup..."
    
    # Test CI setup
    bundle exec fastlane ci_setup
    
    # Test build
    bundle exec fastlane build_and_test
    
    success "Fastlane setup test passed"
}

# Function to test automation script
test_automation_script() {
    log "Testing automation script..."
    
    # Make script executable
    chmod +x scripts/ios-ad-automation.sh
    
    # Test script help
    if ./scripts/ios-ad-automation.sh --help 2>/dev/null; then
        success "Automation script is executable"
    else
        warning "Automation script help not available, but script exists"
    fi
}

# Function to run a quick test
run_quick_test() {
    log "Running quick automation test..."
    
    # Set environment variables for quick test
    export TEST_DURATION=2
    export AD_SCENARIOS=working
    
    # Run automation
    bundle exec fastlane ad_automation
    
    success "Quick test completed"
}

# Function to show usage
show_usage() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  --check-only    Only check prerequisites, don't run tests"
    echo "  --quick-test    Run a quick 2-minute test"
    echo "  --help          Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0                    # Check prerequisites and run quick test"
    echo "  $0 --check-only       # Only check prerequisites"
    echo "  $0 --quick-test       # Run quick test after checks"
}

# Main function
main() {
    local check_only=false
    local quick_test=false
    
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --check-only)
                check_only=true
                shift
                ;;
            --quick-test)
                quick_test=true
                shift
                ;;
            --help)
                show_usage
                exit 0
                ;;
            *)
                error "Unknown option: $1"
                show_usage
                exit 1
                ;;
        esac
    done
    
    log "Starting automation test setup"
    
    # Check prerequisites
    if ! check_prerequisites; then
        error "Prerequisites check failed"
        exit 1
    fi
    
    if [ "$check_only" = true ]; then
        success "Prerequisites check completed successfully"
        exit 0
    fi
    
    # Test Fastlane
    test_fastlane
    
    # Test automation script
    test_automation_script
    
    # Run quick test if requested
    if [ "$quick_test" = true ]; then
        run_quick_test
    fi
    
    success "All tests completed successfully!"
    log "You can now run the full automation with:"
    log "  bundle exec fastlane ad_automation"
    log "  ./scripts/ios-ad-automation.sh"
    log "  Or trigger GitHub Actions workflows manually"
}

# Run main function
main "$@"
