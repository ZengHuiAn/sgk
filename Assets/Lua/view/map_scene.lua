local TeamModule = require "module.TeamModule"
local EncounterFightModule = require "module.EncounterFightModule"
local playerModule = require "module.playerModule"
local NPCModule = require "module.NPCModule"
local MapModule = require "module.MapModule"
local NetworkService = require "utils.NetworkService"
local MapConfig = require "config.MapConfig"
local honorModule = require "module.honorModule"
local Time = require "module.Time"
local Thread = require "utils.Thread"
local PlayerInfoHelper = require "utils.PlayerInfoHelper"
local ItemModule = require "module.ItemModule"
local PlayerInfoModule = require "module.PlayerInfoModule"
local UserDefault = require "utils.UserDefault";
local System_Set_data=UserDefault.Load("System_Set_data",true);
local TreasureModule = require "module.TreasureModule";
local activityConfig = require "config.activityConfig"
local npcScaleConfig = require "config.npcScaleConfig"

local View = {}

local TipScene = {601,};

function View:OnPreload(arg)
    -- SGK.ResourcesManager.LoadAsync("prefabs/StoryFrame", nil)
    -- SGK.ResourcesManager.LoadAsync("prefabs/StoryOptionsFrame", nil);
    -- local x,y,z = MapModule.GetMapPos()
    -- SGK.UIReference.Setup(self.gameObject).MapSceneController.MainCamera[SGK.MapPlayerCamera].temp = Vector3(x,y,z)
    local MapId = SceneStack.MapId()
    if not (MapId >= 501 and MapId <= 510) then
        self.ui = UnityEngine.GameObject.Instantiate(SGK.ResourcesManager.Load("prefabs/mapSceneUI/mapSceneUI.prefab"));
    else
        UnityEngine.GameObject.Instantiate(SGK.ResourcesManager.Load("prefabs/newTrial/newTrailCanves.prefab"));
    end
end

