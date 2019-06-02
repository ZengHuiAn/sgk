local GuildGrabWarModule = require "module.GuildGrabWarModule"
local playerModule = require "module.playerModule"
local Time = require "module.Time"

local View = {};
function View:Start(data)
    self.view = CS.SGK.UIReference.Setup(self.gameObject);
    self.guildGrabWarInfo = GuildGrabWarModule.Get();
    self.pid = playerModule.GetSelfID();
    self.map_id = SceneStack.CurrentSceneID();
    self.updateTime = 0;
    self.rebornTime = 0;
    self:InitData();
    self:InitView();
end

function View:InitData()
    -- self.guildGrabWarInfo:Query();
    self.alive = true;
    self.finish = false;
    self.war_info = self.guildGrabWarInfo:GetWarInfo(); 
    local uninInfo = module.unionModule.Manage:GetSelfUnion();
    if uninInfo then
        if self.war_info.attacker_gid == uninInfo.id then
            self.side = 1;
        elseif self.war_info.defender_gid == uninInfo.id then
            self.side = 2;
        else
            self.side = 0;
        end
    else
        self.side = 0;
    end
end

function View:InitView()
    self.view.report:SetActive(self.side ~= 0);
    self.view.score:SetActive(self.side ~= 0);
    self.view.energy:SetActive(self.side ~= 0);
    CS.UGUIClickEventListener.Get(self.view.apply.gameObject).onClick = function()
        -- self.guildGrabWarInfo:Apply();
        DialogStack.PushPref("guildGrabWar/guildGrabWarFight")
    end
    CS.UGUIClickEventListener.Get(self.view.query.gameObject).onClick = function()
        self.guildGrabWarInfo:Query();
    end
    CS.UGUIClickEventListener.Get(self.view.report.btn.gameObject).onClick = function()
        self.view.report.info:SetActive(not self.view.report.info.activeSelf);
    end
    CS.UGUIPointerEventListener.Get(self.view.energy.gameObject).onPointerDown = function(go, pos)
        self.view.energy.tip:SetActive(true);
    end
    CS.UGUIPointerEventListener.Get(self.view.energy.gameObject).onPointerUp = function(go, pos)
        self.view.energy.tip:SetActive(false);
    end
    for i=2,4 do
        CS.UGUIPointerEventListener.Get(self.view.buff["type"..i].gameObject).onPointerDown = function(go, pos)
            self.view.buff["type"..i].tip:SetActive(true);
        end
        CS.UGUIPointerEventListener.Get(self.view.buff["type"..i].gameObject).onPointerUp = function(go, pos)
            self.view.buff["type"..i].tip:SetActive(false);
        end
    end
    self.view.report.info.rank.me.name[UI.Text].text = playerModule.Get(self.pid).name;
    self.view.report.info.rank.me:SetActive(true);
    self:UpdateWarInfo();
    self:PlayStartEffect();
    self:UpdateSelfInfo(true);
    self:UpdateRank();
    SGK.Action.DelayTime.Create(1):OnComplete(function()
        if not self.finish and self.side ~= 0 then
            DispatchEvent("GUILD_GRABWAR_INIT_MOVE_TIP", self.view.moveTips);
        end
	end) 
end

