local openLevel = require "config.openLevel"
local RedDotModule = require "module.RedDotModule"
local Time = require "module.Time"
local MapConfig = require "config.MapConfig"
local PlayerInfoModule = require "module.PlayerInfoModule"
local TeamModule = require "module.TeamModule"
local NetworkService = require "utils.NetworkService"
local MapModule = require "module.MapModule"
local playerModule = require "module.playerModule"
local View = {}

local click_node = {
    [1] = {node = "home_huodong", tip = "activity", openLevel = 1201, dialog = "mapSceneUI/newMapSceneActivity", args = {filter = {flag = false, id = 1003}}},--活动
    [2] = {node = "home_mail", tip = "mail", openLevel = 1501, dialog = "FriendSystem/FriendMail", red = RedDotModule.Type.Mail.MailAndAward,
    animator = {node = "home_mail_open", name = "home_mail_open", time = 1.2}},--邮箱
    [3] = {node = "home_ziliaogui", tip = "dataBox", openLevel = 8100, dialog = "dataBox/DataBox", red = RedDotModule.Type.DataBox.DataBox},--资料柜
    [4] = {node = "home_dianti", tip = "pvp", openLevel = 2205, dialog = "mapSceneUI/newMapSceneActivity", args = {filter = {flag = true, id = 1003}},
    animator = {node = "open_dianti", name = "open_dianti", time = 1.5}},--竞技
    [5] = {node = "home_door", tip = "jd", openLevel = 2001, map = 26, red = RedDotModule.Type.Manor.Manor, animator = {node = "open_door_Mask", name = "open_door", time = 1}},--基地
}
function View:OnPreload(arg)
    self.updateTime = 0;
    self.ui = UnityEngine.GameObject.Instantiate(SGK.ResourcesManager.Load("prefabs/mapSceneUI/mapSceneUI.prefab"));
    SGK.LuaLoader.Load("view/MapTouchMove.lua", {pos = Vector3(-1.07, 0, 0)})
end

function View:Start(arg)
    self.view = SGK.UIReference.Setup(self.gameObject);
    self.Cemetery = CS.SGK.UIReference.Setup(UnityEngine.GameObject.Find("Cemetery"))
    self.home = CS.SGK.UIReference.Setup(UnityEngine.GameObject.Find("home"));
    self.home_door = self.home.home_door;
    self.mapController = self.view.MapSceneController[SGK.MapSceneController];
    self:ParseMapParams(arg)
    self.doing = false;
    if self.ui then
        self.ui:GetComponent(typeof(UnityEngine.Canvas)).worldCamera = self.mapController.UICamera;
    end
    self:InitUI();
    PlayerInfoModule.SetPlayerScale(1.6);
    -- self:InitPlayer();
    -- module.MapModule.SetMapid(1,0,0,0)
    -- module.TeamModule.MapMoveTo(0,0,0, 1, 1, module.playerModule.Get().id);
    SceneStack.MapId(self.mapId, self.mapType, self.mapRoom)
    self:LoadPlayerPosition(arg)
    TeamModule.ResumeTeamFight();
end

function View:ParseMapParams(arg)
    self.mapId = (arg and arg.mapid) or self.savedValues.mapId or self.mapController.mapId;

    self.mapType = (arg and arg.mapType) or self.savedValues.mapType or self.mapController.mapType;
    self.mapRoom = (arg and arg.room) or self.savedValues.mapRoom;

    if not self.mapRoom then
        if self.mapType == 1 or self.mapType == 5 then
            self.mapRoom = module.playerModule.GetSelfID()  -- private map -- TODO: enter team leader map
        elseif self.mapType == 3 then
            self.mapRoom = TeamModule.GetTeamInfo().id; -- team map
        elseif self.mapType == 4 then
            self.mapRoom = module.unionModule.Manage:GetUionId() or 0;
        else
            self.mapRoom = 1
        end
    end
    self.mapController.mapId = self.mapId
    self.mapController.mapType = self.mapType


    self.savedValues.mapId   = self.mapId;
    self.savedValues.mapType = self.mapType;

    self.savedValues.mapRoom = self.mapRoom;

    self.target = arg and arg.target;

    self.mapMoveStyle = arg and arg.map_move_style;
