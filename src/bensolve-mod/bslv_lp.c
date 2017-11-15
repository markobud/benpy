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

#include <time.h>
#include <assert.h>
#include <unistd.h>
#include <stdlib.h>
#include <string.h>
#include "bslv_lp.h"

/*
double lp_time[1] = { 0 };
int lp_num[1] = { 0 };
glp_prob *lp[1];

// for inhomogeneous problem
int type[] = {GLP_DB,0,GLP_FR,0,0,0,0,0,GLP_LO,0,0,0,0,0,0,GLP_FX,0,GLP_UP};
// for homogeneous problem: change "double bounded" to "fixed"
int type_hom[] = {GLP_FX,0,GLP_FR,0,0,0,0,0,GLP_LO,0,0,0,0,0,0,GLP_FX,0,GLP_UP};

type('d'-'d')==GLP_DB
type('f'-'d')==GLP_FR
type('l'-'d')==GLP_LO
type('s'-'d')==GLP_FX
type('u'-'d')==GLP_UP

lp_idx extra_rows = 0;
lp_idx extra_cols = 0;
glp_smcp parm;
*/
const static int type[] = {GLP_DB,0,GLP_FR,0,0,0,0,0,GLP_LO,0,0,0,0,0,0,GLP_FX,0,GLP_UP};
const static int type_hom[] = {GLP_FX,0,GLP_FR,0,0,0,0,0,GLP_LO,0,0,0,0,0,0,GLP_FX,0,GLP_UP};

void lp_write (lptype *lpstr)
{
	glp_write_prob (lpstr->lp,0, "lp_solve_test_write");
	glp_write_sol (lpstr->lp, "lp_solve_test_sol_write");
}

double lp_write_sol(lptype *lpstr)
{
	return glp_write_sol(lpstr->lp,"tmp.sol");
}


void lp_init(const vlptype *vlp, lptype *lpstr)
{
	lpstr->lp_time =  0 ;
	lpstr->lp_num =  0;
	// for inhomogeneous problem
	memcpy(lpstr->type, type, sizeof(lpstr->type));
	// for homogeneous problem: change "double bounded" to "fixed"
	memcpy(lpstr->type_hom, type_hom, sizeof(lpstr->type_hom));
	lpstr->extra_rows = 0;
	lpstr->extra_cols = 0;
	glp_init_smcp(&lpstr->parm);
	lpstr->lp = glp_create_prob();
	glp_add_rows (lpstr->lp, vlp->m + vlp->q);
	glp_add_cols (lpstr->lp, vlp->n + vlp->q);

	//int f = glp_check_dup(glp_get_num_rows(lp), glp_get_num_cols(lp), (int) A->size, (int*) (A->idx1 - 1), (int*) (A->idx2 - 1));
	int f = 0;
	if (f == 0)
		glp_load_matrix(lpstr->lp, vlp->A_ext->size, (vlp->A_ext->idx1 - 1), (vlp->A_ext->idx2) - 1, vlp->A_ext->data - 1);
	else if (f > 0)
	{
		printf("Error: element A[%d,%d] in line %d is duplicate", vlp->A_ext->idx1[f], vlp->A_ext->idx2[f], f);
		exit(1);
	}
	else
	{
		printf("Error: indices of A[%d,%d] in line %d are out of range", vlp->A_ext->idx1[-f], vlp->A_ext->idx2[-f], -f);
		exit(1);
	}
}

void lp_update_extra_coeffs(lp_idx n_rows, lp_idx n_cols,lptype *lpstr)
{
	if (lpstr->extra_rows > 0)
	{
		int row_idx[lpstr->extra_rows + 1];
		for (lp_idx j = 0; j < lpstr->extra_rows; j++)
		{
			row_idx[j+1] = glp_get_num_rows(lpstr->lp) - lpstr->extra_rows + j + 1;
		}
		glp_del_rows(lpstr->lp, lpstr->extra_rows, row_idx);
	}
	lpstr->extra_rows = n_rows;
	if (n_rows > 0)
		glp_add_rows(lpstr->lp, n_rows);
	
	if (lpstr->extra_cols > 0)
	{
		int col_idx[lpstr->extra_cols + 1];
		for (lp_idx j = 0; j < lpstr->extra_cols; j++)
		{
			col_idx[j+1] = glp_get_num_cols(lpstr->lp) - lpstr->extra_cols + j + 1;
		}
		glp_del_cols(lpstr->lp, lpstr->extra_cols, col_idx);
	}
	lpstr->extra_cols = n_cols;
	if (n_cols > 0)
		glp_add_cols(lpstr->lp, n_cols);
	
	glp_std_basis(lpstr->lp); // compute a valid basis
}
/*
void lp_copy(size_t dest, size_t src)
{
	lp[dest] = glp_create_prob();
	glp_add_rows (lp[dest], glp_get_num_rows(lp[src]));
	glp_add_cols (lp[dest], glp_get_num_cols(lp[src]));
	glp_copy_prob(lp[dest], lp[src], GLP_OFF);
}
*/
void lp_set_rows (const boundlist *rows, lptype *lpstr)
{
	for(lp_idx k = 0; k < rows->size; k++)
		glp_set_row_bnds (lpstr->lp, rows->idx[k], lpstr->type[(int)(rows->type[k]-'d')], rows->lb[k], rows->ub[k]);
}

