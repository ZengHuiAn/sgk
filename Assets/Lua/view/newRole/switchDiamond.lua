local skillConfig = require "config.skill"
local ParameterConf = require "config.ParameterShowInfo";

local View = {};
local skill_type = {"群体","单体"}
local skill_effect = {"物理","法术","治疗","护盾","召唤","削弱","强化"}
function View:Start(data)
	self.view = CS.SGK.UIReference.Setup(self.gameObject);
end

function View:InitData(data)
	self.roleID = data.heroId;
	self.switchConfig = module.TalentModule.GetSkillSwitchConfig(self.roleID);
	self.view.btn:SetActive(self.switchConfig ~= nil);
	if self.switchConfig then
		self.hero = module.HeroModule.GetManager():Get(self.roleID);
		self.diamIndex = self.hero.property_value == 0 and 1 or self.hero.property_value;
		self.select_diam = self.diamIndex;
		self.view.btn[CS.UGUISpriteSelector].index = self.diamIndex - 1;
		self:InitView();
	end
end

function View:InitView()
	if not self.switchConfig then
		return;
	end

	local function CloseDialog()
		self.view.diamond:SetActive(false);
		self.view.diamond.gameObject.transform:SetParent(self.view.gameObject.transform, false);
	end

    self.gray_material = self.view.btn[CS.UnityEngine.MeshRenderer].materials[0];
	CS.UGUIClickEventListener.Get(self.view.btn.gameObject).onClick = function ( obj )
		DispatchEvent("LOCAL_CLOSE_EQUIPINFOFRAME");
		
		if self.view.diamond == nil then
			self.view.diamond = "loading";
			SGK.ResourcesManager.LoadAsync(self.view[CS.SGK.UIReference], "prefabs/newRole/switchDiamond_diamond_dialog.prefab", function(o)
				local parent = UnityEngine.GameObject.FindWithTag("UGUIRoot").gameObject.transform;
				self.view.diamond = SGK.UIReference.Instantiate(o, parent);
				self.view.diamond.name = "diamond";

				CS.UGUIClickEventListener.Get(self.view.diamond.title.close.gameObject).onClick = CloseDialog;
				CS.UGUIClickEventListener.Get(self.view.diamond.BG.gameObject,true).onClick = CloseDialog

				self:ShowDiamonds();
			end);
		end


		if self.view.diamond == "loading" then
			return;
		end

		if not self.view.diamond.gameObject.activeSelf then
			self.view.diamond.gameObject.transform:SetParent(UnityEngine.GameObject.FindWithTag("UGUIRoot").gameObject.transform, false);
			self:ShowDiamonds();
		end
    end

	-- CS.UGUIClickEventListener.Get(self.view.diamond.mask.gameObject,true).onClick = function ( obj )
	-- 	for i=0,3 do
	-- 		local skillUI = self.view.diamond.skillPanel["skill"..i];
	-- 		skillUI[UnityEngine.UI.Toggle].isOn = false;
	-- 	end
    -- end
    -- for i=0,3 do
	-- 	local skillUI = self.view.diamond.skillPanel["skill"..i];
	-- 	skillUI[UnityEngine.UI.Toggle].onValueChanged:AddListener(function ( value )
	-- 		self.view.diamond.mask:SetActive(value);
	-- 		skillUI.tip:SetActive(value);
	-- 		if value then
	-- 			local skillID = self.switchConfig[self.select_diam]["skill"..i];
	-- 			self:UpdateSkillInfo(skillUI.tip, skillID);
	-- 		end
	-- 	end)
    -- end
end


-- function View:UpdateSkillInfo(skillUI, skillID)
--     local skillcfg = skillConfig.GetConfig(skillID);
--     if skillcfg.consume == 0 then
--         skillUI.cost.Text[CS.UnityEngine.UI.Text]:TextFormat("无消耗");
--     else
--         skillUI.cost.Text[CS.UnityEngine.UI.Text]:TextFormat("{0}{1}",ParameterConf.Get(skillcfg.consume_type).name, skillcfg.consume);
--     end
--     skillUI.time.Text[CS.UnityEngine.UI.Text]:TextFormat("{0}回合", skillcfg.cd);
--     skillUI.name.Text[CS.UnityEngine.UI.Text]:TextFormat(skillcfg.name);
--     skillUI.type.type1[CS.UnityEngine.UI.Image]:LoadSprite("propertyIcon/jiaobiao_"..skillcfg.skill_type);
--     skillUI.type.Text1[CS.UnityEngine.UI.Text]:TextFormat(skill_effect[skillcfg.skill_type]);
--     if skill_type[skillcfg.skill_place_type] then
--         skillUI.type.type2[CS.UnityEngine.UI.Image]:LoadSprite("propertyIcon/jiaobiao_1"..skillcfg.skill_place_type);
--         skillUI.type.Text2[CS.UnityEngine.UI.Text]:TextFormat(skill_type[skillcfg.skill_place_type]);
--         skillUI.type.type2:SetActive(true);
--     else
--         skillUI.type.Text2[CS.UnityEngine.UI.Text].text = "";
--         skillUI.type.type2:SetActive(false);
--     end
--     local detail_des = module.TalentModule.GetSkillDetailDes(skillID ,self.hero.property_list)
--     skillUI.Text[CS.UnityEngine.UI.Text]:TextFormat(detail_des[1] or "");
-- end

