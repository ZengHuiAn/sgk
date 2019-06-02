local heroStar = require"hero.HeroStar"
local skillConfig = require "config.skill"
local View = {};
function View:Start()
	self.view = CS.SGK.UIReference.Setup(self.gameObject);
end

function View:InitData(data)
    if data then
        self.heroId = data.heroId;
        self.star = data.star or 0;
        self.offset = data.offset or {0, 0, 0, 0, 0}
        self.Anchors = data.Anchors --锚点偏移
    end
    -- local _cfg = module.TalentModule.GetSkillSwitchConfig(self.heroId)
    -- local skill_heroId = self.heroId;
    -- if _cfg then
    --     skill_heroId = _cfg[self.heroCfg.property_value == 0 and 2 or self.heroCfg.property_value].skill_star;
    -- end
    self.leftDescList = heroStar.GetHeroStarSkillList(self.heroId);
    table.sort( self.leftDescList, function (a, b)
        return a.id < b.id;
    end)
    self:InitView();
end

function View:InitView()
    CS.UGUIClickEventListener.Get(self.view.featuresTip.mask.gameObject, true).onClick = function()
        self.view.featuresTip.mask:SetActive(false);
        self.view.featuresTip.tipsView:SetActive(false)
    end
    for i = 1, 5 do
        local _view = self.view.featuresNode[i];
        local _cfg = self.leftDescList[i]
        if not _cfg then
            _view:SetActive(false);
        else
            _view:SetActive(true);
            _view.icon[UI.Image]:LoadSprite("icon/".._cfg.icon)            
            local _desc, _level = self:getDocLevel(_cfg)
            _view.level[UI.Text].text = "^".._level + 1

            local node = _view.tipSlot;

            local _tipView = self.view.featuresTip.tipsView;
            
            CS.UGUIClickEventListener.Get(_view.gameObject).onClick = function()
                if self.Anchors then
                    _tipView[UnityEngine.RectTransform].anchorMax = UnityEngine.Vector2(0.5, self.Anchors~=0 and 0 or 1);
                    _tipView[UnityEngine.RectTransform].anchorMin = UnityEngine.Vector2(0.5, self.Anchors~=0 and 0 or 1);
                    
                    _tipView.info[UnityEngine.RectTransform].anchorMax = UnityEngine.Vector2(0.5, self.Anchors);
                    _tipView.info[UnityEngine.RectTransform].anchorMin = UnityEngine.Vector2(0.5, self.Anchors);
                    
                    _tipView[UnityEngine.RectTransform].pivot = UnityEngine.Vector2(0.5,self.Anchors)
                    _tipView.info[UnityEngine.RectTransform].pivot = UnityEngine.Vector2(0.5,self.Anchors)
                else
                    _tipView.transform.position = node.transform.position;
                    _tipView.info[UnityEngine.RectTransform].anchoredPosition = UnityEngine.Vector2(self.offset[i], 0);
                end
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
                self.view.featuresTip.mask:SetActive(true);
                _tipView:SetActive(true);
            end
        end
    end
end

function View:getDocLevel(cfg)
    local _count = 0
    local _desc = {}

    for _, v in ipairs(cfg.star_list or {}) do
        if v.level <= self.star then
            _count = _count + 1
        end
        table.insert(_desc, {desc = v.desc, star = v.level, active = (v.level <= self.star)})
    end
    return _desc, _count;
end

function View:listEvent()
	return {
		"",
	}
end

function View:onEvent(event, ...)
	print("onEvent", event, ...);
	if event == "" then

	end
end

return View;