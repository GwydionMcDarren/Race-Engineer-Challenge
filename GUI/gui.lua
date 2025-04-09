gui = {}

function gui:newElement(e)
	local newGuiNode = am.group()
	newGuiNode = am.translate(e.location)^newGuiNode
	local unit_scaling = e.unit_scaling or 1
	e.readoutType = e.readoutType or "analogue"
	if e.readoutType == "analogue" then
		newGuiNode:append(am.scale(2)^am.sprite("graphics/speedometer.png"))
		newGuiNode:append(am.translate(vec2(0,-20))^am.text((e.label or ""),vec4(1,1,1,1),"center"))
		for i = 0,9 do
			newGuiNode:append(
			am.translate(70*vec2(math.sin(math.pi*3/2*(i/9) - math.pi), math.cos(math.pi*3/2*(i/9) - math.pi)))^
			am.text(string.format("%2.0f",(e.min + (i * (e.max-e.min)/9))))
			)
		end
		newGuiNode:append(am.scale(2)^am.rotate(0):tag("needle_angle")^am.translate(vec2(0,0)):tag("needle_location")^am.sprite("graphics/speedo-needle.png"))
		
		if e.valueIsAbs then newGuiNode.valueIsAbs = true end
		newGuiNode:action(
			function (guiNode)
				local value = guiNode:getTrackingValue()
				if type(value) == "number" then
					value = value*unit_scaling
				end
				if guiNode.valueIsAbs then 
					value = math.abs(value) 
				end
				local angle = -((value - guiNode.min)/(guiNode.max-guiNode.min)) * math.pi*1.5 + (math.pi)
				guiNode"needle_angle".angle = angle
				guiNode"needle_location".position2d = vec2(0,20)--20*vec2(math.sin(angle), math.cos(angle))
			end
		)
	elseif e.readoutType == "digit" then
		newGuiNode:append(am.rect(0,0,60,60,vec4(0.2,0.2,0.2,0.5)))
		newGuiNode:append(am.translate(vec2(30,30))^am.scale(4)^am.text("",vec4(1,1,1,1),"center","center"))
		newGuiNode:action(
			function (guiNode)
				local value = guiNode:getTrackingValue()
				if type(value) == "number" then
					value = value*unit_scaling
				end
				if guiNode.valueIsAbs then 
					value = math.abs(value) 
				end
				local text = tostring(value)
				guiNode"text".text = text
			end
		)
	end
	newGuiNode.trackingVariable = e.trackingVariable
	newGuiNode.max = e.max
	newGuiNode.min = e.min
	newGuiNode.getTrackingValue = gui.getTrackingValue
	if e.scale then
		newGuiNode = am.scale(e.scale)^newGuiNode
	end
	return newGuiNode
end

function gui:getTrackingValue()
	if self.trackingVariable == "front_axle_speed" then
		return currentGame.vehicle[1].axles[1].state.theta[1]
	elseif self.trackingVariable == "front_axle_speed_ground_speed" then
		return currentGame.vehicle[1].axles[1].state.theta[1]*currentGame.vehicle[1].axles[1].params.radius
	elseif self.trackingVariable == "gear" then
		return currentGame.vehicle[1].powertrain[1].params.ratioNames[currentGame.vehicle[1].powertrain[1].gear]
	elseif self.trackingVariable == "powertrain_rotational_Speed" then
		return currentGame.vehicle[1].powertrain[1].state.theta[1]
	elseif self.trackingVariable == "body_speed" then
		return math.sqrt(currentGame.vehicle[1].body.state.x[1]^2+currentGame.vehicle[1].body.state.y[1]^2)
	end
	return 0
end