function View:Start(arg)
    module.TeamModule.mapResetPlayers();
    module.sharedQuestModule.ClearShareQuestNPC()
    local Stack = SceneStack.GetTopStack()
    if Stack and Stack.arg then
        arg = Stack.arg
    end
    if (not arg) or (arg and not arg.fightGuideMode) then
        if arg and arg.first then
            if self.ui then
                self.ui:GetComponent(typeof(SGK.LuaBehaviour)):Call("showFirstUi", {})
            end
        end
    end
    
    -- UnityEngine.Camera.main.orthographicSize = 7
    --ERROR_LOG(sprinttb(Stack))
    self.savedValues = Stack.savedValues
    self.arg = arg
    self.view = SGK.UIReference.Setup(self.gameObject);
    Stack.controller = self.view[SGK.LuaBehaviour]:GetScript()
    --ERROR_LOG(sprinttb(SceneStack.GetTopStack()))
    self.MapPlayerPos_list = {}--当前地图玩家坐标保存
    self.ClickPlayer_NPC_Effect = nil--玩家ornpc特效obj
    self.Select_Effect = nil;
    self.Player_State_Effect = {}--玩家状态特效1寻路2巡逻
    self.Play_pid_list = {}--地图所有玩家pid缓存update
    self.Lock_TeamMove = false--是否锁定队伍移动
    self.Lock_PlayerAdd = false--是否锁定玩家生成
    self.EnterMap_succeed = false--玩家切换地图成功
    self.MapClickEventTime = 0--点击地图时间
    self.mapController = self.view.MapSceneController[SGK.MapSceneController];
    self.mapController:ControllPlayer(playerModule.GetSelfID());
    PlayerInfoModule.clearPlayerFootEffect()--清除脚印历史数据
    TeamModule.SetMapTeam(nil,nil)--重置当前地图所有队伍信息
    module.CemeteryModule.LoadMap_Accomplish()--加载地图检测是否有副本任务可以完成（删除）
    TeamModule.ExamineTeamReady()--检查就位确认
    utils.SGKTools.SynchronousPlayStatus({5,{0,module.playerModule.GetSelfID(),"combat"}})
    utils.SGKTools.SynchronousPlayStatus({6,module.playerModule.GetSelfID(),0})--0无自由，1自由(切换地图重置自己状态)
    -- utils.SGKTools.LockMapClick(false)--切换地图后关闭屏蔽点击
    if self.ui then
        self.ui:GetComponent(typeof(UnityEngine.Canvas)).worldCamera = self.mapController.UICamera;
    end
    self:ParseMapParams(arg)

    if self.mapId == 1 then
        PlayerInfoModule.SetPlayerScale(1.4);
    else
        PlayerInfoModule.SetPlayerScale(1.2);
    end

    local mapCfg = MapConfig.GetMapConf(self.mapId);

    self.mapMoveStyle = self.mapMoveStyle or mapCfg.map_move_style or 0;

    local camera = self.view.MapSceneController.MainCamera.gameObject;
    if mapCfg and mapCfg.camera then
        self.mapController:SelectCamera(mapCfg.camera);
    end

    self.view.MapSceneController[SGK.MapSceneController].onClick = function(point, gameObject)
        local cc = {
            x = math.floor(point.x * 1000) / 1000,
            y = math.floor(point.y * 1000) / 1000,
            z = math.floor(point.z * 1000) / 1000,
        }
        self:MapClickEvent(cc, gameObject);
    end

    if mapCfg and mapCfg.script and mapCfg.script ~= "" and mapCfg.script ~= "0" then
        SGK.LuaBehaviour.Append(self.gameObject, "view/"..mapCfg.script..".lua", arg);
    end
    if activityConfig.GetCityConfig(self.mapId) --[[ and module.GuildSeaElectionModule.GetAll(false, self.mapId) ]] then
        SGK.LuaBehaviour.Append(self.gameObject, "view/guildGrabWar/guildGrabWar.lua", {controller = self.mapController, map_id = self.mapId});
    end
    
    SceneStack.MapId(self.mapId, self.mapType, self.mapRoom)
    
    self:LoadPlayerPosition(arg);
    self:LoadMapNPC();
    utils.EventManager.getInstance():dispatch("MAP_SCENE_READY", SceneStack.CurrentSceneName());
    -- ERROR_LOG("============>>>>","切换到地图"..self.mapId);
    self.IsDOGuide_Frame = true
    self:StartEncounter()
    module.EncounterFightModule.StartCombat()
    module.ChatModule.EnterMapChannel(self.mapId);
    local players = module.TeamModule.MapGetPlayers()
    local oldPlayerPids = {}
    -- ERROR_LOG("========>>>刷新地图玩家",sprinttb(players));
    if  next(players)  then
        for pid,v in pairs(players) do
            if playerModule.GetSelfID() ~= pid then
                oldPlayerPids[#oldPlayerPids+1] = pid
            end
        end
        -- ERROR_LOG("========>>>刷新地图玩家");
        self.EnterMap_succeed = true
        self:RefreshObjects(oldPlayerPids);
    else
        self.EnterMap_succeed = true
    end

    TeamModule.ResumeTeamFight();
end

function View:ParseMapParams(arg)
    self.mapId = (arg and arg.mapid) or self.savedValues.mapId or self.mapController.mapId;

    self.mapType = (arg and arg.mapType) or self.savedValues.mapType or self.mapController.mapType;
    self.mapRoom = (arg and arg.room) or self.savedValues.mapRoom;

    if not self.mapRoom then
        if self.mapType == 1 or self.mapType == 5 then
            self.mapRoom = playerModule.GetSelfID()  -- private map -- TODO: enter team leader map
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

function View:MapClickEvent(point, gameObject)
    -- print("点击---------");
    module.EncounterFightModule.GUIDE.Stop();
    -- save self position
    self:SetPosition(point.x,point.y,point.z)
    -- team leader
    local MovePlayer = function ()
        local teamInfo = TeamModule.GetTeamInfo();
        if self.mapMoveStyle and self.mapMoveStyle ~= 0 then
            self:MovePlayerTo(point.x, point.y, point.z, gameObject);
            module.HuntingModule.IsHunting(true);
            module.worldBossModule.worldBossHunting();
        elseif teamInfo.id <= 0 or playerModule.Get().id == teamInfo.leader.pid or TeamModule.getAFKMembers(playerModule.Get().id) or module.MapModule.GetPlayerStatus(playerModule.Get().id) == 1 then
            self:MovePlayerTo(point.x, point.y, point.z, gameObject);
            module.worldBossModule.worldBossHunting();
            module.HuntingModule.IsHunting(true);
        elseif self.MapClickEventTime < Time.now() then
            self.MapClickEventTime = Time.now()
            showDlgError(nil,"你正在队伍中，无法进行该操作")
        end

        self:CloseTeamGuideTips();
        
    end
    

    if not gameObject or (gameObject and gameObject:GetComponent("MapClickableScript")) then
        -- print("当前不能点击");
        MovePlayer();
        return
    end
    if gameObject then
        if self.Select_Effect then
            self.Select_Effect.outlineSize = 0;
            self.Select_Effect = nil;
        end
        local outline = gameObject:GetComponent(typeof(SGK.SpriteOutline))
        if outline then
            outline.outlineSize = 4;
            self.Select_Effect = outline;
        end
        local npc_script = gameObject:GetComponent("MapInteractableMenu")
        local click_script = gameObject:GetComponent("ModelClickEventListener")
        -- print(">"..gameObject.name)
        local gameObjectView = SGK.UIReference.Setup(gameObject);
        local pid = playerModule.GetSelfID();
        local character = self.mapController:Get(pid) or self.mapController:Add(pid);
        if npc_script and npc_script.LuaTextName ~= "" and npc_script.enabled then
            local gid = npc_script.values.Length >1 and npc_script.values[1] or 0
            local scale = npcScaleConfig.GetNPCScale(tonumber(gid))
            if scale then
                self:ClickPlayer_NPC(gameObject,true);
            else
                self:ClickPlayer_NPC(gameObject)
            end
            
            self.ClickNPCView = gameObjectView
            local characterView = SGK.UIReference.Setup(character)
            characterView[SGK.MapPlayer]:UpdateDirection((gameObject.transform.position-character.transform.position).normalized,true);
            MovePlayer();
        elseif click_script then
            
        else
            character:GetComponent("NavMeshAgent").stoppingDistance = 0
            if self.ClickPlayer_NPC_Effect then
                if utils.SGKTools.GameObject_null(self.ClickPlayer_NPC_Effect) == false then
                    self.ClickPlayer_NPC_Effect:SetActive(false)
                else
                    self.ClickPlayer_NPC_Effect = nil;
                end
            end
            if self.ClickNPCView then
                if utils.SGKTools.GameObject_null(self.ClickNPCView.gameObject) == false then
                    local TypeName = StringSplit(self.ClickNPCView.name,"_")
                    if self.ClickNPCView[SGK.MapPlayer] then
                        --self.ClickNPCView[SGK.MapPlayer]:SetDirection(MapConfig.GetMapMonsterConf(tonumber(TypeName[2])).face_to);
                        self.ClickNPCView[SGK.MapPlayer]:SetDirection(self.ClickNPCView[SGK.MapPlayer].Default_Direction);
                    elseif self.ClickNPCView[SGK.MapMonster] then
                        self.ClickNPCView[SGK.MapMonster].character.transform.localEulerAngles = Vector3(0,(MapConfig.GetMapMonsterConf(tonumber(TypeName[2])).face_to== 0 and 0 or 180),0)
                    end
                end
                self.ClickNPCView = nil
            end
            self:ClickEffetct(point);
            MovePlayer();
        end
        self:LoadPlayerStateEffect(nil)--中断玩家状态特效
    end
    DispatchEvent("Map_Click_Player",nil)
end

function View:ClickPlayer_NPC(parent,status)
    local pid = playerModule.GetSelfID();
    local character = self.mapController:Get(pid) or self.mapController:Add(pid);
    character:GetComponent("NavMeshAgent").stoppingDistance = 0.8
    ------------------------------------------------------------------------------
    if self.ClickPlayer_NPC_Effect == nil or utils.SGKTools.GameObject_null(self.ClickPlayer_NPC_Effect) then
        -- SGK.ResourcesManager.LoadAsync(self.view[SGK.UIReference],"prefabs/effect/UI/fx_xuanren",function (tempObj)
        --      self.ClickPlayer_NPC_Effect = CS.UnityEngine.GameObject.Instantiate(tempObj,parent.gameObject.transform)
        --      self.ClickPlayer_NPC_Effect.transform.localPosition = Vector3.zero
        --     self.ClickPlayer_NPC_Effect:SetActive(true)
        -- end)
        

        local tempObj =  SGK.ResourcesManager.Load("prefabs/effect/UI/fx_xuanren.prefab");
        self.ClickPlayer_NPC_Effect = CS.UnityEngine.GameObject.Instantiate(tempObj,parent.gameObject.transform)
        self.ClickPlayer_NPC_Effect.transform.localPosition = Vector3.zero
    else
        self.ClickPlayer_NPC_Effect.transform.parent = parent.gameObject.transform
        self.ClickPlayer_NPC_Effect.transform.localPosition = Vector3.zero
    end
    self.ClickPlayer_NPC_Effect:SetActive(not status)
end

function View:CloseTeamGuideTips( ... )
    if utils.SGKTools.isTeamLeader() and not self.sync_flag  then
        self.sync_flag = true;
        TeamModule.SyncTeamData(201,{2})
    end
end

function View:StopPlayerMove(pid)
    local teamInfo = TeamModule.GetTeamInfo();
    if teamInfo.id <= 0 or playerModule.Get().id == teamInfo.leader.pid then
        pid = pid or playerModule.GetSelfID()
        local _character = self.mapController:Get(pid) or self.mapController:Add(pid)
        if _character then
            self.view.MapSceneController.MainCamera[CS.CameraClickEventListener]:ResetClick()
            _character:Stop()
            local _pos = _character.gameObject.transform.position
            self:SetPosition(_pos.x, _pos.y, _pos.z)
            self:CloseTeamGuideTips();
        end
    end
end

function View:LoadPlayerStateEffect(data)
    local state = nil;
    -- if data then
        -- state = data.id;
        -- module.guideModule.QuestGuideTipStatus = data
    -- else
        -- module.guideModule.QuestGuideTipStatus = nil
    -- end
    
    -- DispatchEvent("NOTIFY_TEAM_GUIDE_CHANGE",module.guideModule.QuestGuideTipStatus);
    for k,v in pairs(self.Player_State_Effect) do
        v:SetActive(false)
    end
    if state == 1 or state == 2 or state == nil then
        return
    end
    local pid = playerModule.GetSelfID();
    local character = self.mapController:Get(pid) or self.mapController:Add(pid);
    local _characterView = SGK.UIReference.Setup(character)
    if self.Player_State_Effect[state] == nil then
        local EffectName = ""
        if state == 1 then
            EffectName = "fx_xunlu"
        elseif state == 2 then
            EffectName = "fx_xunluo"
        else
            EffectName = state
        end
        local tempObj = SGK.ResourcesManager.Load("prefabs/effect/UI/"..EffectName..".prefab")
        self.Player_State_Effect[state] = CS.UnityEngine.GameObject.Instantiate(tempObj,_characterView.Character.gameObject.transform)
        SGK.ParticleSystemSortingLayer.Set(self.Player_State_Effect[state], 0);
    else
        self.Player_State_Effect[state].transform.parent = _characterView.Character.gameObject.transform
    end
    self.Player_State_Effect[state].transform.localPosition = Vector3(0,1.2,0)
    self.Player_State_Effect[state]:SetActive(true)
end

function View:ClickEffetct(point)
    if self.EffectName == "" then
        return;
    end

    self.EffectArr  = self.EffectArr  or {}
    self.EffectNum  = self.EffectNum  or 0
    self.EffectTime = self.EffectTime or 0;

    if not self.EffectName then
        local mapCfg = MapConfig.GetMapConf(self.mapId);
        self.EffectName = mapCfg and mapCfg.click_texiao or "fx_m_click"
    end

    if self.EffectTime + 1 < math.floor(os.clock()*10) then
        self.EffectTime = math.floor(os.clock()*10)
        self.EffectNum = self.EffectNum + 1
        if #self.EffectArr < 3 then
            local tempObj = SGK.ResourcesManager.Load("prefabs/effect/UI/".. self.EffectName .. ".prefab")
            local obj = CS.UnityEngine.GameObject.Instantiate(tempObj)
            self.EffectArr[self.EffectNum] = obj
        else
            if self.EffectNum > 3 then
                self.EffectNum = 1
            end
        end
        self.EffectArr[self.EffectNum].transform.localPosition = Vector3(point.x,point.y+0.01,point.z)
        self.EffectArr[self.EffectNum]:SetActive(false)
        self.EffectArr[self.EffectNum]:SetActive(true)
    end
end

function View:LoadMapNPC()
    NPCModule.NPC_Reset()--重置NPC数据
    local MapNpcConf = MapConfig.GetMapNpcConf(self.mapId)
    for _, v in ipairs(MapNpcConf or {}) do
       --ERROR_LOG(v.type..">"..v.gid..">"..v.mapid..">"..self.mapId)
        if v.mapid == self.mapId then
            NPCModule.LoadNpcOBJ(v.gid)
        end
    end
    for k,v in pairs(NPCModule.Get_Npc_active_id()) do
        local data = MapConfig.GetMapMonsterConf(k)
        if v and data then
            NPCModule.LoadNpcOBJ(data.gid)
        end
    end

    -- DispatchEvent("LOCAL_MAP_REWADY");
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
        --UnityEngine.PlayerPrefs.HasKey("MapNameID"..module.playerModule.GetSelfID())
        --local map_id = UnityEngine.PlayerPrefs.GetInt("MapNameID"..module.playerModule.GetSelfID())
        --ERROR_LOG(System_Set_data.Mapdata.map_id,self.mapId)
        local _mapid,_x,_y,_z = MapModule.GetiMapid()
        if _mapid and _x and _y and _z and _mapid == self.mapId then
            x = _x
            y = _y
            z = _z
        else
            self:SetPosition(x,y,z)
        end
    end
    --ERROR_LOG(">"..self.mapId)
    self.PlayerPosition = {x=x,y=y,z=z};

    local pid = playerModule.GetSelfID();
    -- print("是否可以进入队长地图",module.TeamModule.CheckEnterMap(self.mapId),self.mapId);
    -- if not module.TeamModule.CheckEnterMap(self.mapId) then
    --     -- showDlgError(nil,"无法传送到队长身边");
    --     -- module.TeamModule.TEAM_AFK_REQUEST();
    --     return;
    -- end
    --TeamModule.mapResetPlayers()
    TeamModule.MapMoveTo(x, y, z, self.mapId, self.mapType, self.mapRoom, self.mapMoveStyle)
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
    self.mapController:ResetCamera();

    local teamInfo = module.TeamModule.GetTeamInfo();
    if teamInfo and teamInfo.id > 0 then
        -- self:FollowQueue(self:TeamDatePro(),x,y,z) 
        if playerModule.GetSelfID() ~= teamInfo.leader.pid then

            -- ERROR_LOG("自己的状态------------->>>>>",teamInfo.afk_list[math.floor(playerModule.GetSelfID())]);

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

function View:StartEncounter()
    local teamInfo = TeamModule.GetTeamInfo();

    local ef = EncounterFightModule.GetFightData(self.savedValues.mapId) or {}
    if next(ef) and (teamInfo.group == 0 or playerModule.Get().id == teamInfo.leader.pid) then
        local EncounterFight_Script = self.view:GetComponent(typeof(CS.SGK.EncounterFight)) or self.view:AddComponent(typeof(CS.SGK.EncounterFight))
        local pid = playerModule.GetSelfID();
        local character = self.mapController:Get(pid) or self.mapController:Add(pid);
        EncounterFight_Script.character = character.character
        EncounterFight_Script.mintime = 3--遇怪间隔
        EncounterFight_Script.probability = 50--初始遇怪几率
        EncounterFight_Script.autoincrement = 0.1--遇怪自增几率
        EncounterFight_Script:RandomRef()
        EncounterFight_Script.onMove = function(state,obj)
            EncounterFightModule.EncounterFight(self.savedValues.mapId)
            local pos = character.gameObject.transform.position;
            character:MoveTo(pos.x, pos.y, pos.z, true);
            self:SetPosition(pos.x, pos.y, pos.z)
            local ef = EncounterFightModule.GetFightData(self.savedValues.mapId) or {}
            if not next(ef) then
                EncounterFight_Script.onMove = nil
            end
        end
    end
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
        -- ERROR_LOG("================",sprinttb(tempArr));
        return tempArr
    end
    return {}
end

function View:FollowQueue(data,x,y,z)
    local teamInfo = TeamModule.GetTeamInfo();
    if self.mapMoveStyle and self.mapMoveStyle ~= 0 then
        return;
    end
    --同步自己的队伍
    if data and #data ~=0 and not self.Lock_PlayerAdd and teamInfo.id == data[3] then

    end

    local mapId = SceneStack.MapId();
    -- ERROR_LOG("++++++",debug.traceback());
    -- ERROR_LOG("队伍跟随信息=========>>>>",sprinttb(data));
    if data and #data ~= 0 and not self.Lock_PlayerAdd and data[3] > 0 and #data[2] > 0 then
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

local mapIDMap = {
    [101] = 1,
    [102] = 1,
}

local function isSameMap(a, b)
    a = mapIDMap[a] or a;
    b = mapIDMap[b] or b;
    return a == b;
end

function View:TeamResetPos(data)
    coroutine.resume( coroutine.create( function ( ... )
        if self.mapMoveStyle and self.mapMoveStyle ~= 0 then
            return;
        end
    
        local teamInfo = TeamModule.GetTeamInfo();
        local pid = module.playerModule.GetSelfID();
        if teamInfo.afk_list[pid] == true then
            return
        end
    
        if not TeamModule.CheckEnterMap(data.mapid) then
            -- print("不能进入该地图",TeamModule.CheckEnterMap(mapid));
            return;
        end
    
        if isSameMap(data.mapid, self.mapId) then --如果和队长在同一张图则同步到队长房间
            if data.mapid == 26 and self.mapRoom ~= data.room then
                SceneStack.TeamEnterMap(data.mapid, data);
            else
                local map_info = MapConfig.GetMapConf(data.mapid);
                if not teamInfo.leader then
                    return;
                end
                local character = self.mapController:Get(teamInfo.leader.pid)
                if character then
                    character:MoveTo(data.x, data.y, data.z,TeamModule.TeamLeaderStatus());
                end
                module.TeamModule.TeamLeaderStatus(true)
                TeamModule.MapMoveTo(data.x, data.y, data.z, self.mapId, self.mapType, data.room)
            end
        else
            SceneStack.TeamEnterMap(data.mapid, data);
        end
    end ) )
end

function View:SetPosition(x,y,z)
    local cfg = MapConfig.GetMapConf(self.mapController.mapId);
    if cfg and cfg.sceneback == 0 then
        MapModule.SetMapid(self.mapId,x,y,z)
    end
end

function View:OnDestroy()
    if self.PlayerPosition then
        local pid = playerModule.GetSelfID()
        local character = self.mapController:Get(pid) or self.mapController:Add(pid);
        local pos = character.gameObject.transform.position;
        self.PlayerPosition = {x=pos.x,y=pos.y,z=pos.z};

        self:SetPosition(self.PlayerPosition.x,self.PlayerPosition.y,self.PlayerPosition.z)
        self.savedValues.pos = {self.PlayerPosition.x,self.PlayerPosition.y,self.PlayerPosition.z}
    end
    DeleteStoryOptions()--切换地图清除任务选项
    UserDefault.Save()
end

function View:MovePlayerTo(x, y, z, gameObject)
    local pid = playerModule.GetSelfID();
    local character = self.mapController:Get(pid);
    if character then
        -- self.PlayerPosition.x = x
        -- self.PlayerPosition.y = y
        -- self.PlayerPosition.z = z

        if character.gameObject == gameObject then
            character:MoveTo(x, y, z)
        else
            character:MoveTo(x, y, z, gameObject)
        end
        self:RecordPlayerMove(x, y, z);
        return true;
    end
end

function View:MovePlayerInteract(gameObject, callback)
    local pid = playerModule.GetSelfID();
    local character = self.mapController:Get(pid);
    if character and gameObject then
        character:GetComponent("NavMeshAgent").stoppingDistance = 0.8
        local pos = character:Interact(gameObject, callback)
        local x, y, z = pos.x, pos.y, pos.z;

        -- self.PlayerPosition.x = x
        -- self.PlayerPosition.y = y
        -- self.PlayerPosition.z = z

        self:RecordPlayerMove(x, y, z);
        return true;
    end
end

function View:CheckGuideNpc()
    if self.IsDOGuide_Frame then
        self.IsDOGuide_Frame = nil
        coroutine.resume(coroutine.create(function()
            local _count = 0
            while _count < 3 do
                local _info = module.EncounterFightModule.GUIDE.GetInteractInfo()
                local character = self.mapController:Get(playerModule.GetSelfID())
                if character then
                    local _mapPlayer = character:GetComponent(typeof(SGK.MapPlayer))
                    if (_info and _info.name) and _mapPlayer then
                        if _mapPlayer.agent.desiredVelocity.magnitude == 0 then
                            self:DOGuide()
                        else
                            return
                        end
                    else
                        return
                    end
                end
                _count = _count + 1
                Sleep(0.2)
            end
        end))
    end
end

function View:Update()
    if self.next_sync_info and self.next_sync_info.time < os.time() then
        if self.next_sync_info.x then
            TeamModule.MapMoveTo(self.next_sync_info.x, self.next_sync_info.y, self.next_sync_info.z);
        end
        self.next_sync_info = { time = os.time() + 3 }
    end

    if self.target then
        if self:MovePlayerTo(self.target.x, self.target.y, self.target.z, self.target.object) then
            self.target = nil;
        end
    end
    self:CheckGuideNpc()
    if #self.Play_pid_list > 0 and self.mapController and not self.Lock_PlayerAdd then
        print("list____",sprinttb(self.Play_pid_list));
        self:Add_Player(self.Play_pid_list[1][1],self.Play_pid_list[1][2],self.Play_pid_list[1][3],self.Play_pid_list[1][4])
        table.remove(self.Play_pid_list,1)
    end
end

function View:listEvent()
    return {
        "MAP_CHARACTER_REFRESH",
        "MAP_CHARACTER_MOVE",
        "MAP_CHARACTER_DISAPPEAR",
        "MAP_SCENE_READY",
        -- "MAP_PROTAL",

        "NAV_PLAYER_INTERACT_DIALOG",
        "NAV_PLAYER_INTERACT_SCENE",
        "NAV_PLAYER_INTERACT_EVENT",
        "NAV_PLAYER_INTERACT_SCRIPT",
        "NAV_PLAYER_INTERACT_TRANSPORT",

        "Add_team_succeed",
        "Leave_team_succeed",
        "TEAM_LEADER_CHANGE",
        "Team_members_Request",
        "MAP_QUERY_PLAYER_INFO_REQUEST",
        "NOTIFY_MAP_SYNC",
        "MAP_CHARACTER_MOVE_Player",--11
        "Reset_EncounterFight", --11
        "TEAM_DATA_SYNC",
        "Click_PLayer_MoveTo",

        "GUIDE_INTERACT",  --11
        "TEAM_INFO_CHANGE",
        "HeroCamera_DOOrthoSize",
        "Map_Click_Player", --11
        "LoadPlayerStateEffect",  --11
        "GetplayerCharacter",  --11
        "PlayerEnterMap",  --11
        "Click_Something",  --11
        "Player_Teleport",
        "LOCAL_MAPSCENE_STOPPLAYER_MOVE",
        "NPC_Follow_Player",
        "RecordPlayerMove",
        "ClearMapPlayer",
        "LockMapClickCreate",
        "Player_Stop_MoveTo",
        "LOCAL_PLAYER_MOVETO_INITIALPOSITIO",
        "NOTIFY_TEAM_GUIDE_CHANGE",
        "QUEST_INFO_CHANGE",
    };
end

function View:onEvent(event, ...)
    -- ERROR_LOG("onEvent", event, ...)
    if event == "MAP_CHARACTER_REFRESH" then
        local data = ...
        self.EnterMap_succeed = true
        -- ERROR_LOG("MAP_CHARACTER_REFRESH---------->>刷新该地图玩家",sprinttb(data))
        self:RefreshObjects(data);
        
    elseif event == "MAP_CHARACTER_MOVE" then
        local pid = select(1, ...)
        -- ERROR_LOG("====MAP_CHARACTER_MOVE======",pid,self.EnterMap_succeed)
        if pid ~= playerModule.GetSelfID() and self.EnterMap_succeed then
            self:MoveTo(...);
        end
    elseif event == "MAP_CHARACTER_MOVE_Player" then
        --脱离卡位用
        local data = ...
        local character = self.mapController:Get(data[1]);
        if character then
            if #data == 1 then
                local pos = character.gameObject.transform.position;
                data[2] = pos.x
                data[3] = pos.y
                data[4] = pos.z
            end

            character:MoveTo(data[2],data[3],data[4], not not data[5]);
            if data[1] == module.playerModule.GetSelfID() then
                TeamModule.MapMoveTo(data[2], data[4], data[3]);
                self:SetPosition(data[2], data[3], data[4])
            end
        end
    elseif event == "LOCAL_PLAYER_MOVETO_INITIALPOSITIO" then
        local _data = ...
        if _data and _data.pid then
            local character = self.mapController:Get(_data.pid)
            if character then
                local conf = MapConfig.GetMapConf(self.mapId)
                if conf then
                    TeamModule.MapMoveTo(conf.initialposition_x, conf.initialposition_y, conf.initialposition_z)
                    character:MoveTo(conf.initialposition_x, conf.initialposition_y, conf.initialposition_z, true)
                    self:SetPosition(conf.initialposition_x, conf.initialposition_y, conf.initialposition_z)
                end
            end
        end
    elseif event == "MAP_CHARACTER_DISAPPEAR" then
        local data = ...

        -- ERROR_LOG("释放离开地图玩家",data);
        self:RemoveObject(math.floor(data))
        self:FollowQueue(self:TeamDatePro()) 
    elseif event == "NAV_PLAYER_INTERACT_DIALOG" then
        DialogStack.Push(...);
    elseif event == "NAV_PLAYER_INTERACT_SCENE" then

        -- ERROR_LOG("SceneStack.Push(...)");
        SceneStack.Push(...)
    elseif event == "NAV_PLAYER_INTERACT_TRANSPORT" then
        
        print("NAV_PLAYER_INTERACT_TRANSPORT",(...));
        local data = ...
        coroutine.resume( coroutine.create( function (  )
            SceneStack.TeamEnterMap(data)
        end ) )
    elseif event == "NAV_PLAYER_INTERACT_EVENT" then
        DispatchEvent(...)
    elseif event == "NAV_PLAYER_INTERACT_SCRIPT" then
        -- TODO:
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
                self:NPC_Follow_Player(module.NPCModule.FollowNPCidChange(),true)
            end
        end

        -- self:RefreshObjects();
    elseif event == "TEAM_LEADER_CHANGE" then
       --队长变化
       -- ERROR_LOG("重新排队",event)

        -- ERROR_LOG("重新排队",event)
        self:FollowQueue(self:TeamDatePro())
        self:StartEncounter();
    elseif event =="TEAM_INFO_CHANGE" then
        -- ERROR_LOG(event,"----------->>>>",sprinttb(self:TeamDatePro()));
        self:FollowQueue(self:TeamDatePro())

    elseif event == "Leave_team_succeed" then
        --离开队伍
        local data = ...
        --print("->>>>>>>>>>>>>>>Leave_team_succeed"..data.pid)
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
            local teamInfo = TeamModule.GetTeamInfo()
            if teamInfo.leader and playerModule.Get().id == teamInfo.leader.pid then
                --队长想地图中其他人发送重新编队信息
                -- NetworkService.Send(18046, {nil,{1,data.pid,teamInfo.id,self:TeamDatePro()}})--队伍有人离开后的队伍pid组
            end
            self:FollowQueue(self:TeamDatePro())--队伍中vi 有人离开，队伍重新编队
            self:NPC_Follow_Player(module.NPCModule.FollowNPCidChange(),true)
            if self.mapType ~= 2  then
                self:RemoveObject(data.pid,true)--清除人物
            end
            local Shielding = module.MapModule.GetShielding()
            if Shielding then
                DispatchEvent("PLayer_Shielding",{pid = data.pid,x = 0})
            end
        else
            -- print(sprinttb(module.CemeteryModule.GetTEAM_PveStateUid()));
            for k,v in pairs(module.CemeteryModule.GetTEAM_PveStateUid())do
                 module.QuestModule.Cancel(v)
            end
            module.QuestModule.SetOldUuid(nil)
            local team_id = TeamModule.GetMapPlayerTeam(data.pid)
            local list = module.TeamModule.GetMapLeaveTeam(team_id,data.pid)

            if self.mapType == 1 then
                local map_list = TeamModule.GetMapTeam()--拿到地图上所有队伍数据
                -- ERROR_LOG(sprinttb(map_list))
                -- for k,v in pairs(map_list) do
                --     for i = 1,#v[2] do
                --         self:RemoveObject(v[2][i],true)--清除人物
                --     end
                -- end
            end

            local character = self.mapController:Get(data.pid) or self.mapController:Add(data.pid);

            local FollowMovement3d = character.gameObject:GetComponent("FollowMovement3d")
            if FollowMovement3d then
                FollowMovement3d:Reset()
                FollowMovement3d.enabled = false
            end

            if self.mapId == 1 then
                if math.floor(self.mapRoom) ~= math.floor( playerModule.Get().id ) then
                    SceneStack.EnterMap(1);
                end

               TeamModule.SetMapTeam() 
            end

            -- ERROR_LOG("自己离队==============",sprinttb(list));
            
            self:FollowQueue(list)--自己离队，原队伍重新编队
            
            -- TeamModule.SetMapTeam()--清除地图所有队伍数据
        end
        self:RefreshObjects();
    elseif event == "Team_members_Request" then
        --队伍中的队员数据查询返回
        local data = ...
        -- ERROR_LOG("玩家组队信息查询返回---->>>",sprinttb(data));
        self:FollowQueue(data.members)
    elseif event == "MAP_QUERY_PLAYER_INFO_REQUEST" then
        --查询目标玩家地图位置信息请求
        local data = select(1, ...);
        -- print("查询目标玩家地图位置信息请求",sprinttb(data));
        -- local ret = TeamModule.CheckEnterMap(data.mapid);
        self:TeamResetPos(data)
    elseif event == "TEAM_DATA_SYNC" then
        --type100队长切换地图
        local pid,Type,value = ...
        if Type == 100 and #value > 0 then
            local mapId   = value[1];
            local mapType = value[2];
            local mapRoom = value[3];
            if mapId ~= self.mapId or mapType ~= self.mapType or mapRoom ~= self.mapRoom then
                local teamInfo = TeamModule.GetTeamInfo()
                if teamInfo.group ~= 0 and playerModule.GetSelfID() ~= teamInfo.leader.pid and not(teamInfo.afk_list[playerModule.GetSelfID()]) then
                    coroutine.resume( coroutine.create( function ( ... )
                        SceneStack.TeamEnterMap(mapId, {mapType = mapType, room = mapRoom});
                    end ) )
                end
            end
        elseif Type == 101 or Type == 102 then--队员更换名字or形象
            --playerModule.Get(pid,nil,true)
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
            self.Lock_TeamMove = true
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
    elseif event == "NOTIFY_MAP_SYNC" then
        --地图炮通知
        local data = ...
        -- ERROR_LOG("NOTIFY_MAP_SYNC_------------------->",sprinttb(data))
        local Type = data.TeamMap[1]
        data = data.TeamMap[2]
        --1type 2pid 3teamID 4teamGroupid
        local teamInfo = TeamModule.GetTeamInfo()
        if Type == 1 and math.floor(teamInfo.id) ~= math.floor(data[3]) and data[3] > 0 then--队伍变化了
            for i = 1,#data[2] do
                if data[2][i] == playerModule.Get().id then
                    return
                end
            end
            local list = TeamModule.GetLeavePids(data)

            -- ERROR_LOG("离队的pid",sprinttb(list));
            for k,v in pairs(list) do
                if v == false then
                    self:RemoveObject(k,true)--清除人物
                    local character = self.mapController:Get(k)
                    if character then
                        local FollowMovement3d = character.gameObject:GetComponent("FollowMovement3d")
                        if FollowMovement3d then
                            FollowMovement3d:Reset()
                            FollowMovement3d.enabled = false
                        end
                        local leaderView = SGK.UIReference.Setup(character.gameObject);
                        leaderView.Character.Label.leader:SetActive(false)
                    end
                end
            end
            -- self:FollowQueue(data)
        elseif Type == 2 then
            --地图有人离队
            -- ERROR_LOG(data.."离队---------->>>");
            local character = self.mapController:Get(math.floor(data))
            if character then
                local NavMeshAgent = character.gameObject:GetComponent("NavMeshAgent")
                local FollowMovement3d = character.gameObject:GetComponent("FollowMovement3d")
                if FollowMovement3d then
                    FollowMovement3d:Reset()
                    FollowMovement3d.enabled = false
                end
                local leaderView = SGK.UIReference.Setup(character.gameObject);
                leaderView.Character.Label.leader:SetActive(false)
                NavMeshAgent.enabled = true
                character.enabled = true;
            end
        elseif Type == 3 then--地图上某人的装扮变化
        elseif Type == 4 then--地图上某人头像、边框或称号变化
        elseif Type == 5 then--地图上某人状态变化(战斗,挖矿...)
        elseif Type == 6 then--地图上某人状态变化(队伍中自由移动)
        end
    elseif event == "Reset_EncounterFight" then
        --重新激活暗雷
        self:StartEncounter()
    elseif event == "Click_PLayer_MoveTo" then--点击玩家，移动至玩家所在位置
        self:MoveTo(...)
    elseif event == "GUIDE_INTERACT" then
        self:DOGuide(...);
    elseif event == "HeroCamera_DOOrthoSize" then
        if ... then
            self.view.MapSceneController.MainCamera[UnityEngine.Camera]:DOOrthoSize(4,0.5)
        else
            local mapCfg = MapConfig.GetMapConf(self.mapId);
            -- camera_size
            self.view.MapSceneController.MainCamera[UnityEngine.Camera]:DOOrthoSize(mapCfg.camera_size,0.5)
        end
    elseif event == "Map_Click_Player" then
        --玩家脚下播放圆环
        if ... then
            local character = self.mapController:Get(...) or self.mapController:Add(...);
             local characterView = SGK.UIReference.Setup(character.gameObject);
            self:ClickPlayer_NPC(characterView.Character)
        end
    elseif event == "LoadPlayerStateEffect" then
        --玩家头顶特效
        self:LoadPlayerStateEffect(...)
    elseif event == "GetplayerCharacter" then

        -- ERROR_LOG(event);
        local character = self.mapController:Get(playerModule.GetSelfID()) or self.mapController:Add(playerModule.GetSelfID());
        local characterView = SGK.UIReference.Setup(character.gameObject);
        local id,desc,fun,type,time = ...
        ShowNpcDesc(characterView.Character.Label.dialogue,desc,fun,type,time)
    elseif event == "PlayerEnterMap" then
        local mapId = SceneStack.MapId();
        --判断
        local flag = nil;
        for k,v in pairs(TipScene) do
            if v == mapId then
                flag = true;
            end
        end
        local data = ...

        if not TeamModule.CheckEnterMap(data) then
            showDlgError(nil,"进不了队长的地图");
            return;
        end
        if flag == true then

            -- ERROR_LOG("获取传送数据",data);
            showDlgMsg("现在退出场景将离开队伍", function ()
                module.TeamModule.KickTeamMember()--解散队伍
                if module.TeamModule.GetTeamInfo().id <= 0 then
                    utils.SGKTools.PLayerConceal(true)
                else
                    utils.SGKTools.TeamConceal(true)
                end
                if self.characterEffect == nil then
                    SGK.ResourcesManager.LoadAsync(self.view[SGK.UIReference],"prefabs/effect/UI/fx_chuan_ren.prefab",function (temp)
                        self.characterEffect = GetUIParent(temp,characterView)
                        self.characterEffect.transform.localPosition = Vector3.zero
                    end)
                else
                    self.characterEffect:SetActive(false)
                    self.characterEffect:SetActive(true)
                    self.characterEffect.transform.localPosition = Vector3.zero
                end
                SGK.Action.DelayTime.Create(0.5):OnComplete(function ()

                    coroutine.resume( coroutine.create( function ( ... )
                        SceneStack.TeamEnterMap(data);
                    end ) )
                end)
            end, function ()
                end, "确定", "返回", nil, nil)
        else

            -- ERROR_LOG("PlayerEnterMap");
            local teamInfo = module.TeamModule.GetTeamInfo()
            local pid = module.playerModule.GetSelfID()
            if teamInfo.id <= 0 or teamInfo.afk_list[pid] then
                utils.SGKTools.PLayerConceal(true)
            else
                utils.SGKTools.TeamConceal(true)
            end
            if self.characterEffect == nil then
                SGK.ResourcesManager.LoadAsync(self.view[SGK.UIReference],"prefabs/effect/UI/fx_chuan_ren.prefab",function (temp)
                    self.characterEffect = GetUIParent(temp,characterView)
                    self.characterEffect.transform.localPosition = Vector3.zeroy
                end)
            else
                self.characterEffect:SetActive(false)
                self.characterEffect:SetActive(true)
                self.characterEffect.transform.localPosition = Vector3.zero
            end
            SGK.Action.DelayTime.Create(0.5):OnComplete(function ()

                coroutine.resume( function ( ... )
                    SceneStack.TeamEnterMap(data);
                end )
            end)
        end

        -- local pid = playerModule.GetSelfID()
        -- local character = self.mapController:Get(pid) or self.mapController:Add(pid);
        -- local characterView = SGK.UIReference.Setup(character.gameObject);
        -- characterView.Character.transform.localScale = Vector3(0,1,1)

    elseif event == "Click_Something" then
        self:MapClickEvent(...);
        -- local pos,obj = ...;
        -- local teamInfo = TeamModule.GetTeamInfo();
        -- if teamInfo.group == 0 or playerModule.Get().id == teamInfo.leader.pid then
        --     self:MovePlayerTo(pos.x,pos.y,pos.z, obj);
        -- end
    elseif event == "Player_Teleport" then
        local pid = playerModule.GetSelfID()
        local character = self.mapController:Get(pid) or self.mapController:Add(pid);
        local characterView = SGK.UIReference.Setup(character.gameObject);
        if self.characterEffect == nil then
            SGK.ResourcesManager.LoadAsync(self.view[SGK.UIReference],"prefabs/effect/UI/fx_chuan_ren.prefab",function (temp)
                self.characterEffect = GetUIParent(temp,characterView)
                self.characterEffect.transform.localPosition = Vector3.zero
            end)
        else
            self.characterEffect:SetActive(false)
            self.characterEffect:SetActive(true)
            self.characterEffect.transform.localPosition = Vector3.zero
        end
        local func = ...
        characterView.Character.transform:DOScale(Vector3(0,1,1),0.25):OnComplete(function ()
            if func then
                func();
                characterView.Character.transform.localScale = Vector3(1,1,1)
            end
        end):SetDelay(0.25)
    elseif event == "LOCAL_MAPSCENE_STOPPLAYER_MOVE" then
        self:StopPlayerMove()
    elseif event == "NPC_Follow_Player" then
        self:NPC_Follow_Player(...)
    elseif event == "RecordPlayerMove" then
        self.next_sync_info = nil
        if ... then
            self:RecordPlayerMove(...)
            self.next_sync_info.time = 0
        end
    elseif event == "ClearMapPlayer" then
        -- ERROR_LOG("ClearMapPlayer---------------->>>>>>>>");
        self.Lock_PlayerAdd = ...
        if self.Lock_PlayerAdd then
            local map_list = TeamModule.GetMapTeam()--拿到地图上所有队伍数据
            local teamInfo = TeamModule.GetTeamInfo()
            --ERROR_LOG(sprinttb(map_list))
            for k,v in pairs(map_list) do
                for i = 1,#v[2] do
                    if teamInfo.id <= 0 or (teamInfo.id > 0 and v[3] ~= teamInfo.id) then
                        self:RemoveObject(v[2][i],true)--清除地图组队人物
                    end
                end
            end
            for k,v in pairs(module.TeamModule.MapGetPlayers()) do
                 self:RemoveObject(k,true)--清除地图单人人物
            end
            TeamModule.mapResetPlayers()--清除地图单人人物数据
            TeamModule.SetMapTeam()--清除地图所有队伍数据
        end
    elseif event == "LockMapClickCreate" then
        self.Lock_PlayerAdd = ...
        -- utils.SGKTools.LockMapClick(true)--切换地图屏蔽点击
    elseif event == "Player_Stop_MoveTo" then

        -- ERROR_LOG("==========Player_Stop_MoveTo========");
        local pid = playerModule.GetSelfID();
        local character = self.mapController:Get(pid)
        if character then
            local pos = character.gameObject.transform.position;
            character:MoveTo(pos.x, pos.y, pos.z, true);
            self:SetPosition(pos.x, pos.y, pos.z)
            --  DispatchEvent("LOCAL_QUESTGUIDETIP", nil)
            -- ERROR_LOG("===========>>>");
            self:CloseTeamGuideTips();
        end
    elseif event == "NOTIFY_TEAM_GUIDE_CHANGE" then
        local data = ...
        DispatchEvent("LOCAL_QUESTGUIDETIP", data)

    elseif event == "QUEST_INFO_CHANGE" then
        local data = ...
        if data then

            local cfg = module.QuestModule.GetCfg(data.id);
            if cfg then
                if cfg.npc_id and tonumber(cfg.npc_id) ~=0 then
                    module.NPCModule.Ref_NPC_LuaCondition(cfg.npc_id);
                end
            end
        end
    -- elseif event == "MAP_SCENE_READY" then

    --     self:LoadMapNPC();
    end
end
function View:NPC_Follow_Player(id,_type)
    local npc_obj = module.NPCModule.GetNPCALL(id)
    if not npc_obj then
        return
    end
    if _type then
        module.NPCModule.FollowNPCidChange(id)
        local list = self:TeamDatePro()
        local FollowMovement3d = npc_obj.gameObject:GetComponent("FollowMovement3d")
        if not FollowMovement3d then
            FollowMovement3d = npc_obj.gameObject:AddComponent(typeof(CS.SGK.FollowMovement3d))
        end
        --ERROR_LOG(id..sprinttb(list))
        if #list > 0 then
            local character = self.mapController:Get(list[2][#list[2]]) or self.mapController:Add(list[2][#list[2]]);
            FollowMovement3d.TargetTF = character.gameObject.transform
        else
            local character = self.mapController:Get(playerModule.GetSelfID()) or self.mapController:Add(playerModule.GetSelfID());
            FollowMovement3d.TargetTF = character.gameObject.transform
        end
    else
        module.NPCModule.FollowNPCidChange(0)
        local FollowMovement3d = npc_obj.gameObject:GetComponent("FollowMovement3d")
        if FollowMovement3d then
            FollowMovement3d:Reset()
            FollowMovement3d.enabled = false
        end
    end
end

function View:MoveTo(pid, x, y, z)
    local teamInfo = TeamModule.GetTeamInfo()
    if self.Lock_TeamMove and teamInfo.id > 0 and teamInfo.leader.pid == pid then
        return
    end
    local character = self.mapController:Get(pid)
    if character and character.gameObject:GetComponent("NavMeshAgent").enabled == true then
        local _x,_y,_z = self:PlayerOverlap(pid,x, y, z)
        
        character:MoveTo(_x, _y, _z);
    else
        self.Play_pid_list[#self.Play_pid_list+1] = {pid, x, y, z}
    end
end

function View:Add_Player(pid, x, y, z)
    local Shielding = module.MapModule.GetShielding()
    local character = self.mapController:Get(pid) or self.mapController:Add(pid);
    local _x,_y,_z = self:PlayerOverlap(pid,x, y, z)
    character:MoveTo(_x, _y, _z, true);
    character:GetComponent("NavMeshAgent").stoppingDistance = 0
    -- ERROR_LOG("!",pid)
    module.TeamModule.GetPlayerTeam(pid,true)--查询玩家队伍信息
end
function View:PlayerOverlap(pid,x,y,z)

    -- print("MapPlayerPos_list",sprinttb(self.MapPlayerPos_list));
    local _x,_y,_z = x,y,z
    for k,v in pairs(self.MapPlayerPos_list)do
        if v.x == x and v.z == z then
            _z = _z + 0.1
            break
        end
    end
    self.MapPlayerPos_list[pid] = {x=_x,y=_y,z=_z}
    return _x,_y,_z
end
function View:RecordPlayerMove(x, y, z)
    if not self.next_sync_info then
        TeamModule.MapMoveTo(x, y, z);
        self.next_sync_info = { time = os.time() + 3 }
    else
        self.next_sync_info.x = x;
        self.next_sync_info.y = y;
        self.next_sync_info.z = z;
    end
end

function View:RemoveObject(pid,status)
    -- ERROR_LOG("移除 玩家 ",pid,playerModule.GetSelfID());
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
        -- ERROR_LOG("删除玩家------>>>",pid);
        self.mapController:Remove(pid);
        ModuleMgr.Get().MapPlayerModule:Remove(pid)
    end
end

function View:RefreshObjects(oldPlayerPids)

    -- print("玩家信息_____",sprinttb(oldPlayerPids));
    self.characters = oldPlayerPids or {};
    local players = TeamModule.MapGetPlayers();
    ERROR_LOG("获取当前地图所有玩家",sprinttb(players));

    --获取到所有队伍玩家
    for i = 1,#self.characters do
        local pid = self.characters[i]

        --如果地图上没有该玩家的数据
        if not players[pid] then
            local teamid = TeamModule.GetMapPlayerTeam(pid)

            ERROR_LOG("--------地图上玩家的队伍id",teamid);
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

    for pid, pos in pairs(players) do
        if pid ~= playerModule.GetSelfID() then
            local character = self.mapController:Get(pid)
            
            if character then
                local dist = UnityEngine.Vector3.Distance( UnityEngine.Vector3(pos.x,pos.y,pos.z), character.transform.position)
                if dist >0.1 then
                    self:MoveTo(pid, pos.x, pos.y, pos.z);
                end
            else
                self:MoveTo(pid, pos.x, pos.y, pos.z);
            end

        end
    end
    -- ERROR_LOG(sprinttb(ModuleMgr.Get().MapPlayerModule.data))
end

function View:DOGuide(info)
    -- print("DOGuide", info and info.name);
    info = info or module.EncounterFightModule.GUIDE.GetInteractInfo()
    local gameObjectView = nil
    if info then
        -- ERROR_LOG("==========",sprinttb(info))
        local TypeName = StringSplit(info.name,"_")
        if TypeName[1] == "NPC" then
            gameObjectView = module.NPCModule.GetNPCALL(tonumber(TypeName[2]))

            if gameObjectView and gameObjectView[SGK.MapInteractableMenu] and gameObjectView[SGK.MapInteractableMenu].LuaTextName ~= "" then--and gameObjectView.Root and gameObjectView.Root.spine and gameObjectView.Root.spine.activeSelf then
                local temp = {id = 1,npcid =TypeName[2]}
                self:LoadPlayerStateEffect(temp)
                -- DispatchEvent("LOCAL_QUESTGUIDETIP", temp )
                -- ERROR_LOG("===========>>>");
                if utils.SGKTools.isTeamLeader() then
                    self.sync_flag = nil;
                    TeamModule.SyncTeamData(201,{1,TypeName[2]})
                end
                if self.ClickNPCView then
                    if self.ClickNPCView[SGK.MapPlayer] then
                        --self.ClickNPCView[SGK.MapPlayer]:SetDirection(MapConfig.GetMapMonsterConf(tonumber(TypeName[2])).face_to);
                        self.ClickNPCView[SGK.MapPlayer]:SetDirection(self.ClickNPCView[SGK.MapPlayer].Default_Direction);
                    elseif self.ClickNPCView[SGK.MapMonster] then
                        self.ClickNPCView[SGK.MapMonster].character.transform.localEulerAngles = Vector3(0,(MapConfig.GetMapMonsterConf(tonumber(TypeName[2])).face_to== 0 and 0 or 180),0)
                    end
                end
                local character = self.mapController:Get(playerModule.GetSelfID())
                if character then
                    local characterView = SGK.UIReference.Setup(character)
                    characterView[SGK.MapPlayer]:UpdateDirection((gameObjectView.transform.position-character.transform.position).normalized,true);
                end
                self.ClickNPCView = gameObjectView
            end
        else
            local temp = {id = 2}
            self:LoadPlayerStateEffect(temp)
            -- ERROR_LOG("===========>>>");
            self:CloseTeamGuideTips();
            -- DispatchEvent("LOCAL_QUESTGUIDETIP", temp)
        end
        --self:MovePlayerInteract((gameObjectView and gameObjectView or info.name), function()
        self:MovePlayerInteract(info.name, function()
            -- ERROR_LOG("===========>>>");
            self:CloseTeamGuideTips();
            self:LoadPlayerStateEffect(nil)--中断玩家状态特效
                -- DispatchEvent("LOCAL_QUESTGUIDETIP")
                
            module.EncounterFightModule.GUIDE.ON_Interact();
        end);
    end
end

return View;
