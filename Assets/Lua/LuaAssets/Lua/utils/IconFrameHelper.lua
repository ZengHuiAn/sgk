local GetModule = require "module.GetModule"
local IconFrameHelper = {}

local CommonIconPool = CS.GameObjectPool.GetPool("CommonIconPool");
local TYPE = utils.ItemHelper.TYPE;

function IconFrameHelper.Release(icon)
    CommonIconPool:Release(icon.gameObject);
end

local have_error = false;

local function ResetPrefab(icon)
    if icon then
        icon[UnityEngine.RectTransform].pivot     = CS.UnityEngine.Vector2(0.5,0.5)
        icon[UnityEngine.RectTransform].anchorMin = CS.UnityEngine.Vector2(0.5,0.5)
        icon[UnityEngine.RectTransform].anchorMax = CS.UnityEngine.Vector2(0.5,0.5)

        icon.transform.localPosition              = CS.UnityEngine.Vector3.zero
        icon.transform.localRotation              = CS.UnityEngine.Quaternion.identity
        icon.transform.localScale                 = CS.UnityEngine.Vector3.one
    end
end

function IconFrameHelper.Item(data, parent, opt)
    opt = opt or {}
    local icon = SGK.UIReference.Setup(CommonIconPool:Get(parent and parent.gameObject.transform));
    ResetPrefab(icon)
    icon:SetActive(true);

    if opt.pos   then icon.transform.localPosition = Vector3(opt.pos.x,  opt.pos.y,  opt.pos.z)  end
    if opt.scale then icon.transform.localScale    = Vector3(opt.scale.x,opt.scale.y,opt.scale.z) end


    return IconFrameHelper.UpdateItem(data, icon, opt);
end

function IconFrameHelper.UpdateItem(item, icon, opt)
    opt = opt or {};

    local type         = TYPE.ITEM;
    local id           = opt.id         or item.id
    local count        = opt.count      or item.count

    local showDetail   = opt.showDetail or false
    local showName     = opt.showName   or false
    local getType      = opt.getType    or 0 --默认0 不显示（1必得2概率）

    if not icon then return icon end;

    local script = icon:GetComponent(typeof(SGK.CommonIcon));
    if not script then return icon; end
    script:SetCountScale()

    local cfg = {}
    if id or not opt.icon then
        cfg = GetModule.ItemHelper.Get(type, id or 10000, nil, count)
        if not cfg then
            script:SetInfo("", "", "");
            return icon;
        end
    else
        cfg.icon    = opt.icon
        cfg.count   = opt.count
        cfg.name    = opt.name
        cfg.quality = opt.quality
    end

    local count    = count       or cfg.count
    local name     = opt.name    or cfg.name
    local quality  = opt.quality or cfg.quality
    local iconName = "icon/" .. (opt.icon or cfg.icon);
    local name     = showName and (opt.name or cfg.name) or "";

    local count_str = "";
    if opt.count_str then
        count_str = opt.count_str;
    elseif (opt.limitCount or  -1) >= 0 then
        count_str = string.format("%d/%d", count, opt.limitCount);
    else
        count_str = (count > 0) and string.format("x%d", count) or "";
    end

    if iconName == "icon/0" then have_error = true end

    script:SetInfo(iconName, name, count_str, 0, quality);

    local sub_type = opt.sub_type or cfg.sub_type;

    if sub_type == 21 or sub_type == 22 then
        script:SetMark("Mark4", "touxiang_01");
    end

    if getType == 1 then
        icon:SetMark("Mark1", 'icon_mark_must');
    elseif getType == 2 then
        icon:SetMark("Mark1", 'icon_mark_possible');
    end

    if opt.onClick then
        script.onClick = opt.onClick;
    elseif showDetail then
        script.onClick = function()
            DispatchEvent("OnClickItemIcon", cfg, {0, count})
        end
    end

    return icon;
end

