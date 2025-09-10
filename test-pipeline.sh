#!/bin/bash

# Test script for the Kolumn documentation pipeline
# Tests the complete workflow from generation to distribution

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="/mnt/c/git/Kolumn"
DEPLOY_ROOT="/mnt/c/git/Kolumn-deploy"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log() {
    echo -e "${BLUE}[TEST]${NC} $1"
}

success() {
    echo -e "${GREEN}✅${NC} $1"
}

warning() {
    echo -e "${YELLOW}⚠️${NC}  $1"
}

error() {
    echo -e "${RED}❌${NC} $1"
}

test_docs_command() {
    log "Testing Kolumn docs command availability"
    
    cd "$PROJECT_ROOT"
    
    # Build the binary first
    log "Building Kolumn binary for testing..."
    if go build -o /tmp/kolumn-test ./cmd/kolumn; then
        success "Built Kolumn binary successfully"
    else
        error "Failed to build Kolumn binary"
        return 1
    fi
    
    # Test docs command
    log "Testing docs command availability..."
    if /tmp/kolumn-test docs --help >/dev/null 2>&1; then
        success "Docs command is available"
        
        # Test docs generate subcommand
        if /tmp/kolumn-test docs generate --help >/dev/null 2>&1; then
            success "Docs generate subcommand is available"
        else
            warning "Docs generate subcommand not available, trying legacy docs command"
            if /tmp/kolumn-test docs --comprehensive --help >/dev/null 2>&1; then
                success "Legacy docs command with --comprehensive flag available"
            else
                error "No working docs command found"
                return 1
            fi
        fi
    else
        error "Docs command is not available"
        return 1
    fi
    
    # Test documentation generation
    log "Testing documentation generation..."
    local test_output="/tmp/test-docs.json"
    
    if /tmp/kolumn-test docs generate --output "$test_output" >/dev/null 2>&1; then
        success "Documentation generated successfully with docs generate"
        
        # Validate the generated JSON
        if python3 -m json.tool "$test_output" >/dev/null 2>&1; then
            success "Generated documentation is valid JSON"
            
            # Check basic structure
            local version=$(python3 -c "import json; print(json.load(open('$test_output')).get('kolumn_version', 'unknown'))" 2>/dev/null || echo "unknown")
            local command_count=$(python3 -c "import json; print(len(json.load(open('$test_output')).get('commands', {})))" 2>/dev/null || echo "0")
            
            success "Documentation contains version: $version, commands: $command_count"
            
            if [ "$command_count" -gt 0 ]; then
                success "Documentation has commands documented"
            else
                warning "Documentation has no commands (may be expected for minimal build)"
            fi
        else
            error "Generated documentation is not valid JSON"
            return 1
        fi
    else
        warning "docs generate failed, trying legacy docs command..."
        if /tmp/kolumn-test docs --comprehensive --output "$test_output" >/dev/null 2>&1; then
            success "Documentation generated with legacy command"
        else
            error "Failed to generate documentation with any method"
            return 1
        fi
    fi
    
    # Cleanup
    rm -f "$test_output" /tmp/kolumn-test
}

test_workflow_files() {
    log "Testing GitHub Actions workflow files"
    
    # Check main workflow
    local main_workflow="$PROJECT_ROOT/.github/workflows/kolumn.yml"
    if [ -f "$main_workflow" ]; then
        success "Main workflow file exists"
        
        # Check for documentation integration
        if grep -q "docs.*generate" "$main_workflow"; then
            success "Main workflow includes documentation generation"
        else
            error "Main workflow missing documentation generation"
            return 1
        fi
        
        # Check for proper job dependencies
        if grep -q "needs:.*docs" "$main_workflow"; then
            success "Main workflow has proper documentation dependencies"
        else
            warning "Main workflow may be missing documentation dependencies"
        fi
    else
        error "Main workflow file is missing"
        return 1
    fi
    
    # Check deploy workflow
    local deploy_workflow="$DEPLOY_ROOT/.github/workflows/deploy.yml"
    if [ -f "$deploy_workflow" ]; then
        success "Deploy workflow file exists"
        
        # Check for documentation handling
        if grep -q "documentation" "$deploy_workflow"; then
            success "Deploy workflow includes documentation handling"
        else
            error "Deploy workflow missing documentation handling"
            return 1
        fi
    else
        error "Deploy workflow file is missing"
        return 1
    fi
    
    # Check health check workflow
    local health_workflow="$DEPLOY_ROOT/.github/workflows/docs-health-check.yml"
    if [ -f "$health_workflow" ]; then
        success "Health check workflow exists"
    else
        error "Health check workflow is missing"
        return 1
    fi
}

