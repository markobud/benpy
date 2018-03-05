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
from io import StringIO
from tempfile import NamedTemporaryFile

THISVERSION = 'version MODIFIED 2.0.1'

cdef extern from "bensolve-mod/bslv_main.h":
    cdef enum _lp_method_type:
        PRIMAL_SIMPLEX, DUAL_SIMPLEX, DUAL_PRIMAL_SIMPLEX, LP_METHOD_AUTO

    cdef enum _alg_type:
        PRIMAL_BENSON, DUAL_BENSON

    cdef enum _lp_method_type:
        PRIMAL_SIMPLEX, DUAL_SIMPLEX, DUAL_PRIMAL_SIMPLEX, LP_METHOD_AUTO

    cdef enum _lp_hom_type:
        HOMOGENEOUS, INHOMOGENEOUS

    cdef enum _cone_out_type:
        CONE_OUT_OFF, CONE_OUT_ON

    cdef enum _phase_type:
        PHASE0, PHASE1_PRIMAL, PHASE1_DUAL, PHASE2_PRIMAL, PHASE2_DUAL

    cdef enum _format_type:
        FORMAT_SHORT, FORMAT_LONG, FORMAT_AUTO

    cdef enum _lp_status_type:
        LP_INFEASIBLE, LP_UNBOUNDED, LP_UNEXPECTED_STATUS, LP_UNDEFINED_STATUS, LP_OPTIMAL

    cdef enum _sol_status_type:
        VLP_NOSTATUS, VLP_INFEASIBLE, VLP_UNBOUNDED, VLP_NOVERTEX, VLP_OPTIMAL, VLP_INPUTERROR

    cdef enum _cone_gen_type:
        CONE, DUALCONE, DEFAULT

    cdef enum _c_dir_type:
        C_DIR_POS, C_DIR_NEG

    cdef enum _swap_type:
        SWAP, NO_SWAP

    cdef enum _pre_img_type:
        PRE_IMG_OFF, PRE_IMG_ON


    ctypedef int lp_idx
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
    ctypedef _lp_hom_type lp_hom_type

cdef extern from "bensolve-mod/bslv_lp.h":

    ctypedef struct lptype:
        pass

    void lp_init(vlptype *vlp, lptype *lpstr)
    int lp_get_num (lptype *lpstr)
    void lp_free(lptype *lpstr)


cdef extern from "bensolve-mod/bslv_algs.h":

    void phase0(soltype *sol, vlptype *vlp, opttype *opt, lptype *lpstr)
    void phase1_primal(soltype *sol, vlptype *vlp, opttype *opt, lptype *lpstr)
    void phase2_primal(soltype *sol, vlptype *vlp, opttype *opt, lptype *lpstr, poly_args *image)
    void phase1_dual(soltype * sol, vlptype *vlp, opttype *opt, lptype *lpstr)
    void phase2_dual(soltype * sol, vlptype *vlp, opttype *opt, lptype *lpstr, poly_args *image)
    void phase2_init(soltype *sol, vlptype *vlp)


cdef extern from "bensolve-mod/bslv_poly.h":

    ctypedef size_t btstrg
    ctypedef btstrg vrtx_strg
    size_t BTCNT
    size_t ST_BT(vrtx_strg *lst, size_t idx)
    size_t UNST_BT(vrtx_strg *lst, size_t idx)
    size_t IS_ELEM(vrtx_strg *lst, size_t idx)

    ctypedef struct poly_list:
        size_t cnt
        size_t blcks
        size_t *data

    ctypedef struct polytope:
        size_t dim,dim_primg
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
        double eps
        polytope primal
        polytope dual

    ctypedef struct permutation:
        size_t cnt
        size_t *data
        size_t *inv

    void poly__initialise_permutation (polytope *, permutation *)
    void poly__kill(poly_args *)
    

cdef extern from "bensolve-mod/bslv_lists.h":
    ctypedef struct list1d:
        pass

    ctypedef struct list2d:
        pass

    ctypedef struct boundlist:
        pass

