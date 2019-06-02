local View = {};
function View:Start(data)
    self.view = CS.SGK.UIReference.Setup(self.gameObject);
    self.element_light = self.view.element.light;
    self.tip = self.view.tip.gameObject;
    self.light = {};
    self:InitView();
end

function View:InitView()
	CS.UGUIClickEventListener.Get(self.view.element.gameObject).onClick = function ( obj )
		if not self.tip.activeSelf then
			self.tip.transform:SetParent(UnityEngine.GameObject.FindWithTag("UGUIRoot").gameObject.transform, false);
			self.view.tip:SetActive(true);
		end
    end
	CS.UGUIClickEventListener.Get(self.view.tip.title.close.gameObject).onClick = function ( obj )
		self.tip:SetActive(false);
		self.tip.transform:SetParent(self.view.gameObject.transform, false);
    end
    CS.UGUIClickEventListener.Get(self.view.tip.bg.gameObject).onClick = function ( obj )
		self.tip:SetActive(false);
		self.tip.transform:SetParent(self.view.gameObject.transform, false);
    end
end

function View:Change(id)
    local hero = module.HeroModule.GetManager():Get(id);
    local type = hero.cfg.type;
    local _cfg = module.TalentModule.GetSkillSwitchConfig(id);
    if _cfg then
        local _idx = hero.property_value;
        type = _cfg[_idx].element_type;
    end
    for k,v in pairs(self.light) do
        v:SetActive(false);
    end
    local element = {};
    for i=1,8 do
        if (type & (1 << (i - 1))) ~= 0 then
            table.insert(element, i);
            break;
        end
    end
    for _,v in ipairs(element) do
        if self.light[v] then
            self.light[v]:SetActive(true);
        else
            local obj = CS.UnityEngine.GameObject.Instantiate(self.element_light.gameObject, self.view.element["element"..v].gameObject.transform);
            obj.transform.localPosition = Vector3.zero;
            obj:SetActive(true);
            self.light[v] = obj;
        end
    end
end

function View:OnDestroy()
	if self.tip.activeSelf then
		UnityEngine.GameObject.Destroy(self.tip);
	end
end

function View:listEvent()
	return {
		"LOCAL_NEWROLE_HEROIDX_CHANGE",
	}
end

function View:onEvent(event, ...)
    -- print("onEvent", event, ...);
    local eventData = ...;
	if event == "LOCAL_NEWROLE_HEROIDX_CHANGE"  then
        self:Change(eventData.heroId);
	end
end

return View;