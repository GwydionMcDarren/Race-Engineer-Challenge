--We need a menu class, which has a function to add the menu to the main scene, as well as remove itself from the main scene.
--Should also be able to collect values from all members of the menu and return them for use in the started item

--A game/simulation class is also needed, to initialise the gameplay state.

menu = {}
function menu:new(content)
	menuNode = am.group(content)
	menuNode.isMenu = true
	menuNode.initialise = menu.initialise
	menuNode.close = menu.close
	return menuNode
end

function menu:initialise()
	win.scene:append(self:tag("menu"))
end

function menu:close()
	local menuResults = {}
	for index, child in win.scene"menu":child_pairs() do
		if child.name then
			menuResults[child.name] = child.value
		else
			table.insert(menuResults,child.value)
		end
	end
	win.scene:remove(self)
	if currentLevel then
		currentLevel:nextStage(menuResults)
	else
		return menuResults
	end
end

--Some default menus are defined to give the game structure

mainMenu = menu:new{
--Main title sprite
am.translate(vec2(0,200))^am.sprite("graphics/titleCard.png"),
newButton{size=vec2(150,50),position=vec2(-75,0),colour=vec4(0,0.9,0.4,1),label="Challenges",labelColour=vec4(1,1,1,1), clickFunction = function() mainMenu:close() levelSelect:initialise() end},
newButton{size=vec2(150,50),position=vec2(-75,-75),colour=vec4(0,0.4,0.9,1),label="Sandbox mode",labelColour=vec4(1,1,1,1), clickFunction = function() mainMenu:close() sandbox:start() end},}


levelSelect = menu:new{
	newButton{position=vec2(-300,200),colour=vec4(1,0,0,1),label="Main menu",labelColour=vec4(1,1,1,1), clickFunction = function() levelSelect:close() mainMenu:initialise() end},
	newButton{position=vec2(-100,0),size=vec2(80,80),colour=vec4(0.2,0.5,0.5,1),label="Level 1",labelColour=vec4(1,1,1,1), clickFunction = function() levelSelect:close() level1:startLevel() end},
	newButton{position=vec2(-0,0),size=vec2(80,80),colour=vec4(0.2,0.5,0.5,1),label="Level 2",labelColour=vec4(1,1,1,1), clickFunction = function() levelSelect:close() level2:startLevel() end},
	newButton{position=vec2(100,0),size=vec2(80,80),colour=vec4(0.2,0.5,0.5,1),label="Level 3",labelColour=vec4(1,1,1,1), clickFunction = function() levelSelect:close() level3:startLevel() end},
}
_ = {
newSlider{position=vec2(-300,100),label="Test slider",knobColour = vec4(1,0,0,1),knobSize=8},
newButton{position=vec2(-300,200),colour=vec4(1,0,0,1),label="Return",labelColour=vec4(1,1,1,1), clickFunction = function() levelSelect:close() mainMenu:initialise() end},
newTextEntry{},}