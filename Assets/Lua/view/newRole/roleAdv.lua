local HeroEvo = require "hero.HeroEvo"
local ParameterConf = require "config.ParameterShowInfo"
local CommonConfig = require "config.commonConfig"
local heroModule = require "module.HeroModule"
local ParameterConf = require "config.ParameterShowInfo"

local roleAdv = {}

-- local colorCfg = {
--     [1] = "#30FF00FF",
--     [2] = "#00deffFF",
--     [3] = "#e167ffFF",
--     [4] = "#ff9638FF",
--     [5] = "#ff0000FF",
-- }


local colorCfg = {
    [1] = "#30FF00FF",
    [2] = "#30FF00FF",
    [3] = "#30FF00FF",
    [4] = "#30FF00FF",
    [5] = "#30FF00FF",
}

function roleAdv:Start(data)
    self:initData(data)
    self:initUi()
    self:initGuide()
end

function roleAdv:initGuide()
    module.guideModule.PlayByType(109,0.2)
end

function roleAdv:initRoleIcon(id)
    local icon_cfg = {}
    if id then
        icon_cfg = utils.ItemHelper.Get(utils.ItemHelper.TYPE.HERO,id)
    else
        icon_cfg.quality = 0
        icon_cfg.level = 0
        icon_cfg.star = 0
    end
    if self.heroCfg.stage == self.maxStage then
        utils.IconFrameHelper.Create(self.view.root.maxNode.roleIcon.root.IconFrame, {type = 42, customCfg = icon_cfg, func = function(obj)
            end})
    else
        utils.IconFrameHelper.Create(self.view.root.middle.roleIcon.root.IconFrame, {type = 42, customCfg = icon_cfg, func = function(obj)
            end})
    end
end

function roleAdv:initData(data)
    if data then
        self.heroId = data.heroId
    end
    self.heroManager = heroModule.GetManager();
    self.hero = self.heroManager:Get(self.heroId)
    self.heroCfg = utils.ItemHelper.Get(utils.ItemHelper.TYPE.HERO, self.heroId or 11000)
    self.heroAdvCfg = HeroEvo.GetRoleAdvCfg(self.heroId)[self.heroCfg.stage]
    self.maxStage = #HeroEvo.GetRoleAdvCfg(self.heroId)
    self.nextStage = self.heroCfg.stage + 1
    if self.heroCfg.stage >= self.maxStage then
        self.nextStage = self.maxStage
    end
    self.nextHeroAdvCfg = HeroEvo.GetRoleAdvCfg(self.heroId)[self.nextStage]
    --print("zoe查看进阶",sprinttb(self.nextHeroAdvCfg))
end

function roleAdv:initConsumeNode()
    self.consumeNode = {}
    for i = 2, 3 do
        table.insert(self.consumeNode, self.view.root.bottom["icon"..i])
    end
    
end

function roleAdv:getAllParameter()
    local _list = {}
    for i,v in ipairs(HeroEvo.GetRoleAdvCfg(self.heroId)) do
        for j,p in ipairs(v.littleConsumeProperty) do
            if not _list[p.type] then _list[p.type] = 0 end
            _list[p.type] = _list[p.type] + p.value
        end
        for j,p in ipairs(v.consumeProperty) do
            if not _list[p.type] then _list[p.type] = 0 end
            _list[p.type] = _list[p.type] + p.value
        end
    end
    return _list
end

