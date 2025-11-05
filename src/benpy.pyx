#cython: language_level=3

import time
import numpy as np
cimport numpy as np
from libc.stdlib cimport malloc, free
from libc.limits cimport CHAR_BIT
from prettytable import PrettyTable
from os.path import splitext
from collections import namedtuple as ntp
from warnings import warn
from scipy.sparse import lil_matrix, find
from io import StringIO, open as io_open
from tempfile import NamedTemporaryFile
import sys

# Import types and enums from bslv_main.pxd
from pxd.bslv_main cimport (
    lp_idx, alg_type, lp_method_type, lp_hom_type, cone_out_type,
    phase_type, format_type, lp_status_type, sol_status_type,
    cone_gen_type, c_dir_type, swap_type, pre_img_type,
    PRIMAL_BENSON, DUAL_BENSON,
    PRIMAL_SIMPLEX, DUAL_SIMPLEX, DUAL_PRIMAL_SIMPLEX, LP_METHOD_AUTO,
    HOMOGENEOUS, INHOMOGENEOUS,
    CONE_OUT_OFF, CONE_OUT_ON,
    PHASE0, PHASE1_PRIMAL, PHASE1_DUAL, PHASE2_PRIMAL, PHASE2_DUAL,
    FORMAT_SHORT, FORMAT_LONG, FORMAT_AUTO,
    LP_INFEASIBLE, LP_UNBOUNDED, LP_UNEXPECTED_STATUS, LP_UNDEFINED_STATUS, LP_OPTIMAL,
    VLP_NOSTATUS, VLP_INFEASIBLE, VLP_UNBOUNDED, VLP_NOVERTEX, VLP_OPTIMAL, VLP_INPUTERROR, VLP_UNEXPECTED_STATUS,
    CONE, DUALCONE, DEFAULT,
    C_DIR_POS, C_DIR_NEG,
    SWAP, NO_SWAP,
    PRE_IMG_OFF, PRE_IMG_ON
)

# Import structures and functions from bslv_vlp.pxd
from pxd.bslv_vlp cimport (
    csatype, vlptype, soltype, opttype,
    vlp_init, vlp_free, sol_init, sol_free, set_default_opt
)

# Import LP functions from bslv_lp.pxd
from pxd.bslv_lp cimport lp_init, lp_get_num, lp_free

# Import algorithm phase functions from bslv_algs.pxd
from pxd.bslv_algs cimport (
    phase0, phase1_primal, phase2_primal,
    phase1_dual, phase2_dual, phase2_init
)

# Import polytope types and functions from bslv_poly.pxd
from pxd.bslv_poly cimport (
    btstrg, vrtx_strg, BTCNT, ST_BT, UNST_BT, IS_ELEM,
    poly_list, polytope, poly_args, permutation,
    poly__initialise_permutation, poly__kill
)

# Import list types and functions from bslv_lists.pxd
from pxd.bslv_lists cimport (
    list1d, list2d, boundlist,
    list1d_alloc, list1d_calloc, list1d_init_idx, list1d_free,
    list2d_alloc, list2d_calloc, list2d_init_idx, list2d_free,
    boundlist_alloc, boundlist_calloc, boundlist_init_idx, boundlist_free
)

THISVERSION = 'version 2.1.0'

def par_indent(func):
    def func_wrappper(text):
        return("\n\t{}\n".format(func(text)))
    return func_wrappper

