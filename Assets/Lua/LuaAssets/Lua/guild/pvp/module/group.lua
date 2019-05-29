--require "DelayQuery"
local EventManager = require "utils.EventManager"
local NetworkService = require "utils.NetworkService"
local Time = require "module.Time"
local M = {}

local function ON_SERVER_RESPOND(id, callback)
	EventManager.getInstance():addListener("server_respond_" .. id, callback);
end

local function ON_SERVER_NOTIFY(id, callback)
	EventManager.getInstance():addListener("server_notify_" .. id, callback);
end

local function dumpValue(t, prefix, suffix)
	prefix = prefix or "";
	suffix = suffix or "";

	local ret = "";
	if type(t) == "table" then
		ret = ret .. "{\n";
		for k, v in pairs(t) do
			if type(v) == "table" then
				ret = ret .. dumpValue(k, prefix .. "  [", "]") .. " = " .. dumpValue(v, prefix .. "  ") .. ",\n";
			else
				ret = ret .. dumpValue(k, prefix .. "  [", "]") .. " = " .. dumpValue(v) .. ",\n";
			end
		end
		ret = ret .. prefix .. "}";
	elseif type(t) == "string" then
		ret = ret .. prefix .. "\"" .. t .. "\"" .. suffix;
	elseif type(t) == "number" then
		ret = ret .. prefix .. t .. suffix;
	else
		ret = ret .. prefix .. "<" .. tostring(t) .. ">" .. suffix;
	end
	return ret;
end


local SituationTemplate = {
	{
		{
			{
				{ 1, 32},
				{16, 17},
			},
			{
				{ 8, 25},
				{ 9, 24},				
			}
		},
		{
			{
				{ 4, 29},
				{13, 20},

			},
			{
				{ 5, 28},
				{12, 21},
			}
		},
	},
	{
		{
			{
				{ 2, 31},
				{15, 18},
			},
			{
				{ 7, 26},
				{10, 23},
			}
		},
		{
			{
				{ 3, 30},
				{14, 19},
			},
			{
				{ 6, 27},
				{11, 22},
			}
		},

	},
}


local Ground = {};
local winnerFoo = {
	id = 0,
	name = nil,
	order = 0,
};

local function updateSituation(info, guilds, round)
	round = round or 5;
	if type(info) == "number" then
		return {
			guild = guilds[info] or winnerFoo,
			id    = info,
		}
	elseif type(info) == "table" then
		local ret = {round = round};
		
		local winner = nil;
		for k, v in ipairs(info) do
			ret[k] = updateSituation(v, guilds, round - 1);
			if (ret[k].guild.order and ret[k].guild.order > 0) and (winner == nil or ret[k].guild.order < winner.order) then
				winner = ret[k].guild;
			elseif winner and ret[k].guild.order == winner.order then
				winner = winnerFoo;
			end
		end
		ret.guild = winner or winnerFoo;

		return ret;
	end
end

local function _T(msg)
	return msg
end
function Ground.New(startTime, guilds)
	local fakeOrder = {
		1, 2, 3, 4, 
		5, 5, 5, 5, 
		6, 6, 6, 6, 6, 6, 6, 6,
		7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7
	};
	local minOrder = 7;

	local xguilds = {};
	for k, v in ipairs(guilds) do
		table.insert(xguilds, v);
		v.index = #xguilds;
		if v.order and minOrder > v.order then
			minOrder = v.order;
		end
	end

	while #xguilds < 32 do
		local n = #xguilds + 1;
		table.insert(xguilds, {
			index = n,
			id = 0,
			fight_status = 0,
			name  = nil,
			level = 0,
			order = ((fakeOrder[n] < minOrder) and minOrder or fakeOrder[n]),
		})
	end

	local t = {
		startTime = startTime,
		guilds    = guilds,
		situation = updateSituation(SituationTemplate, xguilds),
	};
	return setmetatable(t, {__indnex=Ground});
end

M.C_GUILD_WAR_ENTER_REQUEST                 = 3320  -- 进入公会战活动请求
M.C_GUILD_WAR_ENTER_RESPOND                 = 3321  --   

