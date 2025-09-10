#!/bin/bash

# Kolumn Documentation Validation Script
# Validates documentation manifests for completeness and quality

set -e

# Configuration
BASE_URL="${BASE_URL:-https://schemabounce.github.io/Kolumn-deploy}"
DOCS_BASE_URL="${BASE_URL}/docs"
VERBOSE="${VERBOSE:-false}"
OUTPUT_FORMAT="${OUTPUT_FORMAT:-text}"  # text, json, markdown

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Counters
TOTAL_CHECKS=0
PASSED_CHECKS=0
FAILED_CHECKS=0
WARNING_CHECKS=0

# Results array for JSON output
declare -a RESULTS=()

log() {
    if [ "$VERBOSE" = "true" ]; then
        echo -e "${BLUE}[INFO]${NC} $1" >&2
    fi
}

success() {
    TOTAL_CHECKS=$((TOTAL_CHECKS + 1))
    PASSED_CHECKS=$((PASSED_CHECKS + 1))
    echo -e "${GREEN}✅${NC} $1"
    RESULTS+=("$(printf '{"type":"success","message":"%s","timestamp":"%s"}' "$1" "$(date -Iseconds)")")
}

warning() {
    TOTAL_CHECKS=$((TOTAL_CHECKS + 1))
    WARNING_CHECKS=$((WARNING_CHECKS + 1))
    echo -e "${YELLOW}⚠️${NC}  $1"
    RESULTS+=("$(printf '{"type":"warning","message":"%s","timestamp":"%s"}' "$1" "$(date -Iseconds)")")
}

error() {
    TOTAL_CHECKS=$((TOTAL_CHECKS + 1))
    FAILED_CHECKS=$((FAILED_CHECKS + 1))
    echo -e "${RED}❌${NC} $1"
    RESULTS+=("$(printf '{"type":"error","message":"%s","timestamp":"%s"}' "$1" "$(date -Iseconds)")")
}

check_endpoint() {
    local url="$1"
    local description="$2"
    local required="${3:-true}"
    
    log "Checking endpoint: $url"
    
    if curl -sf "$url" >/dev/null 2>&1; then
        success "$description is accessible"
        return 0
    else
        if [ "$required" = "true" ]; then
            error "$description is not accessible"
        else
            warning "$description is not accessible (optional)"
        fi
        return 1
    fi
}

validate_json() {
    local url="$1"
    local description="$2"
    local temp_file=$(mktemp)
    
    log "Validating JSON from: $url"
    
    if curl -sf "$url" -o "$temp_file" 2>/dev/null; then
        if python3 -m json.tool "$temp_file" >/dev/null 2>&1; then
            success "$description has valid JSON"
            echo "$temp_file"  # Return temp file path for further analysis
            return 0
        else
            error "$description has invalid JSON"
            rm -f "$temp_file"
            return 1
        fi
    else
        error "Failed to download $description"
        rm -f "$temp_file"
        return 1
    fi
}

