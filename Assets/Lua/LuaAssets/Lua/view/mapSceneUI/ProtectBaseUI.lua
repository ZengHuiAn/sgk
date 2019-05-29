local TeamActivityModule = require "module.TeamActivityModule"
local Time = require "module.Time"
local View = {};
local reward = {};
reward[1] = {type = 41, id = 90002, value = 500};
reward[2] = {type = 41, id = 90010, value = 1};
reward[3] = {type = 41, id = 90016, value = 5};

function View:Start(data)
	self.view = CS.SGK.UIReference.Setup(self.gameObject);
	self:InitData();
    self:InitView();
    self:UpdateView()
end

function View:InitData()
    self.updateTime = Time.now();
    self.leaveTime = -1;
    self.cur_health = 0;
    self.finish = false;
    self.bombCount = {0,0,0};
end

function View:EnterMap()
    SceneStack.EnterMap(10,{pos = {3.91,-0.02,5.33}});
end

function View:InitView()
    if utils.SGKTools.isTeamLeader() then
        self.view.health.info[CS.UnityEngine.RectTransform]:SetSizeWithCurrentAnchors(UnityEngine.RectTransform.Axis.Vertical,192);
    else
        self.view.health.info[CS.UnityEngine.RectTransform]:SetSizeWithCurrentAnchors(UnityEngine.RectTransform.Axis.Vertical,128);
    end
    self.view.health.info.out:SetActive(utils.SGKTools.isTeamLeader());
    CS.UGUIClickEventListener.Get(self.view.leave.gameObject).onClick = function ( object )
       self:EnterMap()
    end
    CS.UGUIClickEventListener.Get(self.view.help.gameObject).onClick = function ( object )
        utils.SGKTools.ShowDlgHelp(SGK.Localize:getInstance():getValue("protect_base_info"))
    end
    CS.UGUIClickEventListener.Get(self.view.goout.confirm.gameObject).onClick = function ( object )
        if utils.SGKTools.isTeamLeader() then
            TeamActivityModule.Interact(2, 1, 3);
            self:EnterMap()
        end
    end
    CS.UGUIClickEventListener.Get(self.view.reward_btn.gameObject).onClick = function ( object )
        self.view.reward:SetActive(true);
    end
    CS.UGUIClickEventListener.Get(self.view.health.info.out.gameObject).onClick = function ( object )
        if self.finish then
            self:EnterMap()
        else
            self.view.goout:SetActive(true);
        end
    end
    for i=1,3 do
        local cfg = utils.ItemHelper.Get(reward[i].type, reward[i].id)
        if cfg then
            utils.IconFrameHelper.Create(self.view.reward.items["item"..i].IconFrame,{type = reward[i].type, id = reward[i].id, count = reward[i].value, showDetail = true})
            self.view.reward.items["item"..i].Text[UnityEngine.UI.Text].text = cfg.name;
        else
            self.view.reward.items["item"..i]:SetActive(false);
        end
    end
    self.view.time[UnityEngine.UI.Toggle].onValueChanged:AddListener(function (value)
        self.view.time[UnityEngine.UI.Toggle].interactable = false;
        if value then
            self.view.time.transform:DOLocalMove(Vector3(-220, 0, 0), 0.2):SetRelative(true);
            self.view.health.transform:DOLocalMove(Vector3(-255, 0, 0), 0.2):SetRelative(true):OnComplete(function ()
                self.view.time[UnityEngine.UI.Toggle].interactable = true;
            end);
        else
            self.view.time.transform:DOLocalMove(Vector3(220, 0, 0), 0.2):SetRelative(true);
            self.view.health.transform:DOLocalMove(Vector3(255, 0, 0), 0.2):SetRelative(true):OnComplete(function ()
                self.view.time[UnityEngine.UI.Toggle].interactable = true;
            end);
        end
    end)
end

