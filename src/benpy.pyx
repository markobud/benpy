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
        # Free any existing allocations before loading new problem
        vlp_free(self._vlp)
        # Re-initialize to NULL
        self._vlp.A_ext = NULL
        self._vlp.rows = NULL
        self._vlp.cols = NULL
        self._vlp.gen = NULL
        self._vlp.c = NULL

        if not isinstance(filename,bytes):
            filename = filename.encode()

        basename, _ = splitext(filename)
        self.set_options({'filename':basename})
        if(vlp_init(filename,self._vlp,self._opt)):
            print("Error in reading")

    def from_arrays(self, B, P, a=None, b=None, l=None, s=None, Y=None, Z=None, c=None, opt_dir=1):
        """
        Initialize VLP problem directly from numpy arrays.
        
        This implementation generates a VLP format string internally and uses from_file()
        to ensure perfect consistency with the file-based solve() method.
        
        Note: This approach uses temporary file I/O to leverage the bensolve VLP parser.
        While this adds small I/O overhead during problem setup, it guarantees
        correctness and consistency with solve(). The overhead is minimal since file
        operations occur only once during initialization, not during solving.
        
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
        # Import numpy and scipy at module level would be ideal, but for Cython
        # compatibility and to avoid circular imports, we import here
        import numpy as np
        from scipy.sparse import lil_matrix
        from tempfile import NamedTemporaryFile
        import os
        
        # Generate VLP format string using the same logic as vlpProblem.vlpfile
        # This ensures perfect consistency with the file-based solve() method
        
        # Convert to sparse matrices
        B_sparse = lil_matrix(B)
        P_sparse = lil_matrix(P)
        
        m, n = B_sparse.shape
        q, p = P_sparse.shape
        
        if n != p:
            raise ValueError(f"B and P must have same number of columns, got {n} and {p}")
        
        # Find non-zero entries
        A_rows, A_cols, A_vals = find(B_sparse)
        k = len(A_rows)
        P_rows, P_cols, P_vals = find(P_sparse)
        k1 = len(P_rows)
        
        # Handle ordering cone generators
        kstr = ''
        k2 = 0
        if Y is not None and hasattr(Y, 'shape') and Y.shape[1] > 0:
            Y_sparse = lil_matrix(Y)
            K_rows, K_cols, K_vals = find(Y_sparse)
            k2 = len(K_rows)
            kstr = ' cone {} {}'.format(Y.shape[1], k2)
        elif Z is not None and hasattr(Z, 'shape') and Z.shape[1] > 0:
            Z_sparse = lil_matrix(Z)
            K_rows, K_cols, K_vals = find(Z_sparse)
            k2 = len(K_rows)
            kstr = ' dualcone {} {}'.format(Z.shape[1], k2)
        
        # Optimization direction
        opt_dir_str = 'min' if opt_dir == 1 else 'max'
        
        # Build VLP format string
        vlp_lines = []
        vlp_lines.append("p vlp {} {} {} {} {} {}{}".format(opt_dir_str, m, n, k, q, k1, kstr))
        
        # Write constraint coefficients
        for i in range(k):
            vlp_lines.append("a {} {} {}".format(A_rows[i]+1, A_cols[i]+1, A_vals[i]))
        
        # Write objective coefficients
        for i in range(k1):
            vlp_lines.append("o {} {} {}".format(P_rows[i]+1, P_cols[i]+1, P_vals[i]))
        
        # Write cone generators
        if k2 > 0:
            for i in range(k2):
                vlp_lines.append("k {} {} {}".format(K_rows[i]+1, K_cols[i]+1, K_vals[i]))
        
        # Write duality parameter vector
        if c is not None:
            if len(c) != q:
                raise ValueError(f"c must have length {q}, got {len(c)}")
            for i in range(q):
                vlp_lines.append("k {} 0 {}".format(i+1, c[i]))
        
        # Write row bounds
        aa = np.full(m, -np.inf) if a is None else np.asarray(a)
        bb = np.full(m, np.inf) if b is None else np.asarray(b)
        
        for i in range(m):
            if aa[i] < bb[i]:
                ch = 2*np.isfinite(aa[i]) + np.isfinite(bb[i])
                if ch == 0:
                    vlp_lines.append('i {} f'.format(i+1))
                elif ch == 1:
                    vlp_lines.append('i {} u {}'.format(i+1, bb[i]))
                elif ch == 2:
                    vlp_lines.append('i {} l {}'.format(i+1, aa[i]))
                elif ch == 3:
                    vlp_lines.append('i {} d {} {}'.format(i+1, aa[i], bb[i]))
            elif aa[i] == bb[i] and np.isfinite(aa[i]):
                vlp_lines.append('i {} s {}'.format(i+1, aa[i]))
            else:
                raise ValueError('Invalid constraints: a[{}]={}, b[{}]={}'.format(i, aa[i], i, bb[i]))
        
        # Write column bounds
        llb = np.full(n, -np.inf) if l is None else np.asarray(l)
        uub = np.full(n, np.inf) if s is None else np.asarray(s)
        
        for j in range(n):
            if llb[j] < uub[j]:
                ch = 2*np.isfinite(llb[j]) + np.isfinite(uub[j])
                if ch == 0:
                    vlp_lines.append('j {} f'.format(j+1))
                elif ch == 1:
                    vlp_lines.append('j {} u {}'.format(j+1, uub[j]))
                elif ch == 2:
                    vlp_lines.append('j {} l {}'.format(j+1, llb[j]))
                elif ch == 3:
                    vlp_lines.append('j {} d {} {}'.format(j+1, llb[j], uub[j]))
            elif llb[j] == uub[j] and np.isfinite(llb[j]):
                vlp_lines.append('j {} s {}'.format(j+1, llb[j]))
            else:
                raise ValueError('Invalid variable bounds: l[{}]={}, s[{}]={}'.format(j, llb[j], j, uub[j]))
        
        vlp_lines.append('e')
        
        # Write to temporary file and load via from_file
        # This ensures we use the exact same VLP parser as solve()
        with NamedTemporaryFile(mode='w+t', suffix='.vlp', delete=False) as f:
            f.write('\n'.join(vlp_lines))
            f.write('\n')
            temp_filename = f.name
        
        try:
            # Use from_file to load the problem via vlp_init() C function
            # This ensures perfect consistency with the file-based solve() method
            self.from_file(temp_filename)
        finally:
            # Clean up temporary file
            try:
                os.unlink(temp_filename)
            except:
                pass

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
        
        Note: bensolve internally negates objectives for minimization problems.
        This property returns the original user-provided objective matrix by
        applying the appropriate sign correction.
        """
        import numpy as np
        cdef lp_idx i, j
        cdef size_t k
        P = np.zeros((self._vlp.q, self._vlp.n))
        
        # Extract from A_ext (entries after nz are objectives)
        for k in range(self._vlp.nzobj):
            i = self._vlp.A_ext.idx1[self._vlp.nz + k] - 1 - self._vlp.m  # Adjust for row offset
            j = self._vlp.A_ext.idx2[self._vlp.nz + k] - 1
            # bensolve negates objectives for minimization (optdir=1)
            # so we need to negate them back to get the original matrix
            if self._vlp.optdir == 1:
                P[i, j] = -self._vlp.A_ext.data[self._vlp.nz + k]
            else:
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
            # Release GIL for phase2_init (computational work)
            with nogil:
                phase2_init(solution._sol, problem._vlp)
        else:
            #Phase 0
            if(problem._opt.message_level >= 3):
                print("Starting Phase 0")
            # Release GIL for phase0 (long-running operation)
            # Note: bensolve is not thread-safe due to global state, but releasing
            # the GIL allows other Python threads to do I/O and improves responsiveness
            with nogil:
                phase0(solution._sol, problem._vlp, problem._opt)
            if (solution._sol.status == VLP_UNBOUNDED):
                print("VLP is totally unbounded, there is no solution")
                # Early return to avoid undefined behavior in phase 1/2
                # This matches bensolve main.c behavior and prevents crashes on Windows
                # Note: lp_free(0) will be called in finally block
                return solution
            if (solution._sol.status == VLP_NOVERTEX):
                print("upper image of VLP has no vertex, not covered by this version")
                # Early return to avoid undefined behavior in phase 1/2
                # This matches bensolve main.c behavior and prevents crashes on Windows
                # Note: lp_free(0) will be called in finally block
                return solution
            if (problem._opt.message_level >= 2):
                eta = []
                for k in range(problem._vlp.q):
                    eta.append(solution._sol.eta[<int>k])
                print("Result of phase 0: eta " + str(eta))
            #Phase 1
            if (problem._opt.alg_phase1 == PRIMAL_BENSON):
                if (problem._opt.message_level >= 3):
                    print("Starting Phase 1 -- Primal Algorithm")
                # Release GIL for phase1_primal (long-running operation)
                with nogil:
                    phase1_primal(solution._sol,problem._vlp,problem._opt)
            else:
                assert(problem._opt.alg_phase1 == DUAL_BENSON)
                if (problem._opt.message_level >= 3):
                    print("Starting Phase 1 -- Dual Algorithm")
                # Release GIL for phase1_dual (long-running operation)
                with nogil:
                    phase1_dual(solution._sol,problem._vlp, problem._opt)
        #Phase 2
        if(problem._opt.alg_phase2 == PRIMAL_BENSON):
            if (problem._opt.message_level >= 3):
                print("Starting Phase 2 -- Primal Algorithm")
            # Release GIL for phase2_primal (long-running operation)
            with nogil:
                phase2_primal(solution._sol, problem._vlp, problem._opt)
            solution.argtype = "phase2 primal"
        else:
            if (problem._opt.message_level >=3):
                print("Starting Phase 2 -- Dual Algorithm")
            # Release GIL for phase2_dual (long-running operation)
            with nogil:
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

