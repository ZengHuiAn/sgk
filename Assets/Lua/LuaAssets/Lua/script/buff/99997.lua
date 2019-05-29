--[被动类效果]
-------------------------------------------------
function onStart(target, buff)
    buff.Effect_targetAfterHit_list = {}
    buff.Effect_attackerAfterHit_list = {}
    buff.Effect_onTick_list = {}
    buff.Effect_onRoundEnd_list = {}
    buff.Effect_onEnd_list = {}

    buff.tick_para_list = {}

    buff.Effect_onTick_hurt = {}
    buff.Effect_onTick_heal = {}

    buff.special_buffs = {}
    buff.last_attackers = {}
end

-------------------------------------------------
function targetWillHit(target, buff, bullet)
    --[免死]
    if target[7220] > 0 then
        if bullet.hurt_final_value > target.hp and target.hp > 1 then
            bullet.hurt_final_value = math.ceil(target.hp - 1)
            bullet.name_id = 2101530
        elseif bullet.hurt_final_value > target.hp and target.hp <= 1 then
            bullet.hurt_final_value = -1
            bullet.name_id = 2101530
        end
    end
end
------------------------------------------------
function attackerBeforeHit(target, buff, bullet)
    --丢失
    if target[7004] > 0 and Hurt_Effect_judge(bullet) and RAND(1,10000) <= target[7004] then
        UnitShowNumber(bullet.target, "", 3, "未命中")
        BulletDisabled(bullet)
    end
end
-------------------------------------------------
function targetFilter(target, buff, bullet)
    --闪避
    if target[7014] > 0 and Hurt_Effect_judge(bullet) and RAND(1,10000) <= target[7014] then
        UnitShowNumber(target, "", 3, "未命中")
        BulletDisabled(bullet)
    end
end
-------------------------------------------------
function targetAfterHit(target, buff, bullet)    
    --其他角色监听受击后的回调
    for _, fun in pairs(buff.Effect_targetAfterHit_list) do
        fun(bullet)
    end

    --保存最后一个攻击自己的敌人
    if target[7015] > 0 and Hurt_Effect_judge(bullet) and bullet.attacker.side ~= target.side then
        buff.last_attackers[bullet.attacker.Force.pid] = bullet.attacker.uuid
    end
end
-------------------------------------------------
function onTick(target, buff)
    if target[7008] > 0 then
        Common_UnitConsumeActPoint(attacker, 1)
        Common_Sleep(target, 0.5)
    end

    Common_ChangeEp(target, math.floor(target.epRevert))

    --其他角色监听行动前的回调
    for _, fun in pairs(buff.Effect_onTick_list) do
        fun(bullet)
    end

    --[持续伤害效果]
    for _, fun in pairs(buff.Effect_onTick_hurt) do
        fun() 
        Common_Sleep(target, 0.1)
    end
    
    --[持续恢复效果]
    Common_Heal(target, {target}, 0, target.hpRevert)
    for _, fun in pairs(buff.Effect_onTick_heal) do
        fun() 
        Common_Sleep(target, 0.1)
    end
end

function onPostTick(target, buff)
    target.focus_pid = 0
end

function attackerAfterHit(target, buff, bullet) 
    --处理吸血                          
    local suckValue = (target.suck + bullet.suck) * bullet.hurt_final_value          
    if suckValue > 0 and Hurt_Effect_judge(bullet) then
        --群体效果减半 
        if bullet.Type == 3 then
            local finalHeal = suckValue * 0.5;
            Common_Heal(target, {target}, 0, finalHeal)
        else
            local finalHeal = suckValue
            Common_Heal(target, {target}, 0, finalHeal)
        end
    end

    if bullet.ChuanCi > 0 and Hurt_Effect_judge(bullet) then
        local Hurt = bullet.hurt_final_value * bullet.ChuanCi

        if bullet.target.owner and bullet.target.owner ~= 0 then
            Common_Hurt(attacker, {bullet.target}, 0, Hurt)
        else
            local pets = UnitPetList(bullet.target)
            Common_Hurt(attacker, {pets}, 0, Hurt)
        end
    end

    for _, fun in pairs(buff.Effect_attackerAfterHit_list) do
        fun(bullet)
    end
end

function onRoundEnd(target, buff)
    target.buff_event_120 = 0
    --[[
        for _, fun in pairs(buff.Effect_onRoundEnd_list) do
            fun() 
        end
    --]]
end

function onEnd(target, buff)
    --其他角色监听的回调
    for _, fun in pairs(buff.Effect_onEnd_list) do
        fun()
    end
end