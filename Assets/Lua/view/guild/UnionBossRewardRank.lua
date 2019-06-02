local ItemHelper = require "utils.ItemHelper";
local unionConfig = require "config.unionConfig"
local View = {};

function View:Close()
    DialogStack.Pop();
end


function View:Start(data)


	self.view = SGK.UIReference.Setup(self.gameObject)
	self.pid =  module.playerModule.GetSelfID();
    self.view.view.closeBtn[UI.Button].onClick:AddListener(function ()
        self:Close();
	end);
	local index = data or 2
    local _data = unionConfig.GetUnionBossRank(index);
	self.UIDragIconScript = self.view.view.ScrollView[CS.UIMultiScroller];
    self.UIDragIconScript.RefreshIconCallback = function (obj, idx)
    	obj.gameObject:SetActive(true);
        local item = SGK.UIReference.Setup(obj);
        self:FreshItem(item,_data[idx+1],idx+1);
	end;
	self.UIDragIconScript.DataCount = #_data;

end

function View:FreshItem(parent,data,idx)
	if not parent or  not data or not idx then return end
	if data.Rank1 == data.Rank2 then
		
		parent.rankPlace[UI.Text].text = "第"..data.Rank1.."名";
	else
		parent.rankPlace[UI.Text].text = "第"..data.Rank1.."-"..data.Rank2.."名";
	end



	local ScrollView = parent.giftContent[CS.UIMultiScroller];
	ScrollView.RefreshIconCallback = function (obj, index)
    	obj.gameObject:SetActive(true);
        local item = SGK.UIReference.Setup(obj);
        self:FreshReward(item,data.reward[index+1]);
	end;


	ScrollView.DataCount = #data.reward



end


function View:FreshReward(parent,data)
	-- local cfg = module.ItemModule.GetConfig(data.id);
	utils.IconFrameHelper.Create(parent.IconFrame, {pos = 2,type = data.type,count = data.value,id = data.id,showName = false,showDetail = true})
end
return View;