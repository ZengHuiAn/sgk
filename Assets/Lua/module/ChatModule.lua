local EventManager = require 'utils.EventManager';
local NetworkService = require "utils.NetworkService";
local playerModule = require "module.playerModule"

local ModuleDataArr = {}
local NewChatData = {}
local ChatDataTeam = {}
local ReadChatid = {}
local SnArr = {}
local AtMyMsg = {} ---@我的消息
local UserDefault = require "utils.UserDefault";
local ChatData = UserDefault.Load("ChatData",true,1);
local System_Set_data=UserDefault.Load("System_Set_data");
local function GetReadChatid(id)
	return ReadChatid[id]
end
local function SetReadChatid(id,type)
	ReadChatid[id] = type
end
local function PrivateShowRed()--私聊页签是否未读 false未读 true已读
	--ERROR_LOG("ReadChatid"..sprinttb(ReadChatid))
	for k,v in pairs(ReadChatid) do
		if v == false then
			return v
		end
	end
	return true
end
local TeamChatKeyword = {"催促","快点吧","你挂自动","给自己奶","给你比心","干的漂亮","扎心了",""}
local function TeamChatKeywordList(idx,desc)
	if idx and desc then
		TeamChatKeyword[idx] = desc
		DispatchEvent("Chat_TeamChatKeyword_CHANGE")
	end
	return TeamChatKeyword
end

local PLayerStatus = {}
local function GetPLayerStatus(channel)
	return PLayerStatus[channel]
end
local function SetPLayerStatus(channel,status)
	PLayerStatus[channel] = status
end

local function GetShowChatRed(privateRed)
	for k,v in pairs(PLayerStatus) do
		if v ~= nil then
			return true
		end
	end
	if privateRed == nil and PrivateShowRed() == false then
		return true
	end
	return false
end

