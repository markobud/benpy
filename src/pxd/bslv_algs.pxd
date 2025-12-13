# cython: language_level=3
"""
Cython declarations for bensolve-2.1.0 bslv_algs.h
Contains algorithm phase functions
"""

from pxd.bslv_main cimport lp_idx, cone_out_type, swap_type
from pxd.bslv_vlp cimport vlptype, soltype, opttype

cdef extern from "bensolve-2.1.0/bslv_algs.h":
    # Functions
    int cone_vertenum(
        double **prim,
        lp_idx *n_prim,
        double **dual,
        lp_idx *n_dual,
        double *prim_in,
        const size_t n_prim_in,
        const size_t dim,
        const opttype *opt,
        cone_out_type output,
        swap_type swap
    ) nogil
    
    int alg(soltype *const sol, const vlptype *vlp, const opttype *opt) nogil
    void phase0(soltype *const sol, const vlptype *vlp, const opttype *opt) nogil
    void phase1_primal(soltype *const sol, const vlptype *vlp, const opttype *opt) nogil
    void phase2_primal(soltype *const sol, const vlptype *vlp, const opttype *opt) nogil
    void phase1_dual(soltype *const sol, const vlptype *vlp, const opttype *opt) nogil
    void phase2_dual(soltype *const sol, const vlptype *vlp, const opttype *opt) nogil
    void phase2_init(soltype *sol, const vlptype *vlp) nogil
