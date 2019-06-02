--行动前 校服陆水银
function onStart(target, buff)
end

local function removePassiveBuff(role)
    local buffs = UnitBuffList(role)
    for _, buff in ipairs(buffs) do
		if buff.id >= 3000000 and buff.id < 4000000 then
            UnitRemoveBuff(buff)
        end
    end
    Common_UnitAddBuff(role, role, 3000005)
end

local effect = nil
--大回合开始前
function onRoundStart(target, buff)
    if not effect then
        if GetFightData().fight_id == 10100101
        or GetFightData().fight_id == 10100100 then
            SkillChangeId(target, 3, 0)
            SkillChangeId(target, 2, 1002)
            SkillChangeId(target, 1, 1001)
            removePassiveBuff(target)
            effect = true
        end
    end

    if GetFightData().fight_id == 10100400 and GetFightData().round == 1  then
        Sleep(0.5)
        AddBattleDialog(1010040001)
    end

    if GetFightData().fight_id == 10100804 and GetFightData().round == 1  then
        Sleep(0.5)
        AddBattleDialog(1010080401)
    end
end

--行动前
function onTick(target, buff)
    if GetFightData().fight_id == 10100100 then
        if GetFightData().round == 1 then
            AddBattleDialog(1101010101)
            Sleep(0.1)
            PlayBattleGuide(7001)
        end

        if GetFightData().round == 2 then
            AddBattleDialog(1101010111)
            Sleep(0.1)
            PlayBattleGuide(7005)
        end

        if GetFightData().round == 3 then
            PlayBattleGuide(7007)
        end
    elseif GetFightData().fight_id == 10100101 then
        if GetFightData().round == 1 then
            AddBattleDialog(1010010101)
            Sleep(0.1)
            PlayBattleGuide(7010)
        end
    elseif GetFightData().fight_id == 10100201 then
        if GetFightData().round == 1 then
            AddBattleDialog(1010020101)
            Sleep(0.1)
            PlayBattleGuide(7027)
        end
    -- elseif GetFightData().fight_id == 10100202 then
    --     if GetFightData().round == 1 then
    --         PlayBattleGuide(7033)
    --     end
    elseif GetFightData().fight_id == 11701 then
        if GetFightData().round == 1 then
            PlayBattleGuide(7021)
        end

    elseif GetFightData().fight_id == 10100200 and not effect then
        SkillChangeId(target, 3, 0)
        SkillChangeId(target, 2, 1002)
        SkillChangeId(target, 1, 1001)

        Sleep(1)
        AddBattleDialog(1010020001) --切钻对话
        Sleep(0.1)

        Common_AddStageEffect(1, 1, 2)
        Sleep(1)

        SkillChangeId(target, 3, 1100030)
        SkillChangeId(target, 2, 1100020)
        SkillChangeId(target, 1, 1100010)

        Sleep(0.5)
        PlayBattleGuide(7016)
        effect = true
    end

    
    if GetFightData().fight_id == 11701 and GetFightData().wave == 2  then
        Sleep(0.5)
        PlayBattleGuide(7022)
    end

    if GetFightData().fight_id == 10100702 and GetFightData().wave == 2 then
        AddBattleDialog(100001)
        Sleep(0.2)
        Common_AddStageEffect(1101620, 1, 1.8)
        Sleep(1.8)
        Common_AddStageEffect(1101620, 2, 1.1)
        Sleep(1.1)
        --[FindAllEnemy()    FindAllPartner()]

        Common_FireBullet(1101620, target, FindAllEnemy(), nil, {
            Duration = 0.1,  	--子弹速度
            Hurt = 10000,    	--伤害
            Type = 3,       		 --子弹类型
            --Attacks_Total = 3,	 --次数
            Element = 7,        --元素类型  
        })
    end
end
