--Powertrain models
--Defines the main layouts for powertrains

--I'm only going to define 2

--Electric motor, and ICE-clutch-gearbox

electricMotorPowertrain = {}

function electricMotorPowertrain:new(maxPower, maxTorque, rInertia, drivenAxles, driveRatio)
	local newElectricMotor = component:new{
		dimensions = {"theta"},
		componentType = "powertrain",
		componentSubType = "electricMotor",
		netForce = function (self)
			return {self.parent.controls.throttle * self.direction * math.min(self.params.maxTorque, self.params.maxPower / math.abs(self.state.theta[1])), 0}
		end,
		update = function (self)
			if self.parent.controls.gear_up or self.parent.controls.gear_down then
				if self.state.theta[1] * self.direction < 5 then
					self.direction = self.direction * -1
				end
			end
		end,
		params = {
		maxTorque = maxTorque,
		maxPower = maxPower,
		},
		direction = 1,
		inertia = {theta = rInertia or 10},
		constraints = {
			output = {
				type = "fixed-axle",
				ratio = driveRatio or 1,
				axles = drivenAxles or {2}
			}
		}
	}
	return newElectricMotor
end

--Combustion engine

combustionEngine = {}

function combustionEngine:new(speedValues, torqueValues, rInertia, driveRatio, gearboxPart)
	local newCombustionEngine = component:new{
		dimensions = {"theta"},
		componentType = "powertrain",
		componentSubType = "combustionEngine",
		throttle = 0,
		starter = 0,
		uninitialised = true,
		netForce = function (self)
			local v = self.state.theta[1]
			--if v <= self.params.speedValues[1] then return {0, -10} end
			if v >= self.params.speedValues[#self.params.speedValues] then return {0, -10} end
			local highIndex = #self.params.speedValues
			local lowIndex = 1
			while highIndex - lowIndex > 1 do
				local guessIndex = math.floor((highIndex+lowIndex)/2)
				if guessIndex == lowIndex then highIndex = guessIndex + 1
				elseif self.params.speedValues[guessIndex] > v then highIndex = guessIndex
				else lowIndex = guessIndex
			end
			end
			local lowX = self.params.speedValues[lowIndex]
			local highX = self.params.speedValues[highIndex]
			local lowY = self.params.torqueValues[lowIndex]
			local highY = self.params.torqueValues[highIndex]
			maxTorque = linearInterpolate(lowX,highX,lowY,highY,v)
			return {(maxTorque+10)*self.throttle-10 + self.starter * 20, 0}
		end,
		update = function (self)
			if self.uninitialised then 
				self.state.theta[1] = self.params.speedValues[1]
				self.uninitialised = false
			end
			if self.state.theta[1] < 30 then 
				self.starter = 1
			elseif self.state.theta[1] < 100 then
				self.throttle = 1
				self.starter = 0
			else 
				self.throttle = self.parent.controls.throttle
				self.starter = 0
			end
		end,
		params = {
		speedValues = speedValues,
		torqueValues = torqueValues,
		},
		direction = 1,
		inertia = {theta = rInertia or 10},
		constraints = {
			output = {
				type = "stick-slip",
				ratio = driveRatio or 1,
				powertrainComponents = gearboxPart or {2}
			}
		}
	}
	return newCombustionEngine
end


--Net torque equation is just throttle * math.min(maxTorque, maxPower/speed)

manualGearbox = component:new{
	dimensions = {"theta"},
	componentType = "powertrainPart",
	componentSubType = "manualGearbox",
}
manualGearbox.__index = manualGearbox
manualGearbox.constraints = {
	input = {
		type = "stick-slip",
		state = "slip",
		inputObject = nil,
	}
}

function manualGearbox:new(g)
	local g = g or {}
	local newManualGearbox = {}
	newManualGearbox.name = g.name or "Unnamed manual gearbox"
	newManualGearbox.inertia = {theta = g.rInertia or 5}
	newManualGearbox.params = {
		ratios = g.ratios or {-3, 0, 2, 1.5, 1.2, 0.8, 0.5},
		defaultGear = g.defaultGear or 2,
		ratioNames = g.ratioNames or {"R", "N", "1", "2", "3", "4", "5"},
		clutchFrictionCoefficient = {
			slip = (g.clutchSlipFriction or 0.8), 
			stick = (g.clutchStickFriction or 0.9)
		},
		maxClutchPressure = g.maxClutchPressure or 100,
	}
	setmetatable(newManualGearbox, self)
	newManualGearbox.constraints.output = {type = "fixed-axle", axles = g.outputAxles or {2}}
	return newManualGearbox
end

function manualGearbox:calcClutchTorque()
	local input = self.constraints.input.inputObject
	local gearRatio = self.params.ratios[self.currentGear]
	local clutchTorque = 0
	if input.state.theta[1]*gearRatio == self.state.theta[1] then
		self.constraints.input.state = "stick"
	end
	if self.constraints.input.state == "slip" then
		clutchTorque = self.calcs.getClutchPressure * self.params.clutchFrictionCoefficient.slip * -math.sign(input.state.theta[1] - self.state.theta[1])
	end
end	

function manualGearbox:calcClutchPressure()
	return (1 - self.parent.controls.clutch) * self.params.maxClutchPressure
end

function manualGearbox:calcClutchSlipTorque()
	return self.calcs.getClutchPressure * self.params.clutchFrictionCoefficient.slip
end

function manualGearbox:calcClutchStickTorque()
	return self.calcs.getClutchPressure * self.params.clutchFrictionCoefficient.stick
end

function manualGearbox:calcClutchPressure()
	return (1 - self.parent.controls.clutch) * self.params.maxClutchPressure
end

function manualGearbox:recalc()
	self.calcs = {}
	self.calcs.getClutchPressure = self:calcClutchPressure()
	self.calcs.getClutchSlipTorque = self:calcClutchSlipTorque()
	self.calcs.getClutchStickTorque = self:calcClutchStickTorque()
end

function manualGearbox:netForce()
	return {self.calcs.getClutchSlipTorque, 0}
end

function manualGearbox:update()
	if not self.gear then
		self.gear = self.params.defaultGear
	end
	if self.parent.controls.gear_up then
		if self.gear < #self.params.ratios then
			self.gear = self.gear + 1
		end
	elseif self.parent.controls.gear_down then
		if self.gear > 1 then
			self.gear = self.gear - 1
		end
	end
end