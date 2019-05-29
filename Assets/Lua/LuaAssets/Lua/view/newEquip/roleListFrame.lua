local HeroModule = require "module.HeroModule"

local View = {}
function View:Start(data)
	self.root = CS.SGK.UIReference.Setup(self.gameObject)
	self.view = self.root.view;

	CS.UGUIClickEventListener.Get(self.root.mask.gameObject,true).onClick = function()
		CS.UnityEngine.GameObject.Destroy(self.gameObject)
	end
	self.heroId = data or 11000
	self.heroList = HeroModule.GetSortHeroList(1)

	self.UIDragIconScript = self.view.ScrollView.Viewport.Content[CS.ScrollViewContent]
	self.UIDragIconScript.RefreshIconCallback = function (obj, idx)
		local _view = CS.SGK.UIReference.Setup(obj.gameObject)
		local _tab = self.heroList[idx + 1]
		if _tab and _tab.uuid then
			local _cfg = utils.ItemHelper.Get(utils.ItemHelper.TYPE.HERO, _tab.id)
		
			_view.root.tip:SetActive(false)

			utils.IconFrameHelper.Create(_view.root.IconFrame, {type = 42, customCfg = _cfg})
			_view.root.select:SetActive(_tab.id == self.heroId)
			CS.UGUIClickEventListener.Get(_view.root.gameObject).onClick = function()
				if _tab.id ~= self.heroId then
					local _lastIdx = self:getIdx(self.heroId)
					local _obj = self.UIDragIconScript:GetItem(_lastIdx-1)
					if _obj then
						local _lastSelectItem = CS.SGK.UIReference.Setup(_obj)
						_lastSelectItem.root.select:SetActive(false)
					end

					self.heroId = _tab.id
					_view.root.select:SetActive(true)
					DispatchEvent("LOCAL_NEWROLE_HEROIDX_CHANGE", {heroId = self.heroId})
				end
			end
			obj:SetActive(true)
		end
	end
	self.UIDragIconScript.DataCount = #self.heroList

	local _idx = self:getIdx(self.heroId)
    self.UIDragIconScript:ScrollMove(_idx - 1)
end

function View:getIdx(heroId)
	for i,v in ipairs(self.heroList) do
		if v.id == heroId then
			return i
		end
	end
	return 1
end

function View:listEvent()
	return {
		"",
	}
end

function View:onEvent(event, data)
	if event == "" then

	end
end

return View;