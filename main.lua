--love.graphics.setDefaultFilter( 'nearest' )

UNIT_TESTS = false
DEBUG = false
TELEMETRY = true
g = 9.81
airDensity = 1.3 --kg/m^3
frontalArea = 2.29 --m^2
num_steps = 4
trueTimeStep = false --uses time_step instead of am.frame_delta/num_steps
time_step = 0.005 --s

win = am.window{
    title = "RE Challenge",
    width = 1200,
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