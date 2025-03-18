function engine:plotTorque(speed_lo,speed_hi,torque_lo,torque_hi,n_speed,n_torque)
	local a,p = {},{}
	local speed = speed_lo
	local d_speed = (speed_hi-speed_lo)/n_speed
	local d_torque = (torque_hi-torque_lo)/n_torque
	car.input.accelerator = 1
	local peakTorque = torque_lo
	local peakPower = torque_lo
	for i = 1,n_speed do
		self.speed = speed
		a[i] = self:torqueUpdate()
		p[i] = a[i]*self.speed
		peakTorque = math.max(peakTorque,a[i])
		peakPower = math.max(peakPower,p[i])
		speed = speed+d_speed
	end
	powerRatio = peakTorque/peakPower
	strs = {}
	str_blank = " "
	for i=0,n_torque do
		strs[i] = {}
		if i%5==0 then
			strs[i][1] = string.format("%3d Nm |", math.floor(torque_lo+(i+1)*d_torque))
			str_blank = "-"	
		else
			strs[i][1] = "       |"
			str_blank = " "
		end
		for j=1,n_speed do
			strs[i][j+1] = str_blank
			if a[j] >= torque_lo + i*d_torque then
				if a[j] < torque_lo + (i+1)*d_torque then
					strs[i][j+1] = "x"
				end
			end
			if p[j]*powerRatio >= torque_lo + i*d_torque then
				if p[j]*powerRatio < torque_lo + (i+1)*d_torque then
					strs[i][j+1] = "o"
				end
			end
		end
		if i%5==0 then
			strs[i][#strs[i]+1] = string.format("| %3d kW", math.floor(torque_lo+(i+1)*d_torque/powerRatio/1000))
		else
			strs[i][#strs[i]+1] = "|    "
		end
	end
	strs[-1] = {string.rep(" ",8)..string.rep("-",n_speed+1)}
	strs[-2] = {"         "}
	for i=2,math.floor(n_speed/7) do
		strs[-2][i] = string.format("| %4d ", math.floor((speed_lo+d_speed*7*(i-2))*60/(2*math.pi)))
	end
	for i=n_torque,-2,-1 do
		for j = 1,#strs[i] do
			io.write(strs[i][j])
		end
		io.write("\n")
	end
end


engine:plotTorque(0,700,0,126,220,50)