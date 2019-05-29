local ActivityModule = require "module.ActivityModule"
local lucky_draw = require "config.lucky_draw"
local QuestModule = require "module.QuestModule"
local timeModule = require "module.Time"
local UserDefault = require "utils.UserDefault";
local View = {}

local last_Refresh_timeDay = UserDefault.Load("last_Refresh_timeDay",true);
local activity_type=2
function View:Start()
	self.view = CS.SGK.UIReference.Setup(self.gameObject)
end

function View:Init()
	self.effectTab={}
	self._quest={}
	--今天刷新了运势
	if last_Refresh_timeDay and last_Refresh_timeDay[1] and last_Refresh_timeDay[1]==CS.System.DateTime.Now.Day then
		self.TodayRefreshed = true
	end

	self.ActivityData = ActivityModule.GetManager(activity_type)
	if next(self.ActivityData)~=nil  then
		self:initData()
	end
	
	self:InitView()	
end

local activity_Id=3--活动Id
function View:initData()
	self.Activity_id = self.ActivityData[activity_Id].id
	self.current_pool = self.ActivityData[activity_Id].CardData.current_pool

	self.current_pool_end_time = self.ActivityData[activity_Id].CardData.current_pool_end_time
	--抽奖次数
	self.Can_Draw_Time = self:GetCanDrawTime()
	--刷新次数
	self.Can_Ref_Pool_Time = self:GetCanRefTime()
	--self.view.top.title.tip[UI.Text]:TextFormat("{0}",self.Can_Ref_Pool_Time>0 and "可免费刷新1次" or "已刷新")
	self:RefSpine()
	self:initUi()
end

function View:RefSpine()
	local _SkeletonGraphic = self.view.bottom.cat.spine:GetComponent(typeof(CS.Spine.Unity.SkeletonGraphic))
	SGK.ResourcesManager.LoadAsync(_SkeletonGraphic,"roles/19071/19071_SkeletonData.asset",function(o)
		if o ~= nil then
			self.SkeletonGraphic = _SkeletonGraphic
			self.SkeletonGraphic.skeletonDataAsset = o
			self.SkeletonGraphic.startingAnimation = "idle"
			self.SkeletonGraphic.startingLoop = true
			self.SkeletonGraphic:Initialize(true);
			if self.SkeletonLoding then
				self.SkeletonLoding = false
				self:initTop()
			end
		end
	end);
end

local advance_quests={1021001,1021002,1021003}
local maxLucky = 15--最好运势
function View:InitView()
	self.lastRestTime = timeModule.now()	
	self.view.Title.Text[UI.Text].text = SGK.Localize:getInstance():getValue("niudantishi_01")
	self.view.mask:SetActive(false)
	
	CS.UGUIClickEventListener.Get(self.view.bottom.DrawTip.gameObject).onClick = function()
		if self.Can_Ref_Pool_Time>0 then
			if self.current_pool ~= maxLucky then
				ActivityModule.ChangePool(self.Activity_id,activity_type)
			else
				showDlg(nil,SGK.Localize:getInstance():getValue("niudan_07"), 
				function()
					ActivityModule.ChangePool(self.Activity_id,activity_type)
				end,
		         function() end,
				"刷新","取消")	
			end
		else
			showDlgError(nil,"改天再来试试吧")
		end
    end

    CS.UGUIClickEventListener.Get(self.view.bottom.Machine.gashaponMachine.drawBtn.gameObject,true).onClick = function()
		if self.Can_Draw_Time>0 then
			local cfgTab=lucky_draw.GetDailyDrawConfig(self.current_pool)
			self:OnDrawInIt(cfgTab)
		else	
			showDlgError(nil,"抽奖次数不足")
		end
    end

	for i=1,#advance_quests do
		local item=self.view.top.right.rewards[i]

		local questCfg = QuestModule.GetCfg(advance_quests[i])
		if questCfg then
			utils.IconFrameHelper.Create(item.IconFrame,{type=questCfg.reward_type1,id=questCfg.reward_id1,count=questCfg.reward_value1,showDetail=true})
			item.checkMark.gameObject:SetActive(false)
			local _targetCount=questCfg.condition[1].count
		else
			ERROR_LOG("questCfg is nil,questid",advance_quests[i])
		end
		CS.UGUIClickEventListener.Get(item.GetBtn.gameObject).onClick = function()
			showDlgError(nil,"未达到奖励领取条件")
		end
	end
	self:refTopRight()
end
function View:initUi()
	self:initTop()

	self.view.bottom.DrawTip.star.gameObject:SetActive(true)
	if not self.TodayRefreshed then
		self.view.transform:DOScale(Vector3.one,3):OnComplete(function()
			if self.view and self.view.bottom.DrawTip.star.gameObject.activeSelf then
				self.view.bottom.DrawTip.star.gameObject:SetActive(false)
			end
		end)
	end
	self.view.bottom.DrawTip.refreshTip.gameObject:SetActive(self.Can_Ref_Pool_Time>0)
	self.view.bottom.DrawTip.refreshedTip.gameObject:SetActive(self.Can_Ref_Pool_Time==0)
	self.view.bottom.Machine.gashaponMachine.qiu.gameObject:SetActive(false)
