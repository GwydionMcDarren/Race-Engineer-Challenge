
matrix = require '3rd_party.matrix'
function timeStepSolver(car,dt)
	--Find number of degrees of freedom
	local dof = 0
	for i=1,#car.components do
		dof = dof + (car.components[i].numCoords or 1)
	end
	--Initialise global matrix vector equation
	--Assemble force vector
	local F, Ff = {}, {}
	for i,component in ipairs(car.components) do
		F[i], Ff[i] = {}, {}
		F[i][1], Ff[i][1] = component:netForce(car)
	end
	--Assemble basic mass vector
	local M = {}
	for i,component in ipairs(car.components) do
		M[i] = {}
		for j=1,#car.components do
			M[i][j] = 0
		end
		M[i][i] = component.inertia
	end
	--Apply constraints
	for i,component in ipairs(car.components) do
		for j=1,#car.components do
			local constraint = component.constraints[j]
			if type(constraint) == "table" then
				if constraint[1] == "fixed" then
					local R = constraint[2]
					for k=1,#car.components do
						M[j][k] = M[j][k]+M[i][k]*R
						M[i][k] = 0
					end
					M[i][i] = R
					M[i][j] = -1
					F[j][1] = F[j][1] + F[i][1]/R
					F[i][1] = 0
					Ff[j][1] = Ff[j][1] + Ff[i][1]/R
					Ff[i][1] = 0
				elseif constraint[1] == "stick-slip" then
					local R = constraint[2]
					local sumInertia = 0
					local speedDifference = component.coords.x[1] * R - car.components[j].coords.x[1]
					local maxAdhesionForce = component.parameters.normalForce * component.parameters.maxFrictionCoef * math.sign(speedDifference)
					for k=1,#car.components do
						sumInertia = sumInertia + M[i][k]
					end
					--print(i.." "..j.." "..F[i][1]+Ff[i][1].." "..maxAdhesionForce)
					if math.abs(F[i][1]+Ff[i][1])>math.abs(maxAdhesionForce) then
						constraint[3] = "slip"
						print(i.." slip")
					elseif constraint[3] == "slip" and math.abs(speedDifference) <=0.1 then
						constraint[3] = "stick"
						print(i.." stick")
						car.components[j].coords.x[1] = component.coords.x[1]*R
					end
					if constraint[3] == "stick" then
						for k=1,#car.components do
							M[j][k] = M[j][k]+M[i][k]*R
							M[i][k] = 0
						end
					M[i][i] = R
					M[i][j] = -1
					F[j][1] = F[j][1] + F[i][1]/R
					F[i][1] = 0
					Ff[j][1] = Ff[j][1] + Ff[i][1]/R
					Ff[i][1] = 0
					else
						Ff[i][1] = Ff[i][1] - maxAdhesionForce
						Ff[j][1] = Ff[j][1] + maxAdhesionForce/R
					end
				end
			end
		end
	end
	for i=1,#car.components do
		if math.sign(Ff[i][1]) * math.sign(F[i][1]) == -1 and math.abs(Ff[i][1]) >= math.abs(F[i][1]) and car.components[i].coords.x[1] == 0 then
			F[i][1] = 0
		else
			F[i][1] = F[i][1] + Ff[i][1]
		end
	end
	M = matrix(M)
	F = matrix(F)
	if false then
		print("\nM_old:")
		print(M_old)
		print("\nF_old:")
		print(F_old)
		print("\nA:")
		print(A)
		print("\nM:")
		print(M)
		print("\nF:")
		print(F)
		print(M+M_old)
	end
	local dt = am.delta_time --Check what this is meant to be
	local A = matrix.div(F:transpose(),M:transpose())
	for i,component in ipairs(car.components) do
		component.coords.x[2] = A[1][i]
			--print("\n"..(component.coords.x[1] + (component.coords.x[2] * dt)).." ->Projected speed of "..component.name)
			--print(component.coords.x[1].." ->Current speed of "..component.name.."\n")
		if math.sign(component.coords.x[1] + (component.coords.x[2] * 2 * dt)) ~= math.sign(component.coords.x[1]) and math.sign(component.coords.x[1]) ~= 0 and math.sign(component.coords.x[1] + (component.coords.x[2] * dt))~=0 then
			--print("Zero crossing detected!\n\n")
			component.coords.x[2] = 0
			component.coords.x[1] = 0
			--if component.parameters.axleTargets ~= nil then
			--	for i,axle in ipairs(component.parameters.axleTargets) do
			--		car.components[axle].x[2] = 0
			--		car.components[axle].x[1] = 0
			--	end
			--end
		else
			component.coords.x[1] = component.coords.x[1] + (component.coords.x[2] * dt)
		end
		component.coords.x[0] = component.coords.x[0] + (component.coords.x[1] * dt)
	end
	for i,component in ipairs(car.components) do
		component:update(car)
	end	
	if false then
		print("\nA:")
		print(A)
		print("\nGV:")
		print(GV)
	end
end

require "vehicle_component"