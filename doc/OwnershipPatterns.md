# Memory Ownership Patterns in benpy

This document describes the memory ownership patterns and lifecycle management in benpy for developers and advanced users.

## Overview

benpy is a Python wrapper for bensolve 2.1.0, a C library for solving vector linear programs. The wrapper uses Cython to interface with C code, which requires careful memory management to prevent leaks and ensure proper cleanup.

## Key Principles

1. **Caller owns structure, bensolve owns members**: Python code allocates `vlptype` and `soltype` structures, but bensolve allocates and owns their members.
2. **Explicit cleanup required**: C structures must be explicitly freed using bensolve's cleanup functions.
3. **RAII in Cython**: We use Cython's `__cinit__` and `__dealloc__` to implement RAII (Resource Acquisition Is Initialization).

## Memory Ownership by Component

### Problem Structure (`_cVlpProblem`)

#### Allocation
```cython
cdef class _cVlpProblem:
    cdef opttype* _opt 
    cdef vlptype* _vlp
    
    def __cinit__(self):
        # Python wrapper owns structure pointers
        self._opt = <opttype *>malloc(sizeof(opttype))
        self._vlp = <vlptype *>malloc(sizeof(vlptype))
        
        # Initialize members to NULL for safe cleanup
        self._vlp.A_ext = NULL
        self._vlp.rows = NULL
        self._vlp.cols = NULL
        self._vlp.gen = NULL
        self._vlp.c = NULL
```

**Ownership:**
- Python wrapper owns `_opt` and `_vlp` structure pointers
- bensolve owns the members pointed to by vlp (A_ext, rows, cols, gen, c)

#### Initialization Methods

**from_file():**
- Calls `vlp_init(filename, vlp, opt)` 
- bensolve allocates all vlp members
- bensolve owns all allocated memory

**from_arrays():**
- Python code allocates vlp members using bensolve's allocators:
  - `list2d_alloc()` for A_ext
  - `boundlist_alloc()` for rows and cols
  - `malloc()` for gen and c
- Ownership transfers to bensolve
- bensolve's `vlp_free()` will clean up

#### Cleanup
```cython
def __dealloc__(self):
    # Free bensolve-owned members first
    if self._vlp != NULL:
        vlp_free(self._vlp)  # Frees A_ext, rows, cols, gen, c
        free(self._vlp)       # Frees structure itself
    if self._opt != NULL:
        free(self._opt)       # Frees options structure
```

**Sequence:**
1. `vlp_free()` frees all members (A_ext, rows, cols, gen, c)
2. `free()` frees the structure pointers
3. NULL checks ensure safety

#### Reuse Protection

When calling `from_arrays()` or `from_file()` multiple times:
```cython
def from_arrays(self, ...):
    # Free previous allocations to prevent leaks
    vlp_free(self._vlp)
    
    # Re-initialize to NULL
    self._vlp.A_ext = NULL
    self._vlp.rows = NULL
    # ... etc
    
    # Allocate new problem
    # ...
```

### Solution Structure (`_cVlpSolution`)

#### Allocation
```cython
cdef class _cVlpSolution:
    cdef soltype* _sol
    
    def __cinit__(self):
        # Python wrapper owns structure pointer
        self._sol = <soltype *>malloc(sizeof(soltype))
        
        # Initialize members to NULL for safe cleanup
        self._sol.eta = NULL
        self._sol.Y = NULL
        self._sol.Z = NULL
        self._sol.c = NULL
        self._sol.R = NULL
        self._sol.H = NULL
```

**Ownership:**
- Python wrapper owns `_sol` structure pointer
- bensolve owns all solution data (eta, Y, Z, c, R, H)

#### Initialization

**In _csolve():**
```cython
solution = _cVlpSolution()
sol_init(solution._sol, problem._vlp, problem._opt)
```

- `sol_init()` allocates eta, Y, Z, c using `calloc()`
- Phase1 functions allocate R and H
- bensolve owns all allocated memory

