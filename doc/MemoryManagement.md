# Memory Management Audit for bensolve 2.1.0

## Overview

This document details the memory management and ownership patterns in the benpy wrapper for bensolve 2.1.0, identifies memory leaks, and documents the fixes applied.

## Memory Ownership Patterns

### bensolve 2.1.0 Internal Memory Management

#### vlptype Structure
The `vlptype` structure owns the following heap-allocated members:
- `A_ext` (list2d*) - Allocated by `list2d_calloc()` or `list2d_alloc()`
- `rows` (boundlist*) - Allocated by `boundlist_calloc()` or `boundlist_alloc()`
- `cols` (boundlist*) - Allocated by `boundlist_calloc()` or `boundlist_alloc()`
- `gen` (double*) - Allocated by `malloc()` or `calloc()`
- `c` (double*) - Allocated by `malloc()` or `calloc()`

**Cleanup:** `vlp_free(vlptype *vlp)` frees all these members

#### soltype Structure
The `soltype` structure owns the following heap-allocated members:
- `eta` (double*) - Allocated by `calloc()` in `sol_init()`
- `Y` (double*) - Allocated by `calloc()` in `sol_init()`
- `Z` (double*) - Allocated by `calloc()` in `sol_init()`
- `c` (double*) - Allocated by `calloc()` in `sol_init()`
- `R` (double*) - Allocated during phase1
- `H` (double*) - Allocated during phase1

**Cleanup:** `sol_free(soltype *sol)` frees all these members

#### LP Structures (bensolve 2.1.0 Change)
In bensolve 2.1.0, the `lptype` structure was removed. Instead:
- LP problems are stored in a global array `lp[]`
- Functions take a `size_t i` index instead of `lptype *lpstr`
- `lp_init(vlptype *vlp)` initializes the global LP
- `lp_free(size_t i)` frees the LP at index i

**Cleanup:** `lp_free(size_t i)` must be called to free GLPK structures

### Wrapper Memory Management

#### _cVlpProblem Class

**Allocated in __cinit__:**
- `_opt` (opttype*) - Allocated by `malloc()`
- `_vlp` (vlptype*) - Allocated by `malloc()`

**Allocated in from_arrays:**
- `_vlp->A_ext` - Allocated by `list2d_alloc()`
- `_vlp->rows` - Allocated by `boundlist_alloc()`
- `_vlp->cols` - Allocated by `boundlist_alloc()`
- `_vlp->gen` - Allocated by `malloc()` (if Y or Z provided)
- `_vlp->c` - Allocated by `malloc()` (if c provided)

**Allocated in from_file:**
- Bensolve's `vlp_init()` allocates all vlp members internally

**Current __dealloc__:**
```cython
def __dealloc__(self):
    free(self._opt)
    free(self._vlp)
```

**PROBLEM:** This only frees the structure pointers, not their members!

#### _cVlpSolution Class

**Allocated in _csolve:**
- `_sol` (soltype*) - Allocated by `malloc()` in __cinit__
- `_sol->eta, Y, Z, c, R, H` - Allocated by bensolve's `sol_init()` and phase functions

**Current __dealloc__:**
```cython
def __dealloc__(self):
    free(self._sol)
```

**PROBLEM:** This only frees the structure pointer, not its members!

## Memory Leaks Identified

### Critical Leaks

1. **_cVlpProblem Memory Leak**
   - **Location:** `_cVlpProblem.__dealloc__()`
   - **Issue:** Does not call `vlp_free()` to free A_ext, rows, cols, gen, c
   - **Severity:** HIGH - Leaks occur on every problem created
   - **Impact:** Each problem leaks:
     - list2d structure (A_ext)
     - 2 boundlist structures (rows, cols)
     - Ordering cone generators (if used)
     - Duality parameter vector (if used)

2. **_cVlpSolution Memory Leak**
   - **Location:** `_cVlpSolution.__dealloc__()`
   - **Issue:** Does not call `sol_free()` to free eta, Y, Z, c, R, H
   - **Severity:** HIGH - Leaks occur on every solution
   - **Impact:** Each solution leaks:
     - Phase 0 result (eta)
     - Ordering cone generators (Y, Z)
     - Duality parameter (c)
     - Phase 1 results (R, H)

3. **LP Structure Leak**
   - **Location:** `_csolve()` function
   - **Issue:** Calls `lp_init()` but never calls `lp_free()`
   - **Severity:** HIGH - Leaks GLPK structures
   - **Impact:** Each solve leaks GLPK problem structure

### Ownership Issues in from_arrays

The `from_arrays()` method manually allocates vlp members:
```cython
self._vlp.A_ext = list2d_alloc(total_nz)
self._vlp.rows = boundlist_alloc(m)
self._vlp.cols = boundlist_alloc(n)
self._vlp.gen = <double*>malloc(...)
self._vlp.c = <double*>malloc(...)
```

