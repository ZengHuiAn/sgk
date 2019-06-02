local activityConfig = require "config.activityConfig"
local CemeteryConf = require "config.cemeteryConfig"
local HeroScroll = require "hero.HeroScroll"
local equipConfig = require "config.equipmentConfig"
local SmallTeamDungeonConf = require "config.SmallTeamDungeonConf"
local ActivityTeamlist = require "config.activityConfig"
local openLevel = require "config.openLevel"

local guideResultModule = require "module.GuidePubRewardAndLuckyDraw"
local activityInfo = {}

function activityInfo:Start(data)
    print("zoezoezoe",sprinttb(data))
    if data then
        self.data = data
    else
        self.data = {}
        self.data.gid = module.TeamModule.GetActivityInfoGid()
    end
    self:initData(data)
    self:upTeamsInfo(true)
    self:initUi()
    CS.UnityEngine.GameObject.Instantiate(SGK.ResourcesManager.Load("prefabs/base/CurrencyChat.prefab"), self.view.transform)
end

function activityInfo:initUi()
    self.view = CS.SGK.UIReference.Setup(self.gameObject)
    self:initBtn()
    self:initMiddleTop()
    if tonumber(self.data.gid) == 117 then
        self:initNewPlayer()
    else
        self:initTeamInfo()
    end
    self:initReward()
    self:upMyTeam()
end

function activityInfo:initData(data)
    if data and data.gid then
        self.gid = data.gid
    elseif self.savedValues.gid then
        self.gid = self.savedValues.gid
    end
    if not self.gid then
        ERROR_LOG("gid error")
        return
    end
    self.cemeteryCfg = CemeteryConf.Getteam_battle_conf(self.gid)
    self.activityCfg = activityConfig.GetActivity(self.cemeteryCfg.activity_id)
end

function activityInfo:initReward()
    local _list = {}
    local _reward = activityConfig.GetReward(self.cemeteryCfg.activity_id) or {}
    for i,v in ipairs(_reward) do
        table.insert(_list, {type = v.type, id = v.id, isEquip = true})
    end
    for i = 1, 4 do
        local _type, _id = self.activityCfg["detailed_reward_type"..i], self.activityCfg["detailed_reward_id"..i]
        if _id ~= 0 then
            table.insert(_list, {type = _type, id = _id})
        end
    end
    self.view.root.middle.top.ScrollView[CS.UIMultiScroller].RefreshIconCallback = function (rObj, rIdx)
        local _rView = CS.SGK.UIReference.Setup(rObj.gameObject)
        local _rCfg = _list[rIdx + 1]
        _rView.IconFrame:SetActive(not _rCfg.isEquip)
        _rView.suit:SetActive(false)
        if _rCfg.isEquip then
            local _icon = utils.IconFrameHelper.Create(_rView,{id = _rCfg.id,type = _rCfg.type,showDetail = true})
            _icon[UnityEngine.RectTransform].anchoredPosition = CS.UnityEngine.Vector2(0,0)
            -- local _equip = equipConfig.GetConfig(_rCfg.id)
            -- if _equip then
            --     local suitTab = HeroScroll.GetSuitConfig(_equip.suit_id)
            --     if suitTab and next(suitTab) ~= nil then
            --         local suitCfg = suitTab[2][_equip.quality]
            --         if suitCfg then
            --             _rView.suit:SetActive(true)

            --             _rView.suit.Frame[CS.UGUISpriteSelector].index = _equip.quality -1
            --             _rView.suit.Icon[UI.Image]:LoadSprite("icon/"..suitCfg.icon)

            --             CS.UGUIClickEventListener.Get(_rView.suit.gameObject).onClick = function()
            --                 DialogStack.PushPrefStact("dataBox/suitsManualFrame", {suitId = _equip.suit_id,hideSuits = true})
            --             end
            --         end
            --     end
            -- else
            --     ERROR_LOG(self.cemeteryCfg.activity_id, _rCfg.id, "error")
            -- end
        else
            local _icon = utils.IconFrameHelper.Create(_rView, {type = _rCfg.type, id = _rCfg.id, count = 0, showDetail = true})
            _icon[UnityEngine.RectTransform].anchoredPosition = CS.UnityEngine.Vector2(0,0)
        end
        rObj:SetActive(true)
    end
    self.view.root.middle.top.ScrollView[CS.UIMultiScroller].DataCount = #_list
end