#### Cleanup
```cython
def __dealloc__(self):
    # Free bensolve-owned members first
    if self._sol != NULL:
        sol_free(self._sol)  # Frees eta, Y, Z, c, R, H
        free(self._sol)      # Frees structure itself
```

**Sequence:**
1. `sol_free()` frees all members (eta, Y, Z, c, R, H)
2. `free()` frees the structure pointer
3. NULL checks ensure safety

### LP Structures

#### bensolve 2.1.0 API Change

**Old (bensolve-mod):**
```c
typedef struct { ... } lptype;
void lp_solve(lptype *lpstr);
```

**New (bensolve 2.1.0):**
```c
// Global array instead of struct
glp_prob *lp[MAX_LP];

// Functions take index instead of pointer
lp_status_type lp_solve(size_t i);
void lp_free(size_t i);
```

#### Ownership
- bensolve owns LP structures in global array
- Caller must call `lp_free(i)` to clean up
- Default index is 0

#### Usage in Wrapper
```cython
cdef _cVlpSolution _csolve(_cVlpProblem problem):
    lp_init(problem._vlp)
    
    try:
        # Solving phases...
        phase0(...)
        phase1_primal(...)
        phase2_primal(...)
    finally:
        # Always free LP, even on error
        lp_free(0)
    
    return solution
```

**Key points:**
- `lp_init()` allocates GLPK structures
- `lp_free(0)` must be called to free GLPK memory
- Use try/finally to ensure cleanup on errors

## Memory Allocators

### bensolve Allocators

bensolve provides custom allocators that wrapper code uses:

```c
// List allocators
list2d *list2d_alloc(size_t size);
list2d *list2d_calloc(size_t size);
void list2d_free(list2d *list);

boundlist *boundlist_alloc(lp_idx size);
boundlist *boundlist_calloc(lp_idx size, char type);
void boundlist_free(boundlist *list);

list1d *list1d_alloc(size_t size);
list1d *list1d_calloc(size_t size);
void list1d_free(list1d *list);
```

**Important:**
- Use these allocators for vlptype members
- They handle internal structure properly
- Match each alloc with appropriate free

### Standard C Allocators

For simple data:
```c
double *gen = malloc(q * n_gen * sizeof(double));
double *c = malloc(q * sizeof(double));
free(gen);
free(c);
```

**Used for:**
- Ordering cone generators (gen)
- Duality parameter vectors (c)

## Error Handling

### Allocation Failures

All allocations check for NULL:
```cython
self._opt = <opttype *>malloc(sizeof(opttype))
if self._opt == NULL:
    raise MemoryError("Failed to allocate problem structures")
```

### Partial Initialization

Members initialized to NULL ensure safe cleanup:
```cython
# If allocation fails after some members allocated
self._vlp.A_ext = list2d_alloc(total_nz)
if self._vlp.A_ext == NULL:
    # vlp_free() will safely handle other members
    raise MemoryError("...")
```

**vlp_free() safety:**
```c
void vlp_free(vlptype *vlp) {
    if (vlp->A_ext != NULL) { list2d_free(vlp->A_ext); vlp->A_ext=NULL; }
    if (vlp->rows != NULL) { boundlist_free(vlp->rows); vlp->rows=NULL; }
    // ... checks all members
}
```

## Lifecycle Examples

### Simple Problem Creation and Solving

```python
# Create problem
prob = benpy._cVlpProblem()
prob.from_arrays(B, P, b=b, l=l, opt_dir=1)

# Solve
sol = benpy.solve_direct(B, P, b=b, l=l, opt_dir=1)

# Use solution
print(sol.status)
print(sol.Y)

# Cleanup happens automatically when objects go out of scope
# Python will call __dealloc__ which calls vlp_free() and sol_free()
```

**Memory flow:**
1. `__cinit__`: malloc(opttype), malloc(vlptype)
2. `from_arrays`: allocates A_ext, rows, cols
3. `solve_direct`: malloc(soltype), sol_init allocates members, lp_init
4. User accesses solution data
5. Python GC triggers __dealloc__
6. `lp_free(0)`: frees GLPK structures
7. `sol_free()`: frees eta, Y, Z, c, R, H
8. `vlp_free()`: frees A_ext, rows, cols, gen, c
9. free(opttype), free(vlptype), free(soltype)

