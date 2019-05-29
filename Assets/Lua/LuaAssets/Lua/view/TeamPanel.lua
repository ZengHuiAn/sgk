
local TeamModule = require "module.TeamModule"
local playerModule = require "module.playerModule"

local View = {}

function View:Start()
    self.view = SGK.UIReference.Setup(self.gameObject);

    TeamModule.WatchTeamGroup(3);
    TeamModule.GetTeamList(3, true)

    local teamInfo = TeamModule.GetTeamInfo();
    self.show_waiting_list = teamInfo.id > 0;

    self.membersObject = {};
    self.teamsObject = {};
    self.waitingsObject = {};

    self:UpdateTeamInfo();
    self:UpdateTeamList();
    self:UpdateWaitingList();

    CS.UGUIClickEventListener.Get(self.view.Chat.bottom.Button.gameObject).onClick = function()
        local msg = self.view.Chat.bottom.InputField[UnityEngine.UI.InputField].text;
        if msg ~= "" then
            if TeamModule.ChatToTeam(msg) then
                self.view.Chat.bottom.InputField[UnityEngine.UI.InputField].text = "";
            end
        end
    end

    CS.UGUIClickEventListener.Get(self.view.Ready.gameObject).onClick = function()
        TeamModule.ReadyToFight(not TeamModule.MemberIsReady() ) ;
    end
end

function View:listEvent()
    return {
        "TEAM_MEMBER_CHANGE",
        "TEAM_INFO_CHANGE",
        "TEAM_LIST_CHANGE",
        "server_respond_18117",
        "TEAM_CHAT",
        "TEAM_JOIN_REQUEST_CHANGE",
        "TEAM_MEMBER_READY_CHECK",
        "TEAM_MEMBER_READY",
        "TEAM_DATA_SYNC",
    }
end

function View:onEvent(event, ...) 
    if event == "TEAM_MEMBER_CHANGE" then
        self:UpdateTeamInfo();
    elseif event == "TEAM_LIST_CHANGE" then
        self:UpdateTeamList();
    elseif event == "server_respond_18117" then
        local data = select(2, ...)
        if data[2] ~= 0 then
            print("join failed");
        end
    elseif event == "TEAM_CHAT" then
        self:Updatechat(...);
    elseif event == "TEAM_JOIN_REQUEST_CHANGE" then
        self:UpdateWaitingList();
    elseif event == "TEAM_MEMBER_READY_CHECK" then
        self:UpdateTeamInfo();
    elseif event == "TEAM_MEMBER_READY" then
        self:UpdateTeamInfo();
    elseif event == "TEAM_DATA_SYNC" then
        self:OnTeamEvent(...)
    end
end

