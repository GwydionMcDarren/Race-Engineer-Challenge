function max(t)
	assert(type(t)=="table","Input must be a table!")
	local localMax = -1/1e-1000
	for k,v in pairs(t) do
		if type(v) == "number" then
			localMax = math.max(v,localMax)
		end
	end
	return localMax
end

math.sign = function (a)
	if a>1e-4 then return 1
	elseif a<-1e-4 then return -1
	else return 0
	end
end

function wrapString(s,length)
	while word do
		word = 0
		break
	end
end

function colourInvert(colourVector)
	local r,g,b,a = colourVector.r, colourVector.g, colourVector.b, colourVector.a
	r = 1-r
	g = 1-g
	b = 1-b
	return vec4(r,g,b,a)
end

function linearInterpolate(x0,x1,y0,y1,xi)
	z = 2*((xi-x0)/(x1-x0))-1
	yi = y0*(1-z)/2 + y1*(1+z)/2
	return yi
end

function iterativeTablePrint(t,i)
	i = i or 0
	if i> 10 then 
		print("Table of more than 10 levels deep detected, stopping")
		return
	end	
	for k,v in pairs(t) do
		if k~="__index" and k~="parent" then --If __index or parent is set then we get recursive infinite loops
			if type(v) == "table" then
				print(string.rep("\t",i),k..":")
				iterativeTablePrint(v,i+1)
			else
				print(string.rep("\t",i),k,v)
			end
		end
	end
end

function iterativeTableDestroy(t,i)
	i = i or 0
	for k,v in pairs(t) do
		if k~="__index" and k~="parent" then --If __index or parent is set then we get recursive infinite loops
			if type(v) == "table" then
				iterativeTablePrint(v,i+1)
			else
				t[k] = nil
			end
		end
	end
end

function listTable(t,i)
	local i = i or 1
	if t[i] then
		return t[i], listTable(t,i+1)
	else
		return
	end
end

function matrixRMS(m)
	local squareSum, elements = 0, 0
	for i=1,#m do
		if type(m[i]) == "table" then
			for j=1,#m[i] do
				squareSum = squareSum + (m[i][j])^2
				elements = elements + 1
			end
		else
			squareSum = squareSum + (m[i])^2
			elements = elements + 1
		end
	end
	local meanSquare = squareSum/elements
	return math.sqrt(meanSquare)
end
	

if UNIT_TESTS then
	print("-- utilityFunctions.lua unit tests --")
	print("- testing listTable -")
	local testTable = {4, 5, 6, 7}
	print(listTable(testTable))
	print("- testing iterativeTablePrint -")
	local testTable = nil
	local testTable = {F = 6, q = {1, 2, "string"}, function () return 1 end, d = nil}
	iterativeTablePrint(testTable)
	print("- testing math.sign -")
	assert(math.sign(4)==1)
	assert(math.sign(0)==0)
	assert(math.sign(-4)==-1)
	print("-- utilityFunctions.lua tests complete --")
end