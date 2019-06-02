local unionModule = require "module.unionModule"
local unionConfig = require "config.unionConfig"
local playerModule = require "module.playerModule"



local newUnionMemberList = {}
function newUnionMemberList:Start()
    self.view = CS.SGK.UIReference.Setup(self.gameObject)
    self:initData()
    self:initUi()
end

function newUnionMemberList:initData()
    self.Manage = unionModule.Manage
    unionModule.UpSelfMember(true)
end

function newUnionMemberList:initUi()
    
    self:upMemberList()
    self:initTop()
    --self:upTop()
end
function newUnionMemberList:initTop()
   self:freshRedTip()
   CS.UGUIClickEventListener.Get(self.view.root.middle.bottom.joinBtn.gameObject).onClick = function()
       DialogStack.PushPrefStact("newUnion/newUnionJoin")
   end
   self.view.root.middle.bottom.Toggle[UI.Toggle].onValueChanged:AddListener(function(value)
        self:upMemberList()
        self.scrollView.DataCount = #self.memberList
   end)
   self.count=0
   CS.UGUIClickEventListener.Get(self.view.root.bg.bg.tip.gameObject).onClick=function ()
       if self.count==0 then
          self.view.root.middle.tipTex:SetActive(true)
          self.count=self.count+1
       else
        self.view.root.middle.tipTex:SetActive(false)
        self.count=0
       end
   end
   self:initBottom()
end


function newUnionMemberList:freshRedTip( ... )
    self.applyLab = unionModule.Manage:GetApply()
    local length = 0;
    for k,v in pairs(self.applyLab) do
        length = length+1;
    end
    if length == 0 then
        self.view.root.middle.bottom.joinBtn.redPoint:SetActive(false);
    else
        module.RedDotModule.PlayRedAnim(self.view.root.middle.bottom.joinBtn.redPoint)
        self.view.root.middle.bottom.joinBtn.redPoint:SetActive(true);
    end

    -- ERROR_LOG(sprinttb(self.applyLab));
    
end

function newUnionMemberList:upMemberList()
    self.memberList = {}
    self.onlieList = {}
    for i,v in ipairs(self.Manage.GetMember()) do
        if v.online then
            table.insert(self.onlieList, v)
        end
        if self.view.root.middle.bottom.Toggle[UI.Toggle].isOn  then
            if v.online then
                table.insert(self.memberList, v)
            end
        else
            table.insert(self.memberList, v)
        end
    end
    table.sort(self.memberList, function(a, b)
        local _titleA = a.title
        local _titleB = b.title
        if _titleA == 0 then
            _titleA = 1000
        end
        if _titleB == 0 then
            _titleB = 1000
        end
        if _titleA == _titleB then
            return a.pid > b.pid
        else
            return _titleA < _titleB
        end
    end)
    self.view.root.middle.bottom.Toggle.number[UI.Text].text = SGK.Localize:getInstance():getValue("juntuan_14").." "..#self.onlieList.."/"..#self.Manage:GetMember()
end



function newUnionMemberList:initBottom()
    self.scrollView = self.view.root.middle.ScrollView[CS.UIMultiScroller]
    self.scrollView.RefreshIconCallback = function(obj, idx)
        local _view = CS.SGK.UIReference.Setup(obj.gameObject)
        local _cfg = self.Manage:GetMember(self.memberList[idx + 1].id)  

        --ERROR_LOG("贡献===========>>>>",sprinttb(_cfg))
        _view.root.name[UI.Text].text = _cfg.name
        _view.root.contribution[UI.Text].text = tostring(_cfg.contirbutionTotal)
        _view.root.record[UI.Text].text = (_cfg.history_achieve or 0)--(_cfg.achieve or 0)今日声望
        utils.IconFrameHelper.Create(_view.root.IconFrame, {pid = _cfg.pid})
        utils.PlayerInfoHelper.GetPlayerAddData(_cfg.pid, 99, function (playerAddData)
            if playerAddData.Sex==0 then
                _view.root.name.Sex[CS.UGUISpriteSelector].index=1
            else
                _view.root.name.Sex[CS.UGUISpriteSelector].index=0
            end
        end)
        
        _view.root.Dropdown:SetActive(self.Manage:GetSelfTitle() == 1 or self.Manage:GetSelfTitle() == 2)

        CS.UGUIClickEventListener.Get(_view.root.IconFrame.gameObject).onClick = function()
            self.view.root.middle.btnList:SetActive(true)
            self.view.root.middle.btnList.transform.position = _view.root.btnPos.transform.position
            self:upBtnList(self.view.root.middle.btnList, _cfg)
        end
        local _id = self.Manage:GetMember(_cfg.pid).title
        if _id == 0 then _id = 4 end

        
        if _id <= self.Manage:GetSelfTitle() or self.Manage:GetSelfTitle() == 0  then
            _view.root.Dropdown:SetActive(false);
        end
        _view.root.Dropdown[UI.Dropdown].onValueChanged:RemoveAllListeners()
        _view.root.Dropdown[UI.Dropdown].value = _id - 1
        _view.root.Dropdown[UI.Dropdown].onValueChanged:AddListener(function (k)
            if _cfg.pid == playerModule.GetSelfID() then
                showDlgError(nil, SGK.Localize:getInstance():getValue("juntuan_tips_09"))
                self.scrollView:ItemRef()
                return
            end
            local _index = k + 1
            if _index == 1 then
                showDlg(nil, SGK.Localize:getInstance():getValue("juntuan_tips_10"), function()
                    unionModule.TransferUnion(_cfg.pid)
                end, function()
                    self.scrollView:ItemRef()
                end)
            else
                if _index == 4 then _index = 0 end
                unionModule.SetTitle(_cfg.pid, _index)
            end
        end)

        _view.root.title[UI.Text].text = "["..unionConfig.GetCompetence(_cfg.title).Name.."]"
        if _cfg.online then
            _view.root.onlie[UI.Text].text = SGK.Localize:getInstance():getValue("juntuan_17")
        else
            _view.root.onlie[UI.Text].text = self:getLastTime(_cfg.login)
        end
        unionModule.UpSelfMember(true)
        if playerModule.GetFightData(_cfg.pid) then
            _view.root.fight[UI.Text].text = tostring(math.ceil(playerModule.GetFightData(_cfg.pid).capacity))
        else
            _view.root.fight[UI.Text].text = "0"
        end
        obj:SetActive(true)
    end
    self.scrollView.DataCount = #self.memberList
