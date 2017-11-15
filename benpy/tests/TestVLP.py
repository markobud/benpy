#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Wed May 31 15:45:22 2017

@author: mbudinich
"""

# Example: MOLP with 2 objectives, simplest example

# min [x1 - x2; x1 + x2]
#
# 6 <= 2*x1 +   x2
# 6 <=   x1 + 2*x2
#
# x1 >= 0
# x2 >= 0

import numpy as np
from benpy import solve as bensolve, vlpProblem
# %%
vlp = vlpProblem()

vlp.B = np.matrix([[2, 1], [1, 2]])    # coefficient matrix
vlp.a = [6, 6]        # lower bounds
vlp.P = np.matrix([[1, -1], [1, 1]])  # objective matrix
vlp.l = [0, 0]        # lower variable bounds

vlp.default_options()

vlp.to_string()

vlp.to_file('test01.vlp')

sol = bensolve(vlp)