M.C_GUILD_WAR_LEAVE_REQUEST                 = 3322  -- 离开公会战活动请求
M.C_GUILD_WAR_LEAVE_RESPOND                 = 3323  --   

M.C_GUILD_WAR_JOIN_REQUEST                  = 3324  -- 公会报名参加活动
M.C_GUILD_WAR_JOIN_RESPOND                  = 3325  -- 

M.C_GUILD_WAR_QUERY_REPORT_REQUEST          = 3330 --公会查询榜单信息
M.C_GUILD_WAR_QUERY_REPORT_RESPOND          = 3331 

M.C_GUILD_WAR_QUERY_HISTORY_REPORT_REQUEST  = 3334 --公会查询历史榜单信息
M.C_GUILD_WAR_QUERY_HISTORY_REPORT_RESPOND  = 3335 


M.NOTIFY_GUILD_WAR_ORDER                    = 1120 -- 公会战顺序改变
M.NOTIFY_GUILD_WAR_STATUS                   = 1117 -- 公会战战场情况
M.NOTIFY_GUILD_WAR_LIST_CHANGE              = 1119 -- 公会战报名

M.C_GUILD_WAR_SET_ORDER_REQUEST = 3332   -- 公会设置主将顺序
M.C_GUILD_WAR_SET_ORDER_RESPOND = 3333

M.C_GUILD_WAR_QUERY_ORDER_REQUEST = 3340  -- 公会查询任命请求
M.C_GUILD_WAR_QUERY_ORDER_RESPOND = 3341  -- 公会查询任命返回

function M.QueryHeros()
	if M.data and M.data.heros == nil then
		M.data.heros = {0, 0, 0, 0};
	end
	--ERROR_LOG(debug.traceback())
	-- NetworkService.Send(3340);
	NetworkService.Send(M.C_GUILD_WAR_QUERY_ORDER_REQUEST);
end

local function updateHeros(heros)
	heros = heros or {};
	M.data.heros = {};
	for i = 1, 4 do
		M.data.heros[i] = heros[i] or 0;
	end
	 EventManager.getInstance():dispatch("GUILD_PVP_HERO_CHANGE");
end

