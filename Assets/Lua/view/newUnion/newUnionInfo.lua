local unionModule = require "module.unionModule"
local unionConfig = require "config.unionConfig"
local questModule = require "module.QuestModule"
local ItemModule=require"module.ItemModule"
local newUnionInfo = {}

function newUnionInfo:Start()
    self:initData()
    self:initUi()
    
end

function newUnionInfo:initData()
    self.Manage = unionModule.Manage
    unionModule.UpSelfMember(true);
    self.childTab = {
        {dialogName = "newUnion/newUnionActivity", data = {idx = 1},red = module.RedDotModule.Type.Union.Activity},
        {dialogName = "newUnion/newUnionActivity", data = {idx = 2},red = module.RedDotModule.Type.Union.UnionActivity},
    }
    self.indexID=1
end

function newUnionInfo:initUi()
    self.view = CS.SGK.UIReference.Setup(self.gameObject)
    DialogStack.PushPref(self.childTab[1].dialogName, self.childTab[1].data, self.view.childRoot)
    DialogStack.PushPref(self.childTab[2].dialogName, self.childTab[2].data, self.view.childRoot1)
    self:upMemberList()
    self:initTop()
    self:upTop()
    self:initGroup()
    self:ShowActivityType(1)
    self:initBottom()
end


function newUnionInfo:initGroup()
    for i,v in ipairs(self.view.middle.group) do
        v[UI.Toggle].onValueChanged:AddListener(function (value)
           if not value then
               v.text[UI.Text].color={r=1,g=1,b=1,a=1}
           else
               v.text[UI.Text].color={r=0,g=0,b=0,a=1}
           end
        end)
        CS.UGUIClickEventListener.Get(v.gameObject,true).onClick=function ()
            if self.indexID ~= i then
                self:ShowActivityType(i)
            end
        end
    end
end
function newUnionInfo:ShowActivityType(index)
    if index then
        self.indexID=index
    end
    if index==1 then
        self.view.childRoot:SetActive(true)
        self.view.childRoot1:SetActive(false)  
    end
    if index==2 then
        self.view.childRoot:SetActive(false)
        self.view.childRoot1:SetActive(true)
    end
end


function newUnionInfo:freshRedTip( ... )
    -- self.applyLab = unionModule.Manage:GetApply()

    -- local length = 0;
    -- for k,v in pairs(self.applyLab) do
    --     length = length+1;
    -- end
    -- if length == 0 then
        
    --     self.view.middle.bottom.joinBtn.redPoint:SetActive(false);
    -- else

    --     module.RedDotModule.PlayRedAnim(self.view.middle.bottom.joinBtn.redPoint)
    --     self.view.middle.bottom.joinBtn.redPoint:SetActive(true);
    -- end

    -- -- ERROR_LOG(sprinttb(self.applyLab));
    
end