void lp_set_rows_hom (const boundlist *rows, lptype *lpstr)
{
	for(lp_idx k = 0; k < rows->size; k++)
		glp_set_row_bnds (lpstr->lp, rows->idx[k], lpstr->type_hom[(int)(rows->type[k]-'d')], 0.0, 0.0);
}

void lp_set_cols (const boundlist *cols, lptype *lpstr)
{
	for(lp_idx k = 0; k < cols->size; k++)	
		glp_set_col_bnds (lpstr->lp, cols->idx[k], lpstr->type[(int)(cols->type[k]-'d')], cols->lb[k], cols->ub[k]);
}

void lp_set_cols_hom (const boundlist *cols, lptype *lpstr)
{
	for(lp_idx k = 0; k < cols->size; k++)	
		glp_set_col_bnds (lpstr->lp, cols->idx[k], lpstr->type_hom[(int)(cols->type[k]-'d')], 0.0, 0.0);
}

void lp_set_mat_row (list1d *list, lp_idx ridx, lptype *lpstr)
{
	glp_set_mat_row(lpstr->lp, (int) ridx, (int) list->size, (int*) (list->idx - 1), list->data-1);
}

void lp_clear_obj_coeffs (lptype *lpstr)
{
	for(lp_idx k = 0; k <= glp_get_num_cols(lpstr->lp); k++)
		glp_set_obj_coef(lpstr->lp, k, 0);
}

void lp_set_obj_coeffs (const list1d *obj, lptype *lpstr)
{
	for(lp_idx k = 0; k < obj->size; k++)
		glp_set_obj_coef(lpstr->lp, obj->idx[k], obj->data[k]);
}

void lp_set_options(const opttype *opt, phase_type phase, lptype *lpstr)
{
	{
		alg_type flag;
		lp_method_type method;
		if (phase == PHASE0)
		{
			method = opt->lp_method_phase0;
			flag = PRIMAL_BENSON;
		}
		else if (phase == PHASE1_PRIMAL)
		{
			method = opt->lp_method_phase1;
			flag = PRIMAL_BENSON;
		}
		else if(phase == PHASE1_DUAL)
		{
			method = opt->lp_method_phase1;
			flag = DUAL_BENSON;
		}
		else if (phase == PHASE2_PRIMAL)
		{
			method = opt->lp_method_phase2;
			flag = PRIMAL_BENSON;
		}
		else
		{
			assert(phase == PHASE2_DUAL);
			method = opt->lp_method_phase2; 
			flag = DUAL_BENSON;
		}
		if (method == PRIMAL_SIMPLEX)
			lpstr->parm.meth = GLP_PRIMAL;
		else if (method == DUAL_SIMPLEX)
			lpstr->parm.meth = GLP_DUAL;
		else if (method == DUAL_PRIMAL_SIMPLEX)
			lpstr->parm.meth = GLP_DUALP;
		else
		{
			assert(method == LP_METHOD_AUTO);
			if (flag == PRIMAL_BENSON)
				lpstr->parm.meth = GLP_DUAL;
			else
			{
				assert(flag == DUAL_BENSON);
				lpstr->parm.meth = GLP_PRIMAL;
			}
		}
	}
	
	if (opt->lp_message_level == 0)
		lpstr->parm.msg_lev = GLP_MSG_OFF;
	else if (opt->lp_message_level == 1)
		lpstr->parm.msg_lev = GLP_MSG_ERR;
	else if (opt->lp_message_level == 2)
		lpstr->parm.msg_lev = GLP_MSG_ON;
	else
	{
		assert(opt->lp_message_level == 3);
		lpstr->parm.msg_lev = GLP_MSG_ALL;
	}	
}

