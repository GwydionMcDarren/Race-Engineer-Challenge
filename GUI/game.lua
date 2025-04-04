game = {}
require '3rd_party.profiler'
--Game is a class that contains data about a certain game session.
--It has methods that initiate the game-playing state, as well as game funuctions such as pausing, quitting, and reporting player score to the level.
--Typically it will contain a car, a telemerty specification for that car, in order to collect score data, a backdrop, and a road surface.
--It will usually be defined and containted within a level object

function game:new(g)
	newGame = g or {}
	assert(#g.vehicle >= 1,"Error! No vehicles defined for game object")
	assert(g.backdrop, "Error! No backdrop defined for game object")
	setmetatable(newGame, self)
	newGame.endCondition = g.endCondition or math.huge
	self.__index = self
	newGame.pause = false
	newGame.isGame = true
	return newGame
end

function game:start(data)
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
		self.mobileScene:append(vehicle:createNode(data))
	end
	self.currentScore = 0
	self.currentProgress = 0
	self.gameTime = 0
	win.scene:append(self:generateBackdrop(self.backdrop.sprite,self.backdrop.movement,self.backdrop.offset):tag("backdrop"))
	win.scene:append(self.mobileScene:tag("mobileScene"))
	win.scene:append(self.gui)
	if self.menu then
		win.scene:append(self.menu:tag("menu"))
	end
	local scoreCounter = am.translate(vec2(-200,200))^am.text("")
	--profiler = newProfiler()
			--profiler:start()
	scoreCounter:action( function (scoreCounter)
		if not self.finished then
			self.currentScore = self:updateScore(self.scoreMode, self.currentScore)
			self.currentProgress = self:updateScore(self.endMode, self.currentProgress)
			self:measureTime()
		end
		self:checkEndCondition(self.currentProgress)
		if win:key_pressed("t") then print(am.frame_time) end
		local str = ""
		--for k,v in pairs(am.perf_stats()) do
		--	str = str..k.." "..v.."\n"
		--end
		str = str.."Score: "..string.format("%.2f",100*self.currentScore/self.scoreThreshold).."%\n"
		str = str.."Progress: "..string.format("%.2f",100*self.currentProgress/self.endCondition).."%"
		scoreCounter"text".text = str
		end
	)
	win.scene:append(scoreCounter:tag("gameMonitor"))
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

function game:triggerEnd()
	local endNode = am.scale(10)^am.text("FINISH",vec4(1,1,1,0))
	endNode.startTime = am.frame_time
	endNode:action(
		function(self)
			local fadeInTime = 2
			local gameKillTime = 5
			local timeSinceTrigger = am.frame_time - self.startTime
			self"text".color = vec4(1,1,1,math.min(timeSinceTrigger/fadeInTime,1))
			if timeSinceTrigger >= fadeInTime + gameKillTime then
				currentGame:kill()
				win.scene:remove(self)
			end
		end
	)
	win.scene:append(endNode)
end

function game:checkEndCondition(currentState)
	if currentState > self.endCondition and self.finished ~= true then
		self:triggerEnd()
		self.finished = true
	end
end

function game:kill()
	--profiler:stop()
	--print("profiler stopped")
    --local outfile = io.open( "profile.txt", "w+" )
    --profiler:report( outfile )
    --outfile:close()
	if TELEMETRY then
		telemOutput = io.open("telemetryData.csv","w")
		for i,v in ipairs(self.vehicle[1].telem) do
			for j,w in ipairs(v) do
				telemOutput:write(w)
				if v[j+1] then
					telemOutput:write(",")
				end
			end
			telemOutput:write("\n")
		end
		telemOutput:close()
	end
	win.scene:remove("mobileScene")
	win.scene:remove("gameMonitor")
	win.scene:remove("menu")
	vehiclesRemain = true
	while win.scene"vehicle" do
		win.scene"vehicle":remove_all()
		iterativeTableDestroy(win.scene"vehicle".parent)
		vehiclesRemain = win.scene:remove("vehicle")
		win.scene:remove_all()
	end
	backdropsRemain = true
	while win.scene"backdrop" do
		backdropsRemain = win.scene:remove("backdrop")
	end
	win.scene:remove(self.gui)
	win.scene:remove_all()
	self.finished = false
	currentGame = nil
	scoreData = {
		finalScore = self.currentScore,
		scoreThreshold = self.scoreThreshold,
		scoreTest = self.scoreTest,
	}
	local finalScore = self.currentScore
	self = nil
	--If there is no level structure defined, then the application will be closed at the end of the game
	if currentLevel then
		currentLevel:nextStage(scoreData)
	else
		return finalScore
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
	return backdropNode:tag("backdrop")
end

function game:updateScore(scoreMode, currentScore)
	scoreMode = scoreMode or "maxDistance"
	currentScore = currentScore or 0
--Game modes:
	--Speed
	--Time
	--Distance
	if scoreMode == "maxSpeed" then
		currentScore = math.max(currentScore, math.sqrt(currentGame.vehicle[1].body.state.x[1]^2+currentGame.vehicle[1].body.state.y[1]^2))
	elseif scoreMode == "maxDistance" then
		currentScore = math.max(currentScore, math.sqrt(currentGame.vehicle[1].body.state.x[0]^2+currentGame.vehicle[1].body.state.y[0]^2))
	elseif scoreMode == "maxSuspensionTravel" then
		for index,axle in currentGame.vehicle[1]:iterateOverAxles() do
			currentScore = math.max(currentScore, math.abs(axle.state.y[0]))
		end
	elseif scoreMode == "time" then
		currentScore = currentScore + am.delta_time
	elseif scoreMode == "x_distance" then
		currentScore = currentGame.vehicle[1].body.state.x[0]
	end
	return currentScore
end

function game:measureTime()
	self.gameTime = self.gameTime + am.delta_time
end

return game