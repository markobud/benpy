# In-Memory Interface for benpy

This document describes the new in-memory interface for benpy that eliminates file I/O overhead and provides direct access to C data structures.

## New Features

### 1. `solve_direct()` - Solve without File I/O

The `solve_direct()` function allows you to solve VLP problems directly from numpy arrays without creating temporary files:

```python
import numpy as np
import benpy

# Define problem matrices
B = np.array([[2.0, 1.0],
              [1.0, 2.0]])  # Constraint matrix (m x n)

P = np.array([[1.0, 0.0],
              [0.0, 1.0]])  # Objective matrix (q x n)

b = np.array([4.0, 4.0])   # Upper bounds on constraints
l = np.array([0.0, 0.0])   # Lower bounds on variables

# Solve directly from arrays (no files!)
sol = benpy.solve_direct(B, P, b=b, l=l, opt_dir=1)

print(f"Found {len(sol.Primal.vertex_value)} efficient points")
```

**Benefits:**
- 2-3x faster than file-based approach
- No temporary files created
- Cleaner, more Pythonic API
- Works seamlessly with numpy arrays

### 2. Direct Structure Access

Access problem and solution data directly through Python properties:

```python
from benpy import _cVlpProblem

# Create and initialize problem
prob = _cVlpProblem()
prob.from_arrays(B, P, b=b, l=l, opt_dir=1)

# Access problem dimensions
print(f"Constraints: {prob.m}")
print(f"Variables: {prob.n}")
print(f"Objectives: {prob.q}")

# Extract matrices
A = prob.constraint_matrix  # Dense numpy array
P = prob.objective_matrix   # Dense numpy array
```

### 3. Solution Data Access

Access solution data in memory without extracting from files:

```python
# After solving...
sol_internal = _csolve(prob)

# Access solution properties
print(f"Status: {sol_internal.status}")
print(f"Upper vertices: {sol_internal.num_vertices_upper}")
print(f"Lower vertices: {sol_internal.num_vertices_lower}")

# Access solution matrices
Y = sol_internal.Y  # Ordering cone generators
Z = sol_internal.Z  # Dual cone generators
c = sol_internal.c_vector  # Duality parameter
```

## API Reference

### `solve_direct(B, P, a=None, b=None, l=None, s=None, Y=None, Z=None, c=None, opt_dir=1, options=None)`

Solve a VLP problem directly from arrays.

**Parameters:**
- `B` : array-like (m x n) - Constraint matrix
- `P` : array-like (q x n) - Objective matrix  
- `a` : array-like (m,), optional - Lower bounds on constraints (default: -∞)
- `b` : array-like (m,), optional - Upper bounds on constraints (default: +∞)
- `l` : array-like (n,), optional - Lower bounds on variables (default: -∞)
- `s` : array-like (n,), optional - Upper bounds on variables (default: +∞)
- `Y` : array-like (q x k), optional - Ordering cone generators (primal)
- `Z` : array-like (q x k), optional - Ordering cone generators (dual)
- `c` : array-like (q,), optional - Duality parameter vector
- `opt_dir` : int - Optimization direction (1=minimize, -1=maximize)
- `options` : dict, optional - Solver options

**Returns:**
- `vlpSolution` - Solution object with Primal and Dual polytopes

### `_cVlpProblem.from_arrays(B, P, a=None, b=None, l=None, s=None, Y=None, Z=None, c=None, opt_dir=1)`

Initialize a VLP problem from numpy arrays.

**Parameters:** Same as `solve_direct()`

**Example:**
```python
prob = benpy._cVlpProblem()
prob.from_arrays(B, P, b=b, l=l, opt_dir=1)
```

### Problem Properties

Access problem data through properties:

- `prob.m` - Number of constraints
- `prob.n` - Number of variables
- `prob.q` - Number of objectives
- `prob.nz` - Number of non-zero constraint entries
- `prob.nzobj` - Number of non-zero objective entries
- `prob.optdir` - Optimization direction
- `prob.constraint_matrix` - Constraint matrix as numpy array
- `prob.objective_matrix` - Objective matrix as numpy array

### Solution Properties

Access solution data through properties:

- `sol.status` - Solution status code
- `sol.num_vertices_upper` - Number of vertices in upper image
- `sol.num_vertices_lower` - Number of vertices in lower image
- `sol.num_extreme_directions_upper` - Number of extreme directions (upper)
- `sol.num_extreme_directions_lower` - Number of extreme directions (lower)
- `sol.eta` - Phase 0 result
- `sol.Y` - Ordering cone generators (primal)
- `sol.Z` - Dual cone generators
- `sol.c_vector` - Duality parameter vector
- `sol.R` - Recession cone generators (dual)
- `sol.H` - Recession cone generators (primal)

## Performance Comparison

Benchmark on a problem with 20 constraints, 50 variables, 3 objectives:

| Method | Time | Speedup |
|--------|------|---------|
| Traditional `solve()` | 0.0046s | 1.0x |
| New `solve_direct()` | 0.0017s | **2.7x** |

The speedup comes from:
1. No file creation/deletion overhead
2. No file I/O system calls
3. Direct memory operations
4. Reduced memory allocations

## Migration Guide

### Before (File-based)
```python
# Old approach with file I/O
prob = benpy.vlpProblem(B=B, P=P, b=b, l=l, opt_dir=1)
sol = benpy.solve(prob)
```

### After (Memory-based)
```python
# New approach without file I/O
sol = benpy.solve_direct(B, P, b=b, l=l, opt_dir=1)
```

Both approaches produce identical results. The new approach is recommended for better performance.

## Examples

See `example_memory_interface.py` for complete examples including:
- Basic bi-objective optimization
- Direct structure access
- Custom ordering cones
- Performance benchmarks

## Implementation Details

The in-memory interface works by:

1. **Direct Structure Population**: The `from_arrays()` method directly populates the C `vlptype` structure using list allocation functions from `bslv_lists.h`

2. **Sparse Matrix Handling**: Input arrays are converted to sparse format internally, matching bensolve's internal representation

3. **Memory Management**: Proper allocation and deallocation using C malloc/free ensures no memory leaks

4. **Zero-Copy Where Possible**: Data is copied efficiently from numpy arrays to C structures with minimal overhead

## Compatibility

- Fully compatible with bensolve 2.1.0
- Works with all existing solver options
- Backward compatible with file-based `solve()` method
- Python 3.8+ required
- NumPy and SciPy required for array handling

## Known Limitations

1. Very large problems (>10,000 variables) may benefit more from sparse file formats
2. Problem definition must fit in memory (not suitable for out-of-core problems)
3. Some advanced file-based features (problem archiving, logging) not available

## Future Enhancements

Planned improvements:
- [ ] Add support for reading/writing problem structures to binary format
- [ ] Implement zero-copy views of solution data
- [ ] Add MPI support for distributed memory problems
- [ ] Expose more internal solver state for debugging

## Contributing

To contribute improvements to the in-memory interface:

1. Review the Cython code in `src/benpy.pyx`
2. Check the C structure definitions in `src/pxd/*.pxd`
3. Add tests to `test_memory_interface.py`
4. Update this documentation

## License

Same license as benpy (GNU General Public License v3.0)