cdef class _cVlpProblem:
    """Internal Wrap Class for Problem structure"""
    cdef opttype* _opt 
    cdef vlptype* _vlp
    cdef char* c_filename


    def __cinit__(self):
        self._opt = <opttype *>malloc(sizeof(opttype))
        self._vlp = <vlptype *>malloc(sizeof(vlptype))
        if self._opt == NULL or self._vlp == NULL:
            raise MemoryError("Failed to allocate problem structures")
        
        # Initialize vlp members to NULL for safe cleanup
        self._vlp.A_ext = NULL
        self._vlp.rows = NULL
        self._vlp.cols = NULL
        self._vlp.gen = NULL
        self._vlp.c = NULL

    def __dealloc__(self):
        # Free bensolve-owned members before freeing structures
        if self._vlp != NULL:
            vlp_free(self._vlp)
            free(self._vlp)
        if self._opt != NULL:
            free(self._opt)

    def __init__(self):
        set_default_opt(self._opt)

    def default_options(self):
        set_default_opt(self._opt)

    def set_options(self,opt_dict):
        for attr,val in opt_dict.items():
            if (attr == "bounded"):
                self._opt.bounded = val
            elif (attr == "plot"):
                self._opt.plot = val
            elif (attr == "filename"):
                if not isinstance(val,bytes):
                    val = val.encode()
                self.c_filename = val
                self._opt.filename = self.c_filename
            elif (attr == "solution"):
                self._opt.solution = val
            elif (attr == "format"):
                self._opt.format = val
            elif (attr == "lp_method_phase0"):
                if (val == "primal_simplex"):
                    self._opt.lp_method_phase0 = PRIMAL_SIMPLEX
                elif (val == "dual_simplex"):
                    self._opt.lp_method_phase0 = DUAL_SIMPLEX
                elif (val == "dual_primal_simplex"):
                    self._opt.lp_method_phase0 = DUAL_PRIMAL_SIMPLEX
                else:
                    warn("'{}':'{}' is a bad keyword value. Defaulting {} to primal_simplex".format(attr,val,attr))
                    self._opt.lp_method_phase0 = PRIMAL_SIMPLEX
            elif (attr == "lp_method_phase1"):
                if (val == "primal_simplex"):
                    self._opt.lp_method_phase1 = PRIMAL_SIMPLEX
                elif (val == "dual_simplex"):
                    self._opt.lp_method_phase1 = DUAL_SIMPLEX
                elif (val == "dual_primal_simplex"):
                    self._opt.lp_method_phase1 = DUAL_PRIMAL_SIMPLEX
                elif (val == "auto"):
                    self._opt.lp_method_phase1 = LP_METHOD_AUTO
                else:
                    warn("'{}':'{}' is a bad keyword value. Defaulting {} to 'auto'".format(attr,val,attr))
                    self._opt.lp_method_phase1 = LP_METHOD_AUTO
            elif (attr == "lp_method_phase2"):
                if (val == "primal_simplex"):
                    self._opt.lp_method_phase2 = PRIMAL_SIMPLEX
                elif (val == "dual_simplex"):
                    self._opt.lp_method_phase2 = DUAL_SIMPLEX
                elif (val == "dual_primal_simplex"):
                    self._opt.lp_method_phase2 = DUAL_PRIMAL_SIMPLEX
                elif (val == "auto"):
                    self._opt.lp_method_phase2 = LP_METHOD_AUTO
                else:
                    warn("'{}':'{}' is a bad keyword value. Defaulting {} to 'auto'".format(attr,val,attr))
                    self._opt.lp_method_phase2 = LP_METHOD_AUTO
            elif (attr == "message_level"):
                self._opt.message_level = val
            elif (attr == "lp_message_level"):
                self._opt.lp_message_level = val
            elif (attr == "alg_phase1"):
                if (val == "primal"):
                    self._opt.alg_phase1 = PRIMAL_BENSON
                elif (val == "dual"):
                    self._opt.alg_phase1 = DUAL_BENSON
                else:
                    warn("'{}':'{}' is a bad keyword value. Defaulting {} to 'primal'".format(attr,val,attr))
                    self._opt.alg_phase1 = PRIMAL_BENSON
            elif (attr == "alg_phase2"):
                if (val == "primal"):
                    self._opt.alg_phase2 = PRIMAL_BENSON
                elif (val == "dual"):
                    self._opt.alg_phase2 = DUAL_BENSON
                else:
                    warn("'{}':'{}' is a bad keyword value. Defaulting {} to 'primal'".format(attr,val,attr))
                    self._opt.alg_phase2 = PRIMAL_BENSON
            elif (attr == "eps_phase0"):
                self._opt.eps_phase0 = val
            elif (attr == "eps_phase1"):
                self._opt.eps_phase1 = val
            elif (attr == "eps_benson_phase1"):
                self._opt.eps_benson_phase1 = val
            elif (attr == "eps_benson_phase2"):
                self._opt.eps_benson_phase2 = val
            elif (attr == "write_files"):
                # Note: bensolve-2.1.0 removed printfiles field
                # File writing is now controlled through other means
                warn("'write_files' option not supported in bensolve-2.1.0, ignoring")
            elif (attr == "log_file"):
                # Note: bensolve-2.1.0 removed logfile field
                # Logging is now controlled through other means
                warn("'log_file' option not supported in bensolve-2.1.0, ignoring")


    @property
    def options(self):
        return(self._opt[0])

    def from_file(self,filename):

        if not isinstance(filename,bytes):
            filename = filename.encode()

        basename, _ = splitext(filename)
        self.set_options({'filename':basename})
        if(vlp_init(filename,self._vlp,self._opt)):
            print("Error in reading")

    def from_arrays(self, B, P, a=None, b=None, l=None, s=None, Y=None, Z=None, c=None, opt_dir=1):
        """
        Initialize VLP problem directly from numpy arrays, bypassing file I/O.
        
        Parameters:
        -----------
        B : array-like (m x n)
            Constraint matrix
        P : array-like (q x n)  
            Objective matrix
        a : array-like (m,), optional
            Lower bounds for constraints (default: -inf)
        b : array-like (m,), optional
            Upper bounds for constraints (default: +inf)
        l : array-like (n,), optional
            Lower bounds for variables (default: -inf)
        s : array-like (n,), optional
            Upper bounds for variables (default: +inf)
        Y : array-like (q x k), optional
            Ordering cone generators (primal)
        Z : array-like (q x k), optional
            Ordering cone generators (dual)
        c : array-like (q,), optional
            Duality parameter vector
        opt_dir : int
            Optimization direction: 1 for minimize, -1 for maximize
        """
        from scipy.sparse import lil_matrix, find as sparse_find
        import numpy as np
        
        # Convert to sparse matrices
        B_sparse = lil_matrix(B)
        P_sparse = lil_matrix(P)
        
        # Get dimensions
        cdef lp_idx m = B_sparse.shape[0]
        cdef lp_idx n = B_sparse.shape[1]
        cdef lp_idx q = P_sparse.shape[0]
        
        if P_sparse.shape[1] != n:
            raise ValueError(f"B and P must have same number of columns, got {n} and {P_sparse.shape[1]}")
        
        # Find non-zero entries
        A_rows, A_cols, A_vals = sparse_find(B_sparse)
        P_rows, P_cols, P_vals = sparse_find(P_sparse)
        
        cdef long int nz = len(A_rows)
        cdef long int nzobj = len(P_rows)
        
        # Initialize vlptype structure
        self._vlp.m = m
        self._vlp.n = n
        self._vlp.q = q
        self._vlp.nz = nz
        self._vlp.nzobj = nzobj
        self._vlp.optdir = opt_dir
        
        # Allocate and populate A_ext (combined constraint and objective matrix)
        cdef size_t total_nz = nz + nzobj
        self._vlp.A_ext = list2d_alloc(total_nz)
        self._vlp.A_ext.size = total_nz
        
        cdef size_t i
        # Copy constraint coefficients
        for i in range(nz):
            self._vlp.A_ext.idx1[i] = A_rows[i] + 1  # 1-based indexing
            self._vlp.A_ext.idx2[i] = A_cols[i] + 1
            self._vlp.A_ext.data[i] = A_vals[i]
        
        # Copy objective coefficients  
        for i in range(nzobj):
            self._vlp.A_ext.idx1[nz + i] = m + P_rows[i] + 1  # Objectives come after constraints
            self._vlp.A_ext.idx2[nz + i] = P_cols[i] + 1
            self._vlp.A_ext.data[nz + i] = P_vals[i]
        
        # Set up row bounds
        self._vlp.rows = boundlist_alloc(m)
        self._vlp.rows.size = 0  # Will be set when we add non-standard bounds
        
        cdef lp_idx row_count = 0
        cdef double a_val, b_val
        for i in range(m):
            a_val = -np.inf if a is None else a[i]
            b_val = np.inf if b is None else b[i]
            
            # Only store non-standard bounds (standard is 'f' for free)
            if np.isfinite(a_val) or np.isfinite(b_val):
                if a_val == b_val and np.isfinite(a_val):
                    # Fixed bound 's'
                    self._vlp.rows.idx[row_count] = i + 1
                    self._vlp.rows.lb[row_count] = a_val
                    self._vlp.rows.ub[row_count] = a_val
                    self._vlp.rows.type[row_count] = ord('s')
                elif np.isfinite(a_val) and np.isfinite(b_val):
                    # Double bound 'd'
                    self._vlp.rows.idx[row_count] = i + 1
                    self._vlp.rows.lb[row_count] = a_val
                    self._vlp.rows.ub[row_count] = b_val
                    self._vlp.rows.type[row_count] = ord('d')
                elif np.isfinite(a_val):
                    # Lower bound 'l'
                    self._vlp.rows.idx[row_count] = i + 1
                    self._vlp.rows.lb[row_count] = a_val
                    self._vlp.rows.ub[row_count] = 0.0  # Unused
                    self._vlp.rows.type[row_count] = ord('l')
                else:
                    # Upper bound 'u'
                    self._vlp.rows.idx[row_count] = i + 1
                    self._vlp.rows.lb[row_count] = 0.0  # Unused
                    self._vlp.rows.ub[row_count] = b_val
                    self._vlp.rows.type[row_count] = ord('u')
                row_count += 1
        self._vlp.rows.size = row_count
        
        # Set up column bounds
        self._vlp.cols = boundlist_alloc(n)
        self._vlp.cols.size = 0
        
        cdef lp_idx col_count = 0
        cdef double l_val, s_val
        for i in range(n):
            l_val = -np.inf if l is None else l[i]
            s_val = np.inf if s is None else s[i]
            
            # Only store non-standard bounds (standard is 's' for fixed at zero,
            # but for variables, standard is actually 'f' for free)
            if np.isfinite(l_val) or np.isfinite(s_val):
                if l_val == s_val and np.isfinite(l_val):
                    # Fixed bound 's'
                    self._vlp.cols.idx[col_count] = i + 1
                    self._vlp.cols.lb[col_count] = l_val
                    self._vlp.cols.ub[col_count] = l_val
                    self._vlp.cols.type[col_count] = ord('s')
                elif np.isfinite(l_val) and np.isfinite(s_val):
                    # Double bound 'd'
                    self._vlp.cols.idx[col_count] = i + 1
                    self._vlp.cols.lb[col_count] = l_val
                    self._vlp.cols.ub[col_count] = s_val
                    self._vlp.cols.type[col_count] = ord('d')
                elif np.isfinite(l_val):
                    # Lower bound 'l'
                    self._vlp.cols.idx[col_count] = i + 1
                    self._vlp.cols.lb[col_count] = l_val
                    self._vlp.cols.ub[col_count] = 0.0  # Unused
                    self._vlp.cols.type[col_count] = ord('l')
                else:
                    # Upper bound 'u'
                    self._vlp.cols.idx[col_count] = i + 1
                    self._vlp.cols.lb[col_count] = 0.0  # Unused
                    self._vlp.cols.ub[col_count] = s_val
                    self._vlp.cols.type[col_count] = ord('u')
                col_count += 1
        self._vlp.cols.size = col_count
        
        # Handle ordering cone generators
        if Y is not None:
            Y_sparse = lil_matrix(Y)
            K_rows, K_cols, K_vals = sparse_find(Y_sparse)
            self._vlp.cone_gen = CONE
            self._vlp.n_gen = Y_sparse.shape[1]
            
            # Allocate and store generators
            self._vlp.gen = <double*>malloc(Y_sparse.shape[0] * Y_sparse.shape[1] * sizeof(double))
            if self._vlp.gen == NULL:
                raise MemoryError("Failed to allocate memory for ordering cone generators")
            for i in range(len(K_vals)):
                idx = K_rows[i] * Y_sparse.shape[1] + K_cols[i]
                self._vlp.gen[idx] = K_vals[i]
                
        elif Z is not None:
            Z_sparse = lil_matrix(Z)
            K_rows, K_cols, K_vals = sparse_find(Z_sparse)
            self._vlp.cone_gen = DUALCONE
            self._vlp.n_gen = Z_sparse.shape[1]
            
            # Allocate and store generators
            self._vlp.gen = <double*>malloc(Z_sparse.shape[0] * Z_sparse.shape[1] * sizeof(double))
            if self._vlp.gen == NULL:
                raise MemoryError("Failed to allocate memory for dual cone generators")
            for i in range(len(K_vals)):
                idx = K_rows[i] * Z_sparse.shape[1] + K_cols[i]
                self._vlp.gen[idx] = K_vals[i]
        else:
            self._vlp.cone_gen = DEFAULT
            self._vlp.n_gen = 0
            self._vlp.gen = NULL
        
        # Handle duality parameter vector
        if c is not None:
            if len(c) != q:
                raise ValueError(f"c must have length {q}, got {len(c)}")
            self._vlp.c = <double*>malloc(q * sizeof(double))
            if self._vlp.c == NULL:
                raise MemoryError("Failed to allocate memory for duality parameter vector")
            for i in range(q):
                self._vlp.c[i] = c[i]
        else:
            self._vlp.c = NULL

    def toString(self):
        return("Rowns: {}, Columns: {},  Non-zero entries: {}, Non-zero objectives: {}".format(self._vlp.m, self._vlp.n, self._vlp.nz, self._vlp.nzobj))

    # Expose VLP problem data for direct access
    @property
    def m(self):
        """Number of constraints"""
        return self._vlp.m
    
    @property
    def n(self):
        """Number of variables"""
        return self._vlp.n
    
    @property
    def q(self):
        """Number of objectives"""
        return self._vlp.q
    
    @property
    def nz(self):
        """Number of non-zero constraint coefficients"""
        return self._vlp.nz
    
    @property
    def nzobj(self):
        """Number of non-zero objective coefficients"""
        return self._vlp.nzobj
    
    @property
    def optdir(self):
        """Optimization direction: 1 for minimize, -1 for maximize"""
        return self._vlp.optdir
    
    @property
    def constraint_matrix(self):
        """
        Get the constraint matrix A as a dense numpy array.
        Returns array of shape (m, n)
        """
        import numpy as np
        cdef lp_idx i, j
        cdef size_t k
        A = np.zeros((self._vlp.m, self._vlp.n))
        
        # Extract from A_ext (first nz entries are constraints)
        for k in range(self._vlp.nz):
            i = self._vlp.A_ext.idx1[k] - 1  # Convert to 0-based
            j = self._vlp.A_ext.idx2[k] - 1
            A[i, j] = self._vlp.A_ext.data[k]
        
        return A
    
    @property
    def objective_matrix(self):
        """
        Get the objective matrix P as a dense numpy array.
        Returns array of shape (q, n)
        """
        import numpy as np
        cdef lp_idx i, j
        cdef size_t k
        P = np.zeros((self._vlp.q, self._vlp.n))
        
        # Extract from A_ext (entries after nz are objectives)
        for k in range(self._vlp.nzobj):
            i = self._vlp.A_ext.idx1[self._vlp.nz + k] - 1 - self._vlp.m  # Adjust for row offset
            j = self._vlp.A_ext.idx2[self._vlp.nz + k] - 1
            P[i, j] = self._vlp.A_ext.data[self._vlp.nz + k]
        
        return P

    cdef print_vlp_address(self):
        print(<int>self._vlp)

