# Cython Declaration Files for bensolve 2.1.0

This directory contains Cython `.pxd` files that declare the C API from bensolve 2.1.0.

## Purpose

These declaration files centralize the C type definitions, structures, and function signatures from the bensolve library. This improves maintainability by:
- Separating declarations from implementation
- Making it easier to update when the bensolve API changes
- Allowing multiple Cython modules to import the same declarations
- Providing better IDE support and type checking

## Files

- **bslv_main.pxd**: Core type definitions and enumerations (algorithm types, LP methods, status types, etc.)
- **bslv_lists.pxd**: List structures (list1d, list2d, boundlist) and related functions
- **bslv_poly.pxd**: Polytope and vertex enumeration structures (polytope, poly_args, permutation)
- **bslv_vlp.pxd**: VLP problem structures (vlptype, soltype, opttype, csatype)
- **bslv_lp.pxd**: LP solver interface functions
- **bslv_algs.pxd**: Algorithm phase functions (phase0, phase1, phase2)

## Usage

To use these declarations in a Cython file:

```cython
from pxd.bslv_main cimport lp_idx, alg_type
from pxd.bslv_vlp cimport vlptype, soltype, opttype
from pxd.bslv_algs cimport phase0, phase1_primal
```

## Dependencies

These files declare the C API from `src/bensolve-2.1.0/` header files. The actual implementation is in the corresponding `.c` files.

## Version

These declarations are based on bensolve version 2.1.0.
