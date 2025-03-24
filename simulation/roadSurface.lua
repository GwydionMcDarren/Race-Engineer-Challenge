--Creates road surface node, as well as processing the road height at a given X position

--Road data is imported as a pair of tables, one representing node X positions, the other representing node Y positions
roadSurface = {}

function roadSurface:new(X,Y)
	local pixelScale = 50 --number of pixels per meter
	local newSurfaceQuads = am.quads(#X,{"vert","vec2"},"static")
		newSurfaceQuads:add_quad{vert = {
		vec2((X[1]-200)*pixelScale, Y[1]*pixelScale), 
		vec2(X[1]*pixelScale, Y[1]*pixelScale),
		vec2(X[1]*pixelScale,-50*pixelScale),
		vec2((X[1]-200)*pixelScale,-50*pixelScale)},
		}
	for i=1,#X-1 do
		newSurfaceQuads:add_quad{vert = {
		vec2(X[i]*pixelScale, Y[i]*pixelScale), 
		vec2(X[i+1]*pixelScale, Y[i+1]*pixelScale),
		vec2(X[i+1]*pixelScale,-50*pixelScale),
		vec2(X[i]*pixelScale,-50*pixelScale)},
		}
	end
		newSurfaceQuads:add_quad{vert = {
		vec2(X[#X]*pixelScale, Y[#X]*pixelScale), 
		vec2((X[#X]+200)*pixelScale, Y[#X]*pixelScale),
		vec2((X[#X]+200)*pixelScale,-50*pixelScale),
		vec2(X[#X]*pixelScale,-50*pixelScale)},
		}
	local prog = am.program([[
		precision highp float;
		attribute vec2 vert;
		uniform mat4 MV;
		uniform mat4 P;
		void main() {
			gl_Position = P * MV * vec4(vert, 0.0, 1.0);
		}
	]], [[
		precision highp float;
		void main() {
			gl_FragColor = vec4(0.1, 0.1, 0.1, 1.0);
		}
	]])
	local newSurface = am.use_program(prog)^newSurfaceQuads
	newSurface.getHeight = roadSurface.getHeight
	newSurface.x = X
	newSurface.y = Y
	newSurface:tag("roadSurface")
	return newSurface
end

function roadSurface:getHeight(x)
	if x <= self.x[1] then return self.y[1] end
	if x >= self.x[#self.x] then return self.y[#self.y] end
	local highIndex = 1
	for index,xVal in pairs(self.x) do
		if xVal > x then 
			highIndex = index 
			break 
		end
	end
	if not highIndex then 
		highIndex = #self.x
	elseif highIndex == 1 then
		highIndex = 2
	end
	local lowIndex = highIndex - 1
	local lowX = self.x[lowIndex]
	local highX = self.x[highIndex]
	local lowY = self.y[lowIndex]
	local highY = self.y[highIndex]
	return linearInterpolate(lowX,highX,lowY,highY,x)
end

return roadSurface