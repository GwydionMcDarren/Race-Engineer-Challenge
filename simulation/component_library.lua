componentLibrary = {}

local static_vertical_displacement = 20 --m/50

componentLibrary.bodies = {
	sedan = body:new{
		name = "Stylish Saloon Body",
		mass = 1500, --kg
		rInertia = 2.56*1500 - 1103, --kg m^2
		axles = 2,
		dragCoefficient = 2,
		axleOffsets = {
			vec2(68,-19-(static_vertical_displacement*83/(83+68))),
			vec2(-83,-19-(static_vertical_displacement*68/(83+68)))
		},
		sprite = "graphics/sedan.png",
	},
	hatchback = body:new{
		name = "Compact Hatchback Body",
		mass = 1300, --kg
		rInertia = 2.56*1300 - 1103, --kg m^2
		axles = 2,
		dragCoefficient = 2,
		axleOffsets = {
			vec2(67,-18-(static_vertical_displacement*71/(67+71))),
			vec2(-71,-18-(static_vertical_displacement*67/(71+67)))
		},
		sprite = "graphics/hatchback.png",
	},
	old_hatchback = body:new{
		name = "Classic Hatchback Body",
		mass = 800, --kg
		rInertia = 2.56*800 - 1103, --kg m^2
		axles = 2,
		dragCoefficient = 2,
		axleOffsets = {
			vec2(59,-17-(static_vertical_displacement*62/(59+62))),
			vec2(-62,-17-(static_vertical_displacement*59/(59+62))),
		},
		sprite = "graphics/old_hatchback.png",
	},
	lorry = body:new{
		name = "Lovely Lorry Body",
		mass = 10000, --kg
		rInertia = 2.56*10000 - 1103, --kg m^2
		axles = 3,
		dragCoefficient = 5,
		axleOffsets = {
			vec2(48, -17-static_vertical_displacement/2),
			vec2(-113, -17-static_vertical_displacement/2),
			vec2(-180, -17-static_vertical_displacement/2),
		},
		sprite = "graphics/lorry.png",
	},
}

componentLibrary.axles = {
	basic_wheel = axle:new{
		name = "Basic wheel (640mm diameter)",
		mass = 10,
		rInertia = 10,
		radius = 0.32,
		springRate = 60e3,
		dampingRate = 5e3,
		maxBrakeTorque = 2e3,
		tyreStiffness = 1e6,
		sprite = "graphics/wheel-simple.png",
		peakFriction = 1.22,
		maxSlipFriction = 1.03,
	},
	old_wheel = axle:new{
		name = "Classic wheel (520mm diameter)",
		mass = 10,
		rInertia = 10,
		radius = 0.26,
		springRate = 20e3,
		dampingRate = 1e3,
		maxBrakeTorque = 800,
		tyreStiffness = 8e5,
		sprite = "graphics/old_wheel.png",
		peakFriction = 1.22,
		maxSlipFriction = 1.03,
	},
	lorry_front_wheel = axle:new{
		name = "Lorry front wheel (920mm diameter)",
		mass = 30,
		rInertia = 15,
		radius = 0.46,
		springRate = 1e6,
		dampingRate = 4e4,
		maxBrakeTorque = 1e4,
		tyreStiffness = 5e6,
		sprite = "graphics/lorry_wheel.png",
	},
	lorry_rear_wheel = axle:new{
		name = "Lorry rear wheel (920mm diameter)",
		mass = 30,
		rInertia = 15,
		radius = 0.46,
		springRate = 2e5,
		dampingRate = 7e3,
		maxBrakeTorque = 1e4,
		tyreStiffness = 5e6,
		sprite = "graphics/lorry_wheel_rear.png",
	},
}

componentLibrary.powertrain = {
	low_power_electric_motor = electricMotorPowertrain:new(110e3, 320, 50, {1}, 8),
	high_power_electric_motor = electricMotorPowertrain:new(500e3, 500, 50, {1,2}, 5),}

return componentLibrary