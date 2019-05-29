local ItemHelper = require "utils.ItemHelper"
local PlayerInfoHelper = require "utils.PlayerInfoHelper"
local PlayerModule = require "module.playerModule"
local ItemModule=require"module.ItemModule"
local HeroLevelup = require "hero.HeroLevelup"
local UserDefault = require "utils.UserDefault";
local openLevel = require "config.openLevel"
local View = {}

function View:Start()
    self.view = CS.SGK.UIReference.Setup(self.gameObject).view
end

function View:Init(data)
    self.selectTabIdx=data and data or 1
    self:initTop()
    self:upTop()
    self:initMid()
    self:initBottom(data)

    if self.Status then
        self.view.ChangeIconFrame.gameObject:SetActive(true)
        self.view.ChangeIconFrame[SGK.LuaBehaviour]:Call("UpdateUI",self.StatusSelect) 
    end
end

function View:initTop()
    self.click_Times = 0;
    CS.UGUIClickEventListener.Get(self.view.top.GMBtn.gameObject, true).onClick = function()
        self.click_Times =self.click_Times + 1;
        if self.click_Times>2 then
            self.click_Times=0
            DialogStack.Push("SubmitForm")
        end
    end
    CS.UGUIClickEventListener.Get(self.view.top.vip[1].gameObject, true).onClick = function()
        DialogStack.Push("SubmitForm")
    end

    CS.UGUIClickEventListener.Get(self.view.top.changeName.gameObject).onClick = function()
        DialogStack.PushPrefStact("mapSceneUI/changeName", nil, UnityEngine.GameObject.FindWithTag("UGUIRootTop"))
    end

    CS.UGUIClickEventListener.Get(self.view.top.info.gameObject).onClick = function()
        local playerAddData=PlayerInfoHelper.GetPlayerAddData();
        DialogStack.PushPrefStact("mapSceneUI/changeName", {idx=2,info=playerAddData.PersonDesc}, UnityEngine.GameObject.FindWithTag("UGUIRootTop"))
    end 

    CS.UGUIClickEventListener.Get(self.view.top.changeIcon.gameObject).onClick = function()
        DialogStack.Push("mapSceneUI/ChangeIconFrame")
    end
end

function View:upTop()
    PlayerInfoHelper.GetSelfBaseInfo(function (player)   
        player.vip=player.vip or 0
        self.view.top.vip[1].Text[UI.Text]:TextFormat("VIP{0}",player.vip)

        self.view.top.icon.CharacterIcon[SGK.CharacterIcon]:SetInfo(setmetatable({level=0},{__index=player}),true)
        -- self.view.top.icon.CharacterIcon.Level.gameObject:SetActive(false)

        self.view.top.name.Text[UI.Text].text=tostring(player.name)
        self.view.top.id.Text[UI.Text]:TextFormat("ID:{0}",player.id)

        self.view.top.ExpInfo.Text[UI.Text].text=tostring("Lv"..player.level)
        self.view.top.changeName.gameObject:SetActive(openLevel.GetStatus(5001))
        self.view.top.changeIcon[CS.UGUIClickEventListener].interactable=openLevel.GetStatus(5001)

        self.view.top.changeIcon.Button:SetActive(openLevel.GetStatus(5001))
        self.view.top.changeIcon.Button.Title[UI.Text].text="点击更换"
        self.view.top.changeIcon.Text:SetActive(not openLevel.GetStatus(5001))
        self.view.top.changeIcon.Text[UI.Text].text=openLevel.GetStatus(5001) and "点击更换" or "未解锁"
    end) 
    
    local hero = module.HeroModule.GetManager():Get(11000) 
    local hero_level_up_config = HeroLevelup.GetExpConfig(1, hero);
    local Level_exp = hero_level_up_config[hero.level]
    local Next_hero_level_up = hero_level_up_config[hero.level+1] and hero_level_up_config[hero.level+1]-Level_exp or hero_level_up_config[hero.level]-hero_level_up_config[hero.level-1]

    local ShowExp=hero_level_up_config[hero.level+1] and hero.exp-Level_exp or Next_hero_level_up
    if not hero_level_up_config[hero.level+1] then
        self.view.top.ExpInfo.value[UI.Text].text="等级已达到上限"
        self.view.top.ExpInfo.Exp[UI.Image].fillAmount = 0;
    else
        self.view.top.ExpInfo.value[UI.Text].text=string.format("%s/%s",math.floor(ShowExp),math.floor(Next_hero_level_up))
        self.view.top.ExpInfo.Exp[UI.Image].fillAmount = ShowExp/Next_hero_level_up;
    end
