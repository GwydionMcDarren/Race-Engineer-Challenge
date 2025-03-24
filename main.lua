--love.graphics.setDefaultFilter( 'nearest' )

UNIT_TESTS = false
DEBUG = false
g = 9.81
num_steps = 3
print(string.rep("#",1e3))
win = am.window{
    title = "RE Challenge",
    width = 800,
    height = 600,
    clear_color = vec4( 0.2,0.7,0.9, 1 ),
    stencil_buffer = true
}

win.scene = am.group()


carSprite = am.sprite("graphics/tigra-no-outline.png")
car_outline = am.sprite("graphics/tigra-outline.png")
wheel_rotating_mask = am.sprite("graphics/wheel-marker.png")
sky = am.sprite("graphics/sky.png")
largeRect = am.group{am.rect(10,-50,40,-55,vec4(0.8,0.8,0.8,1)),am.rect(0,-31,100,0,vec4(0.5,0.5,0.5,1))}
backgroundHillSprite = am.sprite("graphics/largeHills.png")
foregroundHillSprite = am.sprite("graphics/hills.png")
require 'utilityFunctions'

require 'GUI.menuElements'
require 'GUI.game'
require 'GUI.levels'
require 'GUI.menus'
require "GUI.gui"
require 'simulation.roadSurface'
require 'simulation.tyreForce'
require 'simulation.car'
require 'simulation.component_library'
function createWavyRoad(xOrY)
	local output = {}
	if xOrY == "x" then 
		for i=1,2000,1 do
			table.insert(output, i)
		end
	else
		for i=1,2000,1 do
			if i<300 then
				table.insert(output,0 + math.random()*0.05)
			elseif i>500 then
				table.insert(output,20 + math.random()*0.05)
			else
				local c = (i-300)/(500-300)
				y1 = 0*(1-c)^3
				y2 = 0*3*(1-c)^2*c
				y3 = 3*(1-c)*(c^2)
				y4 = c^3
				y = 20*(y1+y2+y3+y4) + math.random()*0.05
			table.insert(output, y)--0.4*math.sin(i/(15*math.pi))+1)
			end
		end
	end
	return output
end
		
sandbox = game:new{
	vehicle = {
		car:new(
			componentLibrary.bodies.sedan,
			{
				axle:new{
					inertia = {y = 10, x=10},
				},
				axle:new{
					inertia = {y = 10, x=10},
				},
			},
			{
				powertrainPart:new{
			
				},
			}
		),
	},
	roadNode = roadSurface:new({0,30000},{0,0}),--createWavyRoad("x"),createWavyRoad("y")),--{0,30,1000,1500,2000,2500,3000},{0,0,100,0,0,0,0}), --
	backdrop = am.rect(0,0,100,5500,vec4(1,0,0,1)),
	gui = gui:newElement{
		trackingVariable = "front_axle_speed",
		unit_scaling = 0.3*2.25,
		max = 135,
		min = 0,
		valueIsAbs = true,
		location = vec2(0,-150),
	}
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
					d, _ = level1[1]:close()
					d[2] = 700
					currentLevel:nextStage(d)
				end
		},
	},	
	[2] = menu:new{
		am.rect(-400,-300,400,300,vec4(0.7,0.7,0.0,1)),
		am.translate(vec2(0,200))^liveText("[Game Placeholder]\nGear ratio selected: ##D",vec4(1,1,1,1)),
		newSlider{
			position=vec2(-150,0),
			length=200,
			label="Score",
			knobColour = vec4(1,0,0,1),
			knobSize=20,
			valueLimits = {0,1000},
			defaultValue = 500,
		},
		newButton{
			size=vec2(150,50),
			position=vec2(-75,-200),
			colour=vec4(0,0.9,0.4,1),
			label="Continue",
			labelColour=vec4(1,1,1,1),
			clickFunction = 
				function() 
					d, _ = level1[2]:close()
					if d[1] >= currentLevel.data[2] then
						d[1] = "passed"
					else
						d[1] = "failed"
					end
					currentLevel:nextStage(d)
				end},
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
					mainMenu:initialise()
				end},
	}
}

backgroundHills = am.scale(1)

function backgroundHills:new(i)
	local node = am.translate(vec2(1000-i,20))^backgroundHillSprite
	node:action( function(hill) hill.x = hill.x - car.components[5].coords.x[1]*am.delta_time
		if hill.x < -1000 then backgroundHills:new(-hill.x-1000) backgroundHills:remove(hill) end
		end)
	backgroundHills:append(node)
end
for i=0,2000,1000 do
backgroundHills:new(i)
end
foregroundHills = am.scale(1)

function foregroundHills:new(i)
	local node = am.translate(vec2(436-i,0))^foregroundHillSprite
	node:action( function(hill) hill.x = hill.x - car.components[5].coords.x[1]*am.delta_time*2
		if hill.x < -500 then foregroundHills:new(-hill.x-500) foregroundHills:remove(hill) end
		end)
	foregroundHills:append(node)