lp_status_type lp_solve(lptype *lpstr)
{
	glp_simplex(lpstr->lp, &(lpstr->parm));
	if (glp_get_status(lpstr->lp) == GLP_UNDEF)
	{
		printf("LP solution is undefined, try again with standard basis\n");
		glp_std_basis(lpstr->lp);
		glp_simplex(lpstr->lp, &(lpstr->parm));
	}	
	int st = glp_get_status(lpstr->lp);
	int stp = glp_get_prim_stat(lpstr->lp);
	int std = glp_get_dual_stat(lpstr->lp);
	if (st != GLP_OPT)
	{
		if(lpstr->parm.msg_lev != GLP_MSG_OFF && lpstr->parm.msg_lev != GLP_MSG_ERR)
			printf("No optimal LP solution found: %s (%s, %s)\n",
		st==GLP_FEAS ? "solution is feasible" :
		st==GLP_INFEAS ? "solution is infeasible" :
		st==GLP_NOFEAS ? "LP has no feasible solution" :
		st==GLP_UNBND ? "LP is unbounded" :
		st==GLP_UNDEF ? "solution is undefined" : "unexpected solution status",
		stp==GLP_UNDEF ? "primal solution undefined" :
		stp==GLP_FEAS ? "primal solution feasible" :
		stp==GLP_INFEAS ? "primal solution infeasible" :
		stp==GLP_NOFEAS ? "no primal feasible solution exists" : "unexpected status",
		std==GLP_UNDEF ? "dual solution undefined" :
		std==GLP_FEAS ? "dual solution feasible" :
		std==GLP_INFEAS ? "dual solution infeasible" :
		std==GLP_NOFEAS ? "no dual feasible solution exists" : "unexpected status");

		if (glp_get_prim_stat
			(lpstr->lp)==GLP_NOFEAS)
				return LP_INFEASIBLE;
		if (glp_get_dual_stat(lpstr->lp)==GLP_NOFEAS)
			return LP_UNBOUNDED;
		else
			return LP_UNEXPECTED_STATUS;
	}
	lpstr->lp_num++;
	return LP_OPTIMAL;
}

void lp_primal_solution_rows(double *const x, lp_idx firstidx, lp_idx size, double sign, lptype *lpstr)
{
	if (firstidx + size - 1 > glp_get_num_rows(lpstr->lp))
	{
		printf("lp_primal_solution_rows: index out of bounds.\n");
		exit(1);
	}
	for (lp_idx k=0; k < size; k++)
		x[k] = sign*glp_get_row_prim (lpstr->lp, k + firstidx);
}

void lp_primal_solution_cols(double *const x, lp_idx firstidx, lp_idx size, double sign, lptype *lpstr)
{
	if (firstidx + size - 1 > glp_get_num_cols(lpstr->lp))
	{
		printf("lp_primal_solution_cols: index out of bounds.\n");
		exit(1);
	}
	for (lp_idx k=0; k < size; k++)
		x[k] = sign*glp_get_col_prim (lpstr->lp, k + firstidx);
}

void lp_dual_solution_rows(double *const u, lp_idx firstidx, lp_idx size, double sign, lptype *lpstr)
{
	if (firstidx + size - 1 > glp_get_num_rows(lpstr->lp))
	{
		printf("lp_dual_solution_rows: index out of bounds.\n");
		exit(1);
	}
	for (lp_idx k=0; k < size; k++)	
		u[k] = sign*glp_get_row_dual (lpstr->lp, k + firstidx);
}

void lp_dual_solution_cols(double *const u, lp_idx firstidx, lp_idx size, double sign, lptype *lpstr)
{
	if (firstidx + size - 1 > glp_get_num_cols(lpstr->lp))
	{
		printf("lp_dual_solution_cols: index out of bounds.\n");
		exit(1);
	}
	for (lp_idx k=0; k < size; k++)
		u[k] = sign*glp_get_col_dual (lpstr->lp, k + firstidx);
}

double lp_obj_val(lptype *lpstr)
{
	return glp_get_obj_val(lpstr->lp);
}

double lp_get_time (lptype *lpstr)
{
	return lpstr->lp_time;
}

int lp_get_num (lptype *lpstr)
{
	return lpstr->lp_num;
}

void lp_free (lptype *lpstr)
{
	glp_delete_prob(lpstr->lp);
	glp_free_env();
}


