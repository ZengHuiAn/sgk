local ChatManager = require 'module.ChatModule'
local NetworkService = require "utils.NetworkService";
local TeamModule = require "module.TeamModule"
local View = {}
function View:Start(data)
	self.view = CS.SGK.UIReference.Setup(self.gameObject)
	self:ChatRef()
	self.view.SendBtn[CS.UGUIClickEventListener].onClick = (function ()
		if TeamModule.GetTeamInfo().id > 0 then
	 		local desc = self.view.InputField[UnityEngine.UI.InputField].text
	 		if #self:string_segmentation(desc) > 0 then
				module.TeamModule.ChatToTeam(desc, 0) --0普通1警告
			else
				showDlgError(nil,"消息内容不能为空")
	 		end
	 		self.view.InputField[UnityEngine.UI.InputField].text = ""
	 	else
	 		showDlgError(nil,"请先创建一个队伍")
	 	end
 	end)
 	self.view.close[CS.UGUIClickEventListener].onClick = (function ()
 		UnityEngine.GameObject.Destroy(self.gameObject)
 	end)
 	self.view.EmojiBtn[CS.UGUIClickEventListener].onClick = function ( ... )
 		self.view.mask:SetActive(true)
 	end
 	for i =1,#self.view.mask.bg do
 		self.view.mask.bg[i][CS.UGUIClickEventListener].onClick = function ( ... )
 			self.view.mask:SetActive(false)
 			self.view.EmojiBtn[UnityEngine.UI.Toggle].isOn = false
 			self.view.InputField[UnityEngine.UI.InputField].text = self.view.InputField[UnityEngine.UI.InputField].text.."[#"..i.."]"
 		end
 	end
 	self.view.mask[CS.UGUIClickEventListener].onClick = function ( ... )
 		self.view.mask:SetActive(false)
 	end
end
function View:ChatRef( ... )
	local channelName = {[0] = "系统",[1] = "世界",[6] = "私聊",[3] = "公会",[7] = "队伍",[8] = "好友",[10] = "组队"}
	self.ChatData = ChatManager.GetChatDataTeam()
	local label = self.view.Chatmask.desc[CS.InlineText];
	label.text = ""
	local list = {}
	for i = 1,#self.ChatData do
		if self.ChatData[i].channel == 7 then
			list[#list+1] = self.ChatData[i]
		end
	end
	for i = 1,#list do	
		local desc = WordFilter.check(list[i].message)
		label.text = label.text.."["..channelName[list[i].channel].."]"..list[i].fromname..":"..desc
		if i < #list then
			label.text = label.text.."\n"
		end
	end
end
function View:onEvent(event,data)
	if event == "Chat_INFO_CHANGE" then
		--聊天
		self:ChatRef()
	end
end
function View:listEvent()
	return {
	"Chat_INFO_CHANGE",
	}
end
function View:string_segmentation(str)
	--print(str)
    local len  = #str
    local left = 0
    local arr  = {0, 0xc0, 0xe0, 0xf0, 0xf8, 0xfc}
    local t = {}
    local start = 1
    local wordLen = 0
    while len ~= left do
        local tmp = string.byte(str, start)
        local i   = #arr
        while arr[i] do
            if tmp >= arr[i] then
                break
            end
            i = i - 1
        end
        wordLen = i + wordLen
        local tmpString = string.sub(str, start, wordLen)
        start = start + i
        left = left + i
        t[#t + 1] = tmpString
    end
    return t
end

function View:OnDestroy()
    module.RedDotModule.CloseRedDot(module.RedDotModule.Type.MainUITeam.MainUITeam)
end

return View