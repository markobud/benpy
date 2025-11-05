# Benpy Example Notebooks

This directory contains Jupyter notebooks demonstrating the use of benpy for solving vector linear programs (VLPs) and multi-objective linear programs (MOLPs).

## Notebooks

### Basic Examples

- **example01.ipynb** - Simple 2-objective MOLP
  - Introduction to benpy
  - Both direct and traditional interfaces
  - Basic constraint and objective setup

### Advanced Examples

- **example05.ipynb** - VLP with Custom Ordering Cone
  - 3 objectives
  - Custom ordering cone via generators Y
  - Duality parameter specification

- **example06.ipynb** - Maximization Problem
  - Maximization (opt_dir=-1)
  - Ordering cone via dual generators Z
  - Variable and constraint bounds

## Running the Notebooks

### Prerequisites

Make sure benpy is installed:

```bash
pip install benpy
```

Or from source:

```bash
cd /path/to/benpy
pip install -e .
```

### Launch Jupyter

```bash
jupyter notebook
```

Then navigate to the `notebooks/` directory and open any example.

## Example Problem Sources

These examples are based on the MATLAB examples from the bensolve distribution:
- `src/bensolve-2.1.0/ex/example01.m`
- `src/bensolve-2.1.0/ex/example05.m`
- `src/bensolve-2.1.0/ex/example06.m`

They have been converted to Python and adapted to demonstrate benpy's features.

## Additional Resources

- **benpy Documentation**: See `/doc/InMemoryInterface.md` for details on the in-memory interface
- **Bensolve Website**: http://www.bensolve.org/
- **Test Suite**: See `/tests/` for more problem examples

## Problem Types Covered

- **MOLP** (Multi-Objective Linear Programming): Standard bi-objective and multi-objective problems
- **VLP** (Vector Linear Programming): Problems with custom ordering cones
- **Minimization and Maximization**: Both optimization directions
- **Bounded and Unbounded**: Various constraint types

## Notes

- The fast `solve_direct()` interface is recommended for production use
- The traditional `vlpProblem` interface is also available for compatibility
- All examples demonstrate proper memory management
- Solutions include primal and dual information
