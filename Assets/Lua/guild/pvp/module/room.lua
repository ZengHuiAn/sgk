local GuildPVPGroupModule = require "guild.pvp.module.group"

local DEBUG = {
	dump = GuildPVPGroupModule.dump
}

local M = {}


local sendServerRequest = utils.NetworkService.Send

------------------
M.C_GUILD_WAR_INSPIRE_REQUEST            = 3326  -- 公会战鼓舞
M.C_GUILD_WAR_INSPIRE_RESPOND            = 3327 

function M.Inspire()
	sendServerRequest(M.C_GUILD_WAR_INSPIRE_REQUEST);
end

utils.EventManager.getInstance():addListener("server_respond_3327", function(event, cmd, data)
	if data[2] == 0 then
		M.data.self_inspire_count = 1;
	end
	utils.EventManager.getInstance():dispatch("GUILD_PVP_INSPIRE_RESULT", data[2] == 0);
end)

------------------
M.C_GUILD_WAR_ENTER_SUB_ROOM_REQUEST     = 3328 --公会进入子房间
M.C_GUILD_WAR_ENTER_SUB_ROOM_RESPOND     = 3329

M.data = {};

local enteredRoomRecord = {};

local lastEnterSN = nil;
local lastEnterRoomID = nil;
function M.EnterRoom(room)	
	lastEnterSN = sendServerRequest(M.C_GUILD_WAR_ENTER_SUB_ROOM_REQUEST, {nil, room});
	lastEnterRoomID = room;
end

local function appendFightRecord(records, data, g1)
	table.insert(records,{
		winner = ((data[1]==g1) and 1 or 2),
		fight  = data[2],
	})
end

-- local function buildTestData()
-- 	do return end;
-- 	if M.data then
-- 		return;
-- 	end

-- 	M.data = {
-- 		fightStatus = 1;
-- 		guilds  = {{id=100}, {id=200}},
-- 		players = {{}, {}},
-- 		records = {},
-- 	}

-- 	for i = 1, 20 do
-- 		table.insert(M.data.players[1], {
-- 			type = ((i<5) and i or 5),
-- 			pid = 100 + i
-- 		});

-- 		table.insert(M.data.players[2], {
-- 			type = ((i<5) and i or 5),
-- 			pid = 200 + i
-- 		});
-- 	end

-- 	for i = 1, 39 do
-- 		table.insert(M.data.records, {
-- 			fid = i,
-- 			winner = ((i+1)%2+1),
-- 		});
-- 	end
-- 	utils.EventManager.getInstance():dispatch("GUILD_PVP_ROOM_RECORD_READY");
-- end


-- local function buildTestData()
-- 	if M.data then
-- 		return;
-- 	end

-- 	M.data = {
-- 		fightStatus = 1;
-- 		guilds  = {{id=100}, {id=200}},
-- 		players = {{}, {}},
-- 		records = {},
-- 	}

-- 	M.data.roomStatus = 3;
-- 	for i = 1, 20 do
-- 		table.insert(M.data.players[1], {
-- 			type = ((i<5) and i or 5),
-- 			pid = 100 + i
-- 		});

-- 		table.insert(M.data.players[2], {
-- 			type = ((i<5) and i or 5),
-- 			pid = 200 + i
-- 		});
-- 	end

-- 	for i = 1, 39 do
-- 		table.insert(M.data.records, {
-- 			fid = i,
-- 			winner = ((i+1)%2+1),
-- 		});
-- 	end
-- 	utils.EventManager.getInstance():dispatch("GUILD_PVP_ROOM_RECORD_READY");
-- end

utils.EventManager.getInstance():addListener("server_respond_3329", function(_, _, data)
	print("--> C_GUILD_WAR_ENTER_SUB_ROOM_RESPOND")
	print("进入房间返回", sprinttb(data))
	DEBUG.dump(data);
	
	if data[1] ~= lastEnterSN then
		return;
	end

	lastEnterSN = nil;

	local errno = data[2];
	if errno ~= 0 then
		utils.EventManager.getInstance():dispatch("GUILD_PVP_ENTER_ROOM_RESULT", errno);
		return;
	end

	data[4] = data[4] or {};
	data[5] = data[5] or {};
	data[6] = data[6] or {};
	data[7] = data[7] or {};

	M.data = {};
	M.data.roomid = lastEnterRoomID;
	lastEnterRoomID = nil;
	M.data.roomStatus = data[3] or 0;
	if enteredRoomRecord[M.data.roomid] then
		M.data.roomStatus = enteredRoomRecord[M.data.roomid];
	end
	
	local _, room_fight_status = GuildPVPGroupModule.GetStatus();
	if M.data.roomStatus == 1 and room_fight_status == 2 then
		M.data.roomStatus = 2;
	end

	M.data.guilds = {
		{id=data[4][1], inspire = data[4][3] or 0}, 
		{id=data[4][2], inspire = data[4][4] or 0},
	};
	
	M.data.self_inspire_count = data[8] or 0;

	local heros    = data[5] or {};
	local soldiers = data[6] or {};
	
--[[
	ERROR_LOG('heros')
	ERROR_LOG("", table.unpack(heros[1]))
	ERROR_LOG("", table.unpack(heros[2]))

	ERROR_LOG('soldiers')
	ERROR_LOG("", table.unpack(soldiers[1]))
	ERROR_LOG("", table.unpack(soldiers[2]))
--]]
	M.data.players = {{}, {}};
	for side = 1, 2 do
		local hs = heros[side] or {};
		local ss = soldiers[side] or {};

		for type = 1, 4 do
			table.insert(M.data.players[side], {
				type = type,
				pid  = hs[type] or 0,
			});
		end

		for _, v in ipairs(ss or {}) do
			table.insert(M.data.players[side], {
				type = 5,
				pid  = v
			});
		end
	end

	M.data.records = {};
	for _, v in ipairs(data[7] or {}) do
		appendFightRecord(M.data.records, v, M.data.guilds[1].id);
	end

	ERROR_LOG('GUILD_PVP_ROOM_RECORD_READY');
	utils.EventManager.getInstance():dispatch("GUILD_PVP_ROOM_RECORD_READY");
end);


