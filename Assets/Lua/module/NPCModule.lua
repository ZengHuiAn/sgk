local UserDefault = require "utils.UserDefault"

local NPC_obj_Arr = {}
local function SetNPC(id,objView)
	NPC_obj_Arr[id] = objView
end
local function GetNPCALL(id)
	--print("->>>>>>>>>>>"..sprinttb(NPC_obj_Arr))
	if id then
		return NPC_obj_Arr[id]
	end
	return NPC_obj_Arr
end
local function LoadNpcEffect(id,name,path,callback)
	if id and name and NPC_obj_Arr[id] then
		if not NPC_obj_Arr[id].effect_list then
			NPC_obj_Arr[id].effect_list = {}
		end
		local _obj = SGK.ResourcesManager.Load(path and "prefabs/"..name .. ".prefab" or "prefabs/effect/"..name..".prefab")
		if _obj then
			local eff = GetUIParent(_obj, module.NPCModule.GetNPCALL(id))
	        eff.transform.localPosition = Vector3.zero
			NPC_obj_Arr[id].effect_list[name] = eff
		end
	end
end

-- utils.EventManager.getInstance():addListener("npc_init_succeed", function(event, data)
-- 	local _bossInfo = module.worldBossModule.GetBossInfo(_cfg.type)
-- 	if data == _bossInfo.id then
-- 		-- ERROR_LOG("npc_init_succeed",data);
-- 		-- local _bossInfo = module.worldBossModule.GetBossInfo(_cfg.type)
-- 		-- local boss = module.NPCModule.GetNPCALL(_bossInfo.id);
--   --   	if boss then
--   --   		local view = CS.SGK.UIReference.Setup(boss)
--   --   		local canvas = view.Root.Canvas; 
--   --   		LoadHPObj(canvas);		
--   --   	end
--   		FreshHP();
-- 	end
-- end)


local follow_NPCid = 0
local function FollowNPCidChange(id)
	if id then
		follow_NPCid = id
	end
	return follow_NPCid
end
local function SetNPCSpeed(id,speed)
	if id then
		NPC_obj_Arr[id][UnityEngine.AI.NavMeshAgent].speed = speed
	end
end
local function SetNPCTimeScale(id,TimeScale)
	if id then
		NPC_obj_Arr[id].Root.spine[CS.Spine.Unity.SkeletonAnimation].timeScale = TimeScale
	end
end


local function LoadNpcOBJ(id,vec3,is_break,pri)
	local MapConfig = require "config.MapConfig"
	local data = MapConfig.GetMapMonsterConf(id)
	-- ERROR_LOG("NPC____加载NPC",sprinttb(data));
	if data then
		LoadNpc(data,vec3,is_break,pri)

	end
end
local Npc_active_id_list = {}
local function Set_Npc_active_id(id,status)
	if id then
		if status == false then
			Npc_active_id_list[id] = false
			
		else
			Npc_active_id_list[id] = true
			LoadNpcOBJ(id)
		end
	end
end
local function Get_Npc_active_id(id)
	if id then
		return Npc_active_id_list[id]
	end
	return Npc_active_id_list
end
local function deleteNPC(id,time)
	if time then
		SGK.Action.DelayTime.Create(time):OnComplete(function()
			DeleteNPC(id)
		end)
	else
		DeleteNPC(id)
		-- 
	end
	-- if NPC_obj_Arr[id] then
	-- end
end


local function DeleteNPC_OBJ( id )
	if id and NPC_obj_Arr[id] then
		NPC_obj_Arr[id]:SetActive(false)
	end
end

local function RemoveNPC(id)
	if NPC_obj_Arr[id] then
		NPC_obj_Arr[id] = nil;
	end
end

local npc_born_script = {}

local function npc_born_check(script, gid)
    if npc_born_script[script] == nil then
        local f = loadfile("guide/".. script ..".lua","bt", _G);
        npc_born_script[script] = f or function() return false end;
    end

    return npc_born_script[script](gid);
end

local function Ref_NPC_LuaCondition(id)--刷新地图上所有npc的lua条件脚本
	local MapConfig = require "config.MapConfig"
	local StackList = SceneStack.GetStack()
	if #StackList > 0 then
	    StackList = StackList[#StackList]
		local MapNpcConf = MapConfig.GetMapNpcConf(StackList.savedValues.mapId)
		for _, v in ipairs(MapNpcConf or {}) do
			if id then
				if id == v.gid then
					if StackList and v.mapid == StackList.savedValues.mapId and v.is_born ~= "0" then
						-- ERROR_LOG("刷新"..v.gid.."脚本");
						if npc_born_check(v.is_born,v.gid) then
							LoadNpcOBJ(v.gid)
						else
							deleteNPC(v.gid)
						end
					end
				end
				break;
			else
				if StackList and v.mapid == StackList.savedValues.mapId and v.is_born ~= "0" then
					
					if npc_born_check(v.is_born,v.gid) then
						LoadNpcOBJ(v.gid)
					else
						deleteNPC(v.gid)
					end
				end
			end
	    end
	end
end

local function NPC_Reset()
	ResetNPCQueue()
	NPC_obj_Arr = {}
end
local NPClikingList = nil
local function SetNPClikingList(id,value)
	if not NPClikingList[id] then
		NPClikingList[id] = {}
	end
	NPClikingList[id][#NPClikingList[id]+1] = value
	UserDefault.Save()
end
local function GetNPClikingList(id)
	if id then
		if not NPClikingList then
			NPClikingList = UserDefault.Load("NPC_Gift_Record",true)
		else
			return NPClikingList[id]
		end
	end
	if not NPClikingList then
		NPClikingList = UserDefault.Load("NPC_Gift_Record",true)
	else
		return NPClikingList
	end
end

local npc_icons = {}
local function SetNPCIcon(gid, icon)
	npc_icons[gid] = icon;
	DispatchEvent("localNpcStatus",{gid = gid})
end

local function GetNPCIcon(gid)
	return npc_icons[gid];
end

return{
	SetNPC = SetNPC,
	FollowNPCidChange = FollowNPCidChange,
	GetNPCALL = GetNPCALL,
	NPC_Reset = NPC_Reset,
	LoadNpcOBJ = LoadNpcOBJ,
	deleteNPC = deleteNPC,
	RemoveNPC = RemoveNPC,
	Ref_NPC_LuaCondition = Ref_NPC_LuaCondition,
	SetNPCSpeed = SetNPCSpeed,
	SetNPCTimeScale = SetNPCTimeScale,
	Set_Npc_active_id = Set_Npc_active_id,
	Get_Npc_active_id = Get_Npc_active_id,
	LoadNpcEffect = LoadNpcEffect,
	SetNPClikingList = SetNPClikingList,
	GetNPClikingList = GetNPClikingList,

	SetIcon = SetNPCIcon,
	GetIcon = GetNPCIcon,

	npc_born_check = npc_born_check,

	DeleteNPC_OBJ = DeleteNPC_OBJ ,
}