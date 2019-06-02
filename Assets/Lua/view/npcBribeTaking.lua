local ItemModule = require "module.ItemModule"
local npcConfig = require "config.npcConfig"
local IconFrameHelper = require "utils.IconFrameHelper"
local rewardModule = require "module.RewardModule"
local npcConfig = require "config.npcConfig"
local View = {};
function View:Start(data)
	self.view = CS.SGK.UIReference.Setup(self.gameObject)
	self.Data = data
	-- self.click_value = nil
	-- self.HeroView = nil
	-- self.shoplist = {{}}
	-- self.shopidx = 1
	-- self.shopitemgid = nil
	--print(data.id)
	self.npc_id = data.id
	self.npc_List = npcConfig.GetnpcList()
	self.npcTopicCfg = npcConfig.GetnpcTopic()
	self.npcCfg=module.HeroModule.GetConfig(self.npc_id);
	self.npcFriendCfg=npcConfig.GetNpcFriendList()
	self.npcGiftDescList=npcConfig.GetGiftDescList(self.npc_id)
	local npcTopicCfg = self.npcTopicCfg[self.npc_id]
	--print("zoe npcBribeTaking",sprinttb(data),sprinttb(self.npcCfg))
	-- print("zoe npcBribeTaking",sprinttb(self.npcGiftDescList))
	self.view.mask[CS.UGUIClickEventListener].onClick = function ( ... )
		UnityEngine.GameObject.Destroy(self.gameObject)
	end
	self.view.Close[CS.UGUIClickEventListener].onClick = function ( ... )
		UnityEngine.GameObject.Destroy(self.gameObject)
		--DialogStack.Pop()
	end
	self.view.name[UI.Image]:LoadSprite("title/yc_n_"..self.npc_id)
	local animation = self.view.spine[CS.Spine.Unity.SkeletonGraphic];
    animation.skeletonDataAsset = SGK.ResourcesManager.Load("roles/"..self.npc_id.."/"..self.npc_id.."_SkeletonData.asset") or SGK.ResourcesManager.Load("roles_small/11000/11000_SkeletonData.asset");
    --animation.skeletonDataAsset =SGK.ResourcesManager.Load("roles/11000/11000_SkeletonData");
    self.view.spine.transform.localScale=Vector3(0.4,0.4,1)
    animation.startingAnimation = "idle";
    animation.startingLoop = true;
    animation:Initialize(true);
    self.select = nil
	local desc_list = module.NPCModule.GetNPClikingList(self.Data.id)
	self.firstUp = true
	self.selecttb={}
	self.shop_id = self.npcFriendCfg[self.npc_id].shop_id
	self.shop = module.ShopModule.GetManager(self.shop_id)
	if not self.shop then
		self:UpShop()
	else
		self:UpUI()
	end
	self:initGuide()
end

function View:initGuide()
    module.guideModule.PlayByType(134,0.2)
end

function View:sort(list)
	table.sort(list,function (a,b)
		if ItemModule.GetConfig(a.consume_item_id1).quality ~= ItemModule.GetConfig(b.consume_item_id1).quality then
			return ItemModule.GetConfig(a.consume_item_id1).quality > ItemModule.GetConfig(b.consume_item_id1).quality
		end
		return a.product_item_value > b.product_item_value
	end)
end

