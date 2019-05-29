--大回合开始前
function afterAllEnter(target, buff)
    if GetFightData().fight_id == 10100403 and GetFightData().round == 4 then
        AddBattleDialog(1010040361)
        Sleep(0.2)
        Common_AddStageEffect(1990121, 1, 9)
        Sleep(8)
        --[FindAllEnemy()    FindAllPartner()]
        Common_FireBullet(1990120, target, FindAllEnemy(), nil, {
            Duration = 0.1,  	--子弹速度
            Hurt = 10000,    	--伤害
            Type = 3,       		 --子弹类型
            --Attacks_Total = 3,	 --次数
            Element = 7,        --元素类型  
        })
    end

    if GetFightData().fight_id == 10100901 and GetFightData().wave == 2 and target.side == 2 then
        AddBattleDialog(1010090101)
    end
end