
local QuestModule = require "module.QuestModule"
local Time = require "module.Time"

local View = {};
function View:Start(data)
    self.view = CS.SGK.UIReference.Setup(self.gameObject);
    self.pid = data and data.pid or 0; 
    self.updateTime = 0;
	self:InitData();
	self:InitView();
end

function View:InitData()
    self.manorProductInfo = module.ManorManufactureModule.Get(self.pid);
    self.manorInfo = module.ManorModule.LoadManorInfo();
    self.isOwner = module.playerModule.GetSelfID() == self.pid;
end

function View:InitView()
    self.view.bottom.news:SetActive(true);
    self.view.bottom.steal:SetActive(true);
    self.view.my:SetActive(not self.isOwner);
    if self.isOwner then
        self.view.bottom.gameObject.transform.localPosition = self.view.bottom.gameObject.transform.localPosition + Vector3(0, 70, 0);
        self.view.friend.gameObject.transform.localPosition = self.view.friend.gameObject.transform.localPosition + Vector3(0, 70, 0);
    else
        module.playerModule.Get(self.pid, function (player)
            utils.IconFrameHelper.Create(self.view.owner.IconFrame, {pid = self.pid});
            self.view.owner.Text[UnityEngine.UI.Text]:TextFormat("{0}的基地", player.name);
            self.view.owner:SetActive(true);
        end)
    end
    self.view.bottom.steal.Text[UnityEngine.UI.Text]:TextFormat("事件 {0}/10", module.ItemModule.GetItemCount(1401));
    self.view.bottom.news.Text[UnityEngine.UI.Text]:TextFormat("新闻 {0}/10", module.ItemModule.GetItemCount(1405));
    CS.UGUIPointerEventListener.Get(self.view.bottom.steal.gameObject).onPointerDown = function()
        self.view.bottom.steal.tip:SetActive(true);
    end
    CS.UGUIPointerEventListener.Get(self.view.bottom.steal.gameObject).onPointerUp = function()
        self.view.bottom.steal.tip:SetActive(false);
    end
    CS.UGUIPointerEventListener.Get(self.view.bottom.news.gameObject).onPointerDown = function()
        self.view.bottom.news.tip:SetActive(true);
    end
    CS.UGUIPointerEventListener.Get(self.view.bottom.news.gameObject).onPointerUp = function()
        self.view.bottom.news.tip:SetActive(false);
    end
    
    CS.UGUIClickEventListener.Get(self.view.my.gameObject).onClick = function (obj)
        SceneStack.EnterMap(26, {mapid = 26, room = module.playerModule.GetSelfID()})
    end
    CS.UGUIClickEventListener.Get(self.view.friend.gameObject).onClick = function (obj)
        DialogStack.Push("manor/ManorFriend")
    end
    CS.UGUIClickEventListener.Get(self.view.bottom.quest.gameObject).onClick = function (obj)
        local quest = QuestModule.GetList(23, 0)[1];
        if quest then
            if module.QuestModule.CanSubmit(quest.id) and #quest.consume ~= 0 then
                local list = module.ManorRandomQuestNPCModule.GetManager():QueryNPC()
                if list[quest.npc_id] then
                    showDlgError(nil,"回到自己基地交付任务吧~")
                else
                    DialogStack.Push("manor/ManorFriend")
                end
            else
                local teamInfo = module.TeamModule.GetTeamInfo();
                if teamInfo.group == 0 or module.playerModule.Get().id == teamInfo.leader.pid then
                    module.QuestModule.StartQuestGuideScript(quest)
                else
                    showDlgError(nil,"你正在队伍中，无法进行该操作")
                end
            end            
        end
    end
    -- CS.UGUIClickEventListener.Get(self.view.steal.gameObject).onClick = function (obj)
    --     if module.ItemModule.GetItemCount(90167) == 0 then
    --         showDlgError(nil, "今日偷取次数已用完")
    --         return;
    --     end
    --     for i,v in ipairs(self.manorInfo) do
    --         if v.line ~= 0 and self.manorProductInfo:CanSteal(v.line) then
    --             DispatchEvent("ENTER_MANOR_BUILDING", v.line);
    --             return;
    --         end
    --     end
    --     showDlgError(nil, "暂时没有东西偷取")
    -- end
    self:UpdateQuest();
