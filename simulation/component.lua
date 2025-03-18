--Class component is the prototype for body, axle, and powertrain classes.

component = {
name = "",
inertia = {},
}
component.__index = component

function component:new(c)
	newComponent = c or {}
	newComponent.spriteNode = c.spriteNode or am.rect(0,0,15,15,vec4(1,1,0,1))
	newComponent.spriteNode.parent = component
	--newComponent.netForce = c.netForce or function () return 0 end
	--newComponent.update = c.update or function () end
	--newComponent.params = c.params or {}
	--newComponent.constraints = c.constraints or {}
	--newComponent.dimensions = c.dimensions or {}
	--newComponent.state = {}
	--newComponent.constraints = {}
	setmetatable(newComponent, self)
	return newComponent
end

function component:getDimensionIndex(dimension)
	assert(type(dimension)=="string")
	for index,dimensionName in pairs(self.dimensions) do
		if dimension == dimensionName then return index end
	end
	print("Warning: Dimension with name '"..dimension.."' not found in component "..self.name)
end

function component:initialise()
	self.state = {}
	for index,dimension in pairs(self.dimensions) do
		self.state[dimension] = {[0] = 0,0,0}
	end
end

--Cases of components:


--Body

body = component:new{
	dimensions = {"x","y","theta"},
	componentType = "body",
}
body.__index = body

