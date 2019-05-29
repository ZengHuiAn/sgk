local EventManager = require 'utils.EventManager';
local NetworkService = require "utils.NetworkService";



local rewardCfg = LoadDatabaseWithKey("rank_rewards", "rankid", "type");
local function GetActivityReward(rankid)
	return rewardCfg[rankid];
end
local function GetNowPeriod()
    local cfg = GetActivityReward(2)
    if not cfg then
        return nil
    end
    local begin_time = cfg.begin_time
    local end_time = cfg.end_time
    local period = cfg.period
    local duration = cfg.duration
    local ret = math.ceil((module.Time.now() + 1 - begin_time) / period);
    return ret
end


local guild_prop_data = nil


--获取军团道具
local function getGuildProp(isreset)

	if guild_prop_data and not isreset then
		return guild_prop_data;
	end
	-- ERROR_LOG("获取军团道具");
	NetworkService.Send(3455,{nil})
end

local function resetGuildProp()
	getGuildProp(true)
end


local prop_data = {
	[79047] = 0,
	[79048] = 0,
	[79049] = 0,
}

EventManager.getInstance():addListener("server_respond_3456", function(event, cmd, data)
	-- ERROR_LOG("server_respond_3456",sprinttb(data))
	local sn = data[1]
	local err = data[2]
	-- prop_data 
	if err == 0 then

		for k,v in pairs(data[3] or {}) do
			if prop_data[v[1]] then
				prop_data[v[1]] = v[2];
			end
		end


		guild_prop_data = prop_data;
		DispatchEvent("GET_GUILD_PROP_SUC");
		
	end
end)
local function GetProp()
	return prop_data
end

--个人道具兑换军团道具
local function guildSubProp(id,value)
	NetworkService.Send(3453,{nil,id,value});
end


local function GetRank()
	local current = GetNowPeriod();
	NetworkService.Send(17103,{nil,2,current,10})
end 


EventManager.getInstance():addListener("server_respond_3454", function(event, cmd, data)
	-- ERROR_LOG("server_respond_3454",sprinttb(data))
	local sn = data[1]
	local err = data[2]
end)

--道具发生改变

EventManager.getInstance():addListener("server_notify_1143",function ( event,cmd,data)
	-- ERROR_LOG("server_notify_1143",sprinttb(data));
	if not data[4] then
		guild_prop_data[data[1]] = data[2]

		-- ERROR_LOG("军团道具数量更新",guild_prop_data);
		DispatchEvent("GUILD_ITEM_CHANGE_INFO",data[1]);
	end

end)
local function GetRankReward(current,email)
	current = current or GetNowPeriod()
	NetworkService.Send(17105,{nil,2,current,email and email or 0})
end

return
{
	GetGuildProp = getGuildProp,
	SubmitGuild	 = guildSubProp,
	GetProp 	 = GetProp,
	GetRankReward = GetRankReward,
	ResetGuildProp = resetGuildProp
}