analyze_docs_structure() {
    local json_file="$1"
    local version_label="$2"
    
    log "Analyzing documentation structure for $version_label"
    
    # Check required fields
    local required_fields=("version" "kolumn_version" "commands")
    
    for field in "${required_fields[@]}"; do
        if python3 -c "import json; json.load(open('$json_file'))['$field']" >/dev/null 2>&1; then
            success "$version_label has required field: $field"
        else
            error "$version_label is missing required field: $field"
        fi
    done
    
    # Check statistics
    if python3 -c "import json; json.load(open('$json_file'))['statistics']" >/dev/null 2>&1; then
        local total_commands=$(python3 -c "import json; print(json.load(open('$json_file'))['statistics'].get('total_commands', 0))" 2>/dev/null || echo "0")
        local total_flags=$(python3 -c "import json; print(json.load(open('$json_file'))['statistics'].get('total_flags', 0))" 2>/dev/null || echo "0")
        
        success "$version_label has statistics: $total_commands commands, $total_flags flags"
        
        if [ "$total_commands" -eq 0 ]; then
            warning "$version_label has no commands documented"
        elif [ "$total_commands" -lt 5 ]; then
            warning "$version_label has very few commands ($total_commands)"
        fi
        
        # Check coverage
        local doc_coverage=$(python3 -c "import json; print(json.load(open('$json_file'))['statistics'].get('coverage_analysis', {}).get('documentation_coverage', 0))" 2>/dev/null || echo "0")
        local example_coverage=$(python3 -c "import json; print(json.load(open('$json_file'))['statistics'].get('coverage_analysis', {}).get('example_coverage', 0))" 2>/dev/null || echo "0")
        
        if python3 -c "exit(0 if $doc_coverage >= 80 else 1)" 2>/dev/null; then
            success "$version_label has good documentation coverage (${doc_coverage}%)"
        elif python3 -c "exit(0 if $doc_coverage >= 50 else 1)" 2>/dev/null; then
            warning "$version_label has moderate documentation coverage (${doc_coverage}%)"
        else
            warning "$version_label has low documentation coverage (${doc_coverage}%)"
        fi
        
        if python3 -c "exit(0 if $example_coverage >= 50 else 1)" 2>/dev/null; then
            success "$version_label has good example coverage (${example_coverage}%)"
        else
            warning "$version_label has low example coverage (${example_coverage}%)"
        fi
    else
        warning "$version_label is missing statistics"
    fi
    
    # Check command structure
    local commands_count=$(python3 -c "import json; print(len(json.load(open('$json_file')).get('commands', {})))" 2>/dev/null || echo "0")
    if [ "$commands_count" -gt 0 ]; then
        success "$version_label has $commands_count commands documented"
        
        # Sample a few commands for detailed validation
        local sample_commands=$(python3 -c "import json; commands = json.load(open('$json_file')).get('commands', {}); print(' '.join(list(commands.keys())[:3]))" 2>/dev/null || echo "")
        
        for cmd in $sample_commands; do
            if python3 -c "import json; cmd = json.load(open('$json_file'))['commands']['$cmd']; assert cmd.get('short'), 'Missing short description'" 2>/dev/null; then
                success "Command '$cmd' has short description"
            else
                warning "Command '$cmd' is missing short description"
            fi
        done
    else
        error "$version_label has no commands documented"
    fi
}

check_performance() {
    local url="$1"
    local description="$2"
    
    log "Checking performance for: $url"
    
    local start_time=$(date +%s%N)
    if curl -sf "$url" >/dev/null 2>&1; then
        local end_time=$(date +%s%N)
        local duration=$((($end_time - $start_time) / 1000000))  # Convert to milliseconds
        
        if [ $duration -lt 1000 ]; then
            success "$description responds quickly (${duration}ms)"
        elif [ $duration -lt 3000 ]; then
            success "$description responds reasonably (${duration}ms)"  
        else
            warning "$description responds slowly (${duration}ms)"
        fi
        
        # Check size
        local temp_file=$(mktemp)
        if curl -sf "$url" -o "$temp_file" 2>/dev/null; then
            local size=$(wc -c < "$temp_file")
            local size_kb=$((size / 1024))
            
            if [ $size_kb -lt 100 ]; then
                success "$description size is optimal (${size_kb}KB)"
            elif [ $size_kb -lt 500 ]; then
                success "$description size is reasonable (${size_kb}KB)"
            else
                warning "$description size is large (${size_kb}KB)"
            fi
            
            rm -f "$temp_file"
        fi
    else
        error "$description is not accessible for performance testing"
    fi
}

check_cors() {
    local url="$1"
    local description="$2"
    
    log "Checking CORS headers for: $url"
    
    local cors_header=$(curl -sI "$url" 2>/dev/null | grep -i "access-control-allow-origin" || echo "")
    if [ -n "$cors_header" ]; then
        success "$description has CORS headers"
    else
        warning "$description is missing CORS headers (may limit browser usage)"
    fi
    
    local content_type=$(curl -sI "$url" 2>/dev/null | grep -i "content-type" || echo "")
    if echo "$content_type" | grep -q "application/json"; then
        success "$description has correct JSON content-type"
    else
        warning "$description may have incorrect content-type for JSON API"
    fi
}

discover_versions() {
    log "Discovering available documentation versions"
    
    # Try to get version from latest docs
    local temp_file=$(mktemp)
    if curl -sf "${DOCS_BASE_URL}/latest/docs.json" -o "$temp_file" 2>/dev/null; then
        local latest_version=$(python3 -c "import json; print(json.load(open('$temp_file')).get('kolumn_version', ''))" 2>/dev/null || echo "")
        if [ -n "$latest_version" ]; then
            echo "$latest_version"
            
            # Try to find other versions based on the latest
            local major_minor=$(echo "$latest_version" | cut -d'.' -f1-2)
            for patch in {0..5}; do
                local test_version="${major_minor}.${patch}"
                if [ "$test_version" != "$latest_version" ]; then
                    if curl -sf "${DOCS_BASE_URL}/v${test_version}/docs.json" >/dev/null 2>&1; then
                        echo "$test_version"
                    fi
                fi
            done
        fi
        rm -f "$temp_file"
    fi
}

