local EventManager = require 'utils.EventManager';
local NetworkService = require "utils.NetworkService";

local ModuleDataArr = nil
local SnArr = {}

local function Set(data)
	if data then
		local temp = {
		pid = data[1],
		type = data[2],--1.好友2.好友黑名单3.特别关注4.陌生人黑名单
		name = utils.SGKTools.matchingName(data[3]),
		online = data[4],
		level = data[5] or 0,
		rtype = data[6],--是否互相为好友0n 1y
		sex = data[7] or 0,
		liking = data[8] or 0,--好感度
		care = 0,
		stranger = 1,--0陌生人1好友
		}
		if not ModuleDataArr then
			ModuleDataArr = {}
		end
		if data[2] == 3 then
			temp.type = 1
			temp.care = 1
		elseif data[2] == 4 then--陌生人黑名单
			temp.type = 2
			temp.stranger = 0
		end
		if temp.online == true or temp.online == 1 then
			temp.online = 1
		else
			temp.online = 0
		end
		--ERROR_LOG(sprinttb(temp))
		if ModuleDataArr[data[1]] and ModuleDataArr[data[1]].online ~= temp.online then
			if temp.online == 1 then
				--上线
				--showDlgError(nil,"您的好友"..temp.name.."已上线")
				DispatchEvent("Friend_INFO_Desc",temp.name.."已上线")
			else
				--离线
				DispatchEvent("Friend_INFO_Desc",temp.name.."已离线")
				--showDlgError(nil,"您的好友"..temp.name.."已离线")
			end
		end
		ModuleDataArr[data[1]] = temp
	end
