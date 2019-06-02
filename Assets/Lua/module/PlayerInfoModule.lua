local PlayerFootEffect_list = {}--当前使用的
local PlayerFootEffect_pool = {}--已使用过后回收
local function CreatePlayerFootEffect(character,name)
	local obj = nil
	if not PlayerFootEffect_list[name] then
		PlayerFootEffect_list[name] = {}
	end
	if not PlayerFootEffect_pool[name] then
		PlayerFootEffect_pool[name] = {}
	end
	if #PlayerFootEffect_pool[name] > 0 then
		obj = PlayerFootEffect_pool[name][1]
		table.remove(PlayerFootEffect_pool[name],1)
	else
		obj = UnityEngine.GameObject(name.."_FootEffect_"..#PlayerFootEffect_list[name] + 1);
		--ERROR_LOG(sprinttb(character))
		SGK.ResourcesManager.LoadAsync(character[SGK.UIReference],name .. ".prefab",function (o)
			--ERROR_LOG(o)
			GetUIParent(o,obj.transform)
		end)
	end
	obj.transform.position = character.footprint.transform.position
	obj:SetActive(true)
	PlayerFootEffect_list[name][#PlayerFootEffect_list[name]+1] = obj
	return obj
end
local function GetPlayerFootEffect(time,character,name)
	local obj = CreatePlayerFootEffect(character,name)
	obj.transform.eulerAngles = character.footprint.transform.eulerAngles
	SGK.Action.DelayTime.Create(time):OnComplete(function()
		table.remove(PlayerFootEffect_list[name],1)
		PlayerFootEffect_pool[name][#PlayerFootEffect_pool[name]+1] = obj
		obj:SetActive(false)
	end)
end
local function GuildExcavate(character,name)
	if PlayerFootEffect_list[name] and #PlayerFootEffect_list[name] >= 10 then
		PlayerFootEffect_pool[name][#PlayerFootEffect_pool[name]+1] = PlayerFootEffect_list[name][1]
		table.remove(PlayerFootEffect_list[name],1)
	end
	CreatePlayerFootEffect(character,name)
end
local function clearPlayerFootEffect( ... )
	PlayerFootEffect_list = {}--当前使用的
	PlayerFootEffect_pool = {}--已使用过后回收
end

local player_scale = 1;
local function GetPlayerScale()
	return player_scale;
end

local function SetPlayerScale(scale)
	player_scale = scale or 1;
end

return {
	GetPlayerFootEffect = GetPlayerFootEffect,
	clearPlayerFootEffect = clearPlayerFootEffect,
	GuildExcavate = GuildExcavate,

	GetPlayerScale = GetPlayerScale,
	SetPlayerScale = SetPlayerScale,
}