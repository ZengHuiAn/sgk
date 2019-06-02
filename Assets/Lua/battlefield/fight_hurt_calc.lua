local RAND = RAND or math.random

local function Hurt_Effect_judge(bullet, per)
	if bullet.Type == 0 or bullet.Type > 4 then
		return false
	end

	if per then
		return RAND(1, 10000) <= per * 10000
	end

	return true
end

local function Hurt(bullet)
    local target = bullet.target
    local attacker = bullet.attacker
    if bullet.hurt_disabled > 0 then
        return 0
    end
    
    if not attacker or attacker == 0 then
        return bullet.trueHurt
    end

    --处理无敌
    if target[7012] > 0 then
        bullet.isPhyResist = 1
        bullet.name_id = 7012
        return -1
    end

    local attacker = bullet.attacker
    local target = bullet.target

    local hurt = bullet.hurt
    local trueHurt = bullet.trueHurt

    --处理暴击
    local Crit = nil
    local temp = RAND()
    local finalCritRate = attacker.critPer + bullet.critPer - target.reduceCritPer
    local finalCritValue = math.max(1, 1.5 + attacker.critValue + bullet.critValue - target.reduceCritValue)
    if finalCritRate >= temp then
        Crit = true
        hurt = hurt * finalCritValue
        bullet.isCrit = 1
        bullet.hurt_number_prefab = "hurt_crit"

        if bullet[300190] > 0 and Hurt_Effect_judge(bullet) then
            bullet.damageAdd = bullet.damageAdd + math.min(target.hp * bullet[300190] / 10000, attacker.ad * (1 + bullet[300191]))
        end

        if bullet[300400] > 0 and Hurt_Effect_judge(bullet) and RAND(1, 10000) <= bullet[300400] then
            bullet.damagePromote = bullet.damagePromote + bullet[300401] / 10000
        end
    end

    local damagePromote = 1 + attacker.damagePromote + bullet.damagePromote

    --对世界boss伤害增加
    if attacker[1041] > 0 and target.npc_type == 4 then
        damagePromote = damagePromote + attacker[1041]/10000
    end

    --处理子弹类型
    local skillsType = {
        [2] = 1023,
        [3] = 1024,
        [4] = 1241,
    }
    if skillsType[bullet.Type] then
        damagePromote = damagePromote + attacker[skillsType[bullet.Type] ] / 10000
    end

    local skillsType_reduce = {
        [2] = 1323,
        [3] = 1324,
        [4] = 1325,
    }

    if skillsType[bullet.Type] then
        bullet.damageReduce = bullet.damageReduce + attacker[skillsType_reduce[bullet.Type] ] / 10000
    end

    local damageReduce = 1 - (1 - target.damageReduce) * (1 - bullet.damageReduce)

    --伤害 = (伤害 * 伤害提升 + 附加伤害) * (1 - 伤害减免)
    hurt = (hurt * damagePromote + attacker.damageAdd + bullet.damageAdd)* (1 - damageReduce)

    --------------------伤害计算---------------------------------

    --实际的防御 = max(0,(防御 - 无视防御) * (1 - 防御穿透比例))
    local ignoreArmor = bullet.ignoreArmor + attacker.ignoreArmor
    local ignoreArmorPer = bullet.ignoreArmorPer + attacker.ignoreArmorPer
    local finalArmor = math.max(0,(target.armor - ignoreArmor ) * (1 - ignoreArmorPer))

    --防御减伤 = 防御/(防御 + 40 + 攻击者等级 * 10)
    --有效伤害 = 伤害 * (40 + 攻击者等级 * 10) / (防御 + 40 + 攻击者等级 * 10)
    local lev_para = 40 + attacker.level * 10
    hurt = hurt * lev_para / (finalArmor + lev_para)

    --标记是否受击时免疫伤害且回血
    local heal_per = 0
    local restrict = 0

    --计算元素克制关系
    local function Element(Promote_key, restrict_key, restricted_key, Reduce_key, heal_key)
        --处理免疫
        if target[Reduce_key] >= 1 then
            bullet.element_resist = 1
            return 0
        end

        --处理回血
        if target[heal_key] > 0 then
            heal_per = heal_per + target[heal_key]
        end

        --克制效果
        local temp = 1
        if restrict_key and target[restrict_key] > 0 then
            temp = temp * 2
            restrict = 1
        end
        if restricted_key and target[restricted_key] > 0 then
            temp = temp * 0.5
            restrict = 2
        end

        --双方提升和减免效果
        local temp2 = (1 + attacker[Promote_key]) * (1 - target[Reduce_key])
        
        hurt = hurt * temp * temp2
    end

    --元素表:当前精通，克制精通，被克制精通
    local route = {
        [1] = {Element, "waterPromote", "fireMaster", "dirtMaster", "waterReduce", "waterHeal"},
        [2] = {Element, "firePromote", "airMaster", "waterMaster", "fireReduce", "fireHeal"},
        [3] = {Element, "dirtPromote", "waterMaster", "airMaster", "dirtReduce", "dirtHeal"},
        [4] = {Element, "airPromote", "dirtMaster", "fireMaster", "airReduce", "airHeal"},
        [5] = {Element, "lightPromote", "darkMaster", nil, "lightReduce", "lightHeal"},
        [6] = {Element, "darkPromote", "lightMaster", nil, "darkReduce", "darkHeal"}
    }
    local keys = route[bullet.Element]
    if keys then
        keys[1](keys[2], keys[3], keys[4], keys[5], keys[6])
    end

    --处理伤害吸收和真实伤害
    hurt = math.floor(math.max(0,hurt - target.damageAbsorb) + trueHurt)

    --伤害上限
    local max_hurt = math.max(target.level, attacker.level) * 2500

    --最终伤害值
    hurt = math.min(hurt,max_hurt)
    bullet.hurt = hurt

    --处理护盾额外伤害
    bullet.shieldHurt = math.floor(bullet.shieldHurt + hurt * (attacker.shieldHurtPer + bullet.shieldHurtPer))

    --处理受击免疫伤害且回血
    if heal_per > 0 then
        bullet.absorb_value = heal_per * hurt
        return 0
    end

    --返回最终伤害值
    return math.min(max_hurt, hurt) , Crit, restrict
end



--------------------------------治疗计算---------------------------------
local function Heal(bullet)
    if bullet.absorb_value > 0 then
        bullet.num_text = "吸收"
        return bullet.absorb_value
    end

    if bullet.heal_enable == 0 then
        return 0
    end

    local attacker = bullet.attacker
    local target = bullet.target

    if target[7011] > 0 then
        return 0
    end

    if not attacker or attacker == 0 or bullet.Type == 24 then
        return bullet.healValue
    end

    --处理治疗提升和重伤
    local healValue = bullet.healValue
    local healPromote = (1 + attacker.healPromote + bullet.healPromote) * (1 - bullet.healReduce)
    local beTreatPromote = (1 + target.beHealPromote) * (0.5^target[7001])

    --处理暴击
    local Crit = nil
    local temp = RAND()
    local finalCritRate = attacker.critPer + bullet.critPer
    local finalCritValue = math.max(1, 1.5 + attacker.critValue + bullet.critValue)
    if finalCritRate >= temp then
        Crit = true
        healValue = healValue * finalCritValue
        bullet.isCrit = 1
        bullet.heal_number_prefab = "health_crit"
    end

    local finalHeal = math.floor(healValue * healPromote * beTreatPromote + bullet.healAdd)
    bullet.finalHeal = finalHeal
    return finalHeal, Crit
end

return {
    Hurt = Hurt,
    Heal = Heal
}