function newUnionInfo:initTop()
   

    CS.UGUIClickEventListener.Get(self.view.top.notify.change.gameObject).onClick = function()
        DialogStack.PushPrefStact("newUnion/newUnionNoticeEdit", {idx = self.notifyIdx or 1, desc = self.Manage:GetSelfUnion().desc, notice = self.Manage:GetSelfUnion().notice})
    end
    self:freshRedTip();

    -- CS.UGUIClickEventListener.Get(self.view.middle.bottom.joinBtn.gameObject).onClick = function()
    --     DialogStack.PushPrefStact("newUnion/newUnionJoin")
    -- end
    
    CS.UGUIClickEventListener.Get(self.view.top.getBtn.gameObject).onClick = function()
        local member = self.Manage:GetSelfInfo()
        if (member.yester_capital or 0) < 5000 then
            showDlgError(nil, "公会资金不足，今日无法发放！")
            return
        end
        self.view.tip.get.num[UI.Text].text = member.receive_capital;
        
        -- ERROR_LOG("声望====>>>>",member.historical_reputation)
        -- ERROR_LOG("声望====>>>>",member.receive_capital)
        if member.historical_reputation ==nil then
            self.view.tip.Text_GuildRank.rank[UI.Text].text=0
            self.view.tip.Text_GuildRank.rank[UI.Text].color=CS.UnityEngine.Color.red
        else
            self.view.tip.Text_GuildRank.rank[UI.Text].text=member.historical_reputation
        end
        if member.receive_capital==0 then
            self.view.tip.Text_GuildReputation.reputation[UI.Text].color=CS.UnityEngine.Color.red
        else
            self.view.tip.Text_GuildReputation.reputation[UI.Text].text=member.receive_capital
        end
        
        
        -- self.view.tip.Text_GuildRank.rank[UI.Text].text=member.historical_reputation
        -- self.view.tip.Text_GuildReputation.reputation[UI.Text].text=member.receive_capital
        self.view.tip.Tip.Text1[UI.Text].text=SGK.Localize:getInstance():getValue("guild_fund_info1");
         ERROR_LOG("历史声望====>>>",member.historical_reputation)
        -- ERROR_LOG("昨日声望====>>>",member.receive_capital)
        self.view.tip:SetActive(true);

        if member.receive_capital<=0 then
            --SetButtonStatus(false, self.view.tip.confirm);
            self.view.tip.title.confirm[UI.Image].material=SGK.QualityConfig.GetInstance().grayMaterial
            CS.UGUIClickEventListener.Get(self.view.tip.title.confirm.gameObject).onClick = function()
                local member = self.Manage:GetSelfInfo()
                if member.receive_capital <= 0 then 
                    showDlgError(nil, "昨日获得的公会声望不足100，无法领取")
                else
                    unionModule.GetUnionCapital()
                    self.view.tip:SetActive(false);
                end
            end
        end

    end
   
    
    
    -- CS.UGUIClickEventListener.Get(self.view.top.name.gameObject).onClick = function()
    --     unionModule.AddAchieve(100)z
    -- end
    -- CS.UGUIClickEventListener.Get(self.view.top.money.icon.gameObject).onClick = function()
    --     unionModule.AddUnionCapital(5000)
    -- end
    -- CS.UGUIClickEventListener.Get(self.view.top.level.gameObject).onClick = function()
    --     print("测试", sprinttb(self.Manage:GetSelfInfo()))
    -- end
    CS.UGUIClickEventListener.Get(self.view.top.money.helpBtn.gameObject).onClick = function()
        utils.SGKTools.ShowDlgHelp(SGK.Localize:getInstance():getValue("guild_fund_info2"), nil, self.view)
    end

    -- self.view.middle.bottom.Toggle[UI.Toggle].onValueChanged:AddListener(function(value)
    --     self:upMemberList()
    --     self.scrollView.DataCount = #self.memberList
    -- end)

    for i = 1, #self.view.top.notify.group do
        self.view.top.notify.group[i][UI.Toggle].onValueChanged:AddListener(function (value)
            if value then
                if i == 1 then
                    self.notifyIdx = 1
                    if self.Manage:GetSelfUnion().desc == "" then
                        self.view.top.notify.label[UI.Text].text = SGK.Localize:getInstance():getValue("juntuan_gonggao_03")
                    else
                        self.view.top.notify.label[UI.Text].text = self.Manage:GetSelfUnion().desc
                    end
                else
                    self.notifyIdx = 2
                    if self.Manage:GetSelfUnion().notice == "" then
                        self.view.top.notify.label[UI.Text].text = SGK.Localize:getInstance():getValue("juntuan_xuanyan_03")
                    else
                        self.view.top.notify.label[UI.Text].text = self.Manage:GetSelfUnion().notice
                    end
                end
            end
        end)
    end
end

function newUnionInfo:getMaxExp()
    local _exp = unionConfig.GetNumber(self.Manage:GetSelfUnion().unionLevel).MaxExp
    local _next = unionConfig.GetNumber(self.Manage:GetSelfUnion().unionLevel+1)
    if _next then
        return _next.MaxExp - _exp
    else
        return "Max"
    end
end

