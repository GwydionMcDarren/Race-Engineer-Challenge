matrix = require('3rd_party.matrix')

function solver(car, dt)
	--if am.frame_time%(15/60) > (1/60) then return nil end
	local state = {}
	for i,component,dimension in car:iterateOverDoF() do
		state[i] = component[dimension]
	end
	local tol = 1e-4
	local A = {}
	local forceTable = {}
	local massMatrixTable = {}
	local V = {}
	V[0] = {}
	local X = {}
	X[0] = {}

	for index,component in car:iterateOverComponents() do
		component.old_state = {}
	end
	for index,component,dimension in car:iterateOverDoF() do
		V[0][index] = {}
		V[0][index][1] = component.state[dimension][1] or 0
		X[0][index] = {}
		X[0][index][1] = component.state[dimension][0] or 0
		component.old_state[dimension] = {}
		component.old_state[dimension][2] = component.state[dimension][2]
		component.old_state[dimension][1] = component.state[dimension][1]
		component.old_state[dimension][0] = component.state[dimension][0]
	end
	V[0] = matrix.transpose(matrix(V[0]))
	X[0] = matrix.transpose(matrix(X[0]))
	--Evaluate mass vector
	
	for itteration = 1,4 do
		old = itteration - 1
		--Evaluate Force vector
		for i,component,dimension in car:iterateOverDoF() do
			forceTable[i] = component:netForce(dimension)
			massMatrixTable[i] = {}
			for j,_,_ in car:iterateOverDoF() do
				massMatrixTable[i][j] = 0
			end
			massMatrixTable[i][i] = component.inertia[dimension]
		end
		--Apply constraints/BCs
		for componentDimensionIndex,component,dimension in car:iterateOverDoF() do
			forceTable,massMatrixTable = car:applyConstraints(componentDimensionIndex,component,dimension,forceTable,massMatrixTable)
		end
		--Resolve frictional forces
		for i=1,#forceTable do
			if false then-- math.sign(forceTable[i][1]) ~= math.sign(forceTable[i][2]) and math.abs(forceTable[i][1]) < math.abs(forceTable[i][2]) then
				forceTable[i] = {0}
			else
				forceTable[i] = {(forceTable[i][1] + forceTable[i][2]) or 0}
			end
		end
		F = matrix(forceTable)
		print("F=",F)
		M = matrix(massMatrixTable)
		--Solve matrix-vector equationlocal 
		A[itteration] = matrix.div(F:transpose(),M:transpose())
		V[itteration] = V[0] + dt * A[itteration]
		X[itteration] = X[0] + dt * V[itteration]
		print("X=",X[#X])
		--Find error
		err = matrixRMS(X[itteration] - X[itteration-1])
		print("ERROR=",string.format("%.2e",err),"ITTERATION=",itteration)
	--Store result
		for i,component,dimension in car:iterateOverDoF() do
			component.state[dimension][2] = A[#A][1][i]
			component.state[dimension][1] = component.old_state[dimension][1] + (A[#A][1][i])*dt
			component.state[dimension][0] = component.old_state[dimension][0] + component.state[dimension][1]*dt
		end
		if err < tol then break end
		break
		--if itteration == 5 then error("Test: break on itteration 5") end
	end
	return dt
end
	