matrix = require('3rd_party.matrix')

function carSolver(car,dt)
	--Create state vector
	state = {}
	local state = {}
	for index, component, dimension in car:iterateOverDoF() do
		for j=0,1 do
			state[2*index+j-1] = {component.state[dimension][j]}
		end
	end
	state = matrix(state)
	k1 = stateDeriv(car,state)
	k2 = stateDeriv(car,state+k1*dt/2)
	k3 = stateDeriv(car,state+k2*dt/2)
	k4 = stateDeriv(car,state+k3*dt)	
	local newState = state + dt * (k1+2*k2+2*k3+k4) / 6
	assignState(car,newState)
	return dt
end




function assignState(car,stateVector)
	for index, component, dimension in car:iterateOverDoF() do
		for j=0,1 do
			 component.state[dimension][j] = stateVector[2*index+j-1][1]
		end
	end
end

function stateDeriv(car, state)
	assignState(car, state)
	local massMatrixTable = {}
	local forceTable = {}
	--Assemble mass matrix
	for i,component in car:iterateOverComponents() do
		if type(component.recalc) == "function" then
			component:recalc()
		end
	end
	for i,component,dimension in car:iterateOverDoF() do
		massMatrixTable[2*i-1] = {}
		massMatrixTable[2*i] = {}
		for j,_,_ in car:iterateOverDoF() do
			massMatrixTable[2*i-1][j*2-1] = 0
			massMatrixTable[2*i-1][j*2] = 0
			massMatrixTable[2*i][j*2-1] = 0
			massMatrixTable[2*i][j*2] = 0
		end
		massMatrixTable[2*i][2*i] = component.inertia[dimension]
		massMatrixTable[2*i-1][2*i-1] = 1
	end
	--Assemble force matrix
	for i,component,dimension in car:iterateOverDoF() do
		forceTable[2*i] = component:netForce(dimension)
		forceTable[2*i-1] = {state[2*i][1], 0}
	end
	--Resolve constraints
	forceTable,massMatrixTable = car:applyConstraints(componentDimensionIndex,component,dimension,forceTable,massMatrixTable)
	--Resolve frictional forces
	for i=1,#forceTable do
		if math.abs(forceTable[i][1]) < math.abs(forceTable[i][2]) then
			forceTable[i] = {0}
		else
			forceTable[i] = {(forceTable[i][1] + forceTable[i][2]) or 0}
		end
	end
	local F = matrix(forceTable)
	local M = matrix(massMatrixTable)
		--Solve matrix-vector equationlocal 
	local A = matrix.div(F:transpose(),M:transpose())
	return A:transpose()
end