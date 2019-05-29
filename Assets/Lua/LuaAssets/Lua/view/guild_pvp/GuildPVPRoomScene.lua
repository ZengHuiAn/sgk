-- 公会战战斗详情
local GuildPVPRoomModule = require "guild.pvp.module.room"
local GuildPVPGroupModule = require "guild.pvp.module.group"
local Time = require "module.Time"

local LeftLineupPosition = {
    {-0.7,0,-2},

    {-1.5,0,-1},
    {-1.5,0,-2},
    {-1.5,0,-3},

    {-2.3,0,0},
    {-2.3,0,-0.8},
    {-2.3,0,-1.3},
    {-2.3,0,-1.8},
    {-2.3,0,-2.3},
    {-2.3,0,-2.8},
    {-2.3,0,-3.3},
    {-2.3,0,-3.8},
    {-2.3,0,-4.3},
    {-2.3,0,-4.8},

    {-3,0,-0},
    {-3,0,-0.8},
    {-3,0,-1.3},
    {-3,0,-1.8},
    {-3,0,-2.3},
    {-3,0,-2.8},
    {-3,0,-3.3},
    {-3,0,-3.8},
    {-3,0,-4.3},
    {-3,0,-4.8},
}
local RightLineupPosition = {
    {0.7,0,-2},

    {1.5,0,-1},
    {1.5,0,-2},
    {1.5,0,-3},

    {2.3,0,0},
    {2.3,0,-0.5},
    {2.3,0,-1},
    {2.3,0,-1.5},
    {2.3,0,-2},
    {2.3,0,-2.5},
    {2.3,0,-3},
    {2.3,0,-3.5},
    {2.3,0,-4},
    {2.3,0,-4.5},
    
    {3,0,0},
    {3,0,-0.5},
    {3,0,-1},
    {3,0,-1.5},
    {3,0,-2},
    {3,0,-2.5},
    {3,0,-3},
    {3,0,-3.5},
    {3,0,-4},
    {3,0,-4.5},
}

local View = {}

function View:Start(arg)
--    ERROR_LOG("ding------>>>",sprinttb(arg))
    self.RootView = SGK.UIReference.Setup()
    self.view = self.RootView.GuildPVPRoomUI
    self.room = arg and arg.room or self.savedValues.room;
    self.minOrder = arg and arg.minOrder or self.savedValues.minOrder or 0;
    self.status = -1;
    self.start = true;
    self.watching = false;
    self.updateTime = 0;
    self.comboUI = {
        [1] = self.view.Win.gameObject,
        [2] = self.view.Combo1.gameObject,
        [3] = self.view.Combo2.gameObject,
    }
    
    self.MapSceneController = UnityEngine.GameObject.FindObjectOfType(typeof(SGK.MapSceneController));
    CS.UnityEngine.GameObject.Instantiate(SGK.ResourcesManager.Load("prefabs/base/CurrencyChat.prefab"), self.view.transform)
    self.view.logArea.tableView:SetActive(false)
    self.view.logArea[CS.UGUIClickEventListener].onClick = function ( ... )
        self.view.logArea.tableView:SetActive(not self.view.logArea.tableView.activeSelf)
        -- self.view.logArea.tableView[UnityEngine.CanvasGroup].alpha = self.view.logArea.tableView[UnityEngine.CanvasGroup].alpha == 1 and 0 or 1
        local vec3 = self.view.logArea.tableView[UnityEngine.CanvasGroup].alpha ~= 0 and Vector3.zero or Vector3(0,0,180)
        self.view.logArea.btnLarge[1].transform.localEulerAngles = vec3;
    end
    self.view.inspireBtn[CS.UGUIClickEventListener].onClick = function ( ... )
        local guild = module.unionModule.Manage:GetSelfUnion()
        local gs = GuildPVPRoomModule.GetGuild();
        local canInspire = false
        if gs and guild and (guild.id == gs[1].id or guild.id == gs[2].id) then
            canInspire = true;
        end
        if not canInspire then
            return showDlgError(nil,"只有公会所属成员才能鼓舞");
        end
        local status = GuildPVPRoomModule.GetRoomStatus();
        if status ~= GuildPVPRoomModule.ROOM_STATUS_INSPIRE then
            return showDlgError(nil,"还未到鼓舞的时间");
        end
        if GuildPVPRoomModule.isInspired() then
            return showDlgError(nil,"不能重复鼓舞");
        end
        GuildPVPRoomModule.Inspire();
    end
    
    
    -- self:initRoom();
    -- self:FightStart();
    GuildPVPRoomModule.EnterRoom(self.room);
