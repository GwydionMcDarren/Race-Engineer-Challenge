function tyreForce(axle,body,normalForce)
	local longitudinalSlip = axle.calcs.getSlip
	local peakSlip = 0.015
	local slipDirection = math.sign(longitudinalSlip)
	local longitudinalSlip = math.abs(longitudinalSlip)
	--Positive slip means force acts forward on axle, negative slip means force acts backwards on axle
	local peakFriction = axle.params.peakFriction --1.22 p57 of Motor Vehicle Dynamics (Genta, 1997)
	local maxSlipFriction = axle.params.maxSlipFriction --1.03 p57 of Motor Vehicle Dynamics (Genta, 1997)
	local coefficientOfFriction = 0
	if longitudinalSlip < peakSlip then
		coefficientOfFriction = longitudinalSlip * peakFriction/peakSlip
	else
		coefficientOfFriction = math.exp(peakSlip-longitudinalSlip) * (peakFriction-maxSlipFriction)+maxSlipFriction
	end	
	local tractiveForce = coefficientOfFriction * normalForce * slipDirection
	--local DEBUG = true
	if DEBUG then
		print("\n\nAxle name:"..axle.axleIndex.."\nBody Name:"..body.name.."\nTractive Force:"..tractiveForce.."\nSlip:"..longitudinalSlip)
	end
	return tractiveForce
end


function rollingResistance(axle,body)
	local R = axle.params.r
	local V = body.state.x[1]
	local c0 = 0
	local c1 = 0
	local resistiveForce = c0 + c1 * V^2
	return resistiveForce
end