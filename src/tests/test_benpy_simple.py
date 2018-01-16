import benpy
problem = benpy.vlpProblem(filename="ex01.vlp", options={
                           'message_level': 3, 'solution': True, 'logfile': False})
sol = benpy.solve(problem)