end

function View:listEvent()
    return {
        "GUILD_PVP_ROOM_RECORD_READY",
        "GUILD_INFO_CHANGE",
        "PLAYER_INFO_CHANGE",
        "GUILD_PVP_ROOM_STATUS_CHANGE",
        "GUILD_PVP_ENTER_ROOM_RESULT",
        "GUILD_PVP_INSPIRE_RESULT",
        "GUILD_PVP_ROOM_INSPIRE_CHANGE",
    }
end

function View:UpdateGuildInfo(data)
    local node = {self.view.Title.Left, self.view.Title.Right}
    for i = 1, 2 do
        local guild = GuildPVPRoomModule.GetGuild(i);
        local info = utils.Container("UNION"):Get(guild.id);
        if info then
            node[i].Name[UnityEngine.UI.Text].text = info.unionName;
            node[i].Level[UnityEngine.UI.Text].text = info.unionLevel;
        end
    end
end

function View:onEvent(event, ...)
--    ERROR_LOG("---------->>>",event)
    
    if event == "GUILD_PVP_ROOM_RECORD_READY" then
        self:initRoom();
        self:FightStart();
    elseif event == "GUILD_INFO_CHANGE" then
        self:UpdateGuildInfo(...)
    elseif event == "GUILD_PVP_ROOM_STATUS_CHANGE" then
        self:updateRoomStatus();
    elseif event == "PLAYER_INFO_CHANGE" then
        -- local pid = select(1, ...);
        -- if self.MapSceneController:Get(pid) then
        --     self:UpdatePlayerInfo(pid)
        -- end
    elseif event == "GUILD_PVP_ENTER_ROOM_RESULT" then
        local error = select(1, ...);
        if error ~= 0 then
            cmn.show_tips("@str/guild/pvp/error/enter");
        end
    elseif event == "GUILD_PVP_INSPIRE_RESULT" then
        local success = select(1, ...)
        if success then
            showDlgError(nil,"鼓舞成功");
        else
            showDlgError(nil,"鼓舞失败");
        end
    elseif event == "GUILD_PVP_ROOM_INSPIRE_CHANGE" then
        self:updateInspireValue();
    end
end

function View:updateInspireValue()
    local node = {
        self.view.Title.Left,
        self.view.Title.Right
    }

    for i = 1, 2 do
        local guild = GuildPVPRoomModule.GetGuild(i);
        if guild then
            node[i].Inspire[UnityEngine.UI.Text].text = tostring(guild.inspire);
        end
    end
end

function View:initRoom()
    ERROR_LOG("初始化")
    GuildPVPRoomModule.InitFightRecord();
    self.playersSprite = {};

    local node = {
        self.view.Title.Left,
        self.view.Title.Right
    }

    for i = 1, 2 do
        local guild = GuildPVPRoomModule.GetGuild(i);
        if guild and guild.id then
            local info = utils.Container("UNION"):Get(guild.id);
            if info then
                node[i].Name[UnityEngine.UI.Text].text = info.unionName;
                node[i].Level[UnityEngine.UI.Text].text = "Lv" .. info.unionLevel;
                node[i].Inspire[UnityEngine.UI.Text].text = tostring(guild.inspire);
                node[i].Score[UnityEngine.UI.Text].text = "0分";
            end
        end
    end

    self.logs = nil;
    self.score = {0, 0};

    local player_guild = module.unionModule.Manage:GetSelfUnion() -- GUILD.PlayerGuild();
    local self_id = module.playerModule.GetSelfID();

    for side = 1, 2 do
        local players = GuildPVPRoomModule.GetPlayers(side);

        local target_guild = GuildPVPRoomModule.GetGuild(side);

        for index, v in ipairs(players) do
            if v.pid > 0 then
                local character = self:UpdatePlayerInfo(v.pid);
                
                if side == 1 then
                    character:MoveTo(LeftLineupPosition[index][1],0,LeftLineupPosition[index][3],true)
                else
                    character:MoveTo(RightLineupPosition[index][1],0,RightLineupPosition[index][3],true)
                end
                character:SetDirection((side == 1) and 7 or 1);

                self.playersSprite[v.pid] = {side = side, index = index};
            end
        end
    end

    self:updateRoomStatus();
