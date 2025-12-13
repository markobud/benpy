# cython: language_level=3
"""
Cython declarations for bensolve-2.1.0 bslv_poly.h
Contains polytope and vertex enumeration structures
"""

cdef extern from "bensolve-2.1.0/bslv_poly.h":
    # Type definitions for bit storage
    ctypedef size_t btstrg
    ctypedef btstrg vrtx_strg
    
    # Macros as external functions
    size_t BTCNT
    size_t ST_BT(vrtx_strg *lst, size_t idx)
    size_t UNST_BT(vrtx_strg *lst, size_t idx)
    size_t IS_ELEM(vrtx_strg *lst, size_t idx)
    
    # Structures
    ctypedef struct poly_list:
        size_t cnt
        size_t blcks
        size_t *data
    
    ctypedef struct polytope:
        size_t dim
        size_t dim_primg
        size_t cnt
        size_t blcks
        double *ip
        double *data
        double *data_primg
        poly_list *adjacence
        poly_list *incidence
        vrtx_strg *ideal
        vrtx_strg *used
        vrtx_strg *sltn
        polytope *dual
        void (*v2h)(double *, int, double *)
    
    ctypedef struct poly_args:
        size_t dim
        size_t dim_primg_prml
        size_t dim_primg_dl
        unsigned int ideal
        size_t idx
        double *val
        double *val_primg_prml
        double *val_primg_dl
        double eps
        polytope primal
        polytope dual
        void (*primalV2dualH)()
        void (*dualV2primalH)()
    
    ctypedef struct permutation:
        size_t cnt
        size_t *data
        size_t *inv
    
    # Functions
    void poly__initialise_permutation(polytope *, permutation *)
    void poly__kill_permutation(permutation *)
    void poly__vrtx2file(polytope *, permutation *, const char *, const char *)
    void poly__primg2file(polytope *, permutation *, const char *, const char *)
    void poly__adj2file(polytope *, permutation *, const char *, const char *)
    void poly__inc2file(polytope *, permutation *, permutation *, const char *, const char *)
    void poly__set_default_args(poly_args *args, size_t dim)
    void poly__initialise(poly_args *)
    void poly__kill(poly_args *)
    void poly__cut(polytope *, size_t, double *)
    void poly__poly_initialise(polytope *, double *, double *, double *, size_t *)
    int poly__add_vrtx(poly_args *)
    int poly__get_vrtx(poly_args *)
    void poly__poly_init(polytope *)
    void poly__poly_kill(polytope *)
    void poly__list_init(poly_list *)
    void add_vrtx(polytope *)
    int poly__intl_apprx(poly_args *)
    void add_lst_elem(poly_list *, size_t)
    int edge_test(polytope *, size_t, size_t)
    void poly__update_adjacence(polytope *)
    void vrtx_cpy(polytope *, size_t, size_t)
    void poly__swap(poly_args *, poly_args *)
    void poly__plot(polytope *, const char *)
    void poly__polyck(poly_args *)
    double bslv__normalise(double *, double *, double *, size_t, size_t)