cdef class _cVlpSolution:
    """Internal Wrap Class for Solution structure."""
    cdef soltype* _sol
    # Note: _image field removed - bensolve-2.1.0 API no longer provides direct access to polytope data
    # Polytope output handling needs to be reimplemented in future phases
    cdef int _pre_img
    cdef object argtype

    def __cinit__(self):
        self._sol = <soltype *>malloc(sizeof(soltype))
        if self._sol == NULL:
            raise MemoryError("Failed to allocate solution structure")
        
        # Initialize sol members to NULL for safe cleanup
        self._sol.eta = NULL
        self._sol.Y = NULL
        self._sol.Z = NULL
        self._sol.c = NULL
        self._sol.R = NULL
        self._sol.H = NULL

    def __dealloc__(self):
        # Free bensolve-owned members before freeing structure
        if self._sol != NULL:
            sol_free(self._sol)
            free(self._sol)

    def toString(self):
        return("Vertices Upper: {}. Vertices Lower: {}. Extreme dir Upper: {}, Extreme dir Lower: {}".format(self._sol.pp, self._sol.dd, self._sol.pp_dir, self._sol.dd_dir))

    # Expose solution data for direct access
    @property
    def status(self):
        """Solution status"""
        return self._sol.status
    
    @property
    def num_vertices_upper(self):
        """Number of vertices in upper image"""
        return self._sol.pp
    
    @property
    def num_vertices_lower(self):
        """Number of vertices in lower image"""
        return self._sol.dd
    
    @property
    def num_extreme_directions_upper(self):
        """Number of extreme directions in upper image"""
        return self._sol.pp_dir
    
    @property
    def num_extreme_directions_lower(self):
        """Number of extreme directions in lower image"""
        return self._sol.dd_dir
    
    @property
    def eta(self):
        """Phase 0 result (if computed)"""
        import numpy as np
        if self._sol.eta == NULL:
            return None
        cdef lp_idx i
        result = np.zeros(self._sol.q)
        for i in range(self._sol.q):
            result[i] = self._sol.eta[i]
        return result
    
    @property
    def Y(self):
        """Ordering cone generators (primal) as array of shape (q, o)"""
        import numpy as np
        if self._sol.Y == NULL:
            return None
        cdef lp_idx i, j
        result = np.zeros((self._sol.q, self._sol.o))
        for i in range(self._sol.q):
            for j in range(self._sol.o):
                result[i, j] = self._sol.Y[i * self._sol.o + j]
        return result
    
    @property
    def Z(self):
        """Dual cone generators as array of shape (q, p)"""
        import numpy as np
        if self._sol.Z == NULL:
            return None
        cdef lp_idx i, j
        result = np.zeros((self._sol.q, self._sol.p))
        for i in range(self._sol.q):
            for j in range(self._sol.p):
                result[i, j] = self._sol.Z[i * self._sol.p + j]
        return result
    
    @property
    def c_vector(self):
        """Duality parameter vector"""
        import numpy as np
        if self._sol.c == NULL:
            return None
        cdef lp_idx i
        result = np.zeros(self._sol.q)
        for i in range(self._sol.q):
            result[i] = self._sol.c[i]
        return result
    
    @property
    def R(self):
        """Generators of dual cone of recession cone (Phase 1 result)"""
        import numpy as np
        if self._sol.R == NULL:
            return None
        cdef lp_idx i, j
        result = np.zeros((self._sol.q, self._sol.r))
        for i in range(self._sol.q):
            for j in range(self._sol.r):
                result[i, j] = self._sol.R[i * self._sol.r + j]
        return result
    
    @property
    def H(self):
        """Generators of recession cone (Phase 1 result)"""
        import numpy as np
        if self._sol.H == NULL:
            return None
        cdef lp_idx i, j
        result = np.zeros((self._sol.q, self._sol.h))
        for i in range(self._sol.q):
            for j in range(self._sol.h):
                result[i, j] = self._sol.H[i * self._sol.h + j]
        return result