function View:UpdateView(change)
    self.battleData = TeamActivityModule.Get(2);
    local BoomCount = 0;
    if self.battleData then
        self.view.time.bg:SetActive(true);
        self.view.leave:SetActive(false);
        self.view.health.info:SetActive(true);
        self.bombCount = {0,0,0};
        for k,v in pairs(self.battleData.npcs) do
            if k ~= 1 and v.dead == 0 and v.id < 9067113 then
                BoomCount = BoomCount + 1
                if v.id >= 9067109 then
                    self.bombCount[3] = self.bombCount[3] + 1;
                elseif v.id >= 9067105 then
                    self.bombCount[2] = self.bombCount[2] + 1;
                else
                    self.bombCount[1] = self.bombCount[1] + 1;
                end
            end
        end
        for i=1,3 do
            local count = self.view.health.info["num"..i];
            count[UnityEngine.UI.Text].text = self.bombCount[i];
        end
        local baseInfo = self.battleData.npcs[1]
        print("防御塔信息",sprinttb(baseInfo))
        if baseInfo then
            self.view.tips.Text2[UnityEngine.UI.Text].text = "";;
            if baseInfo.value[1] <= 200 then
				self.view.fx_UI_suiping:SetActive(true);
				showDlgError(nil,SGK.Localize:getInstance():getValue("protect_base_warning1"))--警告!基地护罩血量降低至200以下!
			elseif baseInfo.value[1] <= 200 then
			    showDlgError(nil,SGK.Localize:getInstance():getValue("protect_base_warning2"))--警告!基地护罩血量降低至100以下!
                self.view.fx_UI_suiping.warn_plane:SetActive(true);
            end
            if change and self.cur_health > baseInfo.value[1] then
                if not self.view.fx_UI_hongping.gameObject.activeSelf then
                    self.view.fx_UI_hongping:SetActive(true);
                end
                self.view.fx_UI_hongping.warn_plane[UnityEngine.ParticleSystem]:Stop();
                self.view.fx_UI_hongping.warn_plane[UnityEngine.ParticleSystem]:Play();
            end
            self.cur_health = baseInfo.value[1];
            self.view.health.num[UnityEngine.UI.Text].text = baseInfo.value[1].."/300";
            self.view.health.Slider[UnityEngine.UI.Slider].value = baseInfo.value[1]/300;
            if baseInfo.value[2] == 1 then
                self.view.tips.Text[UnityEngine.UI.Text].text = SGK.Localize:getInstance():getValue("protect_base_1");--距离第二波炸弹袭击
            elseif baseInfo.value[2] == 2 then
                self.view.tips.Text[UnityEngine.UI.Text].text = SGK.Localize:getInstance():getValue("protect_base_2");--距离第三波炸弹袭击
            elseif baseInfo.value[2] == 3 then
                self.view.tips.Text[UnityEngine.UI.Text].text = SGK.Localize:getInstance():getValue("protect_base_3");--距离最后一波炸弹袭击
            elseif baseInfo.value[2] == 4 then
                self.view.tips.Text[UnityEngine.UI.Text].text = SGK.Localize:getInstance():getValue("julihuodongjieshu");--距离活动结束剩余
            end
            self.view.tips:SetActive(true);
            if Time.now() <= baseInfo.value[3] + baseInfo.value[2] * 300 then
                self.view.tips.num[UnityEngine.UI.Text].text = GetTimeFormat(baseInfo.value[3] + baseInfo.value[2] * 300 - Time.now(), 2, 2);
            else
                if baseInfo.value[2] == 4 then
                    self.view.tips.num[UnityEngine.UI.Text].text = "";
                    self.view.tips.Text[UnityEngine.UI.Text].text = ""
                    self.view.tips.Text2[UnityEngine.UI.Text].text = SGK.Localize:getInstance():getValue("huodongjieshu");--活动已结束，请离开场景！
                else
                    self.view.tips:SetActive(false);
                end
            end
            if Time.now() <= baseInfo.value[3] + 1200 then
                self.view.time.Text[UnityEngine.UI.Text].text = GetTimeFormat(baseInfo.value[3] + 1200 - Time.now(), 2, 2);
            else
                self.view.time.Text[UnityEngine.UI.Text].text = SGK.Localize:getInstance():getValue("yijieshu");--已结束
            end
        end
        if BoomCount == 0 and not self.finish then
            DispatchEvent("BASE_NEXT_WAVE")
        end
    else
        self.view.health.info:SetActive(false);
        self.view.time.bg:SetActive(false);
        self.view.time.Text[UnityEngine.UI.Text].text = "";
        self.view.health.num[UnityEngine.UI.Text].text = "300/300";
        self.view.health.Slider[UnityEngine.UI.Slider].value = 1;
        self.view.tips.num[UnityEngine.UI.Text].text = "";
        self.view.tips.Text[UnityEngine.UI.Text].text = "";
        self.view.tips.Text2[UnityEngine.UI.Text].text = SGK.Localize:getInstance():getValue("protect_base_start");--请与双子星巫师对话，开启活动!
    end