function roleAdv:upMaxNode()
    self.view.root.middle:SetActive(not (self.heroCfg.stage == self.maxStage))
    self.view.root.bottom:SetActive(not (self.heroCfg.stage == self.maxStage))
    self.view.root.activationBtn:SetActive(not (self.heroCfg.stage == self.maxStage))
    self.view.root.needLevel:SetActive(not (self.heroCfg.stage == self.maxStage))
    self.view.root.maxNode:SetActive(self.heroCfg.stage == self.maxStage)
    if self.heroCfg.stage == self.maxStage then
        self.view.root.maxNode.bg.Text[UI.Text].text=self.maxStage.."阶"
    end
    local _list = self:getAllParameter()
    local _item = self.view.root.maxNode.item
    local _count = 0
    local _t = {
        [1] = "  ",
        [2] = " ",
        [3] = "",
    }
    for i = 0, self.view.root.maxNode.infoNode.transform.childCount - 1 do
        CS.UnityEngine.GameObject.Destroy(self.view.root.maxNode.infoNode.transform:GetChild(i).gameObject)
    end
    for k,v in pairs(_list) do
        if k ~= 0 then
            local _cfg = ParameterConf.Get(k)
            if _cfg then
                local _obj = CS.UnityEngine.GameObject.Instantiate(_item.transform, self.view.root.maxNode.infoNode.transform)
                local _objView = CS.SGK.UIReference.Setup(_obj.gameObject)
                local _v = v
                if _cfg.rate ~= 1 then
                    if type(k) == "number" then
                        _v = v / _cfg.rate * 100
                        _v = _v.."%"
                    end
                end
                _objView.info[UI.Text].text = (_t[(_count / 3 + 1)] or "").._cfg.name.." +".._v
                _objView:SetActive(true)
                _count = _count + 1
            end
        end
    end
    self:getAllParameter()
end

function roleAdv:upConsume()
    local _stageSlot = self.heroCfg.stage_slot or {}
    -- for i,v in ipairs(self.consumeNode) do
    --     local _con = self.nextHeroAdvCfg.littleConsume[i]--进阶需要的道具
    --     local _pro = self.nextHeroAdvCfg.littleConsumeProperty[i]
    --     local _cfg = ParameterConf.Get(_pro.type)
    --     local _haveCount = module.ItemModule.GetItemCount(_con.id)--获取玩家已有数量
    --     utils.IconFrameHelper.Create(v.IconFrame, {type = _con.type, id = _con.id, count = 0, showDetail = false})
    --     CS.UGUIClickEventListener.Get(v.gameObject).onClick = function()
    --          DialogStack.PushPrefStact("ItemDetailFrame", {id = _con.id,type = _con.type,InItemBag=2})
    --     end
    --     v.gameObject:SetActive(_con.value~=0)
    --     if _haveCount >= _con.value then
    --         v.number[UI.Text].text = string.format("<color=#00FF00FF>%d/%d</color>", _haveCount, _con.value)
    --     else
    --         v.number[UI.Text].text = string.format("<color=#FF0000FF>%d/%d</color>", _haveCount, _con.value)
    --     end
    -- end
end

function roleAdv:initMiddle()
    self.nowStageText = self.view.root.middle.now[UI.Text]
    self.nextStageText = self.view.root.middle.nex[UI.Text]
    self.effectNowStage = self.view.root.advEffect.root.now[UI.Text]
    self.effectNextStage = self.view.root.advEffect.root.nex[UI.Text]
    CS.UGUIClickEventListener.Get(self.view.root.advEffect.root.mask.gameObject).onClick = function()
        self.view.root.advEffect[UnityEngine.Animator]:Play("advEffect_ani2")
    end
end

function roleAdv:upAdvEffect()
    local _, _color = UnityEngine.ColorUtility.TryParseHtmlString(colorCfg[math.floor(self.heroCfg.stage / 4) + 1])
    self.effectNowStage.color = _color
    self.effectNowStage.text = SGK.Localize:getInstance():getValue("huoban_tupo_02", self.heroCfg.stage)

    local _, _color1 = UnityEngine.ColorUtility.TryParseHtmlString(colorCfg[math.floor(self.nextStage / 4) + 1])
    self.effectNextStage.color = _color1
    self.effectNextStage.text = SGK.Localize:getInstance():getValue("huoban_tupo_02", self.nextStage)
    return self.heroCfg.stage, self.nextStage
end

