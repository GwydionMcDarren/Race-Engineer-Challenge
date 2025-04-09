levels = {}

--Levels is a class that contains data about a certain level.
--It will typically contain a series of menu and game objects
--Its main function is to mediate flow through different stages of a level (set-up, game play, gameplay review) as well as extract level data from a CSV file if need be.

--It's structure is a 1-indexed table (Lua standard), where each item in the table is either a game or menu object. Other named table keys are used for methods or state.

--Its methods create a level, 

function levels:new(l)
	--Check that level is defined well
	if type(l) ~= "table" then
		error("Incorrect level definition: not a table!", 2)
	else
		for index,levelStage in ipairs(l) do
			--print(levelStage, levelStage.isMenu, levelStage.isGame, index)
			assert(levelStage.isMenu or levelStage.isGame, "Error in definition of level '"..l.name.."': Level definition contains a stage that is neither a menu or a game! (Stage "..index..")")
		end
	end	
	newLevel = l
	newLevel.passFail = l.passFail or function() return 1,nil end --Default passFail function is simply to pass to the next stage
	setmetatable(newLevel, self)
	self.__index = self
	
	return newLevel
end

--startLevel method: attaches the level in question to the "currentLevel" variable, and initiates the first level feature

function levels:startLevel()
	currentLevel = self
	currentLevel.stage = 1	
	if self[1].isGame then
		self[1]:start(self.data)
	else
		self[1]:initialise(self.data)
	end
	self.data = nil
end

--nextStage method: based on the outcome of the current stage, 

function levels:nextStage(data)
	local decisionIndex, playerData = self:passFail(self.stage,data) or 1
	
	self.stage = self.stage + decisionIndex
	self.data = data or {}
	if not self[self.stage] then
		mainMenu:initialise()
		currentLevel = nil
		defineLevels()
		return
	end
	--print(self.stage)
	if self[self.stage].isGame then
		self[self.stage]:start(data)
	else
		self[self.stage]:initialise(data)
	end
end
--Default sandbox level is also defined

function closeMenuAndContinue()
	data = win.scene"menu":close()
	currentLevel:nextStage(data)
end

function closeMenuAndQuit()
	data = win.scene"menu":close()
	mainMenu:initialise()
	currentLevel = nil
	defineLevels()
end

function levels:restart()
	data = win.scene"menu":close()
	currentLevel = nil
	defineLevels()
	storedLevels[self.name]:startLevel()
end

function levels:nextLevel()
	data = win.scene"menu":close()
	local nextLevel = self.nextLevelName
	currentLevel = nil
	defineLevels()
	if storedLevels[nextLevel] then
		storedLevels[nextLevel]:startLevel()
	else
		error("No level defined for "..nextLevel)
	end
end
	

