matrix = require('3rd_party.matrix')

function solver(car,dt)
	local state = {}
	local dt = am.delta_time
	for i,component,dimension in car:iterateOverDoF() do
		state[i] = component[dimension]
	end
	local tol = 1e-2
	local A = {}
	local forceTable = {}
	local massMatrixTable = {}
	--Evaluate mass vector
	
	for itteration = 1,50 do
		--Evaluate Force vector
		for i,component,dimension in car:iterateOverDoF() do
			print(string.rep("\n",3)..component.name.." "..dimension)
			forceTable[i] = component:netForce(dimension)
			massMatrixTable[i] = {}
			for j,_,_ in car:iterateOverDoF() do
				massMatrixTable[i][j] = 0
			end
			print(component.inertia[dimension])
			massMatrixTable[i][i] = component.inertia[dimension]
		end
		--Apply constraints/BCs
		for componentDimensionIndex,component,dimension in car:iterateOverDoF() do
			forceTable,massMatrixTable = car:applyConstraints(componentDimensionIndex,component,dimension,forceTable,massMatrixTable)
		end
		--Resolve frictional forces
		for i=1,#forceTable do
			if math.sign(forceTable[i][1]) ~= math.sign(forceTable[i][2]) and math.abs(forceTable[i][1]) < math.abs(forceTable[i][2]) then
				forceTable[i] = 0
			else
				forceTable[i] = forceTable[i][1] + forceTable[i][2]
			end
		end
		F = matrix(forceTable)
		M = matrix(massMatrixTable)
		iterativeTablePrint(forceTable)
		print("F=",F)
		iterativeTablePrint(massMatrixTable)
		print("M=",M)
		--Solve matrix-vector equationlocal 
		A[itteration] = matrix.div(F:transpose(),M:transpose())
		
		--Find error
		err = V[itteration] - (V[old] + dt * A[itteration + 1])
		if err < tol then break end
	end
	--Store result
	for i,component,dimension in car:iterateOverDoF() do
		component.state[dimension][2] = A[#A][i]
		component.state[dimension][1] = component.state[dimension][1] + A[#A][i]*dt
		component.state[dimension][0] = component.state[dimension][0] + component.state[dimension][1]
	end
end
	