local unionConfig = require "config.unionConfig"
local unionModule = require "module.unionModule"
local newUnionInvestment = {}

function newUnionInvestment:Start()
    self:initData()
    self:initUi()
end

function newUnionInvestment:initUi()
    self.view = CS.SGK.UIReference.Setup(self.gameObject)
    CS.UGUIClickEventListener.Get(self.view.mask.gameObject, true).onClick = function()
        DialogStack.Pop()
    end
    CS.UGUIClickEventListener.Get(self.view.root.bg.closeBtn.gameObject).onClick = function()
        DialogStack.Pop()
    end
    CS.UGUIClickEventListener.Get(self.view.root.infoBtn.gameObject).onClick = function()
        DialogStack.PushPrefStact("newUnion/newUnionExpLog")
    end
    self.giftSlider = self.view.root.middle.giftRoot.Slider[UI.Slider]
    self:initMiddle()
    self:upMiddle()
    self:initGift()
end

function newUnionInvestment:playEffect(effectName, position, node, delete, sortOrder)
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

function newUnionInvestment:initGift()
    for i = 1, #self.view.root.middle.giftRoot.giftBtn do
        local _view = self.view.root.middle.giftRoot.giftBtn[i]
        CS.UGUIClickEventListener.Get(_view.gameObject).onClick = function()
            local _memb = module.unionModule.Manage:GetSelfInfo().awardFlag
            if _memb[i] == 1 then
                showDlgError(nil, "该奖励已领取！")
            else
                DialogStack.PushPrefStact("newUnion/item/unionGiftBox", {type = 1, index = i})
            end
        end
    end
    self.giftSlider = self.view.root.middle.giftRoot.Slider[UI.Slider]
    self:upGift()
end

function newUnionInvestment:initMiddle()

    
    local sciene_lev = module.unionScienceModule.GetScienceInfo(24) and module.unionScienceModule.GetScienceInfo(24).level or 0
    for i = 1, #self.view.root.middle.itemNode do
        local _view = self.view.root.middle.itemNode[i]
        _view.name[UI.Text].text = unionConfig.GetDonate(i).Name
        _view.btn.number[UI.Text].text = tostring(unionConfig.GetDonate(i).ExpendItemValue)
        local _iconId = utils.ItemHelper.Get(unionConfig.GetDonate(i).ExpendItemType, unionConfig.GetDonate(i).ExpendItemID).icon
        _view.btn.icon[UI.Image]:LoadSprite("icon/".._iconId.."_small")
        local _table = unionConfig.GetDonate(i)
        for k = 1, 2 do
            local _diObj = UnityEngine.GameObject.Instantiate(_view.labelNode.Text.gameObject, _view.labelNode.gameObject.transform)
            local _diView = CS.SGK.UIReference.Setup(_diObj)
            local _key = ""
            local _value = ""
            if _table then
                if k == 1 then
                    _key = _table.BuildExpName
                    _value = tostring(_table.BuildExp)
                else
                    _key = utils.ItemHelper.Get(_table.ItemType, _table.ItemID).name
                    _value = tostring(_table.Value)
                end
            end
            _diView[UI.Text].text = _key
            _diView.value[UI.Text].text = "+".._value
            _diObj.gameObject:SetActive(true)
        end

        CS.UGUIClickEventListener.Get(_view.btn.gameObject).onClick = function()
            if module.unionModule.Manage:GetSelfInfo().todayDonateCount >= (sciene_lev +1) then
                showDlgError(nil, "今日剩余投资次数不足，请明天再来吧！")
                return
            end
            if module.ItemModule.GetItemCount(unionConfig.GetDonate(i).ExpendItemID) < unionConfig.GetDonate(i).ExpendItemValue then
                showDlgError(nil, "您的资产不足，无法投资！")
                return
            end
            _view.btn[CS.UGUIClickEventListener].interactable = false
            _view.btn[UI.Image].material = SGK.QualityConfig.GetInstance().grayMaterial
            module.unionModule.Donate(i, function()
                _view.btn[UI.Image].material = nil
                _view.btn[CS.UGUIClickEventListener].interactable = true
            end)
        end
    end


end

