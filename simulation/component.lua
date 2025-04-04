--Class component is the prototype for body, axle, and powertrain classes.
matrix = require('3rd_party.matrix')
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

function component:newInstance(adjustmentList)
	local newInstance = {}
	newInstance.state = {}
	for index,dimension in pairs(self.dimensions) do
		newInstance.state[dimension] = {[0] = 0,0}
	end
	local adjustmentsList = adjustmentsList or {}
	for k,v in pairs(adjustmentsList) do
		newInstance.params.k = v
	end
	self.__index = self
	setmetatable(newInstance, self)
	if type(self.createNode) == "function" then
		newInstance.node = newInstance:createNode()
	end
	return newInstance
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
	newBody.inertia.theta = b.rInertia or 1e4
	newBody.params = {
		numAxles = (b.axles or 2),
		dragCoefficient = (b.dragCoefficient or 0.3),
		axleOffsets = b.axleOffsets,
	}
	if newBody.params.axleOffsets == nil then
		--newBody.params.axleOffsets = {vec2(62.5,-0), vec2(-72.5,-0)}
		newBody.params.axleOffsets = {vec2(62.5,-25), vec2(-72.5,-25)}
	end
	assert(#newBody.params.axleOffsets==newBody.params.numAxles, "Number of axles does not match number of offsets given")
	newBody.axleOffsetNodes = {}
	for index,offset in pairs(newBody.params.axleOffsets) do
		newBody.axleOffsetNodes[index] = am.translate(offset)
	end
	newBody.sprite = b.sprite or "graphics/tigra-50.png"
	setmetatable(newBody, self)
	return newBody
end

function body:netForce(dimension)
	local suspensionForce = {x=0,y=0,theta=0}
	local wheelLongitudinalForce = {x=0,y=0,theta=0}
	for index,axle in ipairs(self.parent.axles) do
		local suspensionForceI = self.parent:forceDirectional(axle:vecToGlobalCoords(vec2(0,axle.calcs.getSuspensionForce)), axle:vecToGlobalCoords(self.params.axleOffsets[index]/50+vec2(0,axle.state.y[0])))
		for dimension,value in pairs(suspensionForce) do
			suspensionForce[dimension] = value - suspensionForceI[dimension]
		end
	end
	if dimension == "x" then
		return {self.state.x[1]^2*self.params.dragCoefficient*math.sign(-self.state.x[1])+suspensionForce.x, 0}
	elseif dimension == "y" then
		return {suspensionForce.y-self.inertia.y*g+self.state.y[1]^2*self.params.dragCoefficient*math.sign(-self.state.y[1]),0}
	elseif dimension == "theta" then
		return {suspensionForce.theta,0}
	else
		return {0,0}
	end
end

function body:update()
	return nil
end

function body:createNode()
	local spriteNode = am.sprite((self.sprite))
	spriteNode.parent = self
	return spriteNode
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
	newAxle.inertia.x = a.mass or 10
	newAxle.inertia.y = a.mass or 10
	newAxle.inertia.theta = a.rInertia or 10
	newAxle.params = {
		radius = (a.radius or 0.3),
		springRate = (a.springRate or 30e3),
		dampingRate = (a.dampingRate or 5e3),
		maxBrakeTorque = (a.maxBrakeTorque or 2e3),
		tyreStiffness = (a.tyreStiffness or 1e6),
		brakeApplication = 0,
		maxTravel = 0.5,
		peakFriction = a.peakFriction or 1.22,
		maxSlipFriction = a.maxSlipFriction or 1.03,
	}
	newAxle.constraints = {x = {body = {x="fixed"}}}
	newAxle.sprite = a.sprite or "graphics/wheel.png"--[[
	newAxle.sprite = am.translate(vec2(0,0))^am.rotate(0)^am.sprite((a.sprite or "graphics/wheel.png"))
	newAxle.sprite.parent = newAxle
	newAxle.sprite:action( function (axleSprite)
			axleSprite"translate".position2d = vec2(axleSprite.parent.state.x[0],axleSprite.parent.state.y[0])*50
			axleSprite"rotate".angle = -axleSprite.parent.state.theta[0]
		end
	)]]
	setmetatable(newAxle, self)
	return newAxle
end

function axle:createNode()
	local spriteNode = am.translate(vec2(0,0))^am.rotate(0)^am.sprite((self.sprite))
	spriteNode:action( function (axleSprite)
			axleSprite"translate".position2d = vec2(self.state.x[0],self.state.y[0])*50
			axleSprite"rotate".angle = -self.state.theta[0]
		end
	)
	return spriteNode
end
	

function axle:update()
	self.state.theta[0] = self.state.theta[0]%(math.pi*2)
	--self.state.y[0] = math.max(math.min(self.params.radius,self.state.y[0]),-self.params.radius)
	--Check if brakes are being applied
	--self.params.brakeApplication = self.parent.controls.brakeApplication[self.componentIndex] or 0
end

function axle:recalc()
	if not self.calcs then self.calcs = {} end
	self.calcs.getAxleXPos = self:calcAxleXPos()	
	self.calcs.getAxleYPos = self:calcAxleYPos()
	self.calcs.getContactAngle = self:calcContactAngle()
	self.calcs.getAxleRoadDistance = self:calcAxleRoadDistance()
	self.calcs.getSuspensionForce = self:calcSuspensionForce()
	self.calcs.getSlip = self:calcSlip()
end

function axle:calcAxleXPos()
	local bodyAngle = self.parent.body.state.theta[0]
	return self.parent.body.state.x[0] - 
	self.state.y[0] * math.sin(bodyAngle) +	
	self.parent.body.params.axleOffsets[self.axleIndex].x/50 * math.cos(bodyAngle) - 
	self.parent.body.params.axleOffsets[self.axleIndex].y/50 * math.sin(bodyAngle)
end

function axle:calcAxleYPos()
	local bodyAngle = self.parent.body.state.theta[0]
	return self.parent.body.state.y[0] +
	self.state.y[0] * math.cos(bodyAngle) +
	self.parent.body.params.axleOffsets[self.axleIndex].x/50 * math.sin(bodyAngle) +
	self.parent.body.params.axleOffsets[self.axleIndex].y/50 * math.cos(bodyAngle)
end

function  axle:calcAxleRoadDistance()
	local axleXPos = self.calcs.getAxleXPos
	local axleYPos = self.calcs.getAxleYPos
	local roadHeight = win.scene"roadSurface":getHeight(axleXPos)
	local axleDistance = axleYPos - roadHeight
	return axleDistance
end

function axle:calcContactAngle()
	local bodyAngle = self.parent.body.state.theta[0]
	local axleXPos = self.calcs.getAxleXPos
	local radius = self.params.radius
	local roadSurface = win.scene"roadSurface"
	local y1, y2 = roadSurface:getHeight(axleXPos-radius), roadSurface:getHeight(axleXPos+radius)
	local touchingXVal = radius*(y1-y2)/math.sqrt(y1^2-2*y1*y2+y2^2+4*(radius^2))
	local angle = -math.asin(touchingXVal/radius) + bodyAngle
	return angle
end

function axle:calcSuspensionForce()
	local springForce = - self.params.springRate * (self.state.y[0])
	local damperForce = - self.params.dampingRate * (self.state.y[1])
	return springForce+damperForce
end

function axle:calcSlip()
	local wheelSurfaceSpeed = self.state.theta[1] * self.params.radius
	local contactAngle = self.calcs.getContactAngle
	local groundSpeed = math.dot(vec2(self.parent.body.state.x[1],self.parent.body.state.y[1]),vec2(math.cos(contactAngle),math.sin(contactAngle)))
	local referenceSpeed = wheelSurfaceSpeed - groundSpeed
	local longitudinalSlip = math.abs(wheelSurfaceSpeed/groundSpeed - 1) * math.sign(referenceSpeed)
	--print(longitudinalSlip)
	if math.abs(groundSpeed) < 1e-3 then --Check if slip infinite/NaN
		if math.abs(wheelSurfaceSpeed) < 1e-3 then --When car is stationary, slip is zero
			longitudinalSlip = 0
		else
			longitudinalSlip = math.huge * math.sign(referenceSpeed) -- When ground is not moving but wheel is, slip is infinite
		end
	end
	--longitudinalSlip = math.max(longitudinalSlip, -1) -- Clamp minimum value to -1
	--print(self.axleIndex, groundSpeed,longitudinalSlip,vec2(self.parent.body.state.x[1],self.parent.body.state.y[1]))
	--print(self.axleIndex, groundSpeed, wheelSurfaceSpeed, longitudinalSlip)
	return longitudinalSlip
end
	
function axle:vecToGlobalCoords(vector)
	local angle = self.parent.body.state.theta[0]
	local c = math.cos(angle)
	local s = math.sin(angle)
	local xComponent = c*vector.x+s*vector.y
	local yComponent = c*vector.y-s*vector.x
	return vec2(xComponent, yComponent)
end

function axle:netForce(dimension)
	local constForce = 0
	local frictionForce = 0
	--Evaluate contact angle
	local contactAngle = self.calcs.getContactAngle
	local uprightAngle = self.parent.body.state.theta[0]
	--Evaluate braking torque
	local brakingTorque = self.params.maxBrakeTorque * self.parent.controls.brake
	--Evaluate road normal force
	local roadNormalForce = math.max(-(self.calcs.getAxleRoadDistance)*self.params.tyreStiffness,0)
	if roadNormalForce == 0 then self.isTouchingRoad = false else self.isTouchingRoad = true end
	--print("self.calcs.getAxleRoadDistance",self.calcs.getAxleRoadDistance)
	--print("roadNormalForce",roadNormalForce)
	--Evaluate road friction force
	local roadFrictionForce = tyreForce(self,self.parent.body,roadNormalForce)
	local groundRefSpeed = math.dot(vec2(self.parent.body.state.x[1],self.parent.body.state.y[1]),vec2(math.cos(contactAngle),math.sin(contactAngle)))
	local roadFrictionRefSpeed = groundRefSpeed - self.state.theta[1]*self.params.radius
	local roadFrictionRefDirection = math.sign(-roadFrictionRefSpeed)
	roadFrictionRefDirection = 1
	-- print(self.axleIndex, roadFrictionForce, roadFrictionRefSpeed, roadFrictionRefDirection)
	--Evaluate suspension force
	--print(self.axleIndex, -contactAngle, math.cos(-contactAngle), math.sin(-contactAngle))
	local suspensionForce = self.calcs.getSuspensionForce
	if dimension == "x" then
		constForce = 
			roadNormalForce * math.sin(-contactAngle)
			- self.inertia.x * g * math.sin(uprightAngle) 
		if roadFrictionRefSpeed == 0 then 
			frictionForce = math.abs(roadFrictionForce * math.cos(-contactAngle))
		else
			frictionForce = 0
			constForce = constForce + roadFrictionForce * roadFrictionRefDirection * math.cos(-contactAngle)
		end
		--frictionForce = 0
	--print(self.axleIndex, dimension, constForce)
		return {constForce,0}
	elseif dimension == "y" then
		constForce = 
			suspensionForce 
			+ roadNormalForce * math.cos(-contactAngle)
			- self.inertia.y * g * math.cos(uprightAngle)
		if roadFrictionRefSpeed == 0 then 
			frictionForce = math.abs(roadFrictionForce * math.sin(-contactAngle))
		else
			frictionForce = 0
			constForce = constForce + roadFrictionForce * roadFrictionRefDirection * math.sin(-contactAngle)
		end
	--print(self.axleIndex, dimension, constForce)
	elseif dimension == "theta" then
		constForce = 0
		frictionForce = 0
		if roadFrictionRefSpeed == 0 then 
			frictionForce = frictionForce + math.abs(roadFrictionForce * -self.params.radius)
		else
			constForce = constForce + roadFrictionForce * roadFrictionRefDirection * -self.params.radius
		end
		if self.state.theta[1] == 0 then 
			frictionForce = frictionForce + brakingTorque
		else
			constForce = constForce + brakingTorque * -math.sign(self.state.theta[1])
		end
	--print(self.axleIndex, dimension, constForce)
	else
		error("Invalid dimension passed for axle: "..dimension.."\nValid dimension values are 'x', 'y', and 'theta'", 2)
	end
	--print("--net axle forces--\n",constForce,frictionForce)
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
	newPowertrainPart.netForce = p.netForce or self.netForce
	newPowertrainPart.update = p.update or self.update
	newPowertrainPart.name = p.name or "Unnamed powertrain component"
	newPowertrainPart.constraints = {axles = {}}
	setmetatable(newPowertrainPart, self)
	return newPowertrainPart
end

function powertrainPart:netForce(dimension)
	return {0, 0}
end

function powertrainPart:update()
	self.state.theta[0] = self.state.theta[0]%(math.pi*2)
	return nil
end

require 'simulation.powertrainModels'

--Gearbox
--Engine

if UNIT_TESTS then
	print("-- component.lua unit tests --")
	print("- testing axle class -")
	testAxle = axle:new()
	iterativeTablePrint(testAxle)
	print("-- component.lua tests complete --")
end