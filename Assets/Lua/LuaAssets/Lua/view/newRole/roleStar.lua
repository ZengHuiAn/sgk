local heroStar = require"hero.HeroStar"
local ParameterConf = require "config.ParameterShowInfo";
local skillConfig = require "config.skill"

local roleStar = {}

local arrowRotate = {
    [5] = -153,
    [4] = -100,
    [3] = -69,
    [2] = -20,
    [1] = 70,
    [0] = 136,
}

local sliderRotate = {
    [0] = 0,
    [1] = 0.2,
    [2] = 0.45,
    [3] = 0.6,
    [4] = 0.7,
    [5] = 0.82,
    [6] = 1,
}

function roleStar:Start(data)
    self:initData(data)
    self:initUi()
    if UnityEngine.Screen.height > 1136 then
        self.view.root.viewRoot.transform.localScale = Vector3(1.1, 1.1, 1)
    else
        self.view.root.viewRoot.transform.localScale = Vector3(1, 1, 1)
    end
    self:initGuide()
end

function roleStar:initGuide()
    module.guideModule.PlayByType(110,0.2)
end

function roleStar:initData(data)
    if data then
        self.heroId = data.heroId
    end
    self.heroCfg = utils.ItemHelper.Get(utils.ItemHelper.TYPE.HERO, self.heroId or 11000)
    local _cfg = module.TalentModule.GetSkillSwitchConfig(self.heroId)
    local skill_heroId = self.heroId;
    if _cfg then
        skill_heroId = _cfg[self.heroCfg.property_value].skill_star;
    end
    self.starUpTab = heroStar.GetStarUpTab()
    self.commonTab = heroStar.GetCommonTab()
    local _, _roleStar = heroStar.GetroleStarTab()
    self.roleStarTab = _roleStar[skill_heroId]
    self.nextStar = self.heroCfg.star + 1
    self.maxStar = 30
    if self.nextStar >= self.maxStar then
        self.nextStar = self.maxStar
    end

    self.leftDescList = heroStar.GetHeroStarSkillList(skill_heroId)
    table.sort(self.leftDescList, function(a, b)
        return a.id < b.id;
    end)
end

function roleStar:getDocLevel(cfg)
    local _count = 0
    local _desc = {}

    for _, v in ipairs(cfg.star_list or {}) do
        if v.level <= self.heroCfg.star then
            _count = _count + 1
        end
        table.insert(_desc, {desc = v.desc, star = v.level, active = (v.level <= self.heroCfg.star)})
    end
    return _desc, _count;
end

function roleStar:initUi()
    self.view = CS.SGK.UIReference.Setup(self.gameObject)
    self:initConsumeItem()
    self:initStartNode()
    self:initBtn()
    self:initSkillTip()
    self:initFeaturesTip()
    self:upUi()
    self.view.root.switchDiamond[SGK.LuaBehaviour]:Call("InitData",{heroId = self.heroId})
end

function roleStar:upUi()
    self:upConsume()
    self:upSkill()
end

function roleStar:initConsumeItem()
    self.consume1 = self.view.root.consume.item1.icon
    self.consume2 = self.view.root.consume.item2.icon
    self.consumeLevel = self.view.root.consume.level[UI.Text]
end

function roleStar:initStartNode()
    self.skillNode = self.view.root.viewRoot.skillNode
end

function roleStar:initSkillTip()
    CS.UGUIClickEventListener.Get(self.view.root.skillTip.tipsView.mask.gameObject, true).onClick = function()
        self.view.root.skillTip.tipsView:SetActive(false)
    end
end

function roleStar:initFeaturesTip()
    CS.UGUIClickEventListener.Get(self.view.root.featuresTip.tipsView.mask.gameObject, true).onClick = function()
        self.view.root.featuresTip.tipsView:SetActive(false)
    end

    DispatchEvent("ROLE_FRAME_MOVE_TO_FRONTLAYER", self.view.root.featuresTip.gameObject)
end


local function makeStartPropertys(_cfg, _lastSt, _st)
    local props = {}
    for i = 0, 6 do
        if _cfg["type"..i] ~= 0 then
            local _offValue = 0
            local _valueCfg = ParameterConf.Get(_cfg["type"..i])
            if _valueCfg.showType ~= nil then
                _offValue = math.floor(_st.props[_valueCfg.showType] - _lastSt.props[_valueCfg.showType])
            else
                _offValue = math.floor(_st.props[_valueCfg.id] - _lastSt.props[_valueCfg.id])
            end
            table.insert(props, {
                icon = _valueCfg.icon,
                name = _valueCfg.name,
                value = ParameterConf.GetPeropertyShowValue(_cfg["type"..i], _offValue)
            })
        end
    end

    return props;
