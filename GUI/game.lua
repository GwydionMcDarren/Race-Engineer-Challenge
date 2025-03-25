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
	self.mobileScene = am.translate(vec2(0,0))^am.group()
	self.mobileScene:action( function (mobileScene)
			for index, vehicle in ipairs(self.vehicle) do
				if vehicle.body.state.x[0] > self.roadNode.x[#self.roadNode.x] then vehicle.body.state.x[0] = self.roadNode.x[#self.roadNode.x] end
			end
		end
	)
	--for i=1,self.roadNode.x[#self.roadNode.x],50 do
	--	self.mobileScene:append(am.translate(vec2(i*50,0))^self.backdrop)
	--end
	self.mobileScene:append(self.roadNode:tag"roadSurface")
	for index,vehicle in pairs(self.vehicle) do
		self.mobileScene:append(vehicle:createNode())
	end
	win.scene:append(self:generateBackdrop(self.backdrop.sprite,self.backdrop.movement,self.backdrop.offset))
	win.scene:append(self.mobileScene)
	win.scene:append(self.gui)
	local fpsCounter = am.translate(vec2(-200,200))^am.text("")
	fpsCounter:action( function (fpsNode)
		local str = ""
		for k,v in pairs(am.perf_stats()) do
			str = str..k.." "..v.."\n"
		end
		fpsNode"text".text = str
		end
	)
	win.scene:append(fpsCounter)
end

function game:updateCamera(car)
	self.mobileScene"translate".position2d = vec2(-car.body.state.x[0]*50,-car.body.state.y[0]*50)
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
	win.scene:remove(self.mobileScene)
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

function game:generateBackdrop(sprite,relativeMovement,offset)
	local offset = offset or vec2(0,0)
	local backdropNode = am.group()
	local relativeMovement = relativeMovement or 1
	local coverageRequirement = math.ceil(win.width/am.sprite(sprite).width)+1
	function newBackdropSprite(x)
		local backdropSprite = am.translate(vec2(offset.x-x,offset.y))^am.sprite(sprite)
		local adjustedWidth = coverageRequirement * backdropSprite"sprite".width
		backdropSprite:action(
			function (backdropSpriteNode)
				backdropSpriteNode"translate".x = backdropSpriteNode"translate".x - currentGame.vehicle[1].body.state.x[1]*am.delta_time*50/relativeMovement
				if math.abs(backdropSpriteNode"translate".x) - backdropSprite"sprite".width/2 > win.width/2 then
					if backdropSpriteNode"translate".x > 0 then backdropSpriteNode"translate".x = backdropSpriteNode"translate".x - adjustedWidth
					else backdropSpriteNode"translate".x = backdropSpriteNode"translate".x + adjustedWidth
					end
				end
			end
		)
		return backdropSprite
	end
	for i=0,coverageRequirement-1 do
		backdropNode:append(newBackdropSprite(i*am.sprite(sprite).width))
	end
	return backdropNode
end

return game