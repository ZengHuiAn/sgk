-- 公会战报名
local GuildPVPGroupModule = require "guild.pvp.module.group"
local playerModule = require "module.playerModule"
local View = {};

function View:Start(ctx)
    local this = self;

    self.view = SGK.UIReference.Setup(self.gameObject);

    self.members = self.members or utils.Container("UNION_MEMBER"):GetList();

    local heros = self.heros or GuildPVPGroupModule.GetHero();
    print("heros", sprinttb(GuildPVPGroupModule.GetHero()))
    if not self.heros then
        self.heros = {}
        for k, v in ipairs(heros) do
            if v == 0 or utils.Container("UNION_MEMBER"):Get(v) then
                self.heros[k] = v;
            end
        end
    end
    CS.UGUIClickEventListener.Get(self.view.closeBtn.gameObject).onClick = function()
        DialogStack.Pop();
    end
    self.UIMultiScroller = self.view.ScrollView[CS.UIMultiScroller];
    self.FormationSlots = self.view.Slots[SGK.FormationSlots];

    self.FormationSlots.onOrderChange = function()
        for i = 1, 4 do
            self.heros[i] = self.FormationSlots:Get(i-1);
            print("-->", i, self.heros[i])
        end
    end

    self:UpdateMemberList();
    self:UpdateSlots();

    CS.UGUIClickEventListener.Get(self.view.Save.gameObject).onClick = function()
        self:Save();
    end

    local memberInfo = module.unionModule.Manage:GetSelfInfo()
    if not memberInfo or memberInfo.title == 0 then
        self.view.Save:SetActive(false)
    else
        self.view.Save:SetActive(true)
    end
    -- module.ItemModule.GetGiftItem(89006, function(data)
    --     ERROR_LOG(sprinttb(data))
    --     for i = 1,#data do
    --         self.view.Reward1.Content.Item.icon[UnityEngine.UI.Image]:LoadSprite("icon/"..data[i][2])
    --         self.view.Reward1.Content.Item.count[UnityEngine.UI.Text].text = "x"..data[i][3]
    --         local _Item = CS.UnityEngine.GameObject.Instantiate(self.view.Reward1.Content.Item.gameObject,self.view.Reward1.Content.transform)
    --         _Item:SetActive(true)
    --     end
    -- end)
    utils.IconFrameHelper.Create(self.view.Reward1.Content.IconFrame,{type = 41, id = 89006, count = 1, showDetail = true});
    self.view.Reward1.Content.IconFrame:SetActive(true);
    -- module.ItemModule.GetGiftItem(89007, function(data)
    --    ERROR_LOG(sprinttb(data))
    --     for i = 1,#data do
    --         self.view.Reward2.Content.Item.icon[UnityEngine.UI.Image]:LoadSprite("icon/"..data[i][2])
    --         self.view.Reward2.Content.Item.count[UnityEngine.UI.Text].text = "x"..data[i][3]
    --         local _Item = CS.UnityEngine.GameObject.Instantiate(self.view.Reward2.Content.Item.gameObject,self.view.Reward2.Content.transform)
    --         _Item:SetActive(true)
    --     end
    -- end)
    utils.IconFrameHelper.Create(self.view.Reward2.Content.IconFrame,{type = 41, id = 89007, count = 1, showDetail = true});
    self.view.Reward2.Content.IconFrame:SetActive(true);
end

function View:UpdateMemberList()
    table.sort(self.members,function (a,b)

        local fight1 = module.playerModule.GetFightData(a.pid)

         if  not fight1 then
            return false;
        end

        local capacity1 = fight1.capacity;

        local fight2 = module.playerModule.GetFightData(b.pid);
        if not fight2 then
            return false;
        end
        
        local capacity2 = fight2.capacity;
        if capacity1 ~= capacity2 then
            return capacity1 > capacity2;
        end
        return a.pid < b.pid;
    end )
    self.UIMultiScroller.RefreshIconCallback = function(obj, index)
        self:UpdateMemberInfo(index + 1, obj);
    end

    self.UIMultiScroller.DataCount = #self.members;
end

