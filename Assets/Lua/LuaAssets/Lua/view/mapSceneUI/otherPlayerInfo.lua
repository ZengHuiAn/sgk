local playerModule = require "module.playerModule"
local unionModule = require "module.unionModule"
local NetworkService = require "utils.NetworkService"
local OpenLevel = require "config.openLevel"
local ChatManager = require 'module.ChatModule'
local otherPlayerInfo = {}

function otherPlayerInfo:Start(data)
    self:initData(data)
    self:initUi()
end

function otherPlayerInfo:initData(data)
    self.pid = data
    module.TeamModule.GetPlayerTeam(self.pid,true,function ( ... )
        self:initGroup()
    end)
end

function otherPlayerInfo:initUi()
    self.view = CS.SGK.UIReference.Setup(self.gameObject)
    self:initCloseBtn()
    self:initTop()
    self:initGroup()
end

function otherPlayerInfo:initTop()
    self.name = self.view.otherPlayerInfoRoot.bg.top.name[UI.Text]
    self.level = self.view.otherPlayerInfoRoot.bg.top.level[UI.Text]
    self.id = self.view.otherPlayerInfoRoot.bg.top.id[UI.Text]
    self.unionName = self.view.otherPlayerInfoRoot.bg.top.union[UI.Text]
    self.icon = self.view.otherPlayerInfoRoot.bg.top.icon[UI.Image]
    --self.newCharacterIcon = self.view.otherPlayerInfoRoot.bg.top.newCharacterIcon[SGK.newCharacterIcon]

    utils.IconFrameHelper.Create(self.view.otherPlayerInfoRoot.bg.top.IconFrame, {pid = self.pid, IconType = 3})

    if playerModule.IsDataExist(self.pid) then
        self:upTop(playerModule.IsDataExist(self.pid))
    else
        playerModule.Get(self.pid,(function( ... )
            self:upTop(playerModule.IsDataExist(self.pid))
        end))
    end
    --self.view.otherPlayerInfoRoot.bg.itemGroup["Toggle (6)"]:SetActive(CS.UnityEngine.Application.isEditor)
    self.view.otherPlayerInfoRoot.bg.itemGroup["Toggle (6)"]:SetActive(false)

    utils.PlayerInfoHelper.GetPlayerAddData(self.pid, 99, function(addData)
        --self.view.otherPlayerInfoRoot.bg.top.newCharacterIcon[SGK.newCharacterIcon].headFrame = addData.HeadFrame
        --self.view.otherPlayerInfoRoot.bg.top.newCharacterIcon[SGK.newCharacterIcon].sex = addData.Sex
        if addData and addData.PersonDesc then
            self.view.otherPlayerInfoRoot.bg.top.signature.signatureLab[UI.Text]:TextFormat("签名:"..addData.PersonDesc)
        else
            self.view.otherPlayerInfoRoot.bg.top.signature.signatureLab[UI.Text]:TextFormat("签名:")
        end
    end)
end

function otherPlayerInfo:upTop(data)
    self.name.text = data.name
    --self.level.text = data.level
    self.id.text = "ID: "..data.id
    local head = data.head ~= 0 and data.head or 11001
    --self.icon:LoadSprite("icon/".. head)

    --self.newCharacterIcon.level = data.level
    --self.newCharacterIcon.icon = tostring(head)
    self.view.otherPlayerInfoRoot.bg.itemGroup["Toggle (4)"]:SetActive(false)
    local _view = self.view.otherPlayerInfoRoot.bg.itemGroup["Toggle (5)"]
    _view:SetActive(OpenLevel.GetStatus(2101) and OpenLevel.GetStatus(1601, data.level))
    self.view.otherPlayerInfoRoot.bg.itemGroup["Toggle (1)"]:SetActive(OpenLevel.GetStatus(2501) and OpenLevel.GetStatus(2501, data.level))
    self.view.otherPlayerInfoRoot.bg.itemGroup["Toggle (3)"]:SetActive(OpenLevel.GetStatus(1601) and OpenLevel.GetStatus(1601, data.level))
    self.view.otherPlayerInfoRoot.bg.itemGroup["Toggle (2)"]:SetActive(OpenLevel.GetStatus(2501) and OpenLevel.GetStatus(2501, data.level))
    if unionModule.Manage:GetUionId() == 0 then
        if _view.activeSelf then
            _view.Background[UI.Image].material = _view.Background[CS.UnityEngine.MeshRenderer].materials[0]
        end
    end

    -- if unionModule.GetPlayerUnioInfo(self.pid).haveUnion then
    --     self.unionName:TextFormat("公会:{0}", unionModule.GetPlayerUnioInfo(self.pid).unionName or "无")
    -- else
        unionModule.queryPlayerUnioInfo(self.pid,(function ( ... )
            if unionModule.GetPlayerUnioInfo(self.pid).haveUnion then
                self.unionName:TextFormat("公会:{0}", unionModule.GetPlayerUnioInfo(self.pid).unionName or "无")
            end
        end))
    --end
    self.view.otherPlayerInfoRoot.bg[UI.VerticalLayoutGroup].enabled = false
    self.view.otherPlayerInfoRoot.bg[UI.VerticalLayoutGroup].enabled = true
end

