local RankListModule = require "module.RankListModule"
local PlayerModule = require "module.playerModule"
local UnionModule = require "module.unionModule"
local PVPArenaModule = require "module.PVPArenaModule"
local OpenLevel = require "config.openLevel"
local rankListFrame = {}

local Type = {
    Level = 1,
    Star = 2,
    Wealth = 3,--财力值
    TrialTower = 4,--爬塔
}
function rankListFrame:Start(rankType)
    self.root = CS.SGK.UIReference.Setup(self.gameObject)
    self.view=self.root.view

    self.rankType=rankType or self.savedValues.Selected_type or 1
    self.rangeIdx=self.savedValues.Selected_range or 1

    self.view.title[UI.Text].text=SGK.Localize:getInstance():getValue("biaoti_paihangbang_01")

    self.ranklistTab={}

    self.TotalHeight=self.view.ScrollView[UnityEngine.RectTransform].sizeDelta.y
    self:initUi()
    self:upRankTypeList()
    self:UpUIShow()
end

function rankListFrame:initUi()
    CS.UGUIClickEventListener.Get(self.root.mask.gameObject, true).onClick = function()
        DialogStack.Pop()
    end
    CS.UGUIClickEventListener.Get(self.view.closeBtn.gameObject).onClick = function()
        DialogStack.Pop()
    end
    CS.UGUIClickEventListener.Get(self.view.giftBox.gameObject).onClick = function()
        DialogStack.Push("rankList/rankGiftFrame",{type = self.rankType})
    end
end

function rankListFrame:upRankTypeList()
    local rankCfgList=RankListModule.GetRankCfg()
    self.UIDragTypeIconScript = self.view.bottom.ScrollView[CS.UIMultiScroller]
    self.UIDragTypeIconScript.RefreshIconCallback = function (obj, idx)
        local Item = CS.SGK.UIReference.Setup(obj.gameObject)
        local _cfg = rankCfgList[idx + 1]

        Item.Background.Icon[UI.Image]:LoadSprite("rankList/".._cfg.icon)
        Item.label[UI.Text].text=SGK.Localize:getInstance():getValue(_cfg.rank_name)
        Item[UI.Toggle].isOn=self.rankType==_cfg.rank_type
        
        Item.Background.Checkmark.Image:SetActive(self.rankType==_cfg.rank_type)
        if self.rankType==_cfg.rank_type then
            self.SelectIdx=idx

            Item.Background.Icon[UI.Image].material = nil
            local _, color= UnityEngine.ColorUtility.TryParseHtmlString('#FFD800FF');
            Item.label[UI.Text].color=color--_yellow
        else
            Item.Background.Icon[UI.Image].material = SGK.QualityConfig.GetInstance().grayMaterial
            local _, color= UnityEngine.ColorUtility.TryParseHtmlString('#FFFFFFFF');
            Item.label[UI.Text].color=color--_white
        end
        CS.UGUIClickEventListener.Get(Item.gameObject).onClick = function()
            if self.rankType~=_cfg.rank_type then
                --Item[UI.Toggle].isOn = true

                if self.SelectIdx then
                    local selectIcom= CS.SGK.UIReference.Setup(self.UIDragTypeIconScript:GetItem(self.SelectIdx))
                    selectIcom.Background.Checkmark.Image:SetActive(false)
                    selectIcom.Background.Icon[UI.Image].material = SGK.QualityConfig.GetInstance().grayMaterial
                    
                    local _, color= UnityEngine.ColorUtility.TryParseHtmlString('#FFFFFFFF');
                    selectIcom.label[UI.Text].color=color--_white
                end

                Item.Background.Checkmark.Image:SetActive(true)
                Item.Background.Icon[UI.Image].material =nil
                local _, color= UnityEngine.ColorUtility.TryParseHtmlString('#FFD800FF');
                Item.label[UI.Text].color=color--_yellow

                self.SelectIdx=idx

                self.rankType=_cfg.rank_type
                self:UpUIShow()
            end
        end
        obj:SetActive(true)
    end
    self.UIDragTypeIconScript.DataCount = #rankCfgList
end

function rankListFrame:UpUIShow()
    self:upRankList()
    self:upDropDownList()
end