end

function View:UpdateQuest()
    self.quest = nil;
    local list = QuestModule.GetList(23, 0);
    if #list == 0 then
        self.view.bottom.quest:SetActive(false);
    else
        local view = self.view.bottom.quest;
        local quest = list[1];
        view.root.name[UI.Text].text = quest.name;
        print("任务计数", quest.id, sprinttb(quest.records))
        if QuestModule.CanSubmit(quest.id) then
            view.root.name[UI.Text].text ="<color=#1EFF00FF>"..quest.name.."</color>"
            view.root.canCommit.gameObject:SetActive(true)
            if view.root.canCommit.gameObject.transform.childCount == 0 then
                local obj = CS.UnityEngine.GameObject.Instantiate(SGK.ResourcesManager.Load("prefabs/effect/UI/fx_ui_kuang_reward.prefab"),view.root.canCommit.gameObject.transform)
                obj.transform.localPosition = Vector3(-10.4, 14.7, 0);
                obj.transform.localScale = Vector3(1.17, 1, 1);
            end
        else
            view.root.canCommit.gameObject:SetActive(false)
        end
        if quest.time_limit and quest.time_limit ~= 0 then
            local _endTime = quest.accept_time + quest.time_limit
            local _off = _endTime - Time.now();
            if _off > 0 then
                view.root.time[UI.Text].text = GetTimeFormat(_off, 2);
                self.quest = quest;
            else
                view.root.time[UI.Text].text = "";
            end
        else
            view.root.time[UI.Text].text = "";
        end
        self.view.bottom.quest:SetActive(true);
    end
end

function View:Update()
    if Time.now() - self.updateTime >= 1 then
        self.updateTime = Time.now();
        if self.quest then
            if self.quest.time_limit and self.quest.time_limit ~= 0 then
                local _endTime = self.quest.accept_time + self.quest.time_limit
                local _off = _endTime - Time.now();
                if _off > 0 then
                    self.view.bottom.quest.root.time[UI.Text].text = GetTimeFormat(_off, 2);
                else
                    self.view.bottom.quest.root.time[UI.Text].text = "";
                    self.view.bottom.quest:SetActive(false);
                end
            end
        end
    end
end

function View:listEvent()
	return {
        "MANOR_SCENE_CHANGE",
        "LOCAL_TASKLIST_ARROW_CHANGE",
        "MANOR_MANUFACTURE_STEAL_SUCCESS",
        "QUEST_INFO_CHANGE",
        "ITEM_INFO_CHANGE"
	}
end

function View:onEvent(event, ...)
	print("onEvent", event, ...);
	if event == "MANOR_SCENE_CHANGE" then
        local state,pid = ...;
        if not state then
            UnityEngine.GameObject.Destroy(self.gameObject);
        end
    elseif event == "LOCAL_TASKLIST_ARROW_CHANGE" then

    elseif event == "MANOR_MANUFACTURE_STEAL_SUCCESS" then
        self.view.bottom.steal.Text[UnityEngine.UI.Text]:TextFormat("事件 {0}/10", module.ItemModule.GetItemCount(90167));
    elseif event == "QUEST_INFO_CHANGE" then
        self:UpdateQuest();
    elseif event == "ITEM_INFO_CHANGE" then
        self.view.bottom.steal.Text[UnityEngine.UI.Text]:TextFormat("事件 {0}/10", module.ItemModule.GetItemCount(1401));
        self.view.bottom.news.Text[UnityEngine.UI.Text]:TextFormat("新闻 {0}/10", module.ItemModule.GetItemCount(1405));
	end
end

return View;