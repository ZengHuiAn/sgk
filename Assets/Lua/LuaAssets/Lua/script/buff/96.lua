function onStart(target, buff)
	if buff.cfg and buff.cfg ~= 0 then
		add_buff_parameter(target, buff, 1)
	end
end

function onEnd(target, buff)
	if buff.cfg and buff.cfg ~= 0 then
		add_buff_parameter(target, buff, -1)
	end
end
