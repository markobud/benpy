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
    VLP_NOSTATUS, VLP_INFEASIBLE, VLP_UNBOUNDED, VLP_NOVERTEX, VLP_OPTIMAL, VLP_INPUTERROR,
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

# Import list types from bslv_lists.pxd
from pxd.bslv_lists cimport list1d, list2d, boundlist

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

    def __dealloc__(self):
        free(self._opt)
        free(self._vlp)

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

    def toString(self):
        return("Rowns: {}, Columns: {},  Non-zero entries: {}, Non-zero objectives: {}".format(self._vlp.m, self._vlp.n, self._vlp.nz, self._vlp.nzobj))

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

    def __dealloc__(self):
        free(self._sol)

    def toString(self):
        return("Vertices Upper: {}. Vertices Lower: {}. Extreme dir Upper: {}, Extreme dir Lower: {}".format(self._sol.pp, self._sol.dd, self._sol.pp_dir, self._sol.dd_dir))

cdef _cVlpSolution _csolve(_cVlpProblem problem):
    """"Internal function to drive solving procedure. Basically, mimics bensolve main function."""
    elapsedTime = time.process_time()
    solution = _cVlpSolution()
    solution._pre_img = problem._opt.solution
    sol_init(solution._sol,problem._vlp,problem._opt)

    if(solution._sol.status == VLP_INPUTERROR):
        print("Error in reading")
    lp_init(problem._vlp)
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

