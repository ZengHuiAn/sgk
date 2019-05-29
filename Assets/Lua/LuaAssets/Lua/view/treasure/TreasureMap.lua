local View = {}
local mazeConfig = require "config.mazeConfig"

function View:Start(data )
    -- Minimap
    self.flag = data ;
    self.view = CS.SGK.UIReference.Setup(self.gameObject)
    self.eventQuest = mazeConfig.GetTypeInfo(10)    
    print(self.eventQuest)
    for k,v in pairs(self.eventQuest) do
        if v.fight_id and v.fight_id ~=0  then
            self:FreshDoneQuest(v.fight_id);
        end
    end

    CS.UGUIClickEventListener.Get(self.view.mask.gameObject).onClick = function ( ... )
        -- TreasureMap
        DialogStack.Pop();
    end
end

function View:FreshDoneQuest( quest_id )
    local index = 0;
    for i=1,#self.eventQuest do
        if self.eventQuest[i].fight_id == quest_id then
            index = i;
            break;
        end
    end
    self.allMap = self.allMap or {}
    if not module.QuestModule.Get(quest_id) or module.QuestModule.Get(quest_id).status ~= 1 then
        self.view.Root.MapRoot["Map"..index]:SetActive(false);
        self.allMap[index] = nil
    else
        self.allMap[index] = true

            -- ERROR_LOG("============>>>>");
            self.view.Root.MapRoot["Map"..index]:SetActive(true);
        -- SGK.Action.DelayTime.Create(3):OnComplete(function()
        -- end)
    end
    self:CheckAllMap()
end


function View:CheckAllMap( ... )
    for i=1,4 do
        if not self.allMap[i] then
            self.view.Root.AllMap:SetActive(false);
            self.view.Root.MapRoot:SetActive(true);
            return
        end
    end
    self.view.Root.AllMap:SetActive(true);
    self.view.Root.MapRoot:SetActive(false);
    SGK.Action.DelayTime.Create(3.5):OnComplete(function()
        showDlgError(nil,SGK.Localize:getInstance():getValue("migong_suipian3"))
        DialogStack.Pop();
    end)
end


function View:listEvent()
	return{
		"QUEST_INFO_CHANGE",
	}
end


function View:onEvent(event,data)
    if event == "QUEST_INFO_CHANGE" then
        if data and data.npc_id then
            local info = mazeConfig.GetInfo(data.npc_id);

			if  not info then
				return
            end
            self:FreshDoneQuest();
        end
    end
end

return View