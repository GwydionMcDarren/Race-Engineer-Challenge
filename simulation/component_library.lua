componentLibrary = {}

local static_vertical_displacement = 5 --m/50

componentLibrary.bodies = {
	sedan = body:new{
		name = "Stylish Saloon Body",
		mass = 1500, --kg
		rInertia = 2.56*1500 - 1103, --kg m^2
		numAxles = 2,
		dragCoefficient = 0.3,
		axleOffsets = {vec2(83,-14-static_vertical_displacement),vec2(-68,-14-static_vertical_displacement)},
		sprite = "graphics/sedan.png",
	},
	hatchback = body:new{
		name = "Compact Hatchback Body",
		mass = 1300, --kg
		rInertia = 2.56*1300 - 1103, --kg m^2
		numAxles = 2,
		dragCoefficient = 0.3,
		axleOffsets = {vec2(67,-18-static_vertical_displacement),vec2(-71,-18-static_vertical_displacement)},
		sprite = "graphics/hatchback.png",
	},
	old_hatchback = body:new{
		name = "Classic Hatchback Body",
		mass = 800, --kg
		rInertia = 2.56*800 - 1103, --kg m^2
		numAxles = 2,
		dragCoefficient = 0.3,
		axleOffsets = {vec2(59,-17-static_vertical_displacement),vec2(-62,-17-static_vertical_displacement)},
		sprite = "graphics/old_hatchback.png",
	},
}

componentLibrary.axles = {
	basicWheel = axle:new{
	
	}
}

return componentLibrary