local Number = {"Ⅰ","Ⅱ","Ⅲ","Ⅳ","Ⅴ","Ⅵ","Ⅶ","Ⅷ","Ⅸ"}
function rankListFrame:upRankList()
    local rankListInfo=RankListModule.GetRankList(self.rankType,self.rangeIdx)

    if not rankListInfo then return end
    local list     = rankListInfo.list
    local selfRank = rankListInfo.selfRank
    local selfPid  = PlayerModule.GetSelfID()
    local Item_Height=self.view.selfRankItem[UnityEngine.RectTransform].sizeDelta.y
    --self.view.ScrollView[UnityEngine.RectTransform].sizeDelta=CS.UnityEngine.Vector2(self.view.ScrollView[UnityEngine.RectTransform].sizeDelta.x,(selfRank and 7 or 6)*Item_Height+5)
    --self.view.ScrollView.Viewport[UnityEngine.RectTransform].sizeDelta=CS.UnityEngine.Vector2(self.view.ScrollView[UnityEngine.RectTransform].sizeDelta.x,Item_Height) 
    local UnShowSelfItem=false
    if self.rankType==Type.Wealth then
        if OpenLevel.GetStatus(1901) and module.ItemModule.GetItemCount(90033) > 0 then
            UnShowSelfItem=selfRank
        else
            UnShowSelfItem=true
        end
    elseif self.rankType==Type.TrialTower then
        if module.playerModule.Get().level >=OpenLevel.GetCfg(3101).open_lev then
            UnShowSelfItem=selfRank
        else
            UnShowSelfItem=true
        end
    else
        UnShowSelfItem=selfRank
    end

    self.UIDragIconScript = self.view.ScrollView[CS.UIMultiScroller]
    if next(rankListInfo)~=nil then
        self.view.ScrollView[UnityEngine.RectTransform]:SetSizeWithCurrentAnchors(UnityEngine.RectTransform.Axis.Vertical,UnShowSelfItem and self.TotalHeight or self.TotalHeight-Item_Height);
        self.UIDragIconScript.RefreshIconCallback = function (obj, idx)
            local Item = CS.SGK.UIReference.Setup(obj.gameObject)
            local _cfg = list[idx + 1]

            Item.Image[CS.UGUISpriteSelector].index =_cfg.pid==selfPid and 1 or 0
            if _cfg.pid > 110000 or _cfg.pid < 100000 then
                utils.IconFrameHelper.Create(Item.IconFrame, {pid= _cfg.pid})
                if PlayerModule.IsDataExist(_cfg.pid) then
                    Item.name.Text[UI.Text].text=PlayerModule.IsDataExist(_cfg.pid).name
                else
                    PlayerModule.Get(_cfg.pid,(function( ... )
                        if PlayerModule.IsDataExist(_cfg.pid) then
                            Item.name.Text[UI.Text].text=PlayerModule.IsDataExist(_cfg.pid).name
                        else
                            ERROR_LOG("playerData is nil, pid",_cfg.pid)
                        end
                    end))
                end

                local unionName = UnionModule.GetPlayerUnioInfo(_cfg.pid).unionName
                if unionName then
                    Item.union.Text[UI.Text].text="<color=#FEBA00>"..unionName.."</color>"
                else
                    UnionModule.queryPlayerUnioInfo(_cfg.pid,(function ( ... )
                        if self.view then
                            unionName = UnionModule.GetPlayerUnioInfo(_cfg.pid).unionName or "无"
                            Item.union.Text[UI.Text].text = "<color=#FEBA00>"..unionName.."</color>"
                        end
                    end))
                end
            else
                local npc_config = PVPArenaModule.GetNPCStatus(_cfg.pid);
                if npc_config then
                    local headIconCfg = module.ItemModule.GetShowItemCfg(npc_config.cfg.HeadFrameId)
                    local headFrame = headIconCfg and headIconCfg.effect
                    utils.IconFrameHelper.Create(Item.IconFrame,{customCfg = {head = npc_config.cfg.icon, level = npc_config.heros[1].level, vip = npc_config.cfg.vip_lv , pid = _cfg.pid, HeadFrame = headFrame}})
                    Item.name.Text[UnityEngine.UI.Text].text = npc_config.cfg.name; 
                end
                Item.union.Text[UnityEngine.UI.Text]:TextFormat("无");
            end

            self:upRankItem(Item,_cfg.value,idx)
            obj:SetActive(true)
        end
        self.UIDragIconScript.DataCount = #list
        self.UIDragIconScript:ScrollMove(0)
        self.view.selfRankItem:SetActive(not UnShowSelfItem)
        if selfRank then
            if selfRank-math.floor(self.TotalHeight/Item_Height)>0 then
                self.UIDragIconScript:ScrollMove(selfRank-math.floor(self.TotalHeight/Item_Height)) 
            end
        else
            self.view.selfRankItem.name.Text[UI.Text].text=PlayerModule.IsDataExist(selfPid).name
            utils.IconFrameHelper.Create(self.view.selfRankItem.IconFrame, {pid= selfPid})
            local unionName = UnionModule.GetPlayerUnioInfo(selfPid).unionName
            if unionName then
                self.view.selfRankItem.union.Text[UI.Text].text="<color=#FEBA00>"..unionName.."</color>"
            else
                UnionModule.queryPlayerUnioInfo(selfPid,(function ( ... )
                    if self.view then
                        unionName = UnionModule.GetPlayerUnioInfo(selfPid).unionName or "无"
                        self.view.selfRankItem.union.Text[UI.Text].text = "<color=#FEBA00>"..unionName.."</color>"
                    end
                end))
            end
            
            if self.rankType==Type.Level then
                self.view.selfRankItem.value.staticText.Text[UI.Text].text=PlayerModule.IsDataExist(selfPid).level
            elseif self.rankType==Type.Star then
                self.view.selfRankItem.value.starText[UI.Text].text=PlayerModule.IsDataExist(selfPid).starPoint
            elseif self.rankType==Type.Wealth then
                self.view.selfRankItem.otherValue.Text[UI.Text].text="暂无排名"
                self.view.selfRankItem.value:SetActive(false)
                if not UnShowSelfItem then
                    utils.PlayerInfoHelper.GetSelfPvpInfo(function (desc,pvpInfo)
                        if self.view then
                            self.view.selfRankItem.value:SetActive(true)
                            self.view.selfRankItem.value.staticText.Text[UI.Text].text=self:GetWealthString(pvpInfo.wealth)
                            local str,stage,num = module.PVPArenaModule.GetRankName(pvpInfo.wealth)
                            self.view.selfRankItem.otherValue.Text[UI.Text]:TextFormat("{0}{1}",str,Number[num])
                        end
                    end) 
                end
            elseif self.rankType==Type.TrialTower then
                self.view.selfRankItem.value.staticText.Text[UI.Text].text=PlayerModule.IsDataExist(selfPid).floor
            end

            self:upRankItem(self.view.selfRankItem,nil,9999)
        end
    else 
        self.view.selfRankItem:SetActive(false)
        self.UIDragIconScript.DataCount=0
    end 
