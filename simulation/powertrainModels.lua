--Powertrain models
--Defines the main layouts for powertrains

--I'm only going to define 2

--Electric motor, and ICE-clutch-gearbox

electricMotorPowertrain = {}

electricMotorPowertrain:new(maxPower, maxTorque, rInertia)
	powertrainPart:new{
		netTorque = function (self)
			return self.parent.controls.throttle * math.min(self.params.maxTorque, self.params.maxPower / self.state.theta[1]) * self.gear
		end
		update = function (self)
			if self.parent.controls.gear_up then self.gear = math.min(self.gear+1, 1) end
			if self.parent.controls.gear_down then self.gear = math.max(self.gear-1, -1) end
		end,
		params = {
		maxTorque = maxTorque,
		maxPower = maxPower,
		}
		inertia = {theta = 10}
}

--Net torque equation is just throttle * math.min(maxTorque, maxPower/speed)




manualGearbox = {
	constraints = {

	}
}
manualGearbox = component:new{
	dimensions = {"theta"},
	componentType = "powertrainPart",
	componentSubType = "manualGearbox",
}
manualGearbox.__index = manualGearbox
manualGearbox.constraints = input = {
	type = "stick-slip",
	state = "slip",
	inputObject = nil,
}

function manualGearbox:new(g)
	local g = g or {}
	local newManualGearbox = {}
	newManualGearbox.name = g.name or "Unnamed manual gearbox"
	newManualGearbox.inertia = {theta = g.rInertia or 5}
	newManualGearbox.params = {
		ratios = g.ratios or {-2, 0, 2, 1.5, 1.2, 0.8, 0.5}
		}

function manualGearbox:calcClutchTorque()
	local input = self.constraints.input.inputObject
	local gearRatio = self.params.ratios[self.currentGear]
	local clutchTorque = 0
	if input.state.theta[1]*gearRatio == self.state.theta[1] then
		self.constraints.input.state = "stick"
	end
	if self.constraints.input.state == "slip" then
		clutchTorque = self.calcs.getClutchPressure * self.params.clutchFrictionCoefficient.slip
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
	self.calcs.getClutchTorque = self:calcClutchPressure()
	self.calcs.getClutchSlipTorque = self:calcClutchSlipTorque()
	self.calcs.getClutchStickTorque = self:calcClutchSlipTorque()
end

function manualGearbox:update