function roleAdv:checkStageSlot(needLevel)
    if needLevel > self.heroCfg.level then
        return false
    end
    -- for i,v in ipairs(self.consumeNode) do
    --     local _con = self.nextHeroAdvCfg.littleConsume[i]--进阶需要的道具
    --     local _haveCount = module.ItemModule.GetItemCount(_con.id)--获取玩家已有数量
    --     if _haveCount < _con.value then
    --         return false
    --     end
    -- end
    for i=1,4 do
        local _haveCount1 = module.ItemModule.GetItemCount(self.nextHeroAdvCfg.consume[i].id)--持有的枫叶数量
        if _haveCount1 < self.nextHeroAdvCfg.consume[i].value then--如果持有的大于需要的
            return false
        end
    end
    return true     
end

function roleAdv:upMiddle()
    local _, _color = UnityEngine.ColorUtility.TryParseHtmlString(colorCfg[math.floor(self.heroCfg.stage / 4) + 1])
    self.nowStageText.color = _color
    self.nowStageText.text = SGK.Localize:getInstance():getValue("huoban_tupo_02", self.heroCfg.stage)

    local _, _color1 = UnityEngine.ColorUtility.TryParseHtmlString(colorCfg[math.floor(self.nextStage / 4) + 1])
    self.nextStageText.color = _color1
    self.nextStageText.text = SGK.Localize:getInstance():getValue("huoban_tupo_02", self.nextStage)

    local _levelCfg = CommonConfig.Get(100 + self.nextStage)
    if self.nextHeroAdvCfg and self.nextHeroAdvCfg.consume[1] and self.nextHeroAdvCfg.consume[1].type then
        for i=0,3 do
            self.view.root.bottom["icon"..i]:SetActive(true)
            local _haveCount = module.ItemModule.GetItemCount(self.nextHeroAdvCfg.consume[i+1].id)--持有的枫叶数量
            if _haveCount >= self.nextHeroAdvCfg.consume[i+1].value then--如果持有的大于需要的
                self.view.root.bottom["icon"..i].number[UI.Text].text = string.format("<color=#00FF00FF>%d/%d</color>", _haveCount, self.nextHeroAdvCfg.consume[i+1].value)
            else
                self.view.root.bottom["icon"..i].number[UI.Text].text = string.format("<color=#FF0000FF>%d/%d</color>", _haveCount, self.nextHeroAdvCfg.consume[i+1].value)
            end
            utils.IconFrameHelper.Create(self.view.root.bottom["icon"..i].IconFrame, {type = self.nextHeroAdvCfg.consume[i+1].type, id = self.nextHeroAdvCfg.consume[i+1].id, count = 0, showDetail = false})
            CS.UGUIClickEventListener.Get(self.view.root.bottom["icon"..i].gameObject).onClick = function()
               DialogStack.PushPrefStact("ItemDetailFrame", {id = self.nextHeroAdvCfg.consume[i+1].id,type = self.nextHeroAdvCfg.consume[i+1].type, InItemBag = 2})
            end
        end     
    end

    if _levelCfg.para2 <= self.heroCfg.level then
        self.view.root.needLevel.Level[UI.Text].text = string.format("<color=#00FF00FF>LV%d</color>", _levelCfg.para2)
    else
        self.view.root.needLevel.Level[UI.Text].text = string.format("<color=#FF0000FF>LV%d</color>", _levelCfg.para2)
    end
    
    CS.UGUIClickEventListener.Get(self.view.root.activationBtn.gameObject).onClick = function()
        if not self:checkStageSlot(_levelCfg.para2) then
                showDlgError(nil, "当前未满足进阶条件")
        else
        --进阶成功的点击事件
            -- for i,v in ipairs(self.consumeNode) do
            --    coroutine.resume(coroutine.create(function()
            --         local _data = utils.NetworkService.SyncRequest(17, {nil, self.heroId, i, 0})
            --     end))
            -- end

            SGK.ResourcesManager.LoadAsync("sound/jinjie.wav",typeof(UnityEngine.AudioClip),function (Audio)
                SGK.BackgroundMusicService.PlayUIClickSound(Audio)
            end)

            coroutine.resume(coroutine.create(function()
            local _now, _next = self:upAdvEffect()
            local _data = utils.NetworkService.SyncRequest(15, {nil, self.heroId, 0})
                if _data[2] == 0 then
                   self.view.root.advEffect[UnityEngine.Animator]:Play("advEffect_ani1")
                   DispatchEvent("LOCAL_HERO_STAGE_UP", {heroId = self.heroId, now = _now, next = _next})
                end
            end))
        end 
    end
    --进阶下面加的属性text
    local proText = {
    [0]="baseAd",
    [1]="baseArmor",
    [2]="baseHp",
    [3]="speed",
    [4]="initEp",
    }
    local proTextName = {
    [0]="ad",
    [1]="armor",
    [2]="hpp",
    [3]="speed",
    [4]="initEp",
    }
    local Cfg =self.heroCfg.cfg.__cfg
    local enhanceCfg = self.hero:EnhanceProperty(0,1,0)
    for i = 0, 4 do
        local _view = self.view.root.middle.item.info[i+1]
        _view.triangle.gameObject:SetActive(false)
        local _Cfg=ParameterConf.Get(Cfg["type"..i])
        _view.name[UI.Text].text=ParameterConf.Get(proTextName[i]).name
        --_view.LVUPBefore[UI.Text].text=self:initPropertyText(Cfg["type"..i],Cfg["value"..i],tonumber(string.sub(self.nowStageText.text,1,1)),HeroEvo.GetRoleAdvCfg(self.heroId))
        --_view.LVUPAfter[UI.Text].text=self:initPropertyText(Cfg["type"..i],Cfg["value"..i],tonumber(string.sub(self.nowStageText.text,1,1)),HeroEvo.GetRoleAdvCfg(self.heroId))
        _view.LVUPBefore[UI.Text].text=math.floor(self.hero[proText[i]])
        _view.LVUPAfter[UI.Text].text=math.floor(self.hero[proText[i]])
        if self.nextHeroAdvCfg then
            local _pro = self.nextHeroAdvCfg.consumeProperty[i+1]
            if _pro ~= nil then
                if _pro.type ==Cfg["type"..i] then
                    _view.AddText.gameObject:SetActive(true)
                    _view.LVUPAfter[UI.Text].text=math.floor(enhanceCfg.props[proText[i]])
                    _view.AddText[UI.Text].text=string.format("<color=#ffd800>(+%d)</color>",math.floor(enhanceCfg.props[proText[i]])-math.floor(self.hero[proText[i]]))
                    _view.triangle.gameObject:SetActive(true)
                end
            end
        end
    end
