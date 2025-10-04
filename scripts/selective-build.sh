#!/bin/bash

# Selective build script based on changed files
# This script detects changes and builds only affected services

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Get changed files (works with git)
get_changed_files() {
    if [ -n "$GITHUB_SHA" ] && [ -n "$GITHUB_BASE_REF" ]; then
        # GitHub Actions
        git diff --name-only origin/$GITHUB_BASE_REF..HEAD
    elif [ -n "$CI_COMMIT_SHA" ] && [ -n "$CI_MERGE_REQUEST_TARGET_BRANCH_SHA" ]; then
        # GitLab CI
        git diff --name-only $CI_MERGE_REQUEST_TARGET_BRANCH_SHA..HEAD
    else
        # Local development - compare with origin/main
        git diff --name-only origin/main..HEAD 2>/dev/null || git diff --name-only HEAD~1..HEAD
    fi
}

# Determine which services need to be built
determine_build_targets() {
    local changed_files="$1"
    local targets=()
    
    # Check bot service
    if echo "$changed_files" | grep -q "^api/bot_service/"; then
        targets+=("//api/bot_service:bot_service_image")
        print_status "Bot service changes detected"
    fi
    
    # Check user service
    if echo "$changed_files" | grep -q "^api/user_service/"; then
        targets+=("//api/user_service:user_service_image")
        print_status "User service changes detected"
    fi
    
    # Check admin UI
    if echo "$changed_files" | grep -q "^ui/admin_ui/"; then
        targets+=("//ui/admin_ui:admin_ui_image")
        print_status "Admin UI changes detected"
    fi
    
    # Check client UI
    if echo "$changed_files" | grep -q "^ui/client_ui/"; then
        targets+=("//ui/client_ui:client_ui_image")
        print_status "Client UI changes detected"
    fi
    
    # Check for root level changes that affect all services
    if echo "$changed_files" | grep -qE "^(WORKSPACE|\.bazelrc|BUILD)"; then
        targets=("//api/bot_service:bot_service_image" 
                "//api/user_service:user_service_image" 
                "//ui/admin_ui:admin_ui_image" 
                "//ui/client_ui:client_ui_image")
        print_warning "Root configuration changes detected - building all services"
    fi
    
    printf "%s\n" "${targets[@]}"
}

# Build function
build_targets() {
    local targets=("$@")
    
    if [ ${#targets[@]} -eq 0 ]; then
        print_warning "No targets to build"
        return 0
    fi
    
    print_status "Building targets: ${targets[*]}"
    
    # Run bazel build
    if bazel build "${targets[@]}"; then
        print_success "Build completed successfully"
        return 0
    else
        print_error "Build failed"
        return 1
    fi
}

# Test function
run_tests() {
    local changed_files="$1"
    local test_targets=()
    
    # Determine test targets based on changes
    if echo "$changed_files" | grep -q "^api/bot_service/"; then
        test_targets+=("//api/bot_service:test")
    fi
    
    if echo "$changed_files" | grep -q "^api/user_service/"; then
        test_targets+=("//api/user_service:test")
    fi
    
    if echo "$changed_files" | grep -q "^ui/admin_ui/"; then
        test_targets+=("//ui/admin_ui:test")
    fi
    
    if echo "$changed_files" | grep -q "^ui/client_ui/"; then
        test_targets+=("//ui/client_ui:test")
    fi
    
    if [ ${#test_targets[@]} -gt 0 ]; then
        print_status "Running tests: ${test_targets[*]}"
        if bazel test "${test_targets[@]}"; then
            print_success "Tests passed"
            return 0
        else
            print_error "Tests failed"
            return 1
        fi
    else
        print_warning "No tests to run"
        return 0
    fi
}

# Lint function
run_linting() {
    local changed_files="$1"
    local lint_targets=()
    
    # Determine lint targets based on changes
    if echo "$changed_files" | grep -q "^api/user_service/"; then
        lint_targets+=("//api/user_service:lint")
    fi
    
    if echo "$changed_files" | grep -q "^ui/admin_ui/"; then
        lint_targets+=("//ui/admin_ui:lint")
    fi
    
    if echo "$changed_files" | grep -q "^ui/client_ui/"; then
        lint_targets+=("//ui/client_ui:lint")
    fi
    
    if [ ${#lint_targets[@]} -gt 0 ]; then
        print_status "Running linting: ${lint_targets[*]}"
        if bazel run "${lint_targets[@]}"; then
            print_success "Linting passed"
            return 0
        else
            print_error "Linting failed"
            return 1
        fi
    else
        print_warning "No linting to run"
        return 0
    fi
}

# Deploy to Minikube
deploy_to_minikube() {
    local changed_files="$1"
    
    if [ -z "$changed_files" ]; then
        print_status "No changes detected, performing full deployment"
        ./scripts/minikube-deploy.sh deploy
    else
        print_status "Changes detected, performing selective deployment"
        ./scripts/minikube-deploy.sh selective "$changed_files"
    fi
}

# Main execution
main() {
    local mode="${1:-build}"
    
    print_status "Starting selective build process..."
    
    # Get changed files
    local changed_files
    changed_files=$(get_changed_files)
    
    if [ -z "$changed_files" ]; then
        print_warning "No changes detected"
        if [ "$mode" != "deploy" ]; then
            exit 0
        fi
    fi
    
    if [ -n "$changed_files" ]; then
        print_status "Changed files:"
        echo "$changed_files" | sed 's/^/  /'
    fi
    
    # Determine build targets
    local targets
    readarray -t targets < <(determine_build_targets "$changed_files")
    
    case "$mode" in
        "build")
            build_targets "${targets[@]}"
            ;;
        "test")
            run_tests "$changed_files"
            ;;
        "lint")
            run_linting "$changed_files"
            ;;
        "deploy")
            deploy_to_minikube "$changed_files"
            ;;
        "all")
            run_linting "$changed_files" && \
            run_tests "$changed_files" && \
            build_targets "${targets[@]}"
            ;;
        *)
            print_error "Unknown mode: $mode"
            echo "Usage: $0 [build|test|lint|deploy|all]"
            exit 1
            ;;
    esac
}

# Run main function with all arguments
main "$@"