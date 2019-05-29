--[子弹效果]
-------------------------------------------------
local effect_300250 = nil
function onTick(target, buff, bullet)
    effect_300250 = nil
end

local master_list_2 = {
	airMaster   = 1861,
	dirtMaster  = 1862,
	waterMaster = 1863,
	fireMaster  = 1864,
	lightMaster = 1865,
	darkMaster  = 1866,
}

function attackerBeforeHit(target, buff, bullet)
    if master_list_2[GetRoleMaster(bullet.target)] then
        local k = master_list_2[GetRoleMaster(bullet.target)]
        bullet.damagePromote = bullet.damagePromote + attacker[k]/10000 + attacker[1867]/10000
    end
    --[对嘲讽目标造成额外伤害]
    if bullet[300030] > 0 and Hurt_Effect_judge(bullet) and bullet.target[7000] > 0 then
        bullet.damagePromote = bullet.damagePromote + bullet[300030] / 10000
    end

    --[造成伤害时附加x%目标最大生命的伤害（最大为自身攻击2倍）]
    if bullet[300040] > 0 and Hurt_Effect_judge(bullet) then
        bullet.damageAdd = bullet.damageAdd + math.min(target.ad * (bullet[300041] > 0 and bullet[300041] or 2), bullet.target.hpp * bullet[300040] / 10000)
    end

    --[对冰冻目标造成额外伤害]
    if bullet[300050] > 0 and Hurt_Effect_judge(bullet) and bullet.target[7009] > 0 then
        bullet.damagePromote = bullet.damagePromote + bullet[300050] / 10000
    end
    
    --[对生命值低于30%的，造成额外伤害]
    if bullet[300100] > 0 and Hurt_Effect_judge(bullet) and bullet.target.hp/bullet.target.hpp <= 0.3 then
        bullet.damagePromote = bullet.damagePromote + bullet[300100] / 10000
    end    

    --[对生命值低于40%的，造成额外伤害]
    if bullet[300110] > 0 and Hurt_Effect_judge(bullet) and bullet.target.hp/bullet.target.hpp <= 0.4 then
        bullet.damagePromote = bullet.damagePromote + bullet[300110] / 10000
    end    
    
    --[攻击时造成x%防御值的额外伤害]
    if bullet[300130] > 0 and Hurt_Effect_judge(bullet) then
        bullet.damageAdd = bullet.damageAdd + bullet[300130] / 10000 * target.armor
    end    
    
    --[治疗效果对生命低于40%的友军提高x%]
    if bullet[300150] > 0 and Heal_Effect_judge(bullet) and bullet.target.hp/bullet.target.hpp <= 0.4 then
        bullet.healPromote = bullet.healPromote + bullet[300150] / 10000
    end    

    --[治疗效果对生命低于40%的友军提高x%]
    if bullet[300156] > 0 and Heal_Effect_judge(bullet) and bullet.target.hp/bullet.target.hpp <= 0.6 then
        bullet.healPromote = bullet.healPromote + bullet[300156] / 10000
    end    
    
    --[我方人数少于敌人，附加自身生命值x%的伤害]
    if bullet[300270] > 0 and Hurt_Effect_judge(bullet) then
        if #FindAllPartner() < #FindAllEnemy() then
            bullet.damageAdd = bullet.damageAdd + bullet[300270] / 10000 * target.hpp
        end
    end

    --[目标血量越低伤害越高，最多x%的伤害]
    if bullet[300460] > 0 and Hurt_Effect_judge(bullet) then
        bullet.damagePromote = bullet.damagePromote + (bullet[300460] / 10000 - 1) * (1 - bullet.target.hp / bullet.target.hpp)
    end

    --[生命值高于50%时，增加x%的暴击率]
    if bullet[300360] > 0 and Hurt_Effect_judge(bullet) and target.hp/target.hpp > 0.5 then
        bullet.critPer = bullet.critPer + bullet[300360]/10000 
    end
    
    --[生命值低于50%时，增加x%的吸血]
    if bullet[300370] > 0 and Hurt_Effect_judge(bullet) and target.hp/target.hpp <= 0.5 then
        bullet.suck = bullet.suck + bullet[300370]/10000 
    end
    
    --[造成伤害时附加x%目标当前生命的伤害（最大为自身攻击2倍）]
    if bullet[300390] > 0 and Hurt_Effect_judge(bullet) then
        bullet.damageAdd = bullet.damageAdd + math.min(target.ad * (bullet[300391] > 0 and bullet[300391] or 2), bullet.target.hp * bullet[300390] / 10000)
    end
    
    --[对生命值高于60%的角色伤害提升x%]
    if bullet[300410] > 0 and Hurt_Effect_judge(bullet) and bullet.target.hp/bullet.target.hpp >= 0.6 then
        bullet.damagePromote = bullet.damagePromote + bullet[300410] / 10000
    end    

    --[造成伤害时有50%的概率附加x%攻击的伤害]
    if bullet[300420] > 0 and Hurt_Effect_judge(bullet) and RAND(1, 10000) <= 5000 then
        bullet.damageAdd = bullet.damageAdd + bullet[300420] / 10000 * target.ad
    end    

    --[生命值高于60%时，伤害提升x%]
    if bullet[300430] > 0 and Hurt_Effect_judge(bullet) and target.hp/target.hpp >= 0.6 then
        bullet.damagePromote = bullet.damagePromote + bullet[300430] / 10000 
    end    

    --[生命值低于40%时，伤害提升x%]
    if bullet[300440] > 0 and Hurt_Effect_judge(bullet) and target.hp/target.hpp < 0.4 then
        bullet.damagePromote = bullet.damagePromote + bullet[300440] / 10000 
    end    
    
    --[生命比例高于自己 造成额外伤害]
    if bullet[300490] > 0 and Hurt_Effect_judge(bullet) and target.hp/target.hpp < bullet.target.hp/bullet.target.hpp then
        bullet.damagePromote = bullet.damagePromote + bullet[300490] / 10000 
    end

    --[生命比例低于自己 造成额外伤害]
    if bullet[300500] > 0 and Hurt_Effect_judge(bullet) and target.hp/target.hpp > bullet.target.hp/bullet.target.hpp then
        bullet.damagePromote = bullet.damagePromote + bullet[300500] / 10000 
    end
