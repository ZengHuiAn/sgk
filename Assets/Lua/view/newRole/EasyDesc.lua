local HeroModule = require "module.HeroModule"
local Time = require "module.Time";

local View = {}
function View:Start(arg)
	self.root =SGK.UIReference.Setup(self.gameObject);
	self.view=self.root.view

	CS.UGUIClickEventListener.Get(self.view.ReturnToggle.gameObject,true).onClick = function()
		CS.UnityEngine.GameObject.Destroy(self.gameObject)
	end

	self:InitView(arg)
end

-- function View:deActive(deActive)
-- 	if self.root then
-- 		local co = coroutine.running();
-- 		self.view.gameObject:GetComponent(typeof(UnityEngine.RectTransform)):DOLocalMove(Vector3(600,75,0),0.1):OnComplete(function ( ... )
-- 			coroutine.resume(co);
-- 		end)
-- 		coroutine.yield();
-- 		return true
-- 	end
-- end
local propretyImageTab={"shuxing_feng","shuxing_shui","shuxing_huo","shuxing_tu","shuxing_guang","shuxing_an"}
local animationTab={"attack1","attack3","attack3"}
function View:InitView(data)
	self.heroID = data and data.heroid or 11000;
	local cfg=HeroModule.GetConfig(self.heroID)

	if cfg then
		self.view.dialog.Text[UI.Text].text=cfg.info1

		self.view.nameAndTitle[1][UI.Text].text=cfg.name
		self.view.nameAndTitle[2][UI.Text].text=cfg.info_title

		self.view.elseInfo[1].Text[UI.Text].text=cfg.info4
		self.view.elseInfo[2].Text[UI.Text].text=cfg.info5
		self.view.elseInfo[3].Text[UI.Text].text=cfg.info6

		self.view.credential.Text[UI.Text].text=cfg.info

		self.view.specialty.job.Text[UI.Text].text=cfg.info2
		self.view.specialty.proprety.Text[UI.Text].text=cfg.info3

		if not self.view.HeroAnimation:GetComponent(typeof(CS.Spine.Unity.SkeletonGraphic)) then
			self.view.HeroAnimation:AddComponent(typeof(CS.Spine.Unity.SkeletonGraphic));
		end
		self._SkeletonGraphic=self.view.HeroAnimation:GetComponent(typeof(CS.Spine.Unity.SkeletonGraphic))
		local _hero=HeroModule.GetManager():Get(self.heroID)
		self._SkeletonGraphic.skeletonDataAsset =utils.SGKTools.loadExistSkeletonDataAsset("roles/",self.heroID,_hero.showMode,"_SkeletonData.asset")-- SGK.ResourcesManager.Load("roles/"..suitCfg.showMode.."/"..suitCfg.showMode.."_SkeletonData");--skeletonDataName;

		self._SkeletonGraphic.startingAnimation ="idle"
		self._SkeletonGraphic.startingLoop = true
		self._SkeletonGraphic:Initialize(true);

		local _Position,_Scale = DATABASE.GetBattlefieldCharacterTransform(_hero.showMode, "ui");
		self.view.HeroAnimation.transform.localPosition = _Position*100+ Vector3(50,-150,0)
		self.view.HeroAnimation.transform.localScale = _Scale

		local _type = cfg.type;
		local _profession = cfg.profession

		--proprety
		local j=0
		for i=1,8 do
			if (_type & (1 << (i - 1))) ~= 0 then
				j=j+1
				self.view.specialty.proprety.Icon[j][UI.Image]:LoadSprite("propertyIcon/"..propretyImageTab[i])
				self.view.specialty.proprety.Icon[j].gameObject:SetActive(true)
			end
		end

		if _profession == 0 then
	        local _cfg = module.TalentModule.GetSkillSwitchConfig(11000)
	        local _idx = _hero.property_value~=0 and _hero.property_value or 2

	        ERROR_LOG(_hero.property_value,_idx)
	        if _cfg[_idx] then
	            _profession = _cfg[_idx].profession
	        end
	    end

	    self.view.specialty.job.Icon[1][UI.Image]:LoadSprite("propertyIcon/jiaobiao_".._profession)
	end
end
local startTime=nil
function View:Update()
	if self._SkeletonGraphic then
		if not startTime then
			startTime=Time.now()
		end
		if Time.now()-startTime>=5 then
			self._SkeletonGraphic.AnimationState:SetAnimation(0, "attack1", false);
			self._SkeletonGraphic.AnimationState:AddAnimation(0, "idle", true, 0);
			startTime=nil
		end
	end
end

function View:listEvent()
	return {
		"Equip_Hero_Index_Change",
	}
end

function View:onEvent(event, data)
	if event == "Equip_Hero_Index_Change" then
		local info={}
		info.heroid=data.heroid
		self:InitView(info)
	end
end

return View;