local View = {}
local expModule = require "module.expModule"
local ItemHelper = require "utils.ItemHelper"

function View:Start(data)
	self.view = SGK.UIReference.Setup(self.gameObject);
	print(sprinttb(data))
	self:FreshDesc("战胜"..tostring(data.steps*3).."个敌人");
	-- self.view.fog
	
	self:FreshReward(data.steps);
	self.steps = data.steps;
	self.current = expModule.GetCurrent();
	-- ERROR_LOG(self.current);
	self:FreshInfo();
	self.view.mask[CS.UGUIClickEventListener].onClick = function ()
		DialogStack.Pop();
	end
end

function View:FreshInfo( ... )
	local info = expModule.GetBoxInfo();

	-- ERROR_LOG(sprinttb(info));
	if info and (not info[self.steps]) then
		if self.current > self.steps * 3 then
			--未领取
			print("可以领取")
			self:FreshBtn(true,true);
		else
			print("不可以领取")
			self:FreshBtn();
		end
	else
		print("已领取")
		self:FreshBtn(nil,true);
	end
end

--status == true 已经领取过了
function View:FreshBtn(flag,status)
	if flag and status then
		self.view.bg.fog.Title[UI.Text].text =  "领取" ;
		self.view.bg.fog[CS.UGUIClickEventListener].interactable = true;
		self.view.bg.fog[CS.UGUIClickEventListener].onClick = function ()
			expModule.AwardsBox(self.steps);
		end
	else
		-- 灰色
		self.view.bg.fog.Title[UI.Text].text = status and "已领取" or "领取" ;
		self.view.bg.fog[CS.UGUIClickEventListener].interactable = false;
		-- status
	end
end

function View:FreshDesc(content)
	self.view.bg.desc.Text[UI.Text].text = content;
end



function View:FreshReward(index)

	local reward = expModule.GetBattleReward(index+15);
	-- ERROR_LOG(sprinttb(reward));

	local itemCfg = module.ItemModule.GetGiftItem(reward[1].id,function(_cfg)

			self:FreshScrollView(_cfg);
		end);
end

function View:FreshScrollView(reward)
	self.scroll = self.view.bg.rewardContent.scroll.ScrollView[CS.UIMultiScroller];
	self.scroll.RefreshIconCallback = function (obj, idx)
		obj.gameObject:SetActive(true);
		local item = SGK.UIReference.Setup(obj);
		local data = reward[idx+1];
		print("====",sprinttb(data));
		self:FreshItem(item,data);
	end
	self.scroll.DataCount = #reward or 0;
end

function View:FreshItem(item,data)
	utils.IconFrameHelper.Create(item.IconFrame, {count = data[3],id = data[2], type = data[1],showDetail= true});
end

function View:OnDestory()

end

function View:listEvent()
    return {
    	"GET_BOX_AWARDS",
    }
end

function View:onEvent(event,data)
	if event == "GET_BOX_AWARDS" then
		if data == true then
			self:FreshBtn(nil,true);
			expModule.QueryBoxInfo();
		else
			showDlgError(nil,"领取失败!");
		end
	end
end


return View;