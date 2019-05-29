local heroModule = require "module.HeroModule"
local playerModule = require "module.playerModule"
local NameCfg = require "config.nameConfig"
local PlayerInfoHelper = require "utils.PlayerInfoHelper"
local TipCfg = require "config.TipConfig"

local createCharacter = {}

function createCharacter:initData(data)
    if data then
        self.func = data.func
    end
    self.iconTab = {}
    local _sex = 0
    for i,v in pairs(PlayerInfoHelper.GetModeCfg()) do
        if not v.isLocked and _sex == v.sex then
            table.insert(self.iconTab, {id = i, cfg = v})
        end
    end
    self.selectIndex = 11048
end

function createCharacter:upData()
    self.iconTab = {}
    local _sex = self:getSexIdx()
    for i,v in pairs(PlayerInfoHelper.GetModeCfg()) do
        if not v.isLocked and _sex == v.sex then
            table.insert(self.iconTab, {id = i, cfg = v})
        end
    end
end

function createCharacter:initUi()
    self.view = CS.SGK.UIReference.Setup(self.gameObject)
    self:initData()
    --self:initIcon()
    self:initBtn()
end

-- function createCharacter:showIconNode(idx)
--     local _tab = self.iconTab[idx]
--     SGK.ResourcesManager.LoadAsync(self.iconNode, "roles_small/".._tab.cfg.mode.."/".._tab.cfg.mode.."_SkeletonData", function(o)
--         if o then
--             self.iconNode.skeletonDataAsset = o
--             self.iconNode:Initialize(true)
--         end
--     end)
--     self.selectIndex = _tab.cfg.icon
--     self.ScrollView:ItemRef()
-- end

-- function createCharacter:initIcon()
--     self.ScrollView = self.view.root.ScrollView[CS.UIMultiScroller]
--     self.iconNode = self.view.root.icon[CS.Spine.Unity.SkeletonGraphic]
--     self.ScrollView.RefreshIconCallback = function (obj, idx)
--         local _view = CS.SGK.UIReference.Setup(obj)
--         local _tab = self.iconTab[idx+1]
--         utils.IconFrameHelper.Create(_view.root.IconFrame, {customCfg={
--                 icon    = _tab.cfg.icon,
--                 quality = 0,
--                 star    = 0,
--                 level   = 0,
--         }, type = 42, func = function(obj)
--             obj.other:SetActive(self.selectIndex == _tab.cfg.icon)
--             if self.selectIndex == _tab.cfg.icon then
--                 _view.root.IconFrame.transform.localScale = Vector3(1, 1, 1)
--             else
--                 _view.root.IconFrame.transform.localScale = Vector3(0.8, 0.8, 1)
--             end
--         end})
--         CS.UGUIClickEventListener.Get(_view.root.gameObject).onClick = function()
--             self:showIconNode(idx+1)
--         end
--         obj:SetActive(true)
--     end
--     self.ScrollView.DataCount = #self.iconTab
-- end

function createCharacter:getSexIdx()
    local _sex = self.view.root.sexNode.boy[UI.Toggle]
    local _idx = 1
    if _sex.isOn then
        _idx = 0
    end
    return _idx
end