end

function View:InitUI()
    -- CS.ModelClickEventListener.Get(self.Cemetery.manor.gameObject).onClick = function(go, pos)
    --     if not utils.SGKTools.GetTeamState() or utils.SGKTools.isTeamLeader() then
    --         SceneStack.EnterMap(26, {mapid = 26, mapType = 1})
    --     else
    --         showDlgError(nil, "在队伍中,无法操作")
    --     end
    -- end
    -- CS.ModelClickEventListener.Get(self.Cemetery.manor.title.gameObject).onClick = function(go, pos)
    --     if not utils.SGKTools.GetTeamState() or utils.SGKTools.isTeamLeader() then
    --         SceneStack.EnterMap(26, {mapid = 26, mapType = 1})
    --     else
    --         showDlgError(nil, "在队伍中,无法操作")
    --     end
    -- end
    self:updateStatus();
end

function View:InitPlayer()
    local conf = MapConfig.GetMapConf(self.mapId);
    local pid = module.playerModule.GetSelfID();
    local character = self.mapController:Get(pid) or self.mapController:Add(pid);
    character:MoveTo(conf.initialposition_x, conf.initialposition_y, conf.initialposition_z, true);
    local characterView = SGK.UIReference.Setup(character.gameObject);
    characterView.Character.transform.localScale = Vector3(0,1,1)
    self.characterEffect = nil
    SGK.ResourcesManager.LoadAsync(self.view[SGK.UIReference],"prefabs/effect/UI/fx_chuan_ren.prefab",function (temp)
        self.characterEffect = GetUIParent(temp,characterView)
        self.characterEffect.transform.localPosition = Vector3.zero
    end)
    characterView.Character.transform:DOScale(Vector3(1,1,1),0.25):OnComplete(function ( ... )

    end):SetDelay(0.25)
    -- characterView.Character.Label.Btn:SetActive(false)--完毕玩家自己身上的点击按钮
    
end

function View:updateStatus()
    -- if v.map == 26 then
    --     self.home_door.open_door_Mask[UnityEngine.Animator]:Play("open_door")
    --     SGK.Action.DelayTime.Create(1):OnComplete(function() 
    --         SceneStack.EnterMap(v.map, {mapid = v.map, mapType = 1})
    --     end)
    -- else
    -- end

    for i,v in ipairs(click_node) do
        if v.openLevel == nil or openLevel.GetStatus(v.openLevel) then
            self.Cemetery[v.tip]:SetActive(true)
            local GoTo = function ()
                if v.dialog then
                    DialogStack.Push(v.dialog, v.args)
                elseif v.map then
                    SceneStack.EnterMap(v.map, {mapid = v.map, mapType = 1})
                end
                SGK.Action.DelayTime.Create(0.2):OnComplete(function() 
                    self.doing = false;
                end)
            end
            local listener1 = CS.ModelTouchEventListener.Get(self.Cemetery[v.tip].gameObject);
            if listener1.checkMoveDistance ~= nil then
                listener1.checkMoveDistance = true;
            end
            listener1.onTouchBegan = function(pos)
                self.Cemetery[v.tip].gameObject.transform:DOScale(Vector3.one * 1.1, 0.1);
            end
            listener1.onTouchCancel = function()
                self.Cemetery[v.tip].gameObject.transform:DOScale(Vector3.one, 0.1);
            end
            listener1.onTouchEnd = function(pos)
                self.Cemetery[v.tip].gameObject.transform:DOScale(Vector3.one, 0.1);
                if self.doing then
                    return;
                else
                    self.doing = true;
                end
                if v.animator then
                    self.home[v.node][v.animator.node][UnityEngine.Animator]:Play(v.animator.name);
                    SGK.Action.DelayTime.Create(v.animator.time):OnComplete(function() 
                        SGK.Action.DelayTime.Create(0.1):OnComplete(function() 
                            self.home[v.node][v.animator.node][UnityEngine.Animator]:Rebind();
                        end)
                        GoTo();
                    end)
                else
                    GoTo();
                end    
            end
            local listener2 = CS.ModelTouchEventListener.Get(self.home[v.node].gameObject);
            if listener2.checkMoveDistance ~= nil then
                listener2.checkMoveDistance = true;
            end
            listener2.onTouchEnd = function (pos)
                if self.doing then
                    return;
                else
                    self.doing = true;
                end
                if v.animator then
                    self.home[v.node][v.animator.node][UnityEngine.Animator]:Play(v.animator.name);
                    SGK.Action.DelayTime.Create(v.animator.time):OnComplete(function() 
                        SGK.Action.DelayTime.Create(0.1):OnComplete(function() 
                            self.home[v.node][v.animator.node][UnityEngine.Animator]:Rebind();
                        end)
                        GoTo();
                    end)
                else
                    GoTo();
                end 
            end
            self.home[v.node][UnityEngine.BoxCollider].enabled = true;
        else
            self.home[v.node][UnityEngine.BoxCollider].enabled = false;
            self.Cemetery[v.tip]:SetActive(false);
        end
    end
