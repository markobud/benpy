# Benpy Test Suite

This directory contains the comprehensive pytest-based test suite for benpy 2.1.0.

## Overview

The test suite validates:
- Basic module imports and structure
- API compatibility and backward compatibility
- Memory management and leak detection
- Example problems from the bensolve distribution
- Problem dimension consistency
- Solution properties and data access

## Running Tests

### Run All Tests

```bash
pytest
```

### Run Specific Test Files

```bash
pytest tests/test_import.py
pytest tests/test_api.py
pytest tests/test_memory.py
pytest tests/test_examples.py
```

### Run by Markers

```bash
# Run only API tests
pytest -m api

# Run only memory tests
pytest -m memory

# Run only example-based tests
pytest -m examples

# Skip slow tests
pytest -m "not slow"
```

### Run with Coverage

```bash
pytest --cov=benpy --cov-report=html
```

## Test Structure

### conftest.py

Pytest configuration and shared fixtures:
- `cleanup_memory`: Auto-cleanup after each test
- `simple_2d_problem`: Basic 2D test problem
- `infeasible_problem`: Infeasible problem fixture
- `unbounded_problem`: Unbounded problem fixture
- `cone_problem`: Problem with custom ordering cone
- `max_problem`: Maximization problem fixture
- `partially_unbounded_problem`: Partially unbounded fixture

### test_import.py

Basic import and module structure tests:
- Module can be imported
- Version information available
- Core classes accessible (vlpProblem, vlpSolution, _cVlpProblem, _cVlpSolution)
- Core functions available (solve, solve_direct)
- Dependencies present (numpy, scipy, prettytable)

### test_api.py

API compatibility and functionality tests:
- **In-memory interface**: from_arrays, solve_direct
- **Matrix recovery**: constraint_matrix, objective_matrix
- **Dimension validation**: Mismatch detection
- **Sparse matrices**: scipy.sparse support
- **Bounds handling**: Various bound combinations
- **Ordering cones**: Y and Z generators
- **Duality parameters**: c vector specification
- **Structure access**: Problem and solution properties
- **Backward compatibility**: Traditional vlpProblem interface
- **Optimization directions**: Minimization and maximization
- **Data types**: float32, float64, integer conversion

### test_memory.py

Memory management and leak detection tests:
- **Deallocation**: __dealloc__ called correctly
- **Multiple allocations**: No leaks when creating many objects
- **Ordering cones**: Memory handling with Y generators
- **Duality parameters**: Memory handling with c vectors
- **Property access**: Safe solution property access
- **File-based problems**: from_file memory management
- **Reference counting**: Python refcount correctness
- **Object reuse**: Reusing problem objects safely
- **NULL initialization**: Safe initialization and cleanup

### test_examples.py

Tests using bensolve example problems:
- **Example 01**: Simple 2-objective MOLP
- **Example 02**: Infeasible problem (expected to fail)
- **Example 03**: Upper image with no vertex
- **Example 04**: Totally unbounded problem
- **Example 05**: VLP with custom ordering cone (3 objectives)
- **Example 06**: Maximization with dual cone
- **Example 08**: Partially unbounded problem
- **Example 11**: 5-objective problem (31 constraints)
- **Consistency checks**: All solvable examples run
- **Dimension validation**: Internal consistency of all examples
- **Solution properties**: Expected structure and data

### problems.py

Python definitions of bensolve example problems:
- Converted from MATLAB (.m) files
- Functions: `get_example01()` through `get_example11()`
- Helper functions:
  - `get_all_examples()`: All examples as dictionary
  - `get_solvable_examples()`: Names of solvable examples
  - `get_infeasible_examples()`: Names of infeasible examples
  - `get_unbounded_examples()`: Names of unbounded examples

## Test Markers

Tests are organized using pytest markers:

- `@pytest.mark.api`: API compatibility tests
- `@pytest.mark.memory`: Memory leak detection tests
- `@pytest.mark.examples`: Example problem tests
- `@pytest.mark.integration`: Full solve operations
- `@pytest.mark.slow`: Tests that take longer to run

## Example Problems Reference

| Example | Description | Type | Status |
|---------|-------------|------|--------|
| example01 | Simple 2-objective MOLP | Minimization | Solvable |
| example02 | Infeasible problem | Minimization | Infeasible |
| example03 | No vertex in upper image | Minimization | Solvable |
| example04 | Totally unbounded | Minimization | Unbounded |
| example05 | Custom ordering cone (q=3) | Minimization | Solvable |
| example06 | Maximization with dual cone | Maximization | Solvable |
| example08 | Partially unbounded | Minimization | Unbounded |
| example11 | 5 objectives, 31 constraints | Minimization | Unbounded |

## Writing New Tests

### Using Fixtures

```python
def test_my_feature(simple_2d_problem):
    """Test using the simple 2D problem fixture."""
    sol = benpy.solve_direct(
        simple_2d_problem['B'],
        simple_2d_problem['P'],
        a=simple_2d_problem.get('a'),
        l=simple_2d_problem.get('l'),
        opt_dir=simple_2d_problem['opt_dir']
    )
    assert sol is not None
```

### Using Markers

```python
@pytest.mark.slow
@pytest.mark.examples
def test_large_problem():
    """Test a large problem (marked as slow)."""
    # ... test code ...
```

### Using Example Problems

```python
from problems import get_example05

def test_with_example():
    """Test using a predefined example."""
    prob_data = get_example05()
    sol = benpy.solve_direct(
        prob_data['B'],
        prob_data['P'],
        # ... other parameters ...
    )
    assert sol is not None
```

## Continuous Integration

These tests are designed to run in CI environments:
- GitHub Actions workflow (when configured)
- Multiple Python versions (3.8, 3.9, 3.10, 3.11, 3.12)
- Multiple platforms (Linux, macOS, Windows)

## Test Coverage

Target coverage areas:
- ✓ Module imports and structure
- ✓ API functions and classes
- ✓ Memory management
- ✓ Example problems
- ✓ Dimension validation
- ✓ Error handling
- ✓ Backward compatibility

## Troubleshooting

### Import Errors

If tests fail with import errors:
```bash
# Install benpy in development mode
pip install -e .
```

### Memory Test Failures

Memory tests may fail if:
- benpy is not properly compiled
- There are actual memory leaks
- System memory is constrained

### Slow Tests

Some tests are marked as slow. Skip them:
```bash
pytest -m "not slow"
```

## Contributing

When adding new features to benpy:
1. Add corresponding tests
2. Use appropriate markers
3. Update this README if adding new test files
4. Ensure all tests pass before submitting PR

## References

- bensolve documentation: http://www.bensolve.org/
- benpy documentation: `/doc/InMemoryInterface.md`
- Example notebooks: `/notebooks/`
- MATLAB examples: `/src/bensolve-2.1.0/ex/`
