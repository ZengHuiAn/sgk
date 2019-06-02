local EventManager = require 'utils.EventManager';
local NetworkService = require "utils.NetworkService";
local Time = require "module.Time"

local AwardList = nil
local OfflineAwardList = nil
local Sn2Data = {};
local function GetAward()
	local _awardlist = {};
	local _offline_awardlist = {};
	if AwardList == nil then
		NetworkService.Send(193)
	else
		for i,v in ipairs(AwardList) do
			_awardlist[i] = v;
		end
	end
	if OfflineAwardList == nil then
		NetworkService.Send(199)
	else
		for i,v in ipairs(OfflineAwardList) do
			_offline_awardlist[i] = v;
		end
	end
	---[==[--新
		if OfflineAwardList and next(OfflineAwardList)~=nil then
			for i,v in ipairs(OfflineAwardList) do
				table.insert(_awardlist, v)
			end
		end
	--]==]

	--[===[--旧
		if _offline_awardlist[3] ~= nil and #_offline_awardlist[3] > 0 then
			table.insert(_awardlist, _offline_awardlist);
		end
	--]===]
	
	return _awardlist;
end

local function SetAward()
	
end


local function UpdateReward(data)
	local _tab = {
		content=
		{
			content = data.info,
			item = {},
			id = data.id,
		},
		attachment_opened = 0,
		attachment_count = 1,
		status = 2,

		formid = 100000,
		id = data.id,
		key = 100000,

		title = data.title,
		type = data.type,

		fromname = data.fromname,

		time = data.time or ""--Time.now()
	}

	return _tab
end

local function SetAwardByType(data,type)
	local _tab = {}
	if type == 1 then
		_tab = {
			title = data[2],
			fromname = "老龙",
			id = data[1],
			info = "请继续努力唷~",
			type = 102,
		}
	elseif type == 2 then
		_tab = {
			title = "离线补偿",
			fromname = "双子星",
			info = "主人,请继续努力唷~",
			time = data[1],
			type = 103,
		}
	end
	return UpdateReward(_tab)
end

local function GetOfflineAwardList(force)
	if OfflineAwardList == nil or force then
		NetworkService.Send(199)
		return {}
	end
	return OfflineAwardList
end

local function GetOfflineAward(time, refresh)
	print("领取",time);
	local sn = NetworkService.Send(201, {nil,time});
	Sn2Data[sn] = {time, refresh};
end

EventManager.getInstance():addListener("server_respond_194", function(event, cmd, data)
	--ERROR_LOG(" 查询可领取奖励返回->194"..sprinttb(data))
	local sn = data[1];
	local err = data[2];
	if err == 0 then

		---[==[--新 
			AwardList = {}
			for i=1,#data[3] do
				local _tab = SetAwardByType(data[3][i],1)
				table.insert(AwardList,_tab)
			end
		--]==]
		--[===[--旧
			AwardList = data[3]
		--]===] 
		DispatchEvent("NOTIFY_REWARD_CHANGE")
	end
end)

EventManager.getInstance():addListener("server_respond_196", function(event, cmd, data)
	local sn = data[1];
	local err = data[2];
	--ERROR_LOG("领取奖励返回->196",sprinttb(data))
	if err == 0 then
		utils.NetworkService.Send(193)
	end
end)

EventManager.getInstance():addListener("server_notify_49", function(event, cmd, data)
    --ERROR_LOG("奖励变化通知->49",sprinttb(data))
  	---[==[--新 
		AwardList = {}
		for i=1,#data do
			local _tab = SetAwardByType(data[i],1)
			table.insert(AwardList,_tab)
		end
	--]==]

	--[===[--旧
		AwardList = data
	--]===] 

    DispatchEvent("NOTIFY_REWARD_CHANGE")
end);

EventManager.getInstance():addListener("server_respond_200", function(event, cmd, data) --查询离线奖励
	--ERROR_LOG("server_respond_200>>离线奖励",sprinttb(data))
	local sn = data[1];
	local err = data[2];
	local list = data[3];
	if err == 0 then
		OfflineAwardList = {};
		--[===[--旧
			if list then
				OfflineAwardList[1] = 1;
				OfflineAwardList[2] = "离线补偿";
				OfflineAwardList[3] = {};
				local _t = os.date("*t", Time.now())
				local today = Time.now() - _t.sec - (_t.min * 60) - (_t.hour * 3600)
				for i,v in ipairs(list) do
					if v[1] < today then
						table.insert(OfflineAwardList[3], v)
					end
				end	
			end
		--]===] 

		---[==[--新 
		if list then
			local _t = os.date("*t", Time.now())
			local today = Time.now() - _t.sec - (_t.min * 60) - (_t.hour * 3600)
			local _TimeList = {}
			for i,v in ipairs(list) do
				if v[1] < today then
					if not _TimeList[v[1]] then
						_TimeList[v[1]] = true
						local _tab = SetAwardByType(v,2)
						table.insert(OfflineAwardList,_tab)
					end
				end
			end
		end
		table.sort(OfflineAwardList,function(a,b)
			return a.time > b.time
		end)
		--]==]
		DispatchEvent("NOTIFY_REWARD_CHANGE")
	end
	-- print("离线奖励",sprinttb(data))
end)

local lastSendTime = 0
EventManager.getInstance():addListener("server_respond_202", function(event, cmd, data) --领取离线奖励返回
	local sn = data[1];
	local err = data[2];
	--ERROR_LOG("领取奖励",sprinttb(data))
	if err == 0 then
		---[==[--新
			if Sn2Data[sn] then
				if Sn2Data[sn][2] then
					if tiem.now()-lastSendTime >= 5 then
						lastSendTime = Time.now()
						utils.NetworkService.Send(199)
					end	
				else
					local _OfflineAwardList = {}
					local _time = Sn2Data[sn][1]
					if OfflineAwardList and next(OfflineAwardList)~=nil  then
						for i,v in ipairs(OfflineAwardList) do
							if v.time ~= _time then
								table.insert(_OfflineAwardList,v)
							end
						end
						table.sort(_OfflineAwardList,function(a,b)
							return a.time > b.time
						end)

						OfflineAwardList = _OfflineAwardList
						DispatchEvent("NOTIFY_REWARD_CHANGE")
					end					
				end
			end
		--]==]
		--[===[--旧
			DispatchEvent("OFFLINE_REWARD_CHANGE", {time = Sn2Data[sn][1], list = data[3]})
			if Sn2Data[sn][2] then
				utils.NetworkService.Send(199)
			end
		--]===]
		
	end
end)
return {
	GetAward = GetAward,
	SetAward = SetAward,
	GetOfflineAwardList = GetOfflineAwardList,
	GetOfflineAward = GetOfflineAward,
	GetOfflineAward = GetOfflineAward,
}