end

function View:updateRedPoint()
    for i,v in ipairs(click_node) do
        if v.red then
            if v.openLevel == nil or openLevel.GetStatus(v.openLevel) then
                self.Cemetery[v.tip].red:SetActive(RedDotModule.GetStatus(v.red))
            else
                self.Cemetery[v.tip].red:SetActive(false)
            end
        end
    end
end

function View:TeamResetPos(data)
    coroutine.resume( coroutine.create( function ( ... )    
        local teamInfo = TeamModule.GetTeamInfo();
        local pid = module.playerModule.GetSelfID();
        if teamInfo.afk_list[pid] == true then
            return
        end
        if not TeamModule.CheckEnterMap(data.mapid) then
            -- print("不能进入该地图",TeamModule.CheckEnterMap(mapid));
            return;
        end
        if data.mapid == self.mapId then
            -- print("如果和队长在同一张图则同步到队长房间");
            local map_info = MapConfig.GetMapConf(data.mapid);
            if not teamInfo.leader then
                return;
            end
    
            local character = self.mapController:Get(teamInfo.leader.pid)
            if character then
                character:MoveTo(data.x, data.y, data.z,TeamModule.TeamLeaderStatus());
            end
            if self.mapRoom ~= data.room then
                SceneStack.TeamEnterMap(data.mapid, data);
            else
                TeamModule.MapMoveTo(data.x, data.y, data.z, self.mapId, self.mapType, data.room)--如果和队长在同一张图则同步到队长房间
            end
            module.TeamModule.TeamLeaderStatus(true)
        else
            SceneStack.TeamEnterMap(data.mapid, data);
        end
    end))
end

