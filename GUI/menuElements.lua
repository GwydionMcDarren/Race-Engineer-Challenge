function newButton(buttonData)
	local buttonData = buttonData or {}
	buttonData.position = buttonData.position or vec2(0,0)
	buttonData.size = buttonData.size 
	buttonData.colour = buttonData.colour or vec4(1,1,1,1)
	buttonData.label = buttonData.label or "Unnamed"
	buttonData.name = buttonData.name
	buttonData.labelColour = buttonData.labelColour or vec4(0,0,0,1)
	buttonData.clickFunction = buttonData.clickFunction or function() print("Button "..buttonData.label.." pressed") end
	buttonData.get_value = function (self) return self.value end
	buttonData.get_name = function (self) return self.name end
	
	local textNode = am.text(buttonData.label,buttonData.labelColour,"center","center")
	if not buttonData.size then buttonData.size = vec2(textNode.width+16,textNode.height+16) end
	local buttonNode = am.translate(buttonData.position):tag("buttonLocation")^
	am.group{am.rect(0,0,buttonData.size.x,buttonData.size.y,buttonData.colour):tag("buttonRectangle"),
	am.translate(buttonData.size/2)^textNode,}
	buttonNode.clickFunction = buttonData.clickFunction
	buttonNode:action( function (button)
		local mouseX = win:mouse_position().x
		local mouseY = win:mouse_position().y
		local buttonWidth = buttonData.size.x
		local buttonHeight = buttonData.size.y
		if mouseX > button"buttonLocation".x and mouseY > button"buttonLocation".y
			and mouseX <  button"buttonLocation".x+buttonWidth and mouseY < button"buttonLocation".y+buttonHeight then
				if win:mouse_pressed("left") then
					button:clickFunction()
				end
			end
	end
	)
	buttonNode.get_value = function (self) return buttonData.value end
	buttonNode.set_value = function (self, value) buttonData.value = value end
	buttonNode.get_name = function (self) return buttonData.name end
	buttonNode:tag("button")
	return buttonNode
end

function newTextEntry(textEntryData)
	local textEntryData = textEntryData or {}
	textEntryData.position = textEntryData.position or vec2(0,0)
	textEntryData.size = textEntryData.size 
	textEntryData.colour = textEntryData.colour or vec4(1,1,1,1)
	textEntryData.label = textEntryData.label or "Unnamed"
	textEntryData.labelColour = textEntryData.labelColour or vec4(0,0,0,1)
	local textNode = am.text(textEntryData.label,textEntryData.labelColour)
	if not textEntryData.size then textEntryData.size = vec2(textNode.width+5,textNode.height+5) end
	local textEntryNode = am.translate(textEntryData.position):tag("textEntryLocation")^
	am.group{am.rect(0,0,textEntryData.size.x,textEntryData.size.y,textEntryData.colour):tag("textEntryRectangle"),
	am.translate(textEntryData.size/2)^textNode,}
	textEntryNode.clickFunction = textEntryData.clickFunction
	textEntryNode.focused = false
	textEntryNode:action( function (textEntry)
		if win:mouse_pressed("left") then
			local mouseX = win:mouse_position().x
			local mouseY = win:mouse_position().y
			if mouseX > textEntry"textEntryLocation".x and mouseY > textEntry"textEntryLocation".x
			and mouseX <  textEntry"textEntryLocation".x+textEntry"textEntryRectangle".x2 and mouseY < textEntry"textEntryLocation".y+textEntry"textEntryRectangle".y2 then
				textEntry.focused = true
			else
				textEntry.focused = false
			end
		end
		if textEntry.focused then
			--If a typable key is pressed then add it to the string
			--If backspace is pressed, remove the last letter
			--If left or right arrow keys are pressed, do something else
		end
	end
	)
	return textEntryNode
end