end
function roleStar:upSkill()
    local _idx = math.floor(self.heroCfg.star / 6)
    local _openIdx = self.heroCfg.star % 6
    if self.heroCfg.star == self.maxStar then
        _idx = _idx - 1
        _openIdx = 6
        self.view.root.viewRoot.arrow:SetActive(false)
        self.view.root.consume:SetActive(false)
    else
        self.view.root.viewRoot.arrow:SetActive(true)
        self.view.root.consume:SetActive(true)
    end
    local _startIdx = _idx * 6

    self.roleStarInfo = {};

    for i = 1, 6 do
        local _cfg = self.roleStarTab[i + _startIdx]

        local star_effect = heroStar.GetStarEffect(_cfg.star_type)
        
        self.view.root.viewRoot.skillNode[i].icon[UI.Image]:LoadSprite("icon/".. star_effect.icon)
        if i <= _openIdx then
            self.view.root.viewRoot.skillNode[i].icon[UI.Image].material = nil
        else
            self.view.root.viewRoot.skillNode[i].icon[UI.Image].material = SGK.QualityConfig.GetInstance().grayMaterial
        end
        self.view.root.viewRoot.skillNode[i].up:SetActive(_cfg.desc2 ~= '0')
        self.view.root.viewRoot.skillNode[i].light:SetActive(i == (_openIdx + 1))
        if self.view.root.viewRoot.skillNode[i].light.activeSelf then
            self.view.root.viewRoot.skillNode[i].light[UI.Image]:LoadSprite("icon/".. star_effect.icon)
        end
        
        local info;
        if star_effect.isshow ~= 0 then
            -- self.view.root.skillTip[i].info.Text[UI.Text].text = _typeCfg.name.."\n".._cfg.desc
            info = { text = star_effect.name.."\n".._cfg.desc, props = {} }
        else
            local _off = i + _startIdx - self.heroCfg.star
            local _st = module.HeroModule.GetManager():Get(self.heroId):EnhanceProperty(0, 0, _off)
            local _lastSt = module.HeroModule.GetManager():Get(self.heroId):EnhanceProperty(0, 0, _off - 1)

            local props = makeStartPropertys(_cfg, _lastSt, _st);
            info = { props = props };
            -- self.view.root.skillTip[i].info.Text[UI.Text].text = string.sub(_valueDesc, 1, -2)
        end
        self.roleStarInfo[i + _startIdx] = info;

        local slot = self.view.root.skillTip["slot" .. i]

        CS.UGUIClickEventListener.Get(self.view.root.viewRoot.skillNode[i].gameObject).onClick = function()
            local tipsView = self.view.root.skillTip.tipsView;
            tipsView.info.Text:SetActive(info.text ~= nil)
            tipsView.info.Text[UnityEngine.UI.Text].text = info.text or '';

            for j = 1, 6 do
                local prop = info.props[j];
                local item = tipsView.info['Item' .. j];
                if not prop then
                    item:SetActive(false);
                else
                    item:SetActive(true);
                    item.Icon[UI.Image]:LoadSprite("propertyIcon/" .. prop.icon)
                    item.Text[UnityEngine.UI.Text].text = prop.name;
                    item.Value[UnityEngine.UI.Text].text = "+" .. prop.value;
                end
            end
            tipsView.transform.position = slot.transform.position;
            tipsView:SetActive(true)
        end
    end

    local feature_count = 5;
    for i = 1, 5 do
        local _view = self.view.root.viewRoot.features.featuresNode[i]
        local _cfg = self.leftDescList[i]
        if not _cfg then
            _view:SetActive(false);
            feature_count = i - 1;
        else
            _view:SetActive(true);
            _view.icon[UI.Image]:LoadSprite("icon/".._cfg.icon)            
            local _desc, _level = self:getDocLevel(_cfg)
            _view.level[UI.Text].text = "^".._level + 1

            local node = _view.tipSlot;

            local _tipView = self.view.root.featuresTip.tipsView;

            CS.UGUIClickEventListener.Get(_view.gameObject).onClick = function()
                _tipView.transform.position = node.transform.position;

                _tipView.info.name[UI.Text].text = _cfg.name;
                if _cfg.skill_id == 0 then
                    _tipView.info.Head.BGColor[CS.UGUIColorSelector].index = 1;
                    _tipView.info.Head.TypeText[UnityEngine.UI.Text].text = "被动"  -- SGK.Localize:getInstance():getValue();
                    _tipView.info.Head.ConsumeIcon:SetActive(false);
                    _tipView.info.Head.ConsumeValue:SetActive(false);
                else
                    _tipView.info.Head.BGColor[CS.UGUIColorSelector].index = 0;
                    _tipView.info.Head.TypeText[UnityEngine.UI.Text].text = "主动"  -- SGK.Localize:getInstance():getValue();
                    _tipView.info.Head.ConsumeIcon:SetActive(true);
                    _tipView.info.Head.ConsumeValue:SetActive(true);
                    
                    local skill_cfg = skillConfig.GetConfig(_cfg.skill_id);
                    if skill_cfg then
                        _tipView.info.Head.ConsumeValue[UnityEngine.UI.Text].text = tostring(skill_cfg.consume);
                    else
                        _tipView.info.Head.ConsumeValue[UnityEngine.UI.Text].text = '-';
                    end
                end

                _tipView.info.desc[UI.Text].text = _cfg.desc

                local feature_count = 0;
                for j = 1, 6 do
                    local v = _desc[j];

                    local active = (j <= _level);

                    local item = _tipView.info.mask[j]
                    if v then
                        feature_count = feature_count + 1;
                        local keyStr = SGK.Localize:getInstance():getValue("huoban_shengxing_buff_01", math.floor(v.star / 6),  v.star % 6, "");
                        item:SetActive(true)
                        if active then
                            item.Key[UI.Text].text = keyStr;
                            item.Value[UI.Text].text = v.desc;
                        else
                            item.Key[UI.Text].text = "<color=#828282FF>".. keyStr .. "</color>";
                            item.Value[UI.Text].text = "<color=#828282FF>".. v.desc  .. "</color>";
                        end
                    else
                        item:SetActive(false);
                    end
                end

                _tipView.info.mask:SetActive(feature_count > 0)

                _tipView:SetActive(true);
            end
        end
    end

    local feature_bg_size = {
        [1] = 80,
        [2] = 160,
        [3] = 240,
        [4] = 320,
        [5] = 485,
    }
    self.view.root.viewRoot.features.ImageMask.transform.sizeDelta = UnityEngine.Vector2(91,feature_bg_size[feature_count]);

    if self.heroCfg.star ~= self.maxStar then
        self.view.root.viewRoot.arrow.transform:DORotate(Vector3(0, 0, arrowRotate[_openIdx]), 0)
        self.view.root.viewRoot.slider[UI.Image]:DOFillAmount(sliderRotate[_openIdx], 0.2)
    else
        self.view.root.viewRoot.slider[UI.Image]:DOFillAmount(1, 0.2)
    end
    self.view.root.viewRoot.maxStarNode:SetActive(self.heroCfg.star == self.maxStar)
    self.view.root.viewRoot.activation:SetActive(self.heroCfg.star ~= self.maxStar)
    self.view.root.viewRoot.arrow:SetActive(self.heroCfg.star ~= self.maxStar)
    self.view.root.viewRoot.skillNode:SetActive(self.heroCfg.star ~= self.maxStar)
    self.view.root.viewRoot.slider:SetActive(self.heroCfg.star ~= self.maxStar)