function View:TeamDatePro()
    local teamInfo = TeamModule.GetTeamInfo();
    if teamInfo.group ~= 0 then
        local tempArr = {}
        tempArr[1] = teamInfo.leader.pid
        tempArr[2] = {}
        local members = TeamModule.GetTeamMembers(1)
        for k,v in ipairs(members) do
            tempArr[2][#tempArr[2] + 1] = v.pid
        end
        tempArr[3] = teamInfo.id--队伍id
        return tempArr
    end
    return {}
end

function View:SetPosition(x,y,z)
    local cfg = MapConfig.GetMapConf(self.mapController.mapId);
    if cfg and cfg.sceneback == 0 then
        MapModule.SetMapid(self.mapId,x,y,z)
    end
end

function View:LoadPlayerPosition(arg)
    -- ERROR_LOG("playerPosition",sprinttb(arg));
    local x,y,z = 0, 0, 0;

    local pos = (arg and arg.pos) or self.savedValues.pos;
    if pos then
        x,y,z = pos[1], pos[2], pos[3];
    else
        local conf = MapConfig.GetMapConf(self.mapId)
        if conf then
            x = conf.initialposition_x
            y = conf.initialposition_y
            z = conf.initialposition_z
        end
        local _mapid,_x,_y,_z = MapModule.GetiMapid()
        if _mapid and _x and _y and _z and _mapid == self.mapId then
            -- x = _x
            -- y = _y
            -- z = _z
        else
            self:SetPosition(x,y,z)
        end
    end
    self.PlayerPosition = {x=x,y=y,z=z};
    local pid = playerModule.GetSelfID();
    TeamModule.MapMoveTo(x, y, z, self.mapId, self.mapType, self.mapRoom, self.mapMoveStyle);
    local character = self.mapController:Get(pid) or self.mapController:Add(pid);
    local characterView = SGK.UIReference.Setup(character.gameObject);

    -- 移除玩家自己的碰撞体
    -- characterView[UnityEngine.Collider].enabled = false;

    characterView.Character.transform.localScale = Vector3(0,1,1)
    self.characterEffect = nil
    if arg and arg.effectName then
        if arg.effectName ~= "" then
            SGK.ResourcesManager.LoadAsync(self.view[SGK.UIReference],"prefabs/effect/UI/"..arg.effectName .. ".prefab",function (temp)
               self.characterEffect = GetUIParent(temp,characterView)
               self.characterEffect.transform.localPosition = Vector3.zero
            end)
        end
    else
        SGK.ResourcesManager.LoadAsync(self.view[SGK.UIReference],"prefabs/effect/UI/fx_chuan_ren.prefab",function (temp)
            self.characterEffect = GetUIParent(temp,characterView)
            self.characterEffect.transform.localPosition = Vector3.zero
        end)
    end
    characterView.Character.transform:DOScale(Vector3(1,1,1),0.25):OnComplete(function ( ... )

    end):SetDelay(0.25)
    -- characterView.Character.Label.Btn:SetActive(false)--完毕玩家自己身上的点击按钮
    character:MoveTo(x, y, z, true);
    -- self.mapController:ResetCamera();

    local teamInfo = module.TeamModule.GetTeamInfo();
    if teamInfo and teamInfo.id > 0 then
        if playerModule.GetSelfID() ~= teamInfo.leader.pid then
            if teamInfo.afk_list[math.floor(playerModule.GetSelfID())] ~= true then
                self:FollowQueue(self:TeamDatePro(),x,y,z)        
            end
            NetworkService.Send(18044, {nil,teamInfo.leader.pid})--查询队长位置
        elseif not arg or not arg.effectName or (arg and arg.effectName and arg.effectName ~= "") then
             self:FollowQueue(self:TeamDatePro(),x,y,z)   
            module.TeamModule.SyncTeamData(100, {self.mapId, self.mapType, self.mapRoom})--向队员发送地图
        else
            self:FollowQueue(self:TeamDatePro(),x,y,z)  
        end
    end

    local agent = characterView[UnityEngine.AI.NavMeshAgent]
    character.onStop = function(point)
        if agent.stoppingDistance <= 0.1 then
            return;
        end
        local teamInfo = TeamModule.GetTeamInfo();
        if teamInfo.id <= 0 or playerModule.Get().id == teamInfo.leader.pid then
            local x = math.floor(point.x * 1000) / 1000;
            local y = math.floor(point.y * 1000) / 1000;
            local z = math.floor(point.z * 1000) / 1000;
            self.next_sync_info = nil;

            TeamModule.MapMoveTo(x, y, z)
        end
    end
end

function View:FollowQueue(data,x,y,z)
    local teamInfo = TeamModule.GetTeamInfo();
    if self.mapMoveStyle and self.mapMoveStyle ~= 0 then
        return;
    end

    local mapId = SceneStack.MapId();
    -- ERROR_LOG("队伍跟随信息=========>>>>",sprinttb(data));
    if data and #data ~= 0 and data[3] > 0 and #data[2] > 0 then
        TeamModule.SetMapTeam(data[3],data)
        local obj = self.mapController:Get(data[1]) or self.mapController:Add(data[1]);

        if obj then
            local FollowMovement3d = obj.gameObject:GetComponent("FollowMovement3d")
            if FollowMovement3d then
                FollowMovement3d:Reset()
                FollowMovement3d.enabled = false
            end
            
            if x and y and z then
                obj:MoveTo(x,y,z,true)
            end
            --obj.transform.position = Vector3.zero
           -- local character = self.mapController:Get(teamInfo.leader.pid) or self.mapController:Add(teamInfo.leader.pid);
            local leaderView = SGK.UIReference.Setup(obj.gameObject);
            leaderView.Character.Label.leader:SetActive(true)
            leaderView[UnityEngine.AI.NavMeshAgent].enabled = true
            leaderView[UnityEngine.AI.NavMeshAgent].stoppingDistance = 0
            obj.enabled = true;
            for i = 1,#data[2] do
                local pid = data[2][i]
                if pid ~= data[1] then
                    obj = self.mapController:AddMember(pid,obj.gameObject)
                    local memberView = SGK.UIReference.Setup(obj.gameObject);
                    memberView.Character.Label.leader:SetActive(false)
                    memberView[UnityEngine.AI.NavMeshAgent].enabled = false
                end
            end
        end
    end
end

function View:RefreshObjects(oldPlayerPids)
    -- print("玩家信息_____",sprinttb(oldPlayerPids));
    self.characters = oldPlayerPids or {};
    local players = TeamModule.MapGetPlayers();

    --获取到所有队伍玩家
    for i = 1,#self.characters do
        local pid = self.characters[i]

        --如果地图上没有该玩家的数据
        if not players[pid] then
            local teamid = TeamModule.GetMapPlayerTeam(pid)
            if teamid and self.mapMoveStyle == 0 then
                for i = 1,#TeamModule.GetMapTeam(teamid)[2] do
                    local old_pid = TeamModule.GetMapTeam(teamid)[2][i]
                    if playerModule.GetSelfID() ~= old_pid then
                        self.mapController:Remove(old_pid);
                        ModuleMgr.Get().MapPlayerModule:Remove(old_pid)
                    end
                end
                TeamModule.SetMapTeam(teamid,nil)--清除地图队伍数据
            else
                self.mapController:Remove(pid);
                ModuleMgr.Get().MapPlayerModule:Remove(pid)
            end
        end
    end

    -- for pid, pos in pairs(players) do
    --     if pid ~= playerModule.GetSelfID() then
    --         local character = self.mapController:Get(pid)
    --         if character then
    --             local dist = UnityEngine.Vector3.Distance( UnityEngine.Vector3(pos.x,pos.y,pos.z), character.transform.position)
    --             if dist >0.1 then
    --                 self:MoveTo(pid, pos.x, pos.y, pos.z);
    --             end

    --         end
    --     end
    -- end
end

function View:RemoveObject(pid,status)
    if pid ~=  playerModule.GetSelfID() then
        if TeamModule.GetMapPlayerTeam(pid) and not status then
            local teamid = TeamModule.GetMapPlayerTeam(pid)
            if TeamModule.GetMapTeam(teamid)[1] == pid then
                --是队长
                local Teamlist = TeamModule.GetMapTeam(teamid)[2]
                print("获取队伍列表",sprinttb(Teamlist));
                for i = 1,#Teamlist do
                    if pid ~= Teamlist[i] then
                        self:RemoveObject(Teamlist[i],true)
                    end
                end
            end
        end
        --删除的对象不是自己
        local character = self.mapController:Get(pid)
        if character then
            local _characterView = SGK.UIReference.Setup(character)
            if _characterView.Character.gameObject.transform.childCount == 4 then
                self.ClickPlayer_NPC_Effect = nil
            end
        end
        self.mapController:Remove(pid);
        ModuleMgr.Get().MapPlayerModule:Remove(pid)
    end
end

function View:Update()
    if Time.now() - self.updateTime >= 1 then
        self.updateTime = Time.now();
        self:updateRedPoint();
    end
end

function View:listEvent()
	return {
        "PLAYER_INFO_CHANGE",
        "MAP_QUERY_PLAYER_INFO_REQUEST",
        "TEAM_LEADER_CHANGE",
        "MAP_CHARACTER_REFRESH",
        "MAP_CHARACTER_DISAPPEAR",
        "Add_team_succeed",
        "TEAM_INFO_CHANGE",
        "Leave_team_succeed",
        "Team_members_Request",
        "TEAM_DATA_SYNC",
        "PlayerEnterMap"
	}
end

function View:onEvent(event, ...)
	if event == "PLAYER_INFO_CHANGE" then
        self:updateStatus();
    elseif event == "MAP_QUERY_PLAYER_INFO_REQUEST" then
        --查询目标玩家地图位置信息请求
        local data = select(1, ...);
        self:TeamResetPos(data)
    elseif event == "TEAM_LEADER_CHANGE" then
        self:FollowQueue(self:TeamDatePro())
    elseif event == "MAP_CHARACTER_REFRESH" then
        local data = ...;
        self:RefreshObjects(data);
    elseif event == "MAP_CHARACTER_DISAPPEAR" then
        local data = ...
        self:RemoveObject(math.floor(data))
        self:FollowQueue(self:TeamDatePro()) 
    elseif event == "Add_team_succeed" then
        --新人加入队伍
        local data = ...
        local teamInfo = TeamModule.GetTeamInfo()
        if teamInfo.id > 0 then
            if playerModule.GetSelfID() == data.pid then
                if playerModule.GetSelfID() ~= teamInfo.leader.pid then
                    showDlgError(nil,"成功加入"..teamInfo.leader.name.."的队伍")
                end
            else
                DispatchEvent("PLayer_Shielding",{pid = data.pid})
                self:FollowQueue(self:TeamDatePro())
            end
        end
    elseif event == "TEAM_INFO_CHANGE" then
        self:FollowQueue(self:TeamDatePro())
    elseif event == "Leave_team_succeed" then
        --离开队伍
        local data = ...
        local character = self.mapController:Get(data.pid) or self.mapController:Add(data.pid);
        local NavMeshAgent = character.gameObject:GetComponent("NavMeshAgent")
        if not NavMeshAgent.enabled then
            NavMeshAgent.enabled = true
            character.enabled = true;
        end
        local FollowMovement3d = character.gameObject:GetComponent("FollowMovement3d")
        if FollowMovement3d then
            FollowMovement3d:Reset()
            FollowMovement3d.enabled = false
        end

        local leaderView = SGK.UIReference.Setup(character.gameObject);
        leaderView.Character.Label.leader:SetActive(false)
        if playerModule.Get().id ~= data.pid then
            self:FollowQueue(self:TeamDatePro())--队伍中vi 有人离开，队伍重新编队
            if self.mapType ~= 2  then
                self:RemoveObject(data.pid,true)--清除人物
            end
            local Shielding = module.MapModule.GetShielding()
            if Shielding then
                DispatchEvent("PLayer_Shielding",{pid = data.pid,x = 0})
            end
        else
            module.QuestModule.SetOldUuid(nil)
            local team_id = TeamModule.GetMapPlayerTeam(data.pid)
            local list = module.TeamModule.GetMapLeaveTeam(team_id,data.pid)
            local character = self.mapController:Get(data.pid) or self.mapController:Add(data.pid);

            local FollowMovement3d = character.gameObject:GetComponent("FollowMovement3d")
            if FollowMovement3d then
                FollowMovement3d:Reset()
                FollowMovement3d.enabled = false
            end
            print("自己离队", utils.SGKTools.Athome(), self.mapRoom, playerModule.Get().id)
            if utils.SGKTools.Athome() then
                if math.floor(self.mapRoom) ~= math.floor(playerModule.Get().id) then
                    SceneStack.EnterMap(1);
                end
                TeamModule.SetMapTeam() 
            end
            self:FollowQueue(list)--自己离队，原队伍重新编队
        end
        self:RefreshObjects();
    elseif event == "Team_members_Request" then
         --队伍中的队员数据查询返回
         local data = ...;
         self:FollowQueue(data.members);
    elseif event == "TEAM_DATA_SYNC" then
        local pid,Type,value = ...
        if Type == 100 and #value > 0 then--队长切换地图
            local mapId   = value[1];
            local mapType = value[2];
            local mapRoom = value[3];
            if mapId ~= self.mapId or mapType ~= self.mapType or mapRoom ~= self.mapRoom then
                local teamInfo = TeamModule.GetTeamInfo()
                if teamInfo.group ~= 0 and playerModule.GetSelfID() ~= teamInfo.leader.pid and not(teamInfo.afk_list[playerModule.GetSelfID()]) then
                    coroutine.resume(coroutine.create( function ( ... )
                        SceneStack.TeamEnterMap(mapId, {mapType = mapType, room = mapRoom});
                    end))
                end
            end
        elseif Type == 101 or Type == 102 then--队员更换名字or形象
        elseif Type == 103 then--队长触发剧情
            local teamInfo = TeamModule.GetTeamInfo()
            if pid ~= playerModule.GetSelfID() and not(teamInfo.afk_list[playerModule.GetSelfID()]) then
                LoadStory(value)
            end
        elseif Type == 104 then--全队同步接任务
            if pid ~= playerModule.GetSelfID() then
                module.QuestModule.Accept(value)
            end
        elseif Type == 105 then--全队同步交任务
            if pid ~= playerModule.GetSelfID() then
                module.QuestModule.Submit(value)
            end
        elseif Type == 106 then--队伍发表情
        elseif Type == 107 then--全队发送错误通知
            showDlgError(nil,value[2])
        elseif Type == 108 then--全队通知队员等级变化
            module.playerModule.updatePlayerLevel(pid,value)
            module.TeamModule.updateTeamMemberLevel(pid,value)
            module.playerModule.GetFightData(pid,true)
        elseif Type == 109 then--全队执行某脚本
            -- self.Lock_TeamMove = true
            local name = value[1]
            local mapid = value[2]
            local gid = value[3]
            local target_map = value[4]
            --local character = self.mapController:Get(pid)
            local thread = Thread.Create(function()
                AssociatedLuaScript(name,mapid,gid,target_map)
            end):Start()
        elseif Type == 110 then--对方更新阵容信息
        elseif Type == 111 then--队长召回队员
        end
    elseif event == "PlayerEnterMap" then
        ERROR_LOG("不知道干啥的消息", debug.traceback())
        -- local data = ...
        -- if not TeamModule.CheckEnterMap(data) then
        --     showDlgError(nil,"进不了队长的地图");
        --     return;
        -- end
        -- local teamInfo = module.TeamModule.GetTeamInfo()
        -- local pid = module.playerModule.GetSelfID()
        -- if teamInfo.id <= 0 or teamInfo.afk_list[pid] then
        --     utils.SGKTools.PLayerConceal(true)
        -- else
        --     utils.SGKTools.TeamConceal(true)
        -- end
        -- if self.characterEffect == nil then
        --     SGK.ResourcesManager.LoadAsync(self.view[SGK.UIReference],"prefabs/effect/UI/fx_chuan_ren.prefab",function (temp)
        --         self.characterEffect = GetUIParent(temp,characterView)
        --         self.characterEffect.transform.localPosition = Vector3.zero
        --     end)
        -- else
        --     self.characterEffect:SetActive(false)
        --     self.characterEffect:SetActive(true)
        --     self.characterEffect.transform.localPosition = Vector3.zero
        -- end
        -- SGK.Action.DelayTime.Create(0.5):OnComplete(function ()
        --     SceneStack.TeamEnterMap(data);
        -- end)
 	end
end

return View
