local trialTowerConfig = {}


local rewardCfg = LoadDatabaseWithKey("tower", "fight_id");

local rewardCfg_C = nil;

local function buildCfg()

	for k,v in pairs(rewardCfg) do
		local reward = {};
		for i=1,2 do
			table.insert(reward,{
				count = v["first_reward_count"..i],
				type  = v["first_reward_type"..i],
				id 	  = v["first_reward_id"..i] });
		end
		v.firstReward = reward;

		local accumulate = {};

		for i=1,2 do
			table.insert(accumulate,{
				count =v["accumulate_reward_count"..i],
				type  = v["accumulate_reward_type"..i],
				id 	  = v["accumulate_reward_id"..i] });
		end
		v.accumulate = accumulate;
	end
	rewardCfg_C = true;
end

function trialTowerConfig.GetConfig(fight_id)
	if not rewardCfg_C then
		buildCfg();
	end
	if rewardCfg then
		if fight_id then
			return rewardCfg[fight_id]
		else
			return rewardCfg
		end
	end 
end


local BuffConfig = LoadDatabaseWithKey("item_buff","fight_id");


function trialTowerConfig.GetBuffConfig(fight_id)

	--ERROR_LOG(sprinttb(BuffConfig[fight_id]),fight_id);
	return fight_id and BuffConfig[fight_id] or nil;
end


return trialTowerConfig;