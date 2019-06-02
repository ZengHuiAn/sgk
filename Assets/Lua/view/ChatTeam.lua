local ChatManager = require 'module.ChatModule'
local NetworkService = require "utils.NetworkService";
local View = {}
function View:Start(data)
	self.view = CS.SGK.UIReference.Setup(self.gameObject)
	self:ChatRef()
	self.view.SendBtn[CS.UGUIClickEventListener].onClick = (function ()
 		local desc = self.view.InputField[UnityEngine.UI.InputField].text
 		if #self:string_segmentation(desc) > 0 then
			module.TeamModule.ChatToTeam(desc, 0) --0普通1警告
 		end
 		self.view.InputField[UnityEngine.UI.InputField].text = ""
 	end)	
 	self.view.warningBtn[CS.UGUIClickEventListener].onClick = (function ()
 		local desc = self.view.InputField[UnityEngine.UI.InputField].text
		 if #self:string_segmentation(desc) > 0 then
			module.TeamModule.ChatToTeam(desc, 1) --0普通1警告
 		end
 		self.view.InputField[UnityEngine.UI.InputField].text = ""
 	end)

end
function View:ChatRef( ... )
	local channelName = {[0] = "系统",[1] = "世界",[6] = "私聊",[3] = "公会",[7] = "小队"}
	self.ChatData = ChatManager.GetChatDataTeam()
	local label = self.view.ScrollView.Viewport.Content.desc[UnityEngine.UI.Text];
	label.text = ""
	for i = 1,#self.ChatData do
		local desc = WordFilter.check(self.ChatData[i].message)
		label.text = label.text.."["..channelName[self.ChatData[i].channel].."]"..self.ChatData[i].fromname..":"..desc
		if i < #self.ChatData then
			label.text = label.text.."\n"
		end
	end
	self.view.ScrollView.Viewport.Content.gameObject.transform:DOScale(Vector3(1,1,1),0):SetDelay(0.5):OnComplete(function( ... )
		if self.view.ScrollView.Viewport.Content[UnityEngine.RectTransform].sizeDelta.y > self.view.ScrollView[UnityEngine.RectTransform].sizeDelta.y then
			local y = self.view.ScrollView.Viewport.Content[UnityEngine.RectTransform].sizeDelta.y - self.view.ScrollView[UnityEngine.RectTransform].sizeDelta.y
			self.view.ScrollView.Viewport.Content[UnityEngine.RectTransform].localPosition = Vector3(0,y,0)
		end
	end)
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
return View