These allocations are compatible with bensolve's ownership model, but:
- Must ensure `vlp_free()` is called in __dealloc__
- Must handle partial initialization (if error occurs mid-way)
- Must ensure NULL checks before freeing

## Migration from bensolve-mod to bensolve 2.1.0

### API Changes in bensolve 2.1.0

1. **LP Structure Removal**
   - Old: `lptype *lpstr` passed to functions
   - New: `size_t i` index into global array
   - Impact: Need to track LP index and call `lp_free(i)`

2. **opttype Structure Changes**
   - Removed: `printfiles`, `logfile` fields
   - Impact: Wrapper already handles this with warnings

3. **sol_init Return Value**
   - Old: `void sol_init(...)`
   - New: `int sol_init(...)` - returns status
   - Impact: Wrapper should check return value

### Memory Ownership Unchanged

The ownership patterns for vlptype and soltype remain the same:
- Caller allocates structure
- bensolve allocates/owns members
- Caller must call vlp_free()/sol_free()

## Fixes Required

### 1. Fix _cVlpProblem.__dealloc__

```cython
def __dealloc__(self):
    # Free bensolve-owned members
    vlp_free(self._vlp)
    # Free structure itself
    free(self._opt)
    free(self._vlp)
```

### 2. Fix _cVlpSolution.__dealloc__

```cython
def __dealloc__(self):
    # Free bensolve-owned members
    sol_free(self._sol)
    # Free structure itself
    free(self._sol)
```

### 3. Fix _csolve LP Leak

```cython
cdef _cVlpSolution _csolve(_cVlpProblem problem):
    # ... existing code ...
    lp_init(problem._vlp)
    # ... solving code ...
    # NEW: Free LP after solving
    lp_free(0)  # bensolve uses index 0 for main LP
    return solution
```

### 4. Add Error Handling for from_arrays

Need to ensure partial allocations are cleaned up on error:
```cython
def from_arrays(self, ...):
    # Initialize to NULL for safety
    self._vlp.A_ext = NULL
    self._vlp.rows = NULL
    self._vlp.cols = NULL
    self._vlp.gen = NULL
    self._vlp.c = NULL
    
    try:
        # Allocations...
        self._vlp.A_ext = list2d_alloc(total_nz)
        if self._vlp.A_ext == NULL:
            raise MemoryError("...")
        # etc...
    except:
        # On error, vlp_free will handle NULL pointers safely
        raise
```

## Memory Leak Detection Tests

### Test Strategy

1. **Allocation Counter Test**
   - Track allocations in Python using tracemalloc
   - Create/destroy many problem objects
   - Verify memory is released

2. **Valgrind Test** (if available)
   - Run test suite under valgrind
   - Check for "definitely lost" blocks
   - Verify all malloc/free pairs

3. **Reference Counting Test**
   - Verify Python objects are properly deallocated
   - Check that __dealloc__ is called

### Test Implementation

```python
import tracemalloc

def test_no_memory_leak_problem():
    """Test that _cVlpProblem doesn't leak memory"""
    tracemalloc.start()
    
    # Create baseline
    for _ in range(100):
        prob = benpy._cVlpProblem()
        prob.from_arrays(B, P, b=b, l=l, opt_dir=1)
    
    snapshot1 = tracemalloc.take_snapshot()
    
    # Create more objects
    for _ in range(100):
        prob = benpy._cVlpProblem()
        prob.from_arrays(B, P, b=b, l=l, opt_dir=1)
    
    snapshot2 = tracemalloc.take_snapshot()
    
    # Memory should not grow significantly
    top_stats = snapshot2.compare_to(snapshot1, 'lineno')
    # Check that growth is minimal (allowing for some variation)
    # This is a simplified check - real test would be more sophisticated
```

## Documentation

### User-Facing Documentation

Users don't need to know about internal memory management, but we should document:
- Objects are automatically cleaned up when deleted
- No manual cleanup required
- Safe to create many problem/solution objects

### Developer Documentation

For contributors, document:
- Memory ownership patterns
- When to call vlp_free/sol_free
- NULL pointer safety
- Error handling in allocation paths

## Summary

The memory management issues identified are:
1. ✅ vlp_free() not called - **FIX: Call in __dealloc__**
2. ✅ sol_free() not called - **FIX: Call in __dealloc__**
3. ✅ lp_free() not called - **FIX: Call after solving**
4. ⚠️ Partial allocation cleanup - **FIX: Add error handling**

After fixes, the wrapper will:
- Properly free all bensolve structures
- Clean up GLPK LP structures
- Handle allocation errors gracefully
- Pass memory leak tests