cdef _poly_output(_cVlpSolution s, _cVlpProblem problem, swap = 0):
    """
    Internal function. Reads polytope data from files written by bensolve.
    
    Bensolve 2.1.0 writes polytope data to files during phase2 execution.
    This function reads those files and converts them to Python data structures.
    
    Parameters:
    -----------
    s : _cVlpSolution
        Solution object containing vertex counts
    problem : _cVlpProblem  
        Problem object containing filename in _opt.filename
    swap : int
        Whether primal/dual are swapped (0 for primal, 1 for dual algorithm)
    
    Returns:
    --------
    Tuple of ((primal_data), (dual_data)) where each contains:
        (vertex_type_list, vertex_value_array, adjacency_list, incidence_list, preimage)
    """
    import numpy as np
    import os
    
    # Get the base filename from problem options
    # The filename is stored as a char array in _opt.filename (max 256 chars)
    # We need to decode it from the C string
    filename = problem._opt.filename.decode('utf-8') if problem._opt.filename[0] != 0 else ""
    
    # Define file suffixes based on bensolve conventions
    # These match the constants in bslv_main.h:
    # IMG_P_STR "_img_p", IMG_D_STR "_img_d", ADJ_P_STR "_adj_p", etc.
    img_p_file = filename + "_img_p.sol"
    img_d_file = filename + "_img_d.sol"
    adj_p_file = filename + "_adj_p.sol"
    adj_d_file = filename + "_adj_d.sol"
    inc_p_file = filename + "_inc_p.sol"
    inc_d_file = filename + "_inc_d.sol"
    pre_img_p_file = filename + "_pre_img_p.sol"
    pre_img_d_file = filename + "_pre_img_d.sol"
    
    # Read vertex data (type and values)
    def read_vertices(filepath):
        """Read vertex file. Format: <type> <val1> <val2> ... <valn>"""
        if not os.path.exists(filepath):
            return [], np.array([])
        
        vertex_types = []
        vertex_values = []
        
        with open(filepath, 'r', encoding='utf-8') as f:
            for line in f:
                parts = line.strip().split()
                if len(parts) > 0:
                    vertex_types.append(int(parts[0]))
                    if len(parts) > 1:
                        vertex_values.append([float(x) for x in parts[1:]])
        
        if len(vertex_values) == 0:
            return vertex_types, np.array([])
        return vertex_types, np.array(vertex_values)
    
    # Read adjacency data
    def read_adjacency(filepath):
        """Read adjacency file. Each line has space-separated vertex indices."""
        if not os.path.exists(filepath):
            return []
        
        adjacency = []
        with open(filepath, 'r', encoding='utf-8') as f:
            for line in f:
                parts = line.strip().split()
                if len(parts) > 0:
                    adjacency.append([int(x) for x in parts])
                else:
                    adjacency.append([])
        
        return adjacency
    
    # Read incidence data  
    def read_incidence(filepath):
        """Read incidence file. Each line has space-separated vertex indices."""
        if not os.path.exists(filepath):
            return []
        
        incidence = []
        with open(filepath, 'r', encoding='utf-8') as f:
            for line in f:
                parts = line.strip().split()
                if len(parts) > 0:
                    incidence.append([int(x) for x in parts])
                else:
                    incidence.append([])
        
        return incidence
    
    # Read preimage data
    def read_preimage(filepath):
        """Read preimage file. Each line has space-separated coordinates.
        
        Returns None if:
        - File doesn't exist
        - File contains error message (e.g., "Solution (pre-image) was not stored")
        - File is empty
        """
        if not os.path.exists(filepath):
            return None
        
        preimage = []
        with open(filepath, 'r', encoding='utf-8') as f:
            for line in f:
                parts = line.strip().split()
                # Skip empty lines or lines that start with non-numeric text
                # (bensolve writes "Solution (pre-image) was not stored" when -s option not used)
                if len(parts) == 0:
                    continue
                # Try to parse as floats; if it fails, skip this file
                try:
                    preimage.append([float(x) for x in parts])
                except ValueError:
                    # This line contains non-numeric data (likely an error message)
                    # Return None to indicate no preimage data available
                    return None
        
        if len(preimage) == 0:
            return None
        return np.array(preimage)
    
    # Read primal (upper) image data
    ls1_p, ls2_p = read_vertices(img_p_file)
    adj_p = read_adjacency(adj_p_file)
    inc_p = read_incidence(inc_p_file)
    pre_p = read_preimage(pre_img_p_file)
    
    # Read dual (lower) image data
    ls1_d, ls2_d = read_vertices(img_d_file)
    adj_d = read_adjacency(adj_d_file)
    inc_d = read_incidence(inc_d_file)
    pre_d = read_preimage(pre_img_d_file)
    
    # If swap is enabled, switch primal and dual
    # This happens when using dual algorithm
    if swap:
        return ((ls1_d, ls2_d, adj_d, inc_d, pre_d), (ls1_p, ls2_p, adj_p, inc_p, pre_p))
    else:
        return ((ls1_p, ls2_p, adj_p, inc_p, pre_p), (ls1_d, ls2_d, adj_d, inc_d, pre_d))

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


