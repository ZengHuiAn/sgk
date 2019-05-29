--加敌人属性x倍， x为buff。id对应属性
function onStart(target, buff)
	add_buff_parameter(target, buff, 1)
end

function onEnd(target, buff)
	add_buff_parameter(target, buff, -1)
end

local total_round = 0
function onRoundStart(target, buff)
	total_round = total_round + 1
	local round = buff.cfg_property[1] and buff.cfg_property[1] or 0

	if round ~= total_round then
		return
	end

	local skill_id = buff.cfg_property[2] and buff.cfg_property[2]
	if not skill_id then
		return
	end

    for i = 4, 1,-1 do
        local skill = SkillGetInfo(target, i)
        if skill then
            SkillChangeId(target, i, skill_id)
        end
    end
end