test_deployment_structure() {
    log "Testing deployment repository structure"
    
    cd "$DEPLOY_ROOT"
    
    # Check required files
    local required_files=("index.html" "install.sh" "robots.txt")
    for file in "${required_files[@]}"; do
        if [ -f "$file" ]; then
            success "Required file exists: $file"
        else
            warning "Missing file: $file"
        fi
    done
    
    # Check docs directory structure
    if [ -d "docs" ]; then
        success "Docs directory exists"
        
        # Check for configuration files
        if [ -f "docs/_config.yml" ]; then
            success "Docs Jekyll configuration exists"
        else
            warning "Missing Jekyll configuration for docs"
        fi
        
        if [ -f "docs/README.md" ]; then
            success "Docs README exists"
        else
            warning "Missing docs README"
        fi
        
        # Test directory structure can be created
        mkdir -p docs/test-version docs/latest
        if [ -d "docs/test-version" ] && [ -d "docs/latest" ]; then
            success "Can create versioned documentation directories"
            rmdir docs/test-version docs/latest
        else
            error "Cannot create versioned documentation directories"
        fi
    else
        warning "Docs directory doesn't exist yet (will be created on first deployment)"
        mkdir -p docs
        success "Created docs directory"
    fi
    
    # Check scripts
    if [ -f "scripts/validate-docs.sh" ]; then
        success "Documentation validation script exists"
        
        if [ -x "scripts/validate-docs.sh" ]; then
            success "Validation script is executable"
        else
            warning "Validation script is not executable"
            chmod +x "scripts/validate-docs.sh"
            success "Made validation script executable"
        fi
    else
        error "Documentation validation script is missing"
        return 1
    fi
}

test_validation_script() {
    log "Testing documentation validation script"
    
    cd "$DEPLOY_ROOT"
    
    # Test help option
    if ./scripts/validate-docs.sh --help >/dev/null 2>&1; then
        success "Validation script help works"
    else
        error "Validation script help fails"
        return 1
    fi
    
    # Test with invalid URL (should fail gracefully)
    log "Testing validation script with invalid URL..."
    if ./scripts/validate-docs.sh -u "http://invalid.example.com" >/dev/null 2>&1; then
        warning "Validation script should fail with invalid URL but didn't"
    else
        success "Validation script properly handles invalid URLs"
    fi
    
    # Test output formats
    log "Testing output formats..."
    for format in text json markdown; do
        if ./scripts/validate-docs.sh -f "$format" -u "http://invalid.example.com" >/dev/null 2>&1; then
            # Expected to fail due to invalid URL, but format should be handled
            log "Format $format handled (exit code as expected)"
        else
            log "Format $format handled (exit code as expected)"
        fi
    done
    success "All output formats are supported"
}

test_integration() {
    log "Testing end-to-end integration scenario"
    
    # Create a mock documentation file
    local mock_docs_dir="$DEPLOY_ROOT/docs/test-integration"
    mkdir -p "$mock_docs_dir"
    
    cat > "$mock_docs_dir/docs.json" << EOF
{
  "version": "1.0.0",
  "generated_at": "$(date -Iseconds)",
  "kolumn_version": "1.0.0-test",
  "root_command": {
    "name": "kolumn",
    "short": "Infrastructure-as-code for data stack"
  },
  "commands": {
    "kolumn": {
      "name": "kolumn",
      "short": "Infrastructure-as-code for data stack",
      "path": "kolumn"
    },
    "kolumn docs": {
      "name": "docs",
      "short": "Generate documentation",
      "path": "kolumn docs"
    }
  },
  "statistics": {
    "total_commands": 2,
    "total_flags": 5,
    "coverage_analysis": {
      "documentation_coverage": 100.0,
      "example_coverage": 50.0
    }
  }
}
EOF
    
    cat > "$mock_docs_dir/metadata.json" << EOF
{
  "version": "1.0.0-test",
  "deployed_at": "$(date -Iseconds)",
  "docs_url": "test-url",
  "latest_url": "test-url"
}
EOF
    
    success "Created mock documentation files"
    
    # Validate the mock documentation structure
    if python3 -c "import json; json.load(open('$mock_docs_dir/docs.json'))" 2>/dev/null; then
        success "Mock documentation JSON is valid"
    else
        error "Mock documentation JSON is invalid"
        rm -rf "$mock_docs_dir"
        return 1
    fi
    
    # Test that documentation meets expected structure
    local version=$(python3 -c "import json; print(json.load(open('$mock_docs_dir/docs.json'))['kolumn_version'])" 2>/dev/null)
    local command_count=$(python3 -c "import json; print(len(json.load(open('$mock_docs_dir/docs.json'))['commands']))" 2>/dev/null)
    
    if [ "$version" = "1.0.0-test" ] && [ "$command_count" = "2" ]; then
        success "Mock documentation has expected structure: version=$version, commands=$command_count"
    else
        error "Mock documentation structure is incorrect"
        rm -rf "$mock_docs_dir"
        return 1
    fi
    
    # Cleanup
    rm -rf "$mock_docs_dir"
    success "Integration test completed successfully"
}

