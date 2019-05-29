local HeroEvoConfig = require "hero.HeroEvo"
local BuffSystem  = require "battlefield2.system.Buff"
local HeroModule = require "module.HeroModule"
local battle_config = require "config/battle";
local RoleInfoPanel
local RoleInfoPanel_loading

local EventManager = require "utils.EventManager"
local eventManager = EventManager.getInstance()

local role_master_list = {
    {master = "airMaster",   index = 3, desc = "风系", colorindex = 0},
    {master = "dirtMaster",  index = 2, desc = "土系", colorindex = 1},
    {master = "waterMaster", index = 0, desc = "水系", colorindex = 2},
    {master = "fireMaster",  index = 1, desc = "火系", colorindex = 3},
    {master = "lightMaster", index = 4, desc = "光系", colorindex = 4},
    {master = "darkMaster",  index = 5, desc = "暗系", colorindex = 5},
}

local function GetMasterIcon(role, other_info)
    table.sort(role_master_list, function (a, b)
        if role[a.master] ~= role[b.master] then
            return role[a.master] > role[b.master]
        end
		return a.master > b.master
    end)
    
    if other_info and role[role_master_list[1].master] == role[role_master_list[2].master] then
        return {desc = "全系",  colorindex = 6}
    elseif other_info then
        return {desc = role_master_list[1].desc,  colorindex = role_master_list[1].colorindex}
    end

    if role[role_master_list[1].master] == role[role_master_list[2].master] then
        return 6
    else
        return role_master_list[1].index
    end
end

