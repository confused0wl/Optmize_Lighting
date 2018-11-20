import math
import statistics
from pyomo.environ import *



class Coordinate:
    def __init__(self, x, y, z=0):
        self.x = x
        self.y = y
        self.z = z

    def subtract(self, c1, c2):
        return Coordinate(c1.x - c2.x, c1.y - c2.y, c1.z - c2.z)

    def __str__(self):
        return "(" + str(self.x) + ", " + str(self.y) + ", " + str(self.z) + ")"

class LightSource:
    def __init__(self, k, x, y, z, angle):
        self.k = k
        self.location = Coordinate(x, y, z)
        self.angle = angle


class Cell:
    def __init__(self, c1, c2):
        # x1 y1 bottom left coordinates, x2 y2 upper right coordinates
        self.c1 = c1
        self.c2 = c2

    def get_mid_point(self):
        return Coordinate((self.c1.x+self.c2.x)/2, (self.c1.y+self.c2.y)/2)


class Surface:
    def __init__(self, m, n, width, length):
        # width = max x, length = max y
        self.length = length
        self.width = width
        self.m = m
        self.n = n
        self.grid = self.create_grid(m, n)


    def create_grid(self, m, n):
        is_classic = True
        x_increment = (1.0*self.width)/n
        y_increment = (1.0*self.length)/m
        current_y = 0.0
        z=0.0
        if is_classic:
            y_increment *= -1
            current_y = self.length
        rows = []
        for i in range(m): #for each row
            row = []
            current_x = 0.0
            for j in range(n): #for each column in the ith row
                lower_left = Coordinate(current_x, current_y)
                upper_right = Coordinate(current_x+ x_increment, current_y+y_increment)
                cell = Cell(lower_left, upper_right)
                mid_point = cell.get_mid_point()
                row.append(Coordinate(mid_point.x, mid_point.y, z))
                current_x += x_increment
            current_y += y_increment
            rows.append(row)
        # print(rows)
        return (rows)


    def calc_intensity(self, lights):
        total_intensity = [[0 for j in range(self.n)] for i in range(self.m)]
        # func = np.vectorize(intensity_function)
        for light in lights:
            location = [light.location.x, light.location.y, light.location.z]
            for i in range(len(self.grid)):
                row = self.grid[i]
                for j in range(len(row)):
                    point_coordinates = row[j]
                    point = [point_coordinates.x, point_coordinates.y, point_coordinates.z]
                    r = [location[0] - point[0], location[1] - point[1], location[2] - point[2]]
                    r2 = 0
                    for num in r:
                        r2 += num*num
                    cos_theta = abs(location[2])/sqrt(r2)
                    if value(cos_theta) > math.cos(light.angle):
                        cos_theta = 0
                    total_intensity[i][j]+= k*cos_theta/(r2)
        return total_intensity

def variance(matrix):
    flat_list = [value(item) for sublist in matrix for item in sublist]
    return statistics.variance(flat_list)


# def intensity_function(point_coordinates, k, light_coordinates):
#     location = np.array([light_coordinates.x, light_coordinates.y, light_coordinates.z])
#     point = np.array([point_coordinates.x, point_coordinates.y, point_coordinates.z])
#     r = location - point
#     r2 = np.multiply(r, r)
#
#     cos_theta = abs(location[2])/sqrt(np.sum(r2))
#     if cos_theta > light.angle:
#         cos_theta = 0
#     return k*cos_theta/np.sum(r2)


s = Surface(4,4,8,8)
model = AbstractModel()
k=3
# declare decision variables
model.x = Var(within=NonNegativeReals, bounds=(0,8), initialize=3)
model.y = Var(within=NonNegativeReals, bounds=(0,8), initialize=3)
model.z = Var(within=NonNegativeReals, bounds=(1,8), initialize=3)


model.lights = ([LightSource(k, model.x, model.y, model.z, math.acos(0.5))])
model.intensity_final = s.calc_intensity(model.lights)
# declare objective
def var(model):
    var_all = variance(model.intensity_final)
    return var_all
model.variance = Objective(rule = var, sense = minimize)


# declare constraints
#model.angle_constraint = Constraint(expr = model.angle <= np.arccos(0.5))
def range_intensity(model):
    for i in model.intensity_final:
        for j in i:
            if not 0.3 <j<1.0:
                return j == 0.5
    return j == j
# model.intrange = Constraint(rule = range_intensity)
#number of lights, light intensity range


# solve
instance = model.create_instance()
opt = SolverFactory('glpk')
opt.solve(instance)
#SolverFactory('glpk').solve(model).write()
