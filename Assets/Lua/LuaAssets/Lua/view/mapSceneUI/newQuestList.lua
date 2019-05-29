local activityConfig = require "config.activityConfig"
local newQuestList = {}

function newQuestList:Start(data)
    self:initData(data)
    self:initUi()
    self:upScrollView()
end

function newQuestList:initData(data)
    self.tittleTab = {}
    self.questTab = {}
    self.Type = {
         NowTask = 1,
         PickUpTask = 2,
     }
    self.nowType = self.Type.NowTask
    self.cityContuctId = {41, 42, 43, 44}
    self.typeIconList = {
        [2001] = "bg_rw-xianshi",
        [2002] = "bg_rw-richang",
        [2003] = "bg_rw-juqing",
        [2005] = "bg_rw-shilian",
        [2006] = "bg_rw-shilian",
    }
    self.updateTime = 0.5
    if data then
        self.hideBtn = data.hideBtn
        self.questId = data.questId
        self.mapScene = data.mapScene
    end
    self.tittleList = self:getTittle()
    --self:upData()
end

function newQuestList:upData()
    self.questList = {}
    if self.nowType == self.Type.NowTask then
        local _list = module.QuestModule.GetList(nil, 0)
        for k,v in pairs(_list) do
            if v.is_show_on_task == 0 then
                table.insert(self.questList, v)
            end
        end
    else
        local _list = module.QuestModule.GetCanAccept()
       
        for k,v in pairs(_list) do
            -- if self:getTypeName(v) then
            --     if v.type ~= 10 and v.type ~= 12 and v.is_show_on_task == 0 then
            --         table.insert(self.questList, v)
            --     end
            -- end
            if v.is_show_on_task == 0 then
                table.insert(self.questList, v)
            end
        end
    end
end

function newQuestList:initTop()
    self.group = self.view.root.top.group
    for i = 1, 2 do
        self.group["Toggle"..i][UI.Toggle].onValueChanged:AddListener(function (value)
            if value then
                for i = 0, self.view.root.infoRoot.gameObject.transform.childCount - 1 do
                    local _chile = self.view.root.infoRoot.gameObject.transform:GetChild(i)
                    if _chile then
                        UnityEngine.GameObject.Destroy(_chile.gameObject)
                    end
                end
                if i == 1 then
                    self.nowType = self.Type.NowTask
                else
                    self.nowType = self.Type.PickUpTask
                end
                self:upData()
                self:upScrollView()
                -- if self.questId then
                --     self:showInfo(module.QuestModule.Get(self.questId))
                --     self.questId = nil
                -- else
                --     self:showInfo(self.questList[1])
                -- end
            end
        end)
    end
end

function newQuestList:initUi()
    self.view = CS.SGK.UIReference.Setup(self.gameObject)
    CS.UGUIClickEventListener.Get(self.view.root.closeBtn.gameObject).onClick = function()
        DialogStack.Pop()
    end
    CS.UGUIClickEventListener.Get(self.view.mask.gameObject, true).onClick = function()
        DialogStack.Pop()
    end
    self:initTop()
    self.group["Toggle1"][UI.Toggle].isOn = true
end

function newQuestList:getTypeName(cfg)
    local _type = cfg.type
    if cfg.type == 2 then
        _type = cfg.bountyType
    end
    local _cfg = activityConfig.Get_all_activity(_type)
    if _cfg then
        local _tittleCg = activityConfig.GetBaseTittleByType(2)
        if _tittleCg[_cfg.up_tittle2] then
            return _tittleCg[_cfg.up_tittle2].name, _cfg.up_tittle2
        end
    end
    return nil
end

function newQuestList:getInfoName(_tab)
    local _name = _tab.name
    for i,v in ipairs(self.cityContuctId) do
        if _tab.type == v and self.nowType == self.Type.NowTask then
            local info = module.QuestModule.CityContuctInfo();
            _name = _name.."("..(info.round_index+1).."/".."10)"
        end
    end
    return _name
end

