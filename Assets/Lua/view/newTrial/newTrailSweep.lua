local trialModule = require "module.trialModule"

local View = {}

function View:Start(data)
	self.view = SGK.UIReference.Setup(self.gameObject);
	self:initData(data)
	self:initClick()
	self:initScrollView()
	self:initView()
end

function View:initData(data)
	self.gid = data.gid
	self.isTop = trialModule.GetIsTop()
	if not self.isTop then
		self.rewardGid = self.gid-1
	else
		self.rewardGid = self.gid
	end
	self:initRewardList()
end

function View:TableAddCount(table,data)
    for i=1,#table do
        if table[i].id == data.id then
            table[i].count = table[i].count + data.count
            return table
        end
    end
    table[#table +1] = {id = data.id,count = data.count,type = data.type}
    return table
end

function View:initRewardList()
	self.iconList = {}
	for i=60000001,self.rewardGid do
		local rewardCfg = trialModule.GetReward(i).accumulate
		for k,v in pairs(rewardCfg) do
			self:TableAddCount(self.iconList,v)
		end
	end
end

function View:initClick()
	CS.UGUIClickEventListener.Get(self.view.Dialog.Content.confirmBtn.gameObject).onClick = function ()
		utils.EventManager.getInstance():dispatch("CONFIRM_TRIAL_SWEEP")
		module.ShopModule.Buy(8,1080008,1)
		DialogStack.Pop()
	end
	CS.UGUIClickEventListener.Get(self.view.Dialog.Close.gameObject).onClick = function ()
		DialogStack.Pop()
	end
	CS.UGUIClickEventListener.Get(self.view.mask.gameObject,true).onClick = function ()
		DialogStack.Pop()
	end
end

function View:initScrollView()
	local UIMultiScroller = self.view.Dialog.Content.ScrollView.Viewport.Content[CS.ScrollViewContent];

	UIMultiScroller.RefreshIconCallback = function(obj, idx)
		obj:SetActive(true);
		local slot = SGK.UIReference.Setup(obj);
		local cfg = self.iconList[idx+1];
		utils.IconFrameHelper.Create(slot.IconFrame, {type = cfg.type, id = cfg.id, count = cfg.count, showDetail = true})
	end

	UIMultiScroller.DataCount = #self.iconList;
end

function View:initView()
	local layer = self.rewardGid - 60000000
	self.view.Dialog.Content.TextBg.Text[UI.Text].text = "已通关"..layer.."层扫荡可获得："
end

function View:listEvent()
    return {
    }
end

function View:onEvent(event,data)

end


return View;