function createCharacter:initBtn()
    self.inputText = self.view.root.chanegeName.InputField[UI.InputField]
    self.randomName = NameCfg.Get(self:getSexIdx())
    self.inputText.text = self.randomName
    local _idx = math.random(1, #self.iconTab)
    --self:showIconNode(_idx)
    --self.ScrollView:ScrollMove(_idx - 1)
    --self.view.root.tip[UI.Text].text = TipCfg.GetAssistDescConfig(62004).info

    for i = 1, 2 do
        self.view.root.sexNode[i][UI.Toggle].onValueChanged:AddListener(function (value)
            if value then
                if self.randomName == nil or self.randomName == self.inputText.text then
                    self.randomName = NameCfg.Get(i - 1)
                    self.inputText.text = self.randomName
                end
                self:upData()
                --self.ScrollView.DataCount = #self.iconTab
                self.selectIndex = self.iconTab[1].cfg.icon
                --self.ScrollView:ScrollMove(0)
                --self:showIconNode(1)

                self.view.root.sexNode[i].Background[UI.Image].color = {r = 1, g = 1, b = 1, a = 1}
            else
                self.view.root.sexNode[i].Background[UI.Image].color = {r = 0.5, g = 0.5, b = 0.5, a = 1}
            end
        end)
    end

    -- CS.UGUIClickEventListener.Get(self.view.root.leftBtn.gameObject).onClick = function()
    --     local _direction = self.view.root.icon[SGK.DialogSprite].direction
    --     if _direction ==  2 then
    --         self.view.root.icon[SGK.DialogSprite].direction = 0
    --         return
    --     end
    --     if _direction - 1 < 0 then
    --         self.view.root.icon[SGK.DialogSprite].direction = 6
    --     else
    --         self.view.root.icon[SGK.DialogSprite].direction = _direction - 1
    --     end
    -- end
    -- CS.UGUIClickEventListener.Get(self.view.root.rightBtn.gameObject).onClick = function()
    --     local _direction = self.view.root.icon[SGK.DialogSprite].direction
    --     if _direction ==  1 then
    --         self.view.root.icon[SGK.DialogSprite].direction = 3
    --         return
    --     end
    --     if _direction + 1 > 6 then
    --         self.view.root.icon[SGK.DialogSprite].direction = 0
    --     else
    --         self.view.root.icon[SGK.DialogSprite].direction = _direction + 1
    --     end
    -- end

    CS.UGUIClickEventListener.Get(self.view.root.chanegeName.randomBtn.gameObject).onClick = function()
        self.randomName = NameCfg.Get(self:getSexIdx())
        self.inputText.text = self.randomName
    end
    CS.UGUIClickEventListener.Get(self.view.root.enterBtn.gameObject).onClick = function()
        if self.inputText.text == "陆水银" then
            showDlgError(nil, "请输入新角色名")
            return
        end
        if self.inputText.text == "" then
            showDlgError(nil, "请输入角色名")
            return
        end
        local len = GetUtf8Len(self.inputText.text)
    	if len < 4  or len > 12 then
    		showDlgError(nil, "请输入2~6个汉字或4~12个字母、数字")
            return
    	end
        local name, hit = WordFilter.check(self.inputText.text)
        if hit then
            showDlgError(nil, "检测到敏感字符，请重新输入")
            return
        end
        self.view.root.enterBtn[CS.UGUIClickEventListener].interactable = false
        self.view.root.enterBtn[UI.Image].material = SGK.QualityConfig.GetInstance().grayMaterial
        coroutine.resume(coroutine.create(function()
            local _changeName = function()
                local _nameData = utils.NetworkService.SyncRequest(51, {nil, self.inputText.text, self.selectIndex})
                if _nameData[2] == 0 then
                    self:playEffect("fx_bn_enter", nil, self.view.root.enterBtn.gameObject)                    
                    PlayerInfoHelper.ChangeSex(self:getSexIdx())
                    PlayerInfoHelper.ChangeActorShow(self.selectIndex)
                    module.QuestModule.Finish(10004)
                else
                    self.view.root.enterBtn[CS.UGUIClickEventListener].interactable = true
                    self.view.root.enterBtn[UI.Image].material = nil
                    showDlgError(nil, "该昵称已被使用")
                end
            end
            _changeName()
        end))
    end
end

function createCharacter:Start(data)
    self:initData(data)
    self:initUi()
end

function createCharacter:playEffect(effectName, position, node, sortOrder)
    local prefab = SGK.ResourcesManager.Load("prefabs/effect/UI/" .. effectName .. ".prefab");
    local o = prefab and UnityEngine.GameObject.Instantiate(prefab, node.transform);
    if o then
        local transform = o.transform;
        transform.localPosition = position or Vector3.zero;
        transform.localRotation = Quaternion.identity;
        if sortOrder then
            SGK.ParticleSystemSortingLayer.Set(o, sortOrder);
        end
        if self.func then
            self.func()
        end
        CS.UnityEngine.GameObject.Destroy(self.gameObject)
    end
    return o
end

return createCharacter
