gui = {}

function gui:newElement(e)
	local newGuiNode = am.group()
	local unit_scaling = e.unit_scaling or 1
	if true then --e.type == "analogue" then support for different types of readout later
		newGuiNode:append(am.scale(2)^am.sprite("graphics/speedometer.png"))
		for i = 0,9 do
			newGuiNode:append(
			am.translate(70*vec2(math.sin(math.pi*3/2*(i/9) - math.pi), math.cos(math.pi*3/2*(i/9) - math.pi)))^
			am.text(string.format("%2.0f",(e.min + (i * (e.max-e.min)/9))))
			)
		end
		newGuiNode:append(am.scale(2)^am.rotate(0):tag("needle_angle")^am.translate(vec2(0,0)):tag("needle_location")^am.sprite("graphics/speedo-needle.png"))
		newGuiNode = am.translate(e.location)^newGuiNode
		newGuiNode:action(
			function (guiNode)
				local value = guiNode:getTrackingValue()*unit_scaling
				if guiNode.valueIsAbs then value = math.abs(value) end
				local angle = -((value - guiNode.min)/(guiNode.max-guiNode.min)) * math.pi*1.5 + (math.pi)
				guiNode"needle_angle".angle = angle
				guiNode"needle_location".position2d = vec2(0,20)--20*vec2(math.sin(angle), math.cos(angle))
			end
		)
	end
	newGuiNode.trackingVariable = e.trackingVariable
	newGuiNode.max = e.max
	newGuiNode.min = e.min
	newGuiNode.getTrackingValue = gui.getTrackingValue
	return newGuiNode
end

function gui:getTrackingValue()
	if self.trackingVariable == "front_axle_speed" then
		return currentGame.vehicle[1].axles[1].state.theta[1]
	elseif self.trackingVariable == "body_speed" then
		return math.sqrt(currentGame.vehicle[1].body.state.x[1]^2+currentGame.vehicle[1].body.state.y[1]^2)
	end
	return 0
end