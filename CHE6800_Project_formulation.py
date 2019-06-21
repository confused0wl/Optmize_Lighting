import numpy as np
import matplotlib.pyplot as plt

grd = 6
N = 3
Xdim,Ydim = 8,8
def get_Coords(grd,Xdim,Ydim):
    #this returns a coordinate grid given grid density and X and Y dimensions
    xlb = Xdim*(1/grd)*(0.5)
    xub = Xdim-xlb
    ylb = xlb
    yub = xub
    Gridx = np.zeros((grd,grd))
    Gridy = np.zeros((grd,grd))
    Gridx[:,:]=np.linspace(xlb,xub,grd)
    Gridy[:,:]=np.linspace(ylb,yub,grd)
    Gridy = np.transpose(Gridy)
    Coords = np.zeros((grd,grd,2))
    Coords[:,:,0] = Gridx
    Coords[:,:,1] = Gridy
    return Coords

Pt = [6,6,8]
Coords = get_Coords(grd,Xdim,Ydim)

def get_Imatl(Pt,Coords):
    # this returns the light intensity map for the given Coordinate grid and Pt
    I_mat = np.zeros((Coords.shape[0],Coords.shape[1]))
    I_mat_sum = np.zeros((Coords.shape[0],Coords.shape[1]))
    for i in range(Coords.shape[0]):
        for j in range(Coords.shape[1]):
            Rij = np.sqrt((Coords[i,j,0]-Pt[0])**2 +(Coords[i,j,1]-Pt[1])**2+(Pt[2])**2)
            cosAij= (Pt[2])/Rij
            cosAij = 1
            I_mat[i,j] = (1/Rij**2)*cosAij
    return I_mat


I_mat = get_Imatl(Pt,Coords)


I_mat_sum = np.zeros((grd,grd))
print(np.var(I_mat))
plt.contourf(I_mat)
#print(I_mat)
#print(Coords)