function newUnionInfo:upTop()
    local selfUnion = self.Manage:GetSelfUnion();
    if selfUnion == nil then
        return;
    end
    self.view.top.name.name[UI.Text].text = selfUnion.unionName
    self.view.top.level.level[UI.Text].text = "Lv."..selfUnion.unionLevel
    self.view.top.leadName.name[UI.Text].text = selfUnion.leaderName
    local sciene_lev = module.unionScienceModule.GetScienceInfo(11) and module.unionScienceModule.GetScienceInfo(11).level or 0;
    self.view.top.member.value[UI.Text].text = selfUnion.mcount.."/"..(unionConfig.GetNumber(selfUnion.unionLevel).MaxNumber + selfUnion.memberBuyCount+sciene_lev)
    self.view.top.rank.value[UI.Text].text = tostring(selfUnion.rank)
    self.view.top.money.number[UI.Text].text = (selfUnion.yester_capital or 0)
    if (selfUnion.yester_capital or 0) < 5000 then
        SetButtonStatus(true, self.view.top.getBtn);
        self.view.top.getBtn.Text[UI.Text].text = SGK.Localize:getInstance():getValue("guild_fund_btn1");
        self.view.top.getBtn[UI.Image].material=SGK.QualityConfig.GetInstance().grayMaterial
    else
        local selfInfo = self.Manage:GetSelfInfo();
        
        if selfInfo.is_receive == 0 then
            SetButtonStatus(true, self.view.top.getBtn);
            self.view.top.getBtn.Text[UI.Text].text = SGK.Localize:getInstance():getValue("guild_fund_btn1");
        else
            SetButtonStatus(false, self.view.top.getBtn);
            self.view.top.getBtn.Text[UI.Text].text = SGK.Localize:getInstance():getValue("xiaobai_luyouqi_7");
        end
    end
    local _maxExp = self:getMaxExp()
    if _maxExp == "Max" then
        self.view.top.level.Scrollbar[UI.Scrollbar].size = 1
        self.view.top.level.Scrollbar.number[UI.Text].text = "Max"
    else
        self.view.top.level.Scrollbar[UI.Scrollbar].size = (selfUnion.unionExp - unionConfig.GetNumber(selfUnion.unionLevel).MaxExp) / _maxExp
        self.view.top.level.Scrollbar.number[UI.Text].text = (selfUnion.unionExp - unionConfig.GetNumber(selfUnion.unionLevel).MaxExp).."/".._maxExp
    end
    for i = 1, #self.view.top.notify.group do
        if self.view.top.notify.group[i][UI.Toggle].isOn then
            if i == 1 then
                if selfUnion.desc == "" then
                    self.view.top.notify.label[UI.Text].text = SGK.Localize:getInstance():getValue("juntuan_gonggao_03")
                else
                    self.view.top.notify.label[UI.Text].text = selfUnion.desc
                end
            else
                if selfUnion.notice == "" then
                    self.view.top.notify.label[UI.Text].text = SGK.Localize:getInstance():getValue("juntuan_xuanyan_03")
                else
                    self.view.top.notify.label[UI.Text].text = selfUnion.notice
                end
            end
        end
    end
    
    self._questNum = ItemModule.GetItemCount(90098)
    -- if unionConfig.GetActivity() then
    --     for i,v in ipairs(unionConfig.GetActivity()) do
    --         if v.active_task and v.active_task~=0 then
    --             local MostActive =module.QuestModule.GetCfg(v.active_task)
    --             if MostActive then
    --                 if module.QuestModule.Get(v.active_task).status ==1 and module.QuestModule.Get(v.active_task) then
    --                    self._questNum=self._questNum+tonumber(MostActive.raw.desc2)  
    --                 end 
    --             end
    --         end
    --     end
    --     self.view.middle.top.bg.liveness.Text[UI.Text].text=self._questNum
    -- end
    if self._questNum>=questModule.Get(2015).cfg[1].cfg.raw.consume_value1 then
        self._questNum=questModule.Get(2015).cfg[1].cfg.raw.consume_value1
    end
    self.view.middle.top.bg.liveness.Text[UI.Text].text=self._questNum
    self.view.middle.top.bg.strip.scroll.Scrollbar[UI.Scrollbar].size=self:ratio()        --150/questModule.Get(2015).cfg[1].cfg.raw.consume_value1
end

