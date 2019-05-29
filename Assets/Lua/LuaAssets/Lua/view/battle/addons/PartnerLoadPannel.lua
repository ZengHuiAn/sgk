local load_partners = {}
local PreloadPannel = nil
function Start()
    local Player_list = game:FindAllEntityWithComponent("Player")

    if #Player_list <= 1 then return end
    -- [[
    local have_load_partner = nil
    for _,v in ipairs(Player_list) do
        if v.Player.pid ~= root.pid and v.Player.ready == 0 then
            have_load_partner = true
            break
        end
    end

    if not have_load_partner then return end
    --]]
    LoadAsync("prefabs/battlefield/PreloadPannel.prefab", function(prefab)
        PreloadPannel = SGK.UIReference.Instantiate(prefab)
        PreloadPannel.transform:SetParent(root.view.battle.PersistenceCanvas.transform, false);

        local player_solt = 0
        for i = 1,5,1 do
            local entity = Player_list[i]
            if not entity then
                break
            end

            if entity.Player.pid ~= root.pid then
                player_solt = player_solt + 1
                local PlayerObj = PreloadPannel.Players["Player" .. player_solt]
                local icon_frame = utils.IconFrameHelper.Create(PlayerObj.IconFrame,{pid = entity.Player.pid});
                PlayerObj.Name[UI.Text].text = entity.Player.name
                PlayerObj:SetActive(true)
                load_partners[entity.uuid] = PlayerObj
            end
        end
        PreloadPannel:SetActive(true)
    end)
end

local a = 0 
function Update(dt)
    if next(load_partners) then
        for uuid, PlayerObj in pairs(load_partners) do
            local entity = game:GetEntity(uuid)
            if entity.Player.ready ~= 0 then
                PlayerObj.ready:SetActive(true)
                PlayerObj.load:SetActive(false)
                load_partners[uuid] = nil
            end
        end
    elseif PreloadPannel then
        local obj = PreloadPannel
        PreloadPannel.transform:DOScale(Vector3(0.1, 0.1, 1), 0.3):OnComplete(function()
            UnityEngine.GameObject.Destroy(obj.gameObject);
        end)
        PreloadPannel = nil  
    end
end
