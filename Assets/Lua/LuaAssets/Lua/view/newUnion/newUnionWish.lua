local activityModule = require "module.unionActivityModule"
local ItemHelper = require "utils.ItemHelper"
local ItemModule = require "module.ItemModule"
local TipCfg = require "config.TipConfig"
local timeModule = require "module.Time"
local RewardItemShowCfg = require "config.RewardItemShow"

local newUnionWish = {}

function newUnionWish:initData()
    self.Manage = activityModule.WishManage
    self.nowIndex = 1
end

function newUnionWish:initUi()
    self.view = CS.SGK.UIReference.Setup(self.gameObject)
    self:initBtn()
    self:initTop()
    self:initLeft()
    self:initRight()
    self:initBottom()
    self:reset()
end

function newUnionWish:reset()
    local _day = timeModule.day()
    local _serverDay = timeModule.day(self.Manage:GetWishInfo().lastTime)
    if (self.Manage:GetWishInfo().has_draw_reward == 1 and _day > _serverDay) or  (self.Manage:GetWishInfo().lastTime == 0) then
        self.Manage:reset(0)
    end
end

function newUnionWish:initBtn()
    CS.UGUIClickEventListener.Get(self.view.root.closeBtn.gameObject).onClick = function()
        DialogStack.Pop()
    end
    CS.UGUIClickEventListener.Get(self.view.mask.gameObject, true).onClick = function()
        DialogStack.Pop()
    end
end

function newUnionWish:initTop()
    for i = 1, #self.view.root.group do
        self.view.root.group[i][UI.Toggle].onValueChanged:AddListener(function (value)
            if value then
                self.nowIndex = i
                self:upLeft()
            end
        end)
    end
end

