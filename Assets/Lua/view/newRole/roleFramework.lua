local heroLevelup = require "hero.HeroLevelup"
local roleFramework = {}

local colorCfg = {
    [1] = "#30FF00FF",
    [2] = "#00deffFF",
    [3] = "#e167ffFF",
    [4] = "#ff9638FF",
    [5] = "#ff0000FF",
}

local childCfg = {
    [1] = {name = "newRole/roleEquip"},
    [2] = {name = "newRole/roleAdv"},
    [3] = {name = "newRole/roleStar"},
    [4] = {name = "newRole/roleWeaponStar"},
}

function roleFramework:Start(data)
    self.childeList = {}
    self.loadLock = false
    self:initData(data)
    self:initUi()
    module.guideModule.PlayByType(107, 0.3)
end

function roleFramework:initUi()
    self.view = CS.SGK.UIReference.Setup(self.gameObject)

    CS.UGUIClickEventListener.Get(self.view.root.bg.gameObject,true).onClick = function()
        DispatchEvent("LOCAL_CLOSE_EQUIPINFOFRAME");
    end

    self:showChilde(self.savedValues.idx or 1)
    self:initBtn()
    self:initHeroAnim()
    self:initRoleInfo()
    self:initRoleList()
    self:initBottom()
    self:upUi()
    local _idx = self:getIdx(self.heroId)
    self.ScrollView:ScrollMove(_idx - 1)
    self.view.root.leftBtn:SetActive(_idx ~= 1)
    self.view.root.rightBtn:SetActive(_idx < #self.heroList)
    CS.UnityEngine.GameObject.Instantiate(SGK.ResourcesManager.Load("prefabs/base/CurrencyChat.prefab"), self.view.transform)
    DispatchEvent("CurrencyRef",{3,90002})
end

function roleFramework:getIdx(heroId)
    for i,v in ipairs(self.heroList) do
        if v.id == heroId then
            return i
        end
    end
    return 1
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

function roleFramework:upPropertyIcon()
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

    for i = 1, #self.view.root.roleInfo.property.list do
        local _view = self.view.root.roleInfo.property.list[i]
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

function roleFramework:initBtn()
    CS.UGUIClickEventListener.Get(self.view.root.leftBtn.gameObject).onClick = function()
        local _idx = self:getIdx(self.heroId)
        if _idx > 1 then
            self:upRoleById(self.heroList[_idx - 1].id)
        end
        DispatchEvent("LOCAL_CLOSE_EQUIPINFOFRAME");
    end
    CS.UGUIClickEventListener.Get(self.view.root.rightBtn.gameObject).onClick = function()
        local _idx = self:getIdx(self.heroId)
        if _idx < #self.heroList then
            self:upRoleById(self.heroList[_idx + 1].id)
        end
        DispatchEvent("LOCAL_CLOSE_EQUIPINFOFRAME");
    end
    CS.UGUIClickEventListener.Get(self.view.root.roleInfo.gameObject).onClick = function()
        DispatchEvent("LOCAL_CLOSE_EQUIPINFOFRAME");
        DialogStack.PushPref("newRole/EasyDesc", {heroid = self.heroId})   
    end
end
function roleFramework:setUITrue(t)
    self.view.root.roleInfo.gameObject:SetActive(t)
    self.view.root.infobg.gameObject:SetActive(t)
    self.view.root.level.gameObject:SetActive(t)
    self.view.root.power.gameObject:SetActive(t)
end
function roleFramework:setUIFalse(f)
    self.view.root.roleInfo.gameObject:SetActive(f)
    self.view.root.infobg.gameObject:SetActive(f)
    self.view.root.level.gameObject:SetActive(f)
    self.view.root.power.gameObject:SetActive(f)
end
function roleFramework:showChilde(i)
    self.loadLock = true
    if i==2 then
        self:setUITrue(false)
    else
        self:setUIFalse(true)
    end
    DialogStack.PushPref(childCfg[i].name, {heroId = self.heroId, goInsc = self.savedValues.goInsc, showIdxEffect = self.showIdxEffect}, self.view.root.childRoot.transform, function(obj)
        self.loadLock = false
        self.childeList[i] = obj
        for k,v in pairs(self.childeList) do
            self.childeList[k]:SetActive(k == i)
        end
        DispatchEvent("LOCAL_NEWROLE_HEROIDX_CHANGE", {heroId = self.heroId})
    end)
    DispatchEvent("ROLE_FRAME_CHANGE", i);
end

function roleFramework:upBottomTip()
    local _cfg = {
        [1] = module.RedDotModule.Type.Hero.Equip,
        [2] = module.RedDotModule.Type.Hero.PartnerAdv,
        [3] = module.RedDotModule.Type.Hero.Star,
        [4] = module.RedDotModule.Type.Weapon.Star,
    }
    for i = 1, #self.view.root.bottom do
        local _view = self.view.root.bottom[i]
        _view.tip:SetActive(module.RedDotModule.GetStatus(_cfg[i], self.heroId, _view.tip))
    end
end

function roleFramework:initBottom()
    for i = 1, #self.view.root.bottom do
        local _view = self.view.root.bottom[i]
        _view[UI.Toggle].onValueChanged:RemoveAllListeners()
        _view[UI.Toggle].onValueChanged:AddListener(function(value)
            self.savedValues.idx = i
            if value then
                self.view.root.selectImage.transform:DOMove(Vector3(_view.transform.position.x, self.view.root.selectImage.transform.position.y, self.view.root.selectImage.transform.position.z), 0.2):SetEase(CS.DG.Tweening.Ease.OutBack)
            end
            _view.arr:SetActive(value)
        end)
        CS.UGUIClickEventListener.Get(_view.gameObject).onClick = function()
            DispatchEvent("LOCAL_CLOSE_EQUIPINFOFRAME");
            if childCfg[i] and not self.loadLock then
                if self.childeList[i] then
                    for k,v in pairs(self.childeList) do
                        self.childeList[k]:SetActive(k == i)
                    end
                    if i==2 then
                       self:setUITrue(false)
                    else
                       self:setUIFalse(true)
                    end
                    DispatchEvent("LOCAL_NEWROLE_HEROIDX_CHANGE", {heroId = self.heroId})
                else
                    self:showChilde(i)
                end
                self:setRoleStarInfo()
            end
            --非装备界面关闭heroAnim
			self.view.root.heroAnim:SetActive(i == 1)
			self.view.root.role_bg:SetActive(i == 1)
        end
    end

    self.view.root.bottom[self.savedValues.idx or 1][UI.Toggle].isOn = true
    self.view.root.selectImage.transform.position = Vector3(self.view.root.bottom[self.savedValues.idx or 1].transform.position.x, self.view.root.selectImage.transform.position.y, self.view.root.selectImage.transform.position.z)
    --非装备界面关闭heroAnim
    self.view.root.heroAnim:SetActive(self.savedValues.idx==1)
    self.view.root.role_bg:SetActive(self.savedValues.idx==1)

    self:upBottomTip()
end

function roleFramework:initRoleInfo()
    self.rolePowerNumber = self.view.root.power.number[UI.Text]
    self.roleName = self.view.root.roleInfo.name[UI.Image]
    self.roleStartNode = self.view.root.roleInfo.startNode
    self.roleProperty = self.view.root.roleInfo.property
    self.roleAdv = self.view.root.roleInfo.adv
    self.levelNumber = self.view.root.level.levelNumber[UI.Text]
    self.expNumber = self.view.root.level.exp[UI.Text]
end

function roleFramework:upUi()
    self:upRoleInfo()
    self:upHeroAnim()
    self:upBottomTip()
    self:upPropertyIcon()
end

function roleFramework:upRoleInfo()
    self.rolePowerNumber.text = tostring(self.heroCfg.capacity)
    self.roleAdv.number[UI.Text].text = tostring(self.heroCfg.stage)
    ERROR_LOG("self.heroCfg.stage",self.heroCfg.stage)
    local _, _color = UnityEngine.ColorUtility.TryParseHtmlString(colorCfg[math.floor(self.heroCfg.stage / 4) + 1] or colorCfg[1])
    self.roleAdv.number[UI.Text].color = _color
    for i = 1, #self.roleStartNode do
        self.roleStartNode[i]:SetActive(i <= math.floor(self.heroCfg.star / 6))
    end
    self.roleName:LoadSprite("title/yc_n_"..self.heroId)

    self.levelNumber.text = "Lv "..self.heroCfg.level
    local hero_level_up_config = heroLevelup.GetExpConfig(1, self.heroCfg);
    local Level_exp = hero_level_up_config[self.heroCfg.level]
    local Next_hero_level_up = hero_level_up_config[self.heroCfg.level+1] and hero_level_up_config[self.heroCfg.level+1] or hero_level_up_config[self.heroCfg.level]

    local _value = (self.heroCfg.exp-Level_exp)/(Next_hero_level_up-Level_exp)
    if self.heroCfg.level >= 200 then
        self.expNumber.text = "100%"
    else
        self.expNumber.text = math.floor(_value * 100).."%"
    end
end

function roleFramework:checkProperty(id)
    if UnityEngine.Application.isEditor then
        coroutine.resume(coroutine.create( function()
                local hero = module.HeroModule.GetManager():Get(id);
                local data = utils.NetworkService.SyncRequest(27, {nil, 0, {hero.uuid}});
                local pid, code = data[3], data[4];
                local info = ProtobufDecode(code, "com.agame.protocol.FightPlayer")
                print(info.name, info.level);

                local match = true;
                for k, v in ipairs(info.roles) do

                        local t = {}

                        local merge = {}
                        for _, vv in ipairs(v.propertys) do
                                merge[vv.type] = {0, vv.value};
                        end

                        hero:ReCalcProperty();
                        for kk, vv in pairs(hero.property_list) do
                                merge[kk] = merge[kk] or {0, 0}
                                merge[kk][1] = vv;
                        end

                        local str = v.id .. " " .. hero.name .. " " .. hero.uuid;
                        for k, v in pairs(merge) do
                                str =  str .. "\n" .. k .. "\t" .. v[1] .. "\t" .. v[2];
                                if v[1] ~= v[2] then
                                        str = str .. "\t*";
                                        match = false;
                                end
                        end
                        if match then
                            print(str);
                        else
                            ERROR_LOG(str);
                        end
                end
        end));
    end
end

function roleFramework:upRoleById(id)
    local _idx = self:getIdx(id)
    self.view.root.leftBtn:SetActive(_idx ~= 1)
    self.view.root.rightBtn:SetActive(_idx < #self.heroList)
    local _heroCfg = module.HeroModule.GetManager():Get(id or 11000)
    if _heroCfg and _heroCfg.uuid then
        self.savedValues.heroComposeId = nil
        self:upData(id)
        DispatchEvent("LOCAL_NEWROLE_HEROIDX_CHANGE", {heroId = self.heroId})
        self:upUi()
        self.ScrollView:ItemRef()
        self.ScrollView:ScrollMove(self:getIdx(self.heroId) - 4)
        self:checkProperty(id);
        for k,v in pairs(self.childeList) do
            if v.activeSelf then
                v:SetActive(false)
                v:SetActive(true)
            end
        end
    else
        -- local _product = module.ShopModule.GetManager(6, id) and module.ShopModule.GetManager(6, id)[1]
        -- _product = _product or {}
        -- local _count = module.ItemModule.GetItemCount(_product.consume_item_id1 or 0)
        -- local _info = {
        --     piece_id = _product.consume_item_id1 or 0,
        --     id = id,
        --     cfg = module.HeroModule.GetConfig(id),
        --     compose_count = _product.consume_item_value1,
        --     piece_type = _product.consume_item_type1,
        --     product_gid = _product.gid
        -- }
        self.savedValues.heroComposeId = id
        DialogStack.Push("HeroComposeFrame",{roleID = id, source = 1})
    end
end

function roleFramework:initRoleList()
    self.heroList = module.HeroModule.GetSortHeroList(1)
    local _haveList = module.HeroModule.GetSortHeroList(0)
    local _list = {}
    for i,v in ipairs(_haveList) do
        if v.uuid == nil then
            local _productA = module.ShopModule.GetManager(6, v.id) and module.ShopModule.GetManager(6, v.id)[1]
            _productA = _productA or {}
            local _count = module.ItemModule.GetItemCount(_productA.consume_item_id1 or 0)
            table.insert(_list, {cfg = v, count = _count})
        end
    end
    table.sort(_list, function(a, b)
        if a.cfg.role_stage ~= b.cfg.role_stage then
            return a.cfg.role_stage > b.cfg.role_stage
        end
        if a.count == b.count then
            return a.cfg.id < b.cfg.id
        end
        return a.count > b.count
    end)
    for i,v in ipairs(_list) do
        table.insert(self.heroList, v.cfg)
    end

    self.ScrollView = self.view.root.roleList.ScrollView.Viewport.Content[CS.ScrollViewContent]
    self.ScrollView.RefreshIconCallback = function (obj, idx)
        local _view = CS.SGK.UIReference.Setup(obj.gameObject)
        local _tab = self.heroList[idx + 1]
        local _cfg = {}
        if _tab.uuid then
            _cfg = utils.ItemHelper.Get(utils.ItemHelper.TYPE.HERO, _tab.id)
        else
            _cfg.icon = _tab.icon
            _cfg.role_stage = 0
            _cfg.level = 0
			_cfg.star = 0
        end

        _view.root.tip:SetActive(_tab.uuid and module.RedDotModule.GetStatus(module.RedDotModule.Type.Hero.Hero, _tab.id, _view.root.tip))

        utils.IconFrameHelper.Create(_view.root.IconFrame, {type = 42, customCfg = _cfg, func = function(obj)
            --[[
            obj.other:SetActive(_tab.id == self.heroId)

            local _product = module.ShopModule.GetManager(6, _tab.id) and module.ShopModule.GetManager(6, _tab.id)[1]
            _product = _product or {}
            local _count = module.ItemModule.GetItemCount(_product.consume_item_id1 or 0)
            if _count > 0 and (not _tab.uuid) then
                obj.Frame[CS.UGUISpriteSelector].index = 6
            end
            obj[SGK.CharacterIcon].gray = not _tab.uuid and (_count == 0)
            _view.root.Slider:SetActive(not _tab.uuid and _count > 0)
            if _view.root.Slider.activeSelf then
                _view.root.Slider[UI.Slider].maxValue = _product.consume_item_value1
                _view.root.Slider[UI.Slider].value = _count
                _view.root.Slider.Text[UI.Text].text = string.format("%d/%d", _count, _product.consume_item_value1)
            end
            --]]
        end})
        _view.root.select:SetActive(_tab.id == self.heroId)

        CS.UGUIClickEventListener.Get(_view.root.gameObject).onClick = function()
            if _tab.id ~= self.heroId then
                self:upRoleById(_tab.id)
                self:setRoleStarInfo()
            end
            DispatchEvent("LOCAL_CLOSE_EQUIPINFOFRAME");
        end

        obj:SetActive(true)
    end
    self.ScrollView.DataCount = #self.heroList
end

function roleFramework:upData(heroId)
    local _heroCfg = utils.ItemHelper.Get(utils.ItemHelper.TYPE.HERO, heroId)
    if _heroCfg and _heroCfg.uuid then
        self.heroId = heroId
        self.savedValues.heroId = self.heroId
        self.heroCfg = utils.ItemHelper.Get(utils.ItemHelper.TYPE.HERO, self.heroId or 11000)
    end
end

function roleFramework:initHeroAnim()
    self.animList = {}
    local _color = {
        [0] = "hong",
        [1] = "hong",
        [2] = "huang",
        [3] = "zi",
        [4] = "lv",
        [5] = "hei",
        [6] = "fen",
        [7] = "lan",
    }
    self.bossAnim = self.view.root.heroAnim[CS.Spine.Unity.SkeletonGraphic]
end

function roleFramework:playHeroAnim()
    if self.heroId == 11000 then
        local _color = {
            [0] = "hong",
            [1] = "hong",
            [2] = "huang",
            [3] = "zi",
            [4] = "lv",
            [5] = "hei",
            [6] = "fen",
            [7] = "lan",
        }
        self.bossAnim.initialSkinName = _color[self.heroCfg.property_value]
    else
        self.bossAnim.initialSkinName = "default"
    end
    self.bossAnim.startingAnimation = "idle"
    local _pos, _scale = DATABASE.GetBattlefieldCharacterTransform(tostring(self.heroCfg.mode), "ui")
    self.view.root.heroAnim.transform.localPosition = (_pos * 100)
    self.view.root.heroAnim.transform.localScale = _scale * 0.8
end
local cachekey = false;
function roleFramework:upHeroAnim()
    if self.animList[self.heroCfg.mode] and  self.animList[self.heroCfg.mode].dataAsset then
        self.bossAnim.skeletonDataAsset = self.animList[self.heroCfg.mode].dataAsset
        self.bossAnim.material = self.animList[self.heroCfg.mode].material
        self:playHeroAnim()
        self.bossAnim:Initialize(true)
    else
        self.bossAnim.skeletonDataAsset = nil;
        self.bossAnim:Initialize(true)

        SGK.ResourcesManager.LoadAsync(self.bossAnim, string.format("roles/%s/%s_SkeletonData.asset", self.heroCfg.mode, self.heroCfg.mode), function(o)
            if o ~= nil then
                if not self.animList[self.heroCfg.mode] then 
                    self.animList[self.heroCfg.mode] = {} 
                end
                if cachekey then
                    self.animList[self.heroCfg.mode].dataAsset = o
                    self.bossAnim.skeletonDataAsset = self.animList[self.heroCfg.mode].dataAsset
                    self:playHeroAnim()
                    self.bossAnim:Initialize(true)
                else
                    self.bossAnim.skeletonDataAsset = o
                    self:playHeroAnim()
                    self.bossAnim:Initialize(true)
                end
            else
                SGK.ResourcesManager.LoadAsync(self.bossAnim, string.format("roles/11000/11000_SkeletonData.asset"), function(o)
                    self.bossAnim.skeletonDataAsset = o
                    self.bossAnim:Initialize(true);
                end);
            end
        end);
    end
end

function roleFramework:initData(data)
    if data then
        self.heroId = data.heroid or 11000
        self.savedValues.heroId = self.heroId
        if data.idx then
            self.savedValues.idx = data.idx
        end
        self.savedValues.goInsc = data.goInsc
        self.showIdxEffect = data.showIdx
    elseif self.savedValues.heroComposeId then
        local _cfg = utils.ItemHelper.Get(utils.ItemHelper.TYPE.HERO, self.savedValues.heroComposeId)
        if _cfg and _cfg.uuid then
            self.heroId = self.savedValues.heroComposeId
        end
    elseif self.savedValues.heroId then
        self.heroId = self.savedValues.heroId
    else
        self.heroId = 11000
    end
    self.heroCfg = utils.ItemHelper.Get(utils.ItemHelper.TYPE.HERO, self.heroId or 11000)

    assert(self.heroCfg,'hero config', self.heroId, "not exists")
end

function roleFramework:setRoleStarInfo()
    if self.savedValues.idx == 3 then
        for i = 1, #self.roleStartNode do
            if i>math.floor(self.heroCfg.star / 6) then
                self.roleStartNode[i][UI.Image].color = { r = 1, g = 1, b = 1, a = 0};
            end 
        end
    else
        for i = 1, #self.roleStartNode do
             self.roleStartNode[i][UI.Image].color = { r = 1, g = 1, b = 1, a = 1};      
        end
    end
end

function roleFramework:playUpStarFx(createPos,starIdx)
        local localPos = self.view.root.roleInfo.startNode.transform:TransformPoint(self.view.root.roleInfo.startNode[starIdx].transform.localPosition)
        local tagetPos = self.view.transform:InverseTransformPoint(localPos)

        local prefab_fly = SGK.ResourcesManager.Load("prefabs/effect/UI/fx_ui_dati_lizi.prefab");
        local prefab = SGK.ResourcesManager.Load("prefabs/effect/UI/fx_ui_dati_bao.prefab");

        local o = UnityEngine.GameObject.Instantiate(prefab_fly,self.view.transform); 
        o.transform.localPosition = createPos            
        o.transform.localScale=Vector3.one*100
        o.layer = UnityEngine.LayerMask.NameToLayer("UI");
        for i = 0,o.transform.childCount-1 do
            o.transform:GetChild(i).gameObject.layer = UnityEngine.LayerMask.NameToLayer("UI");
        end

        o.transform:DOLocalMove(tagetPos,0.5):OnComplete(function( ... )
            local _o = prefab and UnityEngine.GameObject.Instantiate(prefab, self.view.transform);
            _o.transform.localScale = Vector3.one*100
            _o.transform.localPosition = tagetPos
            _o.layer = UnityEngine.LayerMask.NameToLayer("UI");
            for i = 0,_o.transform.childCount-1 do
                _o.transform:GetChild(i).gameObject.layer = UnityEngine.LayerMask.NameToLayer("UI");
            end
       
            local _obj = _o:GetComponentInChildren(typeof(UnityEngine.ParticleSystem))
            UnityEngine.Object.Destroy(_o, _obj.main.duration)                                
            
            CS.UnityEngine.GameObject.Destroy(o)
            for i = 1, #self.roleStartNode do
                if i<= math.floor(self.heroCfg.star / 6) then
                    self.roleStartNode[i][UI.Image].color = { r = 1, g = 1, b = 1, a = 1};  
                end    
            end
        end)
end

function roleFramework:onEvent(event, data)
    if event == "HERO_INFO_CHANGE" or event == "GIFT_INFO_CHANGE" then
        self:upData(self.heroId)
        self:upUi()
        self.ScrollView:ItemRef()
    elseif event == "LOCAL_GUIDE_CHANE" then
        module.guideModule.PlayByType(107, 0.3)
    elseif event == "LOCAL_NEWROLE_GETNEWHERO" then
        self.heroList = module.HeroModule.GetSortHeroList(0)
        self:upRoleById(data.heroId)
    elseif event == "EQUIPMENT_INFO_CHANGE" or event == "HERO_BUFF_CHANGE" then
        self:upRoleInfo()
        self:upUi()
        self.ScrollView:ItemRef()
    elseif event == "ROLE_FRAME_MOVE_TO_FRONTLAYER" then
        self:addGameObjectToFrontLayer(data)
    elseif event == "LOCAL_CHANGE_HERO" then
        if self.savedValues.idx ~=1 then
            self.savedValues.idx = 1
            if self.childeList[1] then
                for k,v in pairs(self.childeList) do
                    self.childeList[k]:SetActive(k == 1)
                end
                self:setUIFalse(true)
                DispatchEvent("LOCAL_NEWROLE_HEROIDX_CHANGE", {heroId = data.heroId})
            else
                self:showChilde(1)
            end
            self.view.root.bottom[1][UI.Toggle].isOn = true
            self.view.root.selectImage.transform.position = Vector3(self.view.root.bottom[1].transform.position.x, self.view.root.selectImage.transform.position.y, self.view.root.selectImage.transform.position.z)
        end
        -- ERROR_LOG(self.savedValues.goInsc, data.goInsc)
        if not not self.savedValues.goInsc ~= data.goInsc then
            ERROR_LOG("goInsc err")
        end
        self:upRoleById(data.heroId) 
    elseif event == "Close_Star_up" then
        local createPos = data[1]
        local Idx = data[2]
        self:playUpStarFx(createPos,Idx)
    end
end

function roleFramework:addGameObjectToFrontLayer(gameObject)
    gameObject.transform:SetParent(self.view.root.frontLayer.transform);
end

function roleFramework:listEvent()
	return {
    	"HERO_INFO_CHANGE",
        "LOCAL_GUIDE_CHANE",
        "LOCAL_NEWROLE_GETNEWHERO",
        "GIFT_INFO_CHANGE",
        "EQUIPMENT_INFO_CHANGE",
        "HERO_BUFF_CHANGE",
        "ROLE_FRAME_MOVE_TO_FRONTLAYER",
        "LOCAL_CHANGE_HERO",
        "Close_Star_up",
    }
end

function roleFramework:OnDestroy()
    DispatchEvent("CurrencyRef")
end
function roleFramework:deActive()
    if self.view[UnityEngine.Animator] then
        self.view[UnityEngine.Animator]:Play("roleFramework_ani1")
    end
    self.view[UnityEngine.CanvasGroup]:DOFade(0, 0.3);
    Sleep(0.05);
    return true
end


return roleFramework
