local MapIsLock = false
local function SetMapIsLock(status)
	MapIsLock = status
end
local function GetMapIsLock()
	return MapIsLock
end
local Shielding = false
local function SetShielding(status)
	Shielding = status
end
local playerStatusList = {}
local function SetPlayerStatus(pid,status)
	playerStatusList[pid] = status
	if status == 0 then
		DispatchEvent("NOTIFY_TEAM_PLAYER_AFK_CHANGE",{pid = pid,type = false})
		DispatchEvent("TEAM_INFO_CHANGE")
	else
		DispatchEvent("NOTIFY_TEAM_PLAYER_AFK_CHANGE",{pid = pid,type = true})
	end
end
local function GetPlayerStatus(pid)
	if playerStatusList[pid] then
		return playerStatusList[pid]
	end
	return 0
end

local function SetMapid(mapid,x,y,z)
	local pid = module.playerModule.GetSelfID()
	local key = "PlayerMap"..pid
	local data = mapid.."_"..x.."_"..y.."_"..z
	--ERROR_LOG(key,data)
	UnityEngine.PlayerPrefs.SetString(key,data)
end
local function GetiMapid()
	local pid = module.playerModule.GetSelfID()
	local key = "PlayerMap"..pid
	local mapid,x,y,z = 10,0,0,0
	if UnityEngine.PlayerPrefs.HasKey(key) then
		local data = UnityEngine.PlayerPrefs.GetString(key)
		local list = StringSplit(data,"_")
		if #list == 4 then
			mapid,x,y,z = tonumber(list[1]),tonumber(list[2]),tonumber(list[3]),tonumber(list[4])
		end
		--ERROR_LOG(key,mapid,x,y,z)
	end
	return mapid,x,y,z
end

local function GetShielding()
	return Shielding
end
return{
	SetMapIsLock = SetMapIsLock,
	GetMapIsLock = GetMapIsLock,
	SetShielding = SetShielding,
	GetShielding = GetShielding,
	SetMapid = SetMapid,
	GetiMapid = GetiMapid,
	SetPlayerStatus = SetPlayerStatus,
	GetPlayerStatus = GetPlayerStatus,
}