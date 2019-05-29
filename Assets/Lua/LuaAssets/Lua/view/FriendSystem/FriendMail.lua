local MailModule = require 'module.MailModule'
local NetworkService = require "utils.NetworkService";
local ItemHelper = require "utils.ItemHelper"
local FriendModule = require 'module.FriendModule'
local IconFrameHelper = require "utils.IconFrameHelper"
local View = {};
function View:Start(data)
	self.root = CS.SGK.UIReference.Setup(self.gameObject)
	self.view = self.root.view.Content

	self.nguiDragIconScript = self.view.ScrollView[CS.UIMultiScroller]	

	self.root.view.Title[UI.Text].text = SGK.Localize:getInstance():getValue("biaoti_youjian_01")

	CS.UGUIClickEventListener.Get(self.root.view.Close.gameObject).onClick = function (obj) 
        DialogStack.Pop()
    end

    CS.UGUIClickEventListener.Get(self.root.mask.gameObject,true).onClick = function (obj) 
        DialogStack.Pop()
    end

    self:SetMailList()

	self.nguiDragIconScript.RefreshIconCallback = (function (go,idx)
		self:refreshData(go,idx)
	end)

	CS.UGUIClickEventListener.Get(self.view.emptyBtn.gameObject).onClick = function (obj) 
		--一键清空
		self:OnClickEmptyAllBtn()
    end

    CS.UGUIClickEventListener.Get(self.view.getBtn.gameObject).onClick = function (obj) 
    	--一键领取
		self:OnClickGetAllBtn()
    end
end