end
for i=0,936,72 do
foregroundHills:new(i)
end


roadStripes = am.group()

function roadStripes:new(i)
	local node = am.translate(vec2(500-i,-10))^largeRect
	node:action( function(stripe) stripe.x = stripe.x - car.components[5].coords.x[1]*am.delta_time*50
		if stripe.x < -500 then roadStripes:new(-stripe.x-500) roadStripes:remove(stripe) end
		end)
	roadStripes:append(node)
end
for i=0,1000,100 do
roadStripes:new(i)
end


dataLine = {}
vData = {}
aData = {}
dataLine[0] = am.group()
for i=1,600 do
	dataLine[i] = {}
	dataLine[i][1] = am.line(vec2(i-300, 0), vec2(i-300, 0), 1, vec4(1,1,1,0.4))
	dataLine[i][2] = am.line(vec2(i-300, 0), vec2(i-300, 0), 1, vec4(0,0,1,0.4))
	dataLine[0]:append(dataLine[i][1])
	dataLine[0]:append(dataLine[i][2])
end
--[[
win.scene = am.group{sky,backgroundHills,
	am.rect(-400,-25-16,400,-300,vec4(0,0,0,1)),
	roadStripes,
	am.scale(5) ^ am.group{car_outline, carSprite,}, 
	am.translate(vec2(-14*5,-25)) ^ am.rotate(0):tag("rear_wheel") ^ wheel_rotating_mask,
	am.translate(vec2(13*5,-25)) ^ am.rotate(0):tag("front_wheel") ^ wheel_rotating_mask,
	am.translate(vec2(-200,200)) ^ am.text("0 m/s","right"):tag("road_speed"),
	newButton{position = vec2(50,50),label="Hello world!",labelColour=vec4(0,0,0,1)},
	newSlider{position = vec2(-50,100),length = 200,knobSize = 20,colour = vec4(0,1,1,1),label = "Test slider",valueLimits = {0,100},defaultValue = 50},
	}]]
--require 'timeStepSolver'
require 'gearSettings'

--[[
win.scene:action()
	function(scene)
		car:solver()
		if win:key_down("lctrl") and win:key_down("c") then win:close() end
		scene"rear_wheel".angle = -car.components[3].coords.x[0]
		scene"front_wheel".angle = -car.components[4].coords.x[0]
		--scene"motor_speed".text = string.format("%2.1f rad/s,\t\t%2.1f Nm",car.components[3].coords.x[1],car.components[1]:netForce(car))
		--scene"rear_wheel_speed".text = string.format("%2.1f rad/s",car.components[4].coords.x[1])--car.components[2].coords.x[1]/car.components[2].constraints[4][2]-car.components[3].coords.x[1])
		peakAccel = math.max(car.components[5].coords.x[2], peakAccel)
		peakSpeed = math.max(car.components[5].coords.x[1], peakSpeed)
		scene"road_speed".text = string.format("%2.1f m/s",car.components[5].coords.x[1])
		local vMax = max(vData)
		table.insert(vData,car.components[5].coords.x[1])
		table.insert(aData,car.components[5].coords.x[2])
		while #vData > 600 do
		table.remove(vData,1)
		end
		while #aData > 600 do
		table.remove(aData,1)
		end
		vMax = math.abs(vMax) or 0
		for i=1,600 do
			dataLine[i][1].point2 = vec2(i-300,(vData[i] or 0)*150/vMax)
			--dataLine[i][2].point1 = dataLine[i][1].point2
			--dataLine[i][2].point2 = dataLine[i][2].point1 + vec2(0,(aData[i] or 0)*150/vMax)
			dataLine[i][2].point1 = vec2(i-301,(aData[i] or 0)*20)
			dataLine[i][2].point2 = vec2(i-300,(aData[i+1] or 0)*20)
			if (aData[i] or 0) >= 0 then
				dataLine[i][2].color = vec4(0,1,0,0.4)
			else
				dataLine[i][2].color = vec4(1,0,0,0.4)
			end
		end
	end
)
]]

mainMenu:initialise()


if UNIT_TESTS then
	local x = {}
	local y = {}
	local maxY = 0
	local minY = 0
	for i=1,100 do
		x[i] = i
		y[i] = (y[i-1] or 0) + math.random() - 0.5
		minY = math.min(y[i],minY)
		maxY = math.max(y[i],maxY)
	end
	print("Final height:",y[#y])
	print("Max height:",maxY)
	print("Min height:",minY)
	win.scene:remove_all()
	local r = roadSurface:new(x,y)
	win.scene:append(am.translate(0,0):tag("scroll")^am.group{r})
	win.scene:action(
		function(scene)
			scene"scroll".x = -am.frame_time*10*50
			scene"scroll".y = -r:getHeight(am.frame_time*10)*50
		end
	)
end