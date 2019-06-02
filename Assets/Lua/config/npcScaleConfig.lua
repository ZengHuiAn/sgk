--地图彩蛋NPC
local npcScale = {
    [6028000] = 1,
    [6028001] = 1,
    [6028002] = 1,
    [6028003] = 1,
    [6014002] = 1,
    [6014003] = 1,
    [6014004] = 1,
    [6014005] = 1,
    [6014006] = 1,
}

local function GetNPCScale( id )
    return npcScale[id]
end

return {
    GetNPCScale = GetNPCScale,
}