utils.EventManager.getInstance():addListener("GUILD_PVP_GROUP_STATUS_CHANGE", function(event, battle_status, room_status)
	local finialStatus = nil;

	if battle_status == 1 then
		enteredRoomRecord = {};
	end

	if M.data and M.data.roomStatus and M.data.roomStatus < 3 then
		if room_status == 1 then
			finialStatus = 1
		elseif room_status == 2 then
			finialStatus = 2
			M.EnterRoom(M.data.roomid);
		elseif room_status >= 3 or room_status == 0 then
			finialStatus = 3
		end
	end

	if finialStatus and M.data.roomStatus and finialStatus > M.data.roomStatus then
		M.data.roomStatus = finialStatus;
		utils.EventManager.getInstance():dispatch("GUILD_PVP_ROOM_STATUS_CHANGE", M.data.roomStatus);
	end
end)

M.NOTIFY_GUILD_WAR_FIGHT_RECORD = 1116; -- 公会战公会战报
utils.EventManager.getInstance():addListener("server_notify_1116", function(_, _, data)
	print("--> NOTIFY_GUILD_WAR_FIGHT_RECORD");
	DEBUG.dump(data);
	if M.data and M.data.records then
		local roomid = data[1];
		if roomid ~= M.data.roomid then
			print("not entered roomid", roomid)
			return;
		end
		appendFightRecord(M.data.records, data[2], M.data.guilds[1].id);

		if M.data.roomStatus == 1 then
			M.data.roomStatus = 2;
		end
	end
end)

------------------
M.NOTIFY_GUILD_WAR_ROOM_INSPIRE_CHANGE = 1118;
utils.EventManager.getInstance():addListener("server_notify_1118", function(_, _, data)
	--ERROR_LOG("公会鼓舞--> NOTIFY_GUILD_WAR_ROOM_INSPIRE_CHANGE");
	DEBUG.dump(data);
	if M.data and M.data.guilds then
		for i = 1, 2 do
			if M.data.guilds[i].id == data[i] then
				M.data.guilds[i].inspire = data[2];
				utils.EventManager.getInstance():dispatch("GUILD_PVP_ROOM_INSPIRE_CHANGE");
				return;
			end
		end
	end
end)

------------------

M.C_GUILD_WAR_LEAVE_SUB_ROOM_REQUEST     = 3336 --离开活动子房间
M.C_GUILD_WAR_LEAVE_SUB_ROOM_RESPOND     = 3337 --

function M.LeaveRoom()
	M.data = nil;
	sendServerRequest(M.C_GUILD_WAR_LEAVE_SUB_ROOM_REQUEST)
end

------------------
function M.GetGuild(side)
	if M.data then
		if side then
			return M.data.guilds[side]
		else
			return M.data.guilds;
		end
	end
end

function M.GetPlayers(side)
	if M.data then
		if side then
			return M.data.players[side]
		else
			return M.data.players;
		end
	end
end

function M.GetRecord(idx)
	if M.data then
		if idx then
			return	M.data.records[idx] 
		else
			return  M.data.records;
		end
	end
end

function M.isInspired()
	return M.data and (M.data.self_inspire_count and M.data.self_inspire_count > 0 or nil) or false;
end

M.ROOM_STATUS_WAITING  = 0
M.ROOM_STATUS_INSPIRE  = 1
M.ROOM_STATUS_FIGHTING = 2
M.ROOM_STATUS_FINISHED = 3
M.ROOM_STATUS_EMPTY    = 4

function M.GetRoomStatus()
	if M.data and M.data.roomStatus then
		if M.data.roomStatus <= 0 then
			return M.ROOM_STATUS_WAITING;  -- not start
		elseif M.data.roomStatus == 1 then
			return M.ROOM_STATUS_INSPIRE; -- inspire stage
		elseif M.data.roomStatus == 2 then
			return M.ROOM_STATUS_FIGHTING; -- fight stage
		else
			return M.ROOM_STATUS_FINISHED
		end
	end
	return M.ROOM_STATUS_EMPTY;
