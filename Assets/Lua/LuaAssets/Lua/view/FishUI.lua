local TAG = "FishUI"

local FishModule = require "module.FishModule"
local Time = require "module.Time"
local ItemHelper = require 'utils.ItemHelper'
local ItemModule = require 'module.ItemModule'
local UnionConfig = require "config/UnionConfig"

local view = {}

local activity_Period = nil
function view:FreshSpine()
	local fish = SGK.UIReference.Setup(UnityEngine.GameObject.Instantiate(SGK.ResourcesManager.Load("prefabs/fishUI/fish.prefab"),self.view.gameObject.transform))
	self.fish = fish;
	local spine = fish.bg.bg.yugan[CS.Spine.Unity.SkeletonGraphic];
		--小人
	local state = spine.AnimationState
	if state then
		state:SetAnimation(0, "animation1", true)
		self.m_state = state;
	end
	fish.gameObject.transform:SetSiblingIndex(3);
end

local fish_npc = {
	{
		{npcid = 2344001},
	},
	{
		{npcid = 2344002},
	},

	{
		{npcid = 2344003},
	},
	{
		{npcid = 2344001},
		{npcid = 2344002},
	},

	{
		{npcid = 2344003},
		{npcid = 2344001},
	},

	{
		{npcid = 2344002},
		{npcid = 2344001},
		{npcid = 2344003},
	},
}