end

local Animation={"moji","idle","zhongji","daji","daji"}
function View:initTop()
	if not self.SkeletonGraphic then
		self.SkeletonLoding = true
		return
	end
	
	self.view.top.static_Tip[UI.Text].text = SGK.Localize:getInstance():getValue("niudantishi_02")
    self.view.top.tip[UI.Text]:TextFormat("剩余次数 : {0}",self.Can_Draw_Time<1000 and self.Can_Draw_Time or 999)

    self.view.bottom.Machine.canClickTip.gameObject:SetActive(self.Can_Draw_Time>0)

    local cfgTab=lucky_draw.GetDailyDrawConfig(self.current_pool)
    self.view.bottom.DrawTip.title[UI.Text]:TextFormat(cfgTab[1].lucky_name)
    self.view.bottom.box.lucky[CS.UGUISpriteSelector].index =cfgTab[1].lucky_id-1
    
    self.SkeletonGraphic.AnimationState:SetAnimation(0,Animation[cfgTab[1].lucky_id],true);
    self.ShowTab={}
    for i,v in ipairs(cfgTab) do
    	if v.is_show==1 then
    		table.insert(self.ShowTab,v)
    	end
    end
    
    CS.UGUIClickEventListener.Get(self.view.bottom.box.gameObject,true).onClick = function()
		DialogStack.PushPrefStact("welfare/JackRewardPanel",{self.ShowTab,cfgTab[1].lucky_id});
	end 
end

local delayTime=1.22
function View:OnDrawInIt(cfgTab)
	self.view.mask.gameObject:SetActive(true)

	self.view.bottom.Machine.gashaponMachine.drawBtn[CS.UGUIClickEventListener].interactable=false;
	self.view.bottom.Machine.canClickTip.gameObject:SetActive(false)

	self.view.bottom.Machine.gashaponMachine.qiu[CS.UGUISpriteSelector].index =math.random(0,7)
	self.view.bottom.Machine.gashaponMachine.qiu.gameObject:SetActive(true)
	if not self.view.bottom.Machine[UnityEngine.Animator].enabled then
		self.view.bottom.Machine[UnityEngine.Animator].enabled=true
	else
		self.view.bottom.Machine[UnityEngine.Animator]:Play("ndj_ani1")
	end
	--2秒后向服务器发送抽奖
	self.view.transform:DOScale(Vector3.one,delayTime):OnComplete(function()
		local temp = {self.ActivityData[3].consume_type,self.ActivityData[3].consume_id,self.ActivityData[3].price}
		ActivityModule.DrawCard(self.Activity_id,self.current_pool,temp,0)
		self.view.mask.gameObject:SetActive(false)
	end)
end

local filledValue={2,5,7}
function View:refTopRight()
	local allFinish=true
	for i=1,#advance_quests do
		self._quest[advance_quests[i]]=QuestModule.Get(advance_quests[i])
		if not self._quest[advance_quests[i]]  then
			QuestModule.Accept(advance_quests[i])
			return
		end
		if not self._quest[advance_quests[i]] or self._quest[advance_quests[i]].status==0 then
			allFinish=false
		end
	end

	if allFinish then
		for i=1,#advance_quests do
			self._quest={}
			self.effectTab={}
			QuestModule.Accept(advance_quests[i])
		end
		return
	end

	for i=1,#advance_quests do
		if self._quest[advance_quests[i]] then
			local item=self.view.top.right.rewards[i]
			item.checkMark.gameObject:SetActive(false)
			local _targetCount=self._quest[advance_quests[i]].condition[1].count
			local _finishedCount=self._quest[advance_quests[i]].records[1]
		
			local status=self._quest[advance_quests[i]] and  self._quest[advance_quests[i]].status or 0

			if status==0 and _finishedCount>=_targetCount then
				item.GetBtn.gameObject:SetActive(true)

				if not self.effectTab[i] then
					self.effectTab[i]=self:playEffect("fx_box_get", Vector3(0, 0, 0),item.GetBtn.gameObject)
				end

				CS.UGUIClickEventListener.Get(item.GetBtn.gameObject).onClick = function()
					QuestModule.Finish(advance_quests[i])
				end
				item.checkMark.gameObject:SetActive(false)
			else
				if self.effectTab[i] then
					UnityEngine.GameObject.Destroy(self.effectTab[i])
				end
				item.GetBtn.gameObject:SetActive(false)
			end
			if status~=0 then
				item.checkMark.gameObject:SetActive(true)
				CS.UGUIClickEventListener.Get(item.GetBtn.gameObject).onClick = function()
					showDlgError(nil,"奖励已领取")
				end
			end

			local maxQuestInfo=self._quest[advance_quests[i]]
			self.view.top.right.TimesImage[UI.Image].fillAmount =maxQuestInfo.records[1]/_targetCount

			local _reached = filledValue[i]<=maxQuestInfo.records[1]
			self.view.top.right.FilledDot[i]:SetActive(_reached)
			self.view.top.right.FilledText[i][UI.Text]:TextFormat("{0}{1}</color>",_reached and "<color=#000000FF>" or "<color=#FFFFFFFF>",filledValue[i])
		end
	end