end

function View:initMid()
    self.view.mid.sex.Text[UI.Text].text="性别:"
    self.view.mid.area.Text[UI.Text].text="地区:"
    local province=PlayerInfoHelper.GetPlayerProvince()
    for k,v in pairs(province) do
        self.view.mid.area.Dropdown[SGK.DropdownController]:AddOpotion(tostring(v.province))
    end 
    
    self.view.mid.sex.Dropdown[UI.Dropdown].onValueChanged:AddListener(function (i)
        if i~= self.lastSelectSexIdx then
            PlayerInfoHelper.ChangeSex(self.view.mid.sex.Dropdown[UI.Dropdown].value)
        end
    end)
    
    self.view.mid.area.Dropdown[UI.Dropdown].onValueChanged:AddListener(function (i)
        if i~= self.lastSelectAreaIdx then
            PlayerInfoHelper.ChangeArea(self.view.mid.area.Dropdown[UI.Dropdown].value)
        end
    end)

    PlayerInfoHelper.GetPlayerAddData(0,nil,function (playerAddData)
        self:UpdatePlayerAddDataUI(playerAddData)
    end)
end

function View:UpdatePlayerAddDataUI(playerAddData)
    self.view.top.icon.CharacterIcon[SGK.CharacterIcon].sex=playerAddData.Sex
    self.view.top.icon.CharacterIcon[SGK.CharacterIcon].headFrame=playerAddData.HeadFrame

    local _Info=playerAddData.PersonDesc~="" and playerAddData.PersonDesc or string.format("<color=#808080FF>%s</color>","编辑个性签名…")
    self.view.top.info.Text[UI.Text].text=tostring(_Info)
  
    self.lastSelectSexIdx=playerAddData.Sex and playerAddData.Sex or 0
    self.view.mid.sex.Dropdown[UI.Dropdown].value=self.lastSelectSexIdx
    self.view.mid.sex.Dropdown.Label[UI.Text].text =self.view.mid.sex.Dropdown[UI.Dropdown].options[self.view.mid.sex.Dropdown[UI.Dropdown].value].text  
  
    self.lastSelectAreaIdx=playerAddData.Area and playerAddData.Area or 2
    self.view.mid.area.Dropdown[UI.Dropdown].value=self.lastSelectAreaIdx
    self.view.mid.area.Dropdown.Label[UI.Text].text =self.view.mid.area.Dropdown[UI.Dropdown].options[self.view.mid.area.Dropdown[UI.Dropdown].value].text    
end

local topTabName={"竞技","公会","资源","统计"}
function View:initBottom()
    for i=1,#topTabName do
        self.view.bottom.itemNode.Content[i].gameObject:SetActive(i==self.selectTabIdx)
        if i==self.selectTabIdx then
            self.view.bottom.topTab[self.selectTabIdx][UI.Toggle].isOn = true
            self:upBottom() 
        end
        
        self.view.bottom.topTab[i].Text[UI.Text].text=tostring(topTabName[i])
        CS.UGUIClickEventListener.Get(self.view.bottom.topTab[i].gameObject,true).onClick = function()
            self.view.bottom.itemNode.Content[self.selectTabIdx].gameObject:SetActive(false)
            self.selectTabIdx=i
            DispatchEvent("PLAYER_INFO_IDX_CHANGE",{self.selectTabIdx})
            self.view.bottom.itemNode.Content[self.selectTabIdx].gameObject:SetActive(true)
            self:upBottom()
        end
    end
end

