
local pets = {}
local pets_object = {}

local pet_prefab
local pet_prefab_enemy
local petObject

local function addEntity(entity)
    if not entity.Pet then return end

    -- print('add pet', entity.uuid, entity.Config.name);

    local role = GetBattlefiledObject(entity.Pet.target);
    if not role then
        print('  pet target not exists');
        return;
    end

    petObject = SGK.UIReference.Instantiate(
            (entity.Force.side == 1) and pet_prefab or pet_prefab_enemy)
        
    local script =  petObject[SGK.BattlefieldObjectPet];

    role:AddPet(entity.uuid, petObject.gameObject);

    script:ChangeMode(tostring(entity.Config.icon));

    local health = entity.Health;

    script:UpdateUI(entity:FirstHP() / entity:FirstMaxHP(), 
                   entity.Pet:FirstCD() - game.round_info.round, entity.Pet:Count(), 0);

    pets[entity.uuid] = script;
    pets_object[entity.uuid] = petObject;
end

local function PlayHit(uuid)
    local obj = pets_object[uuid]
    if obj then
        local animate = obj:GetComponent(typeof(UnityEngine.Animator));
        if animate then
            animate:SetTrigger("Hit");
        end
    end
end

local function removeEntity(uuid, role)
    if pets[uuid] then
        print('remove pet', uuid);
        role:RemovePet(uuid);
        PlayHit(uuid);
    end
end

local function UpdatePetUI(uuid)
    local entity = game:GetEntity(uuid)
    if not entity or not entity.PetInventory then
        return
    end    

    local pet_list = entity.PetInventory:FindAllEntityWithComponent("Skill");

    local round_info = game:GetGlobalData();
    for _, v in ipairs(pet_list) do
        local script = pets[v.uuid];
        script:UpdateUI(v:FirstHP() / v:FirstMaxHP(), 
        v.Pet:FirstCD() - round_info.round, v.Pet:Count(), 0);    
    end
end

local remove_list = {}

function Update()
    if remove_list[1] then
        for _, v in ipairs(remove_list) do
            v.wait = v.wait - UnityEngine.Time.deltaTime
        end

        if remove_list[1].wait < 0 then
            removeEntity(remove_list[1].uuid, remove_list[1].role)
            table.remove(remove_list, 1)
        end
    end
end

function Preload()
    LoadAsync("prefabs/battlefield/pet.prefab", function(o)
        pet_prefab = o
    end)

    LoadAsync("prefabs/battlefield/pet_enemy.prefab", function(o)
        pet_prefab_enemy = o
    end)

    local list = game:FindAllEntityWithComponent("Pet")
    for _, v in ipairs(list) do
        addEntity(v, 1);
    end
    -- TODO: player enter script
end

--[[
function Update()
    for uuid, info in ipairs(roles) do
        local entity = game:GetEntity(uuid);
        if entity then
            info.script:UpdateProperty(entity.Property.hp, entity.Property.hpp,
                    100, 100,
                    entity.Property.shield);
        else
            info.script:UpdateProperty(0, 100, 100, 100, 0);
        end
    end
end
--]]

function GetBattlefiledPetsObject(uuid)
    return pets[uuid];
end

function EVENT.RAW_BATTLE_EVENT(_, event, ...)
    if event == "ENTITY_ADD" then
        if root.speedUp then return end
        local uuid, entity = ...
        if filterPartnerEvent(uuid) then return end
        addEntity(entity);
    elseif event == "ENTITY_REMOVED" then
        if root.speedUp then return end
        local uuid, entity = ...
        if filterPartnerEvent(uuid) then return end
        if not entity.Pet then
            return
        end

        local role = GetBattlefiledObject(entity.Pet.target);
        if not role then
            return;
        end

        table.insert(remove_list, {uuid = uuid, role = role, wait = 1})
    elseif event == "UNIT_HURT" or event == "UNIT_HEALTH" then
        if root.speedUp then return end
        local info = select(1, ...)
        if filterPartnerEvent(info.uuid) then return end
        local entity = game:GetEntity(info.uuid)
        if entity and entity.Pet then
            PlayHit(entity.uuid)
            UpdatePetUI(entity.Pet.target)
        end
    end
end