end

function View:FightStart()
    local delay = self:playToFront();
    self.co = coroutine.create(self.PlayThread);
   -- coroutine.resume(self.co, self, delay)
    assert(coroutine.resume(self.co, self, delay));
end

function View:updateRoomStatus()
    local status = GuildPVPRoomModule.GetRoomStatus();
--    ERROR_LOG("房间状态", status);
    self.view.inspireBtn:SetActive(status == 1);
    self.RootView.inspire:SetActive(status == 1);
    self.RootView.npc:SetActive(status == 1);
    --self.RootView.prepare:SetActive(status <= 1);
    --self.RootView.monster:SetActive(status <= 1);
end


function View:PlayThread(delay)
    print("------------------PlayThread sleep------------------", delay);
    Sleep(delay);

    print("------------------PlayThread start------------------");
    --showDlgError(nil,"拳皇争霸赛现在开始!")
    while true do
        local log = GuildPVPRoomModule.NextFightRecord();
        print("NextFightRecord", sprinttb(log))
        if log == nil then
			Sleep(5)
            break;
        end

        if log.winner ~= nil then
            self:playFight(log);
        end
        Sleep(1);
    end
    print("------------------PlayThread end------------------");
    return self:showResult();
end

function View:UpdatePlayerInfo(pid)
    local character = self.MapSceneController:Get(pid) or self.MapSceneController:Add(pid);
    local characterView = SGK.UIReference.Setup(character.gameObject);

    local player = module.playerModule.Get(pid);
    if not player then
        return character;
    end

    if string.sub(character.gameObject.name, 1, 7) == "player_" then
        return character;
    end

    characterView[SGK.LuaBehaviour].enabled = false;
    character.gameObject.name = "player_" .. player.name;
    characterView.Character.Label.name[UnityEngine.UI.Text].text = player.name;
    characterView.Character.Label.honor:SetActive(false);
    utils.PlayerInfoHelper.GetPlayerAddData(pid, 99, function (_playerAddData)
		local mode = _playerAddData and _playerAddData.ActorShow or 11048;
		local skeletonAnimation = characterView.Character.Sprite[Spine.Unity.SkeletonAnimation];
		SGK.ResourcesManager.LoadAsync(skeletonAnimation, string.format("roles_small/%s/%s_SkeletonData.asset", mode, mode), function(o)
            if o ~= nil then
                
				skeletonAnimation.skeletonDataAsset = o
				skeletonAnimation:Initialize(true);
				characterView.Character.Sprite[SGK.CharacterSprite]:SetDirty()
            else
                
                
				SGK.ResourcesManager.LoadAsync(skeletonAnimation, string.format("roles_small/11000/11000_SkeletonData.asset"), function(o)
					skeletonAnimation.skeletonDataAsset = o
					skeletonAnimation:Initialize(true);
					characterView.Character.Sprite[SGK.CharacterSprite]:SetDirty()
				end);
			end
		end);
    end)
    character.transform.localScale=Vector3(1.4,1.4,1.4)
    return character;
end

function View:playToFront()
    if GuildPVPRoomModule.GetRoomStatus() == GuildPVPRoomModule.ROOM_STATUS_FIGHTING then
        local fight = GuildPVPRoomModule.NextFightRecord();
        while fight and fight.winner and GuildPVPRoomModule.NextFightRecordIsReady() do
            self:skipFight(fight);
            fight = GuildPVPRoomModule.NextFightRecord();
        end

        -- for _, v in ipairs(self.logs or {}) do
        --     v.fmt = "@str/guild/pvp/log_format_2";
        -- end

        if fight and fight.winner then 
            coroutine.resume(coroutine.create(self.playFight), self, fight)
            -- self:playFight(fight);
            return 4;
        else
            return 1;
        end
    end
    return 1;
end

local roomStatusString = {
    "战斗将在<color=#29EB8B>{0}</color>后开始",
    "打call棒领取时间还剩<color=#29EB8B>{0}</color>",
    "战斗中<color=#29EB8B>{0}</color>",
     "距离本场战斗结束还剩<color=#29EB8B>{0}</color>",
     "战斗结束<color=#29EB8B>{0}</color>",
}

