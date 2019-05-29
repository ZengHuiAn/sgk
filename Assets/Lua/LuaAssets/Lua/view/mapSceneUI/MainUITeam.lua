local TeamModule = require "module.TeamModule"
local playerModule = require "module.playerModule"
local SmallTeamDungeonConf = require "config.SmallTeamDungeonConf"
local NetworkService = require "utils.NetworkService"
local HeroModule = require "module.HeroModule"
local unionModule = require "module.unionModule"
local ChatManager = require 'module.ChatModule'
local ActivityTeamlist = require "config.activityConfig"
local unionModule = require "module.unionModule"
local FriendModule = require 'module.FriendModule'
local CemeteryConf = require "config.cemeteryConfig"

local View = {}
function View:Start(data)
	self.view = CS.SGK.UIReference.Setup(self.gameObject)
	self.attBgList = self.view.attList.gameObject
	self.nowShow = nil
	self.view.mask:SetActive(false)
	CS.UGUIClickEventListener.Get(self.view.mask.gameObject).onClick = function()
		self:removeNowShow()
    end
    
    CS.UGUIClickEventListener.Get(self.view.teambtn.gameObject).onClick = function()
        DialogStack.Push('TeamFrame', {idx = 1})
		self:removeNowShow()
    end
    
    self.view.Group = self.view.Image.Group;
    CS.UGUIClickEventListener.Get(self.view.Group.packUp.teambtn.gameObject).onClick = function()
        DialogStack.Push('TeamFrame', {idx = 1})
		self:removeNowShow()
	end
	self:loadTeam()
	self:packUpBtn()
	self.packUpFlag = true
end

function View:removeNowShow()
	self.view.mask:SetActive(false)
	if self.nowShow then
		UnityEngine.GameObject.Destroy(self.nowShow)
	end
	self.nowShow = nil
end

function View:utf8sub(size, input)
    local len  = string.len(input)
    local left = len
    local cnt  = 0
    local _count = 0
    local arr  = {0, 0xc0, 0xe0, 0xf0, 0xf8, 0xfc}
    while left ~= 0 do
        local tmp = string.byte(input, -left)
        local i   = #arr
        while arr[i] do
            if tmp >= arr[i] then
                left = left - i
                break
            end
            i = i - 1
        end
        if i ~= 1 then
            _count = _count + i
        else
            cnt = cnt + 1
        end
        if (cnt + _count) >= size then
            return string.sub(input, 1, cnt + _count)
        end
    end
    return input;
end


function View:addTextItem(item, node, text, func)
	local _item = UnityEngine.GameObject.Instantiate(item, node.gameObject.transform)
	local _itemView = CS.SGK.UIReference.Setup(_item)
	_item.gameObject:SetActive(true)
	_itemView.Label[UI.Text]:TextFormat(text)
	CS.UGUIClickEventListener.Get(_itemView.btn.gameObject).onClick = function()
		func()
	end
end

function View:packUpBtn()
	CS.UGUIClickEventListener.Get(self.view.Group.packUp.arrow.gameObject).onClick = function()
		if self.packUpFlag then
			for i = 1, 5 do
				self.view.Group[i].gameObject:SetActive(false or i == 1 or i == 2)
			end
            self.view.Group.transform:DOLocalMoveY(254, 0.2)
			self.packUpFlag = false
		else
            self.view.Group.transform:DOLocalMoveY(30, 0.2)
			self:loadTeam()
			self.packUpFlag = true
		end
        self.view.Group.packUp.arrow.transform:DOLocalRotate(Vector3(0, 0, self.packUpFlag and 0 or 180), 0.2)
	end
    -- CS.UGUIClickEventListener.Get(self.view.chatBtn.gameObject).onClick = function()
    --     DialogStack.PushPref("mapSceneTeamChat", nil, self.view)
    --     self.view.chatBtn.red:SetActive(false)
    -- end
end

function View:upTeamAddData(pid)
    local members = TeamModule.GetTeamMembers()
    local index = 0
	for k,v in ipairs(members) do
        index = index + 1
        if v.pid == pid then
            utils.IconFrameHelper.Create(self.view.Group[index].newCharacterIcon, {pid = v.pid})
        end
    end
end