local rankList = {{"副本星星数"},{"竞技场"},{"试练塔"},{"财力"}}
local unionInfoTab={{"公会","unionName"},{"等级","unionLevel"},{"会长","leaderName"},{"人数","showMemberNumber"}}
function View:upBottom()
    local NodePlane=self.view.bottom.itemNode.Content[self.selectTabIdx]
    if self.selectTabIdx==1 then
        for i=1,NodePlane.Content.transform.childCount do
            NodePlane.Content.transform:GetChild(i-1).gameObject:SetActive(false)
        end
        local _prefab = NodePlane.Content.infoItem
        for i=1,#rankList do
            local _item = utils.SGKTools.GetCopyUIItem(NodePlane.Content,_prefab,i)
            _item.title.Text[UI.Text].text=tostring(rankList[i][1])

            _item.Image:SetActive(i == 1)
            if i == 1 then
               local starInfo =  module.RankListModule.GetSelfStarInfo() 
               _item.infoText[UI.Text].text = starInfo and starInfo[1] or "0"
            elseif i == 2 then
                if module.traditionalArenaModule.GetSelfRankPos() then
                	local _pos = module.traditionalArenaModule.GetSelfRankPos()
                    _item.infoText[UI.Text].text = _pos ~= 0 and string.format("第%s名",_pos) or "暂无排名"
                else
                    _item.infoText[UI.Text].text ="暂无排名"
                end
            elseif i == 3 then
               _item.infoText[UI.Text].text =string.format("第%s波", module.trialModule.GetBattleConfig().gid - 60000000)
            elseif i == 4 then
                _item.infoText[UI.Text].text="暂无排名"
                PlayerInfoHelper.GetSelfPvpInfo(function (_desc)
                    if self.view then
                        _item.infoText[UI.Text].text = _desc
                    end
                end) 
            end
            -- if i==1 then
            --     _item.infoText[UI.Text].text="暂无排名"
            --     PlayerInfoHelper.GetSelfPvpInfo(function (_desc)
            --         if self.view then
            --             _item.infoText[UI.Text].text=tostring(_desc)
            --         end
            --     end)

            -- elseif i==2 then
            --     _item.infoText[UI.Text].text=tostring(PlayerInfoHelper.GetSelfUnionMemberTitle())
            -- end
        end
    elseif self.selectTabIdx==2 then
        local unionInfo=PlayerInfoHelper.GetSelfUnionInfo()
        NodePlane.union.gameObject:SetActive(not not  (unionInfo and next(unionInfo)~=nil))
        NodePlane.NoUnion.gameObject:SetActive(not  (unionInfo and next(unionInfo)~=nil))
        if not not  (unionInfo and next(unionInfo)~=nil) then
            for i=1,4 do
                if NodePlane.union.top[i] then
                    NodePlane.union.top[i].title.Text[UI.Text].text=tostring(unionInfoTab[i][1])
                    NodePlane.union.top[i].infoText[UI.Text].text=tostring(unionInfo and unionInfo[unionInfoTab[i][2]] or "无")
                end
            end
            NodePlane.union.bottom.declaration.gameObject:SetActive(next(unionInfo)~=nil)--("公会宣言:%s",unionInfo.notice~=""  and unionInfo.notice or "<color=#FFFFFF80>无</color>") or "")
            NodePlane.union.bottom.declaration.Text[UI.Text]:TextFormat("{0}",unionInfo and string.format("公会宣言:%s",unionInfo.notice~=""  and unionInfo.notice or "无") or "")
            NodePlane.union.bottom.goToBtn.Text[UI.Text].text="前往公会"

            NodePlane.union.bottom.goToBtn[CS.UGUIClickEventListener].interactable=not not  (unionInfo and next(unionInfo)~=nil) and openLevel.GetStatus(2101)
            
            CS.UGUIClickEventListener.Get(NodePlane.union.bottom.goToBtn.gameObject).onClick = function()
                if utils.SceneStack.CurrentSceneName()~="map_juntuan" then
                    -- if utils.SGKTools.GetTeamState() then
                    --    showDlgError(nil,"组队状态不能前往公会") 
                    -- else
                    --     SceneStack.EnterMap(25)
                    -- end
                    -- SceneStack.EnterMap(25)
                    DialogStack.Push("newUnion/newUnionFrame")
                else
                    showDlgError(nil,"你当前已在公会中")
                end
            end
        else
            NodePlane.NoUnion.tip.Text[UI.Text].text="未加入公会"
            NodePlane.NoUnion.findBtn.Text[UI.Text].text="查找公会"
            CS.UGUIClickEventListener.Get(NodePlane.NoUnion.findBtn.gameObject).onClick = function()
                if openLevel.GetStatus(2101) then
                    DialogStack.PushMapScene("newUnion/newUnionList")
                else
                    local _openLvCfg=openLevel.GetCfg(2101)
                    PlayerInfoHelper.GetSelfBaseInfo(function (player)
                        if player.level>=_openLvCfg.open_lev then
                            showDlgError(nil,_openLvCfg.functional_des)
                        else
                            showDlgError(nil,"等级不足")
                        end
                    end)  
                end
            end
        end
    elseif self.selectTabIdx==3 then
        local showSource =PlayerModule.GetShowSource()

        for i=1,NodePlane.Viewport.Content.transform.childCount do
            NodePlane.Viewport.Content.transform:GetChild(i-1).gameObject:SetActive(false)
        end

        local _prefab =NodePlane.Viewport.Content.infoItem.gameObject
        for i=1,#showSource do
            local _item = utils.SGKTools.GetCopyUIItem(NodePlane.Viewport.Content,_prefab,i)
            local _itemCfg = ItemHelper.Get(showSource[i].type, showSource[i].gid)
            _item.Icon[UI.Image]:LoadSprite("icon/".. _itemCfg.icon.."_small")
            _item.num.Text[UI.Text].text = tostring(ItemModule.GetItemCount(showSource[i].gid) or 0)
            _item.AddBtn.gameObject:SetActive(showSource[i].is_buy==1)
            CS.UGUIClickEventListener.Get(_item.Icon.gameObject).onClick = function()
                DialogStack.PushPrefStact("ItemDetailFrame", {id = _itemCfg.id,type = _itemCfg.type,InItemBag=2},UnityEngine.GameObject.FindWithTag("UGUIRoot").gameObject.transform)
            end

            CS.UGUIClickEventListener.Get(_item.AddBtn.gameObject).onClick = function()
                if openLevel.GetStatus(2401) then
                    DialogStack.Push("ShopFrame",{index =v.go_where});
                else
                    showDlgError(nil,"等级不足")
                end
            end
        end
    elseif self.selectTabIdx==4 then
        -- NodePlane.refshTip[UI.Text].text="每日0点刷新"
        local totalShowInfo = PlayerInfoHelper.GetTotalItemCfg()
        local _prefab = NodePlane.Viewport.Content.infoItem
        for i=1,NodePlane.Viewport.Content.transform.childCount do
            NodePlane.Viewport.Content.transform:GetChild(i-1).gameObject:SetActive(false)
        end

        for i=1,#totalShowInfo do
            local _item = utils.SGKTools.GetCopyUIItem(NodePlane.Viewport.Content,_prefab,i)
            local _info = totalShowInfo[i]

            _item.title[UI.Text].text = _info.name
            local _count = module.ItemModule.GetItemCount(_info.item_id) or 0
            _item.infoText[UI.Text]:TextFormat(_info.info,_info.item_toplimit-_count.."/".._info.item_toplimit)
            _item.infoBg[UI.Image].fillAmount = (_info.item_toplimit-_count)/tonumber(_info.item_toplimit)
        end
    end
end

function View:OnDestroy()
    self.view=nil
end

function View:listEvent()
    return {
        "PLAYER_INFO_CHANGE",
        "ITEM_INFO_CHANGE",
        "PLAYER_ADDDATA_CHANGE",
        "TRADITIONAL_ARENA_PLAYERINFO_CHANGE",
    }
end

function View:onEvent(event,data)
    if event == "PLAYER_INFO_CHANGE" then
        local pid=module.playerModule.GetSelfID() 
        if data and pid==data then
            self:upTop()
        end
    elseif event == "ITEM_INFO_CHANGE" then
        self:upBottom()
    elseif event == "PLAYER_ADDDATA_CHANGE" then
        local pid=module.playerModule.GetSelfID() 
        if data and pid==data then
            PlayerInfoHelper.GetPlayerAddData(0,nil,function (playerAddData)
                self:UpdatePlayerAddDataUI(playerAddData)
            end)
        end
    elseif event == "TRADITIONAL_ARENA_PLAYERINFO_CHANGE" then
        if self.selectTabIdx == 1 then
            self:upBottom()
        end
    end
end

return View