def _status_to_string(status):
    """Convert sol_status_type enum to human-readable string"""
    status_map = {
        VLP_NOSTATUS: "no_status",
        VLP_INFEASIBLE: "infeasible",
        VLP_UNBOUNDED: "unbounded",
        VLP_NOVERTEX: "no_vertex",
        VLP_OPTIMAL: "optimal",
        VLP_INPUTERROR: "input_error",
        VLP_UNEXPECTED_STATUS: "unexpected_status"
    }
    return status_map.get(status, f"unknown_status_{status}")


class vlpSolution:
    """Wrapper Class for a vlpSolution"""

    def __init__(self):
        self.Primal = None
        self.Dual = None
        self.c = None
        self.status = None
        self.num_vertices_upper = None
        self.num_vertices_lower = None
        self.Y = None
        self.Z = None
        self.eta = None
        self.R = None
        self.H = None

    @property
    def c_vector(self):
        """Duality parameter vector as numpy array (alias for c)"""
        import numpy as np
        if self.c is None:
            return None
        return np.array(self.c)

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
    ((ls1_p,ls2_p,adj_p,inc_p,preimg_p),(ls1_d,ls2_d,adj_d,inc_d,preimg_d)) = _poly_output(cSolution,cProblem,swap=(problem.options['alg_phase2']=='dual'))
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
    
    # Add new attributes from cSolution
    sol.status = _status_to_string(cSolution.status)
    sol.num_vertices_upper = cSolution.num_vertices_upper
    sol.num_vertices_lower = cSolution.num_vertices_lower
    sol.Y = cSolution.Y
    sol.Z = cSolution.Z
    sol.eta = cSolution.eta
    sol.R = cSolution.R
    sol.H = cSolution.H
    
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
    ((ls1_p,ls2_p,adj_p,inc_p,preimg_p),(ls1_d,ls2_d,adj_d,inc_d,preimg_d)) = _poly_output(cSolution,cProblem,swap=(options['alg_phase2']=='dual'))
    
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
    
    # Add new attributes from cSolution
    sol.status = _status_to_string(cSolution.status)
    sol.num_vertices_upper = cSolution.num_vertices_upper
    sol.num_vertices_lower = cSolution.num_vertices_lower
    sol.Y = cSolution.Y
    sol.Z = cSolution.Z
    sol.eta = cSolution.eta
    sol.R = cSolution.R
    sol.H = cSolution.H
    
    del cProblem
    del cSolution
    
    return sol


