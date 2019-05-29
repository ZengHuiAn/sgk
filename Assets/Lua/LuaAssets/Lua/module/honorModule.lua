local playerModule = require "module.playerModule"
local HeroModule = require "module.HeroModule"
local ItemModule = require "module.ItemModule"
local fightModule = require "module.fightModule"
local QuestModule = require "module.QuestModule"

local honorConfig = nil
local UnionHonorCfg=nil
local UnionHonorCfgByJob={}
local function getCfg(id,pid)
    if not honorConfig then
    	UnionHonorCfg={}
        honorConfig = {}
        DATABASE.ForEach("honor", function(data)
            if data.special <9999 then--军团头衔
     			UnionHonorCfg[data.special]=data
            end
            honorConfig[data.gid]=data
        end)
    end
    if id then
    	if id==1000 then--公会职务
    		local pid=pid or module.playerModule.GetSelfID() 
    		if pid ==module.playerModule.GetSelfID()  then
				local uninInfo=module.unionModule.Manage:GetSelfUnion()
				if uninInfo then
					local selfUnionJob=module.unionModule.Manage:GetSelfTitle()
					return UnionHonorCfg[selfUnionJob]
				else
					ERROR_LOG("无公会")
				end
			else
				if UnionHonorCfgByJob[pid] then
					local _honorCfg=UnionHonorCfgByJob[pid]
					UnionHonorCfgByJob[pid]=nil
					return _honorCfg
				else
					local uninInfo=module.unionModule.Manage:GetSelfUnion()
					module.unionModule.queryPlayerUnioInfo(pid,function ()
						local uninInfo=module.unionModule.GetPlayerUnioInfo(pid)		
						if uninInfo then
							local unionJob=uninInfo.title
							UnionHonorCfgByJob[pid]=UnionHonorCfg[unionJob]
							DispatchEvent("PLAYER_INFO_CHANGE",pid);
							-- return UnionHonorCfg[unionJob]
						else
							ERROR_LOG("无公会",pid)
						end
					end)
				end
				
			end
    	else
	        return honorConfig[id]
	    end
	else
		return honorConfig
    end   
end

local honorCondition = nil
local function GetCondition(gid)
    if not honorCondition then
        honorCondition = LoadDatabaseWithKey("honor_condition", "gid")
    end
    if gid then
        return honorCondition[gid]
    end
    return honorCondition
end

local honorState = {};
local function CheckHonor(gid)
	local condition = GetCondition(gid);
	if condition then
		if condition.type ~= 2 and honorState[gid] then
			return true;
		end
		if condition.type == 0 then--公会职务
			local uninInfo=module.unionModule.Manage:GetSelfUnion()
			if uninInfo and next(uninInfo)~=nil then
				return true
			end
		elseif condition.type == 1 then
			local hero = HeroModule.GetManager():Get(condition.condition1);
			if hero and hero.level >= condition.condition2 then
				honorState[gid] = true;
				return true;
			end
		elseif condition.type == 2 then
			if ItemModule.GetItemCount(condition.condition1) >= condition.condition2 then
				honorState[gid] = true;
				return true;
			end
		elseif condition.type == 4 then
			local hero = HeroModule.GetManager():Get(condition.condition1);
			if hero and hero.stage >= condition.condition2 then
				honorState[gid] = true;
				return true;
			end
		elseif condition.type == 5 then
			local hero = HeroModule.GetManager():Get(condition.condition1);
			if hero and hero.star >= condition.condition2 then
				honorState[gid] = true;
				return true;
			end
		elseif condition.type == 6 then
			local hero = HeroModule.GetManager():Get(condition.condition1);
			if hero and hero.weapon_stage >= condition.condition2 then
				honorState[gid] = true;
				return true;
			end
		elseif condition.type == 7 then
			local hero = HeroModule.GetManager():Get(condition.condition1);
			if hero and hero.weapon_star >= condition.condition2 then
				honorState[gid] = true;
				return true;
			end
		elseif condition.type == 8 then
			local hero = HeroModule.GetManager():Get(condition.condition1);
			local info = fightModule.GetFightInfo(condition.condition1);
			local star_count = 0
			for i=1,3 do
			 	if fightModule.GetOpenStar(info.star,i) ~= 0 then
			 		star_count = star_count + 1;
			 	end
			end
			if star_count >= condition.condition2 then
				honorState[gid] = true;
				return true;
			end 
		elseif condition.type == 9 then
			if QuestModule.Get(condition.condition1) and QuestModule.Get(condition.condition1).finishCount >= condition.condition2 then
				honorState[gid] = true;
				return true;
			end
		end
	end
	return false;
end

local honorList=nil
local function GetHonorList() 
    local honorConfig =GetCondition();
    local honorList={}
    for k,v in pairs(honorConfig) do
        if CheckHonor(v.gid) then
            local _cfg=getCfg(v.gid)
            table.insert(honorList,_cfg);
        end
    end
    table.sort(honorList,function ( a,b )
        return a.gid < b.gid;
    end)
    return honorList
end

local function getSelfUnionHonor()
	local uninInfo=module.unionModule.Manage:GetSelfUnion()
	if uninInfo then
		local selfUnionJob=module.unionModule.Manage:GetSelfTitle()
		return UnionHonorCfg[selfUnionJob].gid
	end
end

utils.EventManager.getInstance():addListener("CONTAINER_UNION_MEMBER_LIST_CHANGE", function(event, name)
	DispatchEvent("PLAYER_INFO_CHANGE", module.playerModule.GetSelfID());
end)

return {
    GetCfg = getCfg,
    GetCondition = GetCondition,
    CheckHonor = CheckHonor,
    GetSelfHonorList=GetHonorList,
    GetSelfUnionHonor=getSelfUnionHonor,
}