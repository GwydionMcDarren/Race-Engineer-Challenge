function tyreForce(axle,body,normalForce)
	local forceSign = math.sign(body.state.x[1])
	if forceSign == 0 then
		forceSign = math.sign(axle.state.x[1])
	end
	local R = axle.params.radius
	local longitudinalSlip = axle.state.x[1]*R/body.state.x[1] - 1
	if not (longitudinalSlip > 0) and ( not (longitudinalSlip <= 0)) then
		if axle.state.x[1] == 0 and body.state.x[1] == 0 then
			longitudinalSlip = 0
		else
			longitudinalSlip = math.huge -- Set slip to an infinite value
		end
	end
	if longitudinalSlip < -1 then longitudinalSlip = -1 end
	local peakSlip = 0.15
	local slipDirection = math.sign(longitudinalSlip)
	local peakFriction = 1.22 --1.22 p57 of Motor Vehicle Dynamics (Genta, 1997)
	local maxSlipFriction = 1.03 --1.03 p57 of Motor Vehicle Dynamics (Genta, 1997)
	local coefficientOfFriction = 0
	if math.abs(longitudinalSlip) < peakSlip then
		coefficientOfFriction = longitudinalSlip * peakFriction/peakSlip
	elseif slipDirection == -1 then
		coefficientOfFriction = (longitudinalSlip+peakSlip) * (maxSlipFriction-peakFriction)/(1-peakSlip)-peakFriction
	else
		coefficientOfFriction = math.exp(peakSlip-longitudinalSlip) * (peakFriction-maxSlipFriction)+maxSlipFriction
	end	
	local tractiveForce = coefficientOfFriction * normalForce * forceSign
	if DEBUG then
		print("\n\nAxle name:"..axle.name.."\nBody Name:"..body.name.."\nTractive Force:"..tractiveForce.."\nSlip:"..longitudinalSlip.."\nBody Velocity:"..body.state.x[1])
	end
	return tractiveForce
end

function math.sign(x) if x>0 then return 1 elseif x<0 then return -1 else return 0 end end

function rollingResistance(axle,body)
	local R = axle.params.r
	local V = body.state.x[1]
	local c0 = 0
	local c1 = 0
	local resistiveForce = c0 + c1 * V^2
	return resistiveForce
end