local titleDictionaryCfg=nil
local titleCfgByQuality=nil
local titleDictionaryCfgByItemId=nil
local function LoadTitleDictionaryConfig()
	if not titleDictionaryCfg then
		titleCfgByQuality={}
		titleDictionaryCfg={}
		--titleConfigByTitleId={}
		titleDictionaryCfgByItemId={}
		DATABASE.ForEach("title_dictionary", function(data)
	        local titleCfg = setmetatable({ conditions = {} }, {__index = data});
	        for i=1,3 do
	        	if data["condition"..i] then
	        		table.insert(titleCfg.conditions,data["condition"..i])
	        	end
	        end
	        titleDictionaryCfg[data.gid]=titleCfg
	        titleDictionaryCfgByItemId[tonumber(data.itemID)]=titleCfg
	        titleDictionaryCfgByItemId[tonumber(data.itemID1)] = titleCfg

	        titleCfgByQuality[data.quality]=titleCfgByQuality[data.quality] or {}
	        table.insert(titleCfgByQuality[data.quality],titleCfg)      
	    end)
	end
end

local function GetTitleConfig(gid)
	if not titleDictionaryCfg then
		LoadTitleDictionaryConfig()
	end
	if gid then
		return titleDictionaryCfg[gid]
	else
		return titleDictionaryCfg
	end
end

local function GetTitleConfigByItemId(id)
	if not titleDictionaryCfgByItemId then
		LoadTitleDictionaryConfig()
	end
	if id then
		return  titleDictionaryCfgByItemId[id]
	end
end

local function GetTitleDictionaryConfig(quality)
	if not titleCfgByQuality then
		LoadTitleDictionaryConfig()
	end
	if quality then
		return titleCfgByQuality[quality]
	else
		return titleCfgByQuality
	end
end

local roleTitleConfig=nil
local titleOwners=nil--称号拥有者
local function GetRoleTitleConfig(roleId)
	if not roleTitleConfig then
		roleTitleConfig={}
		titleOwners={}
		DATABASE.ForEach("role_title", function(data)
	        local titleCfg = setmetatable({ titleIds = {} }, {__index = data});
	        for i=1,4 do
	        	if data["titleID"..i] then
	        		table.insert(titleCfg.titleIds,data["titleID"..i])
	        		titleOwners[data["titleID"..i]]=titleOwners[data["titleID"..i]] or {}
	        		table.insert(titleOwners[data["titleID"..i]],data.roleID)
	        	end
	        end
	        roleTitleConfig[data.roleID]=titleCfg 
	    end)
	end

	if roleId then
		return roleTitleConfig[roleId]
	else
		return roleTitleConfig
	end
end

local function GetTitleOwners(titleId)
	if not titleOwners then
		GetRoleTitleConfig()
	end
	return titleOwners[titleId]
end

local titleSystemOpinions=nil
local function GetTitleSystemOpinionsConfig(titleId)
	if not titleSystemOpinions then
		titleSystemOpinions={}
		DATABASE.ForEach("title_annotation", function(data)
	        titleSystemOpinions[data.titleID]=titleSystemOpinions[data.titleID] or {}    
	        table.insert(titleSystemOpinions[data.titleID],data)
	    end)
	end
	return titleSystemOpinions[titleId]
end

local titleCondition=nil
local ConditionIdByQueryId=nil
local function GetTitleConditionConfig(ConditionId)
	if not titleCondition then
		titleCondition={}
		ConditionIdByQueryId={}
		DATABASE.ForEach("title_condition", function(data)
	        titleCondition[data.conditionID]=titleCondition[data.conditionID] or {}    
	        table.insert(titleCondition[data.conditionID],data.questID)
	        ConditionIdByQueryId[data.questID]=data
	    end)
	end
	if ConditionId then
		return titleCondition[ConditionId]
	else
		return titleCondition
	end	
end

local conditionTips=nil
local function GetTitleConditionTipConfig(ConditionId)
	if not conditionTips then
		conditionTips={}
		DATABASE.ForEach("finish_condition", function(data)
	        conditionTips[data.conditionID]= data
	    end)
	end
	return conditionTips[ConditionId]
end

local titleQuestTab=nil
local titleCfgByQuest=nil
local function GetAllTitleQuest()--获取所有的称号任务
	if not titleQuestTab then
		titleCfgByQuest={}
		titleQuestTab={}
		if not roleTitleConfig then
			GetRoleTitleConfig()
		end
		for k,v in pairs(roleTitleConfig) do
			local _roleTitleCfg=v
			for i=1,#_roleTitleCfg.titleIds do
				local _titleId=_roleTitleCfg.titleIds[i]
				local _titleCfg=GetTitleConfig(_titleId)--通过称号ID获取配置
				for j=#_titleCfg.conditions,1,-1 do
	                local ItemCount=module.ItemModule.GetItemCount(_titleCfg.itemID)
	                if ItemCount<1 then
	                    local ConditionId=_titleCfg.conditions[j]
	                    local funcTab=GetTitleConditionConfig(ConditionId)
	                    if funcTab then
	                        for _i=1,#funcTab do
	                        	table.insert(titleQuestTab,funcTab[_i])	
	                        	titleCfgByQuest[funcTab[_i]]=_titleId                 
	                        end
	                    end
	                end
	            end
			end
		end
	end
	return titleQuestTab
end

local function GetTitleByQuest(questId)
	if not titleCfgByQuest then
		GetAllTitleQuest()
	end
	return titleCfgByQuest[questId]
end

local function LocalGetRoleTitleCfg(hero)
	local talentdata = module.TalentModule.GetTalentData(hero.uuid, 4);
	local Cfg=nil
	local talentId   =hero.roletalent_id1
	local config=module.TalentModule.GetTalentConfig(talentId)
	for i=#talentdata,1,-1 do
		if talentdata[i]~=0 then
			Cfg=config[i]
			break
		end
	end
	return Cfg
end

local function  GetTitleStatus(hero)
	local Cfg = LocalGetRoleTitleCfg(hero)
	local OpenLevel = require "config.openLevel"
	return Cfg and Cfg.name or "称号",OpenLevel.GetStatus(1102)
end

local function GetHeroTitleQuality(hero)
	local Cfg = LocalGetRoleTitleCfg(hero)
	local _quality = 0
	if Cfg then
		local title_cfg = GetTitleConfig(Cfg.titleID)
		_quality = title_cfg and title_cfg.quality or 0
	end
	return _quality
end

return {
    GetCfg = GetTitleConfig,
    GetDictionaryConfig = GetTitleDictionaryConfig,
    GetRoleTitleCfg = GetRoleTitleConfig,
    GetSystemOpinions = GetTitleSystemOpinionsConfig,
    GetConditionCfg = GetTitleConditionConfig,
    GetTipCfg = GetTitleConditionTipConfig,

    GetTitleCfgByItem = GetTitleConfigByItemId,--通过道具获取称号配置

    GetTitleOwners = GetTitleOwners,--获取称号的所有拥有者
    GetTitleByQuest= GetTitleByQuest,--通过任务ID获得对应的 称号

    GetTitleStatus= GetTitleStatus,
    GetHeroTitleQuality = GetHeroTitleQuality,
}