function View:ShowDiamonds()
	if self.switchConfig then
		self.view.diamond.get:SetActive(false);
		for i=1,7 do
			local cfg = self.switchConfig[i];
			local item = self.view.diamond.select["diamond"..i];
			if cfg then
				item.icon[CS.UnityEngine.UI.Image]:LoadSprite("icon/zuan_"..cfg.property_value);
				if i > 3 then
					item.lock.Text[UnityEngine.UI.Text]:TextFormat("暂未开放");
					item[UnityEngine.UI.Toggle].interactable = false;
					item.icon[UnityEngine.UI.Image].material = self.gray_material;
					item.effect:SetActive(false);
					item.lock:SetActive(true);
				else
					item[UnityEngine.UI.Toggle].interactable = true;
					item.effect:SetActive(true);
					item.lock:SetActive(false);
				end
				item[UnityEngine.UI.Toggle].isOn = (self.diamIndex == i);
				item.Text:SetActive(self.diamIndex == i);
				item.bring:SetActive(self.diamIndex == i);

				CS.UGUIClickEventListener.Get(item.gameObject,true).onClick = function ( obj )
					if item[UnityEngine.UI.Toggle].isOn then
						self.select_diam = i;
						self:UpdateSkill(i);
						self.view.diamond.get:SetActive(self.select_diam ~= self.diamIndex);
					end
				end
				item:SetActive(true);
			else
				item:SetActive(false);
			end
		end
		CS.UGUIClickEventListener.Get(self.view.diamond.get.gameObject).onClick = function ( obj )
			module.HeroModule.GetManager():SwitchDiamond(self.roleID, self.select_diam);
			-- for i=0,3 do
			-- 	local skillUI = self.view.diamond.skillPanel["skill"..i];
			-- 	skillUI[UnityEngine.UI.Toggle].isOn = false;
			-- end
		end
				
		self:UpdateSkill(self.diamIndex);
		self.view.diamond:SetActive(true);
	end
end

function View:UpdateSkill(index)
	local cfg = self.switchConfig[index];
	if cfg then
		-- for i=0,3 do
		-- 	local skillID = cfg["skill"..i];
		-- 	local skillcfg = skillConfig.GetConfig(skillID);
		-- 	local skillUI = self.view.diamond.skillPanel["skill"..i];
		-- 	if skillcfg then
		-- 		skillUI.icon[CS.UnityEngine.UI.Image]:LoadSprite("icon/"..(skillcfg.icon == 0 and 100011 or skillcfg.icon));
		-- 		skillUI.info.type1[CS.UnityEngine.UI.Image]:LoadSprite("propertyIcon/jiaobiao_"..skillcfg.skill_type);
		-- 		if skill_type[skillcfg.skill_place_type] then
		-- 			skillUI.info.type2[CS.UnityEngine.UI.Image]:LoadSprite("propertyIcon/jiaobiao_1"..skillcfg.skill_place_type);
		-- 			skillUI.info.type2:SetActive(true);
		-- 		else
		-- 			skillUI.info.type2:SetActive(false);
		-- 		end
		-- 		skillUI.info.time.Text[UnityEngine.UI.Text].text = tostring(skillcfg.cd);
		-- 		skillUI.name[UnityEngine.UI.Text]:TextFormat(skillcfg.name);
        --         skillUI.info.level:SetActive(false);
        --         skillUI:SetActive(true);
        --     else
        --         skillUI:SetActive(false);
		-- 		ERROR_LOG("skillcfg", skillID, "not exists");
		-- 	end
		-- end
		self.view.diamond.skillView[SGK.LuaBehaviour]:Call("InitData", {heroId = cfg.skill_star, offset = {100 ,0 ,0 ,-20 ,-85}, star = self.hero.star})
		self.view.diamond.info.Text[UnityEngine.UI.Text]:TextFormat("{0}  {1}", cfg.name, cfg.introduce);
	end
end

function View:OnDestroy()
	if self.view.diamond and self.view.diamond.gameObject.activeSelf then
		UnityEngine.GameObject.Destroy(self.view.diamond.gameObject);
	end
end

function View:listEvent()
	return {
        "LOCAL_NEWROLE_HEROIDX_CHANGE",
        "HERO_DIAMOND_CHANGE",
	}
end

function View:onEvent(event, ...)
    -- print("onEvent", event, ...);
    local eventData = ...;
	if event == "LOCAL_NEWROLE_HEROIDX_CHANGE"  then
        self:InitData(eventData);
    elseif event == "HERO_DIAMOND_CHANGE" then
		self.diamIndex = eventData;
		self.view.btn[CS.UGUISpriteSelector].index = self.diamIndex - 1;
		if self.view.diamond then
			self.view.diamond:SetActive(false);
			self.view.diamond.gameObject.transform:SetParent(self.view.gameObject.transform, false);
		end
		showDlgError(nil, "携带的钻石切换为"..self.switchConfig[self.diamIndex].name)
	end
end

return View;