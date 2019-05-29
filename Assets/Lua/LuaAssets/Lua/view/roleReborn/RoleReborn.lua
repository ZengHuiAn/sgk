local HeroModule=require "module.HeroModule";
local RoleRebornModule=require "module.RoleRebornModule";
local CommonConfig = require "config.commonConfig"

local View = {}

function View:Start(data)
	self.view = SGK.UIReference.Setup(self.gameObject);
	self.Role_ID = 11000
	self:InitClick()
	self:initEffert()
end

function View:InitClick()
	CS.UGUIClickEventListener.Get(self.view.middleAdd.addRole.gameObject).onClick = function ()
		DialogStack.PushPref("roleReborn/RoleSelect",{idx = 1})
	end
	CS.UGUIClickEventListener.Get(self.view.root.top.close.gameObject).onClick = function ()
		self.view.middleAdd:SetActive(true)
		self.view.root:SetActive(false)
	end
    CS.UGUIClickEventListener.Get(self.view.help.gameObject).onClick = function ()
        utils.SGKTools.ShowDlgHelp(SGK.Localize:getInstance():getValue("huoban_chongsheng_01"))
    end
end

function View:UpALLView()
	self:initData()
	self:InitSpine()
	self:initEffert()
	self:UpTop()
	self:UpLeft()
	self:UpBottom()
end

function View:initData()
	self.Hero = HeroModule.GetManager():Get(self.Role_ID)
	ERROR_LOG("重生角色信息",self.Hero.pid,self.Hero.uuid,self.Hero.exp,sprinttb(self.Hero))
	self.heroCfg = utils.ItemHelper.Get(utils.ItemHelper.TYPE.HERO, self.Role_ID)
end

function View:UpTop()
	self:UpName()
	self:upPropertyIcon()
end

function View:InitSpine()
	local animation = self.view.root.middle.spine[CS.Spine.Unity.SkeletonGraphic];
    animation.skeletonDataAsset = SGK.ResourcesManager.Load("roles/"..tostring(self.Role_ID).."/"..tostring(self.Role_ID).."_SkeletonData.asset") or SGK.ResourcesManager.Load("roles/11000/11000_SkeletonData.asset");
    --animation.skeletonDataAsset =SGK.ResourcesManager.Load("roles/11000/11000_SkeletonData");
    self.view.root.middle.spine.transform.localScale=Vector3(0.6,0.6,1)
    animation.startingAnimation = "idle";
    animation.startingLoop = true;
    animation:Initialize(true);
end

function View:initEffert()
	SGK.ResourcesManager.LoadAsync("prefabs/effect/UI/fx_chongsheng_back.prefab", function(obj)
        if obj and self.view.EffectBack.transform.childCount == 0 then
            CS.UnityEngine.GameObject.Instantiate(obj.transform,self.view.EffectBack.transform)    
        end
    end)
	SGK.ResourcesManager.LoadAsync("prefabs/effect/UI/fx_chongsheng_front.prefab", function(obj)
        if obj and self.view.root.EffectFront.transform.childCount == 0 then
            CS.UnityEngine.GameObject.Instantiate(obj.transform,self.view.root.EffectFront.transform)    
        end
    end)
end

function View:UpName()
	self.view.root.top.roleInfo.name[UI.Image]:LoadSprite("title/yc_n_"..self.Role_ID)
end

local propertyIcon = {
    [1] = "propertyIcon/shuxing_feng",
    [2] = "propertyIcon/shuxing_shui",
    [3] = "propertyIcon/shuxing_huo",
    [4] = "propertyIcon/shuxing_tu",
    [5] = "propertyIcon/shuxing_guang",
    [6] = "propertyIcon/shuxing_an",
    [7] = "propertyIcon/shuxing_quan",
}

function View:upPropertyIcon()
    local _iconList = {}
    local _profession = self.heroCfg.cfg.profession
    local _type = self.heroCfg.cfg.type
    if self.heroCfg.cfg.profession == 0 then
        local _cfg = module.TalentModule.GetSkillSwitchConfig(11000)
        local _idx = self.heroCfg.property_value
        if _cfg[_idx] then
            _profession = _cfg[_idx].profession
            _type = _cfg[_idx].element_type
        end
    end

    for i = 1,8 do
        if (_type & (1 << (i - 1))) ~= 0 then
            table.insert(_iconList, propertyIcon[i])
        end
    end
    --if _profession >= 10 then
        table.insert(_iconList, string.format("propertyIcon/jiaobiao_%s", _profession))
    -- else
    --     table.insert(_iconList, string.format("propertyIcon/jiaobiao_0%s", _profession))
    -- end

    for i = 1, #self.view.root.top.roleInfo.property.list do
        local _view = self.view.root.top.roleInfo.property.list[i]
        _view:SetActive(_iconList[i] and true)
        if _iconList[i] then
            if string.find(_iconList[i], "propertyIcon/shuxing") then
                _view.transform.localScale = Vector3(0.7, 0.7, 1)
            else
                _view.transform.localScale = Vector3(1, 1, 1)
            end
            _view[UI.Image]:LoadSprite(_iconList[i])
        end
    end
end

function View:UpLeft()
	self.view.root.left.level.count[UI.Text].text = self.heroCfg.level
	self.view.root.left.adv.count[UI.Text].text = self.heroCfg.stage.."阶"
	local starCount = self.heroCfg.star
	self.view.root.left.star.count[UI.Text].text = math.floor((starCount/6)).."星"..(starCount%6).."段"
end

function View:getComsume()
	local count = 0
		count = CommonConfig.Get(18).para1 + CommonConfig.Get(19).para1*self.heroCfg.stage + CommonConfig.Get(20).para1*self.heroCfg.star
	return count
end

function View:UpBottom()
	self.view.root.bottom.reBorn.Text[UI.Text].text = self:getComsume()
	CS.UGUIClickEventListener.Get(self.view.root.bottom.reBorn.gameObject).onClick = function ()
		--RoleRebornModule.RoleReborn(self.Hero.gid,self.Hero.uuid)
		--RoleRebornModule.GetRoleRebornRewardList(self.Role_ID)
		DialogStack.PushPref("roleReborn/RoleRebornTip",{roleId = self.Role_ID})
	end
end

function View:OnDestory()

end

function View:listEvent()
    return {
    "OPEN_ROLE_REBORN",
    "ROLE_REBORN_SUCCESS",
    }
end

function View:onEvent(event,data)
	if event == "OPEN_ROLE_REBORN" then
		if data.RoleId then
			self.Role_ID = data.RoleId
			print("选择的角色id",self.Role_ID)
		end
		self.view.middleAdd:SetActive(false)
		self:UpALLView()
		self.view.root:SetActive(true)
		--DialogStack.PushPref("roleReborn/RoleReborn",nil,self.view.childRoot.gameObject)
	elseif event == "ROLE_REBORN_SUCCESS" then
		self.view.middleAdd:SetActive(true)
		self.view.root:SetActive(false)
	end
end


return View;