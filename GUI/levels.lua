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
	if self[self.stage].isGame then
		self[self.stage]:start(data)
	else
		self[self.stage]:initialise(data)
	end
end
--Default sandbox level is also defined

function levels:createNormalLevel(levelData)
	local levelData = levelData or {}
	local levelTable = {}
	levelTable.name = levelData.name or "Unnamed level"
	levelTable[1] = {
	[1] = menu:new{
		am.translate(vec2(0,200))^wrappedtext(levelData.introText or "<Missing introText>",vec4(1,1,1,1),600),
		newButton{
			size=vec2(150,50),
			position=vec2(-75,-200),
			colour=vec4(0,0.9,0.4,1),
			label="Continue",
			labelColour=vec4(1,1,1,1),
			clickFunction = 
				function()
					closeMenuAndContinue()
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
			{
				electricMotorPowertrain:new(75e3*4, 200, 30, {1}, 30),
			}
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
	endCondition = 30,
	scoreMode = "maxSpeed",
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
					level1[3]:close()
				end},
	}
	}
		
	local newLevel = levels:new(levelTable)
	return newLevel
end

return levels