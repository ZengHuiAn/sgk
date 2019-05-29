--评分计算方式
local function common_capacity(P)
	local score_atk = (P.ad * 6 + P.damageAdd * 3) * (P.critPer * (1.5 + P.critValue) + 1 - P.critPer) * (1 + P.damagePromote + P[10008]/10000)
	local score_def = (P.armor * 6 + P.hpp * 0.6 + P.hpRevert * 3 + P.damageAbsorb * 12 + P.suck * score_atk) * (1 + P.damageReduce + P[10009]/10000)
	local score_com = P.ignoreArmor * 6 + (P.ignoreArmorPer + P.reduceCritPer + P.reduceCritValue) * 10000 + P[10000]
	local score_per = math.max(0,(P.speed - 100)) * 100 + P.initEp * 100 + math.max(0,(P.epRevert-20)) * 200
	return (score_atk * (1 + score_per/10000) + score_def + score_com) / 4
end

--计算装备评分
local function calc_score(P)
	local score =
		P[1002] * 6 + P[1302] * 12 + P[1502] + 
		P[1013] + P[1313] + P[1513] + P[1201] + P[1202] + P[1211] * 100
	return score / 2
end

--属性值计算
return {
	capacity = function(P)
		return math.ceil(common_capacity(P))
	end,
	calc_score = function(P)
		return math.ceil(calc_score(P))
	end,

	--攻击
	ad = function(P)
		return (P.baseAd + P.extraAd) * (1 + P[1014] / 10000)
	end,
	baseAd = function(P)
		return P[1001] * (1 + P[1011] / 10000)
	end,
	extraAd = function(P)
		return P[1002] * (1 + P[1012] / 10000) + P[1003] + P.baseAd * P[1013] / 10000
	end,

	--防御
	armor = function(P)
		return (P.baseArmor + P.extraArmor) * (1 + P[1314] / 10000)
	end,
	baseArmor = function(P)
		return P[1301] * (1 + P[1311] / 10000)
	end,
	extraArmor = function(P)
		return P[1302] * (1 + P[1312] / 10000) + P[1303] + P.baseArmor * P[1313] / 10000
	end,

	--生命,改变hpp时hp也会增加，hp是hpp减去伤害后的值
	hp = function(P)
		return (P.hpp - P[1599]) * (1 - P[1598] / 10000)
	end,
	hpp = function(P)
		return (P.baseHp + P.extraHp) * (1 + P[1514] / 10000)
	end,
	baseHp = function(P)
		return P[1501] * (1 + P[1511] / 10000)
	end,
	extraHp = function(P)
		return P[1502] * (1 + P[1512] / 10000) + P[1503] + P.baseHp * P[1513] / 10000
	end,

	--每回合生命回复
	hpRevert = function(P)
		return P[1521] * (1 + (P[1522]) / 10000)
	end,

	--速度
	speed = function(P)
		return P[1211]
	end,

	--穿透
	ignoreArmor = function(P)
		return P[1031]
	end,
	ignoreArmorPer = function(P)
		return math.min(0.6, P[1032] / 10000)
	end,

	--吸血
	suck = function(P)
		return math.min(0.4, P[1251] / 10000)
	end,

	--伤害加成
	damageAdd = function(P)
		return P[1021]
	end,
	damagePromote = function(P)
		return P[1022] / 10000 + P[3002] / 10000 * (P.hpp - P.hp) / math.max(1,P.hpp) * 100
	end,

	--伤害减免
	damageAbsorb = function(P)
		return P[1321]
	end,
	damageReduce = function(P)
		return math.min(P[1322] / 10000 + P[3001]/10000 * math.max(P.speed - 100, 0), 0.75)
	end,

	--暴击和免暴
	critPer = function(P)
		return P[1201] / 10000
	end,
	critValue = function(P)
		return math.min(4.5, P[1202] / 10000)
	end,
	reduceCritPer = function(P)
		return P[1203] / 10000
	end,
	reduceCritValue = function(P)
		return P[1204] / 10000
	end,

	--韧性:降低被控制的概率
	tenacity = function(P)
		return math.min(1, math.max(0, P[1261] /10000))
	end,

	--治疗效果提升
	healPromote = function(P)
		return P[1221] / 10000
	end,

	--接受治疗的效果提升
	beHealPromote = function(P)
		return P[1222] / 10000
	end,

	--护盾效果提升
	shieldPromote = function(P)
		return P[1231] / 10000
	end,

	--风、土、水、火、光、暗系精通
	airMaster = function(P)
		return P[1801] + P[1807]
	end,
	dirtMaster = function(P)
		return P[1802] + P[1807]
	end,
	waterMaster = function(P)
		return P[1803] + P[1807]
	end,
	fireMaster = function(P)
		return P[1804] + P[1807]
	end,
	lightMaster = function(P)
		return P[1805] + P[1807]
	end,
	darkMaster = function(P)
		return P[1806] + P[1807]
	end,
	
	--元素伤害加成
	airPromote = function(P)
		return (P[1881] + P[1887]) / 10000
	end,
	dirtPromote = function(P)
		return (P[1882] + P[1887]) / 10000
	end,
	waterPromote = function(P)
		return (P[1883] + P[1887]) / 10000
	end,
	firePromote = function(P)
		return (P[1884] + P[1887]) / 10000
	end,
	lightPromote = function(P)
		return (P[1885] + P[1887]) / 10000
	end,
	darkPromote = function(P)
		return (P[1886] + P[1887]) / 10000
	end,

	--元素伤害减免
	airReduce = function(P)
		return (P[1891] + P[1897]) / 10000
	end,
	dirtReduce = function(P)
		return (P[1892] + P[1897]) / 10000
	end,
	waterReduce = function(P)
		return (P[1893] + P[1897]) / 10000
	end,
	fireReduce = function(P)
		return (P[1894] + P[1897]) / 10000
	end,
	lightReduce = function(P)
		return (P[1895] + P[1897]) / 10000
	end,
	darkReduce = function(P)
		return (P[1896] + P[1897]) / 10000
	end,

	--元素伤害治疗
	airHeal = function(P)
		return (P[1871] + P[1877]) / 10000
	end,
	dirtHeal = function(P)
		return (P[1872] + P[1877]) / 10000
	end,
	waterHeal = function(P)
		return (P[1873] + P[1877]) / 10000
	end,
	fireHeal = function(P)
		return (P[1874] + P[1877]) / 10000
	end,
	lightHeal = function(P)
		return (P[1875] + P[1877]) / 10000
	end,
	darkHeal = function(P)
		return (P[1876] + P[1877]) / 10000
	end,

	--出现人数限制（程序使用）
	appear_limit_player = function(P)
		return P[7094]
	end,
	
	--护盾（程序使用）
	shield = function(P)
		return P[7095]
	end,
	buff_shield = function(P)
		return P[7096]
	end,
	
	-- 每轮恢复行动力点数(程序使用)
	dizzy = function(P)
		return math.max(0, 1 - P[7008])
	end,

	--放逐（无法被选到，程序使用）
	exile = function(P)
		return P[7097]
	end,
	
	--混乱
	chaos = function(P)
		return P[7098]
	end,	

	--失控（程序使用）
	outcontrol = function(P)
		return P[7099]
	end,
	
	--沉默（程序使用）
	silence = function(P)
		return P[7003]
	end,	

	--技能cd
	skill_cast_cd = function(P)
		return P[2001]
	end,
	skill_init_cd = function(P)
		return P[2002]
	end,

	--能量energy
	ep = function(P)
		return P.initEp
	end,
	epp = function(P)
		return P[1721]
	end,
	--能量回复
	epRevert = function(P)
		return P[1722]
	end,
	--初始能量
	initEp = function(P)
		return P[1723]
	end,

	--法力消耗类型
	skill_consume_mp = function(P)
		return P[8000]
	end,
	skill_consume_ep = function(P)
		return P[8001]
	end,
	skill_consume_fp = function(P)
		return P[8002]
	end,	
	skill_cooldown_cd = function(P)
		return P[8003]
	end,
	remaining_round = function(P)
		return P[8004]
	end,
	focus_tag = function(P)
		return P[8005]
	end,
	skill_id_change = function(P)
		return P[8006]
	end,

	--陆水银钻石属性
	diamond_index = function(P)
		return P[21000]
	end,

	--升星计数
	star_count = function(P)
		return P[10100]
	end,

	--入场脚本
	enter_script = function(P)
		return "enter_script"
	end
}