end

function roleStar:upConsume()
    if self.commonTab[self.nextStar] then
        self.view.root.consume.level:SetActive(true)
        if self.commonTab[self.nextStar].para2 <= self.heroCfg.level then
            self.consumeLevel.color = {r = 0, g = 1, b = 0, a = 1}
        else
            self.consumeLevel.color = {r = 1, g = 0, b = 0, a = 1}
        end
        self.consumeLevel.text = self.commonTab[self.nextStar].para2.."级"
        utils.IconFrameHelper.Create(self.consume1, {id = self.roleStarTab[self.nextStar].cost_id1, type = 41, count = 0, showDetail = true, pos = 2})
        utils.IconFrameHelper.Create(self.consume2, {id = self.roleStarTab[self.nextStar].cost_id2, type = 41, count = 0, showDetail = true, pos = 2})
        local _consume1 = module.ItemModule.GetItemCount(self.roleStarTab[self.nextStar].cost_id1)
        local _consumeNeed1 = self.roleStarTab[self.nextStar].cost_value1

        local _consume2 = module.ItemModule.GetItemCount(self.roleStarTab[self.nextStar].cost_id2)
        local _consumeNeed2 = self.roleStarTab[self.nextStar].cost_value2

        if _consume1 >= _consumeNeed1 then
            self.view.root.consume.item1.number[UI.Text].text = "<color=#FFFFFF>"..utils.SGKTools.ScientificNotation(_consume1).."</color>".."/"..utils.SGKTools.ScientificNotation(_consumeNeed1)
        else
            self.view.root.consume.item1.number[UI.Text].text = "<color=#FF2625>"..utils.SGKTools.ScientificNotation(_consume1).."</color>".."/"..utils.SGKTools.ScientificNotation(_consumeNeed1)
        end
        if _consume2 >= _consumeNeed2 then
            self.view.root.consume.item2.number[UI.Text].text = "<color=#FFFFFF>"..utils.SGKTools.ScientificNotation(_consume2).."</color>".."/"..utils.SGKTools.ScientificNotation(_consumeNeed2)
        else
            self.view.root.consume.item2.number[UI.Text].text = "<color=#FF2625>"..utils.SGKTools.ScientificNotation(_consume2).."</color>".."/"..utils.SGKTools.ScientificNotation(_consumeNeed2)
        end
    else
        self.view.root.consume.level:SetActive(false)
    end
    self.view.root.viewRoot.activation.effect:SetActive(module.RedDotModule.GetStatus(module.RedDotModule.Type.Hero.Star, self.heroId))
    local _starIdx = self.nextStar % 6
    if _starIdx == 0 then
        self.view.root.viewRoot.activation.Text[UI.Text].text = SGK.Localize:getInstance():getValue("common_jihuo_01")
    else
        self.view.root.viewRoot.activation.Text[UI.Text].text = SGK.Localize:getInstance():getValue("huoban_shengxing_jihuo_01", _starIdx)
    end
