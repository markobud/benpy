# cython: language_level=3
"""
Cython declarations for bensolve-2.1.0 bslv_lists.h
Contains list and bound list structures
"""

from .bslv_main cimport lp_idx

cdef extern from "bensolve-2.1.0/bslv_lists.h":
    # Structures
    ctypedef struct list1d:
        lp_idx size
        lp_idx *idx
        double *data
    
    ctypedef struct list2d:
        size_t size
        lp_idx *idx1
        lp_idx *idx2
        double *data
    
    ctypedef struct boundlist:
        lp_idx size
        lp_idx *idx
        double *lb
        double *ub
        char *type
    
    # Utility functions
    void string_fprint(const char *filename, const char *string)
    void matrix_fprint(double *mat_arr, int m, int n, int tda, char *filename, const char *format)
    void matrix_print(double *mat_arr, int m, int n, const char *format)
    int string_to_int(char *str, char *error_msg)
    int string_to_positive_int(char *str, char *error_msg)
    double string_to_positive_double(char *str, char *error_msg)
    void orthogonal_vector(double *mat_arr, int dim, int cidx)
    int is_equal(const lp_idx size, const double *vec1, const double *vec2, const double tol)
    int is_zero(const lp_idx size, const double *vec, const double tol)
    
    # list1d functions
    list1d *list1d_alloc(lp_idx size)
    list1d *list1d_calloc(lp_idx size)
    void list1d_init_idx(list1d *list, lp_idx firstidx)
    void list1d_free(list1d *list)
    void vector_to_list1d(list1d *const list, const double *vec_arr, int n)
    void list1d_print(const list1d *list, int size)
    
    # list2d functions
    list2d *list2d_alloc(size_t size)
    list2d *list2d_calloc(size_t size)
    void list2d_init_idx(list2d *list, lp_idx nrows, lp_idx ncols)
    void list2d_free(list2d *list)
    void list2d_print(const list2d *list)
    
    # boundlist functions
    boundlist *boundlist_alloc(lp_idx size)
    boundlist *boundlist_calloc(lp_idx size, char type)
    void boundlist_init_idx(boundlist *list, lp_idx firstidx)
    void boundlist_free(boundlist *list)
    void boundlist_print(const boundlist *list)