function View:UpdateWarInfo()
    self.war_info = self.guildGrabWarInfo:GetWarInfo(); 
    if self.war_info.attacker_gid then
        coroutine.resume(coroutine.create(function ()
            local scienceInfo = module.BuildScienceModule.GetScience(self.map_id)
            local attacker_guild = utils.Container("UNION"):Get(self.war_info.attacker_gid);
            self.view.side1.name[UI.Text].text = attacker_guild.unionName;
            self.view.side1.Text[UI.Text].text = "Lv"..attacker_guild.unionLevel;
            self.view.side1.Image3[CS.UGUISpriteSelector].index = scienceInfo.title ~= 0 and 0 or 1;
            self.view.Slider.side1.name[UI.Text].text = attacker_guild.unionName;
            self.view.Slider.side1.Image[CS.UGUISpriteSelector].index = scienceInfo.title ~= 0 and 0 or 1;
            self.view.side2.Image3[CS.UGUISpriteSelector].index = scienceInfo.title ~= 0 and 0 or 1;
            self.view.Slider.side2.Image[CS.UGUISpriteSelector].index = scienceInfo.title ~= 0 and 0 or 1;
        end))
        coroutine.resume(coroutine.create(function ()
            local defender_guild = utils.Container("UNION"):Get(self.war_info.defender_gid);
            self.view.side2.name[UI.Text].text = defender_guild.unionName;
            self.view.side2.Text[UI.Text].text = "Lv"..defender_guild.unionLevel;
            self.view.Slider.side2.name[UI.Text].text = defender_guild.unionName;
        end))
    end
    self:UpdateScore();
end

function View:UpdateSelfInfo(check_energy)
    local player_info = self.guildGrabWarInfo:GetPlayerInfo(self.pid);
    local energy = 3;
    if player_info then
        self.view.score.Text[UI.Text].text = player_info.score;
        for i,v in ipairs(self.view.buff) do
            v:SetActive(false);
        end
        for k,v in pairs(player_info.buffs) do
            if self.view.buff["type"..v.type] then
                self.view.buff["type"..v.type]:SetActive(true);
            end
        end

        print("玩家状态", sprinttb(player_info))
        self.rebornTime = player_info.next_time_to_born;
        -- ERROR_LOG("连胜", player_info.win_count, player_info.next_time_to_born - Time.now())
        if player_info.next_time_to_born - Time.now() > 0 then
            energy = 0;
            self.view.energy.Text[UI.Text].text = "回复中";
        else
            if player_info.win_count == 3 then
                energy = 3;
            else
                energy = 3 - player_info.win_count;
            end
            self.view.energy.Text[UI.Text].text = "战斗体力";
        end
        if check_energy then
            if energy == 0 and self.alive then
                self.alive = false;
                showDlgError(nil, SGK.Localize:getInstance():getValue("shuxingqiu09"))
            elseif energy ~= 0 and not self.alive then
                self.alive = true;
            end
        end
    else
        self.view.score.Text[UI.Text].text = 0;
    end
    for i=1,3 do
        self.view.energy["slot"..i][CS.UGUISpriteSelector].index = energy >= i and 1 or 0;
    end
end

function View:UpdatePlayerStatus()
    local player_info = self.guildGrabWarInfo:GetPlayerInfo(self.pid);
    print("玩家状态", sprinttb(player_info))
end
function View:OnApplicationPause(status)
    if not status then
        self:UpdateSelfInfo(true);
    end
end
function View:PlayStartEffect()
    self.view.title[UnityEngine.CanvasGroup]:DOFade(1,0.2);
    self.view.side1[UnityEngine.CanvasGroup]:DOFade(1,0.2);
    self.view.side2[UnityEngine.CanvasGroup]:DOFade(1,0.2);
    self.view.vs[UI.Image]:DOFade(1,0.2):OnComplete(function ()
        self.view.side1[CS.DG.Tweening.DOTweenAnimation]:DOPlay();
        self.view.side2[CS.DG.Tweening.DOTweenAnimation]:DOPlay();
        self.view.vs[UI.Image]:DOFade(0,0.5):SetDelay(1);
        self.view.title.transform:DOLocalMove(Vector3(0, self.view.Slider.transform.localPosition.y + 70, 0), 0.5):SetDelay(1):OnComplete(function ()
            self.view.Slider[UnityEngine.CanvasGroup]:DOFade(1,0.2);
            self.view.title.time[UnityEngine.CanvasGroup]:DOFade(1,0.2);
            self.view.score[UnityEngine.CanvasGroup]:DOFade(1,0.2);
            self.view.report[UnityEngine.CanvasGroup]:DOFade(1,0.2);
            self.view.energy[UnityEngine.CanvasGroup]:DOFade(1,0.2);
            self.view.buff[UnityEngine.CanvasGroup]:DOFade(1,0.2);
            self.view.moveTips[UnityEngine.CanvasGroup]:DOFade(1,0.2);
        end)
    end);
