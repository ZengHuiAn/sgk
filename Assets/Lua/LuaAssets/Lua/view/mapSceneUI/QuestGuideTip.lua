local QuestGuideTip = {}

function QuestGuideTip:Start()
    self:initUi()
end

function QuestGuideTip:initUi()
    self.view = CS.SGK.UIReference.Setup(self.gameObject)
    -- local _guide = module.EncounterFightModule.GUIDE.GetInteractInfo()
    -- if not _guide or not _guide.name then
    --     module.guideModule.QuestGuideTipStatus = nil
    -- end
    if module.guideModule.QuestGuideTipStatus then
        self:setStatus(module.guideModule.QuestGuideTipStatus.id,module.guideModule.QuestGuideTipStatus.npcid)
    else
        self:setStatus();
    end
end

function QuestGuideTip:closeAll()
    if self.view.pathfinding.activeSelf then
        self.view.pathfinding:SetActive(false)
    end
    if self.view.patrol.activeSelf then
        self.view.patrol:SetActive(false)
    end
end
local teamCfg = LoadDatabaseWithKey ("team_battle_config","find_npc")



function QuestGuideTip:setStatus(data,npcid)
    self:closeAll()

    -- ERROR_LOG("++++++++++++++",data,npcid);
    if data then
        if data == 1 then

            if npcid then
                if teamCfg[tonumber(npcid)] then
                    self.view.pathfinding.target:SetActive(true)
                    self.view.pathfinding.target.Text[UI.Text].text = string.format( "正在前往  %s .....",teamCfg[tonumber(npcid)].tittle_name )
                else
                    self.view.pathfinding.target:SetActive(false);
                end
                -- ERROR_LOG("========目标NPC",npcid);
            else
                self.view.pathfinding.target:SetActive(false);
            end
            self.view.pathfinding:SetActive(true)
        elseif data == 2 then
            self.view.pathfinding.target:SetActive(false);
            self.view.patrol:SetActive(true)
        end
    end
end

function QuestGuideTip:listEvent()
    return {
        "NOTIFY_TEAM_GUIDE_CHANGE",
        -- "Map_Click_Player",
    }
end

function QuestGuideTip:onEvent(event, args)
    if event == "NOTIFY_TEAM_GUIDE_CHANGE" then
        local data = nil;
        local targetNpc = nil;
        if args then
            data = args.id;

            targetNpc = args.npcid;
        end
        self:setStatus(data,targetNpc)
    elseif event == "Map_Click_Player" then
        self:closeAll()
    end
end

return QuestGuideTip
