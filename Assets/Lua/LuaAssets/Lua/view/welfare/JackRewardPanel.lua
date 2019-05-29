local ItemHelper = require "utils.ItemHelper"
local View = {}

function View:Start(data)
	self.root = CS.SGK.UIReference.Setup(self.gameObject)
	self.view = self.root.view

	self.JackPotTabUI={}
	self:ShowJackPot(data)
end

local luckTextTab = {"末吉","小吉","中吉","大吉","大大吉"}
function View:ShowJackPot(data)
	local showTab = data[1]
	local luckId = data[2]
	self.view.Tip:SetActive(not not luckId)
	self.view.Tip[UI.Text].text = SGK.Localize:getInstance():getValue("kucunmiaoshu_01",luckTextTab[luckId])

	self.view.title[UI.Text].text=SGK.Localize:getInstance():getValue("biaoti_kucun_01")
	local Jackpot=self.view.Jackpot
    self.tempObj =self.tempObj or  SGK.ResourcesManager.Load("prefabs/base/ItemIcon.prefab")
    for i=1,#showTab do
    	local _obj=nil
		if self.JackPotTabUI[i] then
			_obj=self.JackPotTabUI[i]
		else
			_obj=CS.UnityEngine.GameObject.Instantiate(self.tempObj,Jackpot.Viewport.Content.gameObject.transform)
			_obj.transform.localScale =Vector3(0.8,0.8,1)
			self.JackPotTabUI[i]=_obj
		end
		_obj.gameObject:SetActive(true)
		local item=CS.SGK.UIReference.Setup(_obj.transform)
		local itemCfg=ItemHelper.Get(showTab[i].item_type,showTab[i].item_id)
		item[SGK.ItemIcon]:SetInfo(itemCfg,true,showTab[i].item_value)
		item[SGK.ItemIcon].showDetail=true
		item.ItemDesc.gameObject:SetActive(false)
	end

	CS.UGUIClickEventListener.Get(self.root.mask.gameObject,true).onClick = function()
		DialogStack.Pop()
	end
	CS.UGUIClickEventListener.Get(self.view.exitBtn.gameObject).onClick = function()
		DialogStack.Pop()
	end
end

function View:listEvent()
	return {

	}
end

function View:onEvent(event,data)

end


return View