function newQuestList:upDesc()
    self.view.root.info.info.desc[UI.Text].text = self.cfg.desc2
    if (self.cfg.type == 60 or self.cfg.type == 11) and self.cfg.status == 0 then
        for i = 1, 1 do
            if self.cfg.condition[i].count ~= 0 and self.cfg.condition[i].type ~= 1 then
                self.view.root.info.info.desc[UI.Text].text = self.cfg.desc2.."("..module.QuestModule.GetOtherRecords(self.cfg, i).."/"..self.cfg.condition[i].count..")"
            end
        end
    end
    if (self.cfg.id == 103012 and self.cfg.status == 0) or (self.cfg.id == 102143 and self.cfg.status == 0) then
        if self.cfg.condition[2].count ~= 0 and self.cfg.condition[2].type ~= 1 then
            if module.QuestModule.CanSubmit(self.cfg.id) then
                self.view.root.info.info.desc[UI.Text].text = "<color=#28ff97>"..self.view.root.info.info.desc[UI.Text].text.."("..module.QuestModule.GetOtherRecords(self.cfg, 2).."/"..self.cfg.condition[2].count..")</color>"
            else
                self.view.root.info.info.desc[UI.Text].text = self.view.root.info.info.desc[UI.Text].text.."("..module.QuestModule.GetOtherRecords(self.cfg, 2).."/"..self.cfg.condition[2].count..")"
            end
        end
    end
    if self.cfg.time_limit and self.cfg.time_limit ~= 0 and self.cfg.status == 0 then
        local _endTime = self.cfg.accept_time + self.cfg.time_limit
        local _off = _endTime - module.Time.now()
        if _off >= 0 then
            if _off > 10 then
                self.view.root.info.info.desc[UI.Text].text = self.view.root.info.info.desc[UI.Text].text.."\n"..SGK.Localize:getInstance():getValue("renwu_liebiao_10_bai", GetTimeFormat(_off, 2))
            else
                self.view.root.info.info.desc[UI.Text].text = self.view.root.info.info.desc[UI.Text].text.."\n"..SGK.Localize:getInstance():getValue("renwu_liebiao_10_hong", GetTimeFormat(_off, 2))
            end
        else
            self.cfg.status = 2
            DispatchEvent("QUEST_INFO_CHANGE")
        end
    end
end

function newQuestList:Update()
    if self.updateTime and self.updateTime > 0 then
        self.updateTime = self.updateTime - UnityEngine.Time.deltaTime
        if self.updateTime <= 0 then
            self.updateTime = 0.5
            if self.cfg and (self.cfg.time_limit and self.cfg.time_limit ~= 0) then
                self:upDesc()
            end
        end
    end
end

function newQuestList:showInfo(cfg)
    self.cfg = cfg
    if not cfg then
        return
    end
    if not cfg.uuid then
        self.view.root.info.cancelBtn:SetActive(false)
    else
        if cfg.type == 2 then
            local teamInfo = module.TeamModule.GetTeamInfo()
            self.view.root.info.cancelBtn:SetActive(teamInfo.id <= 0 or module.playerModule.Get().id == teamInfo.leader.pid)
        else
            self.view.root.info.cancelBtn:SetActive(not (cfg.type == 10 or cfg.type == 11))
        end
    end
    self.view.root.info.finishBtn:SetActive(cfg.status == 0 and (cfg.type ~= 10 or self.mapScene))
    if module.QuestModule.CanSubmit(cfg.uuid) and cfg.npc_id == 0 then
        self.view.root.info.finishBtn[CS.UGUISelectorGroup].index = 3;
        self.view.root.info.finishBtn.Title[UI.Text].text = "完成任务";
    else
        self.view.root.info.finishBtn[CS.UGUISelectorGroup].index = 1;
        self.view.root.info.finishBtn.Title[UI.Text].text = "马上前往";
    end
    CS.UGUIClickEventListener.Get(self.view.root.info.cancelBtn.gameObject).onClick = function()
        module.QuestModule.Cancel(cfg.uuid)
    end
    CS.UGUIClickEventListener.Get(self.view.root.info.finishBtn.gameObject).onClick = function()
        local teamInfo = module.TeamModule.GetTeamInfo();
        if teamInfo.group == 0 or module.playerModule.Get().id == teamInfo.leader.pid then
            --不在一个队伍中或自己为队长
            module.QuestModule.StartQuestGuideScript(cfg, true)
        else
            showDlgError(nil,"你正在队伍中，无法进行该操作")
        end
    end
    self:upDesc()
    self.view.root.info.info.name[UI.Text].text = self:getInfoName(cfg)
    self.view.root.info.info.icon[UI.Image]:LoadSprite("icon/"..(cfg.icon or "bg_rw_4"))

    local scrollView = self.view.root.info.reward.ScrollView[CS.UIMultiScroller]
    scrollView.RefreshIconCallback = function (obj, idx)
        local _view = CS.SGK.UIReference.Setup(obj)
        local _tab = cfg.reward[idx + 1]
        local _cfg = utils.ItemHelper.Get(_tab.type,_tab.id)
        if _cfg and _cfg.is_show ==1 then
            utils.IconFrameHelper.Create(_view.IconFrame, {id = _tab.id, type = _tab.type, showDetail = true, count = _tab.value})
            obj:SetActive(true)
        end
    end
    scrollView.DataCount = #(cfg.reward or {})