end
local careCount = 0
local function Get(Type,id,sort)
	if not ModuleDataArr then
		ModuleDataArr = {}
		NetworkService.Send(5011,{nil})
	end
	if id then
		if ModuleDataArr[id] and Type and ModuleDataArr[id].type ~= Type then
			return nil
		end
		return ModuleDataArr[id]
	else
		local list = {}
		local temp = Type and Type or 1
		if temp	== 1 then
			careCount = 0
		end
		for k,v in pairs(ModuleDataArr) do
			--print(v.pid..">"..temp..">"..v.type)
			if v and v.type == temp then
				list[#list + 1] = v
				if temp == 1 and v.care == 1 then
					careCount = careCount + 1
				end
			end
		end
		sort = sort or 1
		if sort == 1 then
			table.sort(list,function(a,b)
				if a.online == b.online then
					--ERROR_LOG(sprinttb(a),a.online,b.online)
					return a.care > b.care
				else
					return a.online > b.online
				end
				end)
		elseif sort == 2 then
			table.sort(list,function(a,b)
				return a.level > b.level
			end)
		elseif sort == 3 then
			table.sort(list,function(a,b)
				return SGK.SortChinese.GetSpellCodeASCII(a.name) < SGK.SortChinese.GetSpellCodeASCII(b.name)
			end)
		else
			showDlgError(nil,"排序类型错误 "..sort)
		end

		return list
	end
end
local function FindName(Type,name)
	if not ModuleDataArr then
		ModuleDataArr = {}
		NetworkService.Send(5011,{nil})
	end
	for k,v in pairs(ModuleDataArr) do
		if v.type == Type and v.name == name then
			return v
		end
	end
	return nil
end
local function FindId(id)
	return ModuleDataArr[id]
end
local function GetcareCount()
	return careCount
end

local FriendConf = nil
local friend_gift_cfg = nil
local function GetFriendConf()
	if FriendConf == nil then
		friend_gift_cfg = {}
		DATABASE.ForEach("friend_gift", function(row)
			if row.key == 1001 then
				FriendConf = row
			end
			friend_gift_cfg[row.key] = row
		end)
	end
	return FriendConf
end
local function GetFriend_gift_cfg(type)
	if friend_gift_cfg == nil then
		GetFriendConf()
	end
	if type then
		local list = {}
		for k,v in pairs(friend_gift_cfg) do
			if v.type == 3 then
				list[#list+1] = v
			end
		end
		return list
	end
	return friend_gift_cfg
end
local function DelModule(id)
	print("DelModule->"..id)
	ModuleDataArr[id] = nil
end
local givingCount = {}
local function GetgivingCount(pid)
	--ERROR_LOG(pid.."->"..sprinttb(givingCount))
	if pid then
		if givingCount[pid] then
			return givingCount[pid]
		else
			return 0
		end
	end
	local count = 0
	for k,v in pairs(givingCount) do
		count = count + 1
	end
	return count
end
local Giving_sn = {}
local function Giving(pid,item_id,item_type,value)
	--好友送礼
	local sn = NetworkService.Send(5051,{nil,pid,item_id})
	Giving_sn[sn] = {pid = pid,item_id = item_id,item_type = item_type,value = value}
end
EventManager.getInstance():addListener("server_notify_30", function(event, cmd, data)
	--ERROR_LOG(sprinttb(data))
end)
EventManager.getInstance():addListener("server_notify_5048", function(event, cmd, data)
	--好感度变化通知
	--ERROR_LOG("5048",sprinttb(data))
	ModuleDataArr[data[1]].liking = data[2]
	DispatchEvent("Friend_Liking_Change",{pid = data[1],liking = data[2]})
end)
EventManager.getInstance():addListener("server_notify_5027", function(event, cmd, data)
	print("体力接收->5027"..sprinttb(data))
	if module.playerModule.IsDataExist(data[3]) then
		showDlgError(nil,module.playerModule.IsDataExist(data[3]).name.."赠送了"..GetFriendConf().item_value.."点时之力给你，剩余接收赠送次数"..data[4])
	else
		module.playerModule.Get(data[3],(function( ... )
			showDlgError(nil,module.playerModule.IsDataExist(data[3]).name.."赠送了"..GetFriendConf().item_value.."点时之力给你，剩余接收赠送次数"..data[4])
		end))
	end
end)
EventManager.getInstance():addListener("server_respond_5052",function (event,cmd,data)
	local sn = data[1]
	local err = data[2]
	if err == 0 then
		local name = Get(nil,Giving_sn[sn].pid).name
		showDlgError(nil,SGK.Localize:getInstance():getValue("haogandu_wanjia_tips_01",name,"+"..Giving_sn[sn].value))
		DispatchEvent("Friend_Giving_Succeed")
		--ERROR_LOG("5052",sprinttb(data))
	end
end)
EventManager.getInstance():addListener("server_respond_5038",function (event,cmd,data)
	--ERROR_LOG(sprinttb(data))
	local sn = data[1];
	local err = data[2];
	if err == 0 then
		for i =1 ,#data[3] do
			Set(data[3][i])
		end
		DispatchEvent("Friend_INFO_CHANGE")
	else
		print("获取关注好友在线列表返回err", err);
	end
end)
local Friend_receive_give_count = 0
local function GetFriend_receive_give_count()
	return Friend_receive_give_count
end
EventManager.getInstance():addListener("server_respond_5030",function (event,cmd,data)
	local sn = data[1];
	local err = data[2];
	if err == 0 then
		--ERROR_LOG("查询获赠记录->5030",sprinttb(data))
		for i = 1,#data[3] do
			local list = {}
			list[1] = data[3][i][4]--邮件ID,(同一个人赠送的第几封邮件)
			list[2] = 100--邮件类型
			list[5] = data[3][i][1]--来源角色ID
			list[7] = data[3][i][3]--发件时间
			list[9] = data[3][i][5]--附件状态0未领取1领取
			if module.playerModule.IsDataExist(data[3][i][1]) then
				list[6] = module.playerModule.IsDataExist(data[3][i][1]).name
				module.MailModule.SetManager(list)
			else
				module.playerModule.Get(data[3][i][1],(function( ... )
					list[6] = module.playerModule.IsDataExist(data[3][i][1]).name
					module.MailModule.SetManager(list)
					DispatchEvent("Mail_INFO_CHANGE");
				end))
			end
		end
		Friend_receive_give_count = data[4]
		DispatchEvent("Mail_INFO_CHANGE");
		DispatchEvent("receive_give_record_query",{list = data[3],count = data[4]})
	else
		print("查询获赠记录->5030 err"..err)
	end
end)
EventManager.getInstance():addListener("server_notify_5027",function (event,cmd,data)
	--获赠体力通知
	--ERROR_LOG("5027",sprinttb(data))
	local list = {}
	list[1] = data[4]--邮件ID,(同一个人赠送的第几封邮件)
	list[2] = 100--邮件类型
	list[5] = data[1]--来源角色ID
	list[7] = data[3]--发件时间
	list[9] = data[5]--附件状态0未领取1领取
	if module.playerModule.IsDataExist(data[1]) then
		list[6] = module.playerModule.IsDataExist(data[1]).name
		module.MailModule.SetManager(list)
	else
		module.playerModule.Get(data[1],(function( ... )
			list[6] = module.playerModule.IsDataExist(data[1]).name
			module.MailModule.SetManager(list)
			DispatchEvent("Mail_INFO_CHANGE");
		end))
	end
	Friend_receive_give_count = Friend_receive_give_count + 1
	DispatchEvent("Mail_INFO_CHANGE");
	DispatchEvent("receive_give_record_query",{list = {},count = Friend_receive_give_count})
end)
EventManager.getInstance():addListener("server_respond_5012",function (event,cmd,data)
	local sn = data[1];
	local err = data[2];
	if err == 0 then
		for i =1 ,#data[3] do
			--ERROR_LOG(sprinttb(data[3][i]))
			Set(data[3][i])
		end
		DispatchEvent("Friend_INFO_CHANGE")
	else
		print("获取联系人列表返回err", err);
	end
end)
EventManager.getInstance():addListener("server_respond_5024",function (event,cmd,data)
	local sn = data[1];
	local err = data[2];
	--print("体力赠送5024->"..sprinttb(data))
	if err == 0 then	
		showDlgError(nil,"赠送成功")
		NetworkService.Send(5025)--查询赠送记录
	else
		showDlgError(nil,"赠送失败")
	end
end)
EventManager.getInstance():addListener("server_respond_5032",function (event,cmd,data)
	local sn = data[1];
	local err = data[2];
	--ERROR_LOG("体力赠送5032->"..sprinttb(data))
	if err == 0 then	
		showDlgError(nil,"领取成功")
		NetworkService.Send(5029)
	else
		--showDlgError(nil,"领取失败")
	end
end)
EventManager.getInstance():addListener("server_respond_5026",function (event,cmd,data)
	local sn = data[1];
	local err = data[2];
	print("查询体力赠送5026->"..sprinttb(data))
	for i = 1,#data[3] do
		givingCount[data[3][i][1]] = data[3][i][2]
	end
	DispatchEvent("Presented_successful")
end)
EventManager.getInstance():addListener("server_respond_5014",function (event,cmd,data)
	local sn = data[1];
	local err = data[2];
	local TipCfg = require "config.TipConfig"
	if err == 0 then	
		table.remove(data,1)
		table.remove(data,1)
		if data[2] == 1 then
			if Get(2,data[1]) then
				if Get(2,data[1]).stranger == 0 then
					showDlgError(nil,TipCfg.GetAssistDescConfig(61021).info)--"已解除黑名单限制")
				else
					showDlgError(nil,TipCfg.GetAssistDescConfig(61016).info)
				end
			elseif Get(1,data[1]) and Get(1,data[1]).care then
				showDlgError(nil,"取消特别关注成功")
			else
				showDlgError(nil,TipCfg.GetAssistDescConfig(61022).info)--"添加好友成功")
				--NetworkService.Send(5009,{nil,data[1],8,module.playerModule.Get().name.."添加你为好友",""})--发送已添加对方为好友的消息
			end
		elseif data[2] == 2 then
			showDlgError(nil,"添加黑名单成功")
		elseif data[2] == 3 then
			showDlgError(nil,"添加特别关注成功")
			Set(data)
			DispatchEvent("Friend_attention_CHANGE")
			return
		end
		Set(data)
		DispatchEvent("Friend_INFO_CHANGE")
		DispatchEvent("Friend_ADD_CHANGE",{err = err})
	elseif err == 3 then
		showDlgError(nil,"角色不存在")
	elseif err == 9 then
		showDlgError(nil,TipCfg.GetAssistDescConfig(61023).info)--"好友已达上限")
	else
		showDlgError(nil,"添加失败")
		--print("添加联系人请求err", err);
	end
