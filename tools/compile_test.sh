#!/bin/bash
#
# compile_test.sh - DEPRECATED: Historical migration testing tool
#
# NOTE: This script is no longer needed as benpy now uses bensolve 2.1.0.
# It was used during the migration from bensolve-mod to bensolve 2.1.0.
# Kept for historical reference only.
#
# Original purpose: Test Cython compilation against bensolve 2.1.0 by temporarily
# modifying setup.py to use bensolve 2.1.0 headers and sources.
#
# Usage:
#   ./tools/compile_test.sh [output_file]
#
# Default output: doc/CompileErrorReport.txt

set -e

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
SETUP_PY="${REPO_ROOT}/setup.py"
SETUP_BACKUP="${REPO_ROOT}/setup.py.backup"
OUTPUT_FILE="${1:-${REPO_ROOT}/doc/CompileErrorReport.txt}"
BUILD_LOG="${REPO_ROOT}/build_output.log"

# Colors for terminal output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Helper function to print section headers
print_section() {
    echo ""
    echo "=================================================================================="
    echo "$1"
    echo "=================================================================================="
    echo ""
}

# Cleanup function to ensure we always restore the original setup.py
cleanup() {
    if [ -f "$SETUP_BACKUP" ]; then
        echo -e "${YELLOW}Restoring original setup.py...${NC}"
        mv "$SETUP_BACKUP" "$SETUP_PY"
        echo -e "${GREEN}setup.py restored${NC}"
    fi
    # Clean up build artifacts
    if [ -d "${REPO_ROOT}/build" ]; then
        rm -rf "${REPO_ROOT}/build"
    fi
    if [ -f "${REPO_ROOT}/src/benpy.c" ]; then
        rm -f "${REPO_ROOT}/src/benpy.c"
    fi
}

# Set trap to always run cleanup on exit
trap cleanup EXIT