end

function rankListFrame:upRankItem(Item,value,rank) 
    Item.union[UI.Text].text = SGK.Localize:getInstance():getValue("paihangbang_tiaomu_02")
    Item.name[UI.Text].text = SGK.Localize:getInstance():getValue("paihangbang_tiaomu_01")
    Item.otherValue[UI.Text].text = SGK.Localize:getInstance():getValue("paihangbang_tiaomu_05")
    Item.value.staticText:SetActive(self.rankType==Type.Level or self.rankType==Type.Wealth or self.rankType==Type.TrialTower)
    if self.rankType~=Type.Star then
        Item.value.staticText[UI.Text].text = SGK.Localize:getInstance():getValue(self.rankType==Type.Level and "paihangbang_tiaomu_03" or self.rankType==Type.Wealth and "paihangbang_tiaomu_04" or self.rankType==Type.TrialTower and "paihangbang_tiaomu_06")
    end
    Item.value.starText:SetActive(self.rankType==Type.Star)
    Item.value.Image:SetActive(self.rankType==Type.Star)

    Item.otherValue:SetActive(self.rankType==Type.Wealth)

    if value then
        if self.rankType==Type.Level then
            Item.value.staticText.Text[UI.Text].text=value
        elseif self.rankType==Type.Wealth then 
            Item.value.staticText.Text[UI.Text].text=self:GetWealthString(value)
            local str,stage,num = module.PVPArenaModule.GetRankName(value)
            Item.otherValue.Text[UI.Text]:TextFormat("{0}{1}",str,Number[num])
        elseif self.rankType==Type.Star then
            Item.value.starText[UI.Text].text=value
        elseif self.rankType==Type.TrialTower then
            Item.value.staticText.Text[UI.Text].text=value
        end
    end
    Item.rankPlace.Text:SetActive(rank>=3)
    Item.rankPlace.Image:SetActive(rank<3)
    if rank<3 then
        Item.rankPlace.Image[CS.UGUISpriteSelector].index=rank 
    end
    Item.rankPlace.Text[UI.Text].text=rank<9999 and string.format("第%s名",rank+1) or "未上榜"
end

function rankListFrame:GetWealthString(wealth)
    local yi = math.floor(wealth/100000000);
    local wan = math.floor((wealth - yi * 100000000)/10000);
    return (yi > 0 and yi.."亿" or "")..( wan > 0 and wan.."万" or "");
end

function rankListFrame:upDropDownList()
    for i=1,self.view.bottom.filter.transform.childCount do
        self.view.bottom.filter[i].gameObject:SetActive(false)
    end
    local rankCfgList=RankListModule.GetRankCfg(self.rankType)
    for i=1,#rankCfgList do
        self.view.bottom.filter[i].gameObject:SetActive(next(rankCfgList[i])~=nil)
        self.view.bottom.filter[i][UI.Dropdown]:ClearOptions()
        for k,v in pairs(rankCfgList[i]) do
            if k==self.rangeIdx then
                self.view.bottom.filter[i].Label[UI.Text].text=SGK.Localize:getInstance():getValue(v)
            end
            self.view.bottom.filter[i][SGK.DropdownController]:AddOpotion(SGK.Localize:getInstance():getValue(v))
        end
        self.view.bottom.filter[i][UI.Dropdown].onValueChanged:AddListener(function (i)
            if i~= self.rangeIdx-1 then
                self.rangeIdx=i+1
                self:upRankList()
            end
        end)
    end
end

function rankListFrame:OnDestroy()
    self.savedValues.Selected_type=self.rankType
    self.savedValues.Selected_range=self.rangeIdx
    self.view=nil
end

function rankListFrame:listEvent()
    return {
        "RANK_LIST_CHANGE",
        "RANK_FRIENDLIST_CHANGE",    
    }
end

function rankListFrame:onEvent(event,data)
    if event == "RANK_LIST_CHANGE" then
        if self.rankType ==data then
            self:upRankList()
        end
    elseif event == "RANK_FRIENDLIST_CHANGE" then
        self:upRankList()
    end
end

return rankListFrame