end

function View:UpdateScore(data)
    local attacker_score = self.war_info.attacker_score or 0;
    local defender_score = self.war_info.defender_score or 0;
    self.view.Slider.side1.score[UI.Text].text = attacker_score;
    self.view.Slider.side2.score[UI.Text].text = defender_score;
    if attacker_score == 0 and defender_score == 0 then
        self.view.Slider[UI.Slider].value = 0.5;
    else
        self.view.Slider[UI.Slider].value = attacker_score/(attacker_score + defender_score);
    end
    if data then
        if self.view.Slider["side"..data.side] and data.score > 0 then
            self.view.Slider["side"..data.side].add[UI.Text].text = "+"..data.score;
            local obj = CS.UnityEngine.GameObject.Instantiate(self.view.Slider["side"..data.side].add.gameObject, self.view.Slider["side"..data.side].transform);
            obj:SetActive(true);
            obj.transform:DOLocalMove(Vector3(0,50,0),0.8):SetRelative(true);
            obj:GetComponent(typeof(CS.UnityEngine.CanvasGroup)):DOFade(0, 0.6):SetDelay(0.2):OnComplete(function ()
                UnityEngine.GameObject.Destroy(obj);
            end)
        end
    end
end

function View:UpdateRank()
    local player_info = self.guildGrabWarInfo:GetPlayerInfo();
    local selfUnion = {};
    for k,v in pairs(player_info) do
        local side = v.is_attacker == 1 and 1 or 2;
        if side == self.side then
            local info = {};
            info.pid = v.pid;
            info.score = v.score;
            table.insert(selfUnion, info);
        end
    end
    table.sort(selfUnion, function ( a,b )
        if a.score ~= b.score then
            return a.score > b.score;
        end
        return a.pid < b.pid;
    end)
    
    local selfInfo = self.guildGrabWarInfo:GetPlayerInfo(self.pid);
    self.view.report.info.rank.me.score[UI.Text].text = (selfInfo and selfInfo.score or 0).."分" ;
    for i=1,3 do
        if selfUnion[i] then
            playerModule.Get(selfUnion[i].pid, function (player)
                self.view.report.info.rank["item"..i].name[UI.Text].text = player.name;
            end)
            self.view.report.info.rank["item"..i].score[UI.Text].text = selfUnion[i].score.."分"
            self.view.report.info.rank["item"..i]:SetActive(true);
        else
            self.view.report.info.rank["item"..i]:SetActive(false);
        end
    end
end

function View:InsertLog(type, data)
    if type == 1 then
        if data.attacker_pid ~= self.pid and data.defender_pid ~= self.pid then
            return;
        end
        local target = data.attacker_pid == self.pid and data.defender_pid or data.attacker_pid;
        local content = self.view.report.info.ScrollView.Viewport.Content;
        playerModule.Get(target, function (player)
            local obj = CS.UnityEngine.GameObject.Instantiate(content.info.gameObject, content.transform);
            local view = CS.SGK.UIReference.Setup(obj);
            view[UI.Text]:TextFormat("{0} VS {1}", playerModule.Get().name, player.name);
            view.result[CS.UGUISpriteSelector].index = data.winner == self.pid and 0 or 1;
            view.result:SetActive(true);
            view.vedio:SetActive(true);
            obj.transform:SetSiblingIndex(1);
            obj:SetActive(true);
        end)
    end
end

