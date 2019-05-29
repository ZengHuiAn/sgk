local MapConfig = require "config.MapConfig"
local Time = require "module.Time"

local mapSceneQuestList = {}

function mapSceneQuestList:Start()
    self.view = CS.SGK.UIReference.Setup(self.gameObject)
    self.tip = self.view.tip;
    self.mapCfg = MapConfig.GetMapConf(SceneStack.MapId())
    self.updateTime = 0;
    self.recommend = 0;
    self.isShow = utils.SGKTools.SaveContainers("QuestUIShow", nil, true);
    self:initData()
    self:initUi()
    self:upItemList()
end

function mapSceneQuestList:initData()
    self.questUI = {}
    self.questList = {}
    for k,v in pairs(module.QuestModule.GetList(nil, 0)) do
        if v.cfg then
            if v.is_show_on_task == 0 and self:filtrateQuest(v.cfg.cfg.type) then
                table.insert(self.questList, v)
            end
        end
    end
    -- self:checkOtherQuest();
    table.sort(self.questList, function(a, b)
        if a.priority ~= b.priority then
            return a.priority > b.priority
        end
        if a.frame_type ~= b.frame_type then
            return a.frame_type > b.frame_type
        end
        if a.type ~= b.type then
            return a.type < b.type
        end
        return a.id < b.id
    end)
    --print("zoe 查看快捷任务表",sprinttb(self.questList))
end

function mapSceneQuestList:filtrateQuest(questType)
    local UIQuest = StringSplit(self.mapCfg.Uiquest,"|")
    for k,v in pairs(UIQuest) do
        if tonumber(questType) == tonumber(v) then
            return true
        end 
    end
    return false
end

function mapSceneQuestList:checkOtherQuest()
    local _tab = BIT(self.mapCfg.Uishow or 0)
    for i,v in ipairs(_tab) do
        if tonumber(v) == 1 then
            if i == 6 then
               return;
            end
        end
    end    
    for i,v in pairs(module.QuestModule.GetList()) do
        if v.mapId and v.mapId == SceneStack.MapId() then
            table.insert(self.questList, v)
            break;
        end
    end
end

function mapSceneQuestList:initUi()
    CS.UGUIClickEventListener.Get(self.view.quest.gameObject).onClick = function()
        DialogStack.Push("mapSceneUI/newQuestList", {mapScene = true})
    end
    CS.UGUIClickEventListener.Get(self.view.switch.gameObject).onClick = function()
        if self.isShow then
            self.isShow = utils.SGKTools.SaveContainers("QuestUIShow", false);
            self.view.switch.arrow.transform:DORotate(Vector3(0, 0, 180), 0.3):SetEase(CS.DG.Tweening.Ease.InCubic);
            self.view.quest.transform:DOLocalMove(Vector3(-300, self.view.quest.gameObject.transform.localPosition.y, 0), 0.3):SetEase(CS.DG.Tweening.Ease.InCubic);
            self.view.ScrollView.transform:DOLocalMove(Vector3(-315, -8.1, 0), 0.3):SetEase(CS.DG.Tweening.Ease.InCubic);
            self.view.showItem.transform:DOLocalMove(Vector3(-315, -94.9, 0), 0.3):SetEase(CS.DG.Tweening.Ease.InCubic);
        else
            self.isShow = utils.SGKTools.SaveContainers("QuestUIShow", true);
            self.view.switch.arrow.transform:DORotate(Vector3(0, 0, 0), 0.3):SetEase(CS.DG.Tweening.Ease.InCubic);
            self.view.quest.transform:DOLocalMove(Vector3(-34, self.view.quest.gameObject.transform.localPosition.y, 0), 0.3):SetEase(CS.DG.Tweening.Ease.InCubic);
            self.view.ScrollView.transform:DOLocalMove(Vector3(11, -8.1, 0), 0.3):SetEase(CS.DG.Tweening.Ease.InCubic);
            self.view.showItem.transform:DOLocalMove(Vector3(11, -94.9, 0), 0.3):SetEase(CS.DG.Tweening.Ease.InCubic);
        end
    end
    if not self.isShow then
        self.view.switch.arrow.transform.localRotation = Quaternion.Euler(0, 0, 180);
        self.view.quest.gameObject.transform.localPosition = Vector3(-300, self.view.quest.gameObject.transform.localPosition.y, 0);
        self.view.ScrollView.transform.localPosition = Vector3(-315, -8.1, 0);
        self.view.showItem.transform.localPosition = Vector3(-315, -94.9, 0);
    end
    self.view.ScrollView[CS.UnityEngine.UI.ScrollRect].onValueChanged:AddListener(function ()
        if self.tip.gameObject.activeSelf then
            utils.SGKTools.SaveContainers("QuestTip"..self.recommend, false);
            self.tip:SetActive(false);
        end
    end)
    CS.UGUIClickEventListener.Get(self.view.tip.gameObject, true).onClick = function()
        utils.SGKTools.SaveContainers("QuestTip"..self.recommend, false);
        self.tip:SetActive(false);
    end
    self:initScrollView()
