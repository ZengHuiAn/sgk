local View = {};
local TreasureModule = require "module.TreasureModule"
local Time = require "module.Time"

function View:Start( data )
    SetItemTipsStateAndShowTips(false);
    self.view = CS.SGK.UIReference.Setup(self.gameObject);
    -- ERROR_LOG
    self.activityID = data.activity_id;
    self.Period = data.Period;
    self.content = self.view.view.bg.scroll.content;
    
    
    -- print("ret",sprinttb(self.reward))
    
    TreasureModule.GetUnionRank(self.activityID,self.Period,function ( _rank_data )
        if _rank_data then
            local rank = _rank_data.rank[1];
            self.current = rank;
            local cfg = TreasureModule.GetReward(self.activityID);
            self.reward = self:FreshData(cfg).reward;

            self:FreshScroll();
        end
    end);

    self.view.view.bg.btn.rank[CS.UGUIClickEventListener].onClick = function ( ... )
        DialogStack.PushPrefStact("guild/UnionActivityRank",{Period = self.Period, activity_id = self.activityID});
    end
    self.view.view.bg.btn.exit[CS.UGUIClickEventListener].onClick = function ( ... )
        SceneStack.EnterMap(1);
    end

    self.closeTime = Time.now() + 10;
end

function View:Update()
    if self.closeTime then
        local time = self.closeTime - Time.now();

        if time > 0 then
            self.view.view.bg.time[UI.Text].text = math.floor(time).."秒后将自动离开场景";
        else
            self.closeTime = nil
            SceneStack.EnterMap(1);
        end
    end
end

function View:FreshData(all_cfg)
	local up = nil;
	for i=1,#all_cfg do

		if up then
			for j=up,all_cfg[i].rank_range do
				if self.current == j then
					return all_cfg[i];
				end
			end
		else
			if self.current == i then
				return all_cfg[i];
			end
		end
		up = all_cfg[i].rank_range;
	end
end


function View:FreshScroll()
    for i=1,3 do
        local obj = self.content["item"..i];
        local data = self.reward[i]

        if data then
            
            if data.id == 90021 then
                local sciene_lev = module.unionScienceModule.GetScienceInfo(14) and module.unionScienceModule.GetScienceInfo(24).level or 0 
                utils.IconFrameHelper.Create(obj,{id = data.id,type = data.type,count = data.value * (1+sciene_lev*0.2),showDetail = true});
            else
                utils.IconFrameHelper.Create(obj,{id = data.id,type = data.type,count = data.value,showDetail = true});
            end
        end
    end
end
function View:OnDestroy( ... )
    SetItemTipsStateAndShowTips(true);
end

return View;