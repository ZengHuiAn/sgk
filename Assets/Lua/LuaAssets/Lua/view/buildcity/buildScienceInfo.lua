local View = {};

local BuildScienceModule = require "module.BuildScienceModule"
local buildScienceConfig = require "config.buildScienceConfig"
local QuestModule = require("module.QuestModule")
local activityConfig = require "config.activityConfig" 
function View:Start(data)
	-- guanqiazhengduo35
	-- guanqiazhengduoButton12
	self.root = CS.SGK.UIReference.Setup(self.gameObject)

	self.view = self.root.root;
	self.view.bg.Text[UI.Text].text = SGK.Localize:getInstance():getValue("guanqiazhengduo35");
	self.view.bg.closeBtn[CS.UGUIClickEventListener].onClick = function ()
		DialogStack.Pop();		
	end

	self.root.mask[CS.UGUIClickEventListener].onClick = function ()
		DialogStack.Pop();		
	end

	self.level = data.level;
	
	self.mapid = data.map_id;
	self.type = data.type;

	local depot = module.BuildShopModule.GetMapDepot(self.mapid);

	if depot then
		self.depot = depot;
	else
		module.BuildShopModule.QueryMapDepot(self.mapid,true);
	end
	--科技等级
	self:FreshAllUI();
end


function View:initLeft()
	-- guild_cfg
	-- self.data[self.level].icon

	-- ERROR_LOG("========>>>",sprinttb(self.data[self.level]));
	self.view.left.bg.bg.icon[UI.Image]:LoadSprite("icon/"..self.data[self.level].icon)
	self.view.left.bg.bg.icon.Text[UI.Text].text = "^"..(self.level-1);

	self.view.left.bg.Image.name[UI.Text].text = self.data[self.level].name;


end


function View:FreshAllUI( ... )

	local info = BuildScienceModule.GetScience(self.mapid);
	self.info = info;
	self._info = QuestModule.CityContuctInfo()

	self.cfg = activityConfig.GetCityConfig(self.mapid)

	local lastLv,exp,_value = activityConfig.GetCityLvAndExp(self._info,self.cfg.type);
	self.lastLv = lastLv;

	self.level = info.data[self.type]+1; 
	local guild_cfg = buildScienceConfig.GetScienceConfig(self.mapid,self.type);
	self.data = guild_cfg;
	self:initLeft();
	self:initRight();
end