end

function roleStar:playEffect(effectName, node, func)
    SGK.ResourcesManager.LoadAsync("prefabs/effect/UI/"..effectName..".prefab", function(o)
        if o then
            local obj = CS.UnityEngine.GameObject.Instantiate(o, self.view.root.transform)
            obj.transform.position = node.transform.position
            func(obj)
        end
    end)
end

function roleStar:playStarEffect(now, next, isUp)
    local _idx = next % 6
    if _idx == 0 then
        _idx = 6
    end

    local _isUp = self.skillNode[_idx].up.activeSelf
    if not _isUp then
        if self.skillNode[_idx] then
            self:playEffect("fx_rolestar_btn_2", self.skillNode[_idx], function(obj)
                UnityEngine.Object.Destroy(obj, obj:GetComponentInChildren(typeof(UnityEngine.ParticleSystem)).main.duration)
            end)

            local _leftIdx = nil;
            for i = 1, 5 do
                local _cfg = self.leftDescList[i]
                if _cfg and self.roleStarTab[next] and (self.roleStarTab[next].name == _cfg.name) then
                    _leftIdx = i
                    break
                end
            end

            if _leftIdx then
                SGK.ResourcesManager.LoadAsync("sound/shengxing_long.wav",typeof(UnityEngine.AudioClip),function (Audio)
                    SGK.BackgroundMusicService.PlayUIClickSound(Audio)
                end)
                self:playEffect("fx_rolestar_lizi", self.skillNode[_idx], function(obj)
                    obj.transform:DOMove(self.view.root.viewRoot.features.featuresNode[_leftIdx].transform.position, 1):OnComplete(function()
                        self:playEffect("fx_rolestar_lizi_hit", self.view.root.viewRoot.features.featuresNode[_leftIdx], function(_rObj)
                            UnityEngine.Object.Destroy(_rObj, _rObj:GetComponentInChildren(typeof(UnityEngine.ParticleSystem)).main.duration)
                        end)
                        UnityEngine.Object.Destroy(obj)
                    end)
                end)
            else
                SGK.ResourcesManager.LoadAsync("sound/shengxing.wav",typeof(UnityEngine.AudioClip),function (Audio)
                    SGK.BackgroundMusicService.PlayUIClickSound(Audio)
                end)
                local n = #(self.roleStarInfo[next].props);
                for k, prop in ipairs(self.roleStarInfo[next].props) do
                    local tips = SGK.UIReference.Instantiate(self.view.root.skillTip.tipsView2, self.view.root.skillTip[_idx].transform)
                    tips:SetActive(true);
                    tips[UnityEngine.CanvasGroup].alpha = 0;
                    tips.Text[UnityEngine.UI.Text].text = prop.name .. " + " .. prop.value;
                    tips[UnityEngine.CanvasGroup]:DOFade(1, 0.3):SetDelay((n - k) * 0.3);
                    tips.transform:DOLocalMove(Vector3(0, 150, 0), 1):SetDelay((n - k) * 0.3 + 0.1):SetEase(CS.DG.Tweening.Ease.Linear);
                    tips[UnityEngine.CanvasGroup]:DOFade(0, 0.3):SetDelay((n - k) * 0.3 + 0.7);
                    UnityEngine.GameObject.Destroy(tips.gameObject, 1 + (n - k) * 0.3);
                end
                -- tips[]:DOLocalMove(Vector3(0, 100, 0), 1)
            end
        end
    else
        if isUp then
            DialogStack.PushPrefStact("newRole/starReward", {
                heroId = self.heroId,
                nowStar = now, 
                nextStar = next, 
                desc = self.roleStarTab[next].desc2,
                props = self.roleStarInfo[next].props,
            })
        end
        --[[
        self:playEffect("fx_rolestar_lizi", self.skillNode[_idx], function(obj)
            local _leftIdx = 1
            for i = 1, 5 do
                local _cfg = self.leftDescList[i]
                if _cfg and self.roleStarTab[next] and (self.roleStarTab[next].name == _cfg.name) then
                    _leftIdx = i
                    break
                end
            end
            obj.transform:DOMove(self.view.root.viewRoot.features.featuresNode[_leftIdx].transform.position, 1):OnComplete(function()
                self:playEffect("fx_rolestar_lizi_hit", self.view.root.viewRoot.features.featuresNode[_leftIdx], function(_rObj)
                    UnityEngine.Object.Destroy(_rObj, _rObj:GetComponentInChildren(typeof(UnityEngine.ParticleSystem)).main.duration)
                    if isUp then
                        DialogStack.PushPrefStact("newRole/starReward", {nowStar = now, nextStar = next, desc = self.roleStarTab[next].desc2})
                    end
                end)
                UnityEngine.Object.Destroy(obj)
            end)
        end)
        --]]
    end
