using JuMP, Ipopt

 # Creating the Model using JuMP
m = JuMP.Model( solver=Ipopt.IpoptSolver() )

# No. of point sources
P = 10

# lets specify no. of grid points. N is the no. of x grid point. M is the no. of y grid points.
N = 10;
M = 10;

# So we have N*M grid
L = N*M;

# Constant of proportinality for Lamberts Cosine Law
C=100


# Lets specify the size of the room
Xdim = 100;
Ydim = 100;
Zdim = 10;

# Lets specify the variables

# Control variable
Imin =0.02

# Dummy Variables
@variable(m,I_avg>=0)
@variable(m,f>=0)
@variable(m,I[1:L]>=Imin)



# State Variables
@variable(m, x[1:P]>=0)
@variable(m, y[1:P]>=0)
@variable(m, z[1:P]>=1)

# Dimensioning Constraint
@constraint(m, con[i in 1:P], 0<=x[i]<=Xdim)
@constraint(m, don[i in 1:P], 0<=y[i]<=Ydim)
@constraint(m, ron[i in 1:P], 0<=z[i]<=Zdim)


# Initializing xmatrix
xmatrix    = zeros(N,1)

# Lets get all the x-coordinates
count = 0;
for i = 1:N
  xmatrix[i] = Xdim*(1/N)*(0.5 + count)
  count = count+1;
end

# println((xmatrix))

# Initializing ymatrix
ymatrix    = zeros(M,1)

# Lets get all the y-coordinates
count = 0;
for i = 1:M
  ymatrix[i] = Ydim*(1/N)*(0.5 + count)
  count = count+1;
end

# println((ymatrix))

# Now lets get all the combinations of coordinates for our plane of interest
using Iterators
arr = Any[]
       for p in product(xmatrix,ymatrix)
                  push!(arr,[y for y in p])
       end
coordinate_matrix = hcat(arr)

# Non linear constraint for calculating intensity using Lambert's Cosine law and allocating it to the dummy variable I
for l = 1:L
  @NLconstraint(m, sum((C*z[k]/((coordinate_matrix[l][1]-x[k])^2 + (coordinate_matrix[l][2]-y[k])^2 + z[k]^2)^1.5 ) for k = 1:P ) == I[l] )
end

# Calculating average intensity across the plane and assigning it to dummy variable I_avg
@NLconstraint(m, (sum(I[j] for j=1:L)/L) == I_avg)

# Calculating variance and assigning it to dummy variable f
@NLconstraint(m, sum((I[i]- I_avg)^2/L for i = 1:L) == f)

# Minimizing Objective
@NLobjective(m, Min, f)

# Distance Constraint between consecutive lights
for j = 1:P-1
    for i = j+1:P
        @constraint(m, x[i] >=  x[j] + 0.5 )
    end
end

for j = 1:P-1
    for i = j+1:P
        @constraint(m, y[i] >= y[j] + 0.5)
    end
end


# Lets set the initial values for x,y,z coordinates of light sources
count = 0
for i = 1:P
  setvalue(x[i], count)
  count = count + 6
end

count = 0
for i = 1:P
  setvalue(y[i], count)
  count = count + 6
end

count = 0
for i = 1:P
  setvalue(z[i], count)
  count = count + 1
end

status = solve(m)

println("got ", getobjectivevalue(m), " at ", [getvalue(x),getvalue(y),getvalue(z),getvalue(I)])

writecsv("Objective.csv", float(getobjectivevalue(m)))
writecsv("xvalues.csv", float(getvalue(x)))
writecsv("yvalues.csv", float(getvalue(y)))
writecsv("zvalues.csv", float(getvalue(z)))
writecsv("Ivalues.csv", float(getvalue(I)))