function newUnionWish:initLeft()
    self.leftScrollView = self.view.root.left.ScrollView[CS.UIMultiScroller]
    self.leftScrollView.RefreshIconCallback = function(obj, idx)
        local _view = CS.SGK.UIReference.Setup(obj)
        local _tabCfg = nil
        if self.nowIndex == 1 then
            _tabCfg = self.wishInfoItem[idx+1]
        else
            _tabCfg = self.Manage:GetAssisList(idx+1)
        end

        if _tabCfg.pid then
            if module.playerModule.IsDataExist(_tabCfg.pid) then
                _view.playName[UI.Text].text = module.playerModule.IsDataExist(_tabCfg.pid).name.."的请求"
        	else
        		module.playerModule.Get(_tabCfg.pid,(function()
                    _view.playName[UI.Text].text = module.playerModule.IsDataExist(_tabCfg.pid).name.."的请求"
        		end))
        	end
        end
        _view.playName:SetActive(_tabCfg.pid and true)

        local _item1Cfg = ItemHelper.Get(_tabCfg.consume_type, _tabCfg.consume_id, nil, _tabCfg.consume_value)
        local _item2Cfg = ItemHelper.Get(41, 90006, nil, _tabCfg.cost)
        local _item1Count = ItemModule.GetItemCount(_tabCfg.consume_id)
        utils.IconFrameHelper.Create(_view.IconFrame, {pos = 2,id = _tabCfg.consume_id, type = _tabCfg.consume_type, showDetail = true, count = _tabCfg.consume_value,
        onClickFunc = function ( ... )
                DialogStack.PushPrefStact("ItemDetailFrame", {InItemBag=2,id = _tabCfg.consume_id,type = utils.ItemHelper.TYPE.ITEM})
            end
        })
        --_view.newItemIcon[SGK.newItemIcon]:SetInfo(_item1Cfg)
        --_view.newItemIcon[SGK.newItemIcon].showDetail = true
        _view.label[UI.Text].text = _item1Cfg.name
        --_view.btn1.icon[UI.Image]:LoadSprite("icon/".._item1Cfg.icon.."_small")
        --_view.btn1.number[UI.Text].text = tostring(_item1Count)
        _view.btn2.icon[UI.Image]:LoadSprite("icon/".._item2Cfg.icon.."_small")
        _view.btn2.number[UI.Text].text = tostring(_tabCfg.cost)

        _view.btn1[CS.UGUISelectorGroup]:reset()

        if _item1Count < _tabCfg.consume_value then
            _view.btn1.number[UI.Text].color = {r = 1, g = 0, b = 0, a = 1}
        else
            _view.btn1.number[UI.Text].color = {r = 1, g = 1, b = 1, a = 1}
        end

        if self.nowIndex == 1 then
            local _tab = self.wishInfoItem[idx+1]
            _view.btn1.unhaveLabel:SetActive(_item1Count < _tab.consume_value)
            _view.btn1.haveLabel:SetActive(_item1Count >= _tab.consume_value)
            _view.btn1.haveLabel[UI.Text]:TextFormat("上缴")
            _view.btn2.haveLabel[UI.Text]:TextFormat("上缴")
            if ItemModule.GetItemCount(_tab.consume_id) >= _tab.consume_value then
                _view.label2[UI.Text].text = string.format("当前拥有: %s", ItemModule.GetItemCount(_tab.consume_id))
            else
                _view.label2[UI.Text].text = string.format("当前拥有: <color=#FF0000>%s</color>", ItemModule.GetItemCount(_tab.consume_id))
            end

            CS.UGUIClickEventListener.Get(_view.btn1.gameObject).onClick = function()
                if _view.btn1.unhaveLabel.activeSelf then
                    if not self.wishInfoItem[idx+1].show then
                        showDlgError(nil, "已完成")
                        return
                    end
                    if self.wishInfoItem[idx+1].isHelp then
                        showDlgError(nil, "该物品已发布求助请求！")
                        return
                    end
                    if self.Manage:GetWishInfo().today_seek_help_count >= 3 then
                        showDlgError(nil, "您的求助次数不足！")
                        return
                    end
                    showDlg(nil, "今日还可求助<color=#d75d67>"..(3 - self.Manage:GetWishInfo().today_seek_help_count).."</color>次，是否求助？", function()
                        self.Manage:assist(_tab.index)
                    end,function()end)
                else
                    if ItemModule.GetItemCount(_tab.consume_id) >= _tab.consume_value then
                        self.Manage:upProgress(0, _tab.index)
                    else
                        showDlgError(nil, "道具不足")
                    end
                end
            end
            CS.UGUIClickEventListener.Get(_view.btn2.gameObject).onClick = function()
                if ItemModule.GetItemCount(90006) >= _tab.cost then
                    self.Manage:upProgress(1, _tab.index)
                    showDlgError(nil, "物品上交成功，今日进度+25%")
                else
                    showDlgError(nil, "道具不足")
                end
            end
        else
            local _tab = self.Manage:GetAssisList(idx+1)
            _view.btn1.haveLabel[UI.Text]:TextFormat("协助")
            _view.btn2.haveLabel[UI.Text]:TextFormat("协助")
            _view.btn1.unhaveLabel:SetActive(false)
            _view.btn1.haveLabel:SetActive(true)
            _view.label2[UI.Text].text = ""
            if ItemModule.GetItemCount(_tab.consume_id) < _tab.consume_value then
                _view.btn1[CS.UGUISelectorGroup]:setGray()
            end
            CS.UGUIClickEventListener.Get(_view.btn1.gameObject).onClick = function()
                if _tab.pid == module.playerModule.Get().id then
                    showDlgError(nil, "不能完成自己的协助请求")
                    return
                end
                if ItemModule.GetItemCount(_tab.consume_id) >= _tab.consume_value then
                    self.Manage:assistOther(0, _tab.pid, _tab.cfg_id, _tab.index, idx+1)
                else
                    showDlgError(nil, "道具不足")
                end
            end
            CS.UGUIClickEventListener.Get(_view.btn2.gameObject).onClick = function()
                if _tab.pid == module.playerModule.Get().id then
                    showDlgError(nil, "不能完成自己的协助请求")
                    return
                end
                if ItemModule.GetItemCount(90006) >= _tab.cost then
                    self.Manage:assistOther(1, _tab.pid, _tab.cfg_id, _tab.index, idx+1)
                else
                    showDlgError(nil, "道具不足")
                end
            end
        end
        obj:SetActive(true)
    end
    self:upLeft()
end

function newUnionWish:upLeft()
    if self.nowIndex == 1 then
        self.wishInfoItem = {}
        for i,v in ipairs(self.Manage:GetWishInfoItem()) do
            if v.show then
                table.insert(self.wishInfoItem, v)
            end
        end
        self.leftScrollView.DataCount = #self.wishInfoItem
    else
        self.leftScrollView.DataCount = #self.Manage:GetAssisList()
    end
    self.leftScrollView:ItemRef()
    self.view.root.left.max:SetActive(self.leftScrollView.DataCount == 0)
end

function newUnionWish:initRight()
    self.winshLog = self.view.root.right.ScrollView.Viewport.Content.log[UI.Text]
    self:upRight()
end