function View:UpdateMemberInfo(index, obj)
    local info = self.members[index]
    if not info then
        ERROR_LOG('!!!!!', index, "no found");
        return;
    end

    obj = obj or self.UIMultiScroller:GetItem(index-1);

    local _view = SGK.UIReference.Setup(obj)
    if playerModule.IsDataExist(info.pid) then
        utils.IconFrameHelper.Create(_view.IconFrame, {pid = info.id});
        -- local head = playerModule.IsDataExist(info.pid).head ~= 0 and playerModule.IsDataExist(info.pid).head or 11000
        -- PLayerIcon[SGK.newCharacterIcon]:SetInfo({head = head,level =  playerModule.IsDataExist(info.pid).level,name = "",vip=0},true)
        _view.name:TextFormat(playerModule.IsDataExist(info.pid).name)
    else
        playerModule.Get(info.pid,(function( ... )
            -- local head = playerModule.IsDataExist(info.pid).head ~= 0 and playerModule.IsDataExist(info.pid).head or 11000
            -- PLayerIcon[SGK.newCharacterIcon]:SetInfo({head = head,level =  playerModule.IsDataExist(info.pid).level,name = "",vip=0},true)
            utils.IconFrameHelper.Create(_view.IconFrame, {pid = info.id});
             _view.name:TextFormat(playerModule.IsDataExist(info.pid).name)
        end))
    end

    local isSelected = false;
    for _, v in ipairs(self.heros) do
        if v == info.pid then
            isSelected = true;
            break;
        end
    end
    module.playerModule.GetCombat(info.pid,function ( ... )
        _view.PowerText:TextFormat(tostring(math.ceil(module.playerModule.GetFightData(info.pid).capacity)))
    end)
    --_view.PowerText:TextFormat(0)
    _view.Checker:SetActive(isSelected);

    CS.UGUIClickEventListener.Get(_view.click.gameObject).onClick = function()
        local pid = module.playerModule.Get().id
        if module.unionModule.Manage:GetMember(pid).title == 1 or module.unionModule.Manage:GetMember(pid).title == 2 then
            self:SwitchPlayerSlotInfo(info.pid)
        else
            showDlgError(nil,"只有会长和副会长可操作")
        end
    end

    _view:SetActive(true);
end

function View:UpdateSlots()
    for i = 1, 4 do
        local player = {}
        if self.heros[i] ~= 0 then
            utils.PlayerInfoHelper.GetPlayerAddData(self.heros[i], 99, function (_playerAddData)
                self:SetSlots(i-1, self.heros[i], tostring(_playerAddData and _playerAddData.ActorShow or 11048))
            end)
        end
    end
end

function View:SetSlots(idx, key, mode)
    local func = function ()
        local _obj = self.FormationSlots:GetItem(idx)
        local _view = SGK.UIReference.Setup(_obj)
        if key ~= 0 then
            _view.name[UnityEngine.UI.Text].text = playerModule.Get(key).name;
        else
            _view.name[UnityEngine.UI.Text].text = "";
        end
    end
    self.FormationSlots:Set(idx, key, mode, func);
end

function View:SwitchPlayerSlotInfo(pid)
    local slot = nil;
    for k, v in ipairs(self.heros) do
        if v == pid then
            slot = k;
        end
    end

    local index = nil;
    for k, v in ipairs(self.members) do
        if v.pid == pid then
            index = k;
        end
    end

    if slot then
        self.heros[slot] = 0;
        self:SetSlots(slot-1, 0, "")
        self:UpdateMemberInfo(index);
        return;
    end

     for i, v in ipairs(self.heros) do
        if v == 0 then
            self.heros[i] = pid;
            utils.PlayerInfoHelper.GetPlayerAddData(self.heros[i], 99, function (_playerAddData)
                self:SetSlots(i-1, self.heros[i], tostring(_playerAddData and _playerAddData.ActorShow or 11048))
            end)
            self:UpdateMemberInfo(index);
            return;
        end
    end
end

function View:Save()
    local memberInfo = module.unionModule.Manage:GetSelfInfo()
    if not memberInfo or memberInfo.title == 0 then
        showDlgError(nil,"@str/guild/pvp/error/title");
        return;
    end

    for i = 1, 4 do
        self.heros[i] = self.FormationSlots:Get(i-1);
        print('-->', i, self.heros[i]);
    end
    GuildPVPGroupModule.setHero(self.heros);
    showDlgError(nil, "保存成功");
    DialogStack.Pop();
end

function View:setHero(pid, type)
    GuildPVPGroupModule.setHero(pid, type);
end

function View:listEvent()
    return {
        "PLAYER_APPEARANCE_CHANGE",
        "GUILD_PVP_HERO_CHANGE",
        "PLAYER_FIGHT_INFO_CHANGE",
    }
end

function View:onEvent(event, ...)
    print("onEvent", event, ...);
    if event == "PLAYER_INFO_CHANGE" then
        self:UpdateMemberList();
        self:UpdateSlots();
    elseif event == "GUILD_PVP_HERO_CHANGE" or "PLAYER_FIGHT_INFO_CHANGE" then
        self:UpdateMemberList();

    end
end

return View;
