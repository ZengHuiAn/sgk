local EquipmentModule = require "module.equipmentModule";
local EquipmentConfig = require "config.equipmentConfig";

local View = {}

local EquipPosToIdx = {[1] = 1,[2] = 4,[3] = 2,[4] = 3,[5] = 5,[6] = 6}
local ScaleTab = {[4] = 0.85,[5] = 0.8,[6] = 0.7}--默认大小0.85
function View:Start(data)
	self.root = CS.SGK.UIReference.Setup(self.gameObject)
	self.view = self.root.view

	self.heroId = data and data.heroId or 11000
	self.equipTab = data and data.equipTab or {}
	self.state = data and data.state or false
	self.suitIdx = data and data.suitIdx or 0

	CS.UGUIClickEventListener.Get(self.root.mask.gameObject).onClick = function (obj)
		CS.UnityEngine.GameObject.Destroy(self.gameObject)
	end

	CS.UGUIClickEventListener.Get(self.view.Cancel.gameObject).onClick = function (obj)
		CS.UnityEngine.GameObject.Destroy(self.gameObject)
	end

	CS.UGUIClickEventListener.Get(self.view.Ensure.gameObject).onClick = function (obj)
		self:quickToHero(self.equipTab,self.heroId,self.suitIdx)
		CS.UnityEngine.GameObject.Destroy(self.gameObject)
	end

	self.view.tip[UI.Text].text = SGK.Localize:getInstance():getValue("有部位已被装备,是否继续替换")



	local equipList = {}
	for k,v in pairs(self.equipTab) do
		if v ~= 0 then
			local _equip = EquipmentModule.GetEquip()[v]
			if _equip and _equip.heroid ~= 0 and (_equip.heroid ~= self.heroId or (_equip.heroid == self.heroId and _equip.suits ~= self.suitIdx)) then
				table.insert(equipList,{placeholder = k,cfg = _equip})
			end
		end
	end

	table.sort(equipList,function (a,b)
		return a.placeholder < b.placeholder
	end)

	for i=1,#equipList do
		local item = utils.SGKTools.GetCopyUIItem(self.view.equipList,self.view.equipList.item,i)

		local scale_PI = ScaleTab[#equipList] and ScaleTab[#equipList] or ScaleTab[4]
		item:GetComponent(typeof(UnityEngine.UI.LayoutElement)).preferredHeight = 130*scale_PI
		item:GetComponent(typeof(UnityEngine.UI.LayoutElement)).preferredWidth = 130*scale_PI
		item.IconFrame.transform.localScale = Vector3.one*scale_PI


		utils.IconFrameHelper.Create(item.IconFrame, {customCfg = equipList[i].cfg,
			showDetail = true,
			showOwner  = true,
			onClickFunc = function ()
				DialogStack.PushPref("newEquip/equipInfoFrame", {uuid =equipList[i].cfg.uuid})
			end
		});
	end
end

function View:quickToHero(equipTab,heroId,suitIdx)
	for k,_uuid in pairs(equipTab) do
		local _equip = EquipmentModule.GetHeroEquip(heroId, k,suitIdx)
		if _uuid ~= 0 then
			if not _equip or _equip.uuid ~= _uuid then
				local equiIsOpen = EquipmentConfig.GetEquipOpenLevel(suitIdx,k)--套装 位置(除第一套装，一件则全部开启)
				if equiIsOpen then
					EquipmentModule.EquipmentItems(_uuid,heroId, k, suitIdx)
				end
			end
		else
			if _equip then
				EquipmentModule.UnloadEquipment(_equip.uuid)
			end
		end
	end
end

return View;