function view:RandomNpc()
	self.union = module.unionModule.GetPlayerUnioInfo(module.playerModule.Get().id)
	if not self.union or not next(self.union) then
		return;
	end
	print(sprinttb(self.union));
	math.randomseed(self.union.unionId);
	local index = math.random(#fish_npc);
	self:FreshFishNpc(index);
	
end


function view:FreshFishNpc(index)
	for k,v in pairs(fish_npc[index]) do

        if k==1 then
		 module.NPCModule.deleteNPC(v.npcid);
		 module.NPCModule.LoadNpcOBJ(v.npcid);
		end
		
		
	end
end


function view:Start()
	self.view = CS.SGK.UIReference.Setup(self.gameObject)

	self:FreshSpine();
	self.fish.gameObject:SetActive(false)
	self.view.area.gameObject:SetActive(false)
	self.view.area.bg.flag[UI.Image].color = { r = 1, g = 1, b = 1, a = 0};
	self.view.area.bg.flag.flag[UI.Image].color = { r = 1, g = 1, b = 1, a = 0};

	self.view.ScrollView1.gameObject:SetActive(false);

	self.open = true
	self:RandomNpc();


	self.view.btn.gameObject:SetActive(false);
	self.fish.bg.bg.gameObject.transform.localScale = Vector3(0, 0, 1)
	CS.UGUIClickEventListener.Get(self.view.btn.gameObject).onClick = function (obj)
		self.view.leaveBtn:SetActive(false)
		--self.view.rank:SetActive(false)
		--self.view.icon2:SetActive(false)
		utils.SGKTools.StopPlayerMove()
		self.view.btn.gameObject:SetActive(false)
		self:initFishRoom(true)
		self.fish.gameObject:SetActive(true)
		self.fish.bg.bg.gameObject.transform:DOScale(Vector3(1, 1, 1), 0.5):OnComplete(function()
			self.fish.btn.gameObject:SetActive(true)
			self.fish.exit.gameObject:SetActive(true)
			self.view.ScrollView1.gameObject:SetActive(true);
		end)
	end

	CS.UGUIClickEventListener.Get(self.fish.btn.gameObject).onClick = function (obj)
		local ret = FishModule.CheckPushing()
		if not ret then
			if self.pool then
				self.fish.btn:SetActive(false);
				ERROR_LOG("=====",self.pool);
				FishModule.PushRod(self.pool)
			end
			self.view.btn.gameObject:SetActive(false);
		end
		SetItemTipsStateAndShowTips(false)
	end

	CS.UGUIClickEventListener.Get(self.fish.exit.gameObject).onClick = function (obj)
		if self.m_state then
			self.m_state:SetAnimation(0, "animation1", true)
		end
		self.handle_time = nil
		self.m_QTEtime = nil
		self:leaveRoom()
        self.view.leaveBtn:SetActive(true)
		self.view.rank:SetActive(true)
		self.view.icon2:SetActive(true)
		self.fish.btn.gameObject:SetActive(false)
		self.fish.exit.gameObject:SetActive(false)
		self.view.area.gameObject:SetActive(false)
		self.view.ScrollView1.gameObject:SetActive(false);
		self.fish.bg.bg.gameObject.transform:DOScale(Vector3(0, 0, 1), 0.5):OnComplete(function()
			self.fish.gameObject:SetActive(false)
			self.view.btn.gameObject:SetActive(true)
		end)
	end

	CS.UGUIClickEventListener.Get(self.view.icon2.gameObject).onClick = function (obj)
		utils.SGKTools.ShowDlgHelp(SGK.Localize:getInstance():getValue("guild_fish_rule"))		
	end
	self.view.rank[CS.UGUIClickEventListener].onClick = function ( ... )
		DialogStack.PushPrefStact("guild/UnionActivityRank",{Period = activity_Period, activity_id = 7});
	end
	self.view.leaveBtn[CS.UGUIClickEventListener].onClick = function ()
		SceneStack.EnterMap(1);
	end;
	
	self.UIDragIconScript = self.view.ScrollView1[CS.UIMultiScroller]
	self.UIDragIconScript.RefreshIconCallback = (function (obj,idx)
		local item = CS.SGK.UIReference.Setup(obj);
		local data = self.m_data[idx+1];
		if not data then return end

		utils.IconFrameHelper.Create(item.IconFrame, {id = data.id, type = data.type, count = data.value, showDetail = true})
		obj:SetActive(true);
		-- item.num[UI.Text].text = tostring(data.num);
		-- item.name[UI.Text].text = tostring(data.name);
	end)
	

	self:getScrollData();
	activity_Period = module.TreasureModule.GetNowPeriod(7);
	self:showActivityTime()


	module.TreasureModule.GetUnionRank(7,nil,function ( _rank_data )
		local score = module.TreasureModule.GetActivityScore(7)
		print("score1",score)
		self.view.score.point[UI.Text].text = score;
	end);
end

local list = {70001,70002,70003,70004,70005,70006,70007,70008,70009,70010,};
function view:getScrollData()
	self.m_data = {};
	for k,v in pairs(list) do
		local count = ItemModule.GetItemCount(v);
		if count > 0 then
			local info = ItemHelper.Get(41, v);
--			ERROR_LOG("info----->>",sprinttb(info))
			table.insert(self.m_data, {
				num 	= count,
				name 	= info.name,
				id      =info.id ,
				type    =info.type,
			})
		end
	end

	self.UIDragIconScript.DataCount=#self.m_data
	self.UIDragIconScript:ItemRef()	
end

local function getTimeHMS(time)
    local H = math.floor(time /3600);
    time = math.fmod(time ,3600)
    local M = math.floor(time/60);
    time = math.fmod(time ,60)
    local S = time
    return H,M,S
end

function view:showActivityTime()
	local _cfg = UnionConfig.GetActivity(7)
	if _cfg.loop_duration then
		self.maxtitle = _cfg.loop_duration / 15
	end
	if _cfg.begin_time >= 0 and _cfg.end_time >= 0 and _cfg.period >= 0 then
        local total_pass = Time.now() - _cfg.begin_time
        local count = math.floor(total_pass / _cfg.period) * _cfg.period
        self.m_endTime = count + _cfg.loop_duration + _cfg.begin_time
        self.open = true
        if self.m_endTime < Time.now() then
        	self.open = false
        	-- self.m_endTime = self.m_endTime - _cfg.loop_duration + _cfg.period
    	end
    else
    	self.m_endTime = nil
    end
end

function view:ShowEndActivity(activity_id)
	if not DialogStack.GetPref_list("guild/guildEnd") then
		DialogStack.PushPref("guild/guildEnd",{Period = activity_Period , activity_id = activity_id});
	end
end

function view:Update()
	if self.m_endTime and self.open then
		local time = self.m_endTime - Time.now();
		if time >=0 then
			local H,M,S = getTimeHMS(math.floor(self.m_endTime - Time.now()))
			self.view.time.Text[UI.Text].text = string.format("%02d:%02d",M,S);
		else
			self.view.time.Text[UI.Text].text = "已结束";
			self.open = nil;
			self.m_endTime = nil;

			self:ShowEndActivity(7);
		end
	elseif not self.open then
		self.view.time.Text[UI.Text].text = "已结束";
	end

	if self.handle_time then
		self.handle_time = self.handle_time - UnityEngine.Time.deltaTime;
		local pos = self.view.area.bg.handle.gameObject.transform.localPosition;
		if pos.y >= 150 then
			self.m_flag = true
			FishModule.PlayQTE(1)
			self.handle_time = nil
			self.view.area.bg.handle.gameObject.transform:DOComplete()
		elseif pos.y <= -182 then
			self.handle_time = nil
			self.view.area.bg.handle.gameObject.transform:DOComplete()
		end
	end

	if self.m_QTEtime then
		local tt = math.floor(self.m_QTEtime - Time.now())
		if tt < 0 then
			self.view.area.bg.handle.gameObject.transform:DOComplete()
		else
			self.view.area.slider.time.Text[UI.Text].text = tostring(tt)
			self.view.area.slider[UI.Slider].value = tt / 5;
			local pos = self.view.area.bg.handle.gameObject.transform.localPosition;
			self.view.area.bg.up[CS.UnityEngine.RectTransform].sizeDelta = CS.UnityEngine.Vector2(80, 182.5-pos.y);
			self.view.area.bg.down[CS.UnityEngine.RectTransform].sizeDelta = CS.UnityEngine.Vector2(80, 182.5+pos.y);
		end
	end
	if not self.m_index or not self.m_time then
		return
	end
	local tt = self.m_time - Time.now()
	if tt < 0 then
		self:getFish()
		return
	end
end

function view:OnDestroy()
	-- print(TAG, "OnDestroy ===================>>")
	SetItemTipsStateAndShowTips(true)
end

function view:listEvent()
	return {"FISH_QUERY_ROOM","FISH_PUSH_ROD","FISH_PULL_ROD","FISH_PLAY_FISH","FISH_PLAYER_QTE", "MAP_CLIENT_EVENT_11", "FISH_AREA_ENTER", "FISH_AREA_EXIT",
		"GUILD_ACTIVITY_ENDNOTIFY",
		"GUILD_SCORE_INFO_CHANGE",
}
end

function view:onEvent( event,... )
	-- print(TAG, event, "===========>>")
	if event == "FISH_QUERY_ROOM" then
		self:initFishRoom()
	end
	if event == "FISH_PUSH_ROD" then
		self:startFishing()
	end
	if event == "FISH_PULL_ROD" then
		local num = select(1, ...)
		if num == 0 then
			self:showGetFish(1)
		elseif num == 2 then
			FishModule.PlayFish()
		elseif num == 3 then
			DispatchEvent("showDlgError", {nil, "鱼溜走了"})
		elseif num == 1 then
			self:doQTEAction()
			return
		end
		self:stopFish()
	end
	if event == "FISH_PLAY_FISH" then
		self:showGetFish(1)
		self:stopFish()
	end
	if event == "FISH_PLAYER_QTE" then
		self.m_QTEtime = nil
		local v1 = select(1,...)
		if v1 == 1 then
			self:showGetFish(2)
		else
			DispatchEvent("showDlgError", {nil, "鱼溜走了"})
		end
		self:stopFish()
	end
	if event == "MAP_CLIENT_EVENT_11" then
		local v1 = select(1, ...)
		local v2 = select(2, ...)
		self:showBarrage(v2);
	end
	if event == "FISH_AREA_ENTER" then
		self.pool = ...;
		self:PlayEffect(1);

		self.view.btn.gameObject:SetActive(true)
	end
	if event == "FISH_AREA_EXIT" then
		self.pool = nil;
		self:PlayEffect(1);
		self.view.btn.gameObject:SetActive(false)
	end

	if event == "GUILD_ACTIVITY_ENDNOTIFY" then

		local activity_id = ...;
		if activity_id == 7 then
			-- body
			self:ShowEndActivity(7);
		end
		-- body
	end

	if event == "GUILD_SCORE_INFO_CHANGE" then
		local data = ...
		if data == 7 then
			local score = module.TreasureModule.GetActivityScore(7)
			self.view.score.point[UI.Text].text = score;
			-- body
		end
	end
	-- 
end

function view:initFishRoom(force)
	local data = FishModule.CreateRoom(force)
	if data then
		self.m_info = data
	end
end

function view:leaveRoom()
	FishModule.QuitRoom()
	FishModule.OutRoom()
end
function view:PlayEffect( flag )
	
	if flag == 1 then
		self.view.tips:SetActive(true)
		self.view.tips.effect:SetActive(false)
		if self.pool then
			self.view.tips.Text[UI.Text].text = "请点击鱼竿开始钓鱼！"
			self.view.tips.effect:SetActive(true)
		else
			self.view.tips.effect:SetActive(true)
			self.view.tips.Text[UI.Text].text = "请前往甲板上的钓鱼区域！"
		end
		-- self.view.tips.effect.glow[UnityEngine.ParticleSystem]:Stop(true);
		-- self.view.tips.effect.glow[UnityEngine.ParticleSystem]:Play(true);
	else
		self.view.tips:SetActive(false)
	end
	 
end

function view:startFishing()
	local minTime,pTime = FishModule.GetMinPullTime()
	self.m_index = pTime
	self.m_time = minTime
	if self.m_state then
		self.m_state:SetAnimation(0, "animation2", false)
		self.m_state:AddAnimation(0, "animation3", true, 0)
	end
end

function view:getFish()
	self.m_index = nil
	SGK.Action.DelayTime.Create(2):OnComplete(function()
		self.fish.btn.gameObject:SetActive(true);
	end)
	FishModule.PullRod()
end

function view:stopFish()
	if self.m_state then
		self.m_state:SetAnimation(0, "animation5", false)
		self.m_state:AddAnimation(0, "animation1", true, 0)
	end
	self.m_index = nil
	self.m_time = nil

	FishModule.ResetPushing()

	StartCoroutine(function()
		WaitForSeconds(1)
		SetItemTipsStateAndShowTips(true)
	end)
	SGK.Action.DelayTime.Create(2):OnComplete(function()
		self.fish.btn.gameObject:SetActive(true);
	end)
	
end

function view:doQTEAction()
	if self.m_state then
		self.m_state:SetAnimation(0, "animation4", true)
	end
	self.view.area.gameObject:SetActive(true)
	-- self.view.area.bg.handle.gameObject.transform:DOKill()

	self.m_QTEtime = Time.now() + 5
	math.randomseed(os.time())
	local posY = math.random(-100, 0)
	self.m_flag = false
	self.view.area.bg.handle.gameObject.transform.localPosition = Vector3(0, posY, 0)
	local tween = self.view.area.bg.handle.gameObject.transform:DOBlendableLocalMoveBy(Vector3(0,-600,0), 25)--:OnUpdate(function()
	-- tween:DOKill();
	tween:OnUpdate(function ( ... )
		
	end)
	local time = module.Time.now();
	self.fish.btn:SetActive(false);
	self.handle_time = 25;
	tween:OnComplete(function ( ... )
		local pos = self.view.area.bg.handle[UnityEngine.RectTransform].anchoredPosition;
		self.view.area.bg.handle[UnityEngine.RectTransform].anchoredPosition = UnityEngine.Vector2(self.view.area.bg.handle[UnityEngine.RectTransform].anchoredPosition.x,UnityEngine.Mathf.Clamp(self.view.area.bg.handle[UnityEngine.RectTransform].anchoredPosition.y,175,-182))

		if pos.y < 182 and not self.m_flag then
			FishModule.PlayQTE(2)
		end
		self.handle_time = nil;
		-- print("++++",module.Time.now() - time);
		self.m_QTEtime = nil
		self.view.area.gameObject:SetActive(false)
		-- FishModule.PlayQTE(1)
	end)

	local potri = self.view.area.btn[CS.UGUIPointerEventListener]
	CS.UGUIClickEventListener.Get(self.view.area.btn.gameObject).onClick = function (obj)
		StartCoroutine(function()
			self.view.area.bg.flag[UI.Image].color = { r = 1, g = 1, b = 1, a = 1};
			self.view.area.bg.flag.flag[UI.Image].color = { r = 1, g = 1, b = 1, a = 1};
			WaitForSeconds(0.1);
			self.view.area.bg.flag[UI.Image].color = { r = 1, g = 1, b = 1, a = 0};
			self.view.area.bg.flag.flag[UI.Image].color = { r = 1, g = 1, b = 1, a = 0};
		end)
		local pos = self.view.area.bg.handle.gameObject.transform.localPosition
		self.view.area.bg.handle.gameObject.transform.localPosition = Vector3(pos.x, (pos.y + 40>190 and 190 or pos.y + 40), pos.z)
	end
end

function view:showGetFish(type)
	local reward = FishModule.GetFishReward()
	local str
	if reward then
		local v = ItemHelper.Get(41, reward.id, reward.value)
		if v then
			str = tostring(v.name)
		end
	else
		str = "普通鱼"
		type = 1
	end
	StartCoroutine(function()
		WaitForSeconds(1)
		DispatchEvent("showDlgError", {nil, "获得"..str})
	end)

	self:getScrollData();
	local player = module.playerModule.Get();
	utils.SGKTools.MapBroadCastEvent(11, {player.name,str,type});
end

function view:showBarrage(data)
	local prefab;
	local str;
	if data[3] == 2 then
		prefab = self.view.list.Text2.gameObject;
		str = data[1].."钓到了 <color=#D45656>"..data[2].."</color>";
	else
		prefab = self.view.list.Text1.gameObject;
		str = data[1].."钓到了 "..data[2];
	end
	local item = CS.UnityEngine.GameObject.Instantiate(prefab, self.view.list.list.gameObject.transform);
	local posY = math.random(-180, 240)
	item.transform.localPosition = CS.UnityEngine.Vector3(420, posY, 0);
	item.transform:DOBlendableLocalMoveBy(CS.UnityEngine.Vector3( -1000, 0, 0), 14):OnComplete(function()

		if utils.SGKTools.GameObject_null(item) == true then
			UnityEngine.Destroy(item);
		end
	end)
	item:SetActive(true)
	item.transform:GetComponent(typeof(UI.Text)).text = str;
end

return view