local ItemModule = require "module.ItemModule"
local npcConfig = require "config.npcConfig"
local IconFrameHelper = require "utils.IconFrameHelper"
local FriendModule = require 'module.FriendModule'
local ChatManager = require 'module.ChatModule'
local playerModule = require "module.playerModule"
local NetworkService = require "utils.NetworkService";
local View = {};
function View:Start(data)
	self.view = CS.SGK.UIReference.Setup(self.gameObject)
	self.Data = data
	self.click_value = nil
	self.Itemlist = {{}}
	self.Itemidx = 1
	self.ItemIconViews = {}
	self.view.mask[CS.UGUIClickEventListener].onClick = function ( ... )
		UnityEngine.GameObject.Destroy(self.gameObject)
	end
	self.view.Close[CS.UGUIClickEventListener].onClick = function ( ... )
		UnityEngine.GameObject.Destroy(self.gameObject)
		--self:ShowNpcDesc(self.HeroView.Label,"大吉大利，今晚吃鸡！", math.random(1,3))
	end
	self.view.leftBtn:SetActive(false)
	self.view.leftBtn[CS.UGUIClickEventListener].onClick = function ( ... )
		self.Itemidx = self.Itemidx - 1
		if self.Itemidx >= 1 then
			self:LoadItem()
			self.view.leftBtn:SetActive(self.Itemidx > 1)
			self.view.rightBtn:SetActive(self.Itemidx < #self.Itemlist)
		end
	end
	--self.view.rightBtn:SetActive(false)
	self.view.rightBtn[CS.UGUIClickEventListener].onClick = function ( ... )
		self.Itemidx = self.Itemidx + 1
		if self.Itemidx <= #self.Itemlist then
			self:LoadItem()
			self.view.leftBtn:SetActive(self.Itemidx > 1)
			self.view.rightBtn:SetActive(self.Itemidx < #self.Itemlist)
		end
	end
	self:init()
	local player=module.playerModule.Get(self.Data.pid);
	--ERROR_LOG(sprinttb(player))
	self:showHero(player.head,self.view.HeroPos)
	local desc_list = module.NPCModule.GetNPClikingList(self.Data.pid)
	if desc_list then
		for i = 1,#desc_list do
			self.view.ScrollViewDesc.Viewport.Content.desc[UI.Text].text = self.view.ScrollViewDesc.Viewport.Content.desc[UI.Text].text..desc_list[i]
			if i < #desc_list then
				self.view.ScrollViewDesc.Viewport.Content.desc[UI.Text].text = self.view.ScrollViewDesc.Viewport.Content.desc[UI.Text].text.."\n"
			end
		end
	end
	self.view.giveDesc:SetActive(not desc_list or #desc_list == 0)
end
function View:init()
	local npc_Friend_cfg = npcConfig.GetNpcFriendList()[0]
	self.view.name[UI.Text].text = self.Data.name

	local relation = StringSplit(npc_Friend_cfg.qinmi_max,"|")
	local relation_desc = StringSplit(npc_Friend_cfg.qinmi_name,"|")
	local relation_value = FriendModule.GetManager(nil,self.Data.pid).liking or 0
	local relation_index = 0
	for i = 1,#relation do
		if relation_value >= tonumber(relation[i]) then
			relation_index = i
		end
	end
	local relation_Next_value = relation[relation_index+1] or "max"
	if relation_Next_value == "max" then
		self.view.value[UI.Text].text = relation_Next_value
		self.view.Scrollbar[UI.Scrollbar].size = 1
	else
		self.view.value[UI.Text].text = (relation_value - tonumber(relation[relation_index])).."/".. math.floor(relation_Next_value - tonumber(relation[relation_index]))
		self.view.Scrollbar[UI.Scrollbar].size = (relation_value - tonumber(relation[relation_index]))/math.floor(relation_Next_value - tonumber(relation[relation_index]))
		self.view.Scrollbar.SlidingArea:SetActive(self.view.Scrollbar[UI.Scrollbar].size > 0)
	end
	self.view.relation[UI.Text].text = relation_desc[relation_index]
	self.view.statusbg[CS.UGUISpriteSelector].index = relation_index-1
	self.view.num[UI.Text].text = "今日剩余次数"..ItemModule.GetItemCount(90037)
	self:LoadItem()
	--module.ShopModule.GetNpcSouvenirShop()
end
function View:LoadItem()
	self.Itemlist = {{}}
	for i = 1,4 do
		self.view.Group[i]:SetActive(false)
	end
	local ItemArr = FriendModule.GetFriend_gift_cfg(3)
	--ERROR_LOG(sprinttb(ItemArr))
	local idx = 0
	table.sort( ItemArr, function (a,b)
		return a.arguments_value > b.arguments_value
	end )
	for i = 1,#ItemArr do
		if #self.Itemlist[#self.Itemlist] == 4 then
			self.Itemlist[#self.Itemlist+1] = {}
		end
		local count = ItemModule.GetItemCount(ItemArr[i].consume_item_id1)
		if count > 0 then
			self.Itemlist[#self.Itemlist][#self.Itemlist[#self.Itemlist]+1] = ItemArr[i]
		end
		if idx < 4 and self.Itemidx == #self.Itemlist and self.Itemlist[#self.Itemlist][idx+1] then
			idx = idx + 1
			local fun = nil
			if count > 0 then
				fun = function ( ... )

				end
			end
			self.view.Group[idx]:SetActive(true)
			if self.ItemIconViews[idx] then
				IconFrameHelper.UpdateItem({id = ItemArr[i].consume_item_id1,type = ItemArr[i].consume_item_type1,count =count},self.ItemIconViews[idx], {func = fun,showDetail = true})
			else
				self.ItemIconViews[idx] = IconFrameHelper.Item({id = ItemArr[i].consume_item_id1,type = ItemArr[i].consume_item_type1,count =count,},self.view.Group[idx], {func = fun,showDetail = true})
			end
			self.ItemIconViews[idx][SGK.ItemIcon].onPointDown = function ( ... )
				if count > 0 then
					local _cfg=utils.ItemHelper.Get(41,ItemArr[i].consume_item_id1)
					self.click_value = ItemArr[i]
					self.view.icon[UI.Image]:LoadSprite("icon/".._cfg.icon)
					self.view.icon:SetActive(true)
				else
					showDlgError(nil,"礼物数量不足")
				end
			end
		end
	end
	self.view.giftDesc:SetActive(idx==0)
	self.view.rightBtn:SetActive(self.Itemidx < #self.Itemlist)
end
function View:Update( ... )
	if self.view.icon.activeSelf then
		if UnityEngine.Input:GetMouseButton(0) then
			self.view.icon.transform.localPosition = self:ScreenToUIPos(CS.UnityEngine.Input.mousePosition)--Vector3(CS.UnityEngine.Input.mousePosition.x,CS.UnityEngine.Input.mousePosition.y,0)
		elseif UnityEngine.Input:GetMouseButtonUp(0) then
			local a,b = self:ScreenToUIPos(CS.UnityEngine.Input.mousePosition),Vector3(-150,220,0)--self.view.pos.transform:GetChild(0).gameObject.transform.localPosition
			--ERROR_LOG(math.floor(CS.UnityEngine.Vector3.Distance(a,b)))
			if math.floor(CS.UnityEngine.Vector3.Distance(a,b)) < 80 then
				--ERROR_LOG(self.Data.pid,self.click_value.consume_item_id1)
				if FriendModule.GetManager(nil,self.Data.pid).rtype == 1 then
					local npc_Friend_cfg = npcConfig.GetNpcFriendList()[0]
					local relation = StringSplit(npc_Friend_cfg.qinmi_max,"|")
					local relation_value = FriendModule.GetManager(nil,self.Data.pid).liking
					local relation_index = 0
					for i = 1,#relation do
						if relation_value >= tonumber(relation[i]) then
							relation_index = i
						end
					end
					if not relation[relation_index+1] then
						showDlgError(nil,SGK.Localize:getInstance():getValue("haogandu_tips_02"))
					elseif ItemModule.GetItemCount(90037) > 0 then
						FriendModule.Giving(self.Data.pid,self.click_value.consume_item_id1,self.click_value.consume_item_type1,self.click_value.arguments_value)
					else
						showDlgError(nil,SGK.Localize:getInstance():getValue("haogandu_tips_01"))--"今日可赠送次数已用完")
					end
				else
					showDlgError(nil,"互为好友才能赠送礼物")
				end
			end
			self.view.icon:SetActive(false)
		end
	end
end
function View:onEvent(event,data)
	if event == "Friend_Giving_Succeed" then
		--赠送成功
		self:ShowNpcDesc(self.HeroView.Label,"大吉大利，今晚吃鸡！", math.random(1,3))
		local item = utils.ItemHelper.Get(self.click_value.consume_item_type1, self.click_value.consume_item_id1);
		--local desc = "赠送给了对方一个"..item.name
		local itemName = "<color="..utils.ItemHelper.QualityTextColor(item.quality)..">"..item.name.."</color>"
		local desc = SGK.Localize:getInstance():getValue("haogandu_wanjia_song_0"..item.quality,itemName,self.click_value.arguments_value)
		local desc_list = module.NPCModule.GetNPClikingList(self.Data.pid)
		if desc_list then
			self.view.ScrollViewDesc.Viewport.Content.desc[UI.Text].text = self.view.ScrollViewDesc.Viewport.Content.desc[UI.Text].text.."\n"..desc
		else
			self.view.ScrollViewDesc.Viewport.Content.desc[UI.Text].text = self.view.ScrollViewDesc.Viewport.Content.desc[UI.Text].text..desc
		end
		module.NPCModule.SetNPClikingList(self.Data.pid,desc)
		self.view.giveDesc:SetActive(false)
		self:init()

		desc = SGK.Localize:getInstance():getValue("haogandu_wanjia_xiaoxi_0"..item.quality,itemName,self.click_value.arguments_value)
		NetworkService.Send(5009,{nil,self.Data.pid,3,desc,""})
 		if playerModule.IsDataExist(self.Data.pid) then
 			ChatManager.SetManager({fromid = self.Data.pid,fromname = playerModule.IsDataExist(self.Data.pid).name,title = desc},1,3)--0聊天显示方向1右2左
 		else
 			playerModule.Get(self.Data.pid,(function( ... )
 				ChatManager.SetManager({fromid = Giving_sn[sn].pid,fromname = playerModule.IsDataExist(self.Data.pid).name,title = desc},1,3)--0聊天显示方向1右2左
 			end))
 		end
	end
end
function View:listEvent()
	return {
		"Friend_Giving_Succeed",
	}
end
function View:ScreenToUIPos(screenPos)
    local nguiPos = Vector3(0,0,0)
    nguiPos.x = screenPos.x * (750 / UnityEngine.Screen.width) - 375;
    nguiPos.y = screenPos.y * (self.view[UnityEngine.RectTransform].rect.height / UnityEngine.Screen.height) - (self.view[UnityEngine.RectTransform].rect.height/2);
    return nguiPos;
end
function View:showHero(id,parent)
	local cfg = module.HeroModule.GetInfoConfig()
	if cfg[id] then
		--obj = CS.UnityEngine.GameObject.Instantiate(SGK.ResourcesManager.Load("prefabs/newCharacterIcon"),self.view.transform)
		SGK.ResourcesManager.LoadAsync("prefabs/base/npcUI.prefab",function (prefab)
			local obj = CS.UnityEngine.GameObject.Instantiate(prefab,self.view.pos.transform)
			self.HeroView = SGK.UIReference.Setup(obj)
			self.HeroView.transform.localPosition = Vector3(-150,130,0)--parent.transform.position
			self.HeroView.transform.localScale = Vector3(2,2,2)
			--PLayerIcon.transform.localScale = Vector3(0.8,0.8,0.8)
			--PLayerIcon[SGK.newCharacterIcon]:SetInfo({head = id,level = 0,name = "",vip=0},true)
	    	local animation = self.HeroView.spine[CS.Spine.Unity.SkeletonGraphic];
	    	animation:UpdateSkeletonAnimation("roles_small/"..cfg[id].mode_id.."/"..cfg[id].mode_id.."_SkeletonData")
			--animation.startingAnimation = actionName
			animation.startingLoop = true
	    	animation:Initialize(true);
	    	self.HeroView.Label.name:TextFormat("")
			obj:SetActive(true)
			self:ShowNpcDesc(self.HeroView.Label,cfg[id].talk, math.random(1,3))
			self.HeroView[CS.UGUIClickEventListener].onClick = function ( ... )
				utils.SGKTools.HeroShow(id)
			end
		end)
	else
		ERROR_LOG(nil,"配置表role_info中"..id.."不存在")
	end
end
function View:ShowNpcDesc(npc_view,desc,type, fun)
	npc_view.dialogue.bg1:SetActive(type == 1)
	npc_view.dialogue.bg2:SetActive(type == 2)
    npc_view.dialogue.bg3:SetActive(type == 3)
    npc_view.dialogue.desc[UnityEngine.UI.Text].text = desc

    if npc_view.qipao and npc_view.qipao.activeSelf then
        npc_view.qipao[UnityEngine.CanvasGroup]:DOFade(0,0.5):OnComplete(function()
            npc_view.dialogue[UnityEngine.CanvasGroup]:DOFade(1,1):OnComplete(function()
                npc_view.dialogue[UnityEngine.CanvasGroup]:DOFade(0,1):OnComplete(function()
                    npc_view.dialogue.desc[UnityEngine.UI.Text].text = "";
                    if fun then
                        fun()
                    end
                    npc_view.qipao[UnityEngine.CanvasGroup]:DOFade(1,0.5);
                end):SetDelay(1)
            end)
        end)
    else
    	npc_view.dialogue[UnityEngine.CanvasGroup]:DOPause()
        npc_view.dialogue[UnityEngine.CanvasGroup]:DOFade(1,1):OnComplete(function()
            npc_view.dialogue[UnityEngine.CanvasGroup]:DOFade(0,1):OnComplete(function()
                npc_view.dialogue.desc[UnityEngine.UI.Text].text = "";
                if fun then
                    fun()
                end
            end):SetDelay(1)
        end)
    end
end
return View