cdef _cVlpSolution _csolve(_cVlpProblem problem):
    """"Internal function to drive solving procedure. Basically, mimics bensolve main function."""
    elapsedTime = time.process_time()
    solution = _cVlpSolution()
    solution._pre_img = problem._opt.solution
    
    # Check return value of sol_init (returns int in bensolve 2.1.0)
    cdef int sol_init_status = sol_init(solution._sol, problem._vlp, problem._opt)
    if sol_init_status != 0:
        print("Warning: sol_init returned non-zero status: {}".format(sol_init_status))

    if(solution._sol.status == VLP_INPUTERROR):
        print("Error in reading")
    
    # Initialize LP (uses index 0 by default in bensolve 2.1.0)
    lp_init(problem._vlp)
    
    try:
        if(problem._opt.bounded):
            phase2_init(solution._sol, problem._vlp)
        else:
            #Phase 0
            if(problem._opt.message_level >= 3):
                print("Starting Phase 0")
            phase0(solution._sol, problem._vlp, problem._opt)
            if (solution._sol.status == VLP_UNBOUNDED):
                print("VLP is totally unbounded, there is no solution")
            if (solution._sol.status == VLP_NOVERTEX):
                print("upper image of VLP has no vertex, not covered by this version")
            if (problem._opt.message_level >= 2):
                eta = []
                for k in range(problem._vlp.q):
                    eta.append(solution._sol.eta[<int>k])
                print("Result of phase 0: eta " + str(eta))
            #Phase 1
            if (problem._opt.alg_phase1 == PRIMAL_BENSON):
                if (problem._opt.message_level >= 3):
                    print("Starting Phase 1 -- Primal Algorithm")
                phase1_primal(solution._sol,problem._vlp,problem._opt)
            else:
                assert(problem._opt.alg_phase1 == DUAL_BENSON)
                if (problem._opt.message_level >= 3):
                    print("Starting Phase 1 -- Dual Algorithm")
                phase1_dual(solution._sol,problem._vlp, problem._opt)
        #Phase 2
        if(problem._opt.alg_phase2 == PRIMAL_BENSON):
            if (problem._opt.message_level >= 3):
                print("Starting Phase 2 -- Primal Algorithm")
            phase2_primal(solution._sol, problem._vlp, problem._opt)
            solution.argtype = "phase2 primal"
        else:
            if (problem._opt.message_level >=3):
                print("Starting Phase 2 -- Dual Algorithm")
            phase2_dual(solution._sol, problem._vlp, problem._opt)
            solution.argtype = "phase2 dual"

        if (solution._sol.status == VLP_INFEASIBLE):
            print("VLP Infeasible")

        if (solution._sol.status == VLP_UNBOUNDED):
            if (problem._opt.bounded == 1):
                print("VLP is not bounded, re-run without bounded opt")
            else:
                print("LP in Phase 2 is not bounded, probably by innacuracy in phase 1")
    finally:
        # Always free LP structure, even if solving fails
        # bensolve 2.1.0 uses index 0 for the main LP
        lp_free(0)
    
    elapsedTime = (time.process_time() - elapsedTime)*1000 #Time in ms
    # Note: bensolve-2.1.0 removed logfile option
    # Log file generation would need to be reimplemented if needed
    # if (problem._opt.logfile):
    #     ...
    return(solution)

