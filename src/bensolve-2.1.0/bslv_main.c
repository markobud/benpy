/*
This file is part of BENSOLVE - VLP solver

Copyright (C) 2014-2017 Andreas Löhne and Benjamin Weißing

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

#include <sys/time.h>	// for gettimeofday()
#include <string.h>
#include <stdlib.h>
#include <time.h>
#include <unistd.h>

#include "bslv_vlp.h"
#include "bslv_lp.h"
#include "bslv_lists.h"
#include "bslv_algs.h"


struct timeval t_start,t_end;


int main(int argc, char **argv)
{
	/*
	*  set options
	*/
	opttype _opt, *opt = &_opt;
	
	set_default_opt(opt);
	
	if (set_opt(opt, argc, argv))
	{
		printf("invalid problem input.\n");
		return 1;
	}

	if (opt->message_level >= 1)
		 printf(WELCOME, "version "THISVERSION, UMLAUT_OE, UMLAUT_SZ);

	/*
	 *  read problem from file 
	 */
	vlptype _vlp, *vlp = &_vlp;
	if (opt->message_level >= 1)
		 printf("loading ... \n");
	
	if (vlp_init(*(argv+1), vlp, opt)) 
	{	
		vlp_free(vlp);
		return 1;
	}
	
	if (opt->message_level >= 1) printf("done: %d rows, %d columns, %zd non-zero matrix coefficients\n", vlp->m, vlp->n, vlp->nz);

	// begin of computations - start timer
	gettimeofday(&t_start, NULL);
	
	/*
	 *  solve problem
	 */	
	soltype _sol, *sol = &_sol;
	
	if (sol_init(sol,vlp,opt))
	{
		vlp_free(vlp);
		sol_free(sol);	
		printf("exit caused by input error.\n");	
		return 1;
	}
	
	lp_init(vlp);
	
	if (opt->message_level == 1)
		 printf("running ... \n");
	
	if (alg(sol, vlp, opt) >= 0)
	{
		/*
		*  write info
		*/		
		double elapsedTime = (t_end.tv_sec - t_start.tv_sec) * 1000.0; // sec to ms
		elapsedTime += (t_end.tv_usec - t_start.tv_usec) / 1000.0; // us to ms

		write_log_file(vlp, sol, opt, elapsedTime, lp_get_num(0));
		display_info(opt, elapsedTime, lp_get_num(0));
	}
	
	lp_free(0);
	vlp_free(vlp);
	sol_free(sol);
	return 0;
}




