local ItemHelper = require "utils.ItemHelper";
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
	
    local _data = module.TreasureModule.GetReward(data);

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
	local ret = string.gsub(data.rank_client, '[~]', '-');
	parent.rankPlace[UI.Text].text = "第"..ret.."名";


	local ScrollView = parent.giftContent[CS.UIMultiScroller];
	ScrollView.RefreshIconCallback = function (obj, index)
    	obj.gameObject:SetActive(true);
        local item = SGK.UIReference.Setup(obj);
        self:FreshReward(item,data.reward[index+1]);
	end;
	ScrollView.DataCount = #data.reward



end


function View:FreshReward(parent,data)


	local cfg = ItemHelper.Get(data.type,data.id);

	-- print(sprinttb(cfg));
	-- -- local prefab=SGK.ResourcesManager.Load("prefabs/IconFrame");
	-- parent.ItemIcon[SGK.ItemIcon]:SetInfo(cfg,true,data.value)
	
	-- parent.ItemIcon[SGK.ItemIcon].showDetail= true
	-- item["ItemIcon"..(tostring(i))].ItemDesc.gameObject:SetActive(false)

	cfg.count = data.value
	utils.IconFrameHelper.Create(parent.IconFrame, {customCfg = cfg,showName=true,showDetail = true,func = function ( obj)
		-- obj.gameObject.transform.localScale = UnityEngine.Vector3(0.4,0.4,0.4);
		-- parent.IconFrame.gameObject.transform.localScale = UnityEngine.Vector3(0.6,0.6,0.6);
	end})


end
return View;