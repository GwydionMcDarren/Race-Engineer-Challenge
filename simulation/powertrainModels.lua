--Powertrain models
--Defines the main layouts for powertrains

--I'm only going to define 2

--Electric motor, and ICE-clutch-gearbox

torquePowerLimitedMotorPowertrain = {}

function torquePowerLimitedMotorPowertrain:new(maxPower, maxTorque, rInertia, drivenAxles, driveRatio)
	local newElectricMotor = component:new{
		dimensions = {"theta"},
		componentType = "powertrain",
		componentSubType = "electricMotor",
		netForce = function (self,dimension,maxPowerTest,testSpeed)
			local throttle = self.parent.controls.throttle
			local speed = self.state.theta[1]
			if maxPowerTest then throttle = 1 end
			if maxPowerTest then speed = testSpeed end
			--print(throttle * self.direction * math.min(self.params.maxTorque, self.params.maxPower / math.abs(speed)))
			return {throttle * self.direction * math.min(self.params.maxTorque, self.params.maxPower / math.abs(speed)), 0}
		end,
		update = function (self)
			self.gear = self.direction
			if self.parent.controls.gear_up or self.parent.controls.gear_down then
				if self.state.theta[1] * self.direction < 5 then
					self.direction = self.direction * -1
				end
			end
		end,
		params = {
		maxTorque = maxTorque,
		maxPower = maxPower,
		ratioNames = {[-1] = "R", [1] = "F"}
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

function combustionEngine:new(speedValues, torqueValues, rInertia, ratios, finalDrive, defaultGear, ratioNames)
	local newCombustionEngine = component:new{
		dimensions = {"theta"},
		componentType = "powertrain",
		componentSubType = "combustionEngine",
		throttle = 0,
		starter = 0,
		gear = 1,
		uninitialised = true,
		netForce = function (self, dimension, maxPowerTest,testSpeed)
			if self.parent.controls.clutch > 0.5 then return {0,0} end
			local v = self.state.theta[1]
			local throttle = self.throttle
			if maxPowerTest then throttle = 1 end
			if maxPowerTest then v = testSpeed end
			--if v <= self.params.speedValues[1] then return {0, -10} end
			if v >= self.params.speedValues[#self.params.speedValues] then return {0, -10} end
			if v <= self.params.speedValues[1] then return {self.params.torqueValues[1], 0} end
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
			return {(maxTorque+10)*throttle-10 + self.starter * 20, 0}
		end,
		update = function (self)
			if self.uninitialised then 
				self.state.theta[1] = self.params.speedValues[1]
				self.gear = self.params.defaultGear
				self.uninitialised = false
				self.constraints.output.ratio = self.params.ratios[self.gear]*self.params.finalDrive
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
			--gear logic
			if self.parent.controls.gear_up then
				local oldGearRatio = self.constraints.output.ratio
				self.gear = math.min(self.gear+1,#self.params.ratios)
				local newGearRatio = self.params.ratios[self.gear]*self.params.finalDrive
				self.constraints.output.ratio = newGearRatio
				local outputSpeed = self.parent.axles[self.constraints.output.axles[1]].state.theta[1]
				print(outputSpeed, newGearRatio, self.gear)
				self.state.theta[1] = outputSpeed*newGearRatio
			elseif self.parent.controls.gear_down then
				local oldGearRatio = self.constraints.output.ratio
				self.gear = math.max(self.gear-1,1)
				local newGearRatio = self.params.ratios[self.gear]*self.params.finalDrive
				self.constraints.output.ratio = newGearRatio
				local outputSpeed = self.parent.axles[self.constraints.output.axles[1]].state.theta[1]
				print(outputSpeed, newGearRatio, self.gear)
				self.state.theta[1] = outputSpeed*newGearRatio
			end
		end,
		params = {
			speedValues = speedValues,
			torqueValues = torqueValues,
			ratios = ratios or {-3, 0, 2, 1.5, 1.2, 0.8, 0.5},
			finalDrive = finalDrive or 3.74,
			defaultGear = defaultGear or 3,
			ratioNames = ratioNames or {"R", "N", "1", "2", "3", "4", "5"},
		},
		direction = 1,
		inertia = {theta = rInertia or 10},
		constraints = {--[[
			output = {
				type = "stick-slip",
				ratio = driveRatio or 1,
				powertrainComponents = gearboxPart or {2}
			}]]
			
			output = {
				type = "fixed-axle",
				ratio = 10,--driveRatio or 100,
				axles = drivenAxles or {1}
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
manualGearbox.constraints = {
	input = {
		type = "stick-slip",
		state = "slip",
		inputObject = nil,
	}
}

function manualGearbox:new(g)--ratios, ratioNames, rInertia, inputDevice, outputAxles)
	local g = g or {}
	local newManualGearbox = component:new{
		name = g.name or "Unnamed manual gearbox",
		inertia = {theta = g.rInertia or 1},
		params = {
			ratios = g.ratios or {-3, 0, 2, 1.5, 1.2, 0.8, 0.5},
			finalDrive = g.finalDrive or 1,
			defaultGear = g.defaultGear or 2,
			ratioNames = g.ratioNames or {"R", "N", "1", "2", "3", "4", "5"},
			clutchFrictionCoefficient = {
				slip = (g.clutchSlipFriction or 0.8), 
				stick = (g.clutchStickFriction or 0.9)
			},
			maxClutchPressure = g.maxClutchPressure or 100,
		},
		constraints = {
			input = {
				type = "stick-slip",
				ratio = 1,
				powertrainComponent = g.enginePart or {1}
			},
			output = {
				type = "fixed-axle",
				ratio = 0,
				axles = g.drivenAxles or {1}
			}
		},
		clutch = 0
	}
	manualGearbox.__index = manualGearbox
	setmetatable(newManualGearbox, self)
	return newManualGearbox
end

function manualGearbox:calcClutchTorque()
	return {0,0}
end	

function manualGearbox:calcClutchPressure()
	return (1 - self.clutch) * self.params.maxClutchPressure
end

function manualGearbox:calcSlipTorque()
	return self.calcs.getClutchPressure * self.params.clutchFrictionCoefficient.slip
end

function manualGearbox:calcStickTorque()
	return self.calcs.getClutchPressure * self.params.clutchFrictionCoefficient.stick
end

function manualGearbox:calcClutchPressure()
	return (1 - self.parent.controls.clutch) * self.params.maxClutchPressure
end

function manualGearbox:recalc()
	self.calcs = {}
	self.calcs.getClutchPressure = self:calcClutchPressure()
	self.calcs.getSlipTorque = self:calcClutchSlipTorque()
	self.calcs.getStickTorque = self:calcClutchStickTorque()
end

function manualGearbox:netForce()
	return {0, 0}
end

function manualGearbox:update()
	if not self.gear then
		self.gear = self.params.defaultGear
	end
	if self.parent.controls.gear_up then
		if self.gear < #self.params.ratios then
			self.gear = self.gear + 1
			self.clutch = 0
		end
	elseif self.parent.controls.gear_down then
		if self.gear > 1 then
			self.gear = self.gear - 1
			self.clutch = 0
		end
	end
	if self.params.ratio[self.gear] == 0 then
		self.clutch = 0
	else
		self.clutch = math.min(self.parent.controls.clutch, math.min(self.clutch + 1/60, 1))
	end	
	self.constraints.output.ratio = self.params.ratio[self.gear]*self.params.finalDrive
end