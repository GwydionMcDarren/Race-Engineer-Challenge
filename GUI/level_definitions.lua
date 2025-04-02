function defineLevels()
sandbox = {}
level1 = nil
level2 = nil
level3 = nil
sandbox = game:new{
	vehicle = {
		car:new(
			componentLibrary.bodies.old_hatchback,
			{
				componentLibrary.axles.old_wheel,
				componentLibrary.axles.old_wheel,
			},
			componentLibrary.powertrain.low_power_electric_motor
		),
	},
	roadNode = roadSurface:new(createWavyRoad("x"),createWavyRoad("y")),--{0,30,1000,1500,2000,2500,3000},{0,0,100,0,0,0,0}), --
	backdrop = {
		sprite = backgroundHillSprite,
		movement = 5,
		offset = vec2(0,0)
	},
	gui = gui:newElement{
		trackingVariable = "front_axle_speed",
		unit_scaling = 0.3*2.25,
		max = 90,
		min = 0,
		valueIsAbs = true,
		location = vec2(0,-150),
	},
	menu = menu:new{
		newButton{
			size=vec2(150,50),
			position=vec2(-300,-200),
			colour=vec4(1,0.8,0,1),
			label="Restart",
			labelColour=vec4(1,1,1,1),
			clickFunction = 
				function()
					currentLevel:nextStage(d)
				end
		},
		newButton{
			size=vec2(150,50),
			position=vec2(-300,-250),
			colour=vec4(1,0,0,1),
			label="Quit",
			labelColour=vec4(1,1,1,1),
			clickFunction = 
				function()
					currentGame:kill() 
					mainMenu:initialise()
					defineLevels()
				end
		},
	},
}
level1 = levels:new{
	name = "Level 1",
	[1] = menu:new{
		am.rect(-400,-300,400,300,vec4(0.3,0.3,0.3,1)),
		am.translate(vec2(0,200))^am.text("Pass score: 700",vec4(1,1,1,1)),
		newSlider{
			position=vec2(-150,0),
			length=200,
			label="Gear Ratio",
			name="motor_driveRatio",
			knobColour = vec4(1,0,0,1),
			knobSize=20,
			valueLimits = {0.01,7},
			defaultValue = 2.35,
		},
		newButton{
			size=vec2(150,50),
			position=vec2(-75,-200),
			colour=vec4(0,0.9,0.4,1),
			label="Continue",
			labelColour=vec4(1,1,1,1),
			clickFunction = 
				function()
					d = level1[1]:close()
				end
		},
	},	
	[2] = game:new{
	vehicle = {
		car:new(
			componentLibrary.bodies.hatchback,
			{
				componentLibrary.axles.basic_wheel,
				componentLibrary.axles.basic_wheel,
			},
			componentLibrary.powertrain.Z14XEP
		),
	},
	roadNode = roadSurface:new(createWavyRoad("x"),createWavyRoad("y",200)),
	backdrop = {
		sprite = backgroundHillSprite,
		movement = 5,
		offset = vec2(0,0)
	},
	gui = gui:newElement{
		trackingVariable = "front_axle_speed",
		unit_scaling = 0.32*2.25,
		max = 90,
		min = 0,
		valueIsAbs = true,
		location = vec2(0,-150),
	},
	endCondition = math.huge,
	scoreMode = "maxSpeed",
	},
	[3] = menu:new{
		am.rect(-400,-300,400,300,vec4(0,0.5,0.5,1)),
		am.translate(vec2(0,200))^wrappedText("Lots and lots of characters in this text, so it will take lots and lots and lots of new lines.",vec4(1,1,1,1),64),
		newButton{
			size=vec2(150,50),
			position=vec2(-75,-25),
			colour=vec4(0,0.9,0.4,1),
			label="Continue",
			labelColour=vec4(1,1,1,1),
			clickFunction = 
				function() 
					level1[3]:close()
				end},
	}
}

level2 = levels:new{
	name = "Level 2",
	[1] = menu:new{
		am.rect(-400,-300,400,300,vec4(0.3,0.3,0.3,1)),
		am.translate(vec2(0,200))^am.text("Pass score: 700",vec4(1,1,1,1)),
		newSlider{
			position=vec2(-200,0),
			length=200,
			label="Spring Stiffness (N/m)",
			name="axle_springRate",
			knobColour = vec4(1,0,0,1),
			knobSize=20,
			valueLimits = {1e4,1e5},
			defaultValue = 6e4,
		},
		newSlider{
			position=vec2(-200,-75),
			length=200,
			label="Damping Rate (Ns/m)",
			name="axle_dampingRate",
			knobColour = vec4(1,0,0,1),
			knobSize=20,
			valueLimits = {0,1e4},
			defaultValue = 5e3,
		},
		newButton{
			size=vec2(150,50),
			position=vec2(-75,-200),
			colour=vec4(0,0.9,0.4,1),
			label="Continue",
			labelColour=vec4(1,1,1,1),
			clickFunction = 
				function()
					level2[1]:close()
				end
		},
	},	
	[2] = game:new{
	vehicle = {
		car:new(
			componentLibrary.bodies.sedan,
			{
				componentLibrary.axles.basic_wheel,
				componentLibrary.axles.basic_wheel,
			},
				componentLibrary.powertrain.high_power_electric_motor
		),
	},
	roadNode = roadSurface:new(createWavyRoad("x",0,0,1e4),createWavyRoad("y",3,30)),
	backdrop = {
		sprite = backgroundHillSprite,
		movement = 5,
		offset = vec2(0,0)
	},
	gui = gui:newElement{
		trackingVariable = "front_axle_speed",
		unit_scaling = 0.26*2.25,
		max = 90,
		min = 0,
		valueIsAbs = true,
		location = vec2(0,-150),
	},
	endCondition = 1e2,
	},
	[3] = menu:new{
		am.rect(-400,-300,400,300,vec4(0,0.5,0.5,1)),
		am.translate(vec2(0,200))^liveText("You ##D the level",vec4(1,1,1,1),1),
		newButton{
			size=vec2(150,50),
			position=vec2(-75,-25),
			colour=vec4(0,0.9,0.4,1),
			label="Continue",
			labelColour=vec4(1,1,1,1),
			clickFunction = 
				function() 
					level2[3]:close()
				end},
	}
}

level3 = levels:createNormalLevel{
	introText="test level. This is the long introduction text.",
	shortIntroText="short summary of the level",
	adjustments={
		{
			adjustmentType="motor_driveRatio",
			default=8,
			low=3,
			high=20,
		},
	},
	car={
		body="sedan",
		axles={
			"basic_wheel",
			"basic_wheel",
		},
		powertrain="low_power_electric_motor",
	},
	roadSurface={
		x = {0,1000},
		y = {0,0},
	},
	scoreMode="maxSpeed",
	scoreThreshold=20,
	scoreTest=nil,
	endMode="time",
	endCondition=120,
}

end