main() {
    echo -e "${BLUE}Bensolve 2.1.0 Compilation Test${NC}"
    echo -e "${BLUE}================================${NC}"
    echo ""
    echo "This script will:"
    echo "  1. Backup setup.py"
    echo "  2. Modify it to use bensolve-2.1.0"
    echo "  3. Attempt Cython compilation"
    echo "  4. Capture all errors"
    echo "  5. Restore original setup.py"
    echo "  6. Generate error report"
    echo ""
    
    # Check if python is available
    if ! command -v python &> /dev/null; then
        echo -e "${RED}Error: python executable not found${NC}"
        exit 1
    fi
    
    # Check if setup.py exists
    if [ ! -f "$SETUP_PY" ]; then
        echo -e "${RED}Error: setup.py not found at ${SETUP_PY}${NC}"
        exit 1
    fi
    
    # Step 1: Backup setup.py
    echo -e "${YELLOW}Step 1: Backing up setup.py...${NC}"
    cp "$SETUP_PY" "$SETUP_BACKUP"
    echo -e "${GREEN}Backup created: ${SETUP_BACKUP}${NC}"
    echo ""
    
    # Step 2: Modify setup.py to use bensolve-2.1.0
    echo -e "${YELLOW}Step 2: Modifying setup.py to use bensolve-2.1.0...${NC}"
    sed -i 's|bensolve-mod/bslv_|bensolve-2.1.0/bslv_|g' "$SETUP_PY"
    echo -e "${GREEN}setup.py modified${NC}"
    echo ""
    
    # Show the diff
    echo "Changes made to setup.py:"
    diff -u "$SETUP_BACKUP" "$SETUP_PY" || true
    echo ""
    
    # Step 3: Clean previous build artifacts
    echo -e "${YELLOW}Step 3: Cleaning previous build artifacts...${NC}"
    rm -rf "${REPO_ROOT}/build" "${REPO_ROOT}/src/benpy.c" 2>/dev/null || true
    echo -e "${GREEN}Clean complete${NC}"
    echo ""
    
    # Step 4: Attempt compilation
    echo -e "${YELLOW}Step 4: Attempting Cython compilation...${NC}"
    echo "Running: python setup.py build_ext --inplace"
    echo ""
    
    # Capture both stdout and stderr
    if python "${SETUP_PY}" build_ext --inplace > "$BUILD_LOG" 2>&1; then
        echo -e "${GREEN}Compilation succeeded!${NC}"
        COMPILE_STATUS="SUCCESS"
    else
        echo -e "${RED}Compilation failed (as expected)${NC}"
        COMPILE_STATUS="FAILED"
    fi
    echo ""
    
    # Step 5: Generate report
    echo -e "${YELLOW}Step 5: Generating error report...${NC}"
    
    # Create output directory if it doesn't exist
    mkdir -p "$(dirname "$OUTPUT_FILE")"
    
    {
        print_section "Bensolve 2.1.0 Compilation Error Report"
        echo "Generated on: $(date)"
        echo "Test: Cython compilation against bensolve 2.1.0"
        echo "Status: $COMPILE_STATUS"
        echo ""
        echo "This report documents all compilation errors encountered when attempting"
        echo "to build the current Cython wrapper (benpy.pyx) against bensolve 2.1.0"
        echo "headers and source files."
        echo ""
        
        print_section "Build Configuration Changes"
        echo "The following changes were made to setup.py for this test:"
        echo ""
        diff -u "$SETUP_BACKUP" "$SETUP_PY" || true
        echo ""
        
        print_section "Compilation Output"
        echo "Full build output from: python setup.py build_ext --inplace"
        echo ""
        cat "$BUILD_LOG"
        echo ""
        
        print_section "Error Analysis"
        echo ""
        
        if [ "$COMPILE_STATUS" = "SUCCESS" ]; then
            echo "✓ Compilation succeeded without errors!"
            echo ""
            echo "This is unexpected and indicates that either:"
            echo "  - The wrapper is already compatible with bensolve 2.1.0"
            echo "  - The header changes are backward compatible"
            echo ""
        else
            echo "✗ Compilation failed. Analyzing errors..."
            echo ""
            
            # Extract and categorize errors
            echo "--- Error Categories ---"
            echo ""
            
            # Count different types of errors
            local undeclared_count=$(grep -c "undeclared\|was not declared" "$BUILD_LOG" 2>/dev/null || echo "0")
            local type_count=$(grep -c "incompatible type\|type mismatch" "$BUILD_LOG" 2>/dev/null || echo "0")
            local signature_count=$(grep -c "signature\|parameter" "$BUILD_LOG" 2>/dev/null || echo "0")
            local syntax_count=$(grep -c "syntax error\|expected" "$BUILD_LOG" 2>/dev/null || echo "0")
            local undefined_count=$(grep -c "undefined reference\|undefined symbol" "$BUILD_LOG" 2>/dev/null || echo "0")
            
            echo "Error type summary:"
            echo "  - Undeclared identifiers: $undeclared_count"
            echo "  - Type incompatibilities: $type_count"
            echo "  - Signature mismatches: $signature_count"
            echo "  - Syntax errors: $syntax_count"
            echo "  - Undefined references: $undefined_count"
            echo ""
            
            echo "--- Unique Error Messages ---"
            echo ""
            # Extract unique error lines
            grep -i "error:" "$BUILD_LOG" | sort -u | head -50
            echo ""
            
            echo "--- Warnings ---"
            echo ""
            grep -i "warning:" "$BUILD_LOG" | sort -u | head -30
            echo ""
        fi
        
        print_section "Recommendations"
        echo "Based on this compilation test, the following actions are recommended:"
        echo ""
        
        if [ "$COMPILE_STATUS" = "SUCCESS" ]; then
            echo "1. Verify that the compilation truly succeeded (check build artifacts)"
            echo "2. Run tests to ensure functionality is preserved"
            if [ -f "${REPO_ROOT}/doc/HeaderDiffReport.txt" ]; then
                echo "3. Review HeaderDiffReport.txt to understand what changed"
            else
                echo "3. Review header differences to understand what changed"
            fi
            echo "4. Consider if the upgrade can proceed directly"
        else
            echo "1. Review all error messages in the 'Compilation Output' section above"
            if [ -f "${REPO_ROOT}/doc/HeaderDiffReport.txt" ]; then
                echo "2. Compare with HeaderDiffReport.txt to understand API changes"
            else
                echo "2. Compare with header differences to understand API changes"
            fi
            echo "3. Create .pxd files to centralize C declarations (Phase 1)"
            echo "4. Update type definitions, enums, and function signatures in .pxd files"
            echo "5. Modify benpy.pyx to use cimport instead of extern blocks"
            echo "6. Address each error category systematically:"
            echo "   - Undeclared identifiers: Update or remove references"
            echo "   - Type incompatibilities: Update Cython type declarations"
            echo "   - Signature mismatches: Update function prototypes"
            echo "   - Undefined references: Check if functions were removed/renamed"
        fi
        echo ""
        
        print_section "Next Steps"
        echo "Proceed to Phase 1 of the upgrade plan:"
        echo "  1. Create .pxd files in src/ directory (one per bensolve header)"
        echo "  2. Centralize all C declarations from benpy.pyx into .pxd files"
        echo "  3. Update declarations to match bensolve 2.1.0 API"
        echo "  4. Refactor benpy.pyx to cimport from .pxd files"
        echo "  5. Test compilation iteratively"
        echo ""
        echo "See doc/A_plan.md for the complete upgrade strategy."
        echo ""
        
        print_section "End of Report"
        
    } > "$OUTPUT_FILE"
    
    # Clean up build log
    rm -f "$BUILD_LOG"
    
    echo -e "${GREEN}Report generated successfully!${NC}"
    echo "Output: ${OUTPUT_FILE}"
    echo ""
    echo "Compilation status: ${COMPILE_STATUS}"
    echo ""
    echo "To view the report:"
    echo "  cat ${OUTPUT_FILE}"
    echo "  or"
    echo "  less ${OUTPUT_FILE}"
}

# Run main function
main "$@"