cdef _poly__vrtx2arr(polytope* poly,permutation* prm):
    """Internal function. Mimics poly__vrtx2file function, but returns two lists containing the vertex type and the coordinates"""
    cdef size_t *idx
    cdef double *val
    ls1 = []
    ls2 = np.zeros([prm.cnt,poly.dim],dtype=np.float64)
    cdef size_t k
    cdef size_t l
    k = 0
    l = 0
    idx = prm.data
    while (k < prm.cnt):
        ls1.append((1-<int>IS_ELEM(poly.ideal,idx[0])))
        val = poly.data+idx[0]*poly.dim
        l=0
        while (val < poly.data+(idx[0]+1)*poly.dim):
            ls2[<int>k,<int>l]=val[0]
            val = val + 1
            l = l + 1
        idx = idx + 1
        k = k + 1

    return((ls1,ls2))

cdef _poly__adj2arr(polytope *poly, permutation *prm):
    """Internal function. Mimics poly__adj2file function, but returns adjacency as a list of lists instead of writing to a file."""
    cdef size_t *vrtx
    cdef size_t *nghbr 
    cdef size_t k, l
    adj = []
    k = 0
    l = 0
    vrtx = prm.data
    while (k < prm.cnt):
        ls = []
        l = 0
        nghbr = (poly.adjacence+vrtx[0]).data
        while(l < (poly.adjacence+vrtx[0]).cnt):
            ls.append((prm.inv+nghbr[0])[0])
            nghbr = nghbr + 1
            l = l + 1
        adj.append(ls)
        vrtx = vrtx + 1
        k = k + 1
    return(adj)