function newUnionWish:upRight()
    self.winshLog.text = ""
    for i,v in ipairs(self.Manage:GetLogList()) do
        local _text = string.format(TipCfg.GetAssistDescConfig(42001).info, v.name, v.otherName)
        self.winshLog.text = self.winshLog.text.._text.."\n"
    end
    SGK.Action.DelayTime.Create(0.2):OnComplete(function()
        self.view.root.right.ScrollView.Viewport.Content[UI.ContentSizeFitter].verticalFit = UnityEngine.UI.ContentSizeFitter.FitMode.Unconstrained
        self.view.root.right.ScrollView.Viewport.Content[UI.ContentSizeFitter].verticalFit = UnityEngine.UI.ContentSizeFitter.FitMode.PreferredSize
    end)

end

function newUnionWish:initBottom()
    self.Scrollbar = self.view.root.bottom.Scrollbar[UI.Scrollbar]
   -- ERROR_LOG("ding==========>>>",sprinttb(self.Manage:GetWishInfo()))
    CS.UGUIClickEventListener.Get(self.view.root.bottom.box.gameObject).onClick = function()
        
        if self.Manage:GetWishInfo(). has_draw_reward == 1 then
            showDlgError(nil, "今日已领取")
            return
        end
        if self.Manage:GetWishInfo().progress < #self.Manage:GetWishInfoItem() then
            DialogStack.PushPrefStact("mapSceneUI/GiftBoxPre", {itemTab = RewardItemShowCfg.Get(RewardItemShowCfg.TYPE.UNION_WISH), textName = "物资奖励",
			textDesc = ""})
            --textDesc = "完成补货("..self.Manage:GetWishInfo().progress.."/"..#self.Manage:GetWishInfoItem()..")后有概率获得上述奖励"})
            --showDlgError(nil, "上交所有的祭品后可以获得军需官的奖励")
            return
        end
        self.view.root.bottom.box[CS.UGUIClickEventListener].interactable = false
        self.view.root.bottom.box[UI.Image]:LoadSprite("icon/"..89014 .."-"..2)
        self.Manage:reward(function()
            self.view.root.bottom.box[CS.UGUIClickEventListener].interactable = true
        end)
    end
    CS.UGUIClickEventListener.Get(self.view.root.bottom.infoBtn.gameObject).onClick = function()
        utils.SGKTools.ShowDlgHelp(SGK.Localize:getInstance():getValue("juntuan_wuzi_shuoming_02"), SGK.Localize:getInstance():getValue("juntuan_wuzi_shuoming_01"))
    end
    self:upBottom()
end

function newUnionWish:upBottom()
    self.Scrollbar.size = self.Manage:GetWishInfo().progress / #self.Manage:GetWishInfoItem()
    for i = 1, #self.view.root.bottom.box do
        self.view.root.bottom.box[i]:SetActive(i == (self.Manage:GetWishInfo().progress + 1))
        if self.Manage:GetWishInfo().has_draw_reward == 1 then
            self.view.root.bottom.box[i]:SetActive(false)
            self.view.root.bottom.box[UI.Image]:LoadSprite("icon/"..89014 .."-"..2)
        end
    end
    if self.Manage:GetWishInfo().progress >= #self.Manage:GetWishInfoItem() then
        if not self.effectNode and self.Manage:GetWishInfo().has_draw_reward ~= 1 then
            self.effectNode = self:playEffect("fx_item_reward", nil, self.view.root.bottom.box)
        elseif self.effectNode then
            UnityEngine.Object.Destroy(self.effectNode)
        end
    end
end

function newUnionWish:playEffect(effectName, position, node, delete, sortOrder)
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

function newUnionWish:Start()
    self:initData()
    self:initUi()
    module.guideModule.PlayByType(17, 0.3)
end

function newUnionWish:listEvent()
    return {
        "LOCAL_WISHDATA_CHANGE",
        "LOCAL_ASSISTDATA_CHANGE",
        "LOCAL_WISHDATA_LOG_CHANGE",
        "LOCAL_UNIONACTIVITY_GETOVER",
        "LOCAL_GUIDE_CHANE",
    }
end

function newUnionWish:onEvent(event, data)
    if event == "LOCAL_WISHDATA_CHANGE" or event == "LOCAL_ASSISTDATA_CHANGE" then
        self:upLeft()
        self:upBottom()
    elseif event == "LOCAL_WISHDATA_LOG_CHANGE" then
        self:upRight()
    elseif event == "LOCAL_UNIONACTIVITY_GETOVER" then
        self:upBottom()
    elseif event == "LOCAL_GUIDE_CHANE" then
        module.guideModule.PlayByType(17, 0.3)
    end
end

return newUnionWish
