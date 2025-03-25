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
		self[1]:start()
	else
		self[1]:initialise()
	end
end

--nextStage method: based on the outcome of the current stage, 

function levels:nextStage(data)
	local decisionIndex, playerData = self:passFail(self.stage,data) or 1
	
	self.stage = self.stage + decisionIndex
	
	if self[self.stage].isGame then
		self[self.stage]:start(playerData)
	else
		self[self.stage]:initialise(playerData)
	end
	self.data = data
	iterativeTablePrint(currentLevel.data)
end
--Default sandbox level is also defined



return levels