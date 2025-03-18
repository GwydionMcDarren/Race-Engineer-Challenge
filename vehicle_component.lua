--One component is one degree of freedom
--Every component has inertia, its degree of freedom (r[0]), and two derivatives (r[1], r[2])
--Components are stored in a vehicle table, each associated with a number rather than a key
--Components have a list of neighbouring components
--Components can apply constraints against eachother; they are only defined by the lower end constraint

car = {
components = {},
solver = timeStepSolver
}

vehicle_component = {
name = "",
inertia = 1,
}

function vehicle_component:new(component)
	component = component or {}
	setmetatable(component, vehicle_component)
	self.__index = self
	component.netForce = component.netForce or function () return 0 end
	component.update = component.update or function () end
	component.parameters = component.parameters or {}
	component.constraints = component.constraints or {}
	component.numcoords = component.numcoords or 1
	component.coords = {}
	if component.numcoords > 1 then
		for i=1,component.numcoords do
			component.coords[component.coordsNames[i]] = {[0] = 0, 0, 0}
		end
	else 
		component.coords.x = {[0] = 0, 0, 0}
	end
	return component
end



motor = vehicle_component:new{
	name = "Electric motor",
	inertia = 20,
	netForce = function (motor)
		local appliedVoltage = motor.parameters.throttle
		local powerLimitedTorque = math.abs(motor.parameters.maxPower/motor.coords.x[1])
		if motor.coords.x[1] < 0.01 then
			powerLimitedTorque = math.huge
		end
		return math.min(motor.parameters.maxTorque,powerLimitedTorque) * (appliedVoltage), 0
	end,
	update = function (motor)
		if win:key_down("up") then motor.parameters.throttle = 1 
		--elseif win:key_down("down") then motor.parameters.throttle = -0.5
		else motor.parameters.throttle = 0 end
		--if am.frame_time < 15 then	motor.parameters.throttle = 1 else motor.parameters.throttle = 0 end
	end,
	parameters = {throttle = 0, maxSpeed = 1000, maxTorque = 1500, maxPower = 50000},
	constraints = {[3] = {"fixed", 1/8.139}}
	}

motor_f = vehicle_component:new{
	name = "Electric motor (Front)",
	inertia = 20,
	netForce = function (motor)
		local appliedVoltage = motor.parameters.throttle
		local powerLimitedTorque = math.abs(motor.parameters.maxPower/motor.coords.x[1])
		if motor.coords.x[1] < 0.01 then
			powerLimitedTorque = math.huge
		end
		return -math.min(motor.parameters.maxTorque,powerLimitedTorque) * (appliedVoltage), 0
	end,
	update = function (motor)
		if win:key_down("up") then motor.parameters.throttle = 1 
		--elseif win:key_down("down") then motor.parameters.throttle = -0.5
		else motor.parameters.throttle = 0 end
	end,
	parameters = {throttle = 0, maxSpeed = 1000, maxTorque = 0, maxPower = 0},
	constraints = {[4] = {"fixed", 1/8.139}}
	}

driveshaft = vehicle_component:new{
	name = "Rear wheel",
	inertia = 10,
	netForce = function (wheel) 
		local tyreTorque =-tyreForce(wheel,car.components[wheel.parameters.bodyTarget])*wheel.parameters.radius
		local brakeTorque = -driveshaft.parameters.brake * 5000 * math.sign(wheel.coords.x[1])
		return tyreTorque,brakeTorque
	end,
	update = function (driveshaft,car)
		if win:key_down("down") then 
		driveshaft.parameters.brake = 1
		else driveshaft.parameters.brake = 0 end
		--if am.frame_time > 15 then	driveshaft.parameters.brake = 1 else driveshaft.parameters.brake = 0 end
	end,
	parameters = {bodyTarget = 5, radius = 0.32, brake = 0, normalForce = 500*9.81},
	--constraints = {[5] = {"fixed", 0.32}}
	}
	
front_wheel = vehicle_component:new{
	name = "Front wheel",
	inertia = 10,
	netForce = function (wheel) 
		local tyreTorque =-tyreForce(wheel,car.components[wheel.parameters.bodyTarget])*wheel.parameters.radius
		local brakeTorque = -driveshaft.parameters.brake * 5000 * math.sign(wheel.coords.x[1])
		return tyreTorque,brakeTorque
	end,
	update = function (driveshaft,car)
		if win:key_down("down") then 
		driveshaft.parameters.brake = 1
		else driveshaft.parameters.brake = 0 end
		--if am.frame_time > 15 then	driveshaft.parameters.brake = 1 else driveshaft.parameters.brake = 0 end
	end,
	parameters = {bodyTarget = 5, radius = 0.32, brake = 0, normalForce = 500*9.81},
	--constraints = {[5] = {"fixed", 0.32}}
	}
	
body_x =  vehicle_component:new{
	name = "Body (x direction)",
	inertia = 1000,
	netForce = function (body) 
		local frontTyreForce = tyreForce(car.components[body.parameters.axleTargets[1]],body)
		local rearTyreForce = tyreForce(car.components[body.parameters.axleTargets[2]],body)
		local airResistance = body.parameters.coefDrag * body.coords.x[1]^2
		return 0,frontTyreForce+rearTyreForce-airResistance end,
	_ = function (bodyX,car)
		local axleForce = 0
		for i=1,#bodyX.parameters.axleTargets do
			axleForce = axleForce - car.components[bodyX.parameters.axleTargets[i]]:netForce(car)
		end
		return 0,axleForce - bodyX.parameters.coefDrag * bodyX.coords.x[1]^2
	end,
	parameters = {axleTargets = {4,3}, coefDrag = 0.7, mass=1000},
	numcoords = 3,
	coordsNames = {"x","y","theta"},
	}

car.components[1] = motor
car.components[2] = motor_f
car.components[3] = driveshaft
car.components[4] = front_wheel
car.components[5] = body_x