function newSlider(sliderData)

	--Set default data if information is not given
	local sliderData = sliderData or {}
	sliderData.position = sliderData.position or vec2(0,0)
	sliderData.size = sliderData.size 
	sliderData.length = sliderData.length or 64
	sliderData.knobSize = sliderData.knobSize or 16
	sliderData.colour = sliderData.colour or vec4(1,1,1,1)
	sliderData.knobColour = sliderData.knobColour or vec4(0.8,0.8,0.8,1)
	sliderData.barColour = sliderData.barColour or vec4(0.5,0.5,0.5,1)
	sliderData.label = sliderData.label or "Unnamed"
	sliderData.name = sliderData.name
	sliderData.labelColour = sliderData.labelColour or vec4(0,0,0,1)
	sliderData.valueLimits = sliderData.valueLimits or {0,1}
	sliderData.range = sliderData.valueLimits[2] - sliderData.valueLimits[1]
	sliderData.defaultValue = sliderData.defaultValue or sliderData.valueLimits[1]
	sliderData.valueFormat = sliderData.valueFormat or "%.2f"
	sliderData.value = sliderData.defaultValue
	
	local labelNode = am.text(sliderData.label,sliderData.labelColour,"left","center"):tag("textNode")
	local valueNode = am.text(string.format(sliderData.valueFormat,sliderData.defaultValue),sliderData.labelColour,"right","center"):tag("value")
	
	--Calculate the size/padding of the element
	local paddedTextElementWidth = 16 + labelNode.width + 16 + sliderData.knobSize + sliderData.knobSize + 16 + valueNode.width + 16
	local idealWidth = paddedTextElementWidth + sliderData.length
	local leftPadding = 16
	local rightPadding = 16
	local topPadding = 0
	local bottomPadding = 0
	if sliderData.size then
		if sliderData.size.x < paddedTextElementWidth then
			sliderData.size = vec2(paddedTextElementWidth+64,sliderData.size.y)
			sliderData.length = 64
		elseif sliderData.size.x < idealWidth then
			sliderData.length = paddedTextElementWidth - sliderData.size.x
		else
			leftPadding = math.floor((sliderData.size.x - idealWidth + 32)/2)
			rightPadding = math.ceil((sliderData.size.x - idealWidth + 32)/2)
		end
		if sliderData.size.y < 32 + sliderData.knobSize then
			sliderData.size = vec2(sliderData.size.x,32 + sliderData.knobSize)
		end
	else
		sliderData.size = vec2(idealWidth,32+sliderData.knobSize)
	end
	topPadding = math.floor(sliderData.size.y/2)
	bottomPadding = math.ceil(sliderData.size.y/2)	
	
	--Create the graphical objects that make up the slider (descriptive text, 
	local sliderNode = am.translate(sliderData.position):tag("sliderLocation")^
	am.group{
	--Enclosing rectangle
	am.rect(0,0,sliderData.size.x,sliderData.size.y,sliderData.colour),
	--Label text
	am.translate(vec2(leftPadding,topPadding))^labelNode,
	--Main slider bar
	am.line(vec2(labelNode.width+32+sliderData.knobSize,topPadding),vec2(labelNode.width+32+sliderData.length+sliderData.knobSize,topPadding),sliderData.knobSize,sliderData.barColour):tag("sliderBar"),
	--Rounded ends
	am.circle(vec2(labelNode.width+32+sliderData.knobSize,topPadding),sliderData.knobSize/2,sliderData.barColour),
	am.circle(vec2(labelNode.width+32+sliderData.knobSize+sliderData.length,topPadding),sliderData.knobSize/2,sliderData.barColour),
	--Slider knob
	am.circle(vec2(labelNode.width+32,topPadding),sliderData.knobSize,sliderData.knobColour):tag("sliderKnob"),
	am.translate(vec2(sliderData.size.x-rightPadding,topPadding))^valueNode,
	}
	--Assign values to the graphical object
	sliderNode.gripped = false
	sliderNode.valueLimits = sliderData.valueLimits
	sliderNode.range = sliderData.range
	sliderNode.length = sliderData.length 
	sliderNode.width = sliderData.size.x
	
	sliderNode:action( function (slider)
		if win:mouse_pressed("left") then
			if math.distance(win:mouse_position(),(slider"sliderLocation".position2d+slider"sliderKnob".center)) < slider"sliderKnob".radius then
				slider.gripped = true
				slider"sliderKnob".color = colourInvert(slider"sliderKnob".color)
			end
		end
		if slider.gripped then
			slider.value = (win:mouse_position()-(slider"sliderBar".point1+slider"sliderLocation".position2d)).x*(slider.range)/slider.length + slider.valueLimits[1]
			slider.value = math.max(math.min(slider.value,slider.valueLimits[2]),slider.valueLimits[1])
			if not win:mouse_down("left") then slider.gripped=false slider"sliderKnob".color = colourInvert(slider"sliderKnob".color) end
		end
		slider"sliderKnob".center = vec2(slider"sliderBar".point1.x + (slider.value - slider.valueLimits[1])*slider.length/slider.range,
		slider"sliderBar".point1.y)
		slider"value".text = string.format(sliderData.valueFormat,slider.value)
	end
	)
	sliderNode.get_value = function (self) return sliderData.value end
	sliderNode.set_value = function (self, value) sliderData.value = value end
	sliderNode.get_name = function (self) return sliderData.name end
	return sliderNode
end

function newRadioSelect(radioSelectData)
	local radioSelectData = radioSelectData or {}
	radioSelectData.position = radioSelectData.position or vec2(0,0)
	radioSelectData.buttonSize = radioSelectData.buttonSize
	local buttonPositionList = {}
	for index,value in ipairs(radioSelectData.labelList) do
	
	end
		
	local radioSelectNode = am.group()
	local function radioDeselect()
		local buttonNodes = radioSelectNode:all("button")
		for index,buttonNode in ipairs(buttonNodes) do
			buttonNode.value = false
		end
	end
	for index,buttonLabel in ipairs(radioSelectData.labelList) do
		radioSelectNode:append(
			newButton{
				position = buttonPositionList[index],
				size = radioSelectData.buttonSize,
				colour = radioSelectData.colour,
				label = buttonLabel,
				labelColour = radioSelectData.buttonColour,
				clickFunction = function(self)
					radioDeselect()
					self.value = true
					end,
				value = false,
			}
		)
	end
	
	return radioSelectNode
end
	
function liveText(str, colour, firstData)
	local textNode = am.text(str, colour)
	local firstData = firstData or 1
	textNode:action( function (liveTextNode)
		liveTextNode.text = str
		for i,v in ipairs(currentLevel.data) do
			if i >= firstData then
				liveTextNode.text = string.gsub(liveTextNode.text, "##D", v, 1)
			end
		end
	end
	)
	return textNode
end
	
function wrappedText(str, colour, width)
	local stringLength = string.len(str)
	for i=1,math.floor(stringLength/width) do
		local nextSpaceIndex = string.find(str," ",i*width)
		if nextSpaceIndex then
			str = string.sub(str,1,nextSpaceIndex-1).."\n"..string.sub(str,nextSpaceIndex+1,-1)
		end
	end
	local textNode = am.text(str, colour)
	return textNode
end


