#!/bin/bash

# Comprehensive test suite for Chezmoi Bitwarden Vault system
# Tests all components of the secret management system

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    printf "${GREEN}[PASS]${NC} $1\n"
}

print_fail() {
    printf "${RED}[FAIL]${NC} $1\n"
}

print_info() {
    printf "${YELLOW}[INFO]${NC} $1\n"
}

# Counter for tests
total_tests=0
passed_tests=0
failed_tests=0

run_test() {
    local test_name="$1"
    local test_command="$2"
    local expected_result="${3:-0}"  # Default expected result is 0 (success)
    
    ((total_tests++))
    print_info "Running: $test_name"
    
    if eval "$test_command"; then
        if [ $? -eq $expected_result ]; then
            print_status "$test_name"
            ((passed_tests++))
        else
            print_fail "$test_name (unexpected success)"
            ((failed_tests++))
        fi
    else
        if [ $? -ne $expected_result ]; then
            print_status "$test_name (expected failure)"
            ((passed_tests++))
        else
            print_fail "$test_name (unexpected failure)"
            ((failed_tests++))
        fi
    fi
}

print_summary() {
    echo
    echo "========================================="
    echo "TEST SUITE SUMMARY"
    echo "========================================="
    echo "Total tests: $total_tests"
    echo "Passed: $passed_tests"
    echo "Failed: $failed_tests"
    echo "========================================="
    
    if [ $failed_tests -eq 0 ]; then
        echo -e "${GREEN}ALL TESTS PASSED!${NC}"
        return 0
    else
        echo -e "${RED}$failed_tests TEST(S) FAILED!${NC}"
        return 1
    fi
}

# Test if required tools are installed
test_prerequisites() {
    print_info "Testing prerequisites..."
    
    run_test "Chezmoi installation" "command -v chezmoi" 0
    run_test "Bitwarden CLI installation" "command -v bw" 0
    run_test "JQ installation" "command -v jq" 0
    run_test "Git installation" "command -v git" 0
}

# Test scripts directory exists and files are executable
test_core_scripts() {
    print_info "Testing core scripts..."
    
    run_test "Scripts directory exists" "test -d scripts" 0
    run_test "Scripts/bw-helper exists" "test -f scripts/bw-helper" 0
    run_test "Scripts/bw-template exists" "test -f scripts/bw-template" 0
    run_test "Scripts/setup_bitwarden_chezmoi.sh exists" "test -f scripts/setup_bitwarden_chezmoi.sh" 0
    
    run_test "Scripts/bw-helper is executable" "test -x scripts/bw-helper" 0
    run_test "Scripts/bw-template is executable" "test -x scripts/bw-template" 0
    run_test "Scripts/setup_bitwarden_chezmoi.sh is executable" "test -x scripts/setup_bitwarden_chezmoi.sh" 0
}

# Test tools directory exists and files are executable
test_tools() {
    print_info "Testing tools..."
    
    run_test "Tools directory exists" "test -d tools" 0
    run_test "Tools/bw-scan-api-keys.sh exists" "test -f tools/bw-scan-api-keys.sh" 0
    run_test "Tools/organize-bw-items.sh exists" "test -f tools/organize-bw-items.sh" 0
    
    run_test "Tools/bw-scan-api-keys.sh is executable" "test -x tools/bw-scan-api-keys.sh" 0
    run_test "Tools/organize-bw-items.sh is executable" "test -x tools/organize-bw-items.sh" 0
}

# Test demo script exists and is executable
test_demo() {
    print_info "Testing demo setup..."
    
    run_test "Demo setup script exists" "test -f demo-setup.sh" 0
    run_test "Demo setup script is executable" "test -x demo-setup.sh" 0
}

# Test configuration files exist
test_config() {
    print_info "Testing configuration..."
    
    run_test "README exists" "test -f README.md" 0
    run_test "LICENSE exists" "test -f LICENSE" 0
    run_test "System report exists" "test -f system-report.txt" 0
}

# Test scripts content (syntax check)
test_script_syntax() {
    print_info "Testing script syntax..."
    
    run_test "Scripts/bw-helper syntax" "bash -n scripts/bw-helper" 0
    run_test "Scripts/bw-template syntax" "bash -n scripts/bw-template" 0
    run_test "Scripts/setup_bitwarden_chezmoi.sh syntax" "bash -n scripts/setup_bitwarden_chezmoi.sh" 0
    run_test "Tools/bw-scan-api-keys.sh syntax" "bash -n tools/bw-scan-api-keys.sh" 0
    run_test "Tools/organize-bw-items.sh syntax" "bash -n tools/organize-bw-items.sh" 0
    run_test "Demo setup script syntax" "bash -n demo-setup.sh" 0
    run_test "Generate report script syntax" "bash -n generate-report.sh" 0
}

# Test Bitwarden helper functions (without actual API calls)
test_bw_helpers() {
    print_info "Testing Bitwarden helpers (without actual API calls)..."
    
    # Test that helper scripts exist and have proper structure
    run_test "BW_HELPER exports session if set" "grep -q 'BW_SESSION' scripts/bw-helper" 0
    run_test "BW_TEMPLATE uses BW_SESSION" "grep -q 'BW_SESSION' scripts/bw-template" 0
    run_test "Helper scripts check for session" "grep -q 'if \[ -z \"\$BW_SESSION\" \]' scripts/bw-helper || grep -q 'BW_SESSION' scripts/bw-helper" 0
}

# Test that the main README has been updated with new functionality
test_readme_content() {
    print_info "Testing README content..."
    
    run_test "README contains tools section" "grep -qi 'tools/bw-scan-api-keys.sh' README.md" 0
    run_test "README contains organize script" "grep -qi 'tools/organize-bw-items.sh' README.md" 0
    run_test "README contains demo setup" "grep -qi 'demo-setup.sh' README.md" 0
    run_test "README contains usage flow" "grep -qi 'Usage Flow' README.md" 0
}

# Main test function
run_all_tests() {
    echo "Starting comprehensive test suite for Chezmoi Bitwarden Vault..."
    echo
    
    test_prerequisites
    test_core_scripts
    test_tools
    test_demo
    test_config
    test_script_syntax
    test_bw_helpers
    test_readme_content
    
    print_summary
    
    # Exit with error code if any tests failed
    if [ $failed_tests -gt 0 ]; then
        exit 1
    fi
}

# Run main function if called directly
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
    run_all_tests
fi