function  View:TimeRef(endTime)
    local timeCD = "00:00:00" 
    if endTime then
        local time = endTime
        timeCD = string.format("%02d",math.floor(math.floor(time/60)%60))..":"..string.format("%02d",math.floor(time%60))
    end
    return timeCD
end

function View:Update()
    if Time.now() - self.updateTime >= 1 then
        self.updateTime = Time.now();
        -- if self.co then
        --     print("状态", coroutine.status(self.co))
        -- end
        local status,fight_status = GuildPVPGroupModule.GetStatus();
        local roomStatus = GuildPVPRoomModule.GetRoomStatus();
        local minOrder = GuildPVPGroupModule.GetMinOrder()
        if status == 2 then
            if minOrder == self.minOrder then
                if roomStatusString[roomStatus + 1] then
                    self.view.Title.Status:TextFormat(roomStatusString[roomStatus + 1], self:TimeRef(GuildPVPGroupModule.GetLeftTime()))--.."\n"..roomStatusString[status+1])
                else
                    self.view.Title.Status:TextFormat("");
                end
            elseif minOrder < self.minOrder then
                self.view.Title.Status:TextFormat("");
            else
                self.view.Title.Status:TextFormat("比赛尚未开始");
            end
        else
            self.view.Title.Status[UnityEngine.UI.Text].text = "";
        end
    end
    self.view.Title.Status:SetActive(false)
   self:updateRoomStatus()
end

function View:ShowComboUI(count, pid)
    print("显示", count, pid)
    local character = self.MapSceneController:Get(pid);
    local characterView = SGK.UIReference.Setup(character.gameObject);
    local comboUI = self.comboUI[count];
    comboUI.transform:SetParent(characterView.Character.Label.gameObject.transform, false);
    comboUI.transform.localPosition = Vector3(0,50,0);
    comboUI:SetActive(true);
end

function View:showResult( ... )
    local winner,_idx = GuildPVPRoomModule.GetWinner();
    if winner then
        for _,v in ipairs(self.comboUI) do
            v:SetActive(false);
        end

        local guild = utils.Container("UNION"):Get(winner.id); -- GUILD.GetGuildByGID(winner.id);

        if guild then
            if _idx == 1 then
                self.view.Title.Left.fx_ui_shengli:SetActive(true)
                self.view.Title.Right.fx_ui_shibai:SetActive(true)
                -- self.RootView.LeftWin:SetActive(true)
                self.view.Title.Left.Score:TextFormat(self.view.Title.Left.Score[UI.Text].text.."\n胜利")--("胜利")
                self.view.Title.Right.Score:TextFormat(self.view.Title.Right.Score[UI.Text].text.."\n失败")--("失败")
                self.view.Title.fx_ui_nihongdeng.plane_1:SetActive(true)
            else
                self.view.Title.Left.fx_ui_shibai:SetActive(true)
                self.view.Title.Right.fx_ui_shengli:SetActive(true)
                -- self.RootView.RightWin:SetActive(true)
                self.view.Title.Left.Score:TextFormat(self.view.Title.Left.Score[UI.Text].text.."\n失败")--("失败")
                self.view.Title.Right.Score:TextFormat(self.view.Title.Right.Score[UI.Text].text.."\n胜利")--("胜利")
                self.view.Title.fx_ui_nihongdeng.plane_2:SetActive(true)
            end
            for side = 1, 2 do
                local players = GuildPVPRoomModule.GetPlayers(side);
                local target_guild = GuildPVPRoomModule.GetGuild(side);
                local idx = 0
                if side == _idx then
                    self:ShowComboUI(1, players[1].pid);
                end
                for index, v in ipairs(players) do
                    if v.pid > 0 then
                        idx = idx + 1
                        local character = self:UpdatePlayerInfo(v.pid);
                        if side == 1 then
                            character:MoveTo(Vector3(LeftLineupPosition[idx][1],0,LeftLineupPosition[idx][3]),true);
                        else
                            character:MoveTo(Vector3(RightLineupPosition[idx][1],0,RightLineupPosition[idx][3]),true);
                        end
                        character:SetDirection((side == 1) and 7 or 1);
                    end
                end
            end
            -- showDlg(nil, guild.unionName .. "获得胜利", function()
            --     --SceneStack.Pop(); 
            -- end);
        end
    end
end

-- function View:SkipJumpAndAttack(player, side, win, exit)
--     local sprites = self.playersSprite[player.pid];
--     if sprites.flag then
--         sprites.flag:removeFromParent();
--         sprites.flag = nil;
--         local y = self.view.ground[side]:getPositionY();
--         self.view.ground[side]:setPositionY(y+150);
--     end
-- end