end

function mapSceneQuestList:refItem(view, cfg, idx)
    local _name = cfg.name
    --计数后缀
    local special = false;
    local postfix = "";
    for j,k in ipairs({41, 42, 43, 44}) do
        if cfg.type == k then
            local info = module.QuestModule.CityContuctInfo();
            postfix = " ["..(info.round_index+1).."/10]"
            special = true;
            break
        end
    end
    if postfix == "" and cfg.is_show_count == 1 then
        postfix = string.format(" [%s/%s]", cfg.records[1], cfg.condition[1].count)
    end
    local canCommit = module.QuestModule.CanSubmit(cfg.id);
    if canCommit then
        if special then
            view.root.name[UI.Text].text ="<color=#59FF94FF>".._name..postfix.."</color>"
        else
            view.root.name[UI.Text].text ="<color=#59FF94FF>".._name.." [完成]".."</color>"
        end
    elseif cfg.name_color ~= "" then
        view.root.name[UI.Text].text ="<color=#"..cfg.name_color.."FF>".._name..postfix.."</color>"
    else
        view.root.name[UI.Text].text = _name..postfix;
    end
    view.root.des[UI.Text].text = cfg.desc1;
    if idx == 1 and cfg.priority ~= 0 then
        self.recommend = cfg.id;
        view.root.special.gameObject:SetActive(true)
        if view.root.special.gameObject.transform.childCount == 0 then
            local obj = CS.UnityEngine.GameObject.Instantiate(SGK.ResourcesManager.Load("prefabs/effect/UI/fx_ui_kuang_reward.prefab"),view.root.special.gameObject.transform)
            obj.transform.localPosition = Vector3(-160.4, 43.7, 0);
            obj.transform.localScale = Vector3(1.03, 1.1, 0);
        end
        self:showTip(view.root);
    else
        view.root.special.gameObject:SetActive(false)
    end
    view.root.IconFrame:SetActive(cfg.priority ~= 0);
    if cfg.priority ~= 0 and cfg.reward[1] then
        utils.IconFrameHelper.Create(view.root.IconFrame,{type = cfg.reward[1].type, id = cfg.reward[1].id, count = cfg.reward[1].value, showDetail = true})
    end
    view.root.canCommit:SetActive(canCommit and cfg.npc_id == 0)
    
    view.root.icon[UI.Image]:LoadSprite("icon/"..cfg.icon)
    if cfg.time_limit and cfg.time_limit ~= 0 then
        local _endTime = cfg.accept_time + cfg.time_limit
        local _off = _endTime - Time.now();
        if _off > 0 then
            view.root.time[UI.Text].text = GetTimeFormat(_off, 2);
            self.questUI[cfg.id] = {view = view, cfg = cfg};
        else
            view.root.time[UI.Text].text = "";
        end
    else
        view.root.time[UI.Text].text = "";
    end

    CS.UGUIClickEventListener.Get(view.root.gameObject).onClick = function()
        if self.tip.gameObject.activeSelf then
            utils.SGKTools.SaveContainers("QuestTip"..self.recommend, false);
            self.tip:SetActive(false);
        end
        if module.QuestModule.CanSubmit(cfg.id) and cfg.npc_id == 0 then
            local teamInfo = module.TeamModule.GetTeamInfo();
            if teamInfo.group == 0 or module.playerModule.Get().id == teamInfo.leader.pid then
                module.QuestModule.StartQuestGuideScript(cfg)
            else
                showDlgError(nil,"你正在队伍中，无法进行该操作")
            end
        else    
            DialogStack.Push("mapSceneUI/newQuestList", {questId = cfg.id, mapScene = true})
        end
    end
