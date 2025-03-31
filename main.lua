--love.graphics.setDefaultFilter( 'nearest' )

UNIT_TESTS = false
DEBUG = false
g = 9.81
num_steps = 8

win = am.window{
    title = "RE Challenge",
    width = 800,
    height = 600,
    clear_color = vec4( 0.2,0.7,0.9, 1 ),
    stencil_buffer = true
}

win.scene = am.group()

win.scene:action( function (node)
end
)

function traverseChildren(node)
	for i,j in node:child_pairs() do
		print(j)
		if j:child(1) then
			print("^")
			traverseChildren(j)
			print(";")
		end
	end
end


carSprite = am.sprite("graphics/tigra-no-outline.png")
car_outline = am.sprite("graphics/tigra-outline.png")
wheel_rotating_mask = am.sprite("graphics/wheel-marker.png")
sky = am.sprite("graphics/sky.png")
largeRect = am.group{am.rect(10,-50,40,-55,vec4(0.8,0.8,0.8,1)),am.rect(0,-31,100,0,vec4(0.5,0.5,0.5,1))}
backgroundHillSprite = "graphics/largeHills.png"
foregroundHillSprite = "graphics/hills.png"
require 'utilityFunctions'
require '3rd_party.profiler'

require 'GUI.menuElements'
require 'GUI.game'
require 'GUI.levels'
require 'GUI.menus'
require "GUI.gui"
require 'simulation.roadSurface'
require 'simulation.tyreForce'
require 'simulation.car'
require 'simulation.component_library'
require 'GUI.level_definitions'
function createWavyRoad(xOrY,a,b,length)
	local output = {}
	local a = a or 1
	local b = b or 1
	local length = length or 2000
	if xOrY == "x" then 
		for i=1,2000,0.5 do
			table.insert(output, i)
		end
		output[#output] = length
	else
		for i=1,2000,0.5 do
			if i<100 or i>400 then
				table.insert(output,a)
			elseif i>200 and i<300 then
				table.insert(output,0)
			elseif i<=200 then
				local c = (i-100)/(200-100)
				y1 = (1-c)^3
				y2 = 3*(1-c)^2*c
				y3 = 0*3*(1-c)*(c^2)
				y4 = 0*c^3
				y = a*(y1+y2+y3+y4)
			table.insert(output, y)--0.4*math.sin(i/(15*math.pi))+1)
			else
				local c = (i-300)/(400-300)
				y1 = 0*(1-c)^3
				y2 = 0*3*(1-c)^2*c
				y3 = 3*(1-c)*(c^2)
				y4 = c^3
				y = a*(y1+y2+y3+y4)
			table.insert(output, y)--0.4*math.sin(i/(15*math.pi))+1)
			end
		end
	end
	return output
end


mainMenu:initialise()
defineLevels()

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