function View:playFight(fight)
    if self.start then
        self.start = false;
        local VSFrame = GetUIParent(SGK.ResourcesManager.Load("prefabs/base/VSFrame.prefab"), self.view.UIRoot)
        SGK.Action.DelayTime.Create(1):OnComplete(function()
            UnityEngine.GameObject.Destroy(VSFrame.gameObject)
        end)
    end

    for pid, v in pairs(self.playersSprite) do
        if v.enter and pid ~= fight.side[1].pid and pid ~= fight.side[2].pid then
            v.enter = nil;
            local character = self.MapSceneController:Get(pid);
            if character then
                character:MoveTo( (v.side==1) and -10 or 10, 0, -2);
            end
		end
	end

    local delay = nil;
    for side = 1, 2 do
        local id = fight.side[side].pid;
        if id > 0 then
            local v = self.playersSprite[id];

            if not v.enter then
                v.enter = true;
                delay = 2
            end

            if not v then
                ERROR_LOG('player', id, 'no found');
            else
                local character = self.MapSceneController:Get(id);
                character:WaitForArrive(function()
                    character:SetDirection((side == 1) and 6 or 2);
                end)
                character:MoveTo((v.side == 1) and -0.1 or 0.1, 0, -2);
            end
        end
    end

    if delay then
        self:insertLog(fight, 0);
        Sleep(delay);
    end

    print('--->', fight.side[1].pid, fight.side[2].pid, fight.winner)
    Sleep(1);

    for side = 1, 2 do
        if fight.side[side].exit then
            if fight.side[side].pid > 0 then
                self.MapSceneController:Get(fight.side[side].pid):MoveTo( (side == 1) and -10 or 10, 0, 0);
                self.playersSprite[fight.side[side].pid].enter = nil;
            end
        end
    end

    if fight.side[1].score then self.view.Title.Left.Score:TextFormat("{0}分", fight.side[1].score) end
    if fight.side[2].score then self.view.Title.Right.Score:TextFormat("{0}分", fight.side[2].score) end

    self:insertLog(fight, 3);
end

function View:skipFight(fight)
    print("跳过", sprinttb(fight))
    -- self:SkipJumpAndAttack(fight.side[1], 1, fight.winner == 1, fight.side[1].exit);
    -- self:SkipJumpAndAttack(fight.side[2], 2, fight.winner ~= 1, fight.side[2].exit);

    for side = 1, 2 do
        if fight.side[side].exit then
            if fight.side[side].pid > 0 then
                self.MapSceneController:Get(fight.side[side].pid):MoveTo(Vector3((side == 1) and -10 or 10, 0, 0), true);
                self.playersSprite[fight.side[side].pid].enter = nil;
            end
        end
    end

    if fight.side[1].score then self.view.Title.Left.Score:TextFormat("{0}分", fight.side[1].score) end
    if fight.side[2].score then self.view.Title.Right.Score:TextFormat("{0}分", fight.side[2].score) end

    self:insertLog(fight, 0);    
end

