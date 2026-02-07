#!/bin/bash
#
# diff_headers.sh - Compare bensolve headers between two versions (historical comparison tool)
#
# This script compares the header files (.h) between the legacy bensolve-mod fork
# and the official bensolve 2.1.0 version for migration analysis.
#
# Usage:
#   ./tools/diff_headers.sh [output_file]
#
# Default output: doc/HeaderDiffReport.txt

set -e

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
MOD_DIR="${REPO_ROOT}/src/bensolve-mod"
V210_DIR="${REPO_ROOT}/src/bensolve-2.1.0"
OUTPUT_FILE="${1:-${REPO_ROOT}/doc/HeaderDiffReport.txt}"

# Colors for terminal output (optional)
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Header files to compare
HEADERS=(
    "bslv_main.h"
    "bslv_lp.h"
    "bslv_vlp.h"
    "bslv_algs.h"
    "bslv_lists.h"
    "bslv_poly.h"
)

# Helper function to print section headers
print_section() {
    echo ""
    echo "=================================================================================="
    echo "$1"
    echo "=================================================================================="
    echo ""
}

# Helper function to extract function declarations from a header file
extract_functions() {
    local file="$1"
    # Extract function declarations (lines ending with semicolon after a type)
    # This is a simplified approach that catches most function declarations
    grep -E '^[a-zA-Z_][a-zA-Z0-9_*\s]+\s+[a-zA-Z_][a-zA-Z0-9_*]*\s*\([^)]*\)\s*;' "$file" || true
}

# Helper function to extract typedefs
extract_typedefs() {
    local file="$1"
    grep -E '^typedef' "$file" || true
}

# Helper function to extract #define macros
extract_defines() {
    local file="$1"
    grep -E '^#define' "$file" || true
}

# Helper function to extract enums
extract_enums() {
    local file="$1"
    # Extract enum definitions
    sed -n '/^typedef enum/,/^}/p' "$file" || true
}

# Helper function to extract structs
extract_structs() {
    local file="$1"
    # Extract struct definitions
    sed -n '/^typedef struct/,/^}/p' "$file" || true
}