output_results() {
    case "$OUTPUT_FORMAT" in
        "json")
            cat << EOF
{
  "summary": {
    "total_checks": $TOTAL_CHECKS,
    "passed": $PASSED_CHECKS,
    "warnings": $WARNING_CHECKS,
    "failed": $FAILED_CHECKS,
    "success_rate": $(printf "%.1f" $(echo "scale=1; $PASSED_CHECKS * 100 / $TOTAL_CHECKS" | bc -l))
  },
  "timestamp": "$(date -Iseconds)",
  "base_url": "$BASE_URL",
  "results": [
    $(IFS=','; echo "${RESULTS[*]}")
  ]
}
EOF
            ;;
        "markdown")
            cat << EOF
# 📚 Kolumn Documentation Validation Report

**Generated:** $(date)  
**Base URL:** $BASE_URL

## 📊 Summary

- **Total Checks:** $TOTAL_CHECKS
- **Passed:** $PASSED_CHECKS ✅
- **Warnings:** $WARNING_CHECKS ⚠️
- **Failed:** $FAILED_CHECKS ❌
- **Success Rate:** $(printf "%.1f%%" $(echo "scale=1; $PASSED_CHECKS * 100 / $TOTAL_CHECKS" | bc -l))

## 🎯 Overall Status

$(if [ $FAILED_CHECKS -eq 0 ] && [ $WARNING_CHECKS -eq 0 ]; then
    echo "🎉 **All checks passed!** Documentation is healthy."
elif [ $FAILED_CHECKS -eq 0 ]; then
    echo "⚠️ **Minor issues found.** Documentation is mostly healthy with some warnings."
else
    echo "❌ **Critical issues found.** Documentation needs attention."
fi)

## 📋 Detailed Results

$(for result in "${RESULTS[@]}"; do
    local type=$(echo "$result" | python3 -c "import json,sys; print(json.load(sys.stdin)['type'])")
    local message=$(echo "$result" | python3 -c "import json,sys; print(json.load(sys.stdin)['message'])")
    case "$type" in
        "success") echo "- ✅ $message" ;;
        "warning") echo "- ⚠️ $message" ;;
        "error") echo "- ❌ $message" ;;
    esac
done)

## 🚀 Recommendations

$(if [ $FAILED_CHECKS -gt 0 ]; then
    echo "1. **Address critical issues immediately** - documentation endpoints are not working properly"
    echo "2. Check GitHub Pages deployment status"
    echo "3. Verify documentation generation pipeline"
elif [ $WARNING_CHECKS -gt 0 ]; then
    echo "1. **Review warnings** - consider optimizing documentation size or coverage"
    echo "2. Add missing CORS headers if needed for browser usage"
    echo "3. Improve documentation coverage for better user experience"
else
    echo "1. **Maintain current quality** - documentation is in excellent condition"
    echo "2. Continue regular health checks"
fi)
EOF
            ;;
        *)
            echo ""
            echo "📚 Kolumn Documentation Validation Results"
            echo "========================================"
            echo ""
            echo "📊 Summary:"
            echo "   Total checks: $TOTAL_CHECKS"
            echo "   Passed: $PASSED_CHECKS"
            echo "   Warnings: $WARNING_CHECKS" 
            echo "   Failed: $FAILED_CHECKS"
            echo "   Success rate: $(printf "%.1f%%" $(echo "scale=1; $PASSED_CHECKS * 100 / $TOTAL_CHECKS" | bc -l))"
            echo ""
            if [ $FAILED_CHECKS -eq 0 ] && [ $WARNING_CHECKS -eq 0 ]; then
                echo "🎉 All checks passed! Documentation is healthy."
            elif [ $FAILED_CHECKS -eq 0 ]; then
                echo "⚠️ Minor issues found. Documentation is mostly healthy."
            else
                echo "❌ Critical issues found. Documentation needs attention."
            fi
            ;;
    esac
}