function newUnionInfo:ratio()
    local _ratioFis = 0
    local _ratio=1/5
    if questModule.Get(2011) and questModule.Get(2012) then
        if self._questNum<=questModule.Get(2011).cfg[1].cfg.raw.consume_value1 then
            _ratioFis=self._questNum/(questModule.Get(2011).cfg[1].cfg.raw.consume_value1/_ratio)
            return _ratioFis
        elseif self._questNum<=questModule.Get(2012).cfg[1].cfg.raw.consume_value1 and self._questNum>questModule.Get(2011).cfg[1].cfg.raw.consume_value1 then
            local _value1 = self._questNum-questModule.Get(2011).cfg[1].cfg.raw.consume_value1
            local _value2 = (questModule.Get(2012).cfg[1].cfg.raw.consume_value1-questModule.Get(2011).cfg[1].cfg.raw.consume_value1)/_ratio
            local _ratioTow =_value1/_value2
            return (1/5)+_ratioTow
        elseif self._questNum<=questModule.Get(2013).cfg[1].cfg.raw.consume_value1 and self._questNum>questModule.Get(2012).cfg[1].cfg.raw.consume_value1 then
            local _value1 = self._questNum-questModule.Get(2012).cfg[1].cfg.raw.consume_value1
            local _value2 = (questModule.Get(2013).cfg[1].cfg.raw.consume_value1-questModule.Get(2012).cfg[1].cfg.raw.consume_value1)/_ratio
            local _ratioTow =_value1/_value2
            return (2/5)+_ratioTow
        elseif self._questNum<=questModule.Get(2014).cfg[1].cfg.raw.consume_value1 and self._questNum>questModule.Get(2013).cfg[1].cfg.raw.consume_value1 then
            local _value1 = self._questNum-questModule.Get(2013).cfg[1].cfg.raw.consume_value1
            local _value2 = (questModule.Get(2014).cfg[1].cfg.raw.consume_value1-questModule.Get(2013).cfg[1].cfg.raw.consume_value1)/_ratio
            local _ratioTow =_value1/_value2
            return (3/5)+_ratioTow
        elseif self._questNum<=questModule.Get(2015).cfg[1].cfg.raw.consume_value1 and self._questNum>questModule.Get(2014).cfg[1].cfg.raw.consume_value1 then
            local _value1 = self._questNum-questModule.Get(2014).cfg[1].cfg.raw.consume_value1
            local _value2 = (questModule.Get(2015).cfg[1].cfg.raw.consume_value1-questModule.Get(2014).cfg[1].cfg.raw.consume_value1)/_ratio
            local _ratioTow =_value1/_value2
            return (4/5)+_ratioTow
        else
            if self._questNum==questModule.Get(2015).cfg[1].cfg.raw.consume_value1 then
                return 1
            end
        end
    else
        
    end
    -- _ratioFis=questModule.Get(2011).cfg[1].cfg.raw.consume_value1/(questModule.Get(2011).cfg[1].cfg.raw.consume_value1/_ratio)
    -- local _value1 = self._questNum-questModule.Get(2011).cfg[1].cfg.raw.consume_value1
    -- local _value2 = (questModule.Get(2012).cfg[1].cfg.raw.consume_value1-questModule.Get(2011).cfg[1].cfg.raw.consume_value1)*math.floor(25/4)
    -- local _ratioTow =_value1/_value2
    -- return _ratioFis+_ratioTow
end
function newUnionInfo:upMemberList()
    -- self.memberList = {}
    -- self.onlieList = {}
    -- for i,v in ipairs(self.Manage:GetMember()) do
    --     if v.online then
    --         table.insert(self.onlieList, v)
    --     end
    --     if self.view.middle.bottom.Toggle[UI.Toggle].isOn then
    --         if v.online then
    --             table.insert(self.memberList, v)
    --         end
    --     else
    --         table.insert(self.memberList, v)
    --     end
    -- end
    -- table.sort(self.memberList, function(a, b)
    --     local _titleA = a.title
    --     local _titleB = b.title
    --     if _titleA == 0 then
    --         _titleA = 1000
    --     end
    --     if _titleB == 0 then
    --         _titleB = 1000
    --     end
    --     if _titleA == _titleB then
    --         return a.pid > b.pid
    --     else
    --         return _titleA < _titleB
    --     end
    -- end)
    -- self.view.middle.bottom.Toggle.number[UI.Text].text = SGK.Localize:getInstance():getValue("juntuan_14").." "..#self.onlieList.."/"..#self.Manage:GetMember()
end

function newUnionInfo:getLastTime(login)
    local _time = module.Time.now() - login
    if _time < 3600 then
        return SGK.Localize:getInstance():getValue("juntuan_lixian_01", math.floor(_time / 60))
    elseif _time < 86400 then
        return SGK.Localize:getInstance():getValue("juntuan_lixian_02", math.floor(_time / 3600))
    elseif _time < 86400 * 30 then
        return SGK.Localize:getInstance():getValue("juntuan_lixian_03", math.floor(_time / 86400))
    elseif _time < 86400 * 30 * 12 then
        return SGK.Localize:getInstance():getValue("juntuan_lixian_04", math.floor(_time / (86400 * 30)))
    else
        return SGK.Localize:getInstance():getValue("juntuan_lixian_05", math.floor(_time / (86400 * 30 * 12)))
    end
