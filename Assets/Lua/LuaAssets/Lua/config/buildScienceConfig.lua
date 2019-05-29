-- city_construction

 -- activityMonsterCfg = {raw =

local buildScienceConfig = {};

--科技表
local Sciences = nil;


local function buildBaseInfo()
	Sciences = {};

	DATABASE.ForEach("city_construction", function(row)
        	Sciences[row.map_id] = Sciences[row.map_id] or {};
			
        	table.insert(Sciences[row.map_id],row);
    	end)


	for k,v in pairs(Sciences) do
		table.sort( v, function ( a,b )
			return a.id < b.id;
		end );
	end
end

function buildScienceConfig.GetConfig(mapid)
	if not Sciences then
		buildBaseInfo();
	end
	return mapid and Sciences[mapid] or Sciences;
end

local Technology = nil;

local function buildtechnologyBaseInfo()
	Technology = {};
	DATABASE.ForEach("city_technology", function(row)
        	Technology[row.map_id] = Technology[row.map_id] or {};


        	local temp = {};

        	for i=1,4 do

        		local _id = row["expend"..i.."_id"];

        		if _id ~=0 then
        			local _type = row["expend"..i.."_type"];
        			local _value = row["expend"..i.."_value"];
        			table.insert(temp,{id = _id,type = _type,value = _value});
        		end
        	end
			row.expend = temp;
			Technology[row.map_id][row.technology_type] = Technology[row.map_id][row.technology_type] or {}; 
			
			

        	table.insert(Technology[row.map_id][row.technology_type],row);

    	end)


	for k,v in pairs(Technology) do
		for _k,_v in pairs(v) do
			table.sort( _v, function ( a,b )
				return a.city_level < b.city_level;
			end );
		end
	end
end

function buildScienceConfig.GetScienceConfig(map_id,technology_type)
	
	if not Technology then
		buildtechnologyBaseInfo();
	end
	if not technology_type then
		return Technology[map_id];
	end

	
	return Technology[map_id][technology_type];
end



local PriceConfig = {
	0.8,
	0.9,
	1.0,
	1.1,
	1.2
};

--所有商品的可调节商品范围
function buildScienceConfig.GetShopPriceConfig()
	return PriceConfig;
end

local ResourceConfig = nil;



local function buildresourceBaseInfo()

	if ResourceConfig then
		return;
	end
	ResourceConfig = {};

	DATABASE.ForEach("city_resource", function(row)
		print(sprinttb(row))
		table.insert( ResourceConfig, row );
	end)

	table.sort( ResourceConfig, function ( a ,b )
		return a.id < b.id; 
	end )
end


function buildScienceConfig.GetResourceConfig()

	buildresourceBaseInfo();
	return ResourceConfig;
end

-- config_city_resource

return buildScienceConfig;