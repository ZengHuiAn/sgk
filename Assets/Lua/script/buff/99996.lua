--宠物称号效果(以及生命恢复和吸血)
local script_data = GetBattleData()

function onStart(target, buff)
    print("信息===========!!!!!!!!!!!!  角色名字",target.name, target.hpp, target.owner.hpp)

    if target.id == 1100420 then
        Common_UnitAddBuff(attacker, buff.attacker, 2100420)
        Common_UnitAddBuff(attacker, target, 2100420)
    end

    if target.id == 1105230 then
        Common_UnitAddBuff(attacker, target, 2105230)
    end

    if target.id == 1101220 then
        Common_UnitAddBuff(attacker, target, 1101201)
        target[1101201] = buff.attacker[1101201]
    end

end

--生命恢复，魔法恢复
function onTick(target, buff)
    -- Common_Heal(target, {target}, 0,  math.floor(target.hpRevert))
end

function attackerAfterHit(target, buff, bullet)  
    --处理吸血                          
    local suckValue = (target.suck + bullet.suck) * bullet.hurt          
    if suckValue > 0 and Hurt_Effect_judge(bullet) then
        --群体效果减半 
        if bullet.skilltype == 3 then
            local finalHeal = suckValue * 0.5;
            Common_Heal(target, {target}, 0, finalHeal)
        else
            local finalHeal = suckValue
            Common_Heal(target, {target}, 0, finalHeal)
        end
    end
end

function attackerBeforeAttack(target, buff, bullet) 
    local rand_hit = ""
    if bullet.cfg or bullet.hit.cfg then
        rand_hit = "hit"..RAND(1,5)
        if bullet.cfg then bullet.cfg.hitpoint = rand_hit end
        if bullet.hit.cfg then bullet.hit.cfg.hitpoint = rand_hit end
    end

    if bullet.hit and bullet.hit.cfg and bullet.hit.cfg.scale and not bullet.hit.cfg.invariable then
        if bullet.target.side == 1 then
            if bullet.target.owner and bullet.target.owner ~= 0 then
                bullet.hit.cfg.scale = bullet.hit.cfg.scale * 0.5
            else
                bullet.hit.cfg.scale = bullet.hit.cfg.scale * 0.7
            end
        else
            if bullet.target.owner and bullet.target.owner ~= 0 then
                bullet.hit.cfg.scale = bullet.hit.cfg.scale * 1.2
            else
                bullet.hit.cfg.scale = bullet.hit.cfg.scale * 1.6
            end
        end
    end
end

