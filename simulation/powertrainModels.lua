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
		inertia = {theta = 
}

--Net torque equation is just throttle * math.min(maxTorque, maxPower/speed)
	