end)

EventManager.getInstance():addListener("server_respond_5016",function (event,cmd,data)
	local sn = data[1];
	local err = data[2];
	if err == 0 then
		--print(sprinttb(data))
		local TipCfg = require "config.TipConfig"
		if Get(1,data[3]) then
			showDlgError(nil,"删除成功")
		else
			showDlgError(nil,TipCfg.GetAssistDescConfig(61021).info)
		end
		DelModule(data[3])
		DispatchEvent("Friend_INFO_CHANGE")
	else
		print("删除联系人err", err);
	end
end)
local RecommendFriends = {}
local function GetRecommendFriends()
	return RecommendFriends
end
EventManager.getInstance():addListener("server_respond_5022",function (event,cmd,data)
	local sn = data[1];
	local err = data[2];
	if err == 0 then
		local temp = {}
		for i = 1,#data[3] do
			--print(data[3][i][1])
			if not ModuleDataArr[data[3][i][1]] then
				temp[i] = {
				pid = data[3][i][1],
				name = utils.SGKTools.matchingName(data[3][i][2]),
				online = data[3][i][3],
				level = data[3][i][4],
				}
			end
		end
		RecommendFriends = temp
		DispatchEvent("Friend_Recommend_Ref",{data = temp})
	else
		print("推荐好友列表err", err);
	end
end)

