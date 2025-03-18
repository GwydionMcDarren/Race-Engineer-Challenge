game = {}
--Game is a class that contains data about a certain game session.
--It has methods that initiate the game-playing state, as well as game funuctions such as pausing, quitting, and reporting player score to the level.
--Typically it will contain a car, a telemerty specification for that car, in order to collect score data, a backdrop, and a road surface.
--It will usually be defined and containted within a level object


function game:new(g)
	newGame = g or {}
	assert(#g.vehicle >= 1,"Error! No vehicles defined for game object")
	assert(g.backdrop, "Error! No backdrop defined for game object")
	setmetatable(newGame, self)
	self.__index = self
	newGame.pause = false
	newGame.isGame = true
	return newGame
end

function game:start()
	currentGame = self
	win.scene:append(self.backdrop)
	win.scene:append(self.roadNode:tag"roadSurface")
	for index,vehicle in pairs(self.vehicle) do
		win.scene:append(vehicle:createNode())
	end
	--win.scene:append(self.gui)
end

function game:pause()
	currentGame.pause = true
	win.scene:append(self.pauseMenu)
end

function game:unpause()
	currentGame.pause = false
	win.scene:remove(self.pauseMenu)
end

function game:kill()
	currentGame = nil
	win.scene:remove(self.backdrop)
	for index,vehicle in pairs(self.vehicle) do
		win.scene:remove(vehicle)
	end
	win.scene:remove(self.gui)
	--If there is no level structure defined, then the application will be closed at the end of the game
	if currentLevel then
		currentLevel:nextStage(self.scoreState)
	else
		win:close()
	end
end

--We also need to define the gui elements in this class


return game