end
-------------------------------------------------
function BulletFilter_targetFilter( ... )
    -- body
end
-------------------------------------------------
function attackerAfterHit(target, buff, bullet)
    --[击杀固定恢复]
    if Hurt_Effect_judge(bullet) and bullet.target.owner == 0 and bullet.target.hp <= 0 then
        Common_ChangeEp(target, 20, "击杀回能")
    end

    --[治疗效果x%的概率移除目标1个减益效果]
    if bullet[300230] > 0 and Heal_Effect_judge(bullet) and RAND(1, 10000) <= bullet[300230] then
        local remove_count = Common_RemoveBuffRandom(bullet.target, {[1] = true, [3] = true}, 1 + bullet[300232])
        if remove_count == 0 then
            bullet.healPromote = bullet.healPromote + bullet[300231] / 10000
        end
    end  

    --[攻击有x%的概率移除一个增益效果]
    if bullet[300240] > 0 and Hurt_Effect_judge(bullet) and RAND(1, 10000) <= bullet[300240] then
        local remove_count = Common_RemoveBuffRandom(bullet.target, {[2] = true}, 1 + bullet[300242])
        if remove_count == 0 then
            bullet.damagePromote = bullet.damagePromote + bullet[300241] / 10000
        end
    end  
    
    --[伤害对方时，恢复血量最低的1名队友，x%伤害的生命值]
    if bullet[300280] > 0 and Hurt_Effect_judge(bullet) then
        local list = SortWithHpPer(FindAllPartner())
        for i = 1,1 + bullet[300281],1 do
            if list[i] then
                Common_FireBullet(1100310, target, {list[i]}, nil,
                 {Type = 20, Hurt = bullet.hurt_final_value * bullet[300280]/10000, Duration = 0, Interval = 0, name_id = bullet.name_id})
            else
                break
            end
        end
    end
    
    --[攻击后，概率冰冻对手]
    if bullet[300020] > 0 and Hurt_Effect_judge(bullet) then
        if bullet.target[7009] <= 0 then
            Common_UnitAddBuff(attacker, bullet.target, 7009, bullet[300020] / 10000)
        else
            --[如果对手冰冻，恢复能量]
            if bullet[300022] > 0 then
                Common_ChangeEp(target, bullet[300022], true)
            end
            --[如果对手已经冻结，概率延长1回合时间]
            if bullet[300021] > 0 and RAND(1, 10000) < bullet[300021] then
                local buff = Common_FindBuff(bullet.target, 7009)[1]
                buff.remaining_round = buff.remaining_round + 1
            end
        end
    end    

    --[如果目标未行动，概率降低30点速度，持续1回合]
    if bullet[300060] > 0 
    and Hurt_Effect_judge(bullet) 
    and bullet.target.action_count ~= bullet.target.round_count
    then
        Common_UnitAddBuff(attacker, bullet.target, 7010, bullet[300060] / 10000, {round = 1 + bullet[300062], speed = -20})
    end    

    --[概率降低10点速度，持续2回合]
    if bullet[300070] > 0 and Hurt_Effect_judge(bullet) then
        Common_UnitAddBuff(attacker, bullet.target, 7010, bullet[300070] / 10000, {round = 2 + bullet[300071]})
    end    

    --[攻击后，概率重伤对手2回合]
    if bullet[300080] > 0 and Hurt_Effect_judge(bullet) then
        Common_UnitAddBuff(attacker, bullet.target, 7001, bullet[300080] / 10000)
    end    
    
    --[攻击时有概率造成麻痹一回合]
    if bullet[300090] > 0 and Hurt_Effect_judge(bullet) then
        Common_UnitAddBuff(attacker, bullet.target, 7002, bullet[300090] / 10000)
    end    
    
    --[攻击时有概率降低对手25点能量]
    if bullet[300120] > 0 and Hurt_Effect_judge(bullet) and RAND(1, 10000) <= bullet[300120] then
        Common_ChangeEp(bullet.target, -(25 + bullet[300121]), true)
    end    

    --[攻击时有x%概率封印对手一回合]
    if bullet[300160] > 0 and Hurt_Effect_judge(bullet) then
        Common_UnitAddBuff(attacker, bullet.target, 7003, bullet[300160] / 10000)
    end    

    --[攻击时x%概率造成2回合灼烧]
    if bullet[300170] > 0 and Hurt_Effect_judge(bullet) then
        Common_UnitAddBuff(attacker, bullet.target, 7007, bullet[300170] / 10000)
    end   

    --[击杀获得对手的能量]
    if bullet[300180] > 0 and Hurt_Effect_judge(bullet) and bullet.target.hp <= 0 then
        Common_ChangeEp(target, bullet.target.ep, true)
    end  
   
    --[攻击时x%概率造成晕眩]
    if bullet[300200] > 0 and Hurt_Effect_judge(bullet) then
        Common_UnitAddBuff(attacker, bullet.target, 7008, bullet[300200] / 10000)
    end  

    --[治疗效果x%的概率移除目标一个控制效果]
    if bullet[300220] > 0 and Heal_Effect_judge(bullet) and RAND(1, 10000) <= bullet[300220] then
        Common_RemoveBuffRandom(bullet.target, {[3] = true}, 1)
    end  
    
    --[攻击时给能量最低的1名队友恢复x点能量]
    if bullet[300250] > 0 and Hurt_Effect_judge(bullet) and not effect_300250 then
        local partners = FindAllPartner()
        local sort_list = SortWithParameter(partners, "ep")
        local count = 0

        for i = 1, 10, 1 do
            if not sort_list[i] then break end
            if sort_list[i].uuid ~= target.uuid then 
                Common_ChangeEp(sort_list[i], bullet[300250], true)
                count = count + 1
                if count >= 1 + bullet[300251] then
                    break
                end
            end
        end
        effect_300250 = true
    end  

    --[攻击时x%的概率降低20%防御]
    if bullet[300260] > 0 and Hurt_Effect_judge(bullet) then
        Common_UnitAddBuff(attacker, bullet.target, 100004, bullet[300260]/10000)
    end
    --[30%]
    if bullet[300261] > 0 and Hurt_Effect_judge(bullet) then
        Common_UnitAddBuff(attacker, bullet.target, 10019, bullet[300261]/10000)
    end

    --[目标生命值低于40%时，附加x回合禁疗]
    if bullet[300290] > 0 and Hurt_Effect_judge(bullet) and bullet.target.hp/bullet.target.hpp <= 0.4 then
        Common_UnitAddBuff(attacker, bullet.target, 7011, nil, {round = bullet[300290]})
    end

    --[攻击时x%的概率造成混乱1回合]
    if bullet[300300] > 0 and Hurt_Effect_judge(bullet) then
        Common_UnitAddBuff(attacker, bullet.target, 7098, bullet[300260]/10000, {round = 1})
    end

    --[暴击时降低目标此次伤害x%的生命上限]
    if bullet[300310] > 0 and Hurt_Effect_judge(bullet) and bullet.isCrit == 1 then
        local hpp_decrease = bullet.hurt_final_value * bullet[300310] / 10000
        Common_ChangeHpp(bullet.target, -hpp_decrease)
    end

    --[攻击时降低目标x%的生命上限]
    if bullet[300320] > 0 and Hurt_Effect_judge(bullet) then
        local hpp_decrease = bullet.hurt_final_value * bullet[300320] / 10000
        Common_ChangeHpp(bullet.target, -hpp_decrease)
    end

    --[治疗时附加额外效果]
    if bullet[300330] > 0 or bullet[300331] > 0 or bullet[300332] > 0 then
        if Heal_Effect_judge(bullet) then
            bullet.healAdd = bullet.healAdd + bullet[300330]/10000 * bullet.attacker.hpp + bullet[300331]/10000 * bullet.target.hpp + bullet[300332]/10000 * bullet.attacker.ad
        end
    end

    --[每次击杀获得x点能量]
    if bullet[300340] > 0 and Hurt_Effect_judge(bullet) and bullet.target.hp <= 0 then
        Common_ChangeEp(target, bullet[300340], true)
    end  

    --[每次击杀所有队友获得x点能量]
    if bullet[300350] > 0 and Hurt_Effect_judge(bullet) and bullet.target.hp <= 0 and bullet.target.owner == 0 then
        local partners = FindAllPartner()
        for _, v in ipairs(partners) do
            Common_ChangeEp(v, bullet[300350], true)
        end
    end  

    --[每次击杀获得额外行动]
    if bullet[300450] > 0 and Hurt_Effect_judge(bullet) and bullet.target.hp <= 0 then
        Common_UnitConsumeActPoint(attacker, -1)
        Common_FireBullet(300450, target, {target}, nil, {Type = 30, Duration = 0, Interval = 0})
    end  

    --[暴击时造成群体伤害]
    if bullet[300470] > 0 and Hurt_Effect_judge(bullet) and bullet.isCrit == 1 then
        Run(function ()
            Common_Sleep(0.2)
            Common_FireBullet(bullet.Fire_Skill and bullet.Fire_Skill or 0, target, FindAllEnemy(), bullet.Fire_Skill, 
            {Type = 8, Hurt = target.ad * bullet[300470]/10000, name_id = bullet.name_id})
        end)
    end

    --[攻击时，偷取x点能量]
    if bullet[300480] > 0 and Hurt_Effect_judge(bullet) then
        local ep_change = math.min(bullet.target.ep, bullet[300480])
        Common_ChangeEp(bullet.target, -ep_change, "")
        Common_ChangeEp(target, ep_change, "")
    end

    -----------------------------------------Buff施加----------------------------------------------
    if bullet[309001] > 0 and Hurt_Effect_judge(bullet) then
        local range = (bullet[309002] > 0) and bullet[309002] or 10000
        Common_UnitAddBuff(attacker, bullet.target, bullet[309001], range/10000, {
            parameter_99 = {k= bullet[309001], v = bullet[309101]}
        })    
	end

	if bullet[309003] > 0 and Hurt_Effect_judge(bullet) then
		local partners = FindAllPartner()
		for _, v in ipairs(partners) do 
			local range = (bullet[309004] > 0) and bullet[309004] or 10000
            Common_UnitAddBuff(attacker, v, bullet[309003], range/10000, {
                parameter_99 = {k= bullet[309003], v = bullet[309102]}
            })   
		end
	end

	if bullet[309005] > 0 and Hurt_Effect_judge(bullet) then
		for _, v in ipairs(All_target_list()) do 
			local range = (bullet[309006] > 0) and bullet[309006] or 10000
            Common_UnitAddBuff(attacker, v, bullet[309005], range/10000, {
                parameter_99 = {k= bullet[309005], v = bullet[309103]}
            })   
		end
	end

    if bullet[309007] > 0 and Hurt_Effect_judge(bullet) then
        local range = (bullet[309008] > 0) and bullet[309008] or 10000
        Common_UnitAddBuff(attacker, attacker, bullet[309007], range/10000, {
            parameter_99 = {k= bullet[309007], v = bullet[309104]}
        })  
    end
    
    if bullet[309009] > 0 and bullet.isCrit == 1 and Hurt_Effect_judge(bullet) then
        local range = (bullet[309010] > 0) and bullet[309010] or 10000
        Common_UnitAddBuff(attacker, bullet.target, bullet[309009], range/10000, {
            parameter_99 = {k= bullet[309009], v = bullet[309105]}
        })  
	end

    if bullet[309011] > 0 and Heal_Effect_judge(bullet) then
        local range = (bullet[309012] > 0) and bullet[309012] or 10000
        Common_UnitAddBuff(attacker, bullet.target, bullet[309011], range/10000 , {
            parameter_99 = {k= bullet[309011], v = bullet[309106]}
        }) 
	end

end

