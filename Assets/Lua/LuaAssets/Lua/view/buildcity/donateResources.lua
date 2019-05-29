local ItemHelper = require "utils.ItemHelper"
local BuildShopModule = require "module.BuildShopModule"
local buildScienceConfig = require "config.buildScienceConfig"
local View = {};
function View:Start(data)
    self.root = CS.SGK.UIReference.Setup(self.gameObject)
	self.view = self.root.view

	self.view.Title[UI.Text].text = SGK.Localize:getInstance():getValue("guanqiazhengduo11")
	CS.UGUIClickEventListener.Get(self.root.mask.gameObject,true).onClick = function()
		DialogStack.Pop()
	end
	CS.UGUIClickEventListener.Get(self.view.Close.gameObject).onClick = function()
		DialogStack.Pop()
	end

	self.mapId = data and data[1]
	self.cityDepotResource = data and data[2]

	self.shopList = BuildShopModule.GetMapShopInfo(self.mapId)
	if self.shopList then
		self.shopList = BuildShopModule.GetMapShopInfo(self.mapId)
		self:InitView()
	else
		BuildShopModule.QueryMapShopInfo(self.mapId)
	end
end

local function GetCopyUIItem(parent,prefab,i)
    local obj = nil
    if i <= parent.transform.childCount then
        obj = parent.transform:GetChild(i-1).gameObject
    else
        obj = CS.UnityEngine.GameObject.Instantiate(prefab.gameObject,parent.transform)
        obj.transform.localPosition = Vector3.zero
    end
    obj:SetActive(true)
    local item = CS.SGK.UIReference.Setup(obj)
    return item
end

function View:InitView()
	local resourcesList = {}
	for k,v in pairs(self.shopList) do
		resourcesList[v.consume[2]] = v
	end

	local resourcesTab = buildScienceConfig.GetResourceConfig();
	for i=1,#resourcesTab do
		local cfg = resourcesTab[i]
		local itemCfg = ItemHelper.Get(utils.ItemHelper.TYPE.ITEM,cfg.item_id,nil,0)
		if itemCfg then
			local item = GetCopyUIItem(self.view.Content,self.view.Content.ItemPrefab,i)
			utils.IconFrameHelper.Create(item.IconFrame,{customCfg = itemCfg,showDetail = true});
			item.title.Text[UI.Text].text = itemCfg.name

			local cityStorage = self.cityDepotResource[cfg.item_id] and self.cityDepotResource[cfg.item_id].value or 0
			item.storage.Text[UI.Text].text = SGK.Localize:getInstance():getValue("guanqiazhengduo07",cityStorage)

			local price = resourcesList[cfg.item_id].consume[3]
			local limitConsume = resourcesList[cfg.item_id] and resourcesList[cfg.item_id].limt_consume[2]
			local canDonateCount = module.ItemModule.GetItemCount(resourcesList[cfg.item_id].limt_consume[2])
			-- ERROR_LOG(resourcesList[cfg.item_id].limt_consume[2],canDonateCount,cfg.item_id)
			-- ERROR_LOG(canDonateCount*price,canDonateCount,price)
			item.num.Text[UI.Text].text = SGK.Localize:getInstance():getValue("guanqiazhengduo08",canDonateCount*price)

			local ownCount = module.ItemModule.GetItemCount(cfg.item_id)
			item.ownNum[UI.Text].text = SGK.Localize:getInstance():getValue("guanqiazhengduo09",ownCount)
		
			item.btn.Text[UI.Text].text = SGK.Localize:getInstance():getValue("guanqiazhengduoButton05",price)--cfg.count)
			
			item.btn[CS.UGUIClickEventListener].interactable = price<= ownCount and canDonateCount>0
			CS.UGUIClickEventListener.Get(item.btn.gameObject).onClick = function()
				item.btn[CS.UGUIClickEventListener].interactable = false

				BuildShopModule.BuyMapProduct(resourcesList[cfg.item_id].gid,1,self.mapId)
				showDlgError(nil,"捐献成功")
			end
		end
	end
end

function View:deActive()
    utils.SGKTools.PlayDestroyAnim(self.gameObject)
	return true;
end

function View:listEvent()
	return {
		"QUERY_MAP_SHOPINFO_SUCCESS",
		"QUERY_MAP_DEPOT",
	}
end

function View:onEvent(event,data)
	if event == "QUERY_MAP_SHOPINFO_SUCCESS" then
		if data and data == self.mapId then
			self.shopList = BuildShopModule.GetMapShopInfo(self.mapId)
			self:InitView()
		end
	elseif event == "QUERY_MAP_DEPOT" then
		if data and data == self.mapId then
			self.cityDepotResource = BuildShopModule.GetMapDepot(self.mapId)
			self:InitView()
		end
	end
end

return View;