end

function newUnionInfo:upBtnList(_view, _cfg)
    -- CS.UGUIClickEventListener.Get(_view.mask.gameObject, true).onClick = function()
    --     _view:SetActive(false)
    -- end
    -- _view.bg["btn6"]:SetActive((self.Manage:GetSelfTitle() == 1) and (_cfg.pid == module.playerModule.GetSelfID()))
    -- _view.bg["btn1"]:SetActive(_cfg.pid ~= module.playerModule.GetSelfID())
    -- _view.bg["btn2"]:SetActive(_cfg.pid ~= module.playerModule.GetSelfID())
    -- _view.bg["btn3"]:SetActive(_cfg.pid ~= module.playerModule.GetSelfID())
    -- _view.bg["btn5"]:SetActive((self.Manage:GetSelfTitle() == 1) and (_cfg.pid ~= module.playerModule.GetSelfID()))
    -- _view.bg["btn7"]:SetActive((self.Manage:GetSelfTitle() ~= 1) and (_cfg.pid == module.playerModule.GetSelfID()))

    -- for i = 1, 7 do
    --     CS.UGUIClickEventListener.Get(_view.bg["btn"..i].gameObject).onClick = function()
    --         if i == 1 then
    --             DialogStack.Push("FriendSystemList",{idx = 1,viewDatas = {{pid = _cfg.pid,name = _cfg.name}}})
    --         elseif i == 2 then
    --             module.unionModule.AddFriend(_cfg.pid)
    --         elseif i == 3 then
    --             if module.FriendModule.GetManager(nil, _cfg.pid) then
    --                 DialogStack.PushPref("FriendBribeTaking", {pid = _cfg.pid, name = module.playerModule.IsDataExist(_cfg.pid).name})
    --             else
    --                 showDlgError(nil, SGK.Localize:getInstance():getValue("ditu_8"))
    --             end
    --         elseif i == 4 then
    --             if not utils.SGKTools.GetTeamState() then
    --                 utils.MapHelper.EnterOthersManor(_cfg.pid)
    --             else
    --                 showDlgError(nil, "组队中无法前往")
    --             end
    --         elseif i == 5 then
    --             if _cfg.pid == module.playerModule.GetSelfID() then
    --                 showDlgError(nil, SGK.Localize:getInstance():getValue("juntuan_tips_11"))
    --                 return
    --             end
    --             if module.unionModule.Manage:GetSelfTitle() == 1 or module.unionModule.Manage:GetSelfTitle() == 2 then
    --                 if ((unionModule.Manage:GetSelfTitle() ~= module.unionModule.Manage:GetMember(_cfg.pid).title) and module.unionModule.Manage:GetMember(_cfg.pid).title ~= 1) or module.unionModule.Manage:GetSelfTitle() == 1 then
    --                     showDlg(nil, SGK.Localize:getInstance():getValue("juntuan_tips_12"), function()
    --                         module.unionModule.Kick(_cfg.pid)
    --                     end,function ()

    --                     end)
    --                 else
    --                     showDlgError(nil, SGK.Localize:getInstance():getValue("juntuan_tips_13"))
    --                 end
    --             else
    --                 showDlgError(nil, SGK.Localize:getInstance():getValue("juntuan_tips_13"))
    --             end
    --         elseif i == 6 then
    --             showDlg(nil, SGK.Localize:getInstance():getValue("juntuan_tips_08"), function()
    --                     module.unionModule.DissolveUnion()

    --                     DialogStack.Pop();
    --                 end,function ()
    --             end)
    --         elseif i == 7 then
    --             showDlg(nil, SGK.Localize:getInstance():getValue("juntuan_tips_07"), function()
    --                     unionModule.Leave()
    --                 end,function ()
    --             end)
    --         end
    --         _view:SetActive(false)
    --     end
    -- end
end

