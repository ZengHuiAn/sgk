--死亡时 复活
function onStart(target, buff)
	add_buff_parameter(target, buff, 1)
end

function onPostTick(target, buff)
	if buff.not_go_round > 0 then
		return
	end

	buff.remaining_round = buff.remaining_round - 1;
	if buff.remaining_round <= 0 then
		UnitRemoveBuff(buff);
	end	
end

local function do_relive(target, id, id2)
	local pos = target.Position.pos
    Run(function ()
        Sleep(0.3)
		AddEnemyInWave(id, target.Position.pos)
    end)
end

function onEnd(target, buff)
	local id = buff.cfg_property[2] and buff.cfg_property[2]
	if not id then return end

	local need_id = buff.cfg_property[1] and buff.cfg_property[1]
	if need_id then
		local partners = FindAllPartner()
		for _, v in ipairs(partners) do
			if v.id == need_id then
				UnitPlay(v, "skill", {speed = 1});
				Common_Sleep(0.2)
				Common_FireBullet(3908410, v, {v}, nil, {Type = 30})
				do_relive(target, id, buff.id)
				break
			end
		end
	else
		do_relive(target, id)
	end

	add_buff_parameter(target, buff, -1)
end