--    _questView.button[CS.UGUISpriteSelector].index = 1
end

function newQuestList:upScrollView()
    self:initScrollView1()
    self.view.root.info:SetActive(#self.questList > 0)
    self.view.root.nothing:SetActive(#self.questList <= 0)
end

function newQuestList:getTittle()
    local _tittleList = activityConfig.GetBaseTittleByType(2)
    local _temp = {}
    for _,cfg in pairs(_tittleList) do
        local quest_type = StringSplit(cfg.quest_type, "|")
        for i,v in ipairs(quest_type) do
            local type = tonumber(v);
            if type then
                _temp[type] = cfg
            end
        end
    end
    return _temp
end

function newQuestList:initScrollView1()
    local _item = self.view.root.middle.ScrollView2.Viewport.Content.item
    for i,v in pairs(self.tittleTab) do
        -- UnityEngine.GameObject.Destroy(v)
        v:SetActive(false);
    end
    for k,v in pairs(self.questTab) do
        v:SetActive(false);
    end
    table.sort(self.questList,function (a,b)--排序
        if a.type ~= b.type then
            if a.type == 10 then
                return true;
            elseif b.type == 10 then
                return false;
            else
                return a.type < b.type        
            end
        end
        return a.id < b.id
    end)
    self.questId = self.questId or self.questList[1].id;
    self:showInfo(module.QuestModule.Get(self.questId));
    for j,p in ipairs(self.questList) do
        if p.type and p.is_show_on_task == 0 then
            -- local _tempTab = activityConfig.GetActivity(p.type)
            -- for k,v in ipairs(self.tittleList) do
            --     if _tempTab and v.id == _tempTab.up_tittle2 then
            --     end
            -- end
            local cfg = self.tittleList[p.type]
            if cfg then
                if self.tittleTab[cfg.id] == nil then
                    local _obj = UnityEngine.GameObject.Instantiate(_item.gameObject, self.view.root.middle.ScrollView2.Viewport.Content.transform)
                    self.tittleTab[cfg.id] = _obj
                end
                local _itemView = SGK.UIReference.Setup(self.tittleTab[cfg.id].gameObject)
                _itemView.top.name[UI.Text].text = cfg.name
                _itemView.top.icon[UI.Image]:LoadSprite("icon/"..cfg.icon)
                CS.UGUIClickEventListener.Get(_itemView.top.gameObject, true).onClick = function()
                    _itemView.Group:SetActive(not _itemView.Group.activeSelf)
                    if _itemView.Group.activeSelf then
                        _itemView.top.arr.transform:DOLocalRotate(Vector3(0, 0, -180), 0)
                    else
                        _itemView.top.arr.transform:DOLocalRotate(Vector3(0, 0, -90), 0)
                    end
                end
                _itemView:SetActive(true);
                if self.questTab[p.id] == nil then
                    local _questObj = UnityEngine.GameObject.Instantiate(_itemView.Group.item.gameObject, _itemView.Group.transform)
                    self.questTab[p.id] = _questObj
                    _questObj.name = "quest_"..p.id;
                end
                local _questView = SGK.UIReference.Setup(self.questTab[p.id])
                _questView.button.text[UI.Text].text = p.button_des
                -- _questView.button.text[UI.Text].text = string.gsub(p.name,"%(","\n（",1)
                CS.UGUIClickEventListener.Get(_questView.button.gameObject).onClick = function()
                    self:showInfo(p)
                end
                _questView:SetActive(true);
                if p.id == self.questId then
                    _itemView.Group:SetActive(true);
                    _itemView.top.arr.transform:DOLocalRotate(Vector3(0, 0, -180), 0)
                    _questView.button[UI.Toggle].isOn = true;
                end
            end
        end
    end
end

function newQuestList:listEvent()
    return {
        "QUEST_INFO_CHANGE",
    }
end

function newQuestList:onEvent(event, ...)
    if event == "QUEST_INFO_CHANGE" then
        self:upData()
        self:upScrollView()
    end
end

function newQuestList:deActive()
	utils.SGKTools.PlayDestroyAnim(self.gameObject)
	return true;
end

return newQuestList