function body:new(b)
	local newBody = {}
	local b = b or {}
	newBody.name = b.name or "Unnamed body"
	newBody.inertia = {}
	newBody.inertia.x = b.mass or 1e3
	newBody.inertia.y = b.mass or 1e3
	newBody.inertia.theta = b.rInertia or 1e3
	newBody.params = {
		massOffset = (b.offset or vec2(0,40)),
		brakeApplication = 0,
		numAxles = (b.axles or 2),
		dragCoefficient = (b.dragCoefficient or 0.3),
		axleOffsets = b.alxeOffsets,
	}
	if newBody.params.axleOffsets == nil then
		newBody.params.axleOffsets = {}
		for i=1,newBody.params.numAxles do
			newBody.params.axleOffsets[i] = vec2(0,0)
		end
	end
	assert(#newBody.params.axleOffsets==newBody.params.numAxles, "Number of axles does not match number of offsets given")
	newBody.axleOffsetNodes = {}
	for index,offset in pairs(newBody.params.axleOffsets) do
		newBody.axleOffsetNodes[index] = am.translate(offset)
	end
	newBody.sprite = am.translate(newBody.params.massOffset)^am.rotate(0)^am.sprite((b.sprite or "graphics/tigra-50.png"))
	newBody.sprite:action( function (bodySprite)
			bodySprite"translate".position2d = vec2(newBody.state.x[0],newBody.state.y[0])
			bodySprite"rotate".angle = newBody.state.theta[0]
		end
	)
	setmetatable(newBody, self)
	return newBody
end

function body:netForce()
	return {(self.state.x[1]^2+self.state.y[1]^2)*self.params.dragCoefficient, 0}
end

function body:update()
	return nil
end



--Axle

axle = component:new{
	dimensions = {"x","y","theta"},
	componentType = "axle",
}
axle.__index = axle

function axle:new(a)
	local newAxle = {}
	local a = a or {}
	newAxle.name = a.name or "Unnamed axle"
	newAxle.inertia = {}
	newAxle.inertia.x = a.mass or 1
	newAxle.inertia.y = a.mass or 1
	newAxle.inertia.theta = a.rInertia or 1
	newAxle.params = {
		radius = (a.radius or 0.3),
		springRate = (a.springRate or 1e4),
		dampingRate = (a.dampingRate or 1e3),
		maxBrakeTorque = (a.maxBrakeTorque or 100),
		tyreStiffness = (a.tyreStiffness or 1e5),
		brakeApplication = 0,
	}
	newAxle.constraints = {x = {body = {x="fixed"}}}
	newAxle.sprite = am.translate(vec2(0,0)):tag("carPosition")^am.sprite((a.sprite or "graphics/wheel.png"))
	setmetatable(newAxle, self)
	return newAxle
end

function axle:update()
	--Check if brakes are being applied
	--self.params.brakeApplication = self.parent.controls.brakeApplication[self.componentIndex] or 0
end

function axle:getAxleRoadDistance()
	local axlePosition = self.parent.body.state.x[0] + 
	self.parent.body.params.axleOffsets[self.axleIndex].x * math.cos(self.parent.body.state.theta[0]) -
	(self.parent.body.params.axleOffsets[self.axleIndex].y + self.state.y[0]) * math.sin(self.parent.body.state.theta[0])
	local axleYPosition = self.parent.body.state.y[0]  +
	(self.parent.body.params.axleOffsets[self.axleIndex].y + self.state.y[0]) * math.cos(self.parent.body.state.theta[0]) + 
	self.parent.body.params.axleOffsets[self.axleIndex].x * math.sin(self.parent.body.state.theta[0])
	local radius = self.params.radius
	local roadWheelDistance = {}
	local roadSurface = win.scene"roadSurface"
	local angle, RoadHeightAddWheelHeight = self:getContactAngle()
	return axleYPosition - (RoadHeightAddWheelHeight - self.params.radius*math.cos(angle))
end
	

function axle:getContactAngle()
	local axleXPosition = self.parent.body.state.x[0] + 
	self.parent.body.params.axleOffsets[self.axleIndex].x * math.cos(self.parent.body.state.theta[0]) -
	(self.parent.body.params.axleOffsets[self.axleIndex].y + self.state.y[0]) * math.sin(self.parent.body.state.theta[0])
	local axleYPosition = self.parent.body.state.y[0]  +
	(self.parent.body.params.axleOffsets[self.axleIndex].y + self.state.y[0]) * math.cos(self.parent.body.state.theta[0]) + 
	self.parent.body.params.axleOffsets[self.axleIndex].x * math.sin(self.parent.body.state.theta[0])
	local radius = self.params.radius
	local roadWheelDistance = {}
	local roadSurface = win.scene"roadSurface"
	for i=-radius,radius,0.1 do
		local wheelHeight = math.sqrt(radius^2-i^2)
		table.insert(roadWheelDistance,{i,roadSurface:getHeight(axleXPosition+wheelHeight)})
	end
	table.sort(roadWheelDistance, function (a,b) if a[2] < b[2] then return true end end)
	local angle = math.sin((roadWheelDistance)[#roadWheelDistance][1]/radius)
	return angle, (roadWheelDistance)[#roadWheelDistance][2]
end
	

function axle:netForce(dimension)
	local constForce = 0
	local frictionForce = 0
	--Evaluate contact angle
	local contactAngle = self:getContactAngle()
	local uprightAngle = self.parent.body.state.theta[0]
	--Evaluate braking torque
	local brakingTorque = self.params.maxBrakeTorque * self.params.brakeApplication
	--Evaluate road normal force
	local roadNormalForce = math.max((self:getAxleRoadDistance()-self.params.radius)*self.params.tyreStiffness,0)
	--Evaluate road friction force
	local roadFrictionForce = tyreForce(self,self.parent.body,roadNormalForce)
	--Evaluate suspension force
	local springForce = self.params.springRate * (self.state.x[0] - self.parent.body.state.x[0])
	local damperForce = self.params.dampingRate * (self.state.x[1] - self.parent.body.state.x[1])
	local suspensionForce = springForce+damperForce
	if dimension == "x" then
		constForce = 
			roadNormalForce * math.sin(contactAngle)
			- self.inertia.x * g * math.sin(uprightAngle) 
			+ roadFrictionForce * math.cos(contactAngle)
		frictionForce = 0
	elseif dimension == "y" then
		constForce = 
			suspensionForce 
			+ roadNormalForce * math.cos(contactAngle)
			- self.inertia.y * g * math.cos(uprightAngle)
			+ roadFrictionForce * math.sin(contactAngle)
		frictionForce = 0
	elseif dimension == "theta" then
		constForce = 
		- roadFrictionForce * self.params.radius
		frictionForce = brakingTorque
	else
		error("Invalid dimension passed for axle: "..dimension.."\nValid dimension values are 'x', 'y', and 'theta'", 2)
	end
	return {constForce, frictionForce}
end
--Powertrain

powertrainPart = component:new{
	dimensions = {"theta"},
	componentType = "powertrain",
}
powertrainPart.__index = powertrainPart

function powertrainPart:new(p)
	local newPowertrainPart = {}
	local p = p or {}
	newPowertrainPart.inertia = {}
	newPowertrainPart.inertia.theta = p.rInertia or 1
	newPowertrainPart.params = p.params or {}
	newPowertrainPart.name = p.name or "Unnamed powertrain component"
	newPowertrainPart.constraints = {axles = {}}
	setmetatable(newPowertrainPart, self)
	return powertrainPart
end

function powertrainPart:netForce(dimension)
	return {0, 0}
end

function powertrainPart:update()
	return nil
end

--Gearbox
--Engine

if UNIT_TESTS then
	print("-- component.lua unit tests --")
	print("- testing axle class -")
	testAxle = axle:new()
	iterativeTablePrint(testAxle)
	print("-- component.lua tests complete --")
end