function ShowRoleDetail(uuid)
    if RoleInfoPanel == nil then
        if RoleInfoPanel_loading then
            return;
        end
    
        RoleInfoPanel_loading = true
    
        SGK.ResourcesManager.LoadAsync(root.view.battle[SGK.LuaBehaviour], "prefabs/battlefield/RoleInfoPanel.prefab", function(o)
            RoleInfoPanel_loading = nil;
            if o then
                RoleInfoPanel = SGK.UIReference.Instantiate(o);
                RoleInfoPanel.transform:SetParent(root.view.battle.Canvas.UIRoot.transform, false);
                ShowRoleDetail(uuid);
            end
        end)
        return;
    end

    RoleInfoPanel:SetActive(true);

    local entity = game:GetEntity(uuid)
    local script = GetBattlefiledObject(uuid) or GetBattlefiledPetsObject(uuid)
    if not entity or not script then
        ERROR_LOG("___________________________________   entity not found")
        return
    end

    local headManager = RoleInfoPanel[SGK.BattlefiledHeadManager];
    headManager:Clear();

    local dialog = RoleInfoPanel.Dialog;
    dialog.Title[UI.Text].text = SGK.Localize:getInstance():getValue(entity.Force.side == 1 and "biaoti_juesexinxi_01" or "biaoti_guaiwuxinxi_01")

    if entity.pet then
        utils.IconFrameHelper.Create(dialog.HeroInfo.IconFrame, {customCfg={
            icon    = entity.Config.icon,
            quality = 0,
            star    = 0,
            level   = entity.Config.level,
        }, type = 42});
    else
        local stageCfg = HeroEvoConfig.GetConfig(entity.Config.id);
        local cfg = stageCfg and stageCfg[entity.Config.grow_stage];
        utils.IconFrameHelper.Create(dialog.HeroInfo.IconFrame, {customCfg = {
            icon    = entity.Config.icon,
            quality = cfg and cfg.quality or 0,
            star    = entity.Config.grow_star,
            level   = entity.Config.level,
        }, type = 42});
    end

    local ShowAsRole = (entity.Config.id <= 19999 and not entity.Pet) or (entity.Config.npc_type == 3) 

    dialog.HeroInfo.RoletitleBG:SetActive(false)
    --[[
    if ShowAsRole then
        if entity:Export().Ai_Title ~= 0 then
            dialog.HeroInfo.RoletitleBG.Roletitle[UnityEngine.UI.Text].text = entity:Export().Ai_Title
        else
            local heroCfg = module.HeroModule.GetManager():Get(entity.Config.id or 11000)
            local _title = module.titleModule.GetTitleStatus(heroCfg)
            dialog.HeroInfo.RoletitleBG.Roletitle[UnityEngine.UI.Text].text = (_title == "称号" and "暂无称号") or _title
        end
    else
        dialog.HeroInfo.RoletitleBG:SetActive(false)
    end
    --]]
    dialog.HeroInfo.NameLabel[UnityEngine.UI.Text].text = entity.Config.name;

    local mp, mpp = entity.Property.mp, entity.Property.mpp;
    local cfg = HeroModule.GetConfig(entity.Config.id) or battle_config.LoadNPC(entity.Config.id);

    local hpRevert = entity.Property.hpRevert;
    local mpRevert = entity.Property.mpRevert;
    local mpName = "MP";
    local mp, mpp = entity.Property.mp, entity.Property.mpp;
    local color = 0-- UnityEngine.ColorUtility.TryParseHtmlString('#4eaeff');
    if cfg and cfg.mp_type == 8001 then
        mpName = "EP";
        mpRevert = entity.Property.epRevert;
        color = 1
        mp, mpp = entity.Property.ep, entity.Property.epp;
    elseif cfg and cfg.mp_type == 8002 then
        mpName = "FP";
        mpRevert = 0;
        mp, mpp = entity.Property.fp, entity.Property.fpp;
        color = 2
    elseif not cfg or cfg.mp_type ~= 8000 then
        mpName = "XP";
        mpRevert = 0;
        mp, mpp = 0, 0
        color = nil;
    end

    dialog.HeroInfo.HP[CS.BattlefieldProgressBar]:SetValue(math.floor(entity.Property.hp), math.floor(entity.Property.hpp));
    dialog.HeroInfo.element.master[CS.UGUISpriteSelector].index = GetMasterIcon(entity:Export())
    dialog.HeroInfo.element.Text[CS.UGUIColorSelector].index = GetMasterIcon(entity:Export(), true).colorindex
    dialog.HeroInfo.element.Text[UnityEngine.UI.Text].text = GetMasterIcon(entity:Export(), true).desc
    
    if mpp > 0 then
        dialog.HeroInfo.MP[CS.BattlefieldProgressBar].color = color;
        dialog.HeroInfo.MP:SetActive(true);
        dialog.HeroInfo.MP[CS.BattlefieldProgressBar].title = mpName;
        dialog.HeroInfo.MP[CS.BattlefieldProgressBar]:SetValue(math.floor(mp), math.floor(mpp));
    else
        dialog.HeroInfo.MP:SetActive(false);
    end

    UpDateRoleBuffDesc(entity)
    local buffList = BuffSystem.API.UnitBuffList(nil, entity);
    local suit_buff = {}
    local passive_buff = {}
    local other_buff = {}

    for _, buff in ipairs(buffList) do
        if buff.id >= 1200001 and buff.id <= 1299999 then
            table.insert(suit_buff, buff)
        elseif buff.id >= 3000000 and buff.id < 4000000 then
            if buff.icon and buff.icon ~= "0" and buff.icon ~= "" and buff.icon ~= 0 then
                table.insert(passive_buff, buff)
            end
        else
            table.insert(other_buff, buff)
        end
    end

    if ShowAsRole then
        dialog.EnemySkillList:SetActive(false)
        dialog.RoleStarList:SetActive(true)
        dialog.RoleSkillList:SetActive(true)

        for i = 1, 4 do
            local skill_id = entity.Skill.ids[i];
            local skill = battle_config.LoadSkill(skill_id)
            if not skill then
                dialog.RoleSkillList["Skill"..i]:SetActive(false);
            else
                SGK.ResourcesManager.LoadAsync("icon/" .. skill.icon .. ".png", typeof(UnityEngine.Sprite), function (o)
                    dialog.RoleSkillList["Skill"..i][UnityEngine.UI.Image].sprite = o;   
                end);
                local desc_str = skill.desc .. GetSkillDesc(entity, i);

                CS.UGUIPointerEventListener.Get(dialog.RoleSkillList["Skill"..i].gameObject).onPointerDown = function(obj , pos)
                    local skilldetail = dialog.RoleSkillList["Skill"..i].skilldetail
                    skilldetail.Text[UnityEngine.UI.Text].text = desc_str
                    skilldetail.transform.localScale = Vector3(1, 0.05, 1)
                    skilldetail:SetActive(true)
                    skilldetail.transform:DOScale(Vector3.one, 0.2)
                end
            
                CS.UGUIPointerEventListener.Get(dialog.RoleSkillList["Skill"..i].gameObject).onPointerUp = function()
                    dialog.RoleSkillList["Skill"..i].skilldetail:SetActive(false)
                end      
                dialog.RoleSkillList["Skill"..i]:SetActive(true)  
            end
        end
    
        for i = 1, 5, 1 do
            local buff = passive_buff[i]
            if not buff then
                dialog.RoleStarList["Star"..i]:SetActive(false)
            else
                -- dialog.RoleStarList["Star"..i].level[UI.Text].text = "^".._count

                SGK.ResourcesManager.LoadAsync("icon/" .. buff.icon .. ".png", typeof(UnityEngine.Sprite), function (o)
                    dialog.RoleStarList["Star"..i].level:SetActive(false)
                    if o then
                        dialog.RoleStarList["Star"..i][UnityEngine.UI.Image].sprite = o
                    else
                        ERROR_LOG("===========!!!!!!!!!资源缺失")
                    end
                end);
        
                CS.UGUIPointerEventListener.Get(dialog.RoleStarList["Star"..i].gameObject).onPointerDown = function(obj , pos)
                    local otherdetail = dialog.RoleStarList["Star"..i].otherdetail
                    otherdetail.Text[UnityEngine.UI.Text].text = buff._desc
                    otherdetail.transform.localScale = Vector3(1, 0.05, 1)
                    otherdetail:SetActive(true)
                    otherdetail.transform:DOScale(Vector3.one, 0.2)
                end
            
                CS.UGUIPointerEventListener.Get(dialog.RoleStarList["Star"..i].gameObject).onPointerUp = function()
                    dialog.RoleStarList["Star"..i].otherdetail:SetActive(false)
                end         
            end
        end
    else
        dialog.EnemySkillList:SetActive(true)
        dialog.RoleStarList:SetActive(false)
        dialog.RoleSkillList:SetActive(false)
        for i = 1, 4 do
            local skill_id = entity.Skill.ids[i];
            local skill = battle_config.LoadSkill(skill_id)
            if not skill then
                dialog.EnemySkillList["Skill"..i]:SetActive(false);
            else
                dialog.EnemySkillList["Skill"..i]:SetActive(true);
                dialog.EnemySkillList["Skill"..i].name[UI.Text].text = skill.name
                dialog.EnemySkillList["Skill"..i].desc[UI.Text].text = skill.desc
            end
        end
    end

    if ShowAsRole then
        dialog.SuitList.Title.Text[UI.Text].text = "套装效果"
        local suit_descs = ""
        if next(suit_buff) then
            table.sort(suit_buff, function (a, b) 
                return a.id < b.id
            end)

            for i = 1,#suit_buff do
                local buff = suit_buff[i]
                suit_descs = suit_descs.."<color=#6e4800>"..buff.name.."</color>"..":"..buff._desc.."\n"
            end
            dialog.SuitList.descview.Text[UI.Text].alignment = UnityEngine.TextAnchor.MiddleLeft
        else
            suit_descs = "还未获得套装效果"
            dialog.SuitList.descview.Text[UI.Text].alignment = UnityEngine.TextAnchor.MiddleCenter
        end
        dialog.SuitList.descview.Text[UI.Text].text = suit_descs
        dialog.SuitList.descview.Text.transform.localPosition = Vector3(0, -120, 0)
    else
        dialog.SuitList.Title.Text[UI.Text].text = "被动技能"
        local suit_descs = ""
        if next(passive_buff) then
            table.sort(passive_buff, function (a, b) 
                return a.id < b.id
            end)

            for i = 1,#passive_buff do
                local buff = passive_buff[i]
                suit_descs = suit_descs.."<color=#6e4800>"..buff.name.."</color>"..":"..buff._desc.."\n"
            end
            dialog.SuitList.descview.Text[UI.Text].alignment = UnityEngine.TextAnchor.MiddleLeft
        else
            suit_descs = "没有被动技能"
            dialog.SuitList.descview.Text[UI.Text].alignment = UnityEngine.TextAnchor.MiddleCenter
        end
        dialog.SuitList.descview.Text[UI.Text].text = suit_descs
        dialog.SuitList.descview.Text.transform.localPosition = Vector3(0, -120, 0)
    end

    if next(other_buff) then
        local buffObject = {};
        local prefab = dialog.BuffList.buffview.content.buff

        for _, buff in ipairs(other_buff) do
            if buff.icon and buff.icon ~= "0" and buff.icon ~= "" and buff.icon ~= 0 then
                if buffObject[buff.id] then
                    buffObject[buff.id].count = buffObject[buff.id].count + 1;
                    buffObject[buff.id].obj.count[UnityEngine.UI.Text].text = string.format("x%d", buffObject[buff.id].count)
                else
                    local obj = SGK.UIReference.Instantiate(prefab.gameObject, dialog.BuffList.buffview.content.transform)
                    buffObject[buff.id] = {obj = obj, count = 1}
                    obj.icon[UnityEngine.UI.Image]:LoadSprite("icon/" .. buff.icon)
                    obj.nametext[UnityEngine.UI.Text].text = buff.name
                    obj.namebg[CS.UGUISpriteSelector].index = buff.isDebuff

                    print('__________________', buff.name, buff.remaining_round)
                    if buff.remaining_round > 20 or buff.remaining_round <= 0 then
                        obj.Roundimage:SetActive(false)
                        obj.round:TextFormat("永久")
                        obj.round[UnityEngine.UI.Text].fontSize = 20
                        obj.round.transform.localPosition = Vector3(1, obj.round.transform.localPosition.y, 0)
                    else
                        obj.round:TextFormat("{0}", buff.remaining_round)
                    end                    

                    CS.UGUIPointerEventListener.Get(obj.gameObject).onPointerDown = function(o , pos)
                        local info = {
                            desc = buff._desc
                        }
                        dialog[SGK.LuaBehaviour]:Call("UpdateBuffDetails", obj.gameObject.transform.position, info)
                    end
                
                    CS.UGUIPointerEventListener.Get(obj.gameObject).onPointerUp = function()
                        dialog[SGK.LuaBehaviour]:Call("PickBackBuffDetails")
                    end         
            
                    obj:SetActive(true)
                    headManager:Record(obj.gameObject)
                end
            end
        end
    end

    dialog:SetActive(true);