cdef _poly__inc2arr(polytope *poly, permutation *prm, permutation *prm_dual):
    """Internal function. Mimics poly__inc2file function, but returns incidence as a list of lists instead of writing to a file."""
    cdef size_t *fct
    cdef size_t *vrtx
    cdef size_t k, l

    k=0
    l=0
    res = []
    fct = prm_dual.data

    for k in range(prm_dual.cnt):
        ls = []
        vrtx = ((poly.dual.incidence) + fct[0]).data
        for l in range(((poly.dual.incidence) + fct[0]).cnt):
            ls.append(<unsigned int>((prm.inv+vrtx[0])[0]))
            vrtx = vrtx + 1
        res.append(ls)
        fct = fct + 1

    return(res)

cdef _poly__primg2arr(polytope *poly, permutation *prm):
    """Internal function. Mimics poly__primg2file, but returns pre_image as an array instead of writting to a file."""
    cdef size_t *idx
    cdef double *val
    cdef size_t k
    preimg = []
    idx = prm.data
    for k in range(prm.cnt):
        val_list=[]
        if <int>IS_ELEM(poly.sltn,idx[0]):
            val = poly.data_primg+idx[0]*poly.dim_primg
            while (val < poly.data_primg+(idx[0] + 1)*poly.dim_primg):
                val_list.append(val[0])
                val = val + 1
        preimg.append(val_list)
        idx = idx + 1

    return(np.asarray(preimg))

cdef _poly_output(_cVlpSolution s,swap = 0):
    """
    Internal function. Mimics poly_output original functionality.
    
    TODO: bensolve-2.1.0 API change - polytope data is no longer directly accessible.
    Phase2 functions create poly_args internally and don't expose them.
    Options to fix:
    1. Read polytope data from files written by bensolve
    2. Modify bensolve-2.1.0 to expose polytope data
    3. Use alternative API if available
    
    For now, returning empty/placeholder data to allow compilation.
    """
    warn("WARNING: Polytope data extraction not yet implemented for bensolve-2.1.0 API. "
         "Returning placeholder data. Full functionality requires additional implementation.")
    
    # Return placeholder empty data structures
    import numpy as np
    ls1_p = []
    ls2_p = np.array([])
    adj_p = []
    inc_p = []
    pre_p = None
    
    ls1_d = []
    ls2_d = np.array([])
    adj_d = []
    inc_d = []
    pre_d = None
    
    return(((ls1_p,ls2_p,adj_p,inc_p,pre_p),(ls1_d,ls2_d,adj_d,inc_d,pre_d)))

class vlpProblem:
    "Wrapper Class for a vlpProblem"

    @property
    def default_options(self):
            return {
            'write_files':False,
            'log_file':False,
            'bounded': False,
            'solution':False,
            'message_level':3,
            'lp_message_level':0,
            'alg_phase1':'primal',
            'alg_phase2':'primal',
            'lp_method_phase0':'primal_simplex',
            'lp_method_phase1':'auto',
            'lp_method_phase2':'auto'}

    def __init__(self, B=None, a=None, b=None, l=None, s=None,
                 P=None, Y=None, Z=None, c=None,
                 opt_dir=None, filename = None, options = None):
        self.B = B
        self.a = a
        self.b = b
        self.l = l
        self.s = s
        self.P = P
        self.Y = Y
        self.Z = Z
        self.c = c
        self.opt_dir = opt_dir
        self.options = options if options is not None else self.default_options

    @property
    def vlpfile(self):
        #Return a file-like object containing the vlp description. Based on "prob2vlp.m" MATLAB script
        def getlen(obj):
            return 0 if obj is None else len(obj)

 #VLP is 1 based, constraint numbering starts at 1!!
        if hasattr(self,'ub') and not hasattr(self,'s'):
            self.s = self.ub
        if hasattr(self,'lb') and not hasattr(self,'l'):
            self.l = self.lb
        if self.opt_dir is None:
            self.opt_dir = 1
        if self.B is None:
            raise RuntimeError('Coefficient Matrix B must be given')
        if self.P is None:
            raise RuntimeError('Coefficient Matrix P must be given')
