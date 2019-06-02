

local WorldAnswerConfig = require "config.WorldAnswerConfig"
local WorldAnswerModule = require "module.WorldAnswerModule"
local ItemHelper = require "utils.ItemHelper"

local View = {};

function View:SetOnClick(btn,func)
	btn[UI.Button].onClick:RemoveAllListeners();
	btn[UI.Button].onClick:AddListener(func);
end

function View:Start()
	local data = WorldAnswerConfig.getRewardInfo();
    print(sprinttb(data));
	local view = SGK.UIReference.Setup(self.gameObject)
	self:SetOnClick(view.root.exitBtn,function ()
		DialogStack.Pop();
	end);

	self.UIDragIconScript = view.root.bg.scroll[CS.UIMultiScroller];
    self.UIDragIconScript.RefreshIconCallback = function (obj, idx)
    	obj.gameObject:SetActive(true);
    	local ret = data[idx+1];
        print(sprinttb(ret));

        local reward = ret.reward;

        local item = SGK.UIReference.Setup(obj.gameObject)
    	item.desc[UI.Text].text = "积分达到 "..tostring((ret.correct)*10).." 获得";
        for k,v in pairs(reward) do

            if v then
                --todo
                local cfg = module.ItemModule.GetConfig(v.id);

                utils.IconFrameHelper.Create(item["reward"..k], {type = 41, id = cfg.id,showName = false,showDetail = true,count = v.value,func = function ( prefab )
                    prefab.gameObject.transform.localScale = UnityEngine.Vector3(0.6,0.6,1)
                    -- body
                end });
            end
        end
	end;


	self.UIDragIconScript.DataCount = #data
	
end


return View