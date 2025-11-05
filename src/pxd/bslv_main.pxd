# cython: language_level=3
"""
Cython declarations for bensolve-2.1.0 bslv_main.h
Contains core type definitions and enumerations
"""

cdef extern from "bensolve-2.1.0/bslv_main.h":
    # Type definitions
    ctypedef int lp_idx
    
    # Enumerations
    cdef enum _alg_type:
        PRIMAL_BENSON
        DUAL_BENSON
    
    cdef enum _lp_method_type:
        PRIMAL_SIMPLEX
        DUAL_SIMPLEX
        DUAL_PRIMAL_SIMPLEX
        LP_METHOD_AUTO
    
    cdef enum _lp_hom_type:
        HOMOGENEOUS
        INHOMOGENEOUS
    
    cdef enum _cone_out_type:
        CONE_OUT_OFF
        CONE_OUT_ON
    
    cdef enum _phase_type:
        PHASE0
        PHASE1_PRIMAL
        PHASE1_DUAL
        PHASE2_PRIMAL
        PHASE2_DUAL
    
    cdef enum _format_type:
        FORMAT_SHORT
        FORMAT_LONG
        FORMAT_AUTO
    
    cdef enum _lp_status_type:
        LP_INFEASIBLE
        LP_UNBOUNDED
        LP_UNEXPECTED_STATUS
        LP_UNDEFINED_STATUS
        LP_OPTIMAL
    
    cdef enum _sol_status_type:
        VLP_NOSTATUS
        VLP_INFEASIBLE
        VLP_UNBOUNDED
        VLP_NOVERTEX
        VLP_OPTIMAL
        VLP_INPUTERROR
        VLP_UNEXPECTED_STATUS
        VLP_UNEXPECTED_STATUS
    
    cdef enum _cone_gen_type:
        CONE
        DUALCONE
        DEFAULT
    
    cdef enum _c_dir_type:
        C_DIR_POS
        C_DIR_NEG
    
    cdef enum _swap_type:
        SWAP
        NO_SWAP
    
    cdef enum _pre_img_type:
        PRE_IMG_OFF
        PRE_IMG_ON
    
    # Typedefs for enums
    ctypedef _alg_type alg_type
    ctypedef _lp_method_type lp_method_type
    ctypedef _lp_hom_type lp_hom_type
    ctypedef _cone_out_type cone_out_type
    ctypedef _phase_type phase_type
    ctypedef _format_type format_type
    ctypedef _lp_status_type lp_status_type
    ctypedef _sol_status_type sol_status_type
    ctypedef _cone_gen_type cone_gen_type
    ctypedef _c_dir_type c_dir_type
    ctypedef _swap_type swap_type
    ctypedef _pre_img_type pre_img_type