### Reusing Problem Object

```python
prob = benpy._cVlpProblem()

# First problem
prob.from_arrays(B1, P1, b=b1, l=l1, opt_dir=1)
sol1 = prob.solve()  # (if such method existed)

# Second problem - SAFE, no leak
prob.from_arrays(B2, P2, b=b2, l=l2, opt_dir=1)
sol2 = prob.solve()

# Cleanup
del prob  # Only frees last allocation
```

**Memory flow:**
1. First `from_arrays`: allocates vlp members
2. Second `from_arrays`: calls `vlp_free()`, then allocates new vlp members
3. `__dealloc__`: frees only the second allocation

## Common Pitfalls

### DON'T: Manual memory management

```python
# BAD - Python handles this
prob = benpy._cVlpProblem()
prob.from_arrays(B, P, b=b, l=l, opt_dir=1)
# Don't try to manually free anything
```

### DON'T: Accessing data after deletion

```python
# BAD - undefined behavior
sol = benpy.solve_direct(B, P, b=b, l=l, opt_dir=1)
Y = sol.Y
del sol  # Frees underlying data
print(Y)  # Y is now invalid!
```

### DO: Copy data if needed after deletion

```python
# GOOD - copy the data
sol = benpy.solve_direct(B, P, b=b, l=l, opt_dir=1)
Y = sol.Y.copy()  # Make a copy
del sol  # Safe to delete
print(Y)  # Y is still valid
```

### DO: Let Python manage lifecycle

```python
# GOOD - automatic cleanup
def solve_problem(B, P):
    sol = benpy.solve_direct(B, P, opt_dir=1)
    return sol.Y.copy()  # Copy before returning

Y = solve_problem(B, P)
# sol was automatically cleaned up when function returned
```

## Testing Memory Management

### Manual Testing

Use the memory leak tests:
```bash
python tests_memory.py
```

### Valgrind (Linux)

```bash
valgrind --leak-check=full --show-leak-kinds=all python tests_memory.py
```

Look for:
- "definitely lost" - real leaks
- "still reachable" - Python interpreter overhead (usually OK)

### Python tracemalloc

```python
import tracemalloc

tracemalloc.start()

# Create/destroy many objects
for i in range(1000):
    prob = benpy._cVlpProblem()
    prob.from_arrays(B, P, b=b, l=l, opt_dir=1)
    del prob

snapshot = tracemalloc.take_snapshot()
top_stats = snapshot.statistics('lineno')

for stat in top_stats[:10]:
    print(stat)
```

## Developer Guidelines

### When Adding New Features

1. **Identify ownership**: Who allocates? Who frees?
2. **NULL initialization**: Initialize all pointers to NULL
3. **Check allocations**: Always check for NULL after malloc
4. **Match alloc/free**: Every allocation needs a corresponding free
5. **Update __dealloc__**: Add cleanup for new allocated members
6. **Test**: Add memory leak tests for new features

### When Modifying Existing Code

1. **Check ownership**: Don't change who owns what without careful review
2. **Preserve cleanup**: Don't remove free() calls
3. **Test thoroughly**: Run memory leak tests
4. **Document changes**: Update this document if ownership changes

## Summary

The benpy memory management follows these principles:

1. **Wrapper owns structures** - Python code allocates vlptype/soltype pointers
2. **bensolve owns members** - bensolve allocates and owns structure members
3. **Explicit cleanup** - Use bensolve's free functions (vlp_free, sol_free, lp_free)
4. **RAII pattern** - __cinit__ allocates, __dealloc__ frees
5. **NULL safety** - Initialize to NULL, check before freeing
6. **Reuse protection** - Free before reallocating
7. **Error handling** - Check allocations, raise on failure
8. **Automatic cleanup** - Python GC triggers cleanup automatically

Following these patterns ensures no memory leaks and safe operation.
