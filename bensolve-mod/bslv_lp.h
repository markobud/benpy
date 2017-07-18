/*
This file is part of BENSOLVE - VLP solver

Copyright (C) 2014-2015 Andreas Löhne and Benjamin Weißing
Copyright (C) 2017 Marko Budinich

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program (see the reference manual). If not,
see <http://www.gnu.org/licenses/>
*/

#ifndef BSLV_LP_H
#define BSLV_LP_H

#include <glpk.h>
#include "bslv_main.h"
#include "bslv_lists.h"
#include "bslv_vlp.h"

typedef struct { ;
    double lp_time;
    int lp_num;
    glp_prob *lp;

// for inhomogeneous problem
    int type[18];
// for homogeneous problem: change "double bounded" to "fixed"
    int type_hom[18];
    /*
    type('d'-'d')==GLP_DB
    type('f'-'d')==GLP_FR
    type('l'-'d')==GLP_LO
    type('s'-'d')==GLP_FX
    type('u'-'d')==GLP_UP
    */

    lp_idx extra_rows;
    lp_idx extra_cols;
    glp_smcp parm;

} lptype;


//void lp_init_struct(lptype *lpstr);
void lp_write (lptype *lpstr);
double lp_write_sol(lptype *lpstr);

// initialize lp
void lp_init(const vlptype *vlp, lptype *lpstr);

/*
 - for nonapprearing coefficients in obj and A, zero is assumed
 - for non-appearing rows, GLPK standard type 'f' is assumed
 - for non-appearing colums, GLPK standard type 's' is assumed

 - obj index range: 0 ... ncols, where 0 stands for a 'shift'
 - A index range: (1,1) ... (nrows,ncols)
 - rows index range: 1 ... nrows
 - cols index range: 1 ... ncols
*/

// set lp options
void lp_set_options(const opttype *opt, phase_type phase, lptype *lpstr);

// create a copy lp[dest]] of lp[src]
void lp_copy(size_t dest, size_t src, lptype *lpstr);

// delete extra rows and set num new extra rows
void lp_update_extra_coeffs (lp_idx n_rows, lp_idx n_cols, lptype *lpstr);

// set (replace) row bounds
void lp_set_rows (boundlist const *rows, lptype *lpstr);

// set (replace) row bounds of homogeneous problem
void lp_set_rows_hom (boundlist const *rows, lptype *lpstr);

// set (replace) column bounds
void lp_set_cols (boundlist const *cols, lptype *lpstr);

// set (replace) column bounds of homogeneous problem
void lp_set_cols_hom (boundlist const *cols, lptype *lpstr);

// set (replace) constraint coefficients
int lp_set_mat (list2d const *A, lptype *lpstr);

// set (replace) constraint coefficients row
void lp_set_mat_row (list1d *list, lp_idx ridx, lptype *lpstr);

// set all objective coefficients to zero
void lp_clear_obj_coeffs (lptype *lpstr);

// set (replace) (a subset of) objective coefficients
void lp_set_obj_coeffs (list1d const *list, lptype *lpstr);

// solve problem, return
lp_status_type lp_solve(lptype *lpstr);

// retrieve solutions, x and v need to be allocated before functions are called */
void lp_primal_solution_rows(double *const x, lp_idx firstidx, lp_idx size, double sign, lptype *lpstr);
void lp_primal_solution_cols(double *const x, lp_idx firstidx, lp_idx size, double sign, lptype *lpstr);
void lp_dual_solution_rows(double *const u, lp_idx firstidx, lp_idx size, double sign, lptype *lpstr);
void lp_dual_solution_cols(double *const u, lp_idx firstidx, lp_idx size, double sign, lptype *lpstr);

// return (optimal) objective value
double lp_obj_val(lptype *lpstr);

// return CPU time of lp solver in seconds
double lp_get_time (lptype *lpstr);

// return number of LPs (type i) solved
int lp_get_num (lptype *lpstr);

void lp_free(lptype *lpstr);

#endif
