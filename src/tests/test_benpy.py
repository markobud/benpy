import benpy

problem = benpy.vlpProblem()
problem.filename = "ex01.vlp"
problem.options = {'message_level': 3, 'alg_phase2': 'dual', 'solution': True}
sol = benpy.solve(problem)
print(sol)

problem2 = benpy.vlpProblem()
problem2.filename = "ex02.vlp"
problem2.options = problem.options
sol2 = benpy.solve(problem2)
print(sol2)