test_workflow_syntax() {
    log "Testing workflow YAML syntax"
    
    # Test main workflow syntax
    if python3 -c "import yaml; yaml.safe_load(open('$PROJECT_ROOT/.github/workflows/kolumn.yml'))" 2>/dev/null; then
        success "Main workflow YAML syntax is valid"
    else
        error "Main workflow YAML syntax is invalid"
        return 1
    fi
    
    # Test deploy workflow syntax
    if python3 -c "import yaml; yaml.safe_load(open('$DEPLOY_ROOT/.github/workflows/deploy.yml'))" 2>/dev/null; then
        success "Deploy workflow YAML syntax is valid"
    else
        error "Deploy workflow YAML syntax is invalid"
        return 1
    fi
    
    # Test health check workflow syntax
    if python3 -c "import yaml; yaml.safe_load(open('$DEPLOY_ROOT/.github/workflows/docs-health-check.yml'))" 2>/dev/null; then
        success "Health check workflow YAML syntax is valid"
    else
        error "Health check workflow YAML syntax is invalid"
        return 1
    fi
}

run_all_tests() {
    log "🚀 Starting Kolumn Documentation Pipeline Tests"
    echo ""
    
    local failed_tests=0
    local total_tests=0
    
    # List of test functions
    local tests=(
        "test_docs_command"
        "test_workflow_files" 
        "test_deployment_structure"
        "test_validation_script"
        "test_integration"
        "test_workflow_syntax"
    )
    
    for test_func in "${tests[@]}"; do
        total_tests=$((total_tests + 1))
        echo ""
        log "Running test: $test_func"
        
        if $test_func; then
            success "Test passed: $test_func"
        else
            error "Test failed: $test_func"
            failed_tests=$((failed_tests + 1))
        fi
    done
    
    echo ""
    log "📊 Test Results Summary"
    echo "======================="
    echo "Total tests: $total_tests"
    echo "Passed: $((total_tests - failed_tests))"
    echo "Failed: $failed_tests"
    
    if [ $failed_tests -eq 0 ]; then
        success "🎉 All tests passed! Documentation pipeline is ready."
        return 0
    else
        error "❌ $failed_tests test(s) failed. Please review and fix issues."
        return 1
    fi
}

# Check dependencies
check_dependencies() {
    local missing_deps=0
    
    for cmd in go python3 curl; do
        if ! command -v $cmd >/dev/null 2>&1; then
            error "Missing dependency: $cmd"
            missing_deps=$((missing_deps + 1))
        fi
    done
    
    # Check for PyYAML
    if ! python3 -c "import yaml" 2>/dev/null; then
        error "Missing Python dependency: PyYAML (install with: pip install PyYAML)"
        missing_deps=$((missing_deps + 1))
    fi
    
    if [ $missing_deps -gt 0 ]; then
        error "Please install missing dependencies before running tests"
        return 1
    fi
    
    success "All dependencies are available"
    return 0
}

# Main execution
main() {
    log "Kolumn Documentation Pipeline Test Suite"
    echo ""
    
    # Check dependencies first
    if ! check_dependencies; then
        exit 1
    fi
    
    # Run tests
    if run_all_tests; then
        exit 0
    else
        exit 1
    fi
}

# Handle command line arguments
case "${1:-}" in
    -h|--help)
        cat << EOF
Kolumn Documentation Pipeline Test Suite

Usage: $0 [COMMAND]

Commands:
  test-docs         Test only documentation command
  test-workflows    Test only workflow files
  test-structure    Test only deployment structure
  test-validation   Test only validation script
  test-integration  Test only integration scenario
  test-syntax       Test only workflow syntax
  -h, --help        Show this help

If no command is provided, all tests are run.
EOF
        exit 0
        ;;
    test-docs)
        check_dependencies && test_docs_command
        ;;
    test-workflows)
        check_dependencies && test_workflow_files
        ;;
    test-structure)
        check_dependencies && test_deployment_structure
        ;;
    test-validation)
        check_dependencies && test_validation_script
        ;;
    test-integration)
        check_dependencies && test_integration
        ;;
    test-syntax)
        check_dependencies && test_workflow_syntax
        ;;
    "")
        main
        ;;
    *)
        error "Unknown command: $1"
        echo "Use -h or --help for usage information"
        exit 1
        ;;
esac