end

-- function roleAdv:initPropertyText(proid,base,nowAdv,totalCfg)
--     if totalCfg and nowAdv>0 then
--         if proid==totalCfg[1].consumeProperty[1].type then
--             for i=1,nowAdv do
--                 base = base + totalCfg[i].consumeProperty[1].value
--             end
--         elseif proid==totalCfg[1].consumeProperty[2].type then
--             for i=1,nowAdv do
--                 base = base + totalCfg[i].consumeProperty[2].value
--             end
--         elseif proid==totalCfg[1].consumeProperty[3].type then
--             for i=1,nowAdv do
--                 base = base + totalCfg[i].consumeProperty[3].value
--             end
--         end
--     end
--     return base
-- end

function roleAdv:initUi()
    self.view = CS.SGK.UIReference.Setup(self.gameObject)
    self:initMiddle()
    self:initConsumeNode()

    self:upUi()
end

function roleAdv:upUi()
    self:initRoleIcon(self.heroId)
    self:upConsume()
    self:upMiddle()
    self:upMaxNode()
end

function roleAdv:onEvent(event, data)
    if event == "LOCAL_NEWROLE_HEROIDX_CHANGE" then
        self:initData(data)
        self:upUi()
    elseif event == "HERO_INFO_CHANGE" then
        self:initData(data)
        self:upUi()
    elseif event == "LOCAL_GUIDE_CHANE" then
        self:initGuide()
    end
end

function roleAdv:listEvent()
	return {
    	"LOCAL_NEWROLE_HEROIDX_CHANGE",
        "HERO_INFO_CHANGE",
        "LOCAL_GUIDE_CHANE",
    }
end

return roleAdv