end

function newUnionMemberList:getLastTime(login)
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

function newUnionMemberList:upBtnList(_view, _cfg)
    CS.UGUIClickEventListener.Get(_view.mask.gameObject, true).onClick = function()
        _view:SetActive(false)
    end
    _view.bg["btn6"]:SetActive((self.Manage:GetSelfTitle() == 1) and (_cfg.pid == playerModule.GetSelfID()))
    _view.bg["btn1"]:SetActive(_cfg.pid ~= playerModule.GetSelfID())
    _view.bg["btn2"]:SetActive(_cfg.pid ~= playerModule.GetSelfID())
    _view.bg["btn3"]:SetActive(_cfg.pid ~= playerModule.GetSelfID())
    _view.bg["btn5"]:SetActive((self.Manage:GetSelfTitle() == 1) and (_cfg.pid ~= playerModule.GetSelfID()))
    _view.bg["btn7"]:SetActive((self.Manage:GetSelfTitle() ~= 1) and (_cfg.pid == playerModule.GetSelfID()))

    for i = 1, 7 do
        CS.UGUIClickEventListener.Get(_view.bg["btn"..i].gameObject).onClick = function()
            if i == 1 then
                DialogStack.Push("FriendSystemList",{idx = 1,viewDatas = {{pid = _cfg.pid,name = _cfg.name}}})
            elseif i == 2 then
                module.unionModule.AddFriend(_cfg.pid)
            elseif i == 3 then
                if module.FriendModule.GetManager(nil, _cfg.pid) then
                    DialogStack.PushPref("FriendBribeTaking", {pid = _cfg.pid, name = playerModule.IsDataExist(_cfg.pid).name})
                else
                    showDlgError(nil, SGK.Localize:getInstance():getValue("ditu_8"))
                end
            elseif i == 4 then
                if not utils.SGKTools.GetTeamState() then
                    utils.MapHelper.EnterOthersManor(_cfg.pid)
                else
                    showDlgError(nil, "组队中无法前往")
                end
            elseif i == 5 then
                if _cfg.pid ==playerModule.GetSelfID() then
                    showDlgError(nil, SGK.Localize:getInstance():getValue("juntuan_tips_11"))
                    return
                end
                if module.unionModule.Manage:GetSelfTitle() == 1 or module.unionModule.Manage:GetSelfTitle() == 2 then
                    if ((unionModule.Manage:GetSelfTitle() ~= module.unionModule.Manage:GetMember(_cfg.pid).title) and module.unionModule.Manage:GetMember(_cfg.pid).title ~= 1) or module.unionModule.Manage:GetSelfTitle() == 1 then
                        showDlg(nil, SGK.Localize:getInstance():getValue("juntuan_tips_12"), function()
                            module.unionModule.Kick(_cfg.pid)
                        end,function ()

                        end)
                    else
                        showDlgError(nil, SGK.Localize:getInstance():getValue("juntuan_tips_13"))
                    end
                else
                    showDlgError(nil, SGK.Localize:getInstance():getValue("juntuan_tips_13"))
                end
            elseif i == 6 then
                showDlg(nil, SGK.Localize:getInstance():getValue("juntuan_tips_08"), function()
                        module.unionModule.DissolveUnion()

                        DialogStack.Pop();
                    end,function ()
                end)
            elseif i == 7 then
                showDlg(nil, SGK.Localize:getInstance():getValue("juntuan_tips_07"), function()
                        unionModule.Leave()
                    end,function ()
                end)
            end
            _view:SetActive(false)
        end
    end
end



function newUnionMemberList:upTop()
    
end


function newUnionMemberList:listEvent()
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

function newUnionMemberList:onEvent(event, data)
    --print("onEvent", event, data)
    if event == "PLAYER_FIGHT_INFO_CHANGE" or event == "CONTAINER_UNION_MEMBER_INFO_CHANGE" then
        if self.scrollView then
            self.scrollView:ItemRef()
        end
        if event == "CONTAINER_UNION_MEMBER_INFO_CHANGE" and data == playerModule.GetSelfID() then
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










return newUnionMemberList;