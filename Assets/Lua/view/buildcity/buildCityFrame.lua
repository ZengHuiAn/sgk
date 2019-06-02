local ActivityConfig = require "config.activityConfig"
local BuildScienceModule = require "module.BuildScienceModule"
local BuildCityModule = require "module.BuildCityModule"
local View = {};

local function GetCopyUIItem(parent,prefab,i)
    local obj = nil
    if i <= parent.transform.childCount then
        obj = parent.transform:GetChild(i-1).gameObject
    else
        obj = CS.UnityEngine.GameObject.Instantiate(prefab.gameObject,parent.transform)
        obj.transform.localPosition = Vector3.zero
    end
    obj.name = i
    obj:SetActive(true)
    local item = CS.SGK.UIReference.Setup(obj)
    return item
end

local cityWarInfo = {}
function View:Start(data)
    self.root = CS.SGK.UIReference.Setup(self.gameObject);
    self.view =  self.root.view;

	self.Pid = module.playerModule.GetSelfID();

	self.cityCfg = ActivityConfig.GetSortCityCfg()

	local tabIdx = data and data.Idx or 1
	local mapId = data and data.map_Id or BuildCityModule.GetDefaultMapId()
	self:InitView(mapId,tabIdx)
end

local topTab = {"总览","商店","扭蛋","科技"}
function View:InitView(mapId,tabIdx)
	local resourcesBarObj = CS.UnityEngine.GameObject.Instantiate(SGK.ResourcesManager.Load("prefabs/base/CurrencyChat.prefab"),self.root.transform)
	self:UpdateBetterScreenSize(resourcesBarObj)

	for i=1,#topTab do
		local item = GetCopyUIItem(self.view.Content.topTab,self.view.Content.topTab[1],i)
		item.Text[UI.Text].text = topTab[i]
		item.Text[UI.Text].color = i == tabIdx and UnityEngine.Color.black or UnityEngine.Color.white
	 	item[UI.Toggle].isOn = i == tabIdx

		if i == tabIdx then
			self:updateView(tabIdx,mapId)
		end

		CS.UGUIClickEventListener.Get(item.gameObject,true).onClick = function()
			if tabIdx ~= i then
				local _obj = self.view.Content.topTab.transform:GetChild(tabIdx-1).gameObject
				local topTabItem = CS.SGK.UIReference.Setup(_obj)
				topTabItem.Text[UI.Text].color = UnityEngine.Color.white

				item.Text[UI.Text].color = UnityEngine.Color.black
				tabIdx = i

				self:updateView(i,mapId)
			end
		end
	end

	local selectPageTab = nil
	for i=1,#self.cityCfg do
		local item = GetCopyUIItem(self.view.Content.pageContainer.Viewport.Content,self.view.Content.pageContainer.Viewport.Content[1],i)
		local _cfg = self.cityCfg[i]
		item.Icon.Image[UI.Image]:LoadSprite("icon/buildCity/" .. _cfg.city_picture)
		item.Icon.qualityMark[CS.UGUISpriteSelector].index = _cfg.city_quality-1


		item.fightMark:SetActive(false)
		item.statusMark:SetActive(false)
		item.statusMark[CS.UGUISpriteSelector].index = 1


		item.Icon[UnityEngine.UI.Mask].enabled = _cfg.map_id ~= mapId
		if _cfg.map_id == mapId then
			selectPageTab = item
		end

		CS.UGUIClickEventListener.Get(item.gameObject).onClick = function()
			if mapId ~= _cfg.map_id then
				selectPageTab.Icon[UnityEngine.UI.Mask].enabled = true
				item.Icon[UnityEngine.UI.Mask].enabled = false
				selectPageTab = item

				mapId = _cfg.map_id
				DispatchEvent("LOCAL_SLESET_MAPID_CHANGE",mapId);
			end
		end	
	end
end

local viewTab = {{itemName="buildCity/totalInfo"},{itemName="buildCity/buildShop"},{itemName="buildCity/drawCard"},{itemName="buildCity/buildScience"}}
function View:updateView(tabIdx,map_Id)
	if self.nowSelectItem then
		self.nowSelectItem = DialogStack.GetPref_list(self.nowSelectItem)
		if self.nowSelectItem then
			UnityEngine.GameObject.Destroy(self.nowSelectItem)
		end
	end
	if viewTab[tabIdx] and viewTab[tabIdx].itemName~="" then
		self.nowSelectItem = viewTab[tabIdx].itemName
		DialogStack.PushPref(viewTab[tabIdx].itemName, map_Id, self.view.Content.Node.gameObject)
	end
end

local function GetCityWarInfo(mapId,allInfo)
	cityWarInfo = cityWarInfo or {}
	cityWarInfo[mapId] = {status = 2}--status--2不显示 0已报名 1-占领者
	local uninInfo = module.unionModule.Manage:GetSelfUnion();
	if allInfo[mapId] and allInfo[mapId].apply_begin_time ~= -1 then
		cityWarInfo[mapId].fightting = true
		if uninInfo and uninInfo.id then
			for i,v in ipairs(allInfo[mapId].apply_list) do
				if v == uninInfo.id then
					cityWarInfo[mapId].status = 0;
				end
			end

			if cityWarInfo[mapId].status == 2 then
				--防守方
				BuildScienceModule.QueryScience(mapId,function (cityInfo)
					local ownerId = cityInfo and cityInfo.title or 0;
					if ownerId == uninInfo.id then
						cityWarInfo[mapId].status = 1;
					end
				end)
			end
		end

		cityWarInfo[mapId].final_begin_time = allInfo[mapId].final_begin_time
		local warInfo = module.GuildGrabWarModule.Get(mapId);
		if warInfo.war_info.attacker_gid then
			warInfo:Query();
		end
		-- --争夺战开始
		-- if cityWarInfo[mapId].final_begin_time<= module.Time.now() then
		-- 	cityWarInfo[mapId].status = 2;
		-- end
		--争夺战结束
		if warInfo.final_winner ~= -1 then
			cityWarInfo[mapId].status = 2;
			cityWarInfo[mapId].fight_finish = true
		end
		--无人报名
		if next(allInfo[mapId].apply_list)==nil then
			cityWarInfo[mapId].fight_abolish = true
			if cityWarInfo[mapId].final_begin_time and cityWarInfo[mapId].final_begin_time<= module.Time.now() then
				cityWarInfo[mapId].status = 2;
			end
		end
	end
