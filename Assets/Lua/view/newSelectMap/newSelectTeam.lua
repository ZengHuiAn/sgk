local activityConfig = require "config.activityConfig"
local equipConfig = require "config.equipmentConfig"
local HeroScroll = require "hero.HeroScroll"
local CemeteryConf = require "config.cemeteryConfig"
local SmallTeamDungeonConf = require "config.SmallTeamDungeonConf"
local openLevel = require "config.openLevel"

local newSelectTeam = {}

function newSelectTeam:Start(data)
    --self:init(data)
end

function newSelectTeam:init(data)
    if not data then
        return
    end 
    self:initData(data)
    self:initUi()
    self:initGuide()
end

function newSelectTeam:initGuide()
    module.guideModule.PlayByType(102,0.2)
end

function newSelectTeam:initData(data)
    if data then
        self.chapterId = data.chapterId
    end
    self.cfg = activityConfig.GetAllActivityTitle(4, self.chapterId) or {}
    table.sort(self.cfg, function(a, b)
        if a.lv_limit == b.lv_limit then
            return a.id > b.id
        end
        return a.lv_limit < b.lv_limit
    end)
end

function newSelectTeam:initUi()
    self.view = CS.SGK.UIReference.Setup(self.gameObject)
    self:initTop()
    self:initScrollView()
end

function newSelectTeam:initTop()
    local _itemList = {
        [1] = {id = 90023},
        [2] = {id = 90024},
    }
    for i = 1, 2 do
        local _view = self.view.root["item"..i]
        _view.number[UI.Text].text = tostring(module.ItemModule.GetItemCount(_itemList[i].id))
        CS.UGUIClickEventListener.Get(_view.gameObject).onClick = function()
            DialogStack.PushPrefStact("ItemDetailFrame", {id = _itemList[i].id, type = utils.ItemHelper.TYPE.ITEM, InItemBag = 2},UnityEngine.GameObject.FindWithTag("UITopRoot").gameObject)
        end
    end
    if openLevel.GetStatus(1331) then
        self.view.root.luckBtn:SetActive(true)
    else
        self.view.root.luckBtn:SetActive(false)
    end
    CS.UGUIClickEventListener.Get(self.view.root.luckBtn.gameObject).onClick = function()
        DialogStack.PushPref("fightResult/luckyCoin") 
    end
end

