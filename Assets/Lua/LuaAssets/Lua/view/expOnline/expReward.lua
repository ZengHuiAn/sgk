local View = {}
local expModule = require "module.expModule"

function View:Start(data)
	self.view = SGK.UIReference.Setup(self.gameObject);
	self.view.bg.gameObject:SetActive(false);
	self.time = 0.3;
	
	-- ERROR_LOG(sprinttb(data));
	self.data = data;
	self:FreshReward();

	self.view.bg.fog[CS.UGUIClickEventListener].onClick = function ()
		DialogStack.Pop();
	end
end

function View:FreshReward()
	local itemCfg = module.ItemModule.GetGiftItem(self.data.value[2],function(_cfg)
			-- ERROR_LOG(sprinttb(_cfg))
			self:FreshScrollView(_cfg);
		end);
end

function View:Update()

	if self.time then
		if self.time>0 then
			self.time = self.time - UnityEngine.Time.deltaTime;
		else
			self.time = nil;
			self:WaitDone();
		end
	end
	
end

function View:WaitDone()
	self.view.bg.gameObject:SetActive(true);
	SetItemTipsStateAndShowTips(true);
end

function View:FreshScrollView(reward)
	self.scroll = self.view.bg.rewardContent.scroll.ScrollView[CS.UIMultiScroller];
	self.scroll.RefreshIconCallback = function (obj, idx)
		obj.gameObject:SetActive(true);
		local item = SGK.UIReference.Setup(obj);
		local data = reward[idx+1];
		-- print("====",sprinttb(data));
		self:FreshItem(item,data);
	end
	self.scroll.DataCount = #reward or 0;
end
function View:FreshItem(item,data)
	utils.IconFrameHelper.Create(item.IconFrame, {count = data[3],id = data[2], type = data[1],showDetail= true});
end


function View:OnDestroy()
	SetItemTipsStateAndShowTips(true);
end

function View:listEvent()
    return {

    }
end

function View:onEvent(event,data)
end


return View;