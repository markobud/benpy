import benpy
problem = benpy.vlpProblem(filename="ex01.vlp", options={
                           'message_level': 3, 'solution': True,
                           'logfile': False, 'alg_phase2': 'dual'})
sol = benpy.solve(problem)