end

local Queue = utils.Queue;

function M.InitFightRecord()
	M.logs = {
		index = 0,
		side = {
			[1] = {
				players = Queue.New(),
				score   = 0,
			},
			[2] = {
				players = Queue.New(),
				score   = 0,
			}
		},
	};

	for side = 1, 2 do
		local players = M.GetPlayers(side);
		for index, v in ipairs(players) do
			print('insert player', side, v.pid)
			M.logs.side[side].players:push({
				pid   = v.pid,
				index = index,
				winCount = 0,
			});
		end
	end
end

local scoreTable = {
	30,
	10,
	10,
	10
};

function M.NextFightRecordIsReady()
	if M.logs == nil or M.logs.side[1].players:isEmpty() or M.logs.side[2].players:isEmpty() then
		return false;
	end

	local next_record = M.logs.index + 1;
	local record = M.GetRecord(next_record);

	return record and true or false;
end

function M.NextFightRecord()
	local q1, q2 = M.logs.side[1].players, M.logs.side[2].players
	print("NextFightRecord", q1.head, q1.tail, q2.head, q2.tail);

	if M.logs.side[1].players:isEmpty() or M.logs.side[2].players:isEmpty() then
		M.data.roomStatus = 3;
		enteredRoomRecord[M.data.roomid] = 3;
		utils.EventManager.getInstance():dispatch("GUILD_PVP_ROOM_STATUS_CHANGE", M.data.roomStatus);
		return nil;
	end

	local next_record = M.logs.index + 1;

	local record = M.GetRecord(next_record);
	local players = {M.logs.side[1].players:front(), M.logs.side[2].players:front()};

	local info = {
		index = next_record;
		side = {
			[1] = {pid = players[1].pid},
			[2] = {pid = players[2].pid},
		}
	}

	if record == nil then
		return info;
	end

	print(string.format("%d -> %d, winner %d", players[1].pid, players[2].pid, record and record.winner or -1));

	info.fight  = record.fight;
	info.winner = record.winner;

	M.logs.index = next_record;
	local winner, loser = record.winner, (2-record.winner)+1;
	if M.logs.index <= 4 then
		info.side[1].exit = true;
		info.side[2].exit = true;
		M.logs.side[1].players:pop();
		M.logs.side[2].players:pop();

		M.logs.side[winner].score = M.logs.side[winner].score + scoreTable[M.logs.index];
		info.side[winner].score = M.logs.side[winner].score;
		info.side[winner].now_score = scoreTable[M.logs.index];
		info.side[winner].winCount = 1;
	else
		M.logs.side[loser].players:pop();
		info.side[loser].exit = true;
		players[winner].winCount = players[winner].winCount + 1;
		info.side[winner].winCount = players[winner].winCount;
		if players[winner].winCount >= 3 then
			info.side[winner].exit = true;
			M.logs.side[winner].players:pop();
		end

		if M.logs.side[1].players:isEmpty() or M.logs.side[2].players:isEmpty() then
			if not M.logs.side[1].players:isEmpty() then
				info.side[1].now_score = 50
				M.logs.side[1].score = M.logs.side[1].score + 50;
				info.side[1].score = M.logs.side[1].score;
			elseif not M.logs.side[2].players:isEmpty() then
				info.side[2].now_score = 50
				M.logs.side[2].score = M.logs.side[2].score + 50;
				info.side[2].score = M.logs.side[2].score;
			else
				M.logs.side[winner].score = M.logs.side[winner].score + 50;	
				info.side[winner].score = M.logs.side[winner].score;
				info.side[winner].now_score = 50
			end
		end
	end
	return info;
end

function M.GetWinner()
	print("--> GetWinner");
	if M.logs and M.logs.index > 0 then
		print("score", M.logs.side[1].score, M.logs.side[2].score);
		if M.logs.side[1].score >= M.logs.side[2].score then
			return M.GetGuild(1),1;
		else
			return M.GetGuild(2),2;
		end
	else
		print("M.logs == nil", M.logs, M.logs.index);
	end
end

M.FIGHT_QUERY_AUTO_FIGHT_RECORD_REQUEST = 16966
M.FIGHT_QUERY_AUTO_FIGHT_RECORD_RESPOND = 16967

function M.WatchFightReplay(fight_id)
	sendServerRequest(M.FIGHT_QUERY_AUTO_FIGHT_RECORD_REQUEST, {nil, fight_id})
end

utils.EventManager.getInstance():addListener("server_respond_16967", function(event, cmd, data)
	local sn = data[1];
    local result = data[2];
    if result ~= 0 then
        print("查看战斗录像失败", result)
        return;
    end
    local fight_data = data[3];
	print("~~~战斗数据", sprinttb(data));
	local fight_data = ProtobufDecode(fight_data, "com.agame.protocol.FightData")
	--ERROR_LOG("fight_data------->>",sprinttb(fight_data))
    SceneStack.Push('battle', 'view/battle.lua', {fight_id = nil,fight_data = fight_data,  worldBoss = true})
end)
return M;