local function GetManager(Type,id,sort)
	return Get(Type,id,sort)
end
local _RefTime = 0
local function RefTime(time)
	if time then
		_RefTime = time
	end
	return _RefTime
end
local PlayerFinOnline_sn = {}
local PlayerFinOnline_Data = {}
local function PlayerFinOnline(pid,fun)
	local Time = require "module.Time"
	if not PlayerFinOnline_Data[pid] or (PlayerFinOnline_Data[pid] and (Time.now() - PlayerFinOnline_Data[pid].RefTime) > 30) then
		local sn = NetworkService.Send(5039,{nil,{pid}})
		PlayerFinOnline_sn[sn] = {fun = fun,pid = pid}
		return false
	else
		return PlayerFinOnline_Data[pid].online
	end
end
EventManager.getInstance():addListener("server_respond_5040",function (event,cmd,data)
	--ERROR_LOG(5040,sprinttb(data))
	if data [2] == 0 then
		if PlayerFinOnline_sn[data[1]] and #data[3] > 0 then
			local Time = require "module.Time"
			PlayerFinOnline_Data[PlayerFinOnline_sn[data[1]].pid] = {online = data[3][1],RefTime = Time.now()}
			PlayerFinOnline_sn[data[1]].fun(data[3][1])
			DispatchEvent("PlayerFinOnlineChange")
		end
	end
end)
return {
	GetManager = GetManager,
	FindName = FindName,
	GetgivingCount = GetgivingCount,
	GetFriendConf = GetFriendConf,
	GetcareCount = GetcareCount,
	GetRecommendFriends = GetRecommendFriends,
	FindId = FindId,
	RefTime = RefTime,
	PlayerFinOnline = PlayerFinOnline,
	GetFriend_receive_give_count = GetFriend_receive_give_count,
	GetFriend_gift_cfg = GetFriend_gift_cfg,
	Giving = Giving,
};