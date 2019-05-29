
local function changeScene(sceneName)
    if not sceneName or sceneName == "" then
        sceneName = "18hao";
    end

    local fileName = "prefabs/battlefield/environment/" .. sceneName .. ".prefab";

    LoadAsync(fileName, function(o) 
        if not o then
            print(fileName, 'not exists');
            return;
        end

        SGK.BackgroundMusicService.PlayBattleMusic(sceneName);
    
        local env = UnityEngine.GameObject.Instantiate(o);
        if env then
            env.name = sceneName;
            local transform = env:GetComponent(typeof(UnityEngine.Transform));
            local c = transform:Find("Directionallight")
            if c then
                ERROR_LOG('find', c.position);
                CS.FollowTarget.Follow(root.view.battle.ShadowCaster.gameObject, c, -1, true)
                local color = c.gameObject:GetComponent(typeof(CS.UGUIColorSelector));
                if color ~= nil and color.color.Length > 0 then
                    root.view.battle.ShadowCaster[CS.DynamicShadowProjector.ShadowTextureRenderer].shadowColor = color.color[0];
                end
            end
        else
            print('fight scene', sceneName, 'not exists');
        end
    end);
end


local globalEntity = nil;
local last_scene_name = nil;

function Preload()
    -- print('Preload', GetFightData().scene);
    -- changeScene(GetFightData().scene);
    local list = game:FindAllEntityWithComponent("GlobalData");
    globalEntity = list[1];

    if list[1] then
        if globalEntity.GlobalData.scene ~= "" then
            last_scene_name = globalEntity.GlobalData.scene
            changeScene(last_scene_name);
        end
    end
end

function Start()
    local list = game:FindAllEntityWithComponent("GlobalData");
    globalEntity = list[1];
end

function Update()
    if globalEntity == nil then return end

    if last_scene_name ~= globalEntity.GlobalData.scene 
        and globalEntity.GlobalData.scene ~= "" then
        last_scene_name = globalEntity.GlobalData.scene
        changeScene(last_scene_name);
    end
end

--[[
function API.SceneChange(_, ...)
    print(game:GetTime(), 'SceneChange', ...);
end
--]]

function EVENT.RAW_BATTLE_EVENT(_, event, ...)
    if event == "ENTITY_ADD" then
        local entity = select(2, ...)
        if globalEntity == nil and entity.GlobalData then
            globalEntity = entity
        end
    end
end
