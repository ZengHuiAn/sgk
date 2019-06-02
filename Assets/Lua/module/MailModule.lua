local EventManager = require 'utils.EventManager';
local NetworkService = require "utils.NetworkService";
local ChatManager = require 'module.ChatModule'
local TipCfg = require "config.TipConfig"

local ModuleDataArr = nil
local SnArr = {}

local DelMailList = {}
local function SetDelMailList(id)
	local flag = true
	for i=1,#DelMailList do
		if DelMailList[i] == id then
			flag =false
			break
		end
	end
	if flag then
		DelMailList[#DelMailList+1] = id
	end
end

local function Set(data)
	if data then
	-- if not ModuleDataArr[data[4]] then
	-- 	ModuleDataArr[data[4]] = {}
	-- end
	if not ModuleDataArr then
		ModuleDataArr = {}
		NetworkService.Send(5001,{nil, 1,3})
		NetworkService.Send(5001,{nil, 8,3})
	end
		local temp = {
			id = data[1],--邮件ID
			type = data[2],--邮件类型
			title = data[3],--邮件标题
			status = tonumber(data[4]),--邮件状态
			fromid = data[5],--来源角色ID
			fromname = data[6],--来源角色名字
			time = data[7],--发件时间
			attachment_count = data[8],--附件数量
			attachment_opened = tonumber(data[9]),--附件状态0未领取1领取
			content = data[10],--邮件内容附件等
			fun = data[11],
			data = data[12]--邮件临时数据
		}
		if data[2] == 3 then
		--为用户聊天
			ChatManager.SetManager(temp,0,data[2])----0聊天显示在左1显示在右
			NetworkService.Send(5007,{nil,{temp.id}})--收到私聊后立即删除记录
		elseif data[2] == 8 then
			ChatManager.SetManager(temp,0,data[2])--对方加好友通知
        elseif data[2] == 9 then        --通知公会邀请
            module.unionModule.GeneralInvitation({pid = data[5], unionId = data[3]})
            NetworkService.Send(5007,{nil,{temp.id}})--收到私聊后立即删除记录
        elseif data[2] == 10 then
        	--提示对方正在战斗中
        	showDlgError(nil,temp.title)
        	NetworkService.Send(5007,{nil,{temp.id}})--收到后立即删除记录
		elseif data[2] == 100 then--好友赠送的物品邮件
			--temp.title = temp.fromname.."赠送给您的礼物"
			temp.title = string.format(TipCfg.GetAssistDescConfig(61001).info,temp.fromname)
			temp.status = 2
			temp.key = data[1]
			temp.id = "friend"..temp.fromid.."_"..temp.key
			temp.attachment_count = 1
			local _item_1 = {module.FriendModule.GetFriendConf().item_type,module.FriendModule.GetFriendConf().item_id,module.FriendModule.GetFriendConf().item_value}
			temp.content = {content = TipCfg.GetAssistDescConfig(61002).info,item = {_item_1},id = temp.id}
			ModuleDataArr[temp.id] = temp
		elseif data[2] == nil then
			local list = module.MailModule.GetManager()
			temp.id = #list.."TestMail"..temp.time
			temp.type = 101
			temp.content.id = temp.id
			ModuleDataArr[temp.id] = temp
		else
			ModuleDataArr[data[1]] = temp
		end
	end
end

local function SetStatus(id,status)--存邮件状态
	ModuleDataArr[id].status = status
end
local function SetAttachment_opened(id,status)--附件状态0未领取1领取
	ModuleDataArr[id].attachment_opened = status
	DispatchEvent("Mail_INFO_CHANGE")
end

local function SetContent(data)--存邮件内容
	ModuleDataArr[data.id].content = data
end

local function DelMail(id)
	ModuleDataArr[id] = nil
	DispatchEvent("Mail_INFO_CHANGE")
	DispatchEvent("Mail_Delete_Succeed")
end

local function GetAttachment(id)
	--玩家领取邮件物品
	print("玩家领取邮件物品5019")
	local sn = NetworkService.Send(5019,{nil,id})
	SnArr[sn] = id
end
local function GetFrinedAttachment(pid,key)
	NetworkService.Send(5031,{nil,pid,key})
end
local function Get(id)
	if not ModuleDataArr then
		ModuleDataArr = {}
		NetworkService.Send(5001,{nil, 1,3}) -- 系统
		NetworkService.Send(5001,{nil, 8,3}) -- 好友
		NetworkService.Send(5029)--获赠记录
	end
	if id then
		return ModuleDataArr[id]
	else
		local list = {}
		for k,v in pairs(ModuleDataArr) do
			if v then
				list[#list + 1] = v
			end
		end
		table.sort( list,function ( a,b)
			if a.status == b.status then
				if a.status == 1 then
					return a.time > b.time
				elseif a.attachment_opened == b.attachment_opened then
					return a.time > b.time
				else
					return a.attachment_opened < b.attachment_opened
				end
			else
				return a.status < b.status
			end
			-- local r
			-- if tonumber(a.status) == tonumber(b.status) then
			-- 	r = tonumber(a.attachment_opened) < tonumber(b.attachment_opened)
			-- else

			-- 	r = tonumber(a.status) < tonumber(b.status)
			-- end
			-- return r
		end)
		return list
	end
end

local function GetMailStatus()
	local list = Get()
	for i = 1,#list do
		if list[i].attachment_count > 0 then
			--有附件
			if list[i].attachment_opened == 0 then
				--未领取
				return true
			else
				--已领取
			end
		else
			--无附件
			if list[i].status ~= 1 then
				--已读取
			else
				--未读取
				return true
			end
		end
	end
	return false
end

local function GetManager(id)
	return Get(id)
end
local function SetManager(data,status)
	if status then
		Set({data.id,
			data.type,--邮件类型
			data.title,--邮件标题
			data.status,--邮件状态
			data.fromid,--来源角色ID
			data.fromname,--来源角色名字
			data.time,--发件时间
			data.attachment_count,--附件数量
			data.attachment_opened,--附件状态0未领取1领取
			data.content,
			data.fun,
			data.data,--邮件临时数据
		})
	else
		Set(data)
	end
end
EventManager.getInstance():addListener("server_respond_5002", function(event, cmd, data)
	local sn = data[1];
	local err = data[2];
	if err == 0 then
		--ERROR_LOG("查询邮件列表Succeed",sprinttb(data));
		for i = 1 ,#data[3] do
			Set(data[3][i])
		end
		DispatchEvent("Mail_INFO_CHANGE");
	else
		print("查询邮件列表err", err);
	end
end);
local DelFriendMail_sn = {}
local function DelFriendMail(list)--清空已领取好友礼物
	local sn = NetworkService.Send(5041,{nil,list})
	DelFriendMail_sn[sn] = list
end
EventManager.getInstance():addListener("server_respond_5042",function (event,cmd,data)
	local sn = data[1];
	local err = data[2];
	--ERROR_LOG("5042->",sprinttb(data))
	if err == 0 then
		for i = 1,#DelFriendMail_sn[sn] do
			local pid = DelFriendMail_sn[sn][i][1]
			local key = DelFriendMail_sn[sn][i][2]
			ModuleDataArr["friend"..pid.."_"..key] = nil
		end
		DispatchEvent("Mail_INFO_CHANGE")
		DispatchEvent("Mail_Delete_Succeed")
	else
		ERROR_LOG("删除失败 ",err)
	end
end)
EventManager.getInstance():addListener("server_respond_5004", function(event, cmd, data)
	local sn = data[1];
	local err = data[2];
	if err == 0 then
		--print("获取邮件内容", sprinttb(data));
		local temp = {}
		for i =1 ,#data[3] do
			temp[i] = {id = data[3][i][1],content = data[3][i][2],item =data[3][i][3],attachment_opened = data[3][i][4]}
			SetContent(temp[i])
		end
		DispatchEvent("MAIL_GET_RESPOND",{data = temp})
	else
		print("获取邮件内容err", err);
	end
end)

EventManager.getInstance():addListener("server_respond_5006", function(event, cmd, data)
	--更新邮件状态
	local sn = data[1];
	local err = data[2];
	if err == 0 then
		--ERROR_LOG("更新邮件状态", sprinttb(data));
		for i =1 ,#data[3] do
			SetStatus(data[3][i][1],data[3][i][2])
		end
		DispatchEvent("Mail_INFO_CHANGE")
	else
		print("读取邮件err", err);
	end
end)

EventManager.getInstance():addListener("server_respond_5020",function (event,cmd,data)
	local sn = data[1];
	local err = data[2];
	if err == 0 then
		if SnArr[sn] then
			print("sn"..SnArr[sn])
			ModuleDataArr[SnArr[sn]].attachment_opened = 1
			SnArr[sn] = nil
		end
		-- print("领取邮件物品"..sprinttb(data))
		DispatchEvent("Mail_INFO_CHANGE");
	else
		print("领取邮件物品err", err);
	end
end)

EventManager.getInstance():addListener("server_notify_26",function ( event,cmd,data)
	--ERROR_LOG("新邮件"..sprinttb(data))
	if ModuleDataArr then
		Set(data)
		DispatchEvent("Mail_INFO_CHANGE");
	end
end)

EventManager.getInstance():addListener("server_respond_5008",function (event,cmd,data)
	local sn = data[1];
	local err = data[2];
	for i=1,#DelMailList do
		DelMail(DelMailList[i])
	end
	DelMailList = {}
	if err == 0 then
		print("qingkongfanhui",sprinttb(data))
		-- for i =1 ,#data[3] do
		-- 	DelMail(data[3][i])
		-- end
	else
		print("邮件删除err", err);
	end

end)

return {
	GetManager = GetManager,
	SetManager = SetManager,
	DelMail = DelMail,
	GetAttachment = GetAttachment,
	GetMailStatus = GetMailStatus,
	GetFrinedAttachment = GetFrinedAttachment,
	DelFriendMail = DelFriendMail,
	SetAttachment_opened = SetAttachment_opened,
	SetDelMailList = SetDelMailList,
};