function otherPlayerInfo:initGroup()
    for i = 1, 8 do
        local _item = self.view.otherPlayerInfoRoot.bg.itemGroup[i][UI.Toggle]
        if i == 4 then
            local _data = module.TeamModule.GetClickTeamInfo(self.pid)
            --ERROR_LOG(">",sprinttb(_data))
            if _data and _data.members and _data.members[1] and module.TeamModule.GetTeamInfo().id <= 0 then
                self.view.otherPlayerInfoRoot.bg.itemGroup[i].Label[UI.Text].text = "申请入队"
            else
                self.view.otherPlayerInfoRoot.bg.itemGroup[i].Label[UI.Text].text = "邀请入队"
            end
        end
        if i == 1 then
            module.playerModule.Get(self.pid,function ( p_info )

                local status = utils.SGKTools.GetEnterOthersManor(p_info.level);

                _item.gameObject:SetActive(status ~=nil);
            end)
        end
        
        _item.onValueChanged:RemoveAllListeners()
        _item.onValueChanged:AddListener(function ( value )
            if value then
                DialogStack.Pop()
                if i == 1 then      ---查看庄园
                    if not utils.SGKTools.GetTeamState() then
                        utils.MapHelper.EnterOthersManor(self.pid)
                    else
                        if module.TeamModule.GetAfkStatus() ~= true then
                            showDlgError(nil, "组队中无法前往")
                        else
                            utils.MapHelper.EnterOthersManor(self.pid)
                        end
                    end
                elseif i == 2 then  ---发送消息
                    --DispatchEvent("LOCAL_MAPSCENE_OPEN_CHATFRAME", {type = 4,playerData = {id = self.pid,name = self.name.text}})
                    -- local list = nil
                    -- if ChatManager.GetManager(6) then
                    --     list = ChatManager.GetManager(6)[self.pid]
                    -- end
                    -- DialogStack.PushPref("FriendChat",{data = list,pid = self.pid},UnityEngine.GameObject.FindWithTag("UGUIRootTop").gameObject)
                    DialogStack.Push("FriendSystemList",{idx = 1,viewDatas = {{pid = self.pid,name = self.name.text}}})
                elseif i == 4 then  ---邀请入队
                    local _data = module.TeamModule.GetClickTeamInfo(self.pid)
                    if _data and _data.members and _data.members[1] and module.TeamModule.GetTeamInfo().id <= 0 then
                        if _data.members[3] then
                            if _data.upper_limit == 0 or (module.playerModule.Get(module.playerModule.GetSelfID()).level >= _data.lower_limit and  module.playerModule.Get(module.playerModule.GetSelfID()).level <= _data.upper_limit) then
                                module.TeamModule.JoinTeam(_data.members[3])
                            else
                                showDlgError(nil,"你的等级不满足对方的要求")
                            end
                        end
                    elseif module.TeamModule.GetTeamInfo().id <= 0 then
                        module.TeamModule.CreateTeam(999,function ( ... )
                            utils.PlayerInfoHelper.GetPlayerAddData(self.pid, utils.PlayerInfoHelper.ServerAddDataType.UNIONANDTEAMSTATUS, function(addData)
                                if not addData.UnionAndTeamInviteStatus then
                                    module.TeamModule.Invite(self.pid)
                                else
                                    showDlgError(nil, "对方已设置不接受组队邀请")
                                end
                            end, true)
                        end);--创建空队伍并邀请对方
                    else
                        utils.PlayerInfoHelper.GetPlayerAddData(self.pid, utils.PlayerInfoHelper.ServerAddDataType.UNIONANDTEAMSTATUS, function(addData)
                            if not addData.UnionAndTeamInviteStatus then
                                module.TeamModule.Invite(self.pid)
                            else
                                showDlgError(nil, "对方已设置不接受组队邀请")
                            end
                        end, true)
                    end
                elseif i == 3 then  ---加为好友
                    utils.PlayerInfoHelper.GetPlayerAddData(self.pid, utils.PlayerInfoHelper.ServerAddDataType.UNIONANDTEAMSTATUS, function(addData)
                        unionModule.AddFriend(self.pid)
                    end)
                elseif i == 5 then
                    if module.FriendModule.GetManager(nil, self.pid) then
                        DialogStack.PushPref("FriendBribeTaking",{pid = self.pid, name = module.playerModule.IsDataExist(self.pid).name})
                    else
                        showDlgError(nil, SGK.Localize:getInstance():getValue("ditu_8"))
                    end
                elseif i == 6 then  ---邀请入帮
                    if unionModule.Manage:GetUionId() == 0 then
                        showDlgMsg("您还未加入公会，是否申请加入公会", function()
                            utils.MapHelper.OpUnionList()
                        end, function()end, "查看公会", "稍后再说")
                    elseif unionModule.GetPlayerUnioInfo(self.pid).unionId ~= nil and unionModule.GetPlayerUnioInfo(self.pid).unionId ~= 0 then
                        showDlgError(nil, "该玩家已有公会")
                    else
                        utils.PlayerInfoHelper.GetPlayerAddData(self.pid, utils.PlayerInfoHelper.ServerAddDataType.UNIONANDTEAMSTATUS, function(addData)
                            if not addData.UnionAndTeamInviteStatus then
                                unionModule.Invite(self.pid)
                            else
                                showDlgError(nil, "对方已设置不接受加入公会邀请")
                            end
                        end, true)
                    end
                elseif i == 7 then  ---切磋
                    NetworkService.Send(16007, {nil, self.pid})
                    showDlgError(nil,"已发送请求")
                elseif i == 8 then  ---举报

                end
            end
        end)
    end
end

function otherPlayerInfo:initCloseBtn()
    CS.UGUIClickEventListener.Get(self.view.mask.gameObject, true).onClick = function()
        DialogStack.Pop()
    end
end
function otherPlayerInfo:onEvent(event, data)
    if event == "Team_members_Request" then
        
    end
end
function otherPlayerInfo:listEvent()
    return {
    "Team_members_Request",
}
end
return otherPlayerInfo