function View:ShowLog(data)
    local target = data.attacker_pid == self.pid and data.defender_pid or data.attacker_pid;
    playerModule.Get(target, function (player)
        local result = data.winner == self.pid and "获得了胜利！" or "结果失败了。"
        self.view.report.log.Text[UI.Text]:TextFormat("你对{0}发起挑战，{1}", player.name, result);
    end)
    if self.view.report.log[UnityEngine.CanvasGroup].alpha == 0 then
        self.view.report.log[UnityEngine.CanvasGroup]:DOFade(1, 0.5):OnComplete(function ()
            self.view.report.log[UnityEngine.CanvasGroup]:DOFade(0, 0.5):SetDelay(3);
        end)
    else
        self.view.report.log[UnityEngine.CanvasGroup]:DOKill();
        self.view.report.log[UnityEngine.CanvasGroup].alpha = 1;
        self.view.report.log[UnityEngine.CanvasGroup]:DOFade(0, 0.5):SetDelay(3);
    end
end

function View:Update()
    if Time.now() - self.updateTime >= 1 then
        self.updateTime = Time.now();
        if self.war_info and self.war_info.finish_time then
            local time = self.war_info.finish_time - Time.now();
            if time >= 0 then
                self.view.title.time.num[UI.Text]:TextFormat(GetTimeFormat(time, 2, 2));  
            end
        end
        local rebornTime = self.rebornTime - Time.now();
        if rebornTime > 0 then
            self.view.energy.time[UI.Text]:TextFormat(GetTimeFormat(rebornTime, 2, 2));
            self.view.energy.time:SetActive(true);
        else
            if rebornTime == 0 then
                self:UpdateSelfInfo(true);
            end
            self.view.energy.time:SetActive(false);
        end
    end
end

function View:listEvent()
	return {
        "GUILD_GRABWAR_FIGHT_END",
        "GUILD_GRABWAR_WARINFO_CHANGE",
        "GUILD_GRABWAR_SCORE_CHANGE",
        "GUILD_GRABWAR_FINISH",
        "GUILD_GRABWAR_PLAYERINFO_CHANGE"
	}
end

function View:onEvent(event, ...)
    -- print("onEvent", event, ...);
    local data = ...;
    if event == "GUILD_GRABWAR_FIGHT_START"  then
        -- if data.map_id == self.map_id then
        --     showDlgError(nil, "战斗开始");
        -- end
    elseif event == "GUILD_GRABWAR_FIGHT_END" then
        if data.map_id == self.map_id  and (data.attacker_pid == self.pid or data.defender_pid == self.pid)then
            data.func = function ()
                if not self.finish then
                    DispatchEvent("GUILD_GRABWAR_FIGHT_EFFECT_END");
                    self:InsertLog(1, data);
                    self:ShowLog(data);
                    self:UpdateSelfInfo(true);
                end
            end
            DialogStack.PushPref("guildGrabWar/guildGrabWarFight", data)
        end
    elseif event == "GUILD_GRABWAR_WARINFO_CHANGE" then
        self:UpdateWarInfo();
    elseif event == "GUILD_GRABWAR_SCORE_CHANGE" then
        if data.map_id == self.map_id then
            self.war_info = self.guildGrabWarInfo:GetWarInfo();   
            self:UpdateScore(data);
        end
    elseif event == "GUILD_GRABWAR_FINISH" then
        if data.map_id == self.map_id then
            self.finish = true;
            if self.side ~= 0 then
                local win = false;
                if data ~= 0 then
                    win = module.unionModule.Manage:GetSelfUnion().id == data.winner;
                else
                    win = module.unionModule.Manage:GetSelfUnion().id == self.war_info.defender_gid;
                end
                DialogStack.PushPref("guildGrabWar/guildGrabWarResult", {side = self.side, win = win})
            end
            UnityEngine.GameObject.Destroy(self.gameObject);
        end
    elseif event == "GUILD_GRABWAR_PLAYERINFO_CHANGE" then
        if data.map_id == self.map_id then
            local player_info = data.player_info;
            if player_info.pid == self.pid then
                self:UpdateSelfInfo();
            end
            if player_info and player_info.last_score ~= player_info.score then
                self:UpdateRank();
            end
        end
	end 
end

return View;