#        if not hasattr(self.B,'shape'):
#            raise RuntimeError('Matrix B has no shape attribute')
#        if not hasattr(self.P,'shape'):
#            raise RuntimeError('Matrix P has no shape attribute')
        (m,n) = self.B.shape
        (q,p) = self.P.shape
        if (n != p):
            raise RuntimeError('B and P must have same number of columns')

        [A_rows,A_cols,A_vals]=find(lil_matrix(self.B))
        k=len(A_rows)
        [P_rows,P_cols,P_vals]=find(lil_matrix(self.P))
        k1=len(P_rows)
        kstr=''
        if self.Y is not None and self.Y.shape[1] > 0:
            [K_rows,K_cols,K_vals]=find(lil_matrix(self.Y))
            k2=len(K_rows)
            kstr=' cone {} {}'.format(self.Y.shape[1],k2)
        elif self.Z is not None and self.Z.shape[1] > 0:
            [K_rows,K_cols,K_vals] = find(lil_matrix(self.Z))
            k2 = len(K_rows)
            kstr=' dualcone {} {}'.format(self.Z.shape[1],k2)
        else:
            k2=0

        opt_dir_str=''
        if self.opt_dir==1:
            opt_dir_str = 'min'
        elif self.opt_dir==-1:
            opt_dir_str = 'max'
        else:
            raise RuntimeError('Invalid value for opt_dir: use -1 or 1 for maximitation and minimization')

        try:
            file = StringIO()
        except OSError as e:
            print("OS error: {0}".format(e))
            raise
        #Write 'p', 'a', 'k' to file
        file.write("p vlp {} {} {} {} {} {}{}\n".format(opt_dir_str,m,n,k,q,k1,kstr))
        for i in list(range(k)):
            file.write("a {} {} {}\n".format(A_rows[i]+1,A_cols[i]+1,A_vals[i]))
        for i in list(range(k1)):
            file.write("o {} {} {}\n".format(P_rows[i]+1,P_cols[i]+1,P_vals[i]))
        for i in list(range(k2)):
            file.write("k {} {} {}\n".format(K_rows[i]+1,K_cols[i]+1,K_vals[i]))
        # duality parameter vector

        if self.c is not None:
            if(len(np.array(self.c).shape) != 1  ) or (len(self.c)!=q) :
                raise RuntimeError('c has wrong dimension')
            for i in range(q):
                file.write("k {} 0 {}\n".format(i+1,self.c[i]))

        #Write row
        if (len(np.array(self.a).shape) > 1):
            raise RuntimeError('a has wrong dimension')
        if (len(np.array(self.b).shape) > 1):
            raise RuntimeError('b has wrong dimension')
        m1 = max(getlen(self.a),getlen(self.b))
        if self.a is None:
            aa = -np.inf*np.ones((m1,1))
        else:
            aa = self.a
        if self.b is None:
            bb =  np.inf*np.ones((m1,1))
        else:
            bb = self.b

        for i in list(range(m1)):
            if aa[i] < bb[i]:
                ch = 2*np.isfinite(aa[i]) + np.isfinite(bb[i])
                if ch == 0:
                    file.write('i {} f \n'.format(i+1))
                elif ch == 1:
                    file.write('i {} u {}\n'.format(i+1,bb[i]))
                elif ch == 2:
                    file.write('i {} l {}\n'.format(i+1,aa[i]))
                elif ch == 3:
                    file.write('i {} d {} {}\n' .format(i+1,aa[i],bb[i]))
                else:
                    raise RuntimeError("Bad ch switch for constrains bounds")
            elif aa[i] == bb[i] and np.isfinite(aa[i]):
                file.write('i {} s {}\n'.format(i+1,aa[i]))
            else:
                raise RuntimeError('Invalid constraints: a[{}]={}, b[{}]={}'.format(i+1,aa[i],i,bb[i]))

        #Write cols
        if self.l is None:
            llb=-np.inf*np.ones((n,1))
        else:
            llb=self.l

        if self.s is None:
            uub= np.inf*np.ones((n,1))
        else:
            uub= self.s

        for j in range(n):
            if llb[j] < uub[j]:
                ch = 2*np.isfinite(llb[j]) + np.isfinite(uub[j])
                if ch == 0:
                    file.write('j {} f \n'.format(j+1))
                elif ch == 1:
                    file.write('j {} u {}\n'.format(j+1,uub[j]))
                elif ch == 2:
                    file.write('j {} l {}\n'.format(j+1,llb[j]))
                elif ch == 3:
                    file.write('j {} d {} {}\n' .format(j+1,llb[j],uub[j]))
                else:
                    raise RuntimeError("Bad ch switch for variable bounds")
            elif llb[j] == uub[j] and np.isfinite(llb[j]):
                file.write('j {} s {}\n'.format(j+1,llb[j]))
            else:
                raise RuntimeError('Invalid constraints: l[{}]={}, s[{}]={}'.format(j+1,llb[j],i,uub[j]))
        file.write('e ')
        file.seek(0)
        return(file)


    def to_vlp_file(self,filename=None):
        if (filename == None):
            raise RuntimeError("No filename given")
        try:
            print(filename)
            mode = 'w'
            if sys.version_info.major < 3:
                mode += 'b'
            file_out = io_open(filename,mode=mode)
        except OSError as e:
            print("OS Error {0}".format(e))
            raise
        vlpfile = self.vlpfile
        for line in self.vlpfile:
            file_out.write(line)
        vlpfile.close()
        file_out.close()

    def to_vlp_string(self):
        vlpfile = self.vlpfile
        for line in vlpfile:
            print(line,end="")
        vlpfile.close()

    def _cdefault_options(self):
        cProb = _cVlpProblem()
        cProb.default_options()
        return(cProb.options)