function activityInfo:initMiddleTop()
    self.view.root.middle.top.name[UI.Text].text = self.cemeteryCfg.tittle_name
    self.view.root.middle.top.icon[UI.Image]:LoadSprite("guanqia/"..self.activityCfg.use_picture)
    local _infoDesc = "<color=#D72020>"..self.cemeteryCfg.fresh_time_des.."</color>".."\n"..SGK.Localize:getInstance():getValue("huodong_lv_01", self.activityCfg.lv_limit).."\n"..self.activityCfg.parameter
    self.view.root.middle.top.info[UI.Text].text = _infoDesc
    local _battleCfg = SmallTeamDungeonConf.GetTeam_pve_fight(self.gid)
    local _count = module.CemeteryModule.GetTEAMRecord(_battleCfg.idx[1][1].gid) or 0
    self.view.root.middle.top.tip:SetActive((module.playerModule.Get().level >= self.cemeteryCfg.limit_level) and _count == 0)
    self.view.root.middle.top.pass:SetActive((module.playerModule.Get().level >= self.cemeteryCfg.limit_level) and (not self.view.root.middle.top.tip.activeSelf))
    CS.UGUIClickEventListener.Get(self.view.root.middle.infoBtn.gameObject).onClick = function()
        DialogStack.PushPrefStact("newSelectMap/activityDesc", {gid = self.gid})
    end
end

function activityInfo:upTeamsInfo(refresh)
    local _list = module.TeamModule.GetTeamList(self.gid, refresh)
    self.teamsList = {}
    for k,v in pairs(_list) do
        table.insert(self.teamsList, v)
    end
end

function activityInfo:upMyTeam()
    local _teamInfo = module.TeamModule.GetTeamInfo()
    local _status = _teamInfo.group ~= 0
    self.view.root.middle.teamInfo.teamListView:SetActive(not _status)
    self.view.root.middle.teamInfo.myTeam:SetActive(_status)
    -- self.view.root.bottom.createTeam:SetActive(not _status)
    self.view.root.bottom.createTeam.Text[UI.Text].text =  _teamInfo.id ~=0 and "招募队友" or "创建队伍"
        
    if not module.TeamModule.GetTeamInfo().auto_match then
        self.view.root.bottom.createTeam[UI.Button].interactable = true
    else
        self.view.root.bottom.createTeam.Text[UI.Text].text =  "取消招募"
        self.view.root.bottom.createTeam[UI.Button].interactable = false
    end
    -- 

    self.view.root.middle.teamInfo.myTeam.Text:SetActive(module.TeamModule.GetTeamInfo().auto_match);
    self.view.root.bottom.matching:SetActive(not _status)
    self.view.root.bottom.myTeam:SetActive(_status)
    if self.view.root.bottom.matching.activeSelf then
        if module.TeamModule.GetplayerMatchingType() == 0 then
            self.view.root.bottom.matching.Text[UI.Text].text = SGK.Localize:getInstance():getValue("zudui_fuben_01")
        else
            self.view.root.bottom.matching.Text[UI.Text].text = SGK.Localize:getInstance():getValue("team_pipei_03")
        end
    end
    if _status then
        for i = 1, 5 do
            local _memberCfg = _teamInfo.members[i]
            if _memberCfg then
                utils.IconFrameHelper.Create(self.view.root.middle.teamInfo.myTeam[i], {pid = _memberCfg.pid})
                self.view.root.middle.teamInfo.myTeam[i].name[UI.Text].text = _memberCfg.name
                CS.UGUIClickEventListener.Get(self.view.root.middle.teamInfo.myTeam[i].gameObject).interactable = true
                CS.UGUIClickEventListener.Get(self.view.root.middle.teamInfo.myTeam[i].gameObject).onClick = function()
                    DialogStack.PushPrefStact("newSelectMap/teamPlayerBtnList", {pid = _memberCfg.pid})
                end
            else
                CS.UGUIClickEventListener.Get(self.view.root.middle.teamInfo.myTeam[i].gameObject).interactable = false
                utils.IconFrameHelper.Create(self.view.root.middle.teamInfo.myTeam[i], {customCfg = {
                    icon    = 10999,
                    role_stage = -1,
                    star    = 0,
                    level   = 0,
                }, type = 42})
                self.view.root.middle.teamInfo.myTeam[i].name[UI.Text].text = ""
            end
        end
    end
end