end

function roleStar:initBtn()
    CS.UGUIClickEventListener.Get(self.view.root.viewRoot.activation.gameObject).onClick = function()
        if self.heroCfg.star < self.maxStar then
            if self.commonTab[self.heroCfg.star + 1].para2 <= self.heroCfg.level then
                if module.ItemModule.GetItemCount(self.roleStarTab[self.nextStar].cost_id1) >= self.roleStarTab[self.nextStar].cost_value1 then
                    if module.ItemModule.GetItemCount(self.roleStarTab[self.nextStar].cost_id2) >= self.roleStarTab[self.nextStar].cost_value2 then
                        coroutine.resume(coroutine.create(function()
                            local _now = self.heroCfg.star
                            local _next = self.nextStar
                            local _data = utils.NetworkService.SyncRequest(13, {nil, self.heroId, 0})
                            if _data[2] == 0 then
                                DispatchEvent("WORKER_INFO_CHANGE", {uuid = self.heroCfg.uuid})
                                DispatchEvent("LOCAL_HERO_STAR_UP", {heroId = self.heroId, now = _now, next = _next})
                                self.view.root.viewRoot.activation.effect1:SetActive(false)
                                self.view.root.viewRoot.activation.effect1:SetActive(true)
                                self.view.root.viewRoot.activation.effect1.transform:DORotate(Vector3(0, 0, 0), 0.5):OnComplete(function()
                                    self.view.root.viewRoot.activation.effect1:SetActive(false)
                                end)
                                self:playStarEffect(_now, _next, self.roleStarTab[_next].desc2 ~= "0")
                            else
                                showDlgError(nil, "升星失败", function() end)
                                return
                            end
                         end))
                    else
                        showDlgError(nil, "陵币不足", function() end)
                        return
                    end
                else
                    showDlgError(nil, "碎片不足", function() end)
                    return
                end
            else
                showDlgError(nil, "角色等级不足", function() end)
                return
            end
        else
            showDlgError(nil, "升满", function() end)
            return
        end
    end
end

function roleStar:onEvent(event, data)
    if event == "LOCAL_NEWROLE_HEROIDX_CHANGE" then
        self:initData(data)
        self:upUi()
    elseif event == "HERO_INFO_CHANGE" then
        self:initData()
        self:upUi()
    elseif event == "ITEM_INFO_CHANGE" then
        self:initData()
        self:upUi()
    elseif event == "LOCAL_GUIDE_CHANE" then
        self:initGuide()
    elseif event == "HERO_DIAMOND_CHANGE" then
        self:initData({heroId = self.heroId})
        self:upUi()
    end
end

function roleStar:listEvent()
	return {
    	"LOCAL_NEWROLE_HEROIDX_CHANGE",
        "HERO_INFO_CHANGE",
        "ITEM_INFO_CHANGE",
        "LOCAL_GUIDE_CHANE",
        "HERO_DIAMOND_CHANGE"
    }
end


return roleStar
