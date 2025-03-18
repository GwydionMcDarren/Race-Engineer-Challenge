love.graphics.setDefaultFilter( 'nearest' )
car = love.graphics.newImage("graphics/tigra-no-outline.png")
car_outline = love.graphics.newImage("graphics/tigra-outline.png")
wheel_static = love.graphics.newImage("graphics/wheel-colour.png")
wheel_rotating = love.graphics.newImage("graphics/wheel-rotating-colour.png")
wheel_rotating_mask = love.graphics.newImage("graphics/wheel-rotating-alpha.png")
r=0
v=0
love.graphics.setBackgroundColor( 0.1, 0.1, 0.3, 1 )
local mask_shader = love.graphics.newShader[[
   vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords) {
      if (Texel(texture, texture_coords).rgb == vec3(0.0)) {
         // a discarded pixel wont be applied as the stencil.
         discard;
      }
      return vec4(1.0);
   }
]]

local function myStencilFunction()
   love.graphics.setShader(mask_shader)
   love.graphics.draw(wheel_rotating_mask, wx, wy, r, 1, 1, 16, 16)
   love.graphics.setShader()
end


function love.draw()
	love.graphics.draw(car_outline,  50,50,0,4)
	--front wheel
	wx = 50+116+16
	wy = 50+33+16
	love.graphics.draw(wheel_static,wx,wy,0,1,1,16,16)
	love.graphics.stencil(myStencilFunction, "replace", 1, false )
	love.graphics.setStencilTest("greater", 0)
	love.graphics.draw(wheel_rotating,wx,wy,0,1,1,16,16)
	love.graphics.setStencilTest("always", 0)

	--rear wheel
	wx = 50+8+16
	wy = 50+33+16
	love.graphics.draw(wheel_static,wx,wy,0,1,1,16,16)
	love.graphics.stencil(myStencilFunction, "replace", 1, false )
	love.graphics.setStencilTest("greater", 0)
	love.graphics.draw(wheel_rotating,wx,wy,0,1,1,16,16)
	love.graphics.setStencilTest("always", 0)
	--car on top
	love.graphics.draw(car,  50,50,0,4)
end

function love.update(dt)
	r = r+(v*dt)
	while r>math.pi/5 do
		r = r-(math.pi/5)
	end
	while r<-math.pi do
		r = r+(math.pi/5)
	end
	if love.keyboard.isDown( "up" ) then
		v = v+0.01
	end
	if love.keyboard.isDown( "down" ) then
		v = v-0.01
	end
end