function View:SetMailList()
--[[
	self.AwardData = module.AwardModule.GetAward()
	self.MailData = MailModule.GetManager()
	ERROR_LOG(sprinttb(self.AwardData))
	ERROR_LOG(sprinttb(self.MailData))
	--NetworkService.Send(5029)--获赠记录

	self.Click_Mail_data = nil--当前点击打开的邮件
	
	if self.MailData then
		self.root.view.tips:SetActive(#self.MailData == 0)
		self.view:SetActive(#self.MailData ~= 0)
		--初始化数量
		self.nguiDragIconScript.DataCount = #self.MailData
	end
	--]]

	self.MailList = {}
	self.mailData = MailModule.GetManager() or {}
	self.awardData = module.AwardModule.GetAward() or {}

	for i=1,#self.mailData do
		table.insert(self.MailList,self.mailData[i])
	end
	for i=1,#self.awardData do
		table.insert(self.MailList,self.awardData[i])
	end
	for k,v in pairs(self.MailList) do
		if v.time == "" then
			v.time = 0
			--print("12131231231313")
		end
	end
	table.sort(self.MailList,function(a,b)
		return a.time > b.time
	end)
	--print("zoe查看邮件",sprinttb(self.MailList))
	self.Click_Mail_data = nil--当前点击打开的邮件
	
	self.root.view.tips:SetActive(#self.MailList == 0)
	self.view:SetActive(#self.MailList ~= 0)
	--初始化数量
	self.nguiDragIconScript.DataCount = #self.MailList
end

function  View:refreshData(go,idx)
	-- local cfg = self.MailData[idx +1]
	local cfg = self.MailList[idx +1 ]
	if cfg then
		local obj = CS.SGK.UIReference.Setup(go)

		obj.name[UnityEngine.UI.Text].text = cfg.title
		obj.name[UnityEngine.UI.Text].color = cfg.status == 1 and {r = 0,g = 0,b = 0,a = 255} or {r = 0,g = 0,b = 0,a = 204}
		
		--print("zoe查看单个邮件详情",sprinttb(cfg))
		if cfg.time~= "" and cfg.time~= 0 then
			local s_time= os.date("*t",cfg.time)
			obj.time[UnityEngine.UI.Text].text = s_time.year.."."..s_time.month.."."..s_time.day
		else
			obj.time[UnityEngine.UI.Text].text = ""
		end
		obj.read.gameObject:SetActive(cfg.status == 1)
		--obj.read.gameObject:SetActive(false)
		--type 102 可领取奖励 103 离线奖励
		obj.GetTip:SetActive(cfg.type == 102 or cfg.type == 103)

		local status = 0
		if cfg.attachment_count > 0 then--有附件
			if cfg.attachment_opened == 0 then--未领取
				status = 1
			else--已领取
				status = 2
			end
		else--无附件
			if cfg.status ~= 1 then--已读取
				status = 2
			else--未读取
				status = 0
			end
		end

		obj.Icon[CS.UGUISpriteSelector].index = status
		obj.Image[CS.UGUISpriteSelector].index = status == 2 and 1 or 0

		CS.UGUIClickEventListener.Get(obj.Image.gameObject).onClick = function (obj)
			if cfg.type == 102 then
				utils.NetworkService.Send(195,{nil,cfg.id})
			elseif cfg.type == 103 then
				-- ERROR_LOG(cfg.time)
				module.AwardModule.GetOfflineAward(cfg.time)
			else 
				self.root.openMail.view.top.title[UnityEngine.UI.Text].text = cfg.title
				--openMail.view.top.title[UnityEngine.UI.Text].color = cfg.status == 1 and {r = 0,g = 0,b = 0,a = 255} or {r = 0,g = 0,b = 0,a = 204}

				self.root.openMail.view.top.Image[CS.UGUISpriteSelector].index = status

				local s_time= os.date("*t",cfg.time)
				self.root.openMail.view.top.time[UnityEngine.UI.Text].text = s_time.year.."."..s_time.month.."."..s_time.day.." "..(s_time.hour or 0)..":"..((s_time.min < 10 and "0"..s_time.min or s_time.min) or 0)
				
				self.root.openMail.view.bottom.getBtn:SetActive(cfg.attachment_opened == 0)

				self.root.openMail.view.top.is_receive:SetActive(false)
				self.root.openMail.view.bottom.emptyBtn:SetActive(false)

				if cfg.attachment_count > 0 then--有附件
					if cfg.attachment_opened ~= 0 then--已领取
						self.root.openMail.view.top.is_receive:SetActive(true)
						self.root.openMail.view.bottom.emptyBtn:SetActive(true)
					end
				else--无附件
					self.root.openMail.view.bottom.emptyBtn:SetActive(true)
				end

				CS.UGUIClickEventListener.Get(self.root.openMail.view.bottom.emptyBtn.gameObject).onClick = function (obj) 
					--删除正在打开的邮件
					if cfg.type == 100 then
						MailModule.DelFriendMail({{cfg.fromid,cfg.key}})--清空已领取好友礼物
					elseif cfg.type == 101 then
						if cfg.fun then
							cfg.fun(cfg.id,3,cfg.data)--删除
						end
					else
						MailModule.SetDelMailList(cfg.id)
						NetworkService.Send(5007,{nil,{cfg.id}})--删除已领取邮件
					end
				end

				if cfg.content then
					self:OnShowMailDetail({cfg.content})
				else
					NetworkService.Send(5003,{nil,{cfg.id}})--获取邮件内容
					-- if cfg.status == 1 then
					-- 	NetworkService.Send(5005,{nil,{{cfg.id,2}}})--已读取邮件
					-- end
				end

				self.Click_Mail_data = cfg
			end
		end	
	end
	go:SetActive(true)
end

function View:OnClickEmptyAllBtn()
	if #self.MailList == 0 then
		showDlgError(nil,"没有可清空的邮件",nil,nil,11)
		return
	end

	local list = {}
	local friend_list = {}
	
	for i =1 ,#self.MailList do
		local _cfg = self.MailList[i]
		if _cfg.attachment_opened ~= 0 then
			if _cfg.type == 100 then
				friend_list[#friend_list+1] = {_cfg.fromid,_cfg.key}
			elseif _cfg.type == 101 then
				if _cfg.fun then
					_cfg.fun(_cfg.id,3,_cfg.data)--删除
				end
				--MailModule.DelMail(self.MailData[i].id)
			else
				list[#list + 1] = _cfg.id
			end
		end
	end
	showDlg(self.view,"确认清空已提取附件的已读邮件吗？",function()
		if #list > 0 then
			for i=1,#list do
				MailModule.SetDelMailList(list[i])
			end
			NetworkService.Send(5007,{nil,list})--清空已领取邮件
		end
		if #friend_list > 0 then
			MailModule.DelFriendMail(friend_list)--清空已领取好友礼物
		end
	end,function ()end,"清空","取消",11) 
end

function View:OnClickGetAllBtn()
	if self.view.getBtn[CS.UGUIClickEventListener].interactable then
		self.delList = {}
		local friend_list_count = 0
		
		--[[
		for i =1,#self.MailList do
			local _cfg = self.MailList[i]
			if _cfg.attachment_opened == 0 then
				list[#list + 1] = _cfg.id
				if _cfg.type == 100 then
					if friend_list_count < FriendModule.GetFriendConf().get_limit then
						friend_list_count = friend_list_count + 1
						MailModule.GetFrinedAttachment(_cfg.fromid,_cfg.key)
						if friend_list_count == FriendModule.GetFriendConf().get_limit or FriendModule.GetFriend_receive_give_count() >= FriendModule.GetFriendConf().get_limit then
							showDlgError(nil,"每天最多可领取"..FriendModule.GetFriendConf().get_limit.."个好友赠送的时之力，请明天再来吧~")
						end
					end
				elseif _cfg.type == 101 then
					if _cfg.fun then
						_cfg.fun(_cfg.id,2,_cfg.data)--领取
					end
				elseif _cfg.type == 102 then
					utils.NetworkService.Send(195,{nil,_cfg.id})
				elseif _cfg.type == 103 then
					reset = true
					module.AwardModule.GetOfflineAward(_cfg.time)
				else
					MailModule.GetAttachment(_cfg.id)
				end
			end
		end
		--]]
		local friend_Limit_count = 0
		local FriendFlag = nil
		local havemail = false
		for i =#self.MailList,1,-1 do
			local _cfg = self.MailList[i]
			if _cfg.attachment_opened == 0 then
				if _cfg.type == 100 then
					if friend_Limit_count < (FriendModule.GetFriendConf().get_limit-FriendModule.GetFriend_receive_give_count()) then
						friend_Limit_count = friend_Limit_count + 1
						self.delList[#self.delList + 1] = _cfg
					else
						havemail = true
						FriendFlag = true
					end
				else
					self.delList[#self.delList + 1] = _cfg
				end
			end
		end
		
		self.FirendErrFuc = function ()
			--print("11111")	
			if FriendModule.GetFriend_receive_give_count() >= FriendModule.GetFriendConf().get_limit then
				--utils.EventManager.getInstance():dispatch("Mail_INFO_CHANGE")
				if FriendFlag then
					showDlgError(nil,"今日已领取"..FriendModule.GetFriendConf().get_limit.."个好友赠送的体力，请明天再来吧~")
					FriendFlag = false
				end
			end
		end

		if #self.delList == 0 then
			self.FirendErrFuc()
			if not havemail then
				showDlgError(nil,"没有可领取的邮件",nil,nil,11)
			end
		else
			self.root.lockMask:SetActive(true)
			--self.view.getBtn[CS.UGUIClickEventListener].interactable = false

			self.FirendErrFuc()
			-- local FriendFlag = true
			self.GetAllFunc = function ()
				local _cfg = self.delList[#self.delList]
				--print("一键领取",sprinttb(_cfg))
				if _cfg.type == 100 then
					MailModule.GetFrinedAttachment(_cfg.fromid,_cfg.key)
				elseif _cfg.type == 101 then
					if _cfg.fun then
						_cfg.fun(_cfg.id,2,_cfg.data)--领取
					end
				elseif _cfg.type == 102 then
					utils.NetworkService.Send(195,{nil,_cfg.id})
				elseif _cfg.type == 103 then
					module.AwardModule.GetOfflineAward(_cfg.time)
				else
					MailModule.GetAttachment(_cfg.id)
				end	
			end
			self.GetAllFunc()
		end
	end
end

function View:OnShowMailDetail(data)
	local openMail = self.root.openMail
	openMail:SetActive(true)

	local cfg = data[1]
	if cfg then
		openMail.view.top.desc[UnityEngine.UI.Text].text = cfg.content
		openMail.view.mid:SetActive(#cfg.item>0)
		if #cfg.item>0 then
			self.tempObj =self.tempObj or  SGK.ResourcesManager.Load("prefabs/base/IconFrame.prefab")
			for i = 1,openMail.view.mid.scrollView.Viewport.Content.transform.childCount do
				openMail.view.mid.scrollView.Viewport.Content.transform:GetChild(i-1).gameObject:SetActive(false)
			end
			for i=1,#cfg.item do
				local _obj = nil
				if openMail.view.mid.scrollView.Viewport.Content.transform.childCount >= i then
					_obj = openMail.view.mid.scrollView.Viewport.Content.transform:GetChild(i-1).gameObject
				else
					_obj = CS.UnityEngine.GameObject.Instantiate(self.tempObj.gameObject,openMail.view.mid.scrollView.Viewport.Content.transform)
					_obj.transform.localScale =Vector3(0.8,0.8,1)
				end
				_obj:SetActive(true)

				local _item = SGK.UIReference.Setup(_obj)
				utils.IconFrameHelper.Create(_item,{type = cfg.item[i][1], id = cfg.item[i][2], count = cfg.item[i][3],showDetail = true})
			end
		end

		openMail.view.bottom.getBtn[CS.UGUIClickEventListener].interactable = true
		CS.UGUIClickEventListener.Get(openMail.view.bottom.getBtn.gameObject).onClick = function (obj) 
			--读取or领取 邮件
			--NetworkService.Send(5019,{nil,MailContent.id})
			if openMail.view.bottom.getBtn[CS.UGUIClickEventListener].interactable then
				openMail.view.bottom.getBtn[CS.UGUIClickEventListener].interactable = false
				if self.Click_Mail_data.type == 100 then
					if FriendModule.GetFriend_receive_give_count() < FriendModule.GetFriendConf().get_limit then
						MailModule.GetFrinedAttachment(self.Click_Mail_data.fromid,self.Click_Mail_data.key)
					else
						showDlgError(nil,"今日已领取"..FriendModule.GetFriendConf().get_limit.."个好友赠送的体力，请明天再来吧~")
					end
				elseif self.Click_Mail_data.type == 101 then
					if self.Click_Mail_data.fun then
						self.Click_Mail_data.fun(self.Click_Mail_data.id,2,self.Click_Mail_data.data)--领取
					end
				else
					MailModule.GetAttachment(cfg.id)
				end
				self:OpenNextMailContent(cfg)
			end
		end

		CS.UGUIClickEventListener.Get(self.root.openMail.gameObject,true).onClick = function (obj) 
			self:OpenNextMailContent(cfg)
		end
	else
		ERROR_LOG("data is err,",sprinttb(data))
	end
end

function View:OpenNextMailContent(data)
	local MailContent = data
	self.root.openMail.gameObject:SetActive(false)
	table.remove(MailContent,1)
	if #MailContent > 0 then
		self:OnShowMailDetail(MailContent)
	end
end

function View:listEvent()
	return {
		"Mail_INFO_CHANGE",
		"MAIL_GET_RESPOND",
		"MAIL_MARK_RESPOND",
		"Mail_Delete_Succeed",

		"NOTIFY_REWARD_CHANGE",
	}
end

local canRefresh = true
function View:onEvent(event,data)
	if event == "Mail_INFO_CHANGE" then
		--print("22222")
		if self.GetAllFunc and #self.delList>1 then
			table.remove(self.delList,#self.delList)	
			self.GetAllFunc()
		else
			if self.GetAllFunc then
				if #self.delList >0 then
					table.remove(self.delList,#self.delList)
				end
				self.root.lockMask:SetActive(false)
				self.view.getBtn[CS.UGUIClickEventListener].interactable = true
				self.GetAllFunc = nil
				self.FirendErrFuc() 
			end

			self:SetMailList()
			if self.root.openMail.gameObject.activeSelf then
				self.root.openMail:SetActive(false)
			end
		end
	elseif event == "MAIL_GET_RESPOND" then

		self:OnShowMailDetail(data.data)
	elseif event == "MAIL_MARK_RESPOND" then
		self.MailList = {}
		self.mailData = MailModule.GetManager()
	
		for i=1,#self.mailData do
			table.insert(self.MailList,self.mailData[i])
		end
		for i=1,#self.awardData do
			table.insert(self.MailList,self.awardData[i])
		end

		self.nguiDragIconScript:ItemRef()
		self.root.openMail.gameObject:SetActive(false)
	elseif event == "NOTIFY_REWARD_CHANGE" then
		--ERROR_LOG("xxxxxx4444")--离线奖励
		if self.GetAllFunc and #self.delList>1 then
			table.remove(self.delList,#self.delList)	
			self.GetAllFunc()
		else
			if self.GetAllFunc then
				if #self.delList >0 then
					table.remove(self.delList,#self.delList)
				end
				self.root.lockMask:SetActive(false)
				self.GetAllFunc = nil 
			end

			if not self.delay then
				self.delay = true
				self.root.transform:DOScale(Vector3.one,0.2):OnComplete(function()
					self.delay = false
					self:SetMailList()
				end)
			end
		end	
	end
end
return View