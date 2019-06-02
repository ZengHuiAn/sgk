function onStart(target, buff)
    target.Break_Skill = target.Break_Skill + 1
end

function onEnd(target, buff)
    target.Break_Skill = target.Break_Skill - 1
    local partners = FindAllPartner()
    for _ , v in ipairs(partners) do
        RepeatReomveBuff(v, 2903430, 1)
    end
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
