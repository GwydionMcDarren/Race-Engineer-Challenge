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
				print("gear change attempted!", self.direction)
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