local function Set(data)
	if data then
	if not ModuleDataArr[data[4]] then
		ModuleDataArr[data[4]] = {}
	end
		local temp = {
			fromid = data[3][1],--来源角色id
			fromname = utils.SGKTools.matchingName(data[3][2]),--来源角色名字
			source = data[3][3] or 0,--0来自玩家or系统1来自npc
			channel = data[4],--频道0系统1世界6私聊3工会7队伍8被加好友消息10组队消息
			message = data[5],--消息内容
			ChatIdx = data[6] and data[6] or (playerModule.Get().id ~= data[3][1] and 0 or 1),
			time = data[7] or module.Time.now(),
			status = 1,--默认未读
			PlayerData = nil,--玩家挂件
		}
		if not temp.fromname then
			ERROR_LOG("数据缺少->",sprinttb(data))
			return
		end
		if data[4] == 6 or data[4] == 8 then--私聊或者加好友通知
			if not ModuleDataArr[data[4]][data[3][1]] then
				ModuleDataArr[data[4]][data[3][1]] = {}
			end
			if data[4] == 6 then
				temp.idx = #ModuleDataArr[data[4]] [data[3][1]] + 1
				ModuleDataArr[data[4]] [data[3][1]] [#ModuleDataArr[data[4]] [data[3][1]] + 1] = temp
				if temp.ChatIdx == 0 then
					SetReadChatid(data[3][1],false)
					--DispatchEvent("Chat_RedDot_CHANGE",{id = data[3][1]})
				else
					--自己发给自己的消息默认已读
					temp.status = 2
				end
			elseif data[4] == 8 then
				local TipCfg = require "config.TipConfig"
				temp.message = TipCfg.GetAssistDescConfig(61026).info--temp.message.."添加你为好友"
				temp.MailId = data[2333]
				temp.status = data[6666]--是否已读1未读2已读
				temp.id = data[1]
				temp.idx = #ModuleDataArr[temp.channel] [temp.fromid] + 1;
				ModuleDataArr[temp.channel] [temp.fromid] [#ModuleDataArr[temp.channel] [temp.fromid] + 1] = temp
			end
		else
			if temp.fromid ~= 0 then
				if playerModule.IsDataExist(temp.fromid) then
					local honor = playerModule.IsDataExist(temp.fromid).honor
					if honor == 9999 then
						utils.SGKTools.showScrollingMarquee("<color=#ff0000ff>[管理员]"..temp.fromname..":"..temp.message.."</color>")--跑马灯
					end
				end

			end
			temp.idx = #ModuleDataArr[data[4]] + 1;
			ModuleDataArr[data[4]][#ModuleDataArr[data[4]] + 1] = temp
			if not System_Set_data.FiltrationChat then
				System_Set_data.FiltrationChat = {[0] = true,[1] = true,[6] = true,[3] = true,[7] = true,[10] = true,[100] = true,[-1] = true}
			end
			if System_Set_data.FiltrationChat[temp.channel] then
				NewChatData[#NewChatData + 1] = temp
				if #NewChatData > 2 then
					table.remove(NewChatData,1)
				end
			end
		end


		if not ChatData.data then
			ChatData.data = {}
		end
		if temp.channel == 6 or temp.channel == 8 then
			ChatData.data[temp.channel] = ModuleDataArr[temp.channel]
			UserDefault.Save(1)
		end
		------------------------------------
		ChatDataTeam[#ChatDataTeam + 1] = temp
		if #ChatDataTeam > 1000 then
			table.remove(ChatDataTeam,1)
		end
		if #ChatDataTeam > 20 then
			table.remove(ChatDataTeam,1)
		end
		------------------------------------
		if string.find(temp.message, "@"..playerModule.Get().name) then
			SetPLayerStatus(temp.channel,temp)
			AtMyMsg[#AtMyMsg + 1] = temp
			DispatchEvent("Chat_ATMYMSG_CHANGE", {channel = data[4]});
		end
		DispatchEvent("Chat_INFO_CHANGE",temp)--{channel = data[4]});
	end
end

local function ChatUpdate(type_id, idx,data)
	if type_id == 6 then
		ModuleDataArr[type_id][idx[1]][idx[2]].PlayerData = data
	else
		if ModuleDataArr[type_id] and ModuleDataArr[type_id][idx[1]] then
			ModuleDataArr[type_id][idx[1]].PlayerData = data
			-- for k, v in pairs(ModuleDataArr[type_id]) do
			-- 	if k == idx then
			-- 		ModuleDataArr[type_id][k].PlayerData = data
			-- 	end
			-- end
		end
	end
end
local function LoadOldData()
	if ChatData.data then
		for k,v in pairs(ChatData.data) do
		    ModuleDataArr[k] = v
		end
	    --ERROR_LOG(sprinttb(ModuleDataArr[6]))
	end
end
local function Get(type_id, idx)
	ModuleDataArr = ModuleDataArr or {}
	local list = ModuleDataArr[type_id];
	if not idx then
		if list and type_id == 8 then
			for k,v in pairs(list) do
				table.sort(v,function(a,b)
					return a.time < b.time
				end)
			end
		end
		return list
	end
	list = nil
	if ModuleDataArr[type_id] then
		for k, v in pairs(ModuleDataArr[type_id]) do
			if k == idx then
				list = v;
			end
		end
	end
	return list
end

local function Reset_channel(channel,pid)
	ModuleDataArr = ModuleDataArr or {}
	if ModuleDataArr[channel] and ModuleDataArr[channel] [pid] then
		ModuleDataArr[channel] [pid] = {}
	end
end
local function GetNewChat(data)
	return NewChatData
end
local function GetChatDataTeam()
	return ChatDataTeam
end
local function GetManager(type_id, idx)
	return Get(type_id, idx)
end
local function GetAtMyMsg()
	return AtMyMsg
end
--local privateChatData = {}
local function SetManager(data,ChatIdx,channel)
	--格式化邮件发过来的私聊type6
	if data then
		if channel == 3 then
			local FriendData = module.FriendModule.GetManager(nil,data.fromid)
			if FriendData and FriendData.type == 2 then
				return
			end
			local source = data.source or 0
			Set({nil,nil,{data.fromid,data.fromname,source},6,data.title,ChatIdx,data.time})
			-- if ChatIdx == 0 then
			-- 	if not privateChatData[data.fromid] then
			-- 		privateChatData[data.fromid] = 0
			-- 	end
			-- 	privateChatData[data.fromid] = privateChatData[data.fromid] + 1
			-- end
			--fromid邮件发过来为对方id，我自己的为自己id
			--chatId始终为对方id
		elseif channel == 8 then
			-- if ModuleDataArr[8] and ModuleDataArr[8] [data.fromid] then --and ModuleDataArr[8] [data.fromid][2333] then
			-- 	NetworkService.Send(5007,{nil,{data.id}})--如果有相同玩家发来的的消息，删除后面的消息
			-- else
				NetworkService.Send(5007,{nil,{data.id}})--改为本地存储，所以删除邮箱中的玩家加好友通知
				local PlayerInfoHelper = require "utils.PlayerInfoHelper"
				local pid = module.playerModule.Get().id
				PlayerInfoHelper.GetPlayerAddData(pid, 7, function(addData)
					if not addData.RefuseFriend then
					--是否设置屏蔽接收加好友的消息
						local list = {data.id,nil,{data.fromid,data.fromname},8,data.title,ChatIdx,data.time}
						list[2333] = data.id
						list[6666] = data.status
						Set(list)
					end
				end)
			--end
		end
	end
end
local function SetPrivateChatData(id,type)--已读
	if ModuleDataArr[type] and ModuleDataArr[type][id] then
		for i = 1,#ModuleDataArr[type][id] do
			if ModuleDataArr[type][id][i].status and ModuleDataArr[type][id][i].status == 1 then
				ModuleDataArr[type][id][i].status = 2
			end
		end
		ChatData.data[type] = ModuleDataArr[type]
	    UserDefault.Save(1)
	    --DispatchEvent("Chat_INFO_CHANGE",ModuleDataArr[type][id][#ModuleDataArr[type][id]])
	    DispatchEvent("PrivateChatData_CHANGE",ModuleDataArr[type][id][#ModuleDataArr[type][id]])
	end
end
local function GetPrivateChatData(id)--获取好友发送过来的新消息数量
	local a,b = 0,0
	if ModuleDataArr[6] and ModuleDataArr[6][id] then
		for i = 1,#ModuleDataArr[6][id] do
			if ModuleDataArr[6][id][i].status and ModuleDataArr[6][id][i].status == 1 then
				a = a + 1
			end
		end
	end
	if ModuleDataArr[8] and ModuleDataArr[8][id] then
		for i = 1,#ModuleDataArr[8][id] do
			if ModuleDataArr[8][id][i].status and ModuleDataArr[8][id][i].status == 1 then
				b = b + 1
			end
		end
	end
	return (a+b),a,b
end
local function SetTeamChat(pid,name,desc)
	--小队聊天
	if pid and name and desc then
		Set({nil,nil,{pid,name},7,desc,nil})
	end
end
local ChatMessageTime = {}
local function SetChatMessageTime(type,time)
	ChatMessageTime[type] = time
end
local function GetChatMessageTime(type)
	if type then
		return (ChatMessageTime[type] or 0)
	end
	return ChatMessageTime
end

local last_map_chat_channel_id = nil;
local function EnterMapChannel(map_id)
	local MapConfig = require "config.MapConfig"
	local mapCfg = MapConfig.GetMapConf(map_id);
	local next_map_chat_channel_id = mapCfg and mapCfg.chat;

	if next_map_chat_channel_id and next_map_chat_channel_id ~= 0 and (next_map_chat_channel_id < 100 or next_map_chat_channel_id > 200) then
		next_map_chat_channel_id = nil;
		ERROR_LOG("chat of all_map error", map_id, next_map_chat_channel_id)
	end

	if next_map_chat_channel_id == last_map_chat_channel_id then
		return;
	end

	if last_map_chat_channel_id then
		print("leave chat channel ", last_map_chat_channel_id);
		NetworkService.Send(2003,{nil,last_map_chat_channel_id});
	end

	if next_map_chat_channel_id then
		print("enter chat channel ", next_map_chat_channel_id);
		NetworkService.Send(2001,{nil,next_map_chat_channel_id});
	end

	last_map_chat_channel_id = next_map_chat_channel_id;
end

local function ChatMessageRequest(type,desc)
	--0系统1世界2私聊3工会
	if type == 2 then
		return
	end

	if type == 100 then
		type = last_map_chat_channel_id;
	end

	if type == nil then
		return;
	end

	local Time = require "module.Time"
	local cd =  math.floor(Time.now()  - (ChatMessageTime[type] or 0))
	if cd < 10 then
		showDlgError(nil,"您说话太快，请在"..10-cd.."秒后发送")
		return
	else
		ChatMessageTime[type] = Time.now()
		NetworkService.Send(2005,{nil,type,desc});--聊天发送
	end
end

EventManager.getInstance():addListener("CHAT_MESSAGE",function(event,data)
	--ChatMessageRequest(data[1],data[2])
	Set({nil,nil,{11001,"系统"},data[1],data[2],nil})
end)
EventManager.getInstance():addListener("server_notify_40", function(event, cmd, data)
	--跑马灯
	--ERROR_LOG("server_notify_40",sprinttb(data))
	--showDlgError(nil,"")
	-- if data then return end

	if data[1] == 2 then--创建公会
		utils.SGKTools.showScrollingMarquee(SGK.Localize:getInstance():getValue("juntuan_paomadeng_01",data[2],data[3]))
	elseif data[1] == 3 then--通关副本
		--ERROR_LOG(sprinttb(data))
		local pids = data[2]
		local gid = data[3]
		module.playerModule.GetPlayerList(pids,function (players)
			local desc = ""
			for i = 1,#players do
				--if module.playerModule.IsDataExist(pids[i]) then
					local player=players[i]
					desc = desc..player.name
					if i < #players then
						desc = desc.."、"
					end
				--end
			end
			local ActivityTeamlist = require "config.activityConfig"
			--desc = "<color=#FFD700>"..desc.."</color>神威浩荡，攻破副本<color=#EE0000>"..ActivityTeamlist.GetActivity(gid).name.."</color>"
			utils.SGKTools.showScrollingMarquee(SGK.Localize:getInstance():getValue("fuben_paomadeng_01",desc,ActivityTeamlist.GetActivity(gid).name))
		end)
	elseif data[1] == 4 then--占卜获得角色
		local cfg = module.HeroModule.GetConfig(data[3])
        if cfg then
            utils.SGKTools.showScrollingMarquee(SGK.Localize:getInstance():getValue("zhanbu_paomadeng_01",data[2],cfg.name))
        end
	elseif data[1] == 5 then--碎片合成角色
        local cfg = module.HeroModule.GetConfig(data[3])
        if cfg then
		    utils.SGKTools.showScrollingMarquee(SGK.Localize:getInstance():getValue("hecheng_paomadeng_01",data[2],cfg.name))
        end
	elseif data[1] == 6 then--角色获得称号--需要接口提供itemid查询至英雄名字和称号名字
		--local cfg = module.HeroModule.GetInfoConfig()
		--local name = module.titleModule.GetTitleCfgByItem(data[4]).name
		--utils.SGKTools.showScrollingMarquee(SGK.Localize:getInstance():getValue("chenghao_paomadeng_01",data[2],cfg[data[3]].name,name))
		utils.SGKTools.showScrollingMarquee(SGK.Localize:getInstance():getValue("chenghao_paomadeng_01",data[2],data[3],data[4]))
	elseif data[1] == 7 then--与角色好感满--暂无跑马灯
		local cfg = module.HeroModule.GetInfoConfig()
		utils.SGKTools.showScrollingMarquee(SGK.Localize:getInstance():getValue("haogan_paomadeng_01",cfg[data[2]].name,data[3]))
	elseif data[1] == 8 then--角色星级提升
        local cfg = module.HeroModule.GetConfig(data[3])
        if cfg then
		    utils.SGKTools.showScrollingMarquee(SGK.Localize:getInstance():getValue("xingji_paomadeng_01",data[2],cfg.name,data[4]))
        end
	elseif data[1] == 9 then--角色突破
		local cfg = module.HeroModule.GetConfig(data[3])
		local HeroEvo = require "hero.HeroEvo"
		local StageColor = {"绿","蓝","紫","橙","红"}
		local NowStageHeroConf = HeroEvo.GetConfig(data[3])[data[4]]
		utils.SGKTools.showScrollingMarquee(SGK.Localize:getInstance():getValue("tupo_paomadeng_01",data[2],cfg.name,StageColor[NowStageHeroConf.quality].."色"))
	elseif data[1] == 10 then--盗具充能
        local cfg = module.HeroModule.GetConfig(data[3])
        if cfg then
		    utils.SGKTools.showScrollingMarquee(SGK.Localize:getInstance():getValue("daoju_paomadeng_01",data[2],cfg.name,data[4]))
        end
	elseif data[1] == 11 then--获得高级守护
		local _equipCfg=equipmentConfig.GetConfig(data[3])
		local Name = "<color="..ItemHelper.QualityTextColor(_equipCfg.quality)..">".._equipCfg.name.."</color>"
		utils.SGKTools.showScrollingMarquee(SGK.Localize:getInstance():getValue("shouhu_paomadeng_01",data[2],Name))
	elseif data[1] == 12 then--获得高级芯片
		local _equipCfg=equipmentConfig.GetConfig(data[3])
		local Name = "<color="..ItemHelper.QualityTextColor(_equipCfg.quality)..">".._equipCfg.name.."</color>"
		utils.SGKTools.showScrollingMarquee(SGK.Localize:getInstance():getValue("xinpian_paomadeng_01",data[2],Name))
	elseif data[1] == 13 then--芯片进阶满级
		local _equipCfg=equipmentConfig.GetConfig(data[3])
		local desc = string.sub(tostring(_equipCfg.id), -3, -3)
		utils.SGKTools.showScrollingMarquee(SGK.Localize:getInstance():getValue("qianghua_paomadeng_01",data[2],_equipCfg.name,desc))
	elseif data[1] == 14 then--竞技场前十
		utils.SGKTools.showScrollingMarquee(SGK.Localize:getInstance():getValue("jingjichang_paomadeng_01",data[2],data[3],data[4]))
	elseif data[1] == 15 then--每日抽奖
		local ItemHelper = require "utils.ItemHelper"
		local item = ItemHelper.Get(data[4], data[5]);
		local itemName = "<color="..ItemHelper.QualityTextColor(item.quality)..">"..item.name.."</color>"
		local lucky_draw = require "config.lucky_draw"
		local cfgTab = lucky_draw.GetDailyDrawConfig(data[3])
		utils.SGKTools.showScrollingMarquee(SGK.Localize:getInstance():getValue("choujiang_paomadeng_01",data[2],cfgTab[1].lucky_name,itemName))
	elseif data[1] == 16 then--BOSS最后一击
		local cfg = module.worldBossModule.GetBossCfg(data[3]);
		local name = cfg and cfg.describe or data[3];
		utils.SGKTools.showScrollingMarquee(SGK.Localize:getInstance():getValue("boss_01",data[2],name))
	elseif data[1] == 17 then--BOSS逃跑
		local cfg = module.worldBossModule.GetBossCfg(data[2]);
		local name = cfg and cfg.describe or data[3];
		utils.SGKTools.showScrollingMarquee(SGK.Localize:getInstance():getValue("boss_02", name))
	elseif data[1] == 18 then--BOSS出现
		-- local name = module.worldBossModule.GetBossCfg(data[3]).describe
		utils.SGKTools.showScrollingMarquee(SGK.Localize:getInstance():getValue("boss_03",data[2],data[3]))
	end
end)
local function SystemChat(pid,type,id,value,id2)
	local ItemData = utils.ItemHelper.Get(type,id)
	local cfg2 = id2 and module.ItemModule.GetConfig(id2)
    local color = "<color="..utils.ItemHelper.QualityTextColor(ItemData.quality)..">"
    if pid == module.playerModule.Get().id then
    	local name = module.playerModule.Get().name
        module.ChatModule.SetData({nil,nil,{pid,name},0,(cfg2 and "打开"..cfg2.name or "").."获得"..color..ItemData.name.."x"..value.."</color>",0})
	else
		module.playerModule.Get(pid,function( ... )
			local name = module.playerModule.IsDataExist(pid).name
	        module.ChatModule.SetData({nil,nil,{pid,name},0,name..(cfg2 and "打开"..cfg2.name or "").."获得"..color..ItemData.name.."x"..value.."</color>",0})
	    end)
	end
end
local function SystemChatMessage(msg)
	module.ChatModule.SetData({nil,nil,{0,0},0,msg,0})
end
--开礼包全服通知
local colorTab={[0]="<color=#B6B6B6FF>","<color=#17C1A8FF>","<color=#1295CCFF>","<color=#8950DFFF>","<color=#FEA211FF>","<color=#E96651FF>"}
EventManager.getInstance():addListener("server_notify_10", function(event, cmd, data)
    local pid=data[1]
    local itemList=data[2]
    local _type = data[3] or 1
    local _packageId = data[4]
    if _type == 1 then
	    for i=1,#itemList do
	    	local cfg=module.ItemModule.GetConfig(itemList[i][2])
	    	local _packageCfg = _packageId and module.ItemModule.GetConfig(_packageId)
	    	if cfg then
	    		local showName=string.format(" %s%s</color>",colorTab[cfg.quality],cfg.name)
				if module.playerModule.IsDataExist(data[1]) then
					utils.SGKTools.showScrollingMarquee("恭喜"..module.playerModule.IsDataExist(data[1]).name..(_packageCfg and "打开".._packageCfg.name or "").."获得了："..showName)
				else
					module.playerModule.Get(data[1],(function( ... )
						utils.SGKTools.showScrollingMarquee("恭喜"..module.playerModule.IsDataExist(data[1]).name..(_packageCfg and "打开".._packageCfg.name or "").."获得了："..showName)
					end))
				end
				if pid ~= module.playerModule.Get().id then
					SystemChat(pid,itemList[i][1],itemList[i][2],itemList[i][3],_packageId)
				end
		    end
	    end
	else

	end
end);
--聊天信息通知
EventManager.getInstance():addListener("server_respond_2007", function(event, cmd, data)
	local sn = data[1];
	local err = data[2];
	--ERROR_LOG("2007",sprinttb(data))
	if err == 0 then
		if data[4] > 100 then
			data[4] = 100
		end
		Set(data)
	else
		print("聊天信息通知err", err);
	end
end);

--聊天信息返回
EventManager.getInstance():addListener("server_respond_2006", function(event, cmd, data)
	local sn = data[1];
	local err = data[2];
	if err == 0 then
		print("聊天信息返回Succeed");
		-- showDlgError(nil,"发送成功")
	else
		print("聊天信息返回err", err);
		showDlgError(nil,"聊天信息返回err")
	end
end);
local SystemMessageList = nil
local function GetSystemMessageList(type)
	if not SystemMessageList then
		if not System_Set_data.SystemMessageList_Time then
			System_Set_data.SystemMessageList_Time = 0
		end
		NetworkService.Send(16954)
		SystemMessageList = {}
		return {}
	end
	if type then
		return SystemMessageList[type]
	else
		return SystemMessageList
	end
end

local function SetSystemMessageList(type,data)
	if System_Set_data.SystemMessageList_Time and System_Set_data.SystemMessageList_Time >= data[5] then
		return
	end
	if not SystemMessageList[type] then
		SystemMessageList[type] = {}
	end
	data[#data+1] = 0--未读
	SystemMessageList[type][#SystemMessageList[type]+1] = data
end
--离线信息查询返回
EventManager.getInstance():addListener("server_respond_16955", function(event, cmd, data)
	--ERROR_LOG("16955",sprinttb(data))
	if data[2] == 0 then
		for i = 1,#data[3] do
			SetSystemMessageList(data[3][i][1],data[3][i])
		end
		DispatchEvent("SystemMessageList_Change")
	end
end)
return {
	GetManager = GetManager,
	SetManager = SetManager,--给邮件用的，用来存储邮件消息
	GetNewChat = GetNewChat,--获取最新的两条聊天
	ChatMessageRequest = ChatMessageRequest,
	EnterMapChannel = EnterMapChannel,
	GetReadChatid = GetReadChatid,
	SetReadChatid = SetReadChatid,
	SetTeamChat = SetTeamChat,
	GetChatDataTeam = GetChatDataTeam,
	GetAtMyMsg = GetAtMyMsg, ---@我的消息\
	TeamChatKeywordList = TeamChatKeywordList,
	GetPLayerStatus = GetPLayerStatus,
	SetPLayerStatus = SetPLayerStatus,
	PrivateShowRed = PrivateShowRed,
	GetShowChatRed = GetShowChatRed,
	Reset_channel = Reset_channel,
	SetData = Set,
	GetChatMessageTime = GetChatMessageTime,
	GetPrivateChatData = GetPrivateChatData,
	SetPrivateChatData = SetPrivateChatData,
	ChatUpdate = ChatUpdate,
	LoadOldData = LoadOldData,
	SystemChat = SystemChat,
	SystemChatMessage = SystemChatMessage,
	GetSystemMessageList = GetSystemMessageList,
	SetChatMessageTime = SetChatMessageTime,
};
