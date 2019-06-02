local EventManager = require 'utils.EventManager';
local NetworkService = require "utils.NetworkService";
local Property = require "utils.Property"

local players = {};
local curPlayerID = nil;
local ChangeNameSn = {}
local ChangeIconAndHonorSn = {}
local queryPlayerCallback = {}

local function getPlayer(pid,callback,init)
	if not pid or pid == 0 then
		pid = curPlayerID
	end

	if players[pid] == nil then
		if queryPlayerCallback[pid] ~= nil then 
			table.insert(queryPlayerCallback[pid], callback)
			return;
		end

		local sn = NetworkService.Send(5, {nil, pid});
		queryPlayerCallback[pid] = {}
		table.insert(queryPlayerCallback[pid], callback);
		return nil;
	else
		if init and not queryPlayerCallback[pid] then
			NetworkService.Send(5, {nil, pid});
			queryPlayerCallback[pid] = {}
			table.insert(queryPlayerCallback[pid], callback);
		elseif callback ~= nil then
			callback(players[pid]);
		end
		return players[pid];
	end
end

local PlayerList_temp = {}
local function GetPlayerList(pids,callback)
	if pids and #pids > 0 then
		for i = 1,#pids do
			if players[pids[i]] then
				PlayerList_temp[#PlayerList_temp+1] = players[pids[i]]
				if #pids == #PlayerList_temp then
					callback(PlayerList_temp)
					PlayerList_temp = {}
				end
			else
				getPlayer(pids[i],function (player)
					PlayerList_temp[#PlayerList_temp+1] = player
					if #pids == #PlayerList_temp then
						callback(PlayerList_temp)
						PlayerList_temp = {}
					end
				end)
			end
		end
	else
		ERROR_LOG("查询玩家数据错误->",pids)
	end
end
local function GetSelfID()
	return curPlayerID
end

local function IsDataExist(pid)
	return players[pid] and players[pid] or nil;
end

local function updatePlayer(data)
	local ret = data[2];
	if ret ~= 0 then
		print("query player failed")
		DispatchEvent("QUERY_PLAYER_FAILED")
		return;
	else
		-- print("query playerui  success ", data[3])
	end

	local id = math.floor(data[3]);

	local name       = utils.SGKTools.matchingName(data[4]);
	local real_name = data[4]
	local create_time= data[5];
	local exp        = data[6];
	local level      = data[7];
	local head       = data[8] or 11000;
	if head == 0 then
		head = 11000
	end
	local honor      = data[9] or 0;
    local loginTime  = data[10] or 0
    local starPoint =data[11] or 0;--回忆录星级
    local floor =data[12] or 0;--爬塔层数

	local vip		= 0;
	local player = players[id];
	if player == nil then
		player = {};
		players[id] = player;
	end
	player.update_time = os.time();

	player.id   = id;
	player.name = utils.SGKTools.matchingName(name);
	player.real_name = create_time
	player.exp = exp;
	player.level = level;
	player.head = head;
	player.honor = honor;
	player.vip = vip;
	player.create_time = create_time;
    player.loginTime = loginTime
    player.starPoint = starPoint
    player.floor = floor
	DispatchEvent("PLAYER_INFO_CHANGE", id);

	return player;
end

local function GetCreateTime (pid)
	local pid = pid or curPlayerID;
	local player = players[pid];
	if player then
		local _t = os.date("*t", player.create_time)
		return player.create_time - _t.sec - (_t.min * 60) - (_t.hour * 3600)
	end
end

local function updatePlayerLevel(id,level)
	local player = players[id];
	if player ~= nil then
		player.level = level
	end
end
--查询角色
EventManager.getInstance():addListener("server_respond_6", function(event, cmd, data)
	--print("-----server_respond_6:",sprinttb(data));
	local player = updatePlayer(data);

	if player ~= nil and queryPlayerCallback[player.id] then
		local list = queryPlayerCallback[player.id];
		queryPlayerCallback[player.id] = nil;
		for _, v in ipairs(list) do
			v(player);
		end
	end
end);

--创建角色时信息返回
EventManager.getInstance():addListener("server_respond_8", function(event, cmd, data)
	-- print("-----server_respond_8:",sprinttb(data));
	if data[2] == 52 then
		return print("=================the name can't been used");
	end
	curPlayerID = math.floor(data[3]);
	updatePlayer(data);

	DispatchEvent("LOGIN_SUCCESS", curPlayerID);
end);

local function ChangeName(name)
    coroutine.resume(coroutine.create(function()
        local _data = utils.NetworkService.SyncRequest(430, {nil, 790001})
        if _data[2] == 0 then
            for i,v in ipairs(_data[3]) do
                local _count = module.ItemModule.GetItemCount(v[2])
                if _count >= v[3] then
                    local _name = utils.NetworkService.SyncRequest(51, {nil, name, 0})
                end
            end
        end
    end))
end

local function ChangeIcon(icon)
	local sn = NetworkService.Send(51,{nil,"",icon})
	ChangeIconAndHonorSn[sn] = icon
end

local function ChangeHonor(id)
	local player_self = players[curPlayerID];
	local sn=NetworkService.Send(51,{nil,player_self.real_name,player_self.head,id})
	ChangeIconAndHonorSn[sn] = id
end

EventManager.getInstance():addListener("server_respond_52", function(event, cmd, data)
	local sn = data[1]
	local err = data[2]

	if err == 0 then
		--NetworkService.Send(5, {nil, curPlayerID});--改为在server_notify_1更改
		DispatchEvent("LOCAL_PLAYERMODULE_NAMEORICON_CHANGE_OK", ChangeIconAndHonorSn[sn]);
	elseif err == 281 then
		DispatchEvent("LOCAL_PLAYERMODULE_NAMEORICON_CHANGE_ERROR");
	else
		print("更换头像or名字失败")
		DispatchEvent("LOCAL_PLAYERMODULE_NAMEORICON_CHANGE_ERROR");
	end
end)

local login_info = nil
local function Login(account, token, host, port, sid)
	-- if login_info == nil then
		login_info = {
			account = account,
			token = token,
			host = host,
			port = port,
			sid = sid,
		}

		print('playerModule:Login', host, port)

		NetworkService.Connect(host, port);
	-- end
end


local connect_co = nil;

local function DoConnect(host, port)
	connect_co = coroutine.running()
	NetworkService.Connect(login_info.host, login_info.port);
	return coroutine.yield();
end

local reconnectionSn = nil;
EventManager.getInstance():addListener("server_respond_connected", function(event, cmd, data)
	if login_info then
		if connect_co then coroutine.resume(connect_co, true) end
		local client_info = "46001|73213123|1.0|Xiaomi MI 6|WIFI|73213123|0";
		local sn = NetworkService.Send(1, {0, login_info.account or "", login_info.token or 'xxxxxxxxxxxxxxxxxxx', 5, login_info.sid, client_info});
		if reconnectionSn then reconnectionSn = sn; end
	end
end);

local reconnecting_game_object = nil;

local function TryReconnectToServer(show_tips_after_retry_count)
	if connect_co then coroutine.resume(connect_co, false) end

	if not login_info then
		return;
	end

	if not curPlayerID then
		return
	end

	if connect_co then
		return
	end

	assert(coroutine.resume(coroutine.create(function()
		local sleep_time = {1, 1, 1, 3, 3, 3, 3, 5, 5, 5}
		for i = 1, 10 do
			print('reconnect', i, 'times')
			if DoConnect(login_info.host, login_info.port) then
				connect_co = nil;
				return;
			end

			if i > show_tips_after_retry_count then
				if not reconnecting_game_object then
					local prefab = SGK.ResourcesManager.Load("prefabs/common/Reconnecting.prefab");
					reconnecting_game_object = CS.UnityEngine.GameObject.Instantiate(prefab,UnityEngine.GameObject.FindWithTag("UITopRoot").gameObject.transform)
				end
				-- showDlgError(nil,"正在重新连接服务器")
			end
			Sleep(sleep_time[i] or 3, true);
		end

		connect_co = nil;

		if reconnecting_game_object then
			UnityEngine.GameObject.Destroy(reconnecting_game_object);
			reconnecting_game_object = nil;
		end

		showDlg(nil,"连接服务器失败，请稍后重试",function()
			TryReconnectToServer(0)
		end,function()
			SceneService:Reload();
		end,"重新连接","返回登陆")
	end)));
end

EventManager.getInstance():addListener("server_respond_closed", function()
	print("server_respond_closed")
	reconnectionSn = 0
	TryReconnectToServer(3)
end)

EventManager.getInstance():addListener("server_respond_timeout", function()
	print("server_respond_timeout")
	reconnectionSn = 0
	TryReconnectToServer(0)
end)

--判断是否创建角色
EventManager.getInstance():addListener("server_respond_2", function(event, cmd, data)
	--print("-----server_respond_2:",sprinttb(data));
	local err = data[2];
	if err == 0 then
		local pid = math.floor(data[3]);
		curPlayerID = pid;
		NetworkService.Send(5, {nil, pid});
        if reconnectionSn == data[1] then
            DispatchEvent("LOCAL_RECONNECTION", curPlayerID);
		end
		module.HeroModule.GetManager():GetAll(true);
		DispatchEvent("LOGIN_SUCCESS", curPlayerID);
	elseif err == 3 then
		local pid = math.floor(data[3]);
		curPlayerID = pid;
		return DispatchEvent("NEED_TO_CHOOSE_ROLE");
	else
		DispatchEvent("LOGIN_FAILED");
	end

	reconnectionSn = nil;

	if reconnecting_game_object then
		UnityEngine.GameObject.Destroy(reconnecting_game_object);
		reconnecting_game_object = nil;
	end
end);

EventManager.getInstance():addListener("server_respond_4", function(event, cmd, data)
	login_info = nil;
	curPlayerID = nil;
	print("kick out")

	SceneService:Reload();
end);

EventManager.getInstance():addListener("server_notify_1", function(event, cmd, data)
	local name = data[1];
	local head = data[2];
	local honor = data[3]
	local starPoint= data[4]
	-- ERROR_LOG("server_notify_1",sprinttb(data))
	local player = players[curPlayerID];
	if player then
	 	if player.head ~= head or player.name ~= name or player.honor ~= honor or player.starPoint ~= starPoint then
	 		NetworkService.Send(18046, {nil,{4,curPlayerID}})--向地图中其他人发送玩家名字、头像、头衔改变
	 		if player.head ~= head then
	 			--[[--玩家头像变了，获取形象配置
	 			local _headCfg=utils.PlayerInfoHelper.GetHeadCfg(head)
	 			if _headCfg and _headCfg.binding==1 then--头像和形象绑定
	 				local _hero=module.HeroModule.GetManager():Get(_headCfg.id)
	 				if _hero then
	 					local _showMode=_hero.showMode--英雄当前穿戴的时装--module.HeroHelper.GetModeCfg(_hero.id)
	 					local _currentSuitCfg=module.HeroHelper.GetCfgByShowMode(_hero.id,_showMode)
	 					local _suitId=_headCfg.hero
	 					if _suitId~=1 and _suitId~=0 then--该形象拥有时装
	 						if _suitId~= _currentSuitCfg.suitId then
	 							if _hero.items[_suitId] then
			 						module.HeroModule.ChangeSpecialStatus(_hero.uuid,_suitId,true)
			 					end
		 					end
	 					else--_suitId==1--脱
	 						if _currentSuitCfg.suitId~=0 then
								module.HeroModule.ChangeSpecialStatus(_hero.uuid,_currentSuitCfg.suitId,false)
	 						end
	 					end
	 				end
	 				-- utils.PlayerInfoHelper.ChangeActorShow(head,curPlayerID)
			 	end
			 	--3-11版本专用
			 	utils.PlayerInfoHelper.ChangeActorShow(head,curPlayerID)
			 	--]]
	 		end
	 	end
	 	player.name = utils.SGKTools.matchingName(name);
		player.head = head;
		player.honor = honor
		player.starPoint = starPoint

		DispatchEvent("PLAYER_INFO_CHANGE", player.id);
	 end
end);

EventManager.getInstance():addListener("server_notify_51", function(event, cmd, data)
	local type, sec = data[1], data[2];

	local str = string.format("防沉迷提醒，已游戏%d小时%d分钟", math.floor(sec/3600), math.floor((sec%3600)/60));
	print(str);

	EventManager.getInstance():dispatch("CHAT_MESSAGE", {0, str});
end);


local fight_data = {}
local fight_data_querying = {}
local function getPlayerFightData(pid,force,funciton)
	pid = (pid == nil or pid == 0) and GetSelfID() or pid;
	if fight_data[pid] and not force then
		if funciton ~= nil then
			funciton();
		end
		local Time = require "module.Time"
		if fight_data[pid].Refresh then
			fight_data[pid].Refresh = false
			NetworkService.Send(27, {nil, pid});
			fight_data_querying[pid] = fight_data_querying[pid] or {}
		end
		return fight_data[pid]
	end

	if fight_data_querying[pid] then
		if funciton then table.insert(fight_data_querying[pid], funciton); end
		return nil;
	end

	fight_data_querying[pid] = {}
	if funciton then table.insert(fight_data_querying[pid], funciton); end

	NetworkService.Send(27, {nil, pid});

	return fight_data[pid];
end
local function SetPlayerFightDataRefresh(pid)
	if fight_data[pid] then
		fight_data[pid].Refresh = true
	end
end
local function GetCombat(pid, func)
	getPlayerFightData(pid, false, func)
end

EventManager.getInstance():addListener("server_respond_32", function(event, cmd, data)
	local err = data[2];
	if err == 0 then
		print("formation info change");
		fight_data[GetSelfID()] = nil
		module.TeamModule.SyncTeamData(110)
	end
end);



EventManager.getInstance():addListener("server_respond_28", function(event, cmd, data)
	if data[2] ~= 0 then
		return
	end
	local pid, code = data[3], data[4];

	local funcs = fight_data_querying[pid]
	fight_data_querying[pid] = nil;

	local info = ProtobufDecode(code, "com.agame.protocol.FightPlayer")

	fight_data[pid] = {
		pid = pid,
		name = utils.SGKTools.matchingName(info.name),
		level = info.level,
		heros = {},
	}

	local capacity = 0;
	for k, v in ipairs(info.roles) do
		fight_data[pid].heros[k] = {
			id = v.id,
			level = v.level,
			mode = v.mode,
			skills = v.skills,
			equips = v.equips,
			uuid = v.uuid,
			star = v.grow_star,
            stage = v.grow_stage,
            pos = v.pos,
		}

		local t = {}
		for _, vv in ipairs(v.propertys) do
			t[vv.type] = vv.value
		end
		local Time = require "module.Time"
		fight_data[pid].heros[k].property = Property(t);
		capacity = capacity + fight_data[pid].heros[k].property.capacity;
	end
	fight_data[pid].capacity = capacity;
	
	if funcs then
		for _, func in ipairs(funcs) do
			func(fight_data[pid]);
		end
	end
	DispatchEvent("PLAYER_FIGHT_INFO_CHANGE", pid);
end);


--module "playerModule"

local showSourceTab = nil
local function GetShowSource()
	if not showSourceTab then
		showSourceTab = {}
		DATABASE.ForEach("wanjia_source", function(row)
			table.insert(showSourceTab, row)
		end)
	end
	return showSourceTab
end

local IsFirst_start = true
local function GetFirst_start(status)
	if status ~= nil then
		IsFirst_start = status
	end
	return IsFirst_start
end

return {
	Login = Login,
	Get = getPlayer,
	GetSelfID = GetSelfID,
	ChangeName = ChangeName,
	ChangeIcon = ChangeIcon,
	IsDataExist = IsDataExist,
	ChangeHonor = ChangeHonor,
	GetFightData = getPlayerFightData,
	GetFirst_start = GetFirst_start,
	GetCombat = GetCombat,
	GetShowSource = GetShowSource,
	updatePlayerLevel = updatePlayerLevel,
	GetCreateTime = GetCreateTime,
	SetPlayerFightDataRefresh = SetPlayerFightDataRefresh,
	GetPlayerList = GetPlayerList,
};
