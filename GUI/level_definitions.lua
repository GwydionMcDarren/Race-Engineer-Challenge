function defineLevels()
sandbox = {}
storedLevels = {}
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
	roadNode = roadSurface:new(createWavyRoad()[1],createWavyRoad()[2]),--{0,30,1000,1500,2000,2500,3000},{0,0,100,0,0,0,0}), --
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
levels:createNormalLevel{
	name = 1,
	introText="You are setting a car to drive up a steep hill. To pass this level, you need to get the car to at least 60 mph. Select a gear ratio that will help the car get up the hill quickly.",
	shortIntroText="Set up the car to drive up the hill",
	adjustments={
		{
			adjustmentType="motor_driveRatio",
			default=5,
			low=0.5,
			high=10,
		},
	},
	car={
		body="hatchback",
		axles="basic_wheel",
		powertrain="low_power_electric_motor",
	},
	roadSurface={
		x = uphillRoad(50,500)[1],
		y = uphillRoad(50,500)[2]
	},
	scoreMode="maxSpeed",
	scoreThreshold=40/2.25,
	scoreTest=nil,
	endMode="x_distance",
	endCondition=400,
}

	levels:createNormalLevel{
	name = 2,
	introText="You are setting a car to drive up a steep hill. To pass this level, you need to get the car to at least 60 mph. Select a gear ratio that will help the car get up the hill quickly.",
	shortIntroText="Set up the car to drive up the hill",
	adjustments={
		{
			adjustmentType="motor_driveRatio",
			default=5,
			low=0.5,
			high=10,
		},
	},
	car={
		body="hatchback",
		axles="basic_wheel",
		powertrain="low_power_electric_motor",
	},
	roadSurface={
		x = uphillRoad(50,500)[1],
		y = uphillRoad(50,500)[2]
	},
	scoreMode="maxSpeed",
	scoreThreshold=40/2.25,
	scoreTest=nil,
	endMode="x_distance",
	endCondition=400,
	nextLevel = 5
}

	levels:createNormalLevel{
	name = 3,
	introText="You are driving a car over a bumpy road. Try keep suspension travel to less than 0.25m before you reach 30mph",
	shortIntroText="Minimise suspension travel at 30mph",
	adjustments={
		{
			adjustmentType="axle_springRate",
			default=6e4,
			low=1e4,
			high=10e4,
		},
		{
			adjustmentType="axle_dampingRate",
			default=0,
			low=0,
			high=1e4,
		},
	},
	car={
		body="sedan",
		axle="basic_wheel",
		powertrain="high_power_electric_motor",
	},
	roadSurface={
		x = createSinusoidalRoad(1.235,0.05,2000)[1],
		y = createSinusoidalRoad(1.235,0.05,2000)[2]
	},
	scoreMode="maxSuspensionTravel",
	scoreThreshold=0.25,
	scoreTest="lessThan",
	endMode="maxSpeed",
	endCondition=30/2.25,
}

	levels:createNormalLevel{
	name = 4,
	introText="This level is designed to test model performance.",
	shortIntroText="Model Verification Tests",
	car={
		body="unitMass",
		axle="unitMass_wheel",
		powertrain="low_power_electric_motor",
	},
	roadSurface={
		x = {0,1000},
		y = {0,0}
	},
	scoreMode="maxSuspensionTravel",
	scoreThreshold=2,
	scoreTest=nil,
	endMode="time",
	endCondition=30,
}

	levels:createNormalLevel{
	name = 5,
	introText="You are now driving a car along a flat road. Set up the gear ratio to reach 85mph in half a mile",
	shortIntroText="Set up the car to have a high maximum speed",
	adjustments={
		{
			adjustmentType="motor_driveRatio",
			default=8,
			low=0.1,
			high=15,
		},
	},
	car={
		body="old_hatchback",
		axles="old_wheel",
		powertrain="low_power_electric_motor",
	},
	roadSurface={
		x = {0,1000},
		y = {0,0}
	},
	scoreMode="maxSpeed",
	scoreThreshold=85/2.25,
	scoreTest=nil,
	endMode="x_distance",
	endCondition=800,
}

end