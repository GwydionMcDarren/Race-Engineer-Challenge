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
	win.scene:append(am.translate(vec2(250,-275))^self:createTorqueSpeedGraph())
	win.scene:append(am.translate(vec2(250,-150))^self:createLiveSuspensionGraph())
	local inputTelem = am.translate(vec2(-300,-250))^
		am.group{
			am.rect(0,0,20,50,vec4(1,1,1,0.5)),
			am.rect(30,0,50,50,vec4(1,1,1,0.5)),
			am.rect(60,0,80,50,vec4(1,1,1,0.5)),
			am.rect(0,0,20,50,vec4(0,1,0,1)):tag("throttleLevel"),
			am.rect(30,0,50,50,vec4(1,0,0,1)):tag("brakeLevel"),
			--am.rect(60,0,80,50,vec4(0,0,1,1)):tag("clutchLevel"),
		}
	inputTelem.height = 50
	inputTelem:action(
		function (inputTelem)
			inputTelem"throttleLevel".y2 = inputTelem.height*currentGame.vehicle[1].controls.throttle
			inputTelem"brakeLevel".y2 = inputTelem.height*currentGame.vehicle[1].controls.brake
			--inputTelem"clutchLevel".y2 = inputTelem.height*currentGame.vehicle[1].controls.clutch
		end
	)
	win.scene:append(inputTelem)
	if self.menu then
		win.scene:append(self.menu:tag("menu"))
	end
	local scoreCounter = am.translate(vec2(-200,200))^am.text("")
	--profiler = newProfiler()
			--profiler:start()
	scoreCounter:action( function (scoreCounter)
		if not currentGame then return end
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
		if self.scoreMode ~= self.endMode then
			str = str.."Score: "..string.format("%.2f",100*self.currentScore/self.scoreThreshold).."%\n"
		end
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
			local gameKillTime = 2
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

function game:createTorqueSpeedGraph(size)
	local size = size or vec2(100,100)
	local poweredComponent = nil
	local poweredIndex = nil
	for i,v in ipairs(self.vehicle[1].powertrain) do
		if v.componentSubType == "electricMotor" or v.componentSubType == "combustionEngine" then
			poweredComponent = v
			poweredIndex = i
		end
	end
	if not poweredIndex then return am.group() end
	speedValues = {}
	torqueValues = {}
	local maxSpeed = 0
	local maxTorque = 0
	local maxPower = 0
	local i = 0
	while true do
		table.insert(speedValues,i)
		table.insert(torqueValues,poweredComponent:netForce("theta",true,i)[1])
		maxTorque = math.max(poweredComponent:netForce("theta",true,i)[1],maxTorque)
		maxPower = math.max(poweredComponent:netForce("theta",true,i)[1]*i,maxPower)
		i = i+50
		maxSpeed = i
		if torqueValues[#torqueValues] < 0.2*maxTorque then break end
	end
	local getTorque = function (v)
		if v >= speedValues[#speedValues] then return torqueValues[#torqueValues] end
			local highIndex = #speedValues
			local lowIndex = 1
			while highIndex - lowIndex > 1 do
				local guessIndex = math.floor((highIndex+lowIndex)/2)
				if guessIndex == lowIndex then highIndex = guessIndex + 1
				elseif speedValues[guessIndex] > v then highIndex = guessIndex
				else lowIndex = guessIndex
			end
			end
			local lowX = speedValues[lowIndex]
			local highX = speedValues[highIndex]
			local lowY = torqueValues[lowIndex]
			local highY = torqueValues[highIndex]
			local outputTorque = linearInterpolate(lowX,highX,lowY,highY,v)
			return outputTorque
		end
	local graph = am.group{
		am.rect(0,0,size.x,size.y,vec4(0.2,0.2,0.2,0.5)),
		am.line(vec2(0,0),vec2(0,size.y)),
		am.line(vec2(0,0),vec2(size.x,0)),
		am.circle(vec2(0,0),2,vec4(0,0,1,1)):tag("power"),
		am.circle(vec2(0,0),2,vec4(1,0,0,1)):tag("torque"),
		am.translate(vec2(-5,2*size.y/3))^am.text("Power",vec4(0,0,1,1),"right"),
		am.translate(vec2(-5,size.y/3))^am.text("Torque",vec4(1,0,0,1),"right"),
		am.translate(vec2(size.x/2,-10))^am.text("Speed",vec4(1,1,1,1),"center"),
	}
	for i=1,#speedValues-2 do
		graph:append(
			am.line(vec2(speedValues[i]*size.x/maxSpeed,torqueValues[i]*size.y/(maxTorque*1.1)),
			vec2(speedValues[i+1]*size.x/maxSpeed,torqueValues[i+1]*size.y/(maxTorque*1.1)),1,vec4(1,0,0,1))
		)
		graph:append(
			am.line(vec2(speedValues[i]*size.x/maxSpeed,speedValues[i]*torqueValues[i]*size.y/(maxPower*1.1)),
			vec2(speedValues[i+1]*size.x/maxSpeed,speedValues[i+1]*torqueValues[i+1]*size.y/(maxPower*1.1)),1,vec4(0,0,1,1))
		)
	end
	graph:action(
		function (graphNode)
			local speed = math.min(math.abs(currentGame.vehicle[1].powertrain[poweredIndex].state.theta[1]), maxSpeed)
			local xPos = math.min(speed/maxSpeed,1)*size.x
			local torqueYPos = size.y*getTorque(speed)/(maxTorque*1.1)
			local powerYPos = size.y*getTorque(speed)*speed/(maxPower*1.1)
			graphNode"torque".position2d = vec2(xPos, torqueYPos)
			graphNode"power".position2d = vec2(xPos, powerYPos)
		end
	)
	return graph:tag"telemGraph"
end

function game:createLiveSuspensionGraph(size)
	local size=size or vec2(100,100)
	local numAxles = self.vehicle[1].body.params.numAxles
	local cols = {vec4(1,0,0,1),
		vec4(0,0,1,1),
		vec4(0,1,0,1),
		vec4(1,1,0,1),
		vec4(0,1,1,1),
		vec4(1,0,1,1),
		}
	local numSegments = 50
	local graph = am.group{
		am.rect(0,0,size.x,size.y,vec4(0.2,0.2,0.2,0.5)),
		am.line(vec2(0,0),vec2(0,size.y)),
		am.line(vec2(0,size.y/2),vec2(size.x,size.y/2)),
		am.translate(vec2(size.x/2,size.y+10))^am.text("Time",vec4(1,1,1,1),"center"),
		}
	for i,v in self.vehicle[1]:iterateOverAxles() do
		local axleLine = am.group():tag("axleLine")
		for j=1,numSegments do
			axleLine:append(am.line(vec2(size.x-(j-1)*(size.x/numSegments),0),vec2(size.x-j*(size.x/numSegments),0),1,cols[i%#cols]))
		end
		axleLine.parent = v
		axleLine.dataHistory = {}
		graph:append(axleLine)
		graph:append(am.translate(vec2(-5,(numAxles-i+1)*size.y/(numAxles+1)))^am.text("Axle "..tostring(i),cols[i%#cols],"right"))
	end
	graph.scaling = 10
	graph.maxValue = 0
	graph:action(
		function (graphNode)
			graphNode.maxValue = 0
			for i,axleLine in ipairs(graphNode:all"axleLine") do
				local newData = axleLine.parent.state.y[0]
				local newMax = graphNode.maxValue
				table.insert(axleLine.dataHistory,newData)
				if #axleLine.dataHistory > numSegments + 1 then table.remove(axleLine.dataHistory,1) end
				for j, lineSegment in axleLine:child_pairs() do
					graphNode.maxValue = math.max(math.abs(axleLine.dataHistory[#axleLine.dataHistory+1-j] or 0), graphNode.maxValue)
					lineSegment.point1 = vec2(lineSegment.point1.x, ((axleLine.dataHistory[#axleLine.dataHistory+1-j] or 0)*graphNode.scaling)+size.y/2)
					lineSegment.point2 = vec2(lineSegment.point2.x, ((axleLine.dataHistory[#axleLine.dataHistory-j] or 0)*graphNode.scaling)+size.y/2)
				end
			end
			graphNode.scaling = size.y/(2*math.max(graphNode.maxValue,1e-4))
		end
	)
	return graph:tag"telemGraph"
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
	win.scene:remove_all("telemGraph")
	win.scene:remove("menu")
	vehiclesRemain = true
	while win.scene"vehicle" do
		win.scene"vehicle":remove("axle")
		win.scene"vehicle":remove("axleOffset")
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

function game:restartLevel()
	self:kill()
	currentLevel:restart()
end

function game:restartLevel()
	self:kill()
	currentLevel:restart()
end

function game:quitLevel()
	self:kill()
	closeMenuAndQuit()
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
		if not self.scoreOffset then self.scoreOffset = {} end
		if self.gameTime > 1 and self.gameTime < 2 then self.offsetSamples = (self.offsetSamples or 0) + 1 end
		for index,axle in currentGame.vehicle[1]:iterateOverAxles() do
			if self.gameTime > 1 then
				if not self.scoreOffset[index] then
					self.scoreOffset[index] = axle.state.y[0]
				end
				if self.gameTime < 2 then
					self.scoreOffset[index] = (self.scoreOffset[index]*(self.offsetSamples-1) + axle.state.y[0])/self.offsetSamples
				end
				currentScore = math.max(currentScore, math.abs(axle.state.y[0]-self.scoreOffset[index]))
			end
		end
	elseif scoreMode == "body_max_y_travel" then
		if self.gameTime > 1 then
			if not self.scoreOffset then
				self.scoreOffset = currentGame.vehicle[1].body.state.y[0]
			end
			if self.gameTime < 2 then
				self.offsetSamples = (self.offsetSamples or 0) + 1
				self.scoreOffset = (self.scoreOffset*(self.offsetSamples-1) + currentGame.vehicle[1].body.state.y[0])/self.offsetSamples
			end
			currentScore = math.max(currentScore, math.abs(currentGame.vehicle[1].body.state.y[0]-self.scoreOffset))
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