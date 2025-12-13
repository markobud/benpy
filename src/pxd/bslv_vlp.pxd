# cython: language_level=3
"""
Cython declarations for bensolve-2.1.0 bslv_vlp.h
Contains VLP problem and solution structures
"""

from pxd.bslv_main cimport (
    lp_idx, cone_gen_type, sol_status_type, c_dir_type,
    pre_img_type, format_type, lp_method_type, alg_type
)
from pxd.bslv_lists cimport list2d, boundlist

cdef extern from "bensolve-2.1.0/bslv_vlp.h":
    # Structures
    ctypedef struct csatype:
        pass
    
    ctypedef struct vlptype:
        list2d *A_ext
        boundlist *rows
        boundlist *cols
        int optdir
        cone_gen_type cone_gen
        double *gen
        double *c
        long int nz
        long int nzobj
        lp_idx n
        lp_idx m
        lp_idx q
        lp_idx n_gen
    
    ctypedef struct soltype:
        lp_idx m
        lp_idx n
        lp_idx q
        lp_idx o
        lp_idx p
        lp_idx r
        lp_idx h
        double *eta
        double *Y
        double *Z
        double *c
        double *R
        double *H
        sol_status_type status
        c_dir_type c_dir
        size_t pp
        size_t dd
        size_t pp_dir
        size_t dd_dir
    
    ctypedef struct opttype:
        int bounded
        int plot
        char filename[256]
        pre_img_type solution
        format_type format
        lp_method_type lp_method_phase0
        lp_method_type lp_method_phase1
        lp_method_type lp_method_phase2
        int message_level
        int lp_message_level
        alg_type alg_phase1
        alg_type alg_phase2
        double eps_phase0
        double eps_phase1
        double eps_benson_phase1
        double eps_benson_phase2
    
    # Functions
    int vlp_init(const char *filename, vlptype *vlp, const opttype *opt)
    int set_opt(opttype *opt, const int argc, char **argv)
    int write_log_file(const vlptype *vlp, const soltype *sol, const opttype *opt, double elapsedTime, int lp_num)
    void display_info(const opttype *opt, double elapsedTime, int lp_num)
    void vlp_free(vlptype *vlp)
    int sol_init(soltype *sol, const vlptype *vlp, const opttype *opt)
    void sol_free(soltype *sol)
    void set_default_opt(opttype *opt)
