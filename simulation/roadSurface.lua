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
	local highIndex = #self.x
	local lowIndex = 1
	while highIndex - lowIndex > 1 do
		local guessIndex = math.floor((highIndex+lowIndex)/2)
		if guessIndex == lowIndex then highIndex = guessIndex + 1
		elseif self.x[guessIndex] > x then highIndex = guessIndex
		else lowIndex = guessIndex
		end
	end
	local lowX = self.x[lowIndex]
	local highX = self.x[highIndex]
	local lowY = self.y[lowIndex]
	local highY = self.y[highIndex]
	--print(self.x[lowIndex],self.x[highIndex],lowIndex,highIndex,x)
	return linearInterpolate(lowX,highX,lowY,highY,x)
end

function createWavyRoad(a,b,length)
	local outputX, outputY = {}, {}
	local a = a or 1
	local b = b or 1
	local length = length or 2000
	for i=1,2000,0.5 do
		table.insert(outputX, i)
	end
	outputX[#outputX] = length
	for i=1,2000,0.5 do
		if i<100 or i>400 then
			table.insert(outputY,a)
		elseif i>200 and i<300 then
			table.insert(outputY,0)
		elseif i<=200 then
			local c = (i-100)/(200-100)
			y1 = (1-c)^3
			y2 = 3*(1-c)^2*c
			y3 = 0*3*(1-c)*(c^2)
			y4 = 0*c^3
			y = a*(y1+y2+y3+y4)
			table.insert(outputY, y)--0.4*math.sin(i/(15*math.pi))+1)
		else
			local c = (i-300)/(400-300)
			y1 = 0*(1-c)^3
			y2 = 0*3*(1-c)^2*c
			y3 = 3*(1-c)*(c^2)
			y4 = c^3
			y = a*(y1+y2+y3+y4)
			table.insert(outputY, y)--0.4*math.sin(i/(15*math.pi))+1)
		end
	end
	return {outputX, outputY}
end

function createSinusoidalRoad(period,amplitude,length)
	local outputX, outputY = {}, {}
	local period = period or 1
	local amplitude = amplitude or 0.1
	local length = length or 1000
	for i=1,length,period/10 do
		table.insert(outputX, i)
		table.insert(outputY, amplitude*math.sin(i*2*math.pi/period))
	end
	return {outputX, outputY}
end

function createSweepRoad(startFrequency, endFrequency, amplitude, startX, endX)
	local outputX, outputY = {}, {}
	for i=0,endX,1/(math.max(startFrequency,endFrequency)*10) do
		table.insert(outputX,i)
		local f = startFrequency
		local a = amplitude
		if i < startX then
			a = amplitude*i/startX
		else
			f = ((endFrequency - startFrequency)/(endX-startX)) * (i - startX) + startFrequency
		end
		table.insert(outputY, a*math.sin(math.pi*2*i/f))
	end
	return {outputX,outputY}
end	

function uphillRoad(height,length)
	local X, Y = {}, {}
	local height = height or 20
	local length = length or 2000
	for i=1,length,1 do
		table.insert(X, i)
		local c = i/length
		y1 = 0*(1-c)^3
		y2 = 0*3*(1-c)^2*c
		y3 = 3*(1-c)*(c^2)
		y4 = c^3
		y = height*(y1+y2+y3+y4)
		table.insert(Y, y)
	end
	return {X, Y}
end

return roadSurface