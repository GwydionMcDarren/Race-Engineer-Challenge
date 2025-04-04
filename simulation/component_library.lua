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
	unitMass = body:new{
		name = "Unit Mass Test Body",
		mass = 1, --kg
		rInertia = 1, --kg m^2
		axles = 1,
		dragCoefficient = 0,
		axleOffsets = {
			vec2(0, 0),
		},
		sprite = "graphics/wheel-marker.png",
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
	unitMass_wheel = axle:new{
		name = "Unit Wheel",
		mass = 1,
		rInertia = 1,
		radius = 0.32,
		springRate = 1,
		dampingRate = 0,
		maxBrakeTorque = 1,
		tyreStiffness = 100,
		sprite = "graphics/wheel-simple.png",
	},
}

componentLibrary.powertrain = {
	low_power_electric_motor = {electricMotorPowertrain:new(110e3, 320, 50, {1}, 8)},
	high_power_electric_motor = {electricMotorPowertrain:new(250e3, 100, 50, {1}, 5),electricMotorPowertrain:new(250e3, 100, 50, {2}, 5)},
	Z14XEP = {
		combustionEngine:new(
			{104.7197551, 115.1917306, 125.6637061, 136.1356817, 146.6076572, 157.0796327, 167.5516082, 178.0235837, 188.4955592, 198.9675347, 209.4395102, 219.9114858, 230.3834613, 240.8554368, 251.3274123, 261.7993878, 272.2713633, 282.7433388, 293.2153143, 303.6872898, 314.1592654, 324.6312409, 335.1032164, 345.5751919, 356.0471674, 366.5191429, 376.9911184, 387.4630939, 397.9350695, 408.407045, 418.8790205, 429.350996, 439.8229715, 450.294947, 460.7669225, 471.238898, 481.7108736, 492.1828491, 502.6548246, 513.1268001, 523.5987756, 534.0707511, 544.5427266, 555.0147021, 565.4866776, 575.9586532, 586.4306287, 596.9026042, 607.3745797, 617.8465552, 628.3185307, 638.7905062},
			{58.8, 66.8, 73.5, 79.2, 84, 88.2, 91.9, 95.2, 98, 100.6, 102.9, 105, 107, 108.7, 110.3, 111.8, 113.1, 114.4, 115.5, 116.6, 117.6, 118.6, 119.5, 120.3, 121.1, 121.8, 122.5, 123.2, 123.8, 124.4, 125, 125, 124.8, 124.6, 124.2, 123.8, 123.2, 122.6, 121.9, 121.1, 120.1, 119.1, 118, 116.8, 115.5, 114.1, 112.5, 110.1, 106.9, 103, 98.3, 93},
			2,
			1),
		manualGearbox:new{
			ratios = {-3.308,0,3.727,2.136,1.414,1.121,0.892},
			ratioNames = {"R","N","1","2","3","4","5"},
			defaultGear = 2,
			finalDrive = 3.74,
			drivenAxles = {1},
			enginePart = {1},
		}
	}
}

return componentLibrary