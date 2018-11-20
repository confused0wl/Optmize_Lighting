#using Convex Optimization
# For a N*M grid
N = 3;
M = 3;

# Specify dimensions of the room
Xdim = 6;
Ydim = 6;
Zdim = 6;
# # 4x1 vector variable
# x = Variable(N)
# # 4x1 vector variable
# y = Variable(M)
#
# # Writing constraints
# constraints = [x[1]+x[2] == 5, x[3] <= x[2]]
# using JuMP, GLPK
# const MOI = JuMP.MathOptInterface
#
# solver = GLPK.Optimizer
# using JuMP
using JuMP, NLopt
# m = Model(with_optimizer(solver))
# m = Model()
# m = Model(with_optimizer(Gurobi.Optimizer))
# m = Model(solver=GurobiSolver(Presolve=0))
m = Model(solver=NLoptSolver(algorithm=:LD_MMA))

# Representing x and y in matrix forms
# @variable(m, 0 <= x[1:N, 1:M] <= Xdim, Int)
# @variable(m, 0 <= y[1:M, 1:N] <= Ydim, Int)
# @variable(m, z[1]<=Zdim)

@variable(m, x[1:N]>=0)
@variable(m, y[1:M]>=0)
@variable(m, z[1]>=0)

@constraint(m, con[i in 1:N], 2<=x[i]<=Xdim)
@constraint(m, don[i in 1:M], 2.5<=y[i]<=Ydim)
@constraint(m, 1<=z[1]<=Zdim)

# Distance Constraint
# @NLconstraint(m, mon[i in 1:M], sqrt(x[i]^2 + y[i]^2 + z[1]^2) >= 3)
for j = 1:N
    for i = 1:M
        @NLconstraint(m, sqrt(x[j]^2 + y[i]^2 + z[1]^2) >= 3)
    end
end

# @NLconstraint(m, fon[i in 1:M], sqrt( y[i]^2 + z[1]^2) >= 3) # base
# @NLconstraint(m, ron[i in 1:M], sqrt(x[i]^2 + y[i]^2 + z[1]^2) >= 3) # hyp
# @NLconstraint(m, ton[i in 1:N], ron[j in 1:M],  sqrt(y[j]^2 + z[1]^2)/ sqrt(x[i]^2 + y[j]^2 + z[1]^2) >= 0.5253219888177297)

# Angle constraints of being greater than 45 degrees
for j = 1:N
    for i = 1:M
        @NLconstraint(m, sqrt( y[i]^2 + z[1]^2)/ sqrt(x[j]^2 + y[i]^2 + z[1]^2) <= 0.5253219888177297)
    end
end

# Now lets find the intensity at all grid points
C = 1;

# Constraining the intensity at grid points between the farthest point source intensity found in trial and a random no.

for i = 1:N
  for j = 1:M
    @NLconstraint(m, 0.0114541 <= C*sqrt( y[i]^2 + z[1]^2)/ (sqrt(x[j]^2 + y[i]^2 + z[1]^2))^3 <= 0.5253219888177297)
  end
end

# Objective to maximize the sum of intensities on the plane of interest
for i = 1:N
  for j = 1:M
    @NLobjective(m, Max, sum(C*sqrt( y[i]^2 + z[1]^2)/ (sqrt(x[j]^2 + y[i]^2 + z[1]^2) )^3 for i in 1:N for j in 1:M))
  end
end

# Lets set the initial values
for i = 1:N
  setvalue(x[i], 0)
end

for i = 1:M
  setvalue(y[i], 0)
end

setvalue(z[1], 1)


# Print the model to check correctness
# print(m)

# Solve with Gurobi
# JuMP.optimize!(m)
# optimize(m)
status = solve(m)

# Solution
println("got ", getobjectivevalue(m))
println("got ", getobjectivevalue(m), " at ", [getvalue(x[1]),getvalue(x[2]),getvalue(x[3]),getvalue(y[1]),getvalue(y[2]),getvalue(y[3]),getvalue(z[1])])
# println("Objective value: ", JuMP.objective_value(m))
# println("x = ", JuMP.value(x))
# println("y = ", JuMP.value(y))

#     @objective(m, Max, sum(
#       3*(y["R",  3, i] + y["C",  3, i])
#     + 1*(y["R",  4, i] + y["C",  4, i])
#     + 1*(y["R",  5, i] + y["C",  5, i])
#     - 3*(y["R", -3, i] + y["C", -3, i])
#     - 1*(y["R", -4, i] + y["C", -4, i])
#     - 1*(y["R", -5, i] + y["C", -5, i]) for i in 1:5))
#
# Iav = sum(I)/(N*M);
#
# # Lets get the variance matrix now
#
# # Initializing variance matrix
# var   = zeros(N,M)
#
# # Calculate the var at grid points
# for i = 1:N
#   for j = 1:M
#     var[i,j] = (I[i,j] - Iav)^2/Iav;
#   end
# end