function levels:createNormalLevel(levelData)
	--levelData fields:
		--introText: string, Introducing player to what the problem is in the level.
		--shortIntroText: string, Summary of the intro text.
		--adjustments: table, with tables stored in indicies 1 to n. Each table contains:
			--adjustmentType: string, must be a valid adjustment type
			--default: default value
			--low: lowest allowed value, must be less than default value
			--high: highest allowed value, must be more than lowest and default value
		--car: table, with values stored in "body", "axles", and "powertrain"
			--body: string value from component_library.body
			--axles: table with string entries from component_library.axles
			--powertrain: string value from component_library.powertrain
		--roadSurface: table, with fields x and y
		--scoreMode: string, measure used as the score
		--scoreThreshold: number value
		--scoreTest: string. If not set, level passed when score >= scoreThreshold
		--endMode: string, measure used to end the level
		--endCondition: number value. When this value is exceeded, the level ends.
	local levelData = levelData or {}
	local levelTable = {}
	levelTable.name = levelData.name or "Unnamed level"
	levelTable.nextLevelName = levelData.nextLevel
	levelTable.passFail = function(self, stage, data)
		local data = data or {}
		local decisionIndex = 1
		if stage == 3 then
			--print(data.finalScore, "Final score")
			--print(data.scoreThreshold, "Score threshold")
			if not data.scoreTest then
				if data.finalScore < data.scoreThreshold then
					decisionIndex = 2
				end
			elseif data.scoreTest == "lessThan" then
				if data.finalScore > data.scoreThreshold then
					decisionIndex = 2
				end
			elseif data.scoreTest == "equalTo" then
				if data.finalScore ~= data.scoreThreshold then
					decisionIndex = 2
				end
			end				
		end
		return decisionIndex
	end
	levelTable[1] = menu:new{
		am.translate(vec2(0,200))^wrappedText(levelData.introText or "<Missing introText>",vec4(1,1,1,1),60),
		newButton{
		size=vec2(150,50),
		position=vec2(-75,-200),
		colour=vec4(0,0.9,0.4,1),
		label="Continue",
		labelColour=vec4(1,1,1,1),
		clickFunction = 
			function(self)
				closeMenuAndContinue()
			end
		}
	}
	part2MenuTable = {
		am.translate(vec2(0,200))^wrappedText(levelData.shortIntroText or "<Missing shortIntroText>",vec4(1,1,1,1),60),
		newButton{
			size=vec2(150,50),
			position=vec2(-75,-200),
			colour=vec4(0,0.9,0.4,1),
			label="Continue",
			labelColour=vec4(1,1,1,1),
			clickFunction = 
				function(self)
					closeMenuAndContinue()
				end
			},
		}
	if levelData.adjustments then
		for i,v in pairs(levelData.adjustments) do
			if type(i)=="number" then
				table.insert(part2MenuTable, 
				newSlider{
					position=vec2(-300,100-50*i),
					length=200,
					label=adjustmentNames[v.adjustmentType],
					name=v.adjustmentType,
					knobColour = vec4(1,0,0,1),
					knobSize=20,
					valueLimits = {v.low or 0,v.high or 10},
					defaultValue = v.default or 1,
					}
				)
			end
		end
	end
	levelTable[2] = menu:new(part2MenuTable)
	local axleTable = {}
	--print(levelData.name)
	for i,v in ipairs(levelData.car.axles) do
		table.insert(axleTable,componentLibrary.axles[v])
	end
	levelTable[3] = game:new{
	vehicle = {
		car:new(
			componentLibrary.bodies[levelData.car.body or "hatchback"],
			axleTable,
			componentLibrary.powertrain[levelData.car.powertrain or "low_power_electric_motor"]
		),
	},
	roadNode = roadSurface:new(levelData.roadSurface.x, levelData.roadSurface.y),
	backdrop = {
		sprite = backgroundHillSprite,
		movement = 5,
		offset = vec2(0,0)
	},
	gui = am.group{
		gui:newElement{
			trackingVariable = "powertrain_rotational_Speed",
			unit_scaling = 60/(2*math.pi*1000),
			max = 9,
			min = 0,
			valueIsAbs = true,
			scale = 0.5,
			label = "rpm x1000",
			location = vec2(-200,-200),
		},
		gui:newElement{
			trackingVariable = "front_axle_speed_ground_speed",
			unit_scaling = 2.25,
			max = 90,
			min = 0,
			valueIsAbs = true,
			label = "mph",
			location = vec2(0,-150),
		},
		gui:newElement{
			trackingVariable = "gear",
			readoutType = "digit",
			label = "Gear",
			location = vec2(100,-150),
		},
	},
	menu = menu:new{
		newButton{
			size=vec2(100,20),
			position=vec2(-400,280),
			colour=vec4(1,0.8,0,1),
			label="Restart",
			labelColour=vec4(1,1,1,1),
			clickFunction = 
				function()
					currentGame:restartLevel()
				end
		},
		newButton{
			size=vec2(100,20),
			position=vec2(-400,260),
			colour=vec4(1,0,0,1),
			label="Main Menu",
			labelColour=vec4(1,1,1,1),
			clickFunction = 
				function()
					currentGame:quitLevel()
				end
		},
	},
	endCondition = levelData.endCondition or 600,
	endMode = levelData.endMode or "distance_x",
	scoreTest = levelData.scoreTest,
	scoreMode = levelData.scoreMode or "maxSpeed",
	scoreThreshold = levelData.scoreThreshold or 50,
	initialCondition = levelData.initialCondition or {},
	}
	part4MenuTable = {
		am.rect(-400,-300,400,300,vec4(0,0.5,0.5,1)),
		am.translate(vec2(0,200))^am.text("You passed\n"..(levelData.passText or ""),vec4(1,1,1,1),"center"),
		newButton{
			size=vec2(150,50),
			position=vec2(-225,-25),
			colour=vec4(1,0,0,1),
			label="Quit",
			labelColour=vec4(1,1,1,1),
			clickFunction = 
				function() 
					closeMenuAndQuit()
				end
			},
		newButton{
			size=vec2(150,50),
			position=vec2(-75,-25),
			colour=vec4(0.9,0.4,0.2,1),
			label="Retry",
			labelColour=vec4(1,1,1,1),
			clickFunction = 
				function()
					currentLevel:restart()
				end
		},
	}
	if levelData.nextLevel then
		part4MenuTable[5] = newButton{
			size=vec2(150,50),
			position=vec2(75,-25),
			colour=vec4(0,0.9,0.4,1),
			label="Next Level",
			labelColour=vec4(1,1,1,1),
			clickFunction = 
				function() 
					currentLevel:nextLevel()
				end
		}
	end
	
	levelTable[4] = menu:new(part4MenuTable)
	levelTable[5] = menu:new{
		am.rect(-400,-300,400,300,vec4(0.6,0.3,0,1)),
		am.translate(vec2(0,200))^am.text("You failed\n"..(levelData.failureText or ""),vec4(1,1,1,1),"center"),
		newButton{
			size=vec2(150,50),
			position=vec2(-225,-25),
			colour=vec4(1,0,0,1),
			label="Quit",
			labelColour=vec4(1,1,1,1),
			clickFunction = 
				function() 
					closeMenuAndQuit()
				end
			},
		newButton{
			size=vec2(150,50),
			position=vec2(-75,-25),
			colour=vec4(0.9,0.4,0.2,1),
			label="Retry",
			labelColour=vec4(1,1,1,1),
			clickFunction = 
				function()
					currentLevel:restart()
				end
			},
		}
		
	local newLevel = levels:new(levelTable)
	storedLevels[levelData.name] = newLevel
end

return levels