end

local function ShowHeadPanelAfterLoad()
    RoleInfoPanel_loading = nil;

    local headManager = RoleInfoPanel[SGK.BattlefiledHeadManager];

    headManager:Clear();

    local prefab = RoleInfoPanel.IconFrame.gameObject;
    
    local listener = nil;
    
    local list = game:FindAllEntityWithComponent('Health');

    for k, v in pairs(list) do
        if v:Alive() and v.Force.pid == root.pid or v:Alive() and v.Force.side == 2 then
            local icon = nil
            local info = nil;
            local script = GetBattlefiledObject(v.uuid) or GetBattlefiledPetsObject(v.uuid)
            if v.Pet then
                --[[
                icon = SGK.UIReference.Setup(headManager:Show(script, prefab, 0));
                icon.gameObject.name = "pet_" .. v.id
                info = {
                    icon = v.Config.mode,
                    quality = 0,
                    star = 0,
                    level = v.Config.level,
                    pos = 0,
                }
                if v.Pet.target.Position.pos == 11 then
                    icon.transform.position = script.gameObject.transform.position;
                end
                --]]
            else
                local stageCfg = HeroEvoConfig.GetConfig(v.Config.id);
                local cfg = stageCfg and stageCfg[v.Config.grow_stage];
                icon = SGK.UIReference.Setup(headManager:Show(script, prefab, (v.Force.side == 1) and v.Position.pos or 0));
                icon.gameObject.name = "role_" .. v.id .. "_" .. v.Position.pos 
                info = {
                    icon = v.Config.icon,
                    quality = cfg and cfg.quality or 1,
                    star = v.Config.grow_star,
                    level = v.Config.level,
                    pos = (v.Force.side == 1) and v.Position.pos or 0,
                }
                utils.IconFrameHelper.Create(icon, {customCfg = info, type = 42});

                CS.UGUIClickEventListener.Get(icon.gameObject).onClick = function()
                    ShowRoleDetail(v.uuid);
                end
            end
        end
    end

    RoleInfoPanel:SetActive(true)
    if game.round_info.fight_id == 10100101 or game.round_info.fight_id == 11701 then
        module.guideModule.PlayByType(7)
    end
end

local function ShowHeadPanel()
    if RoleInfoPanel_loading then
        return;
    end

    RoleInfoPanel_loading = true

    if RoleInfoPanel == nil then
        SGK.ResourcesManager.LoadAsync(root.view.battle[SGK.LuaBehaviour], "prefabs/battlefield/RoleInfoPanel.prefab", function(o)
            RoleInfoPanel = SGK.UIReference.Instantiate(o);
            RoleInfoPanel.transform:SetParent(root.view.battle.PersistenceCanvas.transform, false);
            ShowHeadPanelAfterLoad();
        end)
    else
        ShowHeadPanelAfterLoad();
    end
end

function EVENT.nextButton_click()
    ShowHeadPanel()
    if UnityEngine and UnityEngine.Application.isEditor then
        local list = game:FindAllEntityWithComponent('Health');
        for k, v in pairs(list) do
            if v.Force.side == 1 and v.Force.pid == root.pid or v.Force.side == 2 then
                role = v:Export()
                print("_____@@@@@",role.name, "攻击", role.ad, "防御", role.armor, "最大生命", role.hpp)
            end
        end
    end
end

function EVENT.GUIDE_SHOW_MASK()
    if not RoleInfoPanel then return end
    RoleInfoPanel:SetActive(false)
end