function IconFrameHelper.Equip(data, parent, opt)
    opt = opt or {}

    local icon = SGK.UIReference.Setup(CommonIconPool:Get(parent and parent.gameObject.transform));
    ResetPrefab(icon)
    icon:SetActive(true);

    if opt.pos   then icon.transform.localPosition = Vector3(opt.pos.x,  opt.pos.y,  opt.pos.z)  end
    if opt.scale then icon.transform.localScale    = Vector3(opt.scale.x,opt.scale.y,opt.scale.z) end

    return IconFrameHelper.UpdateEquip(data, icon, opt);
end

function IconFrameHelper.UpdateEquip(data, icon, opt)
    opt = opt or {}

    local type         = opt.type       or data.type or TYPE.EQUIPMENT
    local uuid         = opt.uuid       or data.uuid
    local pid          = opt.pid        or data.pid

    local showDetail   = opt.showDetail or false
    local showName     = opt.showName   or false
    local showOwner    = opt.showOwner  or false
    local getType      = opt.GetType    or 0 --默认0 不显示（1必得2概率）

    if not icon then return icon; end;

    local script = icon:GetComponent(typeof(SGK.CommonIcon));
    if not script then return icon; end
    script:SetCountScale()

    local _equip;

    if uuid then
        _equip = GetModule.EquipmentModule.GetByUUID(uuid, pid)
    else
        _equip = utils.ItemHelper.Get(type, opt.id or data.id);
    end

    if not _equip then
        script:SetInfo("", "", "");
        return icon;
    end

    local iconName = "icon/" .. (opt.icon or _equip.cfg.icon_2);
    local quality  = opt.quality or _equip.quality;
    local type     = _equip.type;
    local level    = opt.level or _equip.level or 0;
    local name     = showName and (opt.name or _equip.cfg.name) or "";
    local treasure = opt.treasure or _equip.cfg.treasure

    if iconName == "icon/0" then have_error = true end

    local owner   = nil;
    if showOwner and _equip.heroid > 0 then
        local heroCfg = module.HeroModule.GetConfig(_equip.heroid);
        owner = "icon/" .. heroCfg.icon;
    end

    local level_str = (level > 0) and  string.format("^%d", level) or ""
    script:SetInfo(iconName, name, level_str, 0, quality);
    script.Owner = owner;
    if owner then
        script:SetMark("Mark1", script.defaultIcon);
    end

    if getType == 1 then
        script:SetMark("Mark4", 'icon_mark_must');
    elseif getType == 2 then
        script:SetMark("Mark4", 'icon_mark_possible');
    end

    if treasure and treasure ~= 0 then
        script:SetMark("Mark3", 'icon_mark_rare');
    end

    if _equip.isLock then
        -- TODO: show lock mark
        -- script:SetMark("Mark2", "icon_mark_lock")
    end

    if opt.onClick then
        script.onClick = opt.onClick;
    elseif showDetail then
        script.onClick = function()
            local _cfg = setmetatable({ItemType = type,otherPid = pid},{__index = _equip}) 
            DispatchEvent("OnClickItemIcon", _cfg, {0, 0})
        end
    end

    return icon;
end

function IconFrameHelper.Hero(data,parent,opt)
    opt = opt or {}

    local icon = SGK.UIReference.Setup(CommonIconPool:Get(parent and parent.gameObject.transform));
    ResetPrefab(icon)
    icon:SetActive(true);

    if opt.pos   then icon.transform.localPosition = Vector3(opt.pos.x,  opt.pos.y,  opt.pos.z)  end
    if opt.scale then icon.transform.localScale    = Vector3(opt.scale.x,opt.scale.y,opt.scale.z) end

    return IconFrameHelper.UpdateHero(data, icon, opt);
end

