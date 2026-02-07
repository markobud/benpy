# Tools Directory

This directory contains utility scripts for the benpy project.

## diff_headers.sh

A comprehensive script to compare bensolve header files between different versions (historical migration tool).

### Purpose

This tool automates the analysis of API changes between the legacy bensolve-mod fork and bensolve 2.1.0. It generates a detailed report showing:

- Full unified diffs for each header file
- Version string changes
- Typedef differences
- Define macro changes
- Function signature modifications
- Enum value additions/removals
- Struct definition changes

### Usage

```bash
# Generate report with default output location (doc/HeaderDiffReport.txt)
./tools/diff_headers.sh

# Generate report with custom output location
./tools/diff_headers.sh /path/to/output.txt
```

### Requirements

- Bash shell
- Standard Unix tools: `diff`, `grep`, `sed`
- Access to both `src/bensolve-mod` (historical) and `src/bensolve-2.1.0` directories

### Output

The script generates a comprehensive report that includes:

1. **Summary Section**: Lists all header files analyzed
2. **Detailed Diff Analysis**: For each header file:
   - Full unified diff
   - Version string comparison
   - Typedef analysis
   - Define macro comparison
   - Function declaration changes
   - Enum definition changes
   - Struct definition changes
3. **Recommendations**: Suggested next steps for the upgrade process

### Example

```bash
cd /home/runner/work/benpy/benpy
./tools/diff_headers.sh

# View the generated report
less doc/HeaderDiffReport.txt
```

### Notes

- The script can be run from any directory (it determines paths relative to itself)
- Running the script multiple times will overwrite the previous report
- The script exits with code 0 on success, non-zero on error
- Changes are categorized to help understand the upgrade impact

## compile_test.sh

**DEPRECATED**: This script was used during the migration from bensolve-mod to bensolve 2.1.0 and is no longer needed. Kept for historical reference only.

The script was designed to temporarily modify setup.py to test compilation against bensolve 2.1.0. Since benpy now uses bensolve 2.1.0 by default, this tool is obsolete.
