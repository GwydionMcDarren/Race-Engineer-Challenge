window = {}
window.isLoaded = true
windowGroup = am.group()

function window:update()
	parentFeature = self
	return function()
	for index,childFeature in ipairs(parentFeature.features) do
		if childFeature.noParentFlag == true then
			childFeature.parent = parentFeature
			childFeature.childIndex = index
			childFeature.noParentFlag = nil
		end
	end
	if self.size.x == 0 then
		for _,childFeature in pairs(parentFeature.features) do
			parentFeature.size.x = max(parentFeature.size.x,childFeature.size.x)
		end
	end
end
end

function window:getLocation()
	local offset = self.location()
	if childIndex then offset = offset + (childOffsets(i) or vec2(0,0)) end
	return offset
end

function window:addNode(target)
	local windowNode = nil
	if self.type == "full-screen" then
		windowNode = self:addFullScreenNode()
	elseif self.type == "resizable" then
		windowNode = self:addResizableNode()
	else
		windowNode = self:addNormalNode()
	end
	
	if target then
		target:append(windowNode)
	else
		return windowNdoe
	end
end

function window:addNormalNode()
	local x1, y1 = self.location.x, self.location.y
	local x2, y2 = x1+self.size.x, y1+self.size.y
	local windowNodes = am.group()
	for _,feature in pairs(self.features) do
		featureNode = feature:addNode()
		if featureNode then
			windowNodes:append(featureNode)
		end
	end
	local node = am.rect(x1,y1,x2,y2,self.colour)^windowNodes
	node.parentFeature = self
	node:action = self:update()
	return node
end

function window:new(w)
	local w = w or {}
	w.location = w.location or vec2(0,0)
	w.size = w.size or vec2(0,0)
	w.colour = w.colour or vec4(0.5,0.5,0.5,1)
	w.features = w.features or {}
	w.verticalPadding = w.padding or 10
	setmetatable(w, self)
	self.__index = self	
	return w
end

--Windows will be a collection of features

--Features we want
--Text boxes/bubbles
	--Formed of frame/border thickness and colour, fill colour, width, height, position, text alignment, text content
window:newTextbox(data)
	
--Buttons (with just text, or text and an image)
--Sliders (with min and max options)
-- +/- boxes
--Text input boxes
--Windows/Frames

windowFeature = {}

--Fucntion to create a new window feature
function windowFeature:new(w,p)
	--Create the table if not provided
	local w = w or {}
	--if w.type == "textbox" then
	--	w = newTextbox(w)
	--end
	setmetatable(w, self)
	self.__index = self
	if p then --If parent has been assigned, then make associations
		--Assign parent window of feature
		w.parent = p
		w.childIndex = #p.features + 1
		--Add feature to parent window
		table.insert(p.features,w)
	else --Otherwise just return self
		w.noParentFlag = true --assign the fact that this window has no parent set. On update, parents will check all children and assign themselves parents as appropriate
		return w
	end
end

function windowFeature:update()
	for _,childFeature in pairs(self.features) do
		if childFeature.noParentFlag == true then
			childFeature.parent = self
			childFeature.noParentFlag = nil
		end
	end
end

function windowFeature:addNode()
	local node = nil
	if self.type == "textbox" then 
		node = self:textboxNode()
	elseif self.type == "box" then
		node = self:boxNode()
	end
	node.parentFeature = self
	return node
end

function windowFeature:getLocation(childIndex)
	local offset = self.location()
	if childIndex then offset = offset + (childOffsets(i) or vec2(0,0)) end
	if self.parent then
		offset = offset + self.parent:getLocaiton()
	end
	return offset
end

function windowFeature:textboxNode()
	local textNode = am.text(self.text, self.colour)
	self.width = textNode.width
	self.height = textNode.height
	local newNode = self:boxNode() ^ textNode
	return newNode
end

function windowFeature:boxNode()
	return am.rect(0,0,self.width,self.height,self.bgcolour)
end
	

function windowFeature:isClicked()
	local offset = self:getLocation() --Function that calls parent feature offsets and accomodates for those too
end

window.windowFeature = windowFeature
return window