function View:insertLog(log, delay)
    local tableView = self.view.logArea.tableView;
    if self.logs == nil then
        self.logs = {};
    end

    local p1 = log.side[1].pid;
    local p2 = log.side[2].pid;
    local a1 = module.playerModule.IsDataExist(log.side[1].pid) or {name="..."};
    local a2 = module.playerModule.IsDataExist(log.side[2].pid) or {name="..."};

    for _,v in ipairs(self.comboUI) do
        v:SetActive(false);
    end
    -- local logInfo = {
    --     fight = log.fight,
    --     fmt = ((delay>1) and "@str/guild/pvp/log_format_1" or "@str/guild/pvp/log_format_2"),
    --     p1 = p1,
    --     p2 = p2,
    --     winner = log.winner,
    -- }
    
    -- table.insert(self.logs, 1, logInfo);
    if delay == 0 then
        if a1 and a1.name == "..." then
            -- tableView.Viewport.Content[1].desc[UnityEngine.UI.Text].text = self.view.Title.Left.Name[UnityEngine.UI.Text].text.."盗团派出玩家"..a1.name
            -- local battleReport = CS.UnityEngine.GameObject.Instantiate(tableView.Viewport.Content[1].gameObject, tableView.Viewport.Content.gameObject.transform)
            -- battleReport:SetActive(true)
        end
        if a2 and a2.name == "..." then
            -- tableView.Viewport.Content[1].desc[UnityEngine.UI.Text].text = self.view.Title.Right.Name[UnityEngine.UI.Text].text.."盗团派出玩家"..a2.name
            -- local battleReport = CS.UnityEngine.GameObject.Instantiate(tableView.Viewport.Content[1].gameObject, tableView.Viewport.Content.gameObject.transform)
            -- battleReport:SetActive(true)
        end
        if a1.name ~= "..." and a2.name ~= "..." then
            tableView.Viewport.Content[1][UnityEngine.UI.Text].text = a1.name.."对战"..a2.name
            tableView.Viewport.Content[1].view:SetActive(true);
            local battleReport = CS.UnityEngine.GameObject.Instantiate(tableView.Viewport.Content[1].gameObject, tableView.Viewport.Content.gameObject.transform)
            battleReport:SetActive(true)
            local logUI = SGK.UIReference.Setup(battleReport)
            CS.UGUIClickEventListener.Get(logUI.view.gameObject).onClick = function()              
                if not self.watching then                   
                    print("录像", sprinttb(log))
                    GuildPVPRoomModule.WatchFightReplay(log.fight);
                    self.watching = true;
                end
            end
        end
    elseif log.side[log.winner].now_score then
        tableView.Viewport.Content[1].view:SetActive(false);
        if log.winner == 1 then
            --tableView.Viewport.Content[1][UnityEngine.UI.Text].text = a1.name.."击败"..a2.name.."获得"..log.side[1].now_score.."分"
            if a2.name == "..." then
                tableView.Viewport.Content[1][UnityEngine.UI.Text].text = a1.name.."轮空获胜"
            else
                tableView.Viewport.Content[1][UnityEngine.UI.Text].text = a1.name.."取得胜利"
            end
            self.view.Title.Left.win:SetActive(true)
        else
            --tableView.Viewport.Content[1][UnityEngine.UI.Text].text = a2.name.."击败"..a1.name.."获得"..log.side[2].now_score.."分"
            if a1.name == "..." then
                tableView.Viewport.Content[1][UnityEngine.UI.Text].text = a2.name.."轮空获胜"
            else
                tableView.Viewport.Content[1][UnityEngine.UI.Text].text = a2.name.."取得胜利"
            end
            self.view.Title.Right.win:SetActive(true)
        end
        local battleReport = CS.UnityEngine.GameObject.Instantiate(tableView.Viewport.Content[1].gameObject, tableView.Viewport.Content.gameObject.transform)
        battleReport:SetActive(true)
        SGK.Action.DelayTime.Create(1):OnComplete(function()
            self.view.Title.Left.win:SetActive(false)
            self.view.Title.Right.win:SetActive(false)
        end)
        self:ShowComboUI(log.side[log.winner].winCount, log.side[log.winner].pid)
    else
        tableView.Viewport.Content[1].view:SetActive(false)
        -- local guild_name = log.winner == 1 and self.view.Title.Left.Name[UnityEngine.UI.Text].text or self.view.Title.Right.Name[UnityEngine.UI.Text].text
        -- tableView.Viewport.Content[1][UnityEngine.UI.Text].text = guild_name.."盗团获得胜利"
        local name = log.winner == 1 and a1.name or a2.name;
        tableView.Viewport.Content[1][UnityEngine.UI.Text].text = name.."取得胜利"
        local battleReport = CS.UnityEngine.GameObject.Instantiate(tableView.Viewport.Content[1].gameObject, tableView.Viewport.Content.gameObject.transform)
        battleReport:SetActive(true)
        self:ShowComboUI(log.side[log.winner].winCount, log.side[log.winner].pid)
    end

    self.view.logArea.Image.desc[UnityEngine.UI.Text].text = tableView.Viewport.Content[1][UnityEngine.UI.Text].text
    local height = (tableView.Viewport.Content.transform.childCount - 1) * 42 + 20
    if height > 280 then
        tableView.Viewport.Content[UnityEngine.RectTransform]:DOLocalMove(Vector3(0, height - 280, 0),0.5)
    end
end

function View:OnDestroy()
    self.co = nil;
    self.savedValues.room = self.room;
    self.savedValues.minOrder = self.minOrder;
end

return View;