cdef extern from "bensolve-mod/bslv_vlp.h":
    ctypedef struct csatype:
        pass

    ctypedef struct vlptype:
        list2d *A_ext     # non-zero constraint and objective coefficients: A_ext = (A,0P -I)
        boundlist *rows            # non-standard row bounds (standard is 'f')
        boundlist *cols            # non-standard column bounds (standard is 's')
        int optdir     # 1 for minimization, -1 for maximization
        cone_gen_type cone_gen           # type of ordering cone generators CONE: CONE | DUALCONE | DEFAULT
        double *gen     # generators of ordering cone (primal or dual)
        double *c     # duality parameter vector (given data, unscaled)
        long int nz     # number of non-zero entries of A
        long int nzobj     # number of non-zero entries of P
        lp_idx n     # number of variables (cols)
        lp_idx m     # number of constraints (rows)
        lp_idx q     # number of objectives
        lp_idx n_gen     # number of generators of ordering cone (primal or dual)

    ctypedef struct soltype:
        lp_idx m            # number of rows (constraints)
        lp_idx n            # number of cols (variables)
        lp_idx q            # number of objectives
        lp_idx o            # number of generators of ordering cone (after vertex enumeration and scaling)
        lp_idx p            # number of generators of dual of ordering cone (after vertex enumeration and scaling)
        lp_idx r            # number of generators of dual cone of recession cone of upper image
        lp_idx h            # number of generators of recession cone of upper image
        double *eta            # result of phase0
        double *Y            # generators of ordering cone as columns of Y (non-redundant and scaled columns)
        double *Z            # generators of dual cone of C as columns in matrix Z (non-redundant and scaled columns that that Z' * c == (1,...,1)')
        double *c            # geometric duality parameter vector (scaled such that c_q=1)
        double *R            # result of phase1: columns are generators of dual cone of recession cone of upper image
        double *H            # result of phase1: columns are generators of recession cone of upper image
        sol_status_type status           # solution status of VLP
        c_dir_type c_dir           # type of duality parameter vector
        size_t pp            # number of vertices of upper image
        size_t dd            # number of vertices of lower image
        size_t pp_dir            # number of extreme directions of upper image
        size_t dd_dir            # number of extreme directions of lower image

    ctypedef struct opttype:
        int bounded
        int plot
        int printfiles                                  # boolean to print output files
        int logfile                                     # boolean to print log file
        char filename[255+1]
        pre_img_type solution                           # PRE_IMG_OFF - PRE_IMG_ON
        format_type format                              # SHORT - LONG - AUTO
        lp_method_type lp_method_phase0                 # PRIMAL_SIMPLEX - DUAL_SIMPLEX - DUAL
        lp_method_type lp_method_phase1                 # PRIMAL_SIMPLEX - DUAL_SIMPLEX - DUAL
        lp_method_type lp_method_phase2                 # PRIMAL_SIMPLEX - DUAL_SIMPLEX - DUAL
        int message_level                               # 0 - 1 - 2 - 3
        int lp_message_level                            # 0 - 1 - 2 - 3
        alg_type alg_phase1                             # PRIMAL - DUAL
        alg_type alg_phase2                             # PRIMAL - DUAL
        double eps_phase0                               # Epsilon used in Phas
        double eps_phase1                               # Epsilon used in Phas
        double eps_benson_phase1                        # Epsilon of Benson algorithm 
        double eps_benson_phase2                        # Epsilon of Benson algorithm 

    void set_default_opt(opttype *opt)
    int vlp_init(csatype *csa, vlptype *vlp, opttype *opt)
    void vlp_free(vlptype *vlp)
    void sol_init(soltype *sol, vlptype *vlp, opttype *opt)
    void sol_free(soltype *sol)
    void set_input(csatype *csa, char *filename)

def par_indent(func):
    def func_wrappper(text):
        return("\n\t{}\n".format(func(text)))
    return func_wrappper

cdef class _cVlpProblem:
    """Internal Wrap Class for Problem structure"""
    cdef opttype* _opt 
    cdef vlptype* _vlp
    cdef lptype* _lps
    cdef csatype* _csa
    cdef char* c_filename


    @par_indent
    def warn(text):
        return warn(text)

    def __cinit__(self):
        self._opt = <opttype *>malloc(sizeof(opttype))
        self._vlp = <vlptype *>malloc(sizeof(vlptype))
        self._lps = <lptype *>malloc(sizeof (lptype))
        self._csa = <csatype *>malloc(sizeof(csatype))

    def __dealloc__(self):
        free(self._opt)
        free(self._vlp)
        free(self._lps)
        free(self._csa)

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
                self._opt.printfiles = val
            elif (attr == "log_file"):
                self._opt.logfile = val

    @property
    def options(self):
        return(self._opt[0])

    def from_file(self,filename):

        if not isinstance(filename,bytes):
            filename = filename.encode()

        basename, _ = splitext(filename)
        self.set_options({'filename':basename})
        set_input(self._csa,filename)
        if(vlp_init(self._csa,self._vlp,self._opt)):
            print("Error in reading")

    def toString(self):
        return("Rowns: {}, Columns: {},  Non-zero entries: {}, Non-zero objectives: {}".format(self._vlp.m, self._vlp.n, self._vlp.nz, self._vlp.nzobj))

    cdef print_vlp_address(self):
        print(<int>self._vlp)

