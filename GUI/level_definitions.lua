function defineLevels()
storedLevels = {}

	levels:createNormalLevel{
	name = "gears1",
	introText="You are driving a car up a steep hill. Select a gear ratio that will help the car get up the hill quickly.\nCar mass: 1300kg\nPeak Motor Torque: 130Nm\nMax Gradient: 1 in 5\nIf you don't make it up the hill, you can click 'Restart'",
	shortIntroText="Set up the car to drive up the hill. Note: a reduction ratio reduces output speed, but increases output torque.",
	passText="Well done! A higher reduction ratio gives the car more torque to get up the steep hill",
	adjustments={
		{
			adjustmentType="motor_driveRatio",
			default=3.7,
			low=1,
			high=9,
		},
	},
	car={
		body="hatchback",
		axles={"basic_wheel","basic_wheel"},
		powertrain="low_power_electric_motor",
	},
	roadSurface={
		x = uphillRoad(160,800)[1],
		y = uphillRoad(160,800)[2]
	},
	scoreMode="x_distance",
	scoreThreshold=400,
	scoreTest=nil,
	endMode="x_distance",
	endCondition=400,
	nextLevel="gears2"
}

	levels:createNormalLevel{
	name = "gears2",
	introText="You are now driving a car along a flat road. Set up the gear ratio to reach 90mph\nThis car has a manual gearbox, so you will have to change gears as you accelerate using the A key",
	shortIntroText="Set up the car to have a high maximum speed",
	passText="Well done! A lower reduction ratio allows the car to reach a higher speed",
	failedText="",
	adjustments={
		{
			adjustmentType="engine_finalDriveRatio",
			default=10,
			low=5,
			high=17,
		},
	},
	car={
		body="old_hatchback",
		axles={"old_wheel","old_wheel"},
		powertrain="Z14XEP",
	},
	roadSurface={
		x = {0,10000},
		y = {0,0}
	},
	scoreMode="maxSpeed",
	scoreThreshold=90/2.25,
	scoreTest=nil,
	endMode="maxSpeed",
	endCondition=90/2.25,
	initialCondition = {carPosition = -2}
}

	levels:createNormalLevel{
	name = "suspension1",
	introText="You are driving a car over a bumpy road. Adjust the damping level to keep suspension travel to less than 0.15m before you reach 60mph",
	shortIntroText="Minimise suspension travel when accelerating to 60mph",
	passText="Well done, higher levels of damping help disappate energy when the car oscillates",
	failureText="Your car bounced too much!\nCan you change the level of damping to absorb those oscillations?",
	adjustments={
		{
			adjustmentType="axle_dampingRate",
			default=0,
			low=0,
			high=4.5e3,
		},
	},
	car={
		body="sedan",
		axles={"basic_wheel","basic_wheel"},
		powertrain="low_power_electric_motor",
	},
	roadSurface={
		x = createSinusoidalRoad(1.235,0.05,2000)[1],
		y = createSinusoidalRoad(1.235,0.05,2000)[2]
	},
	scoreMode="maxSuspensionTravel",
	scoreThreshold=0.15,
	scoreTest="lessThan",
	endMode="maxSpeed",
	endCondition=60/2.25,
	initialCondition = {carPosition = -5},
	nextLevel = "suspension2"
}
	levels:createNormalLevel{
	name = "suspension2",
	introText="You are driving a car over a large bump in the road. Adjust the spring stiffness to keep suspension travel to less than 0.25m as you cross it. In this level, the car will be travelling at 60mph and you should try to keep a steady speed",
	shortIntroText="Minimise suspension travel over the bump",
	passText="Well done, a higher suspension stiffness reduces the suspension travel over bumps,\nhelping the wheels stay in contact with the road",
	failureText="Your car's wheels bounced too much over the bump, meaning they lost contact with the road!\nCan you adjust the suspension stiffness so the wheels move less when they hit the bump?",
	adjustments={
		{
			adjustmentType="axle_springRate",
			default=3e4,
			low=3e4,
			high=1e5,
		},
	},
	car={
		body="sedan",
		axles={"basic_wheel","basic_wheel"},
		powertrain="low_power_electric_motor",
	},
	roadSurface={
		x = {0,100,100.5,101.5,102,1000},
		y = {0,0,0.20,0.20,0,0}
	},
	scoreMode="maxSuspensionTravel",
	scoreThreshold=0.25,
	scoreTest="lessThan",
	endMode="x_distance",
	endCondition=120,
	initialCondition = {carSpeed = 60/2.25},
	nextLevel = "suspension3",
}
	levels:createNormalLevel{
	name = "suspension3",
	introText="You are seting up a car to drive over the same large bump in the road. This time, adjust the spring stiffness to limit the movement of the body to less than 0.2m over the bump. In this level, the car will be travelling at 60mph and you should try to keep a steady speed",
	shortIntroText="Minimise body movement over the bump",
	passText="Well done, a lower suspension stiffness reduces the transmission\nof the bumps into the body, making the ride more comfortable",
	failureText="Your car's body bounced too much over the bump, making the ride very uncomfortable!\nCan you adjust the suspension stiffness so the\nbody moves less when the car hits the bump?",
	adjustments={
		{
			adjustmentType="axle_springRate",
			default=3e4,
			low=3e4,
			high=1e5,
		},
	},
	car={
		body="sedan",
		axles={"basic_wheel","basic_wheel"},
		powertrain="low_power_electric_motor",
	},
	roadSurface={
		x = {0,100,100.5,101.5,102,1000},
		y = {0,0,0.25,0.25,0,0}
	},
	scoreMode="body_max_y_travel",
	scoreThreshold=0.2,
	scoreTest="lessThan",
	endMode="x_distance",
	endCondition=120,
	initialCondition = {carSpeed = 60/2.25},
}

	levels:createNormalLevel{
	name = 4,
	introText="This level is designed to test model performance.",
	shortIntroText="Model Verification Tests",
	car={
		body="unitMass",
		axles={"unitMass_wheel","unitMass_wheel"},
		powertrain="speed_limited_electric_motor",
	},
	--initialCondition = {carSpeed = 80/2.25},
	roadSurface={x={0,5000},y={0,0}},--{x=createSweepRoad(50,0.25,0.05,10,5010)[1],y=createSweepRoad(50,0.25,0.05,10,5010)[2]},
	scoreMode="telemTime",
	scoreThreshold=5,
	scoreTest=nil,
	endMode="telemTime",
	endCondition=5,
}

end