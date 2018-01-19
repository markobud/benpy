#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Thu May  4 15:35:50 2017
Construct Ecosystem system
@author: mbudinich
"""
from scipy.sparse import lil_matrix, block_diag, eye

class EcosystemModel:

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