class vlpSolution:
    """Wrapper Class for a vlpSolution"""

    def __init__(self):
        self.Primal = None
        self.Dual = None
        self.c = None

    def __str__(self):
        def string_poly(ntp_poly,**kargs):
            """Returns a string representation of the polytopes"""
            field_names = ["Vertex","Type","Value","Adjacency"]
            x = PrettyTable(field_names,**kargs)
            for i in range(len(ntp_poly.vertex_type)):
                x.add_row([i,
                    ntp_poly.vertex_type[i],
                    ntp_poly.vertex_value[i],
                    ntp_poly.adj[i]])

            return x.get_string()

        def string_inc(poly1,poly2,name1,name2,**kargs):
            """Returns a string representation of the incidence matrix"""
            field_names = ["Vertex of {}".format(name2),"Incidence in {}".format(name1)]
            x = PrettyTable(field_names,**kargs)
            for j in range(len(poly2.vertex_type)):
                x.add_row([j,poly1.incidence[j]])

            return x.get_string()

        return "c:{}\nPrimal\n{}\n{}\nDual\n{}\n{}".format(
                                                        str(self.c),
                                                        string_poly(self.Primal),
                                                        string_inc(self.Primal,self.Dual,"Primal","Dual"),
                                                        string_poly(self.Dual),
                                                        string_inc(self.Dual,self.Primal,"Dual","Primal"))


def solve(problem):
    """Solves a vlpProblem instance. It returns a vlpSolution instance"""
    tempfile = NamedTemporaryFile(mode='w+t')
    problem.to_vlp_file(filename=tempfile.name)
    tempfile.flush()
    tempfile.seek(0)
    cProblem = _cVlpProblem()
    cProblem.from_file(tempfile.name)
    cProblem.set_options(problem.options)
    cSolution = _csolve(cProblem)
    ((ls1_p,ls2_p,adj_p,inc_p,preimg_p),(ls1_d,ls2_d,adj_d,inc_d,preimg_d)) = _poly_output(cSolution,swap=(problem.options['alg_phase2']=='dual'))
    sol = vlpSolution()
    Primal = ntp('Primal',['vertex_type','vertex_value','adj','incidence','preimage'])
    Dual = ntp('Dual',['vertex_type','vertex_value','adj','incidence','preimage'])
    c = []
    cdef size_t k
    for k in range(<size_t> cProblem._vlp.q):
        c.append(cSolution._sol.c[k])
    sol.Primal = Primal(ls1_p,ls2_p,adj_p,inc_p,preimg_p)
    sol.Dual = Dual(ls1_d,ls2_d,adj_d,inc_d,preimg_d)
    sol.c = c
    del cProblem
    del cSolution
    tempfile.close()
    return(sol)


def solve_direct(B, P, a=None, b=None, l=None, s=None, Y=None, Z=None, c=None, opt_dir=1, options=None):
    """
    Solve a VLP problem directly from numpy arrays, bypassing file I/O.
    
    This is a more efficient alternative to the standard solve() function that avoids
    writing to temporary files.
    
    Parameters:
    -----------
    B : array-like (m x n)
        Constraint matrix
    P : array-like (q x n)
        Objective matrix
    a : array-like (m,), optional
        Lower bounds for constraints (default: -inf)
    b : array-like (m,), optional
        Upper bounds for constraints (default: +inf)
    l : array-like (n,), optional
        Lower bounds for variables (default: -inf)
    s : array-like (n,), optional
        Upper bounds for variables (default: +inf)
    Y : array-like (q x k), optional
        Ordering cone generators (primal)
    Z : array-like (q x k), optional
        Ordering cone generators (dual)
    c : array-like (q,), optional
        Duality parameter vector
    opt_dir : int
        Optimization direction: 1 for minimize, -1 for maximize
    options : dict, optional
        Solver options (same as vlpProblem.options)
    
    Returns:
    --------
    vlpSolution
        Solution object containing primal and dual polytopes
        
    Example:
    --------
    >>> import numpy as np
    >>> B = np.array([[1, 1], [1, 0]])
    >>> P = np.array([[1, 0], [0, 1]])
    >>> b = np.array([1, 1])
    >>> sol = solve_direct(B, P, b=b, opt_dir=1)
    """
    # Create and configure problem
    cProblem = _cVlpProblem()
    
    # Set options
    if options is None:
        options = vlpProblem().default_options
    cProblem.set_options(options)
    
    # Initialize from arrays (bypasses file I/O)
    cProblem.from_arrays(B, P, a, b, l, s, Y, Z, c, opt_dir)
    
    # Solve
    cSolution = _csolve(cProblem)
    
    # Extract results
    ((ls1_p,ls2_p,adj_p,inc_p,preimg_p),(ls1_d,ls2_d,adj_d,inc_d,preimg_d)) = _poly_output(cSolution,swap=(options['alg_phase2']=='dual'))
    
    sol = vlpSolution()
    Primal = ntp('Primal',['vertex_type','vertex_value','adj','incidence','preimage'])
    Dual = ntp('Dual',['vertex_type','vertex_value','adj','incidence','preimage'])
    
    c_result = []
    cdef size_t k
    for k in range(<size_t> cProblem._vlp.q):
        c_result.append(cSolution._sol.c[k])
    
    sol.Primal = Primal(ls1_p,ls2_p,adj_p,inc_p,preimg_p)
    sol.Dual = Dual(ls1_d,ls2_d,adj_d,inc_d,preimg_d)
    sol.c = c_result
    
    del cProblem
    del cSolution
    
    return sol


