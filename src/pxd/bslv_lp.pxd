# cython: language_level=3
"""
Cython declarations for bensolve-2.1.0 bslv_lp.h
Contains LP solver interface functions
"""

from pxd.bslv_main cimport lp_idx, lp_status_type, phase_type
from pxd.bslv_lists cimport list1d, list2d, boundlist
from pxd.bslv_vlp cimport vlptype, opttype

cdef extern from "bensolve-2.1.0/bslv_lp.h":
    # Functions
    void lp_write(size_t i)
    double lp_write_sol(size_t i)
    void lp_init(const vlptype *vlp)
    void lp_set_options(const opttype *opt, phase_type phase)
    void lp_copy(size_t dest, size_t src)
    void lp_update_extra_coeffs(lp_idx n_rows, lp_idx n_cols)
    void lp_set_rows(size_t i, const boundlist *rows)
    void lp_set_rows_hom(size_t i, const boundlist *rows)
    void lp_set_cols(size_t i, const boundlist *cols)
    void lp_set_cols_hom(size_t i, const boundlist *cols)
    int lp_set_mat(size_t i, const list2d *A)
    void lp_set_mat_row(size_t i, list1d *list, lp_idx ridx)
    void lp_clear_obj_coeffs(size_t i)
    void lp_set_obj_coeffs(size_t i, const list1d *list)
    lp_status_type lp_solve(size_t i)
    void lp_primal_solution_rows(size_t i, double *const x, lp_idx firstidx, lp_idx size, double sign)
    void lp_primal_solution_cols(size_t i, double *const x, lp_idx firstidx, lp_idx size, double sign)
    void lp_dual_solution_rows(size_t i, double *const u, lp_idx firstidx, lp_idx size, double sign)
    void lp_dual_solution_cols(size_t i, double *const u, lp_idx firstidx, lp_idx size, double sign)
    double lp_obj_val(size_t i)
    double lp_get_time(size_t i)
    int lp_get_num(size_t i)
    void lp_free(size_t i)