function View:initRight( ... )
	self.view.right.now.nowDesc[UI.Text].text = self.data[self.level].describe or "无";
	-- Manage

	self.cityDepotResource = module.BuildShopModule.GetMapDepot(self.mapid)
	local info = module.unionModule.Manage:GetSelfUnion();

	if self.data[self.level+1] then

		self.view.right.next.nextDesc[UI.Text].text = self.data[self.level+1].describe;
		local list = self.view.right.research.itemList;
		local flag = nil;
		if self.depot then
			flag = false;
		end
		if info and info.unionId == self.info.title and info.leaderId == module.playerModule.Get().id then

		else
			self.view.right.researchBtn.tip:SetActive(false);
			self.view.right.researchBtn.gameObject:SetActive(false);
			self.view.right.lockInfo.gameObject:SetActive(true);
			self.view.right.lockInfo[UI.Text].text = SGK.Localize:getInstance():getValue("guanqiazhengduo38")
			self.view.right.research.gameObject:SetActive(false)

			return
		end

		for i=1,4 do
			local data = self.data[self.level+1].expend[i];
			-- ERROR_LOG("==============",self.level,sprinttb(data));
			if not data then
				list[i].gameObject:SetActive(false);
			else
				list[i].gameObject:SetActive(true);
				
				if flag ~= nil then
					if self.depot[data.id] then
						local _info = self.depot[data.id];
						-- print("=============",sprinttb(_info))
						--仓库的资源足够
						if _info.value < data.value then
							flag = true;
							-- break;
						end
					end
				end
				self:initReward(list[i],data);
			end
		end
		local tip_desc = string.format(  "需要繁荣度%s级",self.data[self.level+1].city_level)

		local color_desc_red = "<color=red>%s</color>"

		local end_desc = (self.lastLv < self.data[self.level +1].city_level) and string.format( color_desc_red,tip_desc ) or tip_desc
		-- (self.lastLv < self.data[self.level +1].city_level) and 
		self.view.right.researchBtn.Text[UI.Text].text = SGK.Localize:getInstance():getValue("guanqiazhengduoButton12");
		self.view.right.researchBtn.tip[UI.Text].text = end_desc

		if self.level == 1 then
			self.view.right.researchBtn.Text[UI.Text].text = SGK.Localize:getInstance():getValue("guanqiazhengduoButton14");
		end
		-- ERROR_LOG(#self.data[self.level+1].expend);
		if not self.data[self.level+1].expend or #self.data[self.level+1].expend == 0 then
			self.view.right.researchBtn[UnityEngine.RectTransform].anchoredPosition = UnityEngine.Vector2(-58,-190);
			self.view.right.researchBtn.tip[UnityEngine.RectTransform].anchoredPosition = UnityEngine.Vector2(-58,-150);
		else
			self.view.right.researchBtn[UnityEngine.RectTransform].anchoredPosition = UnityEngine.Vector2(159,-190);
			self.view.right.researchBtn.tip[UnityEngine.RectTransform].anchoredPosition = UnityEngine.Vector2(159,-150);
		end


		-- if flag == true then
		-- 	self.view.right.researchBtn[CS.UGUIClickEventListener].interactable = false;
		-- else
		-- 	self.view.right.researchBtn[CS.UGUIClickEventListener].interactable = false;
		-- end
		
		self.view.right.researchBtn[CS.UGUIClickEventListener].onClick = function ()

			if self.lastLv < self.data[self.level +1].city_level then
				return showDlgError(nil,"当前城市等级不足");
			else
				BuildScienceModule.UpGradeScience(self.mapid,self.type,(self.level -1));
			end
		end
		
		
		self.view.right.researchBtn.tip:SetActive(true);

	else
		self.view.right.next.nextDesc[UI.Text].text = "设施已满级"
		self.view.right.researchBtn.tip:SetActive(false);
		self.view.right.researchBtn.gameObject:SetActive(false);
		-- 
		self.view.right.research.gameObject:SetActive(false)
	end
	self.view.right.lockInfo.gameObject:SetActive(false);
	
	if info and info.unionId == self.info.title and info.leaderId == module.playerModule.Get().id then

	else
		self.view.right.researchBtn[UI.Button].interactable = false;

		self.view.right.researchBtn[CS.UGUIClickEventListener].onClick = function ( ... )
			
			showDlgError(nil,SGK.Localize:getInstance():getValue("guanqiazhengduo38"));
		end
	end
end


function View:initReward(item,data)
	local info = module.ItemModule.GetConfig(data.id);
	item.icon[UI.Image]:LoadSprite("icon/"..info.icon.."_small");
	-- ERROR_LOG(sprinttb(data),self.cityDepotResource[data.id]);
	local resource = 0
	if not self.cityDepotResource[data.id] or not self.cityDepotResource[data.id].value then
	else
		resource = self.cityDepotResource[data.id].value
	end
	item.number[UI.Text].text = resource < data.value and "<color=red>" .. "x"..data.value .."</color>" or "x"..data.value
	-- self.mapid
	
	item.icon[UI.Image].raycastTarget = true;
	CS.UGUIClickEventListener.Get(item.icon.gameObject).onClick = function()
		DialogStack.PushPrefStact("ItemDetailFrame", {InItemBag=2,id = data.id,type = utils.ItemHelper.TYPE.ITEM})
	end
end

function View:listEvent( ... )
	return {
		"UPGRADE_SUCCESS",
		"UPGRADE_ERROR",
		"QUERY_MAP_DEPOT",
	}
end


function View:onEvent( event,data )
	
	if event == "UPGRADE_SUCCESS" then
		if data == self.mapid then
			self:FreshAllUI();
		end
	elseif event == "UPGRADE_ERROR" then
		return showDlgError(nil,"当前科技已经被改变");
	elseif event == "QUERY_MAP_DEPOT" then
		if data == self.mapid then
			self.depot = module.BuildShopModule.GetMapDepot(self.mapid);
			self:initRight();
		end
	end
end




return View;