cdef class _cVlpSolution:
    """Internal Wrap Class for Solution structure."""
    cdef soltype* _sol
    cdef poly_args* _image
    cdef int _pre_img
    cdef object argtype

    def __cinit__(self):
        self._sol = <soltype *>malloc(sizeof(soltype))
        self._image = <poly_args *>malloc(sizeof(poly_args))

    def __dealloc__(self):
        free(self._sol)
        free(self._image)

    def toString(self):
        return("Vertices Upper: {}. Vertices Lower: {}. Extreme dir Upper: {}, Extreme dir Lower: {}".format(self._sol.pp, self._sol.dd, self._sol.pp_dir, self._sol.dd_dir))

cdef _cVlpSolution _csolve(_cVlpProblem problem):
    """"Internal function to drive solving procedure. Basically, mimics bensolve main function."""
    elapsedTime = time.clock()
    solution = _cVlpSolution()
    solution._pre_img = problem._opt.solution
    sol_init(solution._sol,problem._vlp,problem._opt)

    if(solution._sol.status == VLP_INPUTERROR):
        print("Error in reading")
    lp_init(problem._vlp, problem._lps)
    if(problem._opt.bounded):
        phase2_init(solution._sol, problem._vlp)
    else:
        #Phase 0
        if(problem._opt.message_level >= 3):
            print("Starting Phase 0")
        phase0(solution._sol, problem._vlp, problem._opt, problem._lps)
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
            phase1_primal(solution._sol,problem._vlp,problem._opt, problem._lps)
        else:
            assert(problem._opt.alg_phase1 == DUAL_BENSON)
            if (problem._opt.message_level >= 3):
                print("Starting Phase 1 -- Dual Algorithm")
            phase1_dual(solution._sol,problem._vlp, problem._opt, problem._lps)
    #Phase 2
    if(problem._opt.alg_phase2 == PRIMAL_BENSON):
        if (problem._opt.message_level >= 3):
            print("Starting Phase 2 -- Primal Algorithm")
        phase2_primal(solution._sol, problem._vlp, problem._opt, problem._lps, solution._image)
        solution.argtype = "phase2 primal"
    else:
        if (problem._opt.message_level >=3):
            print("Starting Phase 2 -- Dual Algorithm")
        phase2_dual(solution._sol, problem._vlp, problem._opt, problem._lps, solution._image)
        solution.argtype = "phase2 dual"

    if (solution._sol.status == VLP_INFEASIBLE):
        print("VLP Infeasible")

    if (solution._sol.status == VLP_UNBOUNDED):
        if (problem._opt.bounded == 1):
            print("VLP is not bounded, re-run without bounded opt")
        else:
            print("LP in Phase 2 is not bounded, probably by innacuracy in phase 1")
    elapsedTime = (time.clock() - elapsedTime)*1000 #Time in ms
    if (problem._opt.logfile):
        logfile = problem._opt.filename.decode('UTF-8') + '.log'
        with open(logfile,'w') as logf:
            logf.write("BENPY a WRAPPER of BENSOLVE: VLP solver, {}\n".format(THISVERSION))

            lp_method_ph0 = "dual_primal_simplex (dual simplex, if not succesful, primal simplex)"
            if (problem._opt.lp_method_phase0 == PRIMAL_SIMPLEX):
                lp_method_ph0 = "primal_simplex"
            elif (problem._opt.lp_method_phase0 == DUAL_SIMPLEX):
                lp_method_ph0 = "dual_simplex"

            lp_method_ph1 = "auto"
            if (problem._opt.lp_method_phase1 == PRIMAL_SIMPLEX):
                lp_method_ph1 = "primal_simplex"
            elif (problem._opt.lp_method_phase1 == DUAL_SIMPLEX):
                lp_method_ph1 = "dual_simplex"
            elif (problem._opt.lp_method_phase1 == DUAL_PRIMAL_SIMPLEX):
                lp_method_ph1 = "dual_primal_simplex (dual simplex, if not succesful, primal simplex)"

            lp_method_ph2 = "auto"
            if (problem._opt.lp_method_phase1 == PRIMAL_SIMPLEX):
                lp_method_ph2 = "primal_simplex"
            elif (problem._opt.lp_method_phase1 == DUAL_SIMPLEX):
                lp_method_ph2 = "dual_simplex"
            elif (problem._opt.lp_method_phase1 == DUAL_PRIMAL_SIMPLEX):
                lp_method_ph2 = "dual_primal_simplex (dual simplex, if not succesful, primal simplex)"
                
            format_str = "short"
            if (problem._opt.format == FORMAT_AUTO):
                format_str = "auto"
            elif (problem._opt.format == FORMAT_LONG):
                format_str = "long"

            logf.write("Problem parameters\n");
            logf.write("  problem file:      {}\n".format(problem._opt.filename.decode()))
            logf.write("  problem rows:      {}\n".format(problem._vlp.m))
            logf.write("  problem columns:   {}\n".format(problem._vlp.n))
            logf.write("  matrix non-zeros:  {}\n".format(problem._vlp.nz))
            logf.write("  primal generators: {}\n".format(solution._sol.o))
            logf.write("  dual generators:   {}\n".format(solution._sol.p))
            logf.write("Options")
            logf.write("  bounded:            {}\n".format("yes (run phase 2 only)"  if problem._opt.bounded  else  "no (run phases 0 to 2)"))
            logf.write("  solution:           {}\n".format("off (no solution output)" if problem._opt.solution == PRE_IMG_OFF  else "on (solutions (pre-image) written to files)")) 
            logf.write("  format:             {}\n".format(format_str))
            logf.write("  lp_method_phase0:   {}\n".format(lp_method_ph0))
            logf.write("  lp_method_phase1:   {}\n".format(lp_method_ph1))
            logf.write("  lp_method_phase2:   {}\n".format(lp_method_ph2))
            logf.write("  message_level:      {}\n".format(problem._opt.message_level))
            logf.write("  lp_message_level:   {}\n".format(problem._opt.lp_message_level))
            logf.write("  alg_phase1:         {}\n".format( "primal"  if problem._opt.alg_phase1 == PRIMAL_BENSON  else  "dual"))
            logf.write("  alg_phase2:         {}\n".format( "primal"  if problem._opt.alg_phase2 == PRIMAL_BENSON  else  "dual"))
            logf.write("  eps_benson_phase1:  {}\n".format(problem._opt.eps_benson_phase1))
            logf.write("  eps_benson_phase2:  {}\n".format(problem._opt.eps_benson_phase2))
            logf.write("  eps_phase0:         {}\n".format(problem._opt.eps_phase0))
            logf.write("  eps_phase1:         {}\n".format(problem._opt.eps_phase1))
            logf.write("Computational results")
            logf.write("  CPU time (ms):      {:.4}\n".format(elapsedTime))
            logf.write("  # LPs:              {}\n".format(lp_get_num(problem._lps)))
            logf.write("Solution properties")
            logf.write("  # primal solution points:     {}\n".format(solution._sol.pp))
            logf.write("  # primal solution directions: {}\n".format(solution._sol.pp_dir))
            logf.write("  # dual solution points:       {}\n".format(solution._sol.dd))
            logf.write("  # dual solution directions:   {}\n".format(solution._sol.dd_dir))
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
    cdef size_t *vrtx, *nghbr 
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
    cdef size_t *fct, *vrtx
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
    """Internal function. Mimics poly_output original functionality, but instead calling poly__*2file functions, use their _poly_*2arr counterparts to get the data."""
    cdef polytope *primal
    cdef polytope *dual
    if (not swap):
        primal = &(s._image).primal
        dual = &(s._image).dual
    else:
        dual = &(s._image).primal
        primal = &(s._image).dual

    cdef size_t k

    for k in range(dual.cnt):
        if (IS_ELEM(dual.used,k)):
            ST_BT(dual.sltn,k)

    for k in range(primal.cnt):
        if (IS_ELEM(primal.used,k)):
            ST_BT(primal.sltn, k)

    cdef permutation prm,prm_dual
    poly__initialise_permutation (primal,&prm)
    poly__initialise_permutation (dual,&prm_dual)

    ls1_p, ls2_p = _poly__vrtx2arr(primal,&prm)
    adj_p = _poly__adj2arr(primal,&prm)
    ls1_d, ls2_d = _poly__vrtx2arr(dual,&prm_dual)
    adj_d = _poly__adj2arr(dual,&prm_dual)
    inc_p = _poly__inc2arr(primal,&prm,&prm_dual)
    inc_d = _poly__inc2arr(dual,&prm_dual,&prm)
    pre_p = None
    pre_d = None
    if s._pre_img:
        pre_p = _poly__primg2arr(primal,&prm)
        pre_d = _poly__primg2arr(dual,&prm_dual)
    else:
        warn("\nPre image was not saved, preimage value set to None. Include 'solution':True in problem options dictionary")

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

    def __init__(self, B=None, a=None, b=None, l=None, s=None, P=None, Y=None, Z=None, c=None, opt_dir=None, filename = None, options = None):
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
            file_out = open(name=filename,mode='w+t')
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