function activityInfo:initNewPlayer()
    local guidePveFightTeamInfo = {-10001,-10002,-10003,-10004}
    self.teamListView = self.view.root.middle.teamInfo.teamListView[CS.UIMultiScroller]
    self.teamListView.RefreshIconCallback = function (obj, idx)
        local _view = CS.SGK.UIReference.Setup(obj.gameObject).root
        for i = 1, 5 do
            local _pid = guidePveFightTeamInfo[i]
            if _pid and _pid <0 then
                    local AIInfo = guideResultModule.GetLocalPubRewardAIData(_pid)
                    if i==1 then
                        _view.teamName[UI.Text].text = SGK.Localize:getInstance():getValue("zudui_fuben_04", AIInfo.name)
                    end
                    utils.IconFrameHelper.Create(_view.heroList[i], {customCfg = {
                        icon    = AIInfo.head,
                        role_stage = -1,
                        star    = 0,
                        level   = AIInfo.level,
                    }, type = 42});
            else
                utils.IconFrameHelper.Create(_view.heroList[i], {customCfg = {
                    icon    = 10999,
                    role_stage = -1,
                    star    = 0,
                    level   = 0,
                }, type = 42})
            end
        end
        CS.UGUIClickEventListener.Get(_view.join.gameObject).onClick = function()
            utils.IconFrameHelper.Create(_view.heroList[5], {pid = module.playerModule.GetSelfID()})
            showDlgError(nil,"申请成功")
            self.view.transform:DOScale(Vector3.one,0.5):OnComplete(function()
                module.TeamModule.GetActivityInfoGid(self.data.gid)
                local EncounterFightModule = require "module.EncounterFightModule"
                EncounterFightModule.StartGuideTeamFight();
            end)  
        end
        obj:SetActive(true)
    end
    self.teamListView.DataCount = 1
end

function activityInfo:initTeamInfo()
    self.teamListView = self.view.root.middle.teamInfo.teamListView[CS.UIMultiScroller]
    self.teamListView.RefreshIconCallback = function (obj, idx)
        local _view = CS.SGK.UIReference.Setup(obj.gameObject).root
        local _cfg = self.teamsList[idx + 1]
        _view.teamName[UI.Text].text = SGK.Localize:getInstance():getValue("zudui_fuben_04", _cfg.leader.name)
        if _cfg.joinRequest then
            _view.join.Text[UI.Text].text = SGK.Localize:getInstance():getValue("zudui_fuben_05")
        else
            _view.join.Text[UI.Text].text = SGK.Localize:getInstance():getValue("juntuan_biaoqian_03")
        end
        CS.UGUIClickEventListener.Get(_view.join.gameObject).onClick = function()
            if not _cfg.joinRequest then
                module.TeamModule.JoinTeam(_cfg.id)
            else
                showDlgError(nil, SGK.Localize:getInstance():getValue("zudui_fuben_05"))
            end
        end
        for i = 1, 5 do
            if _cfg.member_id[i] then
                utils.IconFrameHelper.Create(_view.heroList[i], {pid = _cfg.member_id[i]})
            else
                utils.IconFrameHelper.Create(_view.heroList[i], {customCfg = {
                    icon    = 10999,
                    role_stage = -1,
                    star    = 0,
                    level   = 0,
                }, type = 42});
            end
        end
        obj:SetActive(true)
    end
    self.teamListView.DataCount = #self.teamsList
end

