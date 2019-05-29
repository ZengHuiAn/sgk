local MonsterInfo = nil
local monster_info_cfg = nil
local show_list = {}

local function UpdateSkeletonDataAsset(skeletonAnimation, name, hitpoint)
    CS.SkeletonAnimationAnchoredPosition.Attach(skeletonAnimation, hitpoint);
    skeletonAnimation:UpdateSkeletonAnimation(string.format("roles/%s/%s_SkeletonData", name, name), {"idle"});
end

local function showMonsterInfo(entity, info)
    ShowUI(false)    

    MonsterInfo.root.view.infobg_1.desc1[UI.Text].text = info.characteristic
    MonsterInfo.root.view.infobg_1.desc2[UI.Text].text = info.restrain
    MonsterInfo.root.view.desc[UI.Text].text = info.describe
    MonsterInfo.root.jues_appear_guai.jues_appear_ani.weixiandu["weixiandu_"..info.grade]:SetActive(true)

    local name_Text = MonsterInfo.root.jues_appear_guai.jues_appear_ani.transform:GetComponentsInChildren(typeof(UnityEngine.TextMesh), true)
    for i = 1, name_Text.Length do
        if name_Text[i-1].gameObject.tag == "big_skill" then
            name_Text[i-1].text = entity.Config.name
        end
    end
    
    local objects = MonsterInfo.transform:GetComponentsInChildren(typeof(Spine.Unity.SkeletonAnimation), true)
    for i = 1, objects.Length do
        if objects[i-1].gameObject.tag == "big_skill" then
            UpdateSkeletonDataAsset(objects[i-1], entity.Config.mode, "root");
        end
    end

    MonsterInfo.root.jues_appear_guai.jues_appear_ani.jues.role.transform.localPosition = Vector3(info.battle_x, info.battle_y, 0);
    MonsterInfo.root.jues_appear_guai.jues_appear_ani.jues.role.transform.localScale = Vector3.one * info.scale;
    
    SGK.Action.DelayTime.Create(0.25):OnComplete(function()
        MonsterInfo.root.mask.gameObject:SetActive(true)
        local AnimationState = MonsterInfo.root.jues_appear_guai.jues_appear_ani.jues.role[CS.Spine.Unity.SkeletonAnimation].AnimationState
        pcall(AnimationState.SetAnimation, AnimationState, 0, "ruchang", false)
        pcall(AnimationState.AddAnimation, AnimationState, 0, "idle", true, 0)
    end)

    MonsterInfo.gameObject:SetActive(true);
    module.RewardModule.Gather(info.one_time_id)

    CS.UGUIClickEventListener.Get(MonsterInfo.root.mask.gameObject, true).onClick = function() 
        EventNeedPause_Resume()
    end

    EventNeedPause_Yield()

    MonsterInfo:SetActive(false)
    ShowUI(true)
end

local function showMonsterInfoAsync(entity, info)
    if not MonsterInfo then
        local o = SGK.ResourcesManager.Load(root.view.battle[SGK.UIReference], "prefabs/battlefield/MonsterInfo.prefab");
        MonsterInfo = SGK.UIReference.Instantiate(o);
        MonsterInfo.transform:SetParent(root.view.battle.transform, false);
        showMonsterInfo(entity, info)
    else
        showMonsterInfo(entity, info)
    end
end

local function addInShowList()
    if root.args.remote_server then
        return
    end

    if not monster_info_cfg then
        monster_info_cfg = {}
        DATABASE.ForEach("debut", function(data)
            monster_info_cfg[data.id] = data
        end)
    end

    local add_list = {}
    for k, v in pairs(GetAllBattlefiledObject()) do
        local entity = game:GetEntity(k)
        if entity and entity:Alive() and entity.Force.side == 2 and entity.Config.npc_type ~= 3 then  --约定npc_type为3的为玩家npc 
            local info = monster_info_cfg[entity.Config.id]
            if info then
                local _flag = module.RewardModule.Check(info.one_time_id)
                if _flag ~= module.RewardModule.STATUS.ERROR and _flag ~= module.RewardModule.STATUS.DONE and not add_list[info.one_time_id] then
                    AddEventNeedPause(function()
                        showMonsterInfoAsync(entity, info)
                    end, 30)
                    add_list[info.one_time_id] = true
                end
            end
        end
    end
end

function EVENT.RAW_BATTLE_EVENT(_, event, ...)
    if event == "WAVE_ALL_ENTER" then
        if root.speedUp then return end
        addInShowList()
    end
end