ON_SERVER_RESPOND(M.C_GUILD_WAR_QUERY_ORDER_RESPOND, function(event, cmd, data)
-- EventManager.getInstance():addListener("server_respond_3341", function(event, cmd, data)
	M.dump(data);
	if data[2] ~= 0 then
		return;
	end

	if M.data == nil then
		return;
	end
	print("公会查询任命返回",sprinttb(data))
	updateHeros(data[3]);
end)

M.signupLevel = 2;
M.signupCount = 16;

M.data = nil;
--[[
	room_status = nil; 
	room_fight_status = nil;
	nextBattleInfo = {          -- 当前或者下一场战斗开始时间
		prepare_time = nil,
		check_time   = nil,
		begin_time   = nil,
	};
	guildList = {},
	heros = {},
--]]

function M.GetNextBattleTime()
	return M.data and M.data.nextBattleInfo;
end

function M.setHero(heros)
--[[
	if type < 1 or type > 4 then
		return;
	end
--]]
	if M.data == nil or M.data.heros == nil then
		return;
	end

--[[
	if M.data.heros[type] == pid then
		return;
	end
--]]

--[[
	local heros = {
		M.data.heros[1], 
		M.data.heros[2],
		M.data.heros[3],
		M.data.heros[4],
	};
--]]

	print("setHero", unpack(heros));

--[[
	for k, v in ipairs(heros) do
		if v == pid then
			heros[k] = 0;
			break;
		end
	end
	heros[type] = pid;
--]]

	-- NetworkService.Send(3332,{nil, heros})
	NetworkService.Send(M.C_GUILD_WAR_SET_ORDER_REQUEST, {nil, heros});
end

-- EventManager.getInstance():addListener("server_respond_3333", function(event, cmd, data)
ON_SERVER_RESPOND(M.C_GUILD_WAR_SET_ORDER_RESPOND, function(event, cmd, data)
	print("C_GUILD_WAR_SET_ORDER_RESPOND")
	M.dump(data);
	if data[2] ~= 0 then
		if data[2] == 5 then
			cmn.show_tips("@str/guild/pvp/error/set_hero_at_fighting");
		else
			cmn.show_tips("@str/opt_error");
		end
		return;
	end
	updateHeros(data[3]);
end)


function M.GetHero(idx)
	if M.data and M.data.heros then
		if idx then
			return M.data.heros[idx];
		else
			local heros = {};
			for i,v in ipairs(M.data.heros) do
				heros[i] = v;
			end
			return heros;
		end
	end
end

--[[
local roomStatusMessage = {
	[0] = _T("@str/guild/pvp/room_phase_0"),
	[1] = _T("@str/guild/pvp/room_phase_1"),
	[2] = _T("@str/guild/pvp/room_phase_2"),
	[3] = _T("@str/guild/pvp/room_phase_3"),
	[4] = _T("@str/guild/pvp/room_phase_4"),
};

local roomFightStatusMessage = {
	[0] = _T("@str/guild/pvp/fight_phase_0"),
	[1] = _T("@str/guild/pvp/fight_phase_1"),
	[2] = _T("@str/guild/pvp/fight_phase_2"),
	[3] = _T("@str/guild/pvp/fight_phase_3"),
	[4] = _T("@str/guild/pvp/fight_phase_4"),
};
--]]

local roomStatusNotify = {{},{},{},{}};
roomStatusNotify[1][0] = "@str/guild/pvp/notify/start";
roomStatusNotify[2][1] = "@str/guild/pvp/notify/inspire";
roomStatusNotify[4][0] = "@str/guild/pvp/notify/end";

local g_room_status = nil;
local g_room_fight_status = nil;
local g_room_lefttime = 0;
local g_room_lefttime_update_time = 0;

local function updateStatus(data, isQuery)
	local room_status       = data[1];
	local room_fight_status = data[2];
	local room_lefttime     = data[3];
	
	if M.data then
		M.data.room_status = room_status;
		M.data.room_fight_status = room_fight_status;
		M.data.room_lefttime = room_lefttime
		M.data.room_lefttime_update_time = Time.now();
	end

	if (room_status == 0 or room_status == 4 or room_status == 1) and not isQuery then
		M.clear();
	end

	print("updateStatus", room_status, g_room_status, room_fight_status, g_room_fight_status);
	g_room_lefttime = room_lefttime;
	g_room_lefttime_update_time = Time.now();

	if room_status ~= g_room_status or room_fight_status ~= g_room_fight_status then
		g_room_status = room_status;
		g_room_fight_status = room_fight_status;

		if not isQuery and not M.isEnterRoom and (room_status == 2 or room_status == 3) then
			M.clear();
		end

		EventManager.getInstance():dispatch("GUILD_PVP_GROUP_STATUS_CHANGE", g_room_status, g_room_fight_status);

		if roomStatusNotify[room_status] and roomStatusNotify[room_status][room_fight_status] then
			local msg = roomStatusNotify[room_status][room_fight_status];
			EventManager.getInstance():dispatch("Broadcast_Send", _T(msg), 2);
		end
	end
end

function M.GetLeftTime(native)
	local room_lefttime = M.data and M.data.room_lefttime or g_room_lefttime;
	local room_lefttime_update_time = M.data and M.data.room_lefttime_update_time or g_room_lefttime_update_time;
	
	local lefttime = room_lefttime - (Time.now() - room_lefttime_update_time);
	if native then
		return lefttime;
	else
		return lefttime > 0 and lefttime or 0;
	end
end

local BroadcastString = {
	[1] = {des = "公会战即将开始", count = 0},
	[2] = {des = "公会战新一轮开始啦，会员快来领取打call棒", count = 0},
	[3] = {des = "公会战新一轮开始啦，会员快来领取打call棒", count = 0},
	[4] = {des = "公会战新一轮开始啦，会员快来领取打call棒", count = 0},
	[5] = {des = "公会战新一轮开始啦，会员快来领取打call棒", count = 0},
	[6] = {des = "公会战新一轮开始啦，会员快来领取打call棒", count = 0},
	[7] = {des = "恭喜%s公会，在公会战中勇夺第一！",count = 0 }
}

local function CheckBroadcast(test)
	local status,fight_status = M.data and M.data.room_status or g_room_status, M.data and M.data.room_fight_status or g_room_fight_status;
	local minOrder = M.GetMinOrder();
	local key = 0;
	if status == 1 then
		key = 1;
	elseif status == 2 and fight_status == 1 then
		if minOrder == 7 then
			key = 2;
		elseif minOrder == 6 then
			key = 3;
		elseif minOrder == 5 then
			key = 4;
		elseif minOrder == 4 then
			key = 5;	
		elseif minOrder == 2 then
			key = 6;
		end
	elseif minOrder == 1 then
		key = 7;
	end 
	-- ERROR_LOG("检查广播",test, status,fight_status, minOrder,key)
	if BroadcastString[key] and BroadcastString[key].count == 0 then
		BroadcastString[key].count = BroadcastString[key].count + 1;
		if key ~= 7 then
			if key == 1 then
				BroadcastString[7].count = 0;
			end
			module.ChatModule.SystemChatMessage(BroadcastString[key].des);
			utils.SGKTools.showScrollingMarquee(BroadcastString[key].des, 2);
		else
			for i,v in ipairs(BroadcastString) do
				if i <= 6 then
					BroadcastString[i].count = 0;
				end
			end
			local info = M.GetGroundByGroup(0);
			local guild_slot_list = {
				[1] = {1, 1},
				[4] = {1, 2},
		
				[2] = {2, 1},
				[3] = {2, 2},
			}
			local name = "";
			for i,v in ipairs(guild_slot_list) do
				local guild_info = info[v[1]][v[2]];
				if guild_info.guild.order == 1 then
					local _guild = utils.Container("UNION"):Get(guild_info.guild.id);
					if _guild then
						name = _guild.unionName;
					end
					break;
				end
			end
			module.ChatModule.SystemChatMessage(string.format(BroadcastString[key].des, name));
			utils.SGKTools.showScrollingMarquee(string.format(BroadcastString[key].des, name), 2);
		end
	end
end

-- EventManager.getInstance():addListener("server_notify_1117", function(event, cmd, data)
ON_SERVER_NOTIFY(M.NOTIFY_GUILD_WAR_STATUS, function(event, cmd, data)
	print("--> NOTIFY_GUILD_WAR_STATUS")
	M.dump(data);
	updateStatus(data);	
	CheckBroadcast("状态推送");
end)


function M.Enter()
	print("--> enter guild pvp")
	-- NetworkService.Send(3320)
	NetworkService.Send(M.C_GUILD_WAR_ENTER_REQUEST);
end

ON_SERVER_RESPOND(M.C_GUILD_WAR_ENTER_RESPOND, function(event, cmd, data)
-- EventManager.getInstance():addListener("server_respond_3321", function(event, cmd, data)
	if data[2] == 0 then
		M.isInRoom = true;
	end
end);

function M.Leave()
	print("--> leave guild pvp")
	M.isInRoom = false;
	-- NetworkService.Send(3322)
	NetworkService.Send(M.C_GUILD_WAR_LEAVE_REQUEST);
end

function M.Join()
	-- return NetworkService.Send(3324)
	return NetworkService.Send(M.C_GUILD_WAR_JOIN_REQUEST)
end

ON_SERVER_RESPOND(M.C_GUILD_WAR_JOIN_RESPOND, function(event, cmd, data)
-- EventManager.getInstance():addListener("server_respond_3325", function(event, cmd, data)
	local errno = data[2];
	EventManager.getInstance():dispatch("GUILD_PVP_JOIN_STATUS_CHANGE", errno);
	if errno == 0 then
		showDlgError(nil,"报名成功")
		M.QueryHeros();
	else
		showDlgError(nil,"报名失败 ERROR_LOG "..errno)
	end
end)

local guildListQueryTime = 0;
local guildListQueryDelay = math.random(3,10);
function M.QueryReport()
	local t = M.GetLeftTime(true);
	local nextQueryStep = 60 * 10;
	if t < -guildListQueryDelay then
		nextQueryStep = 10;
	end

	local nextQueryTime = guildListQueryTime + nextQueryStep;
	local now = Time.now();
	if M.data == nil or now >= nextQueryTime then
		-- print("查询战报", debug.traceback())
		NetworkService.Send(M.C_GUILD_WAR_QUERY_REPORT_REQUEST);
		guildListQueryTime = now;
	end
end

ON_SERVER_RESPOND(M.C_GUILD_WAR_QUERY_REPORT_RESPOND, function(event, cmd, data)
-- EventManager.getInstance():addListener("server_respond_3331", function(event, cmd, data)
	print("C_GUILD_WAR_QUERY_REPORT_RESPOND",sprinttb(data));
	-- M.dump(data);

	local errno = data[2];
	if errno ~= 0 then
		return;
	end

	local info = data[3];
	M.data = {};

	M.data.nextBattleInfo = {          -- 当前或者下一场战斗开始时间
		prepare_time = info[1][1],
		check_time   = info[1][2],
		begin_time   = info[1][3],
	}

	updateStatus(info[2], true);

	local pid   = module.playerModule.GetSelfID();
	local guild = {id = module.unionModule.Manage:GetUionId()};
	
	local reports = info[3];
	local guilds = {};
	local minOrder = 7;
	for _, v in ipairs(reports) do
		table.insert(guilds, {
			id = v[1];
			fight_status = v[2];
			order = v[3] or 7;
		})

		if v[3] and v[3] < minOrder then
			minOrder = v[3];
		end

		if guild and v[1] == guild.id then
			M.QueryHeros();
		end
	end

	M.data.minOrder = minOrder;
	M.data.guildList = guilds;            -- 报名列表

	EventManager.getInstance():dispatch("GUILD_PVP_GUILD_LIST_CHANGE");

	local now = Time.now()--ActivityModule.GETSERVERTIME();
	if now >= M.data.nextBattleInfo.check_time then
		print("guild pvp is start")
		M.data.ground = Ground.New(Time.now(), guilds);
		EventManager.getInstance():dispatch("GUILD_PVP_GROUND_CHANGE");
	else
		print("guild pvp is not start, query history report", M.data.nextBattleInfo.check_time - now);
		M.QueryHistoryReport();
	end
	CheckBroadcast("战报查询");
end);

-- EventManager.getInstance():addListener("server_notify_1120", function(event, cmd, data)
ON_SERVER_NOTIFY(M.NOTIFY_GUILD_WAR_ORDER, function(event, cmd, data)
	local reports = data;

	local guilds = {};

	M.dump(data);

	if M.data == nil then
		return;
	end

	local minOrder = 7;
	for _, v in ipairs(reports) do
		table.insert(guilds, {
			id = v[1];
			fight_status = v[2];
			order = v[3] or 7;
		});

		if v[3] and v[3] < minOrder then
			minOrder = v[3];
		end
	end

	M.data.minOrder = minOrder;
	M.data.guildList = guilds;            -- 报名列表
	EventManager.getInstance():dispatch("GUILD_PVP_GUILD_LIST_CHANGE");

	M.data.ground = Ground.New(Time.now(), guilds);
	EventManager.getInstance():dispatch("GUILD_PVP_GROUND_CHANGE");
	CheckBroadcast("战报推送");
end)

-- EventManager.getInstance():addListener("server_notify_1119", function(event, cmd, data)
ON_SERVER_NOTIFY(M.NOTIFY_GUILD_WAR_LIST_CHANGE, function(event, cmd, data)
	if M.data and M.data.guildList then
		for _, v in ipairs(M.data.guildList) do
			if v.id == data then
				return;
			end
		end
		
		table.insert(M.data.guildList, {
			id = data;
			fight_status = 0;
			order = 7;
		});
		EventManager.getInstance():dispatch("GUILD_PVP_GUILD_LIST_CHANGE");
	end
end)

function M.QueryHistoryReport()
	-- NetworkService.Send(3334);
	NetworkService.Send(M.C_GUILD_WAR_QUERY_HISTORY_REPORT_REQUEST);
end

-- EventManager.getInstance():addListener("server_respond_3335", function(event, cmd, data)
ON_SERVER_RESPOND(M.C_GUILD_WAR_QUERY_HISTORY_REPORT_RESPOND, function(event, cmd, data)
	-- M.dump(data);

	if data[2] ~= 0 then
		return;
	end

	if M.data == nil then
		return;
	end

	local reports = data[3];
	local guilds = {};

	local minOrder = 7;
	for _, v in ipairs(reports) do
		table.insert(guilds, {
			id = v[1];
			order = v[2];
			fight_status = v[4];
		})
		if v[2] and v[2] < minOrder then
			minOrder = v[2];
		end
	end

	M.data.minOrder = minOrder;
	M.data.ground = Ground.New(Time.now(), guilds);
	EventManager.getInstance():dispatch("GUILD_PVP_GROUND_CHANGE");
end)

function M.GetGroundByGroup(n)
	M.QueryReport();

	if M.data == nil or M.data.ground == nil then
		return nil;
	end

	if n == 1 then
		return M.data.ground.situation[1][1];
	elseif n == 2 then
		return M.data.ground.situation[2][1];
	elseif n == 3 then
		return M.data.ground.situation[2][2];
	elseif n == 4 then
		return M.data.ground.situation[1][2];
	else
		return M.data.ground.situation;
	end	
end


local fightIndex =
{
	[ 1] = {1, 1, 1, 1},
	[ 2] = {2, 1, 1, 1},
	[ 3] = {2, 2, 1, 1},
	[ 4] = {1, 2, 1, 1},
	[ 5] = {1, 2, 2, 1},
	[ 6] = {2, 2, 2, 1},
	[ 7] = {2, 1, 2, 1},
	[ 8] = {1, 1, 2, 1},
	[ 9] = {1, 1, 2, 2},
	[10] = {2, 1, 2, 2},
	[11] = {2, 2, 2, 2},
	[12] = {1, 2, 2, 2},
	[13] = {1, 2, 1, 2},
	[14] = {2, 2, 1, 2},
	[15] = {2, 1, 1, 2},
	[16] = {1, 1, 1, 2},

	[17] = {1, 1, 1},
	[18] = {2, 1, 1},
	[19] = {2, 2, 1},
	[20] = {1, 2, 1},
	
	[21] = {1, 2, 2},
	[22] = {2, 2, 2},
	[23] = {2, 1, 2},
	[24] = {1, 1, 2},
	
	[33] = {1, 1},
	[34] = {2, 1},
	[35] = {2, 2},
	[36] = {1, 2},

	[49] = {1},
	[50] = {2},

	[65] = {},
}

function M.GetFightByRoomId(id)
	local indexs = fightIndex[id];
	if indexs == nil then
		return nil;
	end

	local situation = M.data.ground.situation;
	for _, i in ipairs(indexs) do
		situation = situation[i];
	end
	return situation;
end

function M.GetGroundGuildList()
	if M.data and M.data.ground then
		return M.data.ground.guilds;
	end
end

function M.IsDataReady( ... )
	return M.data ~= nil;
end

function M.GetGuildList()
	M.QueryReport();
	return M.data and M.data.guildList or {};
end

function M.GetMinOrder()
	return M.data and M.data.minOrder or 7;
end

function M.dump(v)
	print(dumpValue(v));
end

function M.clear()
	if M.data then
		M.data = nil;
		EventManager.getInstance():dispatch("GUILD_PVP_GUILD_LIST_CHANGE");
		EventManager.getInstance():dispatch("GUILD_PVP_GROUND_CHANGE");
	end
end

function M.GetStatus()
	if M.data == nil then
		return 4, 4
	else
		return M.data.room_status or g_room_status, M.data.room_fight_status or g_room_fight_status;
	end
end

function M.setGuildButtonLabel(button, guild, default, withOrder)
	if guild and guild.id > 0 then
		local info = utils.Container("UNION").Get(guild.id);
		local name = info and info.name or "loading...";
		local str = withOrder and string.format("%d.%s", guild.order, name) or name;
		button.titleLabel:setString(str);
		button.titleLabel:setTextColor(cc.c4b(255, 255, 255, 255));

		if button.dragon then
			if guild.order == 4 then
				button.dragon:setTexture("juntuan/pvp/gui_common_bg_juntuan_pvp_17d.png");
			elseif guild.order == 3 and button.dragon then
				button.dragon:setTexture("juntuan/pvp/gui_common_bg_juntuan_pvp_17c.png");
			elseif guild.order == 2 and button.dragon then
				button.dragon:setTexture("juntuan/pvp/gui_common_bg_juntuan_pvp_17b.png");
			elseif guild.order == 1 and button.dragon then
				button.dragon:setTexture("juntuan/pvp/gui_common_bg_juntuan_pvp_17a.png");
			end
			button.dragon:setVisible(guild.order <= 4);
		elseif button.winFlag then
			button.winFlag:setTexture("juntuan/pvp/gui_common_bg_juntuan_pvp_04.png");
			button.winFlag:setVisible(guild.order <= 4);
		end

		local player_guild = GUILD.PlayerGuild();

		local image = nil;
		if guild.order > 4 and guild.order > M.GetMinOrder() then
			image = "juntuan/pvp/gui_common_bg_juntuan_02b.png";
		elseif player_guild and guild.id == player_guild.id then
			image = "juntuan/pvp/gui_common_bg_juntuan_02d.png";
		else
			image = "juntuan/pvp/gui_common_bg_juntuan_02c.png";
		end

		local contentSize = button.bg:getContentSize();
		local frame = cc.SpriteFrame:create(image, cc.rect(0,0, 106, 56));
		button.bg:setSpriteFrame(frame);
		button.bg:setContentSize(contentSize);
	else
		button.titleLabel:setString(_T(default and default or ""));
		button.titleLabel:setTextColor(cc.c4b(143, 143, 143, 255));
	end
end

function M.changeLineColor(line, o1, o2)
	local isWin = ( ((o1.id~=0) or (o2.id~=0)) and (o1.order<=o2.order));
	if line.conner and line.first and line.second then
		line.first:setTexture(isWin and "juntuan/pvp/gui_common_bg_juntuan_pvp_06b.png" or "juntuan/pvp/gui_common_bg_juntuan_pvp_06a.png");
		line.second:setTexture(isWin and "juntuan/pvp/gui_common_bg_juntuan_pvp_06b.png" or "juntuan/pvp/gui_common_bg_juntuan_pvp_06a.png");
		line.conner:setTexture(isWin and "juntuan/pvp/gui_common_bg_juntuan_pvp_07b.png" or "juntuan/pvp/gui_common_bg_juntuan_pvp_07a.png");
	else
		line:setTexture(isWin and "juntuan/pvp/gui_common_bg_juntuan_pvp_06b.png" or "juntuan/pvp/gui_common_bg_juntuan_pvp_06a.png");
	end
end

function M.updateLeftTime(lefttime, label)
	local str = lefttime;
	local blink = false;
	if type(lefttime) == "number" then
		local hour = math.floor(lefttime/3600);
		local min  = math.floor((lefttime%3600)/60)
		local sec  = lefttime%60;
		if hour > 0 then
			str = string.format("%.2d:%.2d:%.2d", hour, min, sec);
		else
			str = string.format("%.2d:%.2d", min, sec);
		end

		blink = (lefttime <= 5);

		if g_room_fight_status == 0 then
			str = _T("@str/guild/pvp/room_stage_0") .. str;
		elseif g_room_fight_status == 1 then
			str = _T("@str/guild/pvp/room_stage_1") .. str;
		elseif g_room_fight_status == 2 then
			str = _T("@str/guild/pvp/room_stage_2") .. str;
		end
	end


	label:setString(str);
	if blink then
		if label:getActionByTag(1001) == nil then
			local act = cc.RepeatForever:create(cc.Sequence:create(
				cc.FadeIn:create(0.1),
				cc.DelayTime:create(0.5),
				cc.FadeOut:create(0.4)
			));
			act:setTag(1001);
			label:runAction(act);
		end
	else
		label:stopActionByTag(1001);
		label:setOpacity(255);
	end
end
-- module.ChatModule.SystemChatMessage
-- utils.SGKTools.showScrollingMarquee(noticeStr,1)
-- local updateTime = 0;
-- SGK.CoroutineService.Schedule(function()
-- 	if os.time() - updateTime >= 1 then
-- 		updateTime = os.time();
-- 		local leftTime = M.GetLeftTime(true);
-- 		if leftTime == 0 then

-- 		end
-- 	end
-- end)
return M;