end
--争夺战
function View:UpdateCityWarInfo()
	local cityCfg = self.cityCfg
	if cityCfg then
		coroutine.resume(coroutine.create( function ()
			local allInfo = module.GuildSeaElectionModule.GetAll(true);
			for i=1,#cityCfg do
				local mapId = cityCfg[i].map_id
				GetCityWarInfo(mapId,allInfo)
				
				if cityWarInfo[mapId] then
					local item = CS.SGK.UIReference.Setup(self.view.Content.pageContainer.Viewport.Content.transform:GetChild(i-1).gameObject)
					if item then
						--报名或防守状态
						item.statusMark:SetActive(cityWarInfo[mapId].status~=2)
						if cityWarInfo[mapId].status~=2 then
							item.statusMark[CS.UGUISpriteSelector].index = cityWarInfo[mapId].status
						end

						--该城市有争夺战,并且未结束
						if cityWarInfo[mapId].fightting and not cityWarInfo[mapId].fight_finish and not cityWarInfo[mapId].fight_abolish and cityWarInfo[mapId].final_begin_time and cityWarInfo[mapId].final_begin_time<= module.Time.now() then
							item.fightMark:SetActive(false)
							if item.fightingNode.transform.childCount==0 and not cityWarInfo[mapId].fx then
								cityWarInfo[mapId].fx = self:playEffect("combat_ui",nil,item.fightingNode.transform)
							end
						else
							if cityWarInfo[mapId].fightting then
								item.fightMark:SetActive(true)
							end
							for i=1,item.fightingNode.transform.childCount do
								local fx_obj = item.fightingNode.transform:GetChild(i-1).gameObject
								UnityEngine.Object.Destroy(fx_obj)
							end
							cityWarInfo[mapId].fx = nil
						end
					end
				end
			end
		end))
	end
end

local lastRefreshTime = 0
function View:Update()
	if module.Time.now() - lastRefreshTime>=15 then
		if #self.cityCfg <= self.view.Content.pageContainer.Viewport.Content.transform.childCount then
			lastRefreshTime = module.Time.now()
			-- self:UpdateCityWarInfo()
		end
	end
end

function View:playEffect(effectName, position, node, sortOrder)
    local prefab = SGK.ResourcesManager.Load("prefabs/effect/UI/" .. effectName .. ".prefab");
    local o = prefab and UnityEngine.GameObject.Instantiate(prefab, node.transform);
    if o then
        local transform = o.transform;
        transform.localPosition = Vector3.zero--position or Vector3.zero;
        --transform.localScale = Vector3.zero
        transform.localRotation = Quaternion.identity;
        if sortOrder then
            SGK.ParticleSystemSortingLayer.Set(o, sortOrder);
        end
    end
    return o
end

--适应超长屏UI填充
function View:UpdateBetterScreenSize(resourcesBarObj)
	if resourcesBarObj then
		local resourcesBar = CS.SGK.UIReference.Setup(resourcesBarObj)
		if resourcesBar then
			local off_top = resourcesBar.UGUIResourceBar.TopBar[UnityEngine.RectTransform].rect.height
			local off_bottom = resourcesBar.UGUIResourceBar.BottomBar[UnityEngine.RectTransform].rect.height
			local off_H = (self.root[UnityEngine.RectTransform].rect.height-self.view[UnityEngine.RectTransform].rect.height)/2
			if off_top and off_bottom then
				self.root.top[UnityEngine.RectTransform]:SetSizeWithCurrentAnchors(UnityEngine.RectTransform.Axis.Vertical, off_H+ off_top)
				self.root.bottom[UnityEngine.RectTransform]:SetSizeWithCurrentAnchors(UnityEngine.RectTransform.Axis.Vertical, off_H+off_bottom )
			end
		end
	end
end

function View:deActive()
    utils.SGKTools.PlayDestroyAnim(self.gameObject)
	return true;
end

function View:initGuide()
    module.guideModule.PlayByType(122,0.2)
end

function View:listEvent()
	return {
		"GUILD_SEA_ELECTION_APPLY_SUCCESS",
		"LOCAL_CITYWAR_STATUS_CHANGE",

		"LOCAL_GUIDE_CHANE",
		"GUILD_GRABWAR_FINISH",
	}
end

function View:onEvent(event,data)
	if event == "GUILD_SEA_ELECTION_APPLY_SUCCESS"  or event == "LOCAL_CITYWAR_STATUS_CHANGE" then
		--self.Setted = false
		lastRefreshTime = 0
	elseif event == "LOCAL_GUIDE_CHANE" then
		self:initGuide()
	elseif event == "GUILD_GRABWAR_FINISH" then--争夺战结束
		if data and data.map_id and cityWarInfo[data.map_id] and cityWarInfo[data.map_id].fx then
			UnityEngine.Object.Destroy(cityWarInfo[data.map_id].fx)
			cityWarInfo[data.map_id].fx = nil
		end
	end
end

return View;