function View:UpUI()
	--self.shop.shoplist
	local _view=self.view.ScrollView.Viewport.Content
	local _index = 0
	local list = {}
	if not self.shop.shoplist then
		return
	end
	self:init()
	local haveList = {}
	local nohaveList = {}
	for k,v in pairs(self.shop.shoplist)do
		if ItemModule.GetItemCount(v.consume_item_id1) > 0 then
			haveList[#haveList+1] = v
		else
			nohaveList[#nohaveList+1] = v
		end
	end
	self:sort(haveList)
	self:sort(nohaveList)
	for k,v in pairs(haveList) do
		list[#list+1] = v
	end
	for k,v in pairs(nohaveList) do
		list[#list+1] = v
	end

	self.nguiDragIconScript = self.view.ScrollView.Viewport.Content[CS.ScrollViewContent]
	self.nguiDragIconScript.RefreshIconCallback = (function (obj,idx)
		local go = CS.SGK.UIReference.Setup(obj)
		local v = list[idx + 1]
		utils.IconFrameHelper.Create(go.IconFrame, {type = v.consume_item_type1, id = v.consume_item_id1, count = 0, showDetail = false})
		local _haveCount = ItemModule.GetItemCount(v.consume_item_id1)
		if _haveCount == 0 then
			go.haveCount[UI.Text].text="<color=red>".._haveCount.."</color>"
		else
			go.haveCount[UI.Text].text=_haveCount
		end
		CS.UGUIClickEventListener.Get(go.tip.gameObject).onClick = function()
			DialogStack.PushPrefStact("ItemDetailFrame", {id = v.consume_item_id1,InItemBag = 2},UnityEngine.GameObject.FindWithTag("UITopRoot").gameObject)
		end
		go.tip.Text[UI.Text].text=ItemModule.GetConfig(v.consume_item_id1).name
		--print("zoe npcBribeTaking",i,v.consume_item_id1,v.gid,sprinttb())
		go.numBg.Text[UI.Text].text="+"..v.product_item_value
		--if ItemModule.GetItemCount(v.consume_item_id1)>0 then
			self.selecttb[idx+ 1]={gid=v.gid,id=v.consume_item_id1}
		--end
		if v.drop == 3017 then
			go.tag[CS.UGUISpriteSelector].index = 0
			go.tag[UnityEngine.RectTransform].anchoredPosition = CS.UnityEngine.Vector2(40,34)
		elseif v.drop == 3018 then
			go.tag[CS.UGUISpriteSelector].index = 1
			go.tag[UnityEngine.RectTransform].anchoredPosition = CS.UnityEngine.Vector2(30,34)
		else
			go.tag:SetActive(false)
		end
		if self.firstUp and idx == 0 then
			go.select.gameObject:SetActive(true)
			self.select = go.select
			CS.UGUIClickEventListener.Get(self.view.sendGift.gameObject).onClick = function ()
				if tonumber(ItemModule.GetItemCount(self.selecttb[1].id)) > 0 then
					if self.view.Scrollbar[UI.Scrollbar].size == 1 then
	        				showDlgError(nil,"好感度已满,请先完成好感度升级事件")
	        		else
						if ItemModule.GetItemCount(90038) > 0 then
							module.ShopModule.Buy(self.shop_id,self.selecttb[1].gid,1)
						else
							showDlgError(nil,SGK.Localize:getInstance():getValue("haogandu_tips_01"))
						end
					end
				else
					showDlgError(nil,"所需物品数量不足")
				end
			end
			self.firstUp  = false
		end
		CS.UGUIClickEventListener.Get(go.IconFrame.gameObject).onClick = function ()
        	self.select.gameObject:SetActive(false)
        	go.select.gameObject:SetActive(true)
        	self.select = go.select
        	CS.UGUIClickEventListener.Get(self.view.sendGift.gameObject).onClick = function ()
        		if tonumber(ItemModule.GetItemCount(self.selecttb[idx+1].id)) > 0 then
        			if self.view.Scrollbar[UI.Scrollbar].size == 1 then
        				showDlgError(nil,"好感度已满,请先完成好感度升级事件")
        			else
	        			if ItemModule.GetItemCount(90038) > 0 then
	        				module.ShopModule.Buy(self.shop_id,self.selecttb[idx+1].gid,1)
						else
							showDlgError(nil,SGK.Localize:getInstance():getValue("haogandu_tips_01"))
						end
					end
				else
					showDlgError(nil,"所需物品数量不足")
				end
    		end
    	end
		go.gameObject:SetActive(true)
	end)
	self.nguiDragIconScript.DataCount = #list
	if ItemModule.GetItemCount(90038) > 0 then
		self.view.time[UI.Text].text = "次数：".."<color=#00FF48FF>"..ItemModule.GetItemCount(90038).."/20</color>"
	else
		self.view.time[UI.Text].text = "次数：".."<color=red>"..ItemModule.GetItemCount(90038).."</color><color=#00FF48FF>/20</color>"
	end
    if ItemModule.GetItemCount(90038) > 0 then
		self.view.sendGift[UI.Image].color={r=1,g=1,b=1,a=1}
	else
		self.view.sendGift[UI.Image].color={r=0.4,g=0.4,b=0.4,a=1}
	end		
end

function View:playEffert()
	SGK.ResourcesManager.LoadAsync(self.view[SGK.UIReference],"prefabs/effect/UI/fx_aixin.prefab",function (obj)
        local effect = GetUIParent(obj, self.view.effertRoot.transform)
        effect.transform.localPosition = Vector3.zero;
        SGK.Action.DelayTime.Create(2):OnComplete(function()
        	UnityEngine.GameObject.Destroy(effect.gameObject)
		end)
    end)
end

function View:UpShop()
	self.shop = module.ShopModule.GetManager(self.shop_id)
	self:UpUI()
end

function View:init()
	local npc_List = npcConfig.GetnpcList()
	local npc_Friend_cfg = npcConfig.GetNpcFriendList()[self.Data.id]
	--self.view.name[UI.Text].text = npc_List[self.Data.id].name
	local stageNum = module.ItemModule.GetItemCount(npc_Friend_cfg.stage_item)
	local relation = StringSplit(npc_Friend_cfg.qinmi_max,"|")
	local relation_desc = StringSplit(npc_Friend_cfg.qinmi_name,"|")
	local relation_value = ItemModule.GetItemCount(npc_Friend_cfg.arguments_item_id)
	self.view.statusbg[CS.UGUISpriteSelector].index = stageNum
	local relation_Next_value = relation[stageNum+2] or "max"
	if relation_Next_value == "max" then
		self.view.value[UI.Text].text = relation_Next_value
		self.view.Scrollbar[UI.Scrollbar].size = 1
		self.view.need.Text[UI.Text].text="好感度已满"
	else
		self.view.value[UI.Text].text = relation_value.."/"..tonumber(relation_Next_value)
		if (tonumber(relation_Next_value) - relation_value) <= 0 then
			self.view.need.Text[UI.Text].text="请完成好感度升级事件"
		else
			self.view.need.Text[UI.Text].text="还需"..(tonumber(relation_Next_value) - relation_value).."到".."<color=#28FF00FF>"..relation_desc[stageNum+2].."</color>"
		end
		if relation_value > tonumber(relation_Next_value) then
			self.view.Scrollbar[UI.Scrollbar].size = 1
		else
			self.view.Scrollbar[UI.Scrollbar].size = relation_value/math.floor(relation_Next_value)
		end
	end
	CS.UGUIClickEventListener.Get(self.view.gift.gameObject).onClick = function ()
        DialogStack.PushPrefStact("npcChat/npcGiftRecord",self.Data)
    end
end

function View:GetRandomDesc(type)
	local desc = nil
	if type == 1 then
		local flag = 3
		for i=1,3 do
			if self.npcGiftDescList[1]["like"..i] == "" then
				flag = flag - 1
			end
		end
		if flag == 0 then
			desc = "我收下了"
		else
			local _flag = math.random(1,flag)
			desc = self.npcGiftDescList[1]["like".._flag]
		end
	elseif type == 2 then
		local flag = 2
		for i=1,2 do
			if self.npcGiftDescList[1]["normal"..i] == "" then
				flag = flag - 1
			end
		end
		if flag == 0 then
			desc = "我收下了"
		else
			local _flag = math.random(1,flag)
			desc = self.npcGiftDescList[1]["normal".._flag]
		end
	elseif type == 3 then
		if self.npcGiftDescList[1].specia_up_words then
			desc = self.npcGiftDescList[1].specia_up_words
		else
			desc = "我收下了"
		end
	elseif type == 4 then
		if self.npcGiftDescList[1].specia_down_words then
			desc = self.npcGiftDescList[1].specia_down_words
		else
			desc = "我收下了"
		end
	end
	return desc
end

function View:giftSucceed(data)
	if self.view.likeView.Viewport.Content.transform.childCount > 2 then
		local g=self.view.likeView.Viewport.Content.transform:GetChild(1).gameObject
		UnityEngine.GameObject.Destroy(g)
	end
	self:playEffert()
	local _obj =CS.UnityEngine.GameObject.Instantiate(self.view.likeView.Viewport.Content.obj.gameObject,self.view.likeView.Viewport.Content.transform)
	local _objView = CS.SGK.UIReference.Setup(_obj.gameObject)
	local _text = nil
	if data.dropList[1][2] == 3015 then
		_text = self:GetRandomDesc(1)
	elseif data.dropList[1][2] == 3016 then
		_text = self:GetRandomDesc(2)
	elseif data.dropList[1][2] == 3017 then
		_text = self:GetRandomDesc(3)
	elseif data.dropList[1][2] == 3018 then
		_text = self:GetRandomDesc(4)
	end
	_objView.Text[UI.Text].text = _text--:TextFormat(_text,self.npcCfg.name,ItemModule.GetConfig(self.shop.shoplist[data.gid].consume_item_id1).name,self.shop.shoplist[data.gid].product_item_value)
	module.NPCModule.SetNPClikingList(self.Data.id,{time=module.Time.now(),desc="赠送"..ItemModule.GetConfig(self.shop.shoplist[data.gid].consume_item_id1).name..",好感度+"..self.shop.shoplist[data.gid].product_item_value})
	_objView.gameObject:SetActive(true)
	_objView[UnityEngine.CanvasGroup]:DOFade(1,0.5):OnComplete(function ()
		_objView[UnityEngine.CanvasGroup]:DOFade(0,0.5):SetDelay(2.5):OnComplete(function ()
			UnityEngine.GameObject.Destroy(_objView.gameObject)
		end)
	end)
end

function View:onEvent(event,data)
	if event == "SHOP_BUY_SUCCEED" then
		self:UpUI()
		self:giftSucceed(data)
	elseif event == "ITEM_INFO_CHANGE" then
		
	elseif event == "SHOP_INFO_CHANGE" then

    	self:UpShop()
	-- 	if data.id >= 1001 and data.id <= 1099 then
	-- 		self:LoadItem()
	-- 	end
	elseif event == "QUEST_INFO_CHANGE" then
		self:UpUI()
	elseif event == "LOCAL_GUIDE_CHANE" then
        self:initGuide()
	end
end

function View:Update( ... )
end

function View:listEvent()
	return {
	"SHOP_BUY_SUCCEED",
	"ITEM_INFO_CHANGE",
	"SHOP_INFO_CHANGE",
	"QUEST_INFO_CHANGE",
	"LOCAL_GUIDE_CHANE",
	}
end

return View