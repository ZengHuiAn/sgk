local defensiveModule = require "module.DefensiveFortressModule"
local playerModule = require "module.playerModule";
local Time = require "module.Time";
local View = {};


function View:Start(data)
	self.root=CS.SGK.UIReference.Setup(self.gameObject)
	self.view=self.root.view.Content
	self.Pid=playerModule.GetSelfID()
	self:InitData(data)
end

function View:InitData(data)
	self.mapInfo = data and data.mapInfo
	self.PlayerData = data and data.PlayerData
	ERROR_LOG(sprinttb(self.PlayerData))
	self.BossId = data and data.BossId
	self.OwnResource = data and data.OwnResource
	self.Site_Id = data and data.siteId
	self:InitUI()
end

function View:InitUI()
	CS.UGUIClickEventListener.Get(self.root.mask.gameObject,true).onClick = function (obj)
		DialogStack.Pop()
	end
	CS.UGUIClickEventListener.Get(self.root.view.ExitBtn.gameObject).onClick = function (obj)
		DialogStack.Pop()
	end

	local _nowLevel=self.mapInfo[self.Site_Id].NextPitfall_level~=0 and self.mapInfo[self.Site_Id].NextPitfall_level or self.mapInfo[self.Site_Id].Pitfall_level
	local pixFallType=self.mapInfo[self.Site_Id].Pitfall_type
	self.pitFallCfg =defensiveModule.GetPitFallLevelCfg(pixFallType,_nowLevel)

	self.root.AddPanel.slider[UI.Slider].maxValue = self.pitFallCfg.Time_cd/1000

	self.lastClickTime = not self.AddPitFalling and 0 or self.PlayerData[self.Pid].LastAddTime
	self.AddPitFalling = (self.lastClickTime+self.pitFallCfg.Time_cd/1000-Time.now())>0

	--self.root.AddPanel.gameObject:SetActive(self.AddPitFalling)

	for i=1,5 do
		self.view.AddLevel.stage[i][CS.UGUISpriteSelector].index =i<=_nowLevel and 1 or 0
	end

	self.view.Icon.Icon[UI.Image]:LoadSprite("propertyIcon/"..self.pitFallCfg.Pitfall_icon)
	self.view.AddLevel.stage.Text[UI.Text].text =string.format("%d/5",_nowLevel)
	self.view.Icon.name[UI.Text].text=self.pitFallCfg.Pitfall_name

	-- 	--effects
	local bossCfg=defensiveModule.GetBossCfg(self.BossId)
	local bossType=bossCfg.Monster_type

	local cfg1=defensiveModule.GetPitFallLevelCfg(self.pitFallCfg.Pitfall_type,_nowLevel)--当前等级的资源配置
	--local cfg2=_nowLevel<5 and defensiveModule.GetPitFallLevelCfg(self.pitFallCfg.Pitfall_type,_nowLevel+1) or nil--下一级
	local cfg2=defensiveModule.GetPitFallLevelCfg(self.pitFallCfg.Pitfall_type,1)--一级
	local cfg3=defensiveModule.GetPitFallLevelCfg(self.pitFallCfg.Pitfall_type,2)--二级

	local pitFallEffectValue1=self.pitFallCfg.Type1==bossType and cfg1.Value1 or self.pitFallCfg.Type2==bossType and cfg1.Value2 or self.pitFallCfg.Type3==bossType and cfg1.Value3 or self.pitFallCfg.Type4==bossType and cfg1.Value4 or self.pitFallCfg.Type5==bossType and cfg1.Value5 or cfg1.Value6
	--一级 2级
	local pitFallEffectValue2=self.pitFallCfg.Type1==bossType and cfg2.Value1 or self.pitFallCfg.Type2==bossType and cfg2.Value2 or self.pitFallCfg.Type3==bossType and cfg2.Value3 or self.pitFallCfg.Type4==bossType and cfg2.Value4 or self.pitFallCfg.Type5==bossType and cfg2.Value5 or cfg2.Value6
	local pitFallEffectValue3=self.pitFallCfg.Type1==bossType and cfg3.Value1 or self.pitFallCfg.Type2==bossType and cfg3.Value2 or self.pitFallCfg.Type3==bossType and cfg3.Value3 or self.pitFallCfg.Type4==bossType and cfg3.Value4 or self.pitFallCfg.Type5==bossType and cfg3.Value5 or cfg3.Value6

	self.view.BaseEffect[UI.Text].text="基础效果:"
	self.view.BaseEffect.Text[UI.Text]:TextFormat("对{0}{1}{2}造成{3}%最大生命的伤害","<color=#FE0000FF>",bossCfg.Monster_name,"</color>",pitFallEffectValue1/100)
	self.view.NowEffect[UI.Text].text="提升效果:"
	self.view.NowEffect.Text[UI.Text]:TextFormat("每升一级,伤害提升{0}%",math.ceil((pitFallEffectValue3-pitFallEffectValue2)/100))

	local _buffId=self.mapInfo[self.Site_Id].BuffId
	local buffCfg=defensiveModule.GetBuffCfg(_buffId)
	self.view.MaxEffect[UI.Text].text=string.format("%s满级效果:</color>",_nowLevel<5 and "<color=#B6B6B6FF>" or "<color=#FFFFFFFF>")

	self.view.MaxEffect.Text[UI.Text]:TextFormat("{0}{1}</color>",_nowLevel<5 and "<color=#B6B6B6FF>" or "<color=#FFFFFFFF>",buffCfg.Dec)

	self.view.consume.title[UI.Text]:TextFormat("强化消耗:")
	local consume1=	defensiveModule.GetResourceCfgById(self.pitFallCfg.Consume_type1)--Consume_value1
	local consume2=	defensiveModule.GetResourceCfgById(self.pitFallCfg.Consume_type2)

	self.view.consume.item1.Icon[UI.Image]:LoadSprite("propertyIcon/"..consume1.Resource_icon)
	self.view.consume.item1.num[UI.Text].text=string.format("X%d",self.pitFallCfg.Consume_value1)
	
	self.view.consume.item2:SetActive(not not consume2)
	if consume2 then
		self.view.consume.item2.Icon[UI.Image]:LoadSprite("propertyIcon/"..consume2.Resource_icon)
		self.view.consume.item2.num[UI.Text].text=string.format("X%d",self.pitFallCfg.Consume_value2)
	end

	CS.UGUIClickEventListener.Get(self.view.addBtn.gameObject).onClick = function (obj) 
		if Time.now()-self.PlayerData[self.Pid].LastAddTime>=self.pitFallCfg.Time_cd/1000 then
			if _nowLevel>=5 then
				showDlgError(nil,"强化已达上限")
			else
				local case
				if self.pitFallCfg.Consume_value2 ~=0 then
					case=self.OwnResource[self.pitFallCfg.Consume_type1]>=self.pitFallCfg.Consume_value1 and self.OwnResource[self.pitFallCfg.Consume_type2]>=self.pitFallCfg.Consume_value2 and ((self.OwnResource[self.pitFallCfg.Consume_type1]+self.OwnResource[self.pitFallCfg.Consume_type2])>=(self.pitFallCfg.Consume_value1+self.pitFallCfg.Consume_value2))
				else
					case=self.OwnResource[self.pitFallCfg.Consume_type1]>=self.pitFallCfg.Consume_value1
				end
				if  case then
					self.AddPitFalling=true
					self.lastClickTime=Time.now()
					--self.root.AddPanel.gameObject:SetActive(true)
				else
					showDlgError(nil,"材料不足")
				end
			end
		else
			showDlgError(nil,"强化冷却中")
		end 
	end

	CS.UGUIClickEventListener.Get(self.root.AddPanel.closeBtn.gameObject).onClick = function (obj)
		self.AddObstructing = true
		self.lastClickTime = 0
		--self.root.AddPanel.gameObject:SetActive(false)	
	end
	
end

function View:Update()
	if self.AddPitFalling and self.lastClickTime~=0 then
		local time=Time.now()-self.lastClickTime
		if time<=self.pitFallCfg.Time_cd/1000 then
			-- self.root.AddPanel.slider[UI.Slider].value=time
			-- self.root.AddPanel.slider.Text[UI.Text].text=string.format("%sS",math.floor(time))
		else
			self.AddPitFalling = false
			self.lastClickTime = 0
			defensiveModule.QueryaAddPitfall(self.Site_Id)
			DialogStack.Pop() 
		end
	end
end


function View:listEvent()
	return {
		"RESOURCES_NUM_CHANGE",
		"BOSS_DATA_CHANGE",
	}
end

function View:onEvent(event,data)
	if event == "RESOURCES_NUM_CHANGE" then
		self.OwnResource=data[1]
	elseif event=="BOSS_DATA_CHANGE" then
		if data and data[3] == 4 and self.mapInfo then
			if data[2] == self.Site_Id then--boss进攻点为 当前点
				self.AddPitFalling = false
				self.lastClickTime=0
				showDlgError(nil,"魔王向据点发起攻击,强化陷阱失败")
				DialogStack.Pop()
			end
		end
	end
end

 
return View;