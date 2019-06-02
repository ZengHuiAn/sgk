local is_Common_Sleep = 0
local script_data = GetBattleData()

function onStart(target, buff)
    attacker.round_count = 0
end

function onRoundStart(target, buff)
    attacker.round_count = attacker.round_count + 1   
    --[[
    if attacker.Show_Monster_info == 1 and attacker.round_count == 1 and attacker.side == 2 then
        ShowMonsterInfo()        
        Common_Sleep(attacker, 0.1)
    end
    --]]
end

--[[
local element_list = {
    [1] = {name = "水系"},
    [2] = {name = "火系"},
    [3] = {name = "土系"},
    [4] = {name = "风系"},
    [5] = {name = "光系"},
    [6] = {name = "暗系"},
}
--]]

--受到反弹伤害 延迟回合结束 防止伤害飘字跑偏
function targetAfterHit(target, buff, bullet)    
    if Hurt_Effect_judge(bullet) then
        if target.Aciton_Sing ~= 1 then
            UnitPlay(target, "hit", {speed = 1})
        end
    end
end    

function onPostTick(target, buff)
    target.action_count = target.round_count
end

function attackerBeforeHit(target, buff, bullet) 
    --[[
    local rand_hit = ""
    if bullet.cfg or bullet.hit.cfg then
        rand_hit = "hit"..RAND(1,5)
        if bullet.cfg then bullet.cfg.hitpoint = rand_hit end
        if bullet.hit.cfg and bullet.hit.cfg.hitpoint ~= "root" then 
            bullet.hit.cfg.hitpoint = rand_hit 
        end
    end
    --]]

    if attacker.beat_back > 0 and bullet.hurt_disabled == 0 then
        bullet.num_text = "反击"
    end
end