function newUnionInfo:initBottom()
    local _box=self.view.middle.top.bg.box
    local _idx=2011
    for i=1,5 do
        --ERROR_LOG("公会===>>>>",sprinttb(questModule.Get(_idx)))
        --ERROR_LOG("任务status===========>>>",questModule.Get(_idx).status)
        --ERROR_LOG("_idx2======>>",_idx)
        if questModule.Get(_idx) then
            _box[i].Image.Text[UI.Text].text=questModule.Get(_idx).cfg[1].cfg.raw.consume_value1
        else
            showDlgError(nil, "error")
            return
        end
        local ActivityList =module.QuestModule.GetCfg(_idx)
        if questModule.Get(_idx) and questModule.Get(_idx).status and questModule.Get(_idx).status==0 and self._questNum >=questModule.Get(_idx).cfg[1].cfg.raw.consume_value1 then
        
               _box[i].Image4:SetActive(false)
               _box[i].Image[CS.UGUISpriteSelector].index=1
            _box[i].Image.Text[UI.Text].text="<color=#000000FF>" .._box[i].Image.Text[UI.Text].text .."</color>"
            self.effectNode = self:playEffect("fx_item_reward", nil, _box[i].pos )
            CS.UGUIClickEventListener.Get( _box[i].Image.gameObject).onClick=function()
                  --showDlgError(nil, "条件满足")
                  questModule.Finish((2010+i))
                  UnityEngine.Object.Destroy(_box[i].pos.gameObject)
                  _box[i].Image4:SetActive(true)
                  _box[i].Image[CS.UGUISpriteSelector].index=2
                  CS.UGUIClickEventListener.Get( _box[i].Image.gameObject).onClick=function()
                     showDlgError(nil, "奖励已领取")
                 end
            end
            --ERROR_LOG("ding------>>>",i)
         elseif questModule.Get(_idx).status==1  then
               _box[i].Image4:SetActive(true)
               _box[i].Image[CS.UGUISpriteSelector].index=2
            _box[i].Image.Text[UI.Text].text="<color=#000000FF>" .._box[i].Image.Text[UI.Text].text .."</color>"
            CS.UGUIClickEventListener.Get( _box[i].Image.gameObject).onClick=function()
                 showDlgError(nil, "奖励已领取")
             end
         else
               _box[i].Image4:SetActive(false)
               _box[i].Image[CS.UGUISpriteSelector].index=0
            CS.UGUIClickEventListener.Get(_box[i].Image.gameObject).onClick=function()
              DialogStack.PushPrefStact("newUnion/activeReward",{data=ActivityList})   
            end
        end
        _idx=_idx+1
    end

end

function newUnionInfo:playEffect(effectName, position, node, delete, sortOrder)
    local prefab = SGK.ResourcesManager.Load("prefabs/effect/UI/" .. effectName .. ".prefab");
    local o = prefab and UnityEngine.GameObject.Instantiate(prefab, node.transform);
    if o then
        local transform = o.transform;
        transform.localPosition = position or Vector3.zero;
        --transform.localScale = Vector3.zero
        transform.localRotation = Quaternion.identity;
        if sortOrder then
            SGK.ParticleSystemSortingLayer.Set(o, sortOrder);
        end
        if delete then
            local _obj = o:GetComponentInChildren(typeof(UnityEngine.ParticleSystem))
            UnityEngine.Object.Destroy(o, _obj.main.duration)
        end
    end
    return o
end

function newUnionInfo:listEvent()
    return {
        "PLAYER_FIGHT_INFO_CHANGE",
        "CONTAINER_UNION_MEMBER_INFO_CHANGE",
        "LOCAL_UNION_UPDATE_UI",
        "LOCAL_UNION_EXP_CHANGE",
        "LOCAL_UNION_NOTICE_CHANGE",
        "LOCAL_UNION_INFO_CHANGE",
        "LOCAL_CHANGE_APPLYLIST",
    }
end

function newUnionInfo:onEvent(event, data)
   -- print("onEvent", event, data)
    if event == "PLAYER_FIGHT_INFO_CHANGE" or event == "CONTAINER_UNION_MEMBER_INFO_CHANGE" then
        if self.scrollView then
            self.scrollView:ItemRef()
        end
        if event == "CONTAINER_UNION_MEMBER_INFO_CHANGE" and data == module.playerModule.GetSelfID() then
            self:upTop();
        end
    elseif event == "LOCAL_UNION_UPDATE_UI" or event == "LOCAL_UNION_EXP_CHANGE" or event == "LOCAL_UNION_NOTICE_CHANGE" or event == "LOCAL_UNION_INFO_CHANGE" then
        if self.scrollView then
            self:initData()
            self:upMemberList()
            self.scrollView.DataCount = #self.memberList
        end
        self:upTop()
    elseif event == "LOCAL_CHANGE_APPLYLIST" then
        self:freshRedTip();
    end
end

return newUnionInfo