function newSelectTeam:initScrollView()
    self.scrollView = self.view.root.ScrollView[CS.UIMultiScroller]
    self.scrollView.RefreshIconCallback = function (obj, idx)
        local _view = CS.SGK.UIReference.Setup(obj.gameObject)
        local _cfg = self.cfg[idx + 1]
        local pic_cfg = CemeteryConf.Getteam_battle_conf(_cfg.id)
        --print(sprinttb(pic_cfg))
        --_view.root.icon[UI.Image]:LoadSprite("guanqia/".._cfg.use_picture)
        _view.root.IconMask.icon[UI.Image]:LoadSpriteWithExt("guanqia/"..pic_cfg.bg_xditu..".jpg")
        if pic_cfg.bg_xditu_2 and pic_cfg.bg_xditu_2 ~= "" and pic_cfg.bg_xditu_2 ~= "0" then
            _view.root.IconMask.icon2:SetActive(true)
            _view.root.IconMask.icon2[UI.Image]:LoadSpriteWithExt("guanqia/"..pic_cfg.bg_xditu_2..".png")
        else
            _view.root.IconMask.icon2:SetActive(false)
        end

        _view.root.name[UI.Text].text = _cfg.name
        _view.root.time[UI.Text].text = _cfg.activity_time
        local _reward = activityConfig.GetReward(_cfg.id) or {}
        --_view.root.ScrollView[CS.UIMultiScroller].RefreshIconCallback = function (rObj, rIdx)
        for rIdx=0,#_reward-1 do
            local rObj = _view.root.item
            local _rView = CS.SGK.UIReference.Setup(rObj.gameObject)
            local _rCfg = _reward[rIdx + 1]
            local _equip = equipConfig.GetConfig(_rCfg.id)
            _rView.IconFrame:SetActive(false)
            _rView.suit:SetActive(false)
            --if _equip then
                local _icon = utils.IconFrameHelper.Create(_rView,{id = _rCfg.id,type = _rCfg.type,showDetail = true})
                _icon[UnityEngine.RectTransform].anchoredPosition = CS.UnityEngine.Vector2(0,0)
                -- local suitTab = HeroScroll.GetSuitConfig(_equip.suit_id)
                -- if suitTab and next(suitTab) ~= nil then
                --     local suitCfg = suitTab[2][_equip.quality]
                --     if suitCfg then
                --         _rView.suit:SetActive(true)

                --         _rView.suit.Frame[CS.UGUISpriteSelector].index = _equip.quality -1
                --         _rView.suit.Icon[UI.Image]:LoadSprite("icon/"..suitCfg.icon)
                --         -- utils.IconFrameHelper.Create(_rView.IconFrame, {customCfg = {
                --         --         icon    = suitCfg.icon,
                --         --         role_stage = -1,
                --         --         star    = 0,
                --         --         level   = 0,
                --         -- }, type = 42})

                --         CS.UGUIClickEventListener.Get(_rView.suit.gameObject).onClick = function()
                --             DialogStack.PushPrefStact("dataBox/suitsManualFrame", {suitId = _equip.suit_id,hideSuits = true,quality = _equip.quality})
                --         end
                --     end
                -- end
            --else
                --ERROR_LOG(_cfg.id, _rCfg.id, "error")
            --end
            rObj:SetActive(true)
        end
        --_view.root.ScrollView[CS.UIMultiScroller].DataCount = #_reward
        _view.root.bg:SetActive(not (_cfg.lv_limit > module.HeroModule.GetManager():Get(11000).level))
        _view.root.difficulty:SetActive(_cfg.id > 1000 and (_cfg.lv_limit <= module.HeroModule.GetManager():Get(11000).level))
        --_view.root.difficulty:SetActive(_cfg.id > 1000)
        _view.root.name:SetActive(not (_cfg.lv_limit > module.HeroModule.GetManager():Get(11000).level))
        _view.root.lock:SetActive(_cfg.lv_limit > module.HeroModule.GetManager():Get(11000).level)
        local _battleCfg = SmallTeamDungeonConf.GetTeam_pve_fight(_cfg.isunique)
        local _count = module.CemeteryModule.GetTEAMRecord(_battleCfg.idx[1][1].gid) or 0
        --print("kkkkk",_battleCfg.idx[1][1].drop1,module.ItemModule.GetItemCount(_battleCfg.idx[1][1].drop1))
        _view.root.tip:SetActive((not _view.root.lock.activeSelf) and _count == 0)
        _view.root.ExtraReward:SetActive(module.ItemModule.GetItemCount(_battleCfg.idx[1][1].drop1) ~= 0 and (not (_cfg.lv_limit > module.HeroModule.GetManager():Get(11000).level)))
        if _view.root.lock.activeSelf then
            _view.root.IconMask.icon[UI.Image].color = {r = 94 / 255, g = 94 / 255, b = 94 / 255, a = 1}
            _view.root.IconMask.icon2[UI.Image].color = {r = 94 / 255, g = 94 / 255, b = 94 / 255, a = 1}
        else
            _view.root.IconMask.icon[UI.Image].color = {r = 1, g = 1, b = 1, a = 1}
            _view.root.IconMask.icon2[UI.Image].color = {r = 1, g = 1, b = 1, a = 1}
        end
        --_view.root.ScrollView:SetActive(not _view.root.lock.activeSelf)
        if _view.root.lock.activeSelf then
            _view.root.lock.info[UI.Text].text = SGK.Localize:getInstance():getValue("tips_lv_02", _cfg.lv_limit)
        end
        local _one, _ten = module.CemeteryModule.Query_Pve_Schedule(_cfg.id)
        -- _view.root.double:SetActive(_ten and _ten > 0 and not _view.root.lock.activeSelf)
        -- if _ten and _ten > 0 then
        --     _view.root.double.number[UI.Text].text = tostring(_ten)
        -- end
        _view.root.double:SetActive(false)
        CS.UGUIClickEventListener.Get(_view.root.IconMask.icon.gameObject).onClick = function()
            if not _view.root.lock.activeSelf then
                module.guideModule.SelectChapterGuide[self.chapterId] = idx + 1
                --DialogStack.Push("TeamPveEntrance", {gid = _cfg.isunique})
                DialogStack.Push("newSelectMap/activityInfo", {gid = _cfg.isunique})
            else
                showDlgError(nil, "等级不足")
            end
        end
        obj:SetActive(true)
    end

    local TotalHeight = self.view.root.ScrollView[UnityEngine.RectTransform].rect.height--sizeDelta.y
    local Item_Height = CS.SGK.UIReference.Setup(self.scrollView.itemPrefab)[UnityEngine.RectTransform].sizeDelta.y
    
    self.scrollView.DataCount = #self.cfg
    if module.guideModule.SelectChapterGuide[self.chapterId] then
        local _idx = module.guideModule.SelectChapterGuide[self.chapterId]
        if _idx - 1 > math.abs(math.floor(TotalHeight/Item_Height)) then
            self.scrollView:ScrollMove(_idx - 1 - math.abs(math.floor(TotalHeight/Item_Height)))
        end
        --self.scrollView:ScrollMove(module.guideModule.SelectChapterGuide[self.chapterId] - 1 - 1)
    else
        local _idx = 1
        for i,v in ipairs(self.cfg) do
            if v.lv_limit > module.HeroModule.GetManager():Get(11000).level then
                _idx = i
                break
            end
        end
        if _idx-1 > math.abs(math.floor(TotalHeight/Item_Height)) then
            self.scrollView:ScrollMove(_idx - 1 - math.abs(math.floor(TotalHeight/Item_Height)))
            --self.scrollView:ScrollMove(_idx - 1 - 1)
        end
    end
end

function newSelectTeam:listEvent()
    return {
        "LOCAL_GUIDE_CHANE",
    }
end

function newSelectTeam:onEvent(event, data)
    if event == "LOCAL_GUIDE_CHANE" then
        self:initGuide()
    end
end

return newSelectTeam