function View:UpdateTeamInfo()
    local teamInfo = TeamModule.GetTeamInfo();
    local members = TeamModule.GetTeamMembers();
    print("UpdateTeamInfo", #members);

    self.membersObject = self.membersObject or {};

    local prefab = self.view.Members[1].gameObject;
    local parent = self.view.Members.gameObject.transform;
    local memMap = {};
    for _, v in ipairs(members) do
        memMap[v.pid] = true;
        local view = self.membersObject[v.pid];
        if  not view then
            view = SGK.UIReference.Setup(UnityEngine.GameObject.Instantiate(prefab, parent));
            view.gameObject:SetActive(true);
            self.membersObject[v.pid] = view;

            CS.UGUIClickEventListener.Get(view.Remove.gameObject).onClick = function()
                TeamModule.KickTeamMember(v.pid)
            end
        end

        view.Name[UnityEngine.UI.Text].text = v.name;
        view.LeaderFlag.gameObject:SetActive(v.pid == teamInfo.leader.pid);
        view.Ready.gameObject:SetActive(v.is_ready == true);
    end

    for k, v in pairs(self.membersObject) do
        if not memMap[k] then
            UnityEngine.GameObject.Destroy(v.gameObject);
            self.membersObject[k] = nil;
        end
    end

    local teamInfo = TeamModule.GetTeamInfo();
    if teamInfo.id == 0 then
        self.view.buttons.createOrLeave.Text[UnityEngine.UI.Text].text = "创建队伍";
    elseif teamInfo.id > 0 then
        self.view.buttons.createOrLeave.Text[UnityEngine.UI.Text].text = "退出队伍";
    else
        self.view.buttons.createOrLeave.Text[UnityEngine.UI.Text].text = "查询中";
    end

    if teamInfo.id > 0 and (teamInfo.is_checking_ready or teamInfo.leader.pid == playerModule.GetSelfID() ) then
        self.view.Ready.gameObject:SetActive(true);
        if not teamInfo.is_checking_ready then
            self.view.Ready.Text[UnityEngine.UI.Text].text = "就位检查";
        elseif TeamModule.MemberIsReady() then
            self.view.Ready.Text[UnityEngine.UI.Text].text = "取消";
        else
            self.view.Ready.Text[UnityEngine.UI.Text].text = "就位确认";
        end
    else
        self.view.Ready.gameObject:SetActive(false);
    end
end

function View:UpdateTeamList()
    if self.show_waiting_list then
        return;
    end

    self.view.buttons.TeamList.Text[UnityEngine.UI.Text].text = "等待队列";
    local teamInfo = TeamModule.GetTeamInfo();
    local inTeam = (teamInfo.id > 0);


    local list = {};
    local teams = TeamModule.GetTeamList(3)
    for k, v in pairs(teams) do
        table.insert(list, {
            id = v.id, member_count = v.member_count, leader = {pid = v.leader.pid, name = v.leader.name},
            joinRequest = v.joinRequest,
        })
    end

    print("UpdateTeamList", #list);

    -- self.view.List.Title[UnityEngine.UI.Text].text = "队伍列表";
    --self.nguiDragIconScript = self.view.List[CS.UIMultiScroller]
    self.nguiDragIconScript = self.view.ScrollView[CS.UIMultiScroller]
    self.nguiDragIconScript.RefreshIconCallback = function (obj,idx)
        local info = list[idx + 1];
        
        local view = CS.SGK.UIReference.Setup(obj)
        view.gameObject:SetActive(true);
        view.Button.Text[UnityEngine.UI.Text].text = "加入";
        view.Name[UnityEngine.UI.Text].text = "(" .. info.id .. ")" .. info.leader.name .. "   " .. info.member_count;

        view.Button.gameObject:SetActive( (not info.joinRequest) and (not inTeam) );

        CS.UGUIClickEventListener.Get(view.Button.gameObject).onClick = function()
            TeamModule.JoinTeam(info.id);
        end
	end
    
    self.nguiDragIconScript.DataCount = #list;
end

function View:UpdateWaitingList()
    local teamInfo = TeamModule.GetTeamInfo();
    if teamInfo.id <= 0 then
        return;
    end

    if not self.show_waiting_list then
        return;
    end

    print("UpdateWaitingList");
    self.view.buttons.TeamList.Text[UnityEngine.UI.Text].text = "队伍列表";
    
    local list = {};
    local waiting = TeamModule.GetTeamWaitingList(3)
    for k, v in pairs(waiting) do
        print(v.pid, v.level, v.name);
        table.insert(list, {
            pid = v.pid, level = v.level, name = v.name
        })
    end

    -- self.view.List.Title[UnityEngine.UI.Text].text = "队伍列表";
    --self.nguiDragIconScript = self.view.List[CS.UIMultiScroller]
    self.nguiDragIconScript = self.view.ScrollView[CS.UIMultiScroller]
    self.nguiDragIconScript.RefreshIconCallback = function (obj,idx)
        local info = list[idx + 1];
        local view = CS.SGK.UIReference.Setup(obj)
        view.gameObject:SetActive(true);
        view.Button.Text[UnityEngine.UI.Text].text = "同意";
        view.Name[UnityEngine.UI.Text].text = info.name .. "   Lv. " .. info.level;
        view.Button.gameObject:SetActive( true );
        CS.UGUIClickEventListener.Get(view.Button.gameObject).onClick = function()
            TeamModule.ConfiremTeamJoinRequest(info.pid);
        end
	end
     print(#list)
    self.nguiDragIconScript.DataCount = #list
end

function View:SwitchList()
    local teamInfo = TeamModule.GetTeamInfo();
    if teamInfo.id <= 0 then
        self.show_waiting_list = false;
    else
        self.show_waiting_list = not self.show_waiting_list;
    end

    self:UpdateTeamList();
    self:UpdateWaitingList();
    self:UpdateTeamList();
end

function View:Updatechat(chatInfo)
    local members = TeamModule.GetTeamMembers();
    local name = "unknown";
    for _, v in ipairs(members) do
        if v.pid == chatInfo.pid then
            name = v.name;
            break;
        end
    end
    self.view.Chat.LastMessage[UnityEngine.UI.Text].text = "[" .. name .. "] " .. chatInfo.msg;
end

function View:OnCreateTeamClick()
    local teamInfo = TeamModule.GetTeamInfo();
    if teamInfo.id > 0 then
        TeamModule.KickTeamMember();
    elseif teamInfo.id == 0 then
        TeamModule.CreateTeam(3);
    else
        print("loading team info")
    end
end


function View:OnTeamEvent(type, data)
    print("OnTeamEvent", type, data);
    if type == 1 then
        SceneStack.Push('battle', 'view/battle.lua', {fight_data = data[1], round_timeout = data[2], callback = function(win, heros)
			print("!!!!!!!!!!!!!!!! fight result", win)
		end } );
    end
end

function View:OpenMap()
    SceneStack.EnterMap("map_scene");
end


return View;