function View:loadTeam( ... )
    -- ERROR_LOG("玩家或队员信息改变");
	self:removeNowShow()
	local teamInfo = TeamModule.GetTeamInfo();
	local members = TeamModule.GetTeamMembers()
    --self.view.chatBtn:SetActive(teamInfo.id > 0)
    -- self.view.Group.packUp:SetActive(false)
    self.view.Group[UI.Image].color = {r = 1, g = 1, b = 1, a = 0}
    if teamInfo.id <= 0 then
        -- self.view.teambtn:SetActive(false);
        --DialogStack.Destroy("mapSceneTeamChat")
        self.view.Group:SetActive(false)
        if module.TeamModule.GetplayerMatchingType() ~= 0 then
            self.view.matchBtn:SetActive(true);
            
            self.view.matchBtn[CS.UGUIClickEventListener].onClick = function ()
                module.TeamModule.playerMatching(0)
            end
            self.view.teambtn:SetActive(false);
        else    
            self.view.matchBtn:SetActive(false);
            self.view.teambtn:SetActive(true);
        end
        return
    end
    self.view.matchBtn:SetActive(false);
    self.view.teambtn:SetActive(false);
    -- if not DialogStack.GetPref_list("mapSceneTeamChat") then
    --     DialogStack.PushPref("mapSceneTeamChat", nil, self.view)
    -- end
    local selfPid = playerModule.Get().id;
    self.view.Group[UI.Image].color = {r = 1, g = 1, b = 1, a = 1}
    --self.view.chatBtn.red:SetActive(module.RedDotModule.GetStatus(module.RedDotModule.Type.MainUITeam.MainUITeam))
    self.view.Group.packUp:SetActive(true)
	self.view.Group:SetActive(true)
	for i = 1, 5 do
		self.view.Group[i].name[UnityEngine.UI.Text].text = ""
		self.view.Group[i].leader.gameObject:SetActive(false)
		self.view.Group[i].icon.gameObject:SetActive(false)
        self.view.Group[i]:SetActive(false)
        self.view.Group[i].add:SetActive(false)
        self.view.Group[i].add.cancel:SetActive(false)
        self.view.Group[i].nameBg:SetActive(false)
	end
	local cfg = HeroModule.GetConfig()
	local index = 0

	for k,v in ipairs(members) do
        index = index + 1

        local info = playerModule.Get(v.pid)

        if info then
            v.name = info.name
        end
        local _name = self:utf8sub(9, v.name)
        self.view.Group[index].name[UnityEngine.UI.Text].text = _name
        if _name ~= v.name then
            self.view.Group[index].name[UnityEngine.UI.Text].text = self.view.Group[index].name[UnityEngine.UI.Text].text.."..."
        end
        self.view.Group[index].nameBg:SetActive(true)
        self.view.Group[index].add:SetActive(false)
		self.view.Group[index].leader:SetActive(v.pid == teamInfo.leader.pid)
        self.view.Group[index].afk:SetActive(TeamModule.getAFKMembers(v.pid) and v.pid ~= teamInfo.leader.pid)
        self.view.Group[index].afk.btn:SetActive(v.pid==playerModule.GetSelfID())
        CS.UGUIClickEventListener.Get(self.view.Group[index].afk.btn.gameObject).onClick = function()
            teamInfo = TeamModule.GetTeamInfo();
            --回归

            TeamModule.QueryLeaderInfo(function (data)
                if data[2] == 0 then
                    --todo
                    if TeamModule.CheckEnterMap(data[3][1],true) then

                        TeamModule.TEAM_AFK_RESPOND(function (err )
                            if err == 0 then
                                module.TeamModule.QueryLeaderInfo();--查询队长位置
                            end
                        end)
                    else
                        showDlgError(nil,"无法传送到队长身边");
                    end
                end
            end);
            self:removeNowShow()
        end
		local _attNod = self.view.Group[index].attNode.gameObject.transform
		self.view.Group[index][CS.UGUIClickEventListener].onClick = function ( ... )
			local _attBgList = UnityEngine.GameObject.Instantiate(self.attBgList, _attNod)
			_attBgList.gameObject:SetActive(true)

			self:removeNowShow()
			self.nowShow = _attBgList
			self.view.mask:SetActive(true)
    		local _view = CS.SGK.UIReference.Setup(_attBgList)

            local fistMember = TeamModule.GetFirstMember();
            if selfPid == teamInfo.leader.pid and not fistMember then
                _view.aft.Text[UI.Text]:TextFormat("解散队伍")
            end
            _view.leaveBy.Text[UI.Text]:TextFormat("离开队伍")
            _view.leaveBy:SetActive(v.pid == selfPid)
            _view.chat:SetActive(v.pid ~= selfPid)
            _view.checkTeam:SetActive(v.pid == selfPid)
            _view.addFriend:SetActive(v.pid ~= selfPid and not FriendModule.GetManager(1,v.pid))
            _view.handOver:SetActive(teamInfo.leader.pid == selfPid and v.pid ~= selfPid)
            _view.leave:SetActive(teamInfo.leader.pid == selfPid and v.pid ~= selfPid)

            _view.applyLeader:SetActive(teamInfo.leader.pid == v.pid and teamInfo.leader.pid ~= selfPid)

            _view.confirm:SetActive(v.pid == teamInfo.leader.pid and v.pid == selfPid)
            --暂离按钮
            if v.pid == selfPid and teamInfo.leader.pid == selfPid then
                _view.aft:SetActive(false)
            else
                _view.aft:SetActive(selfPid == v.pid and (not TeamModule.getAFKMembers(v.pid)) and #members>1)
            end
            _view.aftLeave:SetActive(selfPid == v.pid and v.pid ~= teamInfo.leader.pid and TeamModule.getAFKMembers(v.pid))
            _view.free:SetActive(false);
            -- _view.free:SetActive(selfPid == v.pid and v.pid ~= teamInfo.leader.pid and (module.MapModule.GetPlayerStatus(v.pid)))
            _view.freeLeave:SetActive(selfPid == v.pid and v.pid ~= teamInfo.leader.pid and (not module.MapModule.GetPlayerStatus(v.pid)))
            _view.assembled:SetActive(selfPid == v.pid and v.pid == teamInfo.leader.pid)
            CS.UGUIClickEventListener.Get(_view.checkTeam.gameObject).onClick = function()
                DialogStack.PushPrefStact('TeamFrame', {idx = 1})
                self:removeNowShow()
        	end
            CS.UGUIClickEventListener.Get(_view.confirm.gameObject).onClick = function()
                TeamModule.NewReadyToFight(0)
                self:removeNowShow()
            end
            --离队按钮
            CS.UGUIClickEventListener.Get(_view.leaveBy.gameObject).onClick = function()
                if teamInfo.leader.pid == selfPid and #members > 1 then
                    showDlgMsg("是否确认离开队伍?", function()
                        --获取到第一个不是暂离的成员,
                        TeamModule.KickTeamMember()

                    end, function()end)
                else
                    TeamModule.KickTeamMember()
                end
        	end
            CS.UGUIClickEventListener.Get(_view.applyLeader.gameObject).onClick = function()
                TeamModule.LeaderApplySend()
        	end
            CS.UGUIClickEventListener.Get(_view.chat.gameObject).onClick = function()
            	-- local list = nil
             --    if ChatManager.GetManager(6) then
             --        list = ChatManager.GetManager(6)[v.pid]
             --    end
             --    DialogStack.PushPref("FriendChat",{data = list,pid = v.pid},UnityEngine.GameObject.FindWithTag("UGUIRootTop").gameObject)
                --DispatchEvent("LOCAL_MAPSCENE_OPEN_CHATFRAME", {type = 4,playerData = {id = v.pid,name = v.name}})
                DialogStack.Push("FriendSystemList",{idx = 1,viewDatas = {{pid = v.pid,name = v.name}}})
        	end
            CS.UGUIClickEventListener.Get(_view.addFriend.gameObject).onClick = function()
                unionModule.AddFriend(v.pid)
    	    	self:removeNowShow()
        	end
            CS.UGUIClickEventListener.Get(_view.handOver.gameObject).onClick = function()
                local status = TeamModule.MoveHeader(v.pid);

                if status == 1 then
                    showDlgError(nil, "对方处于暂离状态,不能移交队长")
                end
        	end
            CS.UGUIClickEventListener.Get(_view.leave.gameObject).onClick = function()
                TeamModule.KickTeamMember(v.pid)
        	end

            CS.UGUIClickEventListener.Get(_view.aft.gameObject).onClick = function()
                --如果自己是队长
                local fistMember = TeamModule.GetFirstMember();
                if selfPid == teamInfo.leader.pid  then
                    showDlgMsg( fistMember and "确认暂离队伍吗?" or "确认解散队伍吗?", function()
                        -- TeamModule.MoveHeader();

                        --当前没有在线成员(离线和暂离)
                        if not fistMember then
                            TeamModule.KickTeamMember()
                        else
                            local err = TeamModule.MoveHeader(fistMember.pid);
                            if not err then
                                self.aftStatus = true;
                            end

                        end
                        self:removeNowShow()

                    end, function()end)
                else
                    -- if teamInfo.afk_list[math.floor(playerModule.Get().id)] == false then
                    --     --todo
                    --     TeamModule.TEAM_AFK_REQUEST()
                    -- end
                    TeamModule.TEAM_AFK_REQUEST()
                    self:removeNowShow()
                end
        	end
            CS.UGUIClickEventListener.Get(_view.aftLeave.gameObject).onClick = function()
                teamInfo = TeamModule.GetTeamInfo();
                -- print("队伍信息",sprinttb(teamInfo));
                --回归

                TeamModule.QueryLeaderInfo(function (data)
                    if data[2] == 0 then
                        --todo
                        if TeamModule.CheckEnterMap(data[3][1],true) then
                            -- print("可以进地图");

                            TeamModule.TEAM_AFK_RESPOND(function (err )
                                if err == 0 then
                                    module.TeamModule.QueryLeaderInfo();--查询队长位置
                                end
                            end)
                        else
                            showDlgError(nil,"无法传送到队长身边");
                            -- print("不可以进地图"); 
                        end
                    end
                    -- print(sprinttb(data));
                end);
                -- 
                self:removeNowShow()
        	end
            CS.UGUIClickEventListener.Get(_view.free.gameObject).onClick = function()
                utils.SGKTools.SynchronousPlayStatus({6, v.pid, 1})
                self:removeNowShow()
        	end
            CS.UGUIClickEventListener.Get(_view.freeLeave.gameObject).onClick = function()
                utils.SGKTools.SynchronousPlayStatus({6, v.pid, 0})
                self:removeNowShow()
        	end
            --召集按钮
            CS.UGUIClickEventListener.Get(_view.assembled.gameObject).onClick = function()
                utils.SGKTools.TeamAssembled()
                self:removeNowShow()
            end

            teamInfo = TeamModule.GetTeamInfo();
            local flag = nil;
            for k,v in pairs(teamInfo.afk_list) do
                if v == true then
                    flag = true;
                    break;
                end
            end
            -- print("flag",flag);
            if not flag then
                _view.assembled[UI.Image].color = UnityEngine.Color.gray;
                _view.assembled[UI.Button].enabled = false;
                CS.UGUIClickEventListener.Get(_view.assembled.gameObject).interactable = false;
            else
                _view.assembled[UI.Button].enabled = true;
                _view.assembled[UI.Image].color = UnityEngine.Color.white;
                CS.UGUIClickEventListener.Get(_view.assembled.gameObject).interactable = true;
            end
            -- print("点击");
		end
		self.view.Group[index]:SetActive(true)

        -- print("玩家信息",v.id,sprinttb(module.playerModule.Get(v.pid)));
        utils.PlayerInfoHelper.GetPlayerAddData(v.pid, 99, function (addData)
            utils.IconFrameHelper.Create(self.view.Group[index].newCharacterIcon,{pid = v.pid,customCfg = {HeadFrame = addData.HeadFrame,sex = addData.Sex}})
        end)
        -- utils.IconFrameHelper.Create(self.view.Group[index].newCharacterIcon, {pid = v.pid})
	end


    if self.view.Group[index + 1] and index < 5 then
        self.view.Group[index + 1]:SetActive(true)
        self.view.Group[index + 1].add:SetActive(true)
        self.view.Group[index + 1].afk:SetActive(false)
        self.view.Group[index + 1].add.cancel:SetActive(module.TeamModule.GetTeamInfo().auto_match)
        if module.TeamModule.GetTeamInfo().auto_match then

        end
        self.view.Group[index + 1][CS.UGUIClickEventListener].onClick = function ( ... )
            self:removeNowShow()
            if SceneStack.GetBattleStatus() then
		        showDlgError(nil, "战斗内无法进行该操作")
		        return
		    end
			local teamInfo = TeamModule.GetTeamInfo()--获取当前自己的队伍
			if teamInfo.leader.pid == selfPid then
				local conf = CemeteryConf.Getteam_battle_conf(teamInfo.group)
                if not conf then
                    showDlgError(nil,SGK.Localize:getInstance():getValue("zudui_fuben_07"))
    		        return
                end
				local unqualified_name = {}
				for k,v in ipairs(module.TeamModule.GetTeamMembers()) do
                    local current_player = playerModule.Get(v.pid)
                    if current_player.level < conf.limit_level then
						unqualified_name[#unqualified_name+1] = {v.pid,"队伍成员"..current_player.name.."未达到副本所需等级"}
					end
				end
				if #unqualified_name == 0 then
					if not TeamModule.GetTeamInfo().auto_match then
						TeamModule.TeamMatching(true)
					else
						TeamModule.TeamMatching(false)
					end
				else
					for i =1 ,#unqualified_name do
						module.TeamModule.SyncTeamData(107,{unqualified_name[i][1],unqualified_name[i][2]})
					end
				end
			else
				showDlgError(nil,SGK.Localize:getInstance():getValue("common_duiyuanpipei"))
			end
        end


    end
end
function View:onEvent(event, data)
	if event == "LOCAL_MAPSCENE_UI_REFRESH" then

	elseif event == "TeamMatching_succeed" or event == "playerMatching_succeed" or event == "GROUP_CHANGE"
    or event == "TEAM_LEADER_CHANGE" or event == "NOTIFY_TEAM_PLAYER_AFK_CHANGE" then
        self:loadTeam()
    elseif event == "updateTeamMember" then
        self:loadTeam()
    elseif event == "LOCAL_REDDOT_MAPSCENE_TEAM" or event == "LOCAL_REDDOT_CLOSE" then
        --self.view.chatBtn.red:SetActive(module.RedDotModule.GetStatus(module.RedDotModule.Type.MainUITeam.MainUITeam))
    elseif event == "LOCAL_TEAM_PLAYERADDDATE_CHANGE" then
        self:upTeamAddData(data)
    elseif event == "PLAYER_INFO_CHANGE" then
        if data then
            for i,v in ipairs(TeamModule.GetTeamMembers() or {}) do
                if v.pid == data then
                    self:loadTeam()
                end
            end
            ERROR_LOG(event);
            self:loadTeam()
        end
    elseif event == "MOVEHEADERSUCCESS" then

        -- ERROR_LOG("玩家信息改变MOVEHEADERSUCCESS");
        if self.aftStatus then
            -- TeamModule.TEAM_AFK_REQUEST()
            self:removeNowShow()
            self.aftStatus = nil;
        end
    elseif event == "TEAM_MEMBER_CHANGE" then
        self:loadTeam()
        -- ERROR_LOG("有玩家加入",data);
    elseif event == "Add_team_succeed" then
         if data then
            local selfPid = playerModule.Get().id;

            
            local info = playerModule.Get(data.pid);

            if info then
                if data.pid ~= selfPid then
                    showDlgError(nil,info.name .."加入小队");
                    self:loadTeam()
                end      
            end
        end
    elseif event == "Leave_team_succeed" then
        self:loadTeam()
        if data then
            --todo
            local selfPid = playerModule.Get().id;

            -- if playerModule.IsDataExist(data.pid) then
                local info = playerModule.Get(data.pid);
                if info and data.pid ~= selfPid then
                    showDlgError(nil,info.name .."离开小队");   
                end      
            -- end
        end
    end
end

function View:OnEnable()
    self:loadTeam()
end

function View:listEvent()
    return {
    "Leave_team_succeed",
    "TEAM_MEMBER_CHANGE",
    "TEAM_LEADER_CHANGE",
    "LOCAL_MAPSCENE_UI_REFRESH",
    "updateTeamMember",
    "LOCAL_REDDOT_MAPSCENE_TEAM",
    "LOCAL_REDDOT_CLOSE",
    "LOCAL_TEAM_PLAYERADDDATE_CHANGE",
    "TeamMatching_succeed",
    "playerMatching_succeed",
    "GROUP_CHANGE",
    "PLAYER_INFO_CHANGE",
    "NOTIFY_TEAM_PLAYER_AFK_CHANGE",
    "MOVEHEADERSUCCESS",
    "TEAM_JOIN_REQUEST_CHANGE",
    "Add_team_succeed",
}
end
return View
