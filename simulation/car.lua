require 'simulation.component'
require 'simulation.carSolver'

car = {}

function car:iterateOverDoF()
	local a = 0
	local aMax = 3
	local b = 0
	local bMax = #self.axles*3
	local c = 0
	local cMax = #self.powertrain
	local i=0
	return function () 
		i=i+1
		if a<aMax then 
			a=a+1 
			return i, self.body, self.body.dimensions[a]
		elseif b<bMax then 
			b=b+1 
			return i, self.axles[math.ceil(b/3)], self.axles[math.ceil(b/3)].dimensions[(b-1)%3+1]
		elseif c<cMax then 
			c=c+1 
			iterativeTablePrint(self.powertrain)
			return i, self.powertrain[c], self.powertrain[c].dimensions[1]
		else return nil end
	end
end

function car:iterateOverComponents()
	local a = 0
	local b = 0
	local bMax = #self.axles
	local c = 0
	local cMax = #self.powertrain
	local i=0
	return function () 
		i=i+1
		if a<1 then a=a+1 return i, self.body
		elseif b<bMax then b=b+1 return i, self.axles[b]
		elseif c<cMax then c=c+1 return i, self.powertrain[c]
		else return nil end
	end
end

function car:getNumDoF()
	local bodyDoF = 3
	local axlesDoF = #self.axles * 3
	local powertrainDoF = #self.powertrain
	return bodyDoF + axlesDoF + powertrainDoF
end

function car:getComponentDimensionIndex(componentIndex,dimension)
	local baseIndex = 0 --lowest index of the component
	local component = car
	for i,v in pairs(component.dimensions) do
		if v==dimension then
			return i
		end
	end
end

--Applying constraints, there are currently 2 types of constraint:
--	Fixed
--	Stick-slip
--Constraints have a lot of important information
--The constrained dimension
--The component that it is constrainted to
--The diemnsion in that component it is constrained to
--The ratio of motion between the two components
--Current state of the constraint (for stick slip, whether it is stick or slip)
function car:applyConstraints(component,dimension,dimension,forceTable,massMatrixTable) -- What are we trying to do here?
	for targetComponent,targetDimension,constraint in self:iterateOverDoF() do
		local targetDimension = constraint.dimension
		local ratio = constraint.r
		local constraintType = constraint.type
		if constraintType == "fixed" then
			local targetIndex = 0
		end
	end
	return forceTable, massMatrixTable
end

function car:new(body,axles,powertrain)
	local newCar =  {body = body, axles = axles, powertrain = powertrain}
	setmetatable(newCar, self)
	self.__index = self
	--Iterate over car dimensions and initialise state
	for componentDimensionIndex,component,dimension in newCar:iterateOverDoF() do
		component:initialise()
		if not component.dimensionIndices then component.dimensionIndices = {} end
		table.insert(component.dimensionIndices,componentDimensionIndex)
	end
	--Iterate over car components to set the lowest dimension index for each component
	for componentIndex,component in newCar:iterateOverComponents() do
		component.firstDimensionIndex = math.min(listTable(component.dimensionIndices))
		component.componentIndex = componentIndex
		component.parent = newCar
	end
	for index,axle in ipairs(newCar.axles) do
		axle.axleIndex = index
	end
	newCar.solver = solver
	return newCar
end

function car:createNode()
	local carNode = am.group()
	carNode:append(self.body.sprite)
	for index,axles in pairs(self.axles) do
		carNode:append(self.body.axleOffsetNodes[index]^self.axles[index].sprite)
	end
	carNode.parent = self
	carNode:action( function ()
		self:solver(am.delta_time)
		for index,component in self:iterateOverComponents() do
			component:update()
		end
	end
	)
	return carNode
end

--telemetry

function car:createTelemetry(variablesTable)
	local telemTable = {}
	for index,varName in pairs(variablesTable) do
		if type(varName) == "string" then
			if varName == "body_displacement" or
			varName == "body_speed" or
			varName == "body_acceleration" or
			varName == "control_throttle" or
			varName == "control_brake" or
			varName == "control_gear" then
				telemTable[varName] = {}
			end
		end
	end
	self.telemetry = telemTable
	return --need function that actually collects each value every few frames
end



--dofile("componentLibrary.lua")
if UNIT_TESTS then
	print("-- car.lua unit tests --")
	testComponents = {
		body = {
			netForce = function (self) return self.dimension.x[1]^2*self.parameters.coefficientOfDrag end,
			update = function () return 0 end,
			dimensions = {"x","y","theta"},
			state = {
				x = {[0] = 0,0,0},
				y = {[0] = 0,0,0},
				theta = {[0] = 0,0,0},
				},
			parameters = {
				coefficientOfDrag = 0.3,
				length = 3.5,
				height = 1.5,
				},
			},
		axles = {
			{
			dimensions = {"x","y","theta"},
			state = {
				x = {[0] = 0,0,0},
				y = {[0] = 0,0,0},
				theta = {[0] = 0,0,0},
				},
			},
			{
			dimensions = {"x","y","theta"},
			state = {
				x = {[0] = 0,0,0},
				y = {[0] = 0,0,0},
				theta = {[0] = 0,0,0},
				},
			},
		},
		powertrain = {
			{
			dimensions = {"theta"},
			state = {
				theta = {[0] = 0,0,0},
				},
			},
		},
	}
	testCar = car:new(testComponents.body,testComponents.axles,testComponents.powertrain)
	print("-- write of components of test car table --")
	iterativeTablePrint(testCar)
	print("-- car.lua tests complete --")
end




return car