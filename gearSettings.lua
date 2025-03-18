gear = {ratio = 2,
	graphics = am.group{am.rotate(0):tag("gear1")^am.group{am.circle(vec2(0,0),50):tag("gear1graphic"),am.rect(0,1,0,-1,vec4(0,0,0,1)):tag("gear1Marker")},
		am.translate(vec2(100,0))^am.rotate(0):tag("gear2")^am.group{am.circle(vec2(0,0),50):tag("gear2graphic"),am.rect(0,1,0,-1,vec4(0,0,0,1)):tag("gear2Marker")}
	},
}

gear.graphics("gear1graphic").radius = 100 - (100/(gear.ratio + 1))
gear.graphics("gear1Marker").x1 = 100 - (100/(gear.ratio + 1))
gear.graphics("gear2graphic").radius = 100/(gear.ratio + 1)
gear.graphics("gear2Marker").x2 = -100/(gear.ratio + 1)

gear.graphics:action(
	function(gearGraphics)
		local dTheta = 0.01
		gearGraphics("gear1").angle = gearGraphics("gear1").angle + dTheta
		gearGraphics("gear2").angle = gearGraphics("gear2").angle - dTheta * gear.ratio
	end)