function activityInfo:initBtn()
    self.view.root.top.item1.number[UI.Text].text = tostring(module.ItemModule.GetItemCount(90023))
    if openLevel.GetStatus(1331) then
        self.view.root.top.luckBtn:SetActive(true)
    else
        self.view.root.top.luckBtn:SetActive(false)
    end
    CS.UGUIClickEventListener.Get(self.view.root.top.luckBtn.gameObject).onClick = function()
        DialogStack.PushPref("fightResult/luckyCoin") 
    end
    CS.UGUIClickEventListener.Get(self.view.root.top.item1.gameObject).onClick = function()
        DialogStack.PushPrefStact("ItemDetailFrame", {id = 90023, type = utils.ItemHelper.TYPE.ITEM, InItemBag = 2},UnityEngine.GameObject.FindWithTag("UITopRoot").gameObject)
    end
    CS.UGUIClickEventListener.Get(self.view.root.bottom.matching.gameObject).onClick = function()
        if SceneStack.GetBattleStatus() then
            showDlgError(nil, "战斗内无法进行该操作")
            return
        end
        if module.playerModule.Get().level < self.cemeteryCfg.limit_level then
            showDlgError(nil, "等级不足")
            return
        end

        local teamInfo = module.TeamModule.GetTeamInfo()
		if teamInfo.group == 0 then
			if module.TeamModule.GetplayerMatchingType() ~= 0 then
                module.TeamModule.playerMatching(0)
            else
                module.TeamModule.playerMatching(self.gid)
            end
        end
    end
    CS.UGUIClickEventListener.Get(self.view.root.bottom.myTeam.gameObject).onClick = function()
        DialogStack.PushPrefStact('TeamFrame', {idx = 1})
    end

    print("===========",module.TeamModule.GetTeamInfo().auto_match);

    CS.UGUIClickEventListener.Get(self.view.root.bottom.goWhere.gameObject).onClick = function()
        if self.data.gid == 117 then
            local teamInfo = module.TeamModule.GetTeamInfo()
            if teamInfo.group ~= 0 then
                showDlgError(nil, "此副本为特殊的单人副本")
            else
                module.TeamModule.GetActivityInfoGid(self.data.gid)
                local EncounterFightModule = require "module.EncounterFightModule"
                EncounterFightModule.StartGuideTeamFight();
            end
        else
            if SceneStack.GetBattleStatus() then
                showDlgError(nil, "战斗内无法进行该操作")
                return
            end
            if module.playerModule.Get().level < self.cemeteryCfg.limit_level then
                showDlgError(nil, "等级不足")
                return
            end
            local teamInfo = module.TeamModule.GetTeamInfo()
    		if teamInfo.group ~= 0 then
                if module.playerModule.GetSelfID() == teamInfo.leader.pid then
                    if activityConfig.GetActivity(teamInfo.group) and activityConfig.GetActivity(teamInfo.group).name then
                        if self.cemeteryCfg.tittle_name ~= activityConfig.GetActivity(teamInfo.group).name then
                            utils.NetworkService.Send(18178,{nil, self.gid})
                        end
                    end
                    if module.TeamModule.GetTeamInfo().auto_match then
                        module.TeamModule.TeamMatching(true)
                    end
                    utils.SGKTools.SwitchTeamTarget(self.gid);
                    module.TeamModule.GetActivityInfoGid(self.data.gid)
                    AssociatedLuaScript("guide/"..self.cemeteryCfg.enter_script..".lua", self.cemeteryCfg)
                else
                    showDlgError(nil, "只有队长可以带领队伍前往")
                end
            else
                showDlgError(nil, "未组队")
            end
        end
    end
        CS.UGUIClickEventListener.Get(self.view.root.bottom.createTeam.gameObject).onClick = function()
            local teamInfo = module.TeamModule.GetTeamInfo()

            if SceneStack.GetBattleStatus() then
                showDlgError(nil, "战斗内无法进行该操作")
                return
            end
            if module.playerModule.Get().level < self.cemeteryCfg.limit_level then
                showDlgError(nil, "等级不足")
                return
            end
            if teamInfo.id <=0 then 
                module.TeamModule.CreateTeam(self.gid, nil, self.cemeteryCfg.limit_level, self.cemeteryCfg.des_limit)
            else
                utils.SGKTools.SwitchTeamTarget(self.gid); 
            end


        end
end

function activityInfo:initGuide()
    module.guideModule.PlayByType(102,0.2)
end

function activityInfo:listEvent()
    return {
        "TEAM_LIST_CHANGE",
        "Leave_team_succeed",
        "TeamMatching_succeed",
        "playerMatching_succeed",
        "GROUP_CHANGE",
        "TEAM_MEMBER_CHANGE",
        "TEAM_LEADER_CHANGE",
        "NOTIFY_TEAM_PLAYER_AFK_CHANGE",
        "LOCAL_TEAM_JOIN_CHANGE",
        "LOCAL_GUIDE_CHANE",
        "TEAM_BATTLE_START_ERROR",
    }
end

function activityInfo:upTeamsUIInfo()
    self:upTeamsInfo()
    if self.data.gid == 117 then
        self.teamListView.DataCount = 1
    else
        self.teamListView.DataCount = #self.teamsList
    end
end

function activityInfo:onEvent(event, data)
    if event == "TEAM_LIST_CHANGE" then
        if data == self.gid then
            self:upTeamsUIInfo()
        end
    elseif event == "Leave_team_succeed" or event == "TeamMatching_succeed" or event == "playerMatching_succeed" or event == "GROUP_CHANGE"
    or event == "TEAM_MEMBER_CHANGE" or event == "TEAM_LEADER_CHANGE" or event == "NOTIFY_TEAM_PLAYER_AFK_CHANGE" then
        self:upMyTeam()
    elseif event == "LOCAL_TEAM_JOIN_CHANGE" then
        self:upTeamsUIInfo()
    elseif event == "LOCAL_GUIDE_CHANE" then
        self:initGuide()
    elseif event == "TEAM_BATTLE_START_ERROR" then
        if module.TeamModule.GetTeamInfo().group ~= 0 and #module.TeamModule.GetTeamInfo().members < tonumber(self.cemeteryCfg.team_member) then
            showDlgError(nil,"队伍人数不足")
        end
    end
end

return activityInfo