end

function View:Update()
    if Time.now() - self.updateTime >= 1 then
        self.updateTime = Time.now();
        if self.finish then
            if self.leaveTime >= 0 then
                self.view.tips.num[UnityEngine.UI.Text].text = "";
                self.view.tips.Text[UnityEngine.UI.Text].text = "";
                self.view.tips.Text2[UnityEngine.UI.Text]:TextFormat("（<color=#FF0000FF>{0}</color>s后自动离开活动场景）", self.leaveTime);
                self.view.goout.Text2[UnityEngine.UI.Text]:TextFormat("（<color=#FF0000FF>{0}</color>s后自动离开活动场景）", self.leaveTime);
                if self.leaveTime == 0 and utils.SGKTools.isTeamLeader() then
                    self:EnterMap()
                end
                self.leaveTime = self.leaveTime - 1;
            end
            if not self.goout then
                self.view.goout:SetActive(true);
                self.goout = true
            end
        else
            if self.battleData then
                local baseInfo = self.battleData.npcs[1];
                if baseInfo then
                    local time = baseInfo.value[3] + baseInfo.value[2] * 300 - Time.now()
                    if time >= 0 then
                        self.view.tips.num[UnityEngine.UI.Text].text = GetTimeFormat(time, 2, 2);
                    end
                    local time2 = baseInfo.value[3] + 1200 - Time.now();
                    if time2 >= 0 then
                        self.view.time.Text[UnityEngine.UI.Text].text = GetTimeFormat(time2, 2, 2);
                    else
                        self.view.time.Text[UnityEngine.UI.Text].text = SGK.Localize:getInstance():getValue("yijieshu");--已结束
                    end
                end
            end
        end

    end
end

function View:OnApplicationPause(status)
    if not status then
        -- self.battleData = TeamActivityModule.Get(2);
        -- if self.battleData then
        --     local baseInfo = self.battleData.npcs[1];
        --     if baseInfo then
        --         local time = baseInfo.value[3] + baseInfo.value[2] * 300 - Time.now()
        --         if time <= 0 and baseInfo.value[2] ~= 4 then
        --             self.view.tips:SetActive(false);
        --         end
        --     else
        --         self.view.tips:SetActive(false);
        --     end
        -- end
        self:UpdateView();
    end
end

function View:listEvent()
	return {
        "BASE_INFO_CHANGE",
        "LEAVE_PROTECT_BASE",
        "TEAM_ACTIVITY_FINISHED",
        "TEAM_ACTIVITY_NPC_CHANGE"
	}
end

function View:onEvent(event, ...)
	-- print("onEvent", event, ...);
	if event == "BASE_INFO_CHANGE" or event == "TEAM_ACTIVITY_NPC_CHANGE" then
        self:UpdateView(true);
    elseif event == "LEAVE_PROTECT_BASE" then
        UnityEngine.GameObject.Destroy(self.gameObject);
    elseif event == "TEAM_ACTIVITY_FINISHED" then
        self.view.tips.Text[UnityEngine.UI.Text].text = ""
        self.view.tips.Text2[UnityEngine.UI.Text].text = SGK.Localize:getInstance():getValue("huodongjieshu");--活动已结束，请离开场景！
        self.view.goout.Text[UI.Text].text = SGK.Localize:getInstance():getValue("huodongjieshu1");--活动已结束，是否离开活动场景
        self.view.time.Text[UnityEngine.UI.Text].text = SGK.Localize:getInstance():getValue("yijieshu");--已结束
        self.leaveTime = 10;
        self.finish = true;
        print("活动结束")
	end
end

return View;