local MailModule = require 'module.MailModule'
local NetworkService = require "utils.NetworkService";
local ItemHelper = require "utils.ItemHelper"
local FriendModule = require 'module.FriendModule'
local IconFrameHelper = require "utils.IconFrameHelper"
local View = {};
function View:Start(data)
	self.view = CS.SGK.UIReference.Setup(self.gameObject)
	self.MailData = MailModule.GetManager()
	--NetworkService.Send(5029)--获赠记录
	self.Click_Mail_data = nil--当前点击打开的邮件
	self.nguiDragIconScript = self.view.ScrollView[CS.UIMultiScroller]	
	self.nguiDragIconScript.RefreshIconCallback = (function (go,idx)
		--print(self.MailData[idx +1].title .."->"..self.MailData[idx +1].status)
		local obj = CS.SGK.UIReference.Setup(go)
		
		obj.name[UnityEngine.UI.Text].text = self.MailData[idx +1].title
		--obj.time[UnityEngine.UI.Text].text = self.MailData[idx +1].fromname.."\n"..os.date("%d/%m/%Y",math.floor(self.MailData[idx +1].time))
		local s_time= os.date("*t",self.MailData[idx +1].time)
		obj.time[UnityEngine.UI.Text].text = s_time.year.."."..s_time.month.."."..s_time.day--os.date("%d/%m/%Y",math.floor(self.MailData[idx +1].time))
		--obj.read.gameObject.transform.localPosition = Vector3(270,0,0)
		obj.read.gameObject:SetActive(self.MailData[idx +1].status == 1)
		for i = 1,4 do
			obj.iconGrod[i].gameObject:SetActive(false)
		end
		if self.MailData[idx +1].attachment_count > 0 then
			--有附件
			if self.MailData[idx +1].attachment_opened == 0 then
				--未领取
				obj.iconGrod[1].gameObject:SetActive(true)
			else
				--已领取
				obj.iconGrod[2].gameObject:SetActive(true)
			end
		else
			--无附件
			if self.MailData[idx +1].status ~= 1 then
				--已读取
				obj.iconGrod[4].gameObject:SetActive(true)
			else
				--未读取
				obj.iconGrod[3].gameObject:SetActive(true)
			end
		end
		
		obj[CS.UGUIClickEventListener].onClick = (function ()
			self.view.openMail.title[UnityEngine.UI.Text].text = self.MailData[idx +1].title
			local s_time= os.date("*t",self.MailData[idx +1].time)
			self.view.openMail.time[UnityEngine.UI.Text].text = s_time.year.."."..s_time.month.."."..s_time.day.." "..(s_time.hour or 0)..":"..((s_time.min < 10 and "0"..s_time.min or s_time.min) or 0)
			self.view.openMail.getBtn.gameObject:SetActive(self.MailData[idx +1].attachment_opened == 0)
			for i = 1,4 do
				self.view.openMail.iconGrod[i].gameObject:SetActive(false)
			end
			self.view.openMail.is_receive:SetActive(false)
			self.view.openMail.emptyBtn:SetActive(false)
			if self.MailData[idx +1].attachment_count > 0 then
			--有附件
				if self.MailData[idx +1].attachment_opened == 0 then
					--未领取
					self.view.openMail.iconGrod[1].gameObject:SetActive(true)
				else
					--已领取
					self.view.openMail.is_receive:SetActive(true)
					self.view.openMail.emptyBtn:SetActive(true)
					self.view.openMail.iconGrod[2].gameObject:SetActive(true)
				end
			else
				--无附件
				self.view.openMail.emptyBtn:SetActive(true)
				if self.MailData[idx +1].status ~= 1 then
					--已读取
					self.view.openMail.iconGrod[4].gameObject:SetActive(true)
				else
					--未读取
					self.view.openMail.iconGrod[3].gameObject:SetActive(true)
				end
			end

			self.view.openMail.emptyBtn[CS.UGUIClickEventListener].onClick = function ( ... )
				--删除正在打开的邮件
				if self.MailData[idx +1].type == 100 then
					MailModule.DelFriendMail({{self.MailData[idx +1].fromid,self.MailData[idx +1].key}})--清空已领取好友礼物
				elseif self.MailData[idx +1].type == 101 then
					if self.MailData[idx +1].fun then
						self.MailData[idx +1].fun(self.MailData[idx +1].id,3,self.MailData[idx +1].data)--删除
					end
					--MailModule.DelMail(self.MailData[idx +1].id)
				else
					NetworkService.Send(5007,{nil,{self.MailData[idx +1].id}})--删除已领取邮件
				end
			end
			if self.MailData[idx +1].content then
				self:OpenMailContent({self.MailData[idx +1].content})
			else
				NetworkService.Send(5003,{nil,{self.MailData[idx +1].id}})--获取邮件内容
				if self.MailData[idx +1].status == 1 then
					NetworkService.Send(5005,{nil,{{self.MailData[idx +1].id,2}}})--已读取邮件
				end
			end
			self.Click_Mail_data = self.MailData[idx +1]
		end)
		go:SetActive(true)
	end)
	if self.MailData then
		--初始化数量
		self.nguiDragIconScript.DataCount = #self.MailData
		self.view.tips:SetActive(#self.MailData == 0)
	end
	self.view.emptyBtn[CS.UGUIClickEventListener].onClick = (function( ... )
		--一键清空
		if #self.MailData == 0 then
			showDlgError(nil,"没有可清空的邮件",nil,nil,11)
			return
		end

		local list = {}
		local friend_list = {}
		
		local temp = false
		for i =1 ,#self.MailData do
			if self.MailData[i].attachment_opened ~= 0 then
				if self.MailData[i].type == 100 then
					friend_list[#friend_list+1] = {self.MailData[i].fromid,self.MailData[i].key}
				elseif self.MailData[i].type == 101 then
					if self.MailData[i].fun then
						self.MailData[i].fun(self.MailData[i].id,3,self.MailData[i].data)--删除
					end
					--MailModule.DelMail(self.MailData[i].id)
				else
					list[#list + 1] = self.MailData[i].id
				end
			end
		end
		showDlg(self.view,"确认清空已提取附件的已读邮件吗？",function()
			if #list > 0 then
				NetworkService.Send(5007,{nil,list})--清空已领取邮件
			end
			if #friend_list > 0 then
				MailModule.DelFriendMail(friend_list)--清空已领取好友礼物
			end
		end,function ()end,"清空","取消",11)
	end)
	self.view.getBtn[CS.UGUIClickEventListener].onClick = (function( ... )
		--一键领取
		if self.view.getBtn[UnityEngine.UI.Button].interactable then
			self.view.getBtn[UnityEngine.UI.Button].interactable = false
			local list = {}
			local friend_list_count = 0
			for i =1 ,#self.MailData do
				if self.MailData[i].attachment_opened == 0 then
					list[#list + 1] = self.MailData[i].id
					if self.MailData[i].type == 100 then
						if friend_list_count < FriendModule.GetFriendConf().get_limit then
							friend_list_count = friend_list_count + 1
							MailModule.GetFrinedAttachment(self.MailData[i].fromid,self.MailData[i].key)
							if friend_list_count == FriendModule.GetFriendConf().get_limit or FriendModule.GetFriend_receive_give_count() >= FriendModule.GetFriendConf().get_limit then
								showDlgError(nil,"每天最多可领取"..FriendModule.GetFriendConf().get_limit.."个好友赠送的时之力，请明天再来吧~")
							end
						end
					elseif self.MailData[i].type == 101 then
						if self.MailData[i].fun then
							self.MailData[i].fun(self.MailData[i].id,2,self.MailData[i].data)--领取
						end
					else
						MailModule.GetAttachment(self.MailData[i].id)
					end
				end
			end
			if #list == 0 then
				showDlgError(nil,"没有可领取的邮件",nil,nil,11)
			end
		end
	end)
end
function View:OpenMailContent(data)
	print(">>"..sprinttb(data))
	for i = 1,self.view.openMail.ItemGroup.transform.childCount do
		self.view.openMail.ItemGroup.transform:GetChild(i-1).gameObject:SetActive(false)
	end
	local MailContent = data[1]
	self.view.openMail.desc[UnityEngine.UI.Text].text = MailContent.content
	self.view.openMail:SetActive(true)
	self.view.openMail.getBtn[UnityEngine.UI.Button].interactable = true
	for i = 1,#MailContent.item do
		local ItemClone = nil
		if self.view.openMail.ItemGroup.transform.childCount-1 < i then
			ItemClone = CS.UnityEngine.GameObject.Instantiate(self.view.openMail.ItemGroup.item.gameObject,self.view.openMail.ItemGroup.transform)
		else
			ItemClone = self.view.openMail.ItemGroup.transform:GetChild(i)
		end
		ItemClone.gameObject:SetActive(true)
		local ItemCloneView = SGK.UIReference.Setup(ItemClone)
		ItemCloneView.ItemCount[UI.Text].text = "x"..MailContent.item[i][3]
		local ItemIconView = nil
		if ItemCloneView.pos.transform.childCount == 0 then
			ItemIconView = IconFrameHelper.Item({id = MailContent.item[i][2],type = MailContent.item[i][1]},ItemCloneView.pos, {showDetail = true})
			ItemIconView.transform.localScale = Vector3(0.6,0.6,0.6)
		else
			local ItemIconClone = ItemCloneView.pos.transform:GetChild(0)
			ItemIconView = SGK.UIReference.Setup(ItemIconClone)
			IconFrameHelper.UpdateItem({id = MailContent.item[i][2],type = MailContent.item[i][1]},ItemIconView, {showDetail = true})
		end
  --       ItemIconView[SGK.newItemIcon]:SetInfo(ItemHelper.Get(MailContent.item[i][1],MailContent.item[i][2],nil,0))--MailContent.item[i][3]))
	end
	self.view.openMail[CS.UGUIClickEventListener].onClick = (function( ... )
		self:OpenNextMailContent(MailContent)
	end)
	self.view.openMail.getBtn[CS.UGUIClickEventListener].onClick = (function( ... )
		--读取or领取 邮件
		--NetworkService.Send(5019,{nil,MailContent.id})
		if self.view.openMail.getBtn[UnityEngine.UI.Button].interactable then
			self.view.openMail.getBtn[UnityEngine.UI.Button].interactable = false
			if self.Click_Mail_data.type == 100 then
				if FriendModule.GetFriend_receive_give_count() < FriendModule.GetFriendConf().get_limit then
					MailModule.GetFrinedAttachment(self.Click_Mail_data.fromid,self.Click_Mail_data.key)
				else
					showDlgError(nil,"每天最多可领取"..FriendModule.GetFriendConf().get_limit.."个好友赠送的时之力，请明天再来吧~")
				end
			elseif self.Click_Mail_data.type == 101 then
				if self.Click_Mail_data.fun then
					self.Click_Mail_data.fun(self.Click_Mail_data.id,2,self.Click_Mail_data.data)--领取
				end
			else
				MailModule.GetAttachment(MailContent.id)
			end
			self:OpenNextMailContent(MailContent)
		end
	end)
end

function View:OpenNextMailContent(data)
	local MailContent = data
	self.view.openMail.gameObject:SetActive(false)
	table.remove(MailContent,1)
	if #MailContent > 0 then
		self:OpenMailContent(MailContent)
	end
end

function View:listEvent()
	return {
		"Mail_INFO_CHANGE",
		"MAIL_GET_RESPOND",
		"MAIL_MARK_RESPOND",
		"Mail_Delete_Succeed",
	}
end

function View:onEvent(event,data)
	if event == "Mail_INFO_CHANGE" then
		--刚打开初始化or增加新邮件
		self.MailData = MailModule.GetManager()
		self.nguiDragIconScript.DataCount =#self.MailData--初始化数量
		self.view.tips:SetActive(#self.MailData == 0)
	elseif event == "MAIL_GET_RESPOND" then
		self:OpenMailContent(data.data)
	elseif event == "MAIL_MARK_RESPOND" then
		--已读or已领取刷新
		self.MailData = MailModule.GetManager()
		self.nguiDragIconScript:ItemRef()
	elseif event == "Mail_Delete_Succeed" then
		self.view.openMail:SetActive(false)
	end
end
return View