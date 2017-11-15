#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Thu May  4 15:35:50 2017
Construct Ecosystem system
@author: mbudinich
"""
# import cobra
import numpy as np
from scipy.sparse import lil_matrix, find
# %%


class VlpProblem:
    def __init__(self, B=None, a=None, b=None, l=None, s=None, P=None, Y=None, Z=None, c=None, opt_dir=None):
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

    def to_file(self, filename=None):  # VLP is 1 based, constraint numbering starts at 1!!
        def getlen(obj):
            return 0 if obj is None else len(obj)

        if filename is None:
            raise RuntimeError("No filename given")
        if hasattr(self, 'ub') and not hasattr(self, 's'):
            self.s = self.ub
        if hasattr(self, 'lb') and not hasattr(self, 'l'):
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
        (m, n) = self.B.shape
        (q, p) = self.P.shape
        if (n != p):
            raise RuntimeError('B and P must have same number of columns')

        [A_rows, A_cols, A_vals] = find(lil_matrix(self.B))
        k = len(A_rows)
        [P_rows, P_cols, P_vals] = find(lil_matrix(self.P))
        k1 = len(P_rows)
        kstr = ''
        if self.Y is not None and self.Y.shape[1] > 0:
            [K_rows, K_cols, K_vals] = find(lil_matrix(self.Y))
            k2 = len(K_rows)
            kstr = ' cone {} {}'.format(self.Y.shape[1], k2)
        elif self.Z is not None and self.Z.shape[1] > 0:
            [K_rows, K_cols, K_vals] = find(lil_matrix(self.Z))
            k2 = len(K_rows)
            kstr = ' dualcone {} {}'.format(self.Z.shape[1], k2)
        else:
            k2 = 0

        opt_dir_str = ''
        if self.opt_dir == 1:
            opt_dir_str = 'min'
        elif self.opt_dir == -1:
            opt_dir_str = 'max'
        else:
            raise RuntimeError(
                'Invalid value for opt_dir: use -1 or 1 for maximitation and minimization')

        try:
            file = open(filename, 'w')
        except OSError as e:
            print("OS error: {0}".format(e))
            raise
        # Write 'p', 'a', 'k' to file
        file.write("p vlp {} {} {} {} {} {}{}\n".format(
            opt_dir_str, m, n, k, q, k1, kstr))
        for i in list(range(k)):
            file.write("a {} {} {}\n".format(
                A_rows[i] + 1, A_cols[i] + 1, A_vals[i]))
        for i in list(range(k1)):
            file.write("o {} {} {}\n".format(
                P_rows[i] + 1, P_cols[i] + 1, P_vals[i]))
        for i in list(range(k2)):
            file.write("k {} {} {}\n".format(
                K_rows[i] + 1, K_cols[i] + 1, K_vals[i]))
        # duality parameter vector

        if self.c is not None:
            if(len(np.array(self.c).shape) != 1) or (len(self.c) != q):
                raise RuntimeError('c has wrong dimension')
            for i in range(q):
                file.write("k {} 0 {}\n".format(i + 1, self.c[i]))

        # Write row
        if (len(np.array(self.a).shape) > 1):
            raise RuntimeError('a has wrong dimension')
        if (len(np.array(self.b).shape) > 1):
            raise RuntimeError('b has wrong dimension')
        m1 = max(getlen(self.a), getlen(self.b))
        if self.a is None:
            aa = -np.inf * np.ones((m1, 1))
        else:
            aa = self.a
        if self.b is None:
            bb = np.inf * np.ones((m1, 1))
        else:
            bb = self.b

        for i in list(range(m1)):
            if aa[i] < bb[i]:
                ch = 2 * np.isfinite(aa[i]) + np.isfinite(bb[i])
                if ch == 0:
                    file.write('i {} f \n'.format(i + 1))
                elif ch == 1:
                    file.write('i {} u {}\n'.format(i + 1, bb[i]))
                elif ch == 2:
                    file.write('i {} l {}\n'.format(i + 1, aa[i]))
                elif ch == 3:
                    file.write('i {} d {} {}\n' .format(i + 1, aa[i], bb[i]))
                else:
                    raise RuntimeError("Bad ch switch for constrains bounds")
            elif aa[i] == bb[i] and np.isfinite(aa[i]):
                file.write('i %d s %g\n', i, aa[i])
            else:
                raise RuntimeError(
                    'Invalid constrsaints: a[{}]={}, b[{}]={}'.format(i + 1, aa[i], i, bb[i]))

        # Write cols
        if self.l is None:
            llb = -np.inf * np.ones((n, 1))
        else:
            llb = self.l

        if self.s is None:
            uub = np.inf * np.ones((n, 1))
        else:
            uub = self.s

        for j in range(n):
            if llb[j] < uub[j]:
                ch = 2 * np.isfinite(llb[j]) + np.isfinite(uub[j])
                if ch == 0:
                    file.write('j {} f \n'.format(j + 1))
                elif ch == 1:
                    file.write('j {} u {}\n'.format(j + 1, uub[j]))
                elif ch == 2:
                    file.write('j {} l {}\n'.format(j + 1, llb[j]))
                elif ch == 3:
                    file.write('j {} d {} {}\n' .format(j + 1, llb[j], uub[j]))
                else:
                    raise RuntimeError("Bad ch switch for variable bounds")
            elif llb[j] == uub[j] and np.isfinite(llb[j]):
                file.write('i %d s %g\n', j + 1, llb[j])
            else:
                raise RuntimeError('Invalid constrsaints: l[{}]={}, s[{}]={}'.format(
                    j + 1, llb[j], i, uub[j]))
        file.write('e ')
        file.close()
# %%


class EcosystemModel:

    from scipy.sparse import lil_matrix, block_diag, eye

    def __init__(self, model_array=None, metabolic_dict=None):
        """Instatiate the EcosystemModel object
        model_array is an array of cobra models to connect
        metabolic_dict is a dicctionary where its keys correspond to metabolites id's and their values to the name equivalence"""
        self.models = model_array
        self.metabolic_dict = metabolic_dict
        self._pooldict = None
        self.pool_ex_rxns = None
        self.pool_ex_mets = None
        self.Ssigma = None
        self.sysreactions = None
        self.sysmetabolites = None
        self.lb = None
        self.ub = None
        self.objectives = None

    def construct_ecosystem_pool(self):
        """Check all metabolites used in import/export exchanges and construct the pool compartment"""
        pooldict = dict()
        for model in self.models:
            for rxn_ex in model.exchanges:
                for met_ex in rxn_ex.metabolites:
                    met_name = self.metabolic_dict[met_ex.id]
                    if met_name not in pooldict:
                        pooldict[met_name] = [
                            (model, rxn_ex, rxn_ex.get_coefficient(met_ex.id))]
                    else:
                        pooldict[met_name].append(
                            (model, rxn_ex, rxn_ex.get_coefficient(met_ex.id)))
        self._pooldict = pooldict

    def populate_ecosystem_model(self):
        """Calculate the object attributes after pool construction"""
        self.pool_ex_rxns = ["EX_{}:pool".format(
            key) for key in self._pooldict.keys()]
        self.pool_ex_mets = ["{}:pool".format(
            key) for key in self._pooldict.keys()]
        self.sysreactions = ["{}:{}".format(
            r.id, model.id) for model in self.models for r in model.reactions]
        self.sysmetabolites = ["{}:{}".format(
            m.id, model.id) for model in self.models for m in model.metabolites]
        self.sysreactions.extend(self.pool_ex_rxns)
        self.sysmetabolites.extend(self.pool_ex_mets)
        array_form = [model.to_array_based_model() for model in self.models]
        self.Ssigma = block_diag([model.S for model in array_form])
        self.Ssigma = lil_matrix(block_diag(
            [self.Ssigma, -eye(len(self.pool_ex_rxns))]))
        for met in self._pooldict.keys():
            met_name = "{}:pool".format(met)
            met_idx = self.sysmetabolites.index(met_name)
            for model, reaction, coeff in self._pooldict[met]:
                rxn_name = "{}:{}".format(reaction.id, model.id)
                rxn_idx = self.sysreactions.index(rxn_name)
                self.Ssigma[met_idx, rxn_idx] = -coeff

    def add_comparment(self, model):
        """Utility function to add a new agent to models. Pretty ineficient, re-runs all the steps again for each addition"""
        self.__init__(self.model_array.add(model), self.metabolic_dict)
        self.construct_ecosystem_pool()
        self.populate_ecosystem_model()

    @staticmethod
    def get_common_mets(model_list):
        """Naive implementation of getting common exchange metabolites, using their id's"""
        common_mets = dict()
        for model in model_list:
            for rxn_ex in model.exchanges:
                for met_ex in rxn_ex.metabolites:
                    if met_ex.id not in common_mets:
                        common_mets[met_ex.id] = dict([(model, rxn_ex)])
                    else:
                        common_mets[met_ex.id][model] = rxn_ex
        return(common_mets)


# %%


# %%