function newUnionInvestment:upMiddle()
    local sciene_lev = module.unionScienceModule.GetScienceInfo(24) and module.unionScienceModule.GetScienceInfo(24).level or 0

    if module.unionModule.Manage:GetSelfInfo().todayDonateCount and module.unionModule.Manage:GetSelfInfo().todayDonateCount < sciene_lev+1 then
        self.view.root.Text[UI.Text].text = SGK.Localize:getInstance():getValue("guild_donate_info1","<color=#00FF00>"..(sciene_lev+1 - (module.unionModule.Manage:GetSelfInfo().todayDonateCount or 0)).."/"..(sciene_lev+1).."</color>");
    else
        self.view.root.Text[UI.Text].text = SGK.Localize:getInstance():getValue("guild_donate_info1","<color=#FF0000>"..(sciene_lev+1 - (module.unionModule.Manage:GetSelfInfo().todayDonateCount or 0)).."/"..(sciene_lev+1).."</color>");
    end
    -- self.view.root.Text[UI.Text].text = SGK.Localize:getInstance():getValue("guild_donate_info1",module.unionModule.Manage:GetSelfInfo().todayDonateCount,sciene_lev+1);
    ERROR_LOG(module.unionModule.Manage:GetSelfInfo().todayDonateCount)
    
    for i =1, #self.view.root.middle.itemNode do
        local _view = self.view.root.middle.itemNode[i]
        local _material = _view.btn[CS.UnityEngine.MeshRenderer].materials[0]
        if module.unionModule.Manage:GetSelfInfo().todayDonateCount and module.unionModule.Manage:GetSelfInfo().todayDonateCount >= (sciene_lev +1) then
            _view.btn[UI.Image].material = _material
        else
            _view.btn[UI.Image].material = nil
        end
    end
end

function newUnionInvestment:getNowAddExp()
    local _count = 0
    local _addExp = 0
    for i = 1, 3 do
        local _exp = unionConfig.GetTeamAward(i, module.unionModule.Manage:GetSelfUnion().unionLevel).condition_value
        if module.unionModule.Manage:GetSelfUnion().todayAddExp > _exp then
            _count = _count + 1
        end
    end
    if _count ~= 0 then
        _addExp = _count
    else
        _addExp = 0
    end
    if _count < 3 then
        _addExp = _addExp + ((module.unionModule.Manage:GetSelfUnion().todayAddExp / unionConfig.GetTeamAward(_count+1, module.unionModule.Manage:GetSelfUnion().unionLevel).condition_value))
    end

    print(_addExp);
    return _addExp
end

function newUnionInvestment:upGift()
    local _max = unionConfig.GetTeamAward(3, module.unionModule.Manage:GetSelfUnion().unionLevel).condition_value
    self.giftSlider.maxValue = 3
    self.giftSlider.value = self:getNowAddExp()
    self.view.root.middle.giftRoot.Slider.Image.Text[UI.Text].text=unionModule.Manage:GetSelfUnion().todayAddExp
    for i = 1, 3 do

        local _view = self.view.root.middle.giftRoot.giftBtn[i]
        local _memb = module.unionModule.Manage:GetSelfInfo().awardFlag or {}
        local _bgContainer = self.view.root.middle.giftRoot.Slider.Container[i+1]
        local _conditionValue = unionConfig.GetTeamAward(i, module.unionModule.Manage:GetSelfUnion().unionLevel).condition_value
        _bgContainer.Text[UI.Text].text=_conditionValue
        _view.get:SetActive(false)
        _view.have:SetActive(false)
        _view.unHave:SetActive(false)

        _bgContainer[CS.UGUISpriteSelector].index = 1
        if _memb[i] == 1 then
            _bgContainer[CS.UGUISpriteSelector].index = 0
            _view.get:SetActive(true)
        else
            if _conditionValue <= module.unionModule.Manage:GetSelfUnion().todayAddExp then
                _bgContainer[CS.UGUISpriteSelector].index = 0
                _view.have:SetActive(true)
                if not self.effectTab[i] then
                    self.effectTab[i] = self:playEffect("fx_item_reward", Vector3(0, 0, 0), _view.have.gameObject)
                end
            else
                _view.unHave:SetActive(true)
                _view.unHave[UI.Image].material=SGK.QualityConfig.GetInstance().grayMaterial
            end
        end
        _bgContainer[CS.UGUISpriteSelector].index = 0
    end
end

function newUnionInvestment:listEvent()
    return {
        "LOCAL_UNION_REWARD_GET",
        "LOCAL_UNION_UPDATE_UI",
        "LOCAL_UNION_EXP_CHANGE",
        "LOCAL_UNION_INFO_CHANGE",
    }
end

function newUnionInvestment:onEvent(event, data)
    if event == "LOCAL_UNION_UPDATE_UI" or event == "LOCAL_UNION_EXP_CHANGE" or event == "LOCAL_UNION_INFO_CHANGE" then
        self:upMiddle()
        self:upGift()
    elseif event == "LOCAL_UNION_REWARD_GET" then
        if data.typeId == 1 then
            if self.effectTab[data.index] then
                self:playEffect("fx_box_kai_blue", Vector3(0, 0, 0), self.effectTab[data.index].transform.parent.parent, true)
                UnityEngine.GameObject.Destroy(self.effectTab[data.index])
            end
        end
    end
end

function newUnionInvestment:initData()
    self.effectTab = {}
end

return newUnionInvestment