function IconFrameHelper.UpdateHero(data, icon, opt)
    opt = opt or {}

    -- local vip = data.vip or 0    
    local showDetail = opt.showDetail or false
    local getType    = opt.GetType or 0 --默认0 不显示（1必得2概率）
    local showName   = opt.showName   or false

    if not icon then return icon; end;

    local script = icon:GetComponent(typeof(SGK.CommonIcon));
    if not script then return icon; end
    script:SetCountScale()

    local hero = {}
    local uuid = data.uuid;
    if uuid and uuid ~= 0 then
        hero = module.HeroModule.GetManager(data.pid):GetByUuid(uuid);
    elseif data.id then
        if data.pid == nil or data.pid == module.playerModule.GetSelfID() then
            hero = utils.ItemHelper.Get(TYPE.HERO, data.id);
        else
            hero = module.HeroModule.GetManager(data.pid):GetConfig(data.id);
        end
    end
    
    local iconName = "icon/" .. (opt.icon or hero.icon or 11000);
    local quality  = opt.quality or opt.role_stage or hero.role_stage or 0;
    local star     = opt.star or hero.star or 0;
    local level    = opt.level or hero.level or 0;
    local level_str= (level > 0) and  string.format("^%d", level) or "";
    local name     = showName and (opt.name or hero.name) or "";
    
    if iconName == "icon/0" then have_error = true end

    script:SetInfo(iconName, name, level_str, math.floor(star/6), quality);

    if opt.onClick then
        script.onClick = opt.onClick;
    elseif showDetail then
        script.onClick = function()
            DispatchEvent("OnClickItemIcon", data, {0, 0})
        end
    end

    if getType == 1 then
        script:SetMark("Mark4", 'icon_mark_must');
    elseif getType == 2 then
        script:SetMark("Mark4", 'icon_mark_possible');
    end

    return icon;
end

function IconFrameHelper.Player(data,parent,opt)
    opt = opt or {}

    local icon = SGK.UIReference.Setup(CommonIconPool:Get(parent and parent.gameObject.transform));
    ResetPrefab(icon)
    icon:SetActive(true);

    if opt.pos   then icon.transform.localPosition = Vector3(opt.pos.x,  opt.pos.y,  opt.pos.z)  end
    if opt.scale then icon.transform.localScale    = Vector3(opt.scale.x,opt.scale.y,opt.scale.z) end

    return IconFrameHelper.UpdatePlayer(data, icon, opt);
end

function IconFrameHelper.UpdatePlayer(data, icon, opt)
    opt = opt or {}

    local pid = opt.pid or data.pid
    local headFrame = opt.headFrame or data.headFrame
    -- local vip = data.vip or 0

    local showDetail = opt.showDetail or false
    local getType    = opt.GetType or 0 --默认0 不显示（1必得2概率）
    local showName   = opt.showName   or false
    local sex        = opt.sex or nil
    if not icon then return icon; end;
    local script = icon:GetComponent(typeof(SGK.CommonIcon));
    if not script then return icon; end
    script:SetCountScale()

    local function UpdatePlayerIcon(player)
        local icon = "icon/" .. player.head;
        local vip  = player.vip;
        local name = showName and player.name or "";
        local level = player.level == 0 and "" or string.format("^%d", player.level);

        script:SetInfo(icon, name, level);

        local sex = sex or (player.sex or -1)
        if sex == 0 then
            script:SetMark("Mark4", "icon_mark_male");
        elseif sex == 1 then
            script:SetMark("Mark4", "icon_mark_female");
        end
        
        headFrame = headFrame or player.headFrame;
        if headFrame and headFrame ~= "" then
            SGK.ResourcesManager.LoadAsync(script, "icon/" .. headFrame .. ".png", typeof(UnityEngine.Sprite),  function(o)
                script:SetMark("Mark1", o);
                script._Mark[0]:SetNativeSize();
                script._Mark[0].gameObject:GetComponent(typeof(UnityEngine.RectTransform)).anchorMin = CS.UnityEngine.Vector2(0.5,0.5)
                script._Mark[0].gameObject:GetComponent(typeof(UnityEngine.RectTransform)).anchorMax = CS.UnityEngine.Vector2(0.5,0.5)
            end)
        end

        if opt.onClick then
            script.onClick = opt.onClick;
        end
    end

    if pid == nil then
        return UpdatePlayerIcon(opt);
    elseif pid > 100000 and pid < 110000 then -- 竞技场ai
        local playerdata = module.traditionalArenaModule.GetNpcCfg(pid)
        local headIconCfg = module.ItemModule.GetShowItemCfg(playerdata.HeadFrameId)
        local _headFrame = headIconCfg and headIconCfg.effect

        return UpdatePlayerIcon({
            pid   = pid,
            head  = playerdata.icon,
            level = playerdata.level1,
            vip   = playerdata.vip_lv,
            sex   = playerdata.Sex,
            headFrame = _headFrame,
        })
    end
   

        if module.playerModule.IsDataExist(data.pid) then
             utils.PlayerInfoHelper.GetPlayerAddData(data.pid, 99, function ( pid_add_data )
                local player = module.playerModule.Get(data.pid)
                player.sex = pid_add_data.Sex
                player.headFrame = pid_add_data.HeadFrame
                UpdatePlayerIcon(player)  
            end)
        else
            module.playerModule.Get(data.pid, function (player)
                utils.PlayerInfoHelper.GetPlayerAddData(data.pid, 99, function ( pid_add_data )
                    player.sex = pid_add_data.Sex
                    player.headFrame = pid_add_data.HeadFrame
                    UpdatePlayerIcon(player)  
                end)
            end);
        end

    return icon;
