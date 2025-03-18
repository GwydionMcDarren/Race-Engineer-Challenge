--Helper functions

function linearInterpolate(x0,x1,y0,y1,xi)
	z = 2*((xi-x0)/(x1-x0))-1
	yi = y0*(1-z)/2 + y1*(1+z)/2
	return yi
end