main() {
    echo "🚀 Starting Kolumn Documentation Validation"
    echo "Base URL: $BASE_URL"
    echo ""
    
    # Check main endpoints
    echo "📡 Checking main documentation endpoints..."
    check_endpoint "${DOCS_BASE_URL}/latest/docs.json" "Latest documentation endpoint"
    check_endpoint "${DOCS_BASE_URL}/latest/metadata.json" "Latest metadata endpoint" "false"
    check_endpoint "${DOCS_BASE_URL}/" "Documentation index" "false"
    check_endpoint "${BASE_URL}/install.sh" "Install script" "false"
    
    # Validate latest documentation JSON
    echo ""
    echo "🔍 Validating latest documentation..."
    local latest_docs_file
    if latest_docs_file=$(validate_json "${DOCS_BASE_URL}/latest/docs.json" "Latest documentation"); then
        analyze_docs_structure "$latest_docs_file" "Latest documentation"
        rm -f "$latest_docs_file"
    fi
    
    # Check performance
    echo ""
    echo "⚡ Checking performance..."
    check_performance "${DOCS_BASE_URL}/latest/docs.json" "Latest documentation endpoint"
    
    # Check CORS and headers
    echo ""
    echo "🌐 Checking API compatibility..."
    check_cors "${DOCS_BASE_URL}/latest/docs.json" "Latest documentation endpoint"
    
    # Discover and check versions
    echo ""
    echo "🔍 Discovering available versions..."
    local versions
    versions=$(discover_versions)
    if [ -n "$versions" ]; then
        success "Found versions: $(echo $versions | tr '\n' ' ')"
        
        # Check a few versions
        local version_count=0
        for version in $versions; do
            if [ $version_count -lt 3 ]; then  # Limit to 3 versions to avoid too many checks
                echo ""
                echo "📋 Checking version $version..."
                check_endpoint "${DOCS_BASE_URL}/v${version}/docs.json" "Version $version documentation"
                check_endpoint "${DOCS_BASE_URL}/v${version}/metadata.json" "Version $version metadata" "false"
                
                local version_docs_file
                if version_docs_file=$(validate_json "${DOCS_BASE_URL}/v${version}/docs.json" "Version $version documentation"); then
                    analyze_docs_structure "$version_docs_file" "Version $version"
                    rm -f "$version_docs_file"
                fi
                
                version_count=$((version_count + 1))
            fi
        done
    else
        warning "No versions discovered - may indicate discovery issues"
    fi
    
    echo ""
    echo "📋 Validation completed!"
    echo ""
    
    # Output results
    output_results
    
    # Exit with appropriate code
    if [ $FAILED_CHECKS -gt 0 ]; then
        exit 1
    elif [ $WARNING_CHECKS -gt 0 ]; then
        exit 2  # Warnings but no failures
    else
        exit 0
    fi
}

# Handle command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -v|--verbose)
            VERBOSE=true
            shift
            ;;
        -f|--format)
            OUTPUT_FORMAT="$2"
            shift 2
            ;;
        -u|--url)
            BASE_URL="$2"
            DOCS_BASE_URL="${BASE_URL}/docs"
            shift 2
            ;;
        -h|--help)
            cat << EOF
Kolumn Documentation Validation Script

Usage: $0 [OPTIONS]

Options:
  -v, --verbose     Enable verbose logging
  -f, --format      Output format (text, json, markdown) [default: text]
  -u, --url         Base URL to validate [default: https://schemabounce.github.io/Kolumn-deploy]
  -h, --help        Show this help message

Environment Variables:
  BASE_URL          Base URL for validation
  VERBOSE           Enable verbose mode (true/false)
  OUTPUT_FORMAT     Output format (text/json/markdown)

Examples:
  $0                           # Basic validation
  $0 -v                        # Verbose validation  
  $0 -f json                   # JSON output
  $0 -u http://localhost:4000  # Test local deployment

Exit Codes:
  0  Success - all checks passed
  1  Failure - critical issues found
  2  Warnings - minor issues found
EOF
            exit 0
            ;;
        *)
            echo "Unknown option: $1" >&2
            echo "Use -h or --help for usage information" >&2
            exit 1
            ;;
    esac
done

# Check dependencies
if ! command -v curl >/dev/null 2>&1; then
    echo "Error: curl is required but not installed" >&2
    exit 1
fi

if ! command -v python3 >/dev/null 2>&1; then
    echo "Error: python3 is required but not installed" >&2
    exit 1
fi

if ! command -v bc >/dev/null 2>&1; then
    echo "Error: bc is required but not installed" >&2
    exit 1
fi

# Run main function
main