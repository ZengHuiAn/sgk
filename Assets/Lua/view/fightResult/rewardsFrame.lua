local ItemHelper = require "utils.ItemHelper"
local TipConfig=require "config.TipConfig"
local View={}

function View:Start(data)
	self.view = SGK.UIReference.Setup(self.gameObject);
	self:UpdateReward(data)
end

function View:ShowNoReward(dayTip)
	self.view.RewardTimeUseUp.gameObject:SetActive(true)
	-- self.view.RewardTimeUseUp.gameObject.transform:DOLocalMove(Vector3(0,-360,-100),0.1):OnComplete(function ( ... )     
		self.view.RewardTimeUseUp.Tip[UI.Text].text=dayTip and "今日活动奖励次数已用尽" or "本周活动奖励次数已用尽"		
	-- end):SetDelay(1)   
end

local CantGetTipItemId=90113--不获得额外奖励道具标识
local CantGetWeekTipItemId=90116--不获得额外周奖励道具标识
function View:UpdateReward(rewards)
	if not rewards then return end
	self.reward_will_create = self.reward_will_create or {};
	-- 合并相同的奖励
	self.create_info = self.create_info or {};

	for _, v in ipairs(rewards) do
		local type,id,value,uuid= v[1],v[2],v[3],(v[4]~=0 and v[4]);--uuid 有 可能 是 无效的0
		if type ~= 90 and id ~= 90000 then
			local key = id * 1000 + type * 10+(v[4] or 0);
			if not self.create_info[key] then
				self.create_info[key] = {}
				table.insert(self.reward_will_create, v)
			end
			self.create_info[key].total_value = (self.create_info[key].total_value or 0) + value;
		end
		if type == 90 and id == 90000 then
			local item = ItemHelper.Get(ItemHelper.TYPE.ITEM, id, nil, v[3]);
			local color = "<color="..ItemHelper.QualityTextColor(item.quality)..">"
		end
		if id==CantGetTipItemId or id==CantGetWeekTipItemId then
			self:ShowNoReward(id==CantGetTipItemId)
		end
	end

	for _, v in pairs(self.create_info) do
		v.value = v.total_value;
		v.total_value = nil;

		if v.icon then
			v.icon.Count = v.value;
		end
	end

	if not self.can_create_reward and not self.animation_running and #self.reward_will_create > 0 then
		local y = self.have_score_info and -200 or -90;
		self.animation_running = true;
		self.view.Content.gameObject:SetActive(true)

		--self.view.transform:DOScale(Vector3.one,0.5):OnComplete(function ( ... )
		-- self.view.Content.titleBg.Image.gameObject.transform:DOLocalMove(Vector3.zero,0.1)
		--self.view.Content.titleBg.Image[UI.Image]:DOFade(1,0.1):OnComplete(function ( ... )
			--双倍道具消耗则显示双倍加成标识
			local doubleAward = GetRawardItemChange()
			self.view.Content.titleBg.doubleTip.gameObject:SetActive(doubleAward)

			print("animation finished")
			self.animation_running = nil;
			self.can_create_reward = true;
		--end)
		--end)
	end
end


local showLeadReward = nil
local showTeamLeaderShow = false
local ShowDoubleRewardTipTab = {[90401]=true,[90402]=true,[90403]=true,[90404]=true,[90016]=true,[90019]=true}--显示队长加成奖励的道具
function View:Update()
	if not self.can_create_reward or #self.reward_will_create == 0 then
		return;
	end

	self.pass = (self.pass or 0.15) + UnityEngine.Time.deltaTime;
	if self.pass < 0.15 then
		return;
	end
	self.pass = 0;

	--奖励类型
	if not showLeadReward and showTeamLeaderShow then--是否为队长
		local _teamInfo = module.TeamModule.GetTeamInfo();
		if _teamInfo and _teamInfo.leader and _teamInfo.leader.pid == module.playerModule.GetSelfID() then
			showLeadReward=true
		end
	end

	self.reward_parent_transform = self.reward_parent_transform or self.view.Content.Viewport.Content.gameObject.transform;
	-- self.prefab = self.view.ItemIcon

	local v = self.reward_will_create[1];
	table.remove(self.reward_will_create, 1);
	if v[1] ~= 90 and v[2] ~= 90000  then
		local type,id,uuid = v[1],v[2],(v[4]~=0 and v[4]);
		local key = id * 1000 + type * 10 + (v[4] or 0);
		local value = self.create_info[key].value;

		local item = ItemHelper.Get(v[1], v[2], nil, value);
		if item.is_show ~= 0 then
			local CommonIconPool = CS.GameObjectPool.GetPool("CommonIconPool");
			local ItemIcon = SGK.UIReference.Setup(CommonIconPool:Get(self.reward_parent_transform))
			ItemIcon.transform.localScale = Vector3.one * 0.9
			ItemIcon:SetActive(true)
			utils.IconFrameHelper.UpdateIcon({type=type,id=id,uuid=uuid,count=value},ItemIcon, {
				showDetail = true,
				onClick = function ()
					local UIRootParent = UnityEngine.GameObject.FindWithTag("battle_root").gameObject
					if UIRootParent then
						local _root = SGK.UIReference.Setup(UIRootParent).Canvas.UIRoot
						DialogStack.PushPrefStact("ItemDetailFrame", {id = id,type = type,uuid =uuid},_root.gameObject)
					else
						DialogStack.PushPrefStact("ItemDetailFrame", {id = id,type = type,uuid =uuid},UnityEngine.GameObject.FindWithTag("UITopRoot"))
					end
				end,
				
			});

			local _markSprite = self.view.Content._mark_sprite[UI.Image].sprite
			if showLeadReward and ShowDoubleRewardTipTab[id] then
				ItemIcon[CS.SGK.CommonIcon]:SetMark("Mark1",_markSprite)

				ItemIcon[CS.SGK.CommonIcon]._Mark[0]:SetNativeSize()
				ItemIcon[CS.SGK.CommonIcon]._Mark[0].transform:GetComponent(typeof(UnityEngine.RectTransform)).anchorMin = CS.UnityEngine.Vector2(0.5,1)
				ItemIcon[CS.SGK.CommonIcon]._Mark[0].transform:GetComponent(typeof(UnityEngine.RectTransform)).anchorMax = CS.UnityEngine.Vector2(0.5,1)
				ItemIcon[CS.SGK.CommonIcon]._Mark[0].transform.localPosition = Vector3(0,55,0)
			else
				ItemIcon[CS.SGK.CommonIcon]:SetMark("Mark1")
			end
			-- local obj = SGK.UIReference.Instantiate(self.prefab)
			-- obj:SetActive(true)

			-- local go=SGK.UIReference.Setup(obj)
			-- if go then
			-- 	go.transform:SetParent(self.reward_parent_transform, false);

			-- 	utils.IconFrameHelper.Create(go.IconFrame,{type=type,id=id,uuid=uuid,count=value, showDetail = true,onClickFunc=function ()
			-- 		local UIRootParent = UnityEngine.GameObject.FindWithTag("battle_root").gameObject
			-- 		if UIRootParent then
			-- 			local _root = SGK.UIReference.Setup(UIRootParent).Canvas.UIRoot
			-- 			DialogStack.PushPrefStact("ItemDetailFrame", {id = id,type = type,uuid =uuid},_root.gameObject)
			-- 		else
			-- 			DialogStack.PushPrefStact("ItemDetailFrame", {id = id,type = type,uuid =uuid},UnityEngine.GameObject.FindWithTag("UITopRoot"))
			-- 		end
			-- 	end})
			-- 	go.TopImage.gameObject:SetActive(showLeadReward and ShowDoubleRewardTipTab[id])
			-- end
		end
    end
end

function View:listEvent()
	return {
		"battle_event_close_result_panel"
	}
end

function View:onEvent(event)
	if event == "battle_event_close_result_panel" then
		self.view:SetActive(false);
	end
end

return View;