end

function View:GetCanDrawTime()
	local draw_consume_id = self.ActivityData[3].consume_id
	local draw_item_count = module.ItemModule.GetItemCount(draw_consume_id)
	local draw_Price = self.ActivityData[3].price
	return tonumber(draw_item_count/draw_Price)
end

function View:GetCanRefTime()
	local ref_consume_id = self.ActivityData[3].ref_consume_id
	local ref_item_count = module.ItemModule.GetItemCount(ref_consume_id)
	local ref_Price = self.ActivityData[3].ref_price
	if ref_consume_id~=0 and ref_Price~=0 then
		return tonumber(ref_item_count/ref_Price)
	else
		return math.huge
	end
end

function View:playEffect(effectName, position, node, sortOrder)
    local prefab = SGK.ResourcesManager.Load("prefabs/effect/UI/" .. effectName..".prefab");
    local o = prefab and UnityEngine.GameObject.Instantiate(prefab, node.transform);
    if o then
        local transform = o.transform;
        transform.localPosition = position or Vector3.zero;
        transform.localRotation = Quaternion.identity;
        if sortOrder then
            SGK.ParticleSystemSortingLayer.Set(o, sortOrder);
        end
    end
    return o
end

function View:OnDestroy( ... )
	self.view = nil
end

function View:Update()
	if self.current_pool_end_time and self.lastRestTime and self.lastRestTime <= self.current_pool_end_time then
		if timeModule.now()>self.current_pool_end_time  then
			ActivityModule.QueryDrawCardData(activity_Id)
			self.lastRestTime=timeModule.now()
		end
	end
end

function View:listEvent()
	return {
		"DrawCard_Succeed",
		"Activity_INFO_CHANGE",
		"Change_Pool_Succeed",
		"QUEST_INFO_CHANGE",
	}
end

local changePoolTips={[11]="niudan_01",[12]="niudan_02",[13]="niudan_03",[14]="niudan_04",[15]="niudan_05",[16]="niudan_06"}
function View:onEvent(event,data)
	if event =="Activity_INFO_CHANGE" then
		self.ActivityData =ActivityModule.GetManager(activity_type)
		self:initData()
	elseif event =="Change_Pool_Succeed" then
	  	--刷新次数
		self.Can_Ref_Pool_Time=self:GetCanRefTime()

		last_Refresh_timeDay=last_Refresh_timeDay or {}
		last_Refresh_timeDay[1]=CS.System.DateTime.Now.Day
		self.TodayRefreshed=true
		
		if self.current_pool==data then
			showDlgError(nil,SGK.Localize:getInstance():getValue(changePoolTips[16]))
		else
			showDlgError(nil,SGK.Localize:getInstance():getValue(changePoolTips[data]))
		end
		self.current_pool=data
	  	--local cfgTab=lucky_draw.GetDailyDrawConfig(self.current_pool)
	  	-- showDlgError(nil,"本次运势:"..cfgTab[1].lucky_name)

		self.view.bottom.DrawTip.refreshTip.gameObject:SetActive(false)
		self.view.bottom.DrawTip.star.gameObject:SetActive(true)
		self.view.bottom.DrawTip.refreshedTip.gameObject:SetActive(true)
		
		self.view.transform:DOScale(Vector3.one,2):OnComplete(function()
			if self.view then
				if not self.TodayRefreshed then
					self.view.bottom.DrawTip.star.gameObject:SetActive(false)
				end
				if self.Can_Ref_Pool_Time>0 then
					self.view.bottom.DrawTip.refreshTip.gameObject:SetActive(true)
					self.view.bottom.DrawTip.refreshedTip.gameObject:SetActive(false)
				end
			end
		end)	
		self:initTop()
	elseif event =="DrawCard_Succeed" then
		self.view.bottom.Machine.canClickTip.gameObject:SetActive(self.Can_Draw_Time>0)
		self.view.bottom.Machine.gashaponMachine.qiu.gameObject:SetActive(false)
		self.view.bottom.Machine.gashaponMachine.drawBtn[CS.UGUIClickEventListener].interactable=true
	elseif event =="QUEST_INFO_CHANGE" then
		self:refTopRight()
	end
end


return View