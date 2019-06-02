local defensiveModule = require "module.DefensiveFortressModule"
local View = {};

function View:Start()
	self.root=CS.SGK.UIReference.Setup(self.gameObject)
	self.view=self.root.view
end

function View:InitData(data)
	self.BossData=data and data.BossData
	self.LastHP=data and (data.LastHP>=0 and  data.LastHP or 0)
	self:InitUI()
end

local colorTab={"<color=#095D59FF>","<color=#4B2C09FF>","<color=#092C62FF>","<color=#9D0607FF>","<color=#564804FF>","<color=#480C60FF>","<color=#FDB2B2FF>"}
local propertyTab={"风","土","水","火","光","暗"}
local activeTab={[0]="等待中","破坏中","发呆","生命回复","移动中"}
local activeDesc={[0]="怪物晕乎乎的","破坏据点后,据点将无法产生资源","怪物懵圈中","回复最大生命值10%","魔王向据点发起攻击"}
---[[--boss信息
function View:InitUI()
	CS.UGUIClickEventListener.Get(self.root.mask.gameObject,true).onClick = function (obj)
		self.gameObject:SetActive(false)
	end
	CS.UGUIClickEventListener.Get(self.view.ExitBtn.gameObject).onClick = function (obj)
		self.gameObject:SetActive(false)
	end

	local bossCfg=defensiveModule.GetBossCfg(self.BossData.Id)
	self.view.top.bossData.Icon[UI.Image]:LoadSprite("icon/"..bossCfg.Monster_icon)
	self.view.top.bossData.name[UI.Text].text=bossCfg.Monster_name
	self.view.top.bossData.line1[UI.Text]:TextFormat("当前血量:")
	self.view.top.bossData.line1.Slider[UI.Slider].maxValue=bossCfg.Monster_hp
	self:RefBossData()


	local _status=self.BossData.Status
	self.view.top.bossData.line2[UI.Text]:TextFormat("状态:{0}({1})",activeTab[_status],activeDesc[_status])

	local propertyCfg=defensiveModule.GetResourceCfgById(bossCfg.Monster_type)
	self.view.OddsTitle.static_addedOdds[UI.Text]:TextFormat("怪物属性:\t{0}{1}{2}",colorTab[bossCfg.Monster_type],propertyTab[bossCfg.Monster_type],"</color>")

	local _item=self.view.effects
	local _elseType=0
	for i=1,6 do
		if i~=bossCfg.restrain_type and i~=bossCfg.Monster_type and i~=bossCfg.Berestrain_type then
			_elseType=i
			break
		end
	end

	self:refreshPitFallEffectDesc(_item[1],bossCfg.restrain_type,propertyTab[bossCfg.restrain_type])--相克
	self:refreshPitFallEffectDesc(_item[2],bossCfg.Monster_type,propertyTab[bossCfg.Monster_type])--相同

	if bossCfg.Berestrain_type~=0 then
		self:refreshPitFallEffectDesc(_item[3],bossCfg.Berestrain_type,propertyTab[bossCfg.Berestrain_type])--相生
	end
	self:refreshPitFallEffectDesc(_item[4],_elseType,"其余")--其他

end
function View:refreshPitFallEffectDesc(item,typeId,typeDes)
	item.gameObject:SetActive(true)
	local _value=self:GetPitFallEffectValueByType(typeId)
	local cfg=defensiveModule.GetResourceCfgById(typeId)
	item.Icon.gameObject:SetActive(typeDes~="其余")
	item.Icon[UI.Image]:LoadSprite("propertyIcon/"..cfg.Resource_icon)
	item.effect[UI.Text]:TextFormat("受 {0} 系陷阱伤害\t{1}%",typeDes,_value/100)
end

function View:GetPitFallEffectValueByType(type)
	local pitFallCfg=defensiveModule.GetPitFallLevelCfg(type,1)
	local bossCfg=defensiveModule.GetBossCfg(self.BossData.Id)
	local bossType=bossCfg.Monster_type
	local _value=pitFallCfg.Type1==bossType and pitFallCfg.Value1 or pitFallCfg.Type2==bossType and pitFallCfg.Value2 or pitFallCfg.Type3==bossType and pitFallCfg.Value3 or pitFallCfg.Type4==bossType and pitFallCfg.Value4 or pitFallCfg.Type5==bossType and pitFallCfg.Value5 or pitFallCfg.Value6
	return _value
end

function View:RefBossData()
	local bossCfg=defensiveModule.GetBossCfg(self.BossData.Id)
	self.view.top.bossData.line1.Slider[UI.Slider].value=self.LastHP
	self.view.top.bossData.line1.Slider.Text[UI.Text].text=string.format("%d%%",math.ceil(self.LastHP*100/bossCfg.Monster_hp))
end

return View;