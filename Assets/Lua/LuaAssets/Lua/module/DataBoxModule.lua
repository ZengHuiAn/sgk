local chapterConfig = nil
local function GetMemoryChapterConfig(id)
    if chapterConfig == nil then
        chapterConfig = LoadDatabaseWithKey("memory_chapter", "chapter");
    end
    if id then
        return chapterConfig[id]
    end
    return chapterConfig
end

local stageConfig = nil
local function GetMemoryStageConfig(chapter_id, stage)
    if stageConfig == nil then
        stageConfig = {};
        DATABASE.ForEach("memory_stage", function(row)
            if stageConfig[row.chapter_id] == nil then
                stageConfig[row.chapter_id] = {}
            end
            stageConfig[row.chapter_id][row.stage] = row
        end)
    end
    if stage then
        return stageConfig[chapter_id][stage]
    elseif chapter_id then
        return stageConfig[chapter_id]
    end
    return stageConfig;
end

local suitsConfig = nil
local suitBySuitId = nil
local suitByType = nil
local function GetSuitsManual(suitId,type,allType)
    if suitsConfig == nil then
        suitsConfig = {}
        suitBySuitId = {}
        suitByType = {}
        DATABASE.ForEach("equipment_handbook", function(data)
            local equips = {}
            for i=1,6 do
                if data["equipment"..i] then
                    equips[i] = data["equipment"..i]
                end
            end
            local suitCfg = setmetatable({equips=equips},{__index=data})
            table.insert(suitsConfig,suitCfg)
            suitBySuitId[data.suit_id] = suitCfg

            suitByType[data.type] = suitByType[data.type] or {}
            table.insert(suitByType[data.type],suitCfg)
        end)
    end
    if suitId then
        return suitBySuitId[suitId]
    end
    if type then
        -- table.sort(suitByType[type],function (a,b)
        --     return a.id < b.id
        -- end)
        return suitByType[type]
    end
    if allType then
        table.sort(suitByType,function (a,b)
            return a[#a].id > b[#b].id
        end)
        return suitByType
    end
    return suitsConfig
end

local biographyConfig = nil;
local function GetBiographyConfig(npc_id)
    if biographyConfig == nil then
        biographyConfig = LoadDatabaseWithKey("biography", "npc_id");
    end
    if npc_id then
        return biographyConfig[npc_id]
    end
    return biographyConfig
end

local biographyDesConfig = nil;
local function GetBiographyDesConfig(id)
    if biographyDesConfig == nil then
        biographyDesConfig = LoadDatabaseWithKey("biography_des", "id");
    end
    if id then
        return biographyDesConfig[id]
    end
    return biographyDesConfig
end

local consortiaConfig = nil;
local function GetConsortiaConfig(id)
    if consortiaConfig == nil then
        consortiaConfig = LoadDatabaseWithKey("consortia_context", "id");
    end
    if id then
        return consortiaConfig[id]
    end
    return consortiaConfig
end

local consortiaDesConfig = nil;
local function GetConsortiaDesConfig(id)
    if consortiaDesConfig == nil then
        consortiaDesConfig = LoadDatabaseWithKey("consortia_des", "id");
    end
    if id then
        return consortiaDesConfig[id]
    end
    return consortiaDesConfig
end

local function GetUnlockPropertyCount(id)
    -- local cfg = GetBiographyConfig(id);
    -- local count = 0
    -- if cfg then
    --     local quest_id = cfg.reward_quest;
    --     local quest = module.QuestModule.Get(quest_id);
    --     if quest then
    --         if quest.status == 1 and quest.reward[1].type == 93 then
    --             count = count + 1;
    --         end
    --     else
    --         ERROR_LOG("quset is nil,quest_id",quest_id)
    --     end
    -- end
    -- return count
end

return {
    GetChapterConfig = GetMemoryChapterConfig,
    GetStageConfig = GetMemoryStageConfig,
    GetBiographyConfig = GetBiographyConfig,
    GetBiographyDesConfig = GetBiographyDesConfig,
    GetConsortiaConfig = GetConsortiaConfig,
    GetConsortiaDesConfig = GetConsortiaDesConfig,
    GetSuitsManual = GetSuitsManual,
    GetUnlockPropertyCount = GetUnlockPropertyCount,
}