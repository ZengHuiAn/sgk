local openLevel = require "config.openLevel"
local RedDotModule = require "module.RedDotModule"
local Time = require "module.Time"
local homeScenes = {}

local click_node = {
    [1] = {node = "home_day_banner", tip = "activity", openLevel = 1201, dialog = "mapSceneUI/newMapSceneActivity", args = {filter = {flag = false, id = 1003}}},--活动
    [2] = {node = "home_dianmao", tip = "mail", openLevel = 1501, dialog = "FriendSystem/FriendMail", red = RedDotModule.Type.Mail.MailAndAward},--邮箱
    [3] = {node = "home_shujia", tip = "dataBox", openLevel = 8100, dialog = "dataBox/DataBox", red = RedDotModule.Type.DataBox.DataBox},--资料柜
    [4] = {node = "home_jiangpai", tip = "pvp", openLevel = 2205, dialog = "mapSceneUI/newMapSceneActivity", args = {filter = {flag = true, id = 1003}}},--竞技
    [5] = {node = "home_day_door", tip = "jd", openLevel = 2001, map = 26, red = RedDotModule.Type.Manor.Manor},--基地
}

function homeScenes:Start()
    self.view = CS.SGK.UIReference.Setup(self.gameObject)
    self.home = CS.SGK.UIReference.Setup(UnityEngine.GameObject.Find("home"));
    self.home_door = CS.SGK.UIReference.Setup(UnityEngine.GameObject.Find("home_door"));
    self.updateTime = 0;
    self:initUi()
end

function homeScenes:initUi()
    -- CS.ModelClickEventListener.Get(self.view.manor.gameObject).onClick = function(go, pos)
    --     if not utils.SGKTools.GetTeamState() or utils.SGKTools.isTeamLeader() then
    --         SceneStack.EnterMap(26, {mapid = 26, mapType = 1})
    --     else
    --         showDlgError(nil, "在队伍中,无法操作")
    --     end
    -- end
    -- CS.ModelClickEventListener.Get(self.view.manor.title.gameObject).onClick = function(go, pos)
    --     if not utils.SGKTools.GetTeamState() or utils.SGKTools.isTeamLeader() then
    --         SceneStack.EnterMap(26, {mapid = 26, mapType = 1})
    --     else
    --         showDlgError(nil, "在队伍中,无法操作")
    --     end
    -- end
    self:updateStatus();
end

function homeScenes:updateStatus()
    for i,v in ipairs(click_node) do
        if v.openLevel == nil or openLevel.GetStatus(v.openLevel) then
            self.view[v.tip]:SetActive(true)
            CS.ModelClickEventListener.Get(self.view[v.tip].gameObject).onClick = function(go, pos)
                if v.dialog then
                    DialogStack.Push(v.dialog, v.args)
                elseif v.map then
                    if not utils.SGKTools.GetTeamState() or utils.SGKTools.isTeamLeader() then
                        if v.map == 26 then
                            self.home_door.open_door_Mask[UnityEngine.Animator]:Play("JD_open_door")
                            SGK.Action.DelayTime.Create(1):OnComplete(function() 
                                SceneStack.EnterMap(v.map, {mapid = v.map, mapType = 1})
                            end)
                        else
                            SceneStack.EnterMap(v.map, {mapid = v.map, mapType = 1})
                        end
                    else
                        showDlgError(nil, "在队伍中,无法操作")
                    end
                end
            end
            CS.ModelClickEventListener.Get(self.home[v.node].gameObject).onClick = function(go, pos)
                if v.dialog then
                    DialogStack.Push(v.dialog, v.args)
                elseif v.map then
                    if not utils.SGKTools.GetTeamState() or utils.SGKTools.isTeamLeader() then
                        if v.map == 26 then
                            self.home_door.open_door_Mask[UnityEngine.Animator]:Play("JD_open_door")
                            SGK.Action.DelayTime.Create(1):OnComplete(function() 
                                SceneStack.EnterMap(v.map, {mapid = v.map, mapType = 1})
                            end)
                        else
                            SceneStack.EnterMap(v.map, {mapid = v.map, mapType = 1})
                        end
                    else
                        showDlgError(nil, "在队伍中,无法操作")
                    end
                end
            end
            self.home[v.node][UnityEngine.BoxCollider].enabled = true;
        else
            self.home[v.node][UnityEngine.BoxCollider].enabled = false;
            self.view[v.tip]:SetActive(false);
        end
    end
end

function homeScenes:updateRedPoint()
    for i,v in ipairs(click_node) do
        if v.red then
            if v.openLevel == nil or openLevel.GetStatus(v.openLevel) then
                self.view[v.tip].red:SetActive(RedDotModule.GetStatus(v.red))
            else
                self.view[v.tip].red:SetActive(false)
            end
        end
    end
end

function homeScenes:Update()
    if Time.now() - self.updateTime >= 1 then
        self.updateTime = Time.now();
        self:updateRedPoint();
    end
end

function homeScenes:listEvent()
	return {
		"PLAYER_INFO_CHANGE",
	}
end

function homeScenes:onEvent(event, ...)
	if event == "PLAYER_INFO_CHANGE"  then
        self:updateStatus();
	end
end

return homeScenes