end

function mapSceneQuestList:showTip(node)
    self.tip:SetActive(false);
    if module.playerModule.Get().level > 15 then
        return;
    end
    SGK.Action.DelayTime.Create(0.5):OnComplete(function()
        local active = utils.SGKTools.SaveContainers("QuestTip"..self.recommend, nil, true);
        if active then
            self.tip.transform:DOKill();
            self.tip.transform.position = node.transform.position;
            self.tip.transform.localPosition = self.tip.transform.localPosition + Vector3(135, 0, 0);
            self.tip.transform:DOLocalMove(Vector3(5,0,0),0.5):SetLoops(-1,CS.DG.Tweening.LoopType.Yoyo):SetRelative(true);
            self.tip:SetActive(true);
        end
    end)
end

function mapSceneQuestList:upItemList()
    self.tip:SetActive(false);
    self.view.showItem:SetActive(#self.questList <= 3)
    self.view.ScrollView:SetActive(#self.questList > 3)

    if #self.questList <= 3 then
        self.view.ScrollView[UnityEngine.UI.ScrollRect].movementType = UnityEngine.UI.ScrollRect.MovementType.Clamped
    else
        self.view.ScrollView[UnityEngine.UI.ScrollRect].movementType = UnityEngine.UI.ScrollRect.MovementType.Elastic
    end

    local count = math.min(3, #self.questList)
    local height = count * 54 + math.max(0, count - 1) * 8;
    self.view.quest.transform.localPosition = Vector3(self.view.quest.transform.localPosition.x, -65 + height,0);
    self.view.switch.transform.localPosition = Vector3(self.view.switch.transform.localPosition.x, -65 + height,0);
    if #self.questList > 3 then
        self.scrollView.DataCount = #self.questList
    else
        for i=1,3 do
            if self.questList[i] then
                self:refItem(self.view.showItem["item"..i], self.questList[i], i)
                self.view.showItem["item"..i]:SetActive(true)
            else
                self.view.showItem["item"..i]:SetActive(false)
            end
        end
    end
end

function mapSceneQuestList:initScrollView()
    self.scrollView = self.view.ScrollView.Viewport.Content[CS.ScrollViewContent]
    self.scrollView.RefreshIconCallback = function (obj, idx)
        local _view = CS.SGK.UIReference.Setup(obj.gameObject)
        local _cfg = self.questList[idx + 1]
        self:refItem(_view, _cfg, idx + 1)
        obj:SetActive(true)
    end
    local _y = utils.SGKTools.SaveContainers("QuestUIOffset", nil, 0);
    self.view.ScrollView.Viewport.Content[UnityEngine.RectTransform].anchoredPosition = CS.UnityEngine.Vector2(0, _y);
    self.view.ScrollView.Viewport.Content.transform:DOLocalMove(Vector3(0, 1, 0), 0):SetRelative(true);
end

function mapSceneQuestList:Update()
    if Time.now() - self.updateTime >= 1 then
        self.updateTime = Time.now();
        for k,v in pairs(self.questUI) do
            if v.cfg.time_limit and v.cfg.time_limit ~= 0 then
                local _endTime = v.cfg.accept_time + v.cfg.time_limit
                local _off = _endTime - Time.now();
                if _off > 0 then
                    v.view.root.time[UI.Text].text = GetTimeFormat(_off, 2);
                else
                    v.view.root.time[UI.Text].text = "";
                end
            end
        end
    end
end

function mapSceneQuestList:OnDestroy()
    utils.SGKTools.SaveContainers("QuestUIOffset", self.view.ScrollView.Viewport.Content[UnityEngine.RectTransform].anchoredPosition.y);
end

function mapSceneQuestList:listEvent()
    return {
        "QUEST_INFO_CHANGE",
    }
end

function mapSceneQuestList:onEvent(event, ...)
    if event == "QUEST_INFO_CHANGE" then
        self:initData()
        self:upItemList()
    end
end

return mapSceneQuestList
