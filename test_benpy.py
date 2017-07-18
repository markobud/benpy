import benpy

problem = benpy.vlpProblem()
problem.filename = "ex01.vlp"
problem.options={'message_level':3}
sol = benpy.solve(problem)

problem2 = benpy.vlpProblem()
problem2.filename = "ex01copy.vlp"
problem2.options = problem.options
sol2 = benpy.solve(problem2)