# Main function
main() {
    echo -e "${BLUE}Bensolve Header Diff Analysis${NC}"
    echo -e "${BLUE}==============================${NC}"
    echo ""
    echo "Comparing:"
    echo "  Current:  ${MOD_DIR}"
    echo "  Target:   ${V210_DIR}"
    echo "  Output:   ${OUTPUT_FILE}"
    echo ""

    # Check if directories exist
    if [ ! -d "$MOD_DIR" ]; then
        echo -e "${RED}Error: bensolve-mod directory not found at ${MOD_DIR}${NC}"
        exit 1
    fi

    if [ ! -d "$V210_DIR" ]; then
        echo -e "${RED}Error: bensolve-2.1.0 directory not found at ${V210_DIR}${NC}"
        exit 1
    fi

    # Create output directory if it doesn't exist
    mkdir -p "$(dirname "$OUTPUT_FILE")"

    # Generate the report
    {
        print_section "Bensolve Header Diff Report"
        echo "Generated on: $(date)"
        echo "Comparing: bensolve-mod vs bensolve-2.1.0"
        echo ""
        echo "This report analyzes API changes between the current vendored version"
        echo "(bensolve-mod) and the official bensolve 2.1.0 release."
        echo ""

        print_section "Summary of Header Files"
        echo "Header files analyzed:"
        for header in "${HEADERS[@]}"; do
            echo "  - $header"
        done
        echo ""

        print_section "Detailed Diff Analysis"

        for header in "${HEADERS[@]}"; do
            mod_file="${MOD_DIR}/${header}"
            v210_file="${V210_DIR}/${header}"

            echo ""
            echo "--------------------------------------------------------------------------------"
            echo "FILE: ${header}"
            echo "--------------------------------------------------------------------------------"
            echo ""

            if [ ! -f "$mod_file" ]; then
                echo "WARNING: ${mod_file} does not exist!"
                echo ""
                continue
            fi

            if [ ! -f "$v210_file" ]; then
                echo "WARNING: ${v210_file} does not exist!"
                echo ""
                continue
            fi

            # Check if files are identical
            if diff -q "$mod_file" "$v210_file" > /dev/null 2>&1; then
                echo "✓ No changes - Files are identical"
                echo ""
                continue
            fi

            echo "✗ Changes detected"
            echo ""

            # Full unified diff
            echo "--- Full Unified Diff ---"
            echo ""
            diff -u "$mod_file" "$v210_file" || true
            echo ""

            # Analyze specific changes
            echo "--- Analysis by Category ---"
            echo ""

            # Version strings
            echo "VERSION STRINGS:"
            echo "  bensolve-mod:"
            grep -i "version\|THISVERSION" "$mod_file" || echo "    (none found)"
            echo "  bensolve-2.1.0:"
            grep -i "version\|THISVERSION" "$v210_file" || echo "    (none found)"
            echo ""

            # Typedefs
            echo "TYPEDEFS:"
            echo "  bensolve-mod:"
            extract_typedefs "$mod_file" | sed 's/^/    /'
            echo "  bensolve-2.1.0:"
            extract_typedefs "$v210_file" | sed 's/^/    /'
            echo ""

            # Defines
            echo "DEFINES (sample):"
            echo "  bensolve-mod (count: $(extract_defines "$mod_file" | wc -l)):"
            extract_defines "$mod_file" | head -10 | sed 's/^/    /'
            echo "  bensolve-2.1.0 (count: $(extract_defines "$v210_file" | wc -l)):"
            extract_defines "$v210_file" | head -10 | sed 's/^/    /'
            echo ""

            # Function declarations
            echo "FUNCTION DECLARATIONS:"
            echo "  bensolve-mod:"
            extract_functions "$mod_file" | sed 's/^/    /'
            echo "  bensolve-2.1.0:"
            extract_functions "$v210_file" | sed 's/^/    /'
            echo ""

            # Enums
            echo "ENUMS:"
            local mod_enums=$(extract_enums "$mod_file")
            local v210_enums=$(extract_enums "$v210_file")
            if [ -n "$mod_enums" ] || [ -n "$v210_enums" ]; then
                echo "  bensolve-mod:"
                echo "$mod_enums" | sed 's/^/    /'
                echo "  bensolve-2.1.0:"
                echo "$v210_enums" | sed 's/^/    /'
            else
                echo "  (none found in either version)"
            fi
            echo ""

            # Structs
            echo "STRUCTS:"
            local mod_structs=$(extract_structs "$mod_file")
            local v210_structs=$(extract_structs "$v210_file")
            if [ -n "$mod_structs" ] || [ -n "$v210_structs" ]; then
                echo "  bensolve-mod:"
                echo "$mod_structs" | sed 's/^/    /'
                echo "  bensolve-2.1.0:"
                echo "$v210_structs" | sed 's/^/    /'
            else
                echo "  (none found in either version)"
            fi
            echo ""
        done

        print_section "Recommendations"
        echo "Based on this diff, the following updates may be needed:"
        echo ""
        echo "1. Update version strings in wrapper code (if any reference THISVERSION)"
        echo "2. Review and update Cython .pxd files with new function signatures"
        echo "3. Check for any new/removed/modified enum values"
        echo "4. Verify struct definitions match in Cython declarations"
        echo "5. Update any #define constants that changed"
        echo "6. Test compilation with updated declarations"
        echo ""
        echo "Next steps:"
        echo "  - Review this report carefully"
        echo "  - Create .pxd files for Cython declarations"
        echo "  - Update benpy.pyx to use new declarations"
        echo "  - Run test builds to identify issues"
        echo ""

        print_section "End of Report"

    } > "$OUTPUT_FILE"

    echo -e "${GREEN}Report generated successfully!${NC}"
    echo "Output: ${OUTPUT_FILE}"
    echo ""
    echo -e "${YELLOW}Summary:${NC}"
    grep -c "✗ Changes detected\|✓ No changes" "$OUTPUT_FILE" || true
    echo ""
    echo "To view the report:"
    echo "  cat ${OUTPUT_FILE}"
    echo "  or"
    echo "  less ${OUTPUT_FILE}"
}

# Run main function
main "$@"
