require 'simulation.component'
require 'simulation.carSolver3'

car = {}
car.__index = car

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

function car:iterateOverAxles()
	local b = 0
	local bMax = #self.axles
	local i=0
	return function () 
		i=i+1
		if b<bMax then b=b+1 return i, self.axles[b]
		else return nil end
	end
end

function car:iterateOverPowertrain()
	local c = 0
	local cMax = #self.powertrain
	local i=0
	return function () 
		if c<cMax then c=c+1 return i, self.powertrain[c]
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
function car:applyConstraints(component,forceIn,dimension,forceTable,massMatrixTable) -- What are we trying to do here?
	--Iterate over powertrain members to do something
	for index,powertrainComponent in self:iterateOverPowertrain() do
		--??
	end
	local bodyAngle = self.body.state.theta[0]
	local bodyXForceIndex = self.body.firstDimensionIndex * 2
	local bodyYForceIndex = (self.body.firstDimensionIndex + 1) * 2
	local bodyThetaForceIndex = (self.body.firstDimensionIndex + 2) * 2
	for index,axle in self:iterateOverAxles() do
		local axleXForceIndex = axle.firstDimensionIndex * 2
		local axleOffset = -self.body.params.axleOffsets[index]/50
		for j=1,2 do -- iterate twice to get both the constant and frictional force components
			local axleForces = self:forceDirectional(axle:vecToGlobalCoords(vec2(forceTable[axleXForceIndex][j], 0)), axle:vecToGlobalCoords(self.body.params.axleOffsets[index]/50+vec2(0,axle.state.y[0]) )+ vec2(0,-axle.params.radius))
			forceTable[axleXForceIndex] = {0,0}
			forceTable[bodyXForceIndex][j] = forceTable[bodyXForceIndex][j] + axleForces.x
			forceTable[bodyYForceIndex][j] = forceTable[bodyYForceIndex][j] + axleForces.y
			forceTable[bodyThetaForceIndex][j] = forceTable[bodyThetaForceIndex][j] + axleForces.theta
		end
		for j=1,#forceTable do
			massMatrixTable[axleXForceIndex][j] = 0
		end
			massMatrixTable[axleXForceIndex][axleXForceIndex] = 1
	end
	return forceTable, massMatrixTable
end

function car:forceDirectional(forceUV, locationXY)
	local forceVector = {}
	forceVector.x = forceUV.x
	forceVector.y = forceUV.y
	local locationYX = vec2(locationXY.y, locationXY.x)
	forceVector.theta = math.dot(vec2(forceUV.x,-forceUV.y),-locationYX)
	return forceVector
end

function car:new(body,axles,powertrain, isPlayer, adjustments)
	local newCar =  {}
	local adjustments = adjustments or {}
	newCar.body = body:newInstance(adjustments.body)
	newCar.body.dimensionIndices = {}
	newCar.axles = {}
	adjustments.axles = adjustments.axles or {}
	newCar.powertrain = {}
	adjustments.powertrain = adjustments.powertrain or {}
	for i,v in ipairs(axles) do
		newCar.axles[i] = axles[i]:newInstance(adjustments.axles[i])
		newCar.axles[i].dimensionIndices = {}
	end
	for i,v in ipairs(powertrain) do
		newCar.powertrain[i] = powertrain[i]:newInstance(adjustments.powertrain[i])
		newCar.powertrain[i].dimensionIndices = {}
	end
	setmetatable(newCar, self)
	--Iterate over car dimensions and initialise state
	for componentDimensionIndex,component,dimension in newCar:iterateOverDoF() do
		table.insert(component.dimensionIndices,componentDimensionIndex)
	end
	--Iterate over car components to set the lowest dimension index for each component
	for componentIndex,component in newCar:iterateOverComponents() do
		component.firstDimensionIndex = math.min(listTable(component.dimensionIndices))
		component.componentIndex = componentIndex
		component.parent = newCar
		print(component.firstDimensionIndex, component.name)
	end
	for index,axle in ipairs(newCar.axles) do
		axle.axleIndex = index
	end
	newCar.controls = {
		thottle = 0,
		brake = 0,
		gear_up = false,
		gear_down = false,
		clutch = 0,
		}
	newCar.solver = carSolver
	return newCar
end

function car:updateControls()
	--gear changes use key_pressed
	if win:key_pressed("a") then
		self.controls.gear_up = true
		self.controls.gear_down = false
	elseif win:key_pressed("z") then
		self.controls.gear_up = false
		self.controls.gear_down = true
	else
		self.controls.gear_up = false
		self.controls.gear_down = false
	end
	--other controls use key_down
	if win:key_down("up") then
		self.controls.throttle = 1
	else
		self.controls.throttle = 0
	end
	if win:key_down("down") then
		self.controls.brake = 1
	else
		self.controls.brake = 0
	end
	if win:key_down("space") then
		self.controls.clutch = 1
	else
		self.controls.clutch = 0
	end
end
	
function car:createNode()
	local carParts = am.group()
	local carNode = am.group(am.translate(vec2(0,0))^am.rotate(0)^carParts,am.text(""))
	carParts:append(self.body.node)
	for index,axles in pairs(self.axles) do
		carParts:append(self.body.axleOffsetNodes[index]^self.axles[index].node)
	end
	self.body.state.y[0] = (-self.body.params.axleOffsets[1].y+1)/50
	self.body.state.x[0] = 0
	self.body.state.x[1] = 0
	carNode.parent = self
	carNode:action( function (bodySprite)
		if not win:key_down("space") then
		
		ts = 1/(60*num_steps)
		timestep = 0
		while timestep <= am.delta_time do
			timestep = timestep + self:solver(ts)
		end
		for index,component in self:iterateOverComponents() do
			component:update()
		end
		end
		if win:key_pressed("q") then
			print("STATE DUMP\n")
			for index, component, dimension in self:iterateOverDoF() do
				print(component.state[dimension][1])
			end
		end
		currentGame:updateCamera(self)
		self:updateControls()
		bodySprite"translate".position2d = vec2(bodySprite.parent.body.state.x[0],bodySprite.parent.body.state.y[0])*50
		bodySprite"rotate".angle = bodySprite.parent.body.state.theta[0]
		--bodySprite"text".text = ""..tostring(bodySprite.parent.body.state.y[0]).." "..tostring(bodySprite.parent.body.state.y[1]).."\n"..tostring(bodySprite.parent.axles[1].state.y[0]).." "..tostring(bodySprite.parent.axles[1].state.y[1])
	end
	)
	return carNode
end

--Controls
--This contains functions to update controller state by player or computer
--These control values can then be accessed by different components do decide state

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