end

function IconFrameHelper.Suit(data,parent,opt)
    opt = opt or {}

    local icon = SGK.UIReference.Setup(CommonIconPool:Get(parent and parent.gameObject.transform));
    ResetPrefab(icon)
    icon:SetActive(true);

    if opt.pos   then icon.transform.localPosition = Vector3(opt.pos.x,  opt.pos.y,  opt.pos.z)  end
    if opt.scale then icon.transform.localScale    = Vector3(opt.scale.x,opt.scale.y,opt.scale.z) end

    return IconFrameHelper.UpdateSuit(data, icon, opt);
end

function IconFrameHelper.UpdateSuit(data, icon, opt)
    opt = opt or {};

    local type         = TYPE.SUIT;
    local id           = opt.id         or data.id

    local showDetail   = opt.showDetail or false
    local showName     = opt.showName   or false
    local getType      = opt.getType    or 0 --默认0 不显示（1必得2概率）

    if not icon then return icon end;

    local script = icon:GetComponent(typeof(SGK.CommonIcon));
    if not script then return icon; end

    local cfg = {}
    if id or not opt.icon then
        cfg = GetModule.ItemHelper.Get(type, id or 10000)
        if not cfg then
            script:SetInfo("", "", "");
            return icon;
        end
    else
        cfg.icon    = opt.icon
        cfg.name    = opt.name
        cfg.quality = opt.quality
    end

    local quality  = opt.quality or cfg.quality
    local iconName = "icon/" .. (opt.icon or cfg.icon);
    local name     = showName and (opt.name or cfg.name) or "";

    --套装品质显示在框 idx 从 9 开始
    quality = quality < 10 and quality + 9
    script:SetInfo(iconName, name, "",0, quality);

    if getType == 1 then
        icon:SetMark("Mark1", 'icon_mark_must');
    elseif getType == 2 then
        icon:SetMark("Mark1", 'icon_mark_possible');
    end

    if opt.onClick then
        script.onClick = opt.onClick;
    elseif showDetail then
        script.onClick = function()
            DispatchEvent("OnClickItemIcon",{type = type,id = id}, {0, 0})
        end
    end

    return icon;
end

function IconFrameHelper.Icon(data, parent, opt)
    opt = opt or {}

    local icon = SGK.UIReference.Setup(CommonIconPool:Get(parent and parent.gameObject.transform));
    ResetPrefab(icon)
    icon:SetActive(true);

    if opt.pos   then icon.transform.localPosition = Vector3(opt.pos.x,  opt.pos.y,  opt.pos.z)  end
    if opt.scale then icon.transform.localScale    = Vector3(opt.scale.x,opt.scale.y,opt.scale.z) end

    return IconFrameHelper.UpdateIcon(data, icon, opt);
end

function IconFrameHelper.UpdateIcon(data, icon, opt)
    if data.type == TYPE.ITEM or data.type == TYPE.HERO_ITEM then
        return IconFrameHelper.UpdateItem(data, icon, opt)
    elseif data.type == TYPE.EQUIPMENT or data.type == TYPE.INSCRIPTION then
        return IconFrameHelper.UpdateEquip(data, icon, opt)
    elseif data.type == TYPE.HERO then
        return IconFrameHelper.UpdateHero(data, icon, opt)
    elseif data.type == TYPE.PLAYER then
        return IconFrameHelper.UpdatePlayer(data, icon, opt)
    elseif data.type == TYPE.SUIT then
        return IconFrameHelper.UpdateSuit(data, icon, opt)
    end
end


function IconFrameHelper.Create(IconFrame, data)  
    local otherPid = data.customCfg and data.customCfg.otherPid or data.otherPid
    local pid      = data.customCfg and data.customCfg.pid or data.pid

    local raw_data = {
        type = data.customCfg and data.customCfg.type or data.type,
        id   = data.customCfg and data.customCfg.id   or data.id or 10000,
        uuid = data.customCfg and data.customCfg.uuid or data.uuid,
        pid  = otherPid or pid,
    }

    if raw_data.type == nil or raw_data.type == 0 then
        if raw_data.uuid then
            raw_data.type = TYPE.EQUIPMENT
        elseif raw_data.pid then
            raw_data.type = TYPE.PLAYER;
        end
    end

    assert(raw_data.type);

    local customCfg = data.customCfg or {}

    local opt = {
        getType    = data.GetType or 0, --默认0 不显示（1必得2概率）
        showDetail = data.showDetail or false,

        showOwner   = customCfg.showOwner or data.showOwner or false,
        showName   = customCfg.showName or data.showName or false,
        onClick    = customCfg.func     or data.onClickFunc,

        name       = customCfg.name,
        icon       = customCfg.icon, -- or 11048,
        head       = customCfg.head, -- or 11048,
        level      = customCfg.level,
        count      = data.count or customCfg.count,
        star       = customCfg.star,
        quality    = customCfg.role_stage or customCfg.quality,

        vip        = customCfg.vip,
        headFrame  = customCfg.HeadFrame,
        sex        = customCfg.sex,

        limitCount = customCfg.limitCount or data.limitCount,
        count_str  = customCfg.count_str or data.count_str,
        treasure   = customCfg.treasure   or data.treasure,
    }

    --[[
    if data.type == TYPE.PLAYER then
        local AIInfo = guideResultModule.GetLocalPubRewardAIData(data.pid)
        if AIInfo then
            opt.level = AIInfo.level
            opt.vip   = 0
            opt.name  = AIInfo.name
            opt.icon  = AIInfo.head
        end
    end
    --]]

    local icon = nil;
    local n = IconFrame.transform.childCount;
    for i = 1, n do
        local child = IconFrame.transform:GetChild(i - 1);
        if child.gameObject:GetComponent(typeof(SGK.CommonIcon)) then
            icon = SGK.UIReference.Setup(child.gameObject);
            break;
        end
    end

    if icon == nil then
        icon = IconFrameHelper.Icon(raw_data, IconFrame, opt)
    else
        IconFrameHelper.UpdateIcon(raw_data, icon, opt)
    end

    if data.func then
        data.func(icon)
    end

    return icon;
end

return IconFrameHelper
