local UserDefault = require "utils.UserDefault";
local System_Set_data=UserDefault.Load("System_Set_data");
local View = {}
function View:Start(data)
	self.view = CS.SGK.UIReference.Setup(self.gameObject)
	self.view.mask[CS.UGUIClickEventListener].onClick = function ( ... )
		UnityEngine.GameObject.Destroy(self.gameObject)
		UserDefault.Save()
	end
	self.view.close[CS.UGUIClickEventListener].onClick = function ( ... )
		UnityEngine.GameObject.Destroy(self.gameObject)
		UserDefault.Save()
	end
	self.ToggleToChatType = {[1] = 0,[2] = 1,[3] = 10,[4] = 3,[5] = 7,[6] = 100,[7] = -1}--toggle排序1系统2世界3组队4公会5队伍喊话6地图7等级相近
 	self.ChatTypeToToggle = {[0] = 1,[1] = 2,[7] = 5,[3] = 4,[10] = 3,[100] = 6,[-1] = 7}--数据排序0系统1世界6私聊3工会7队伍8加好友消息10组队喊话100地图
	for i = 1,6 do
		self.view.Group[i].Background[CS.UGUIClickEventListener].onClick = function ( ... )
			System_Set_data.FiltrationChat[self.ToggleToChatType[i]] = not System_Set_data.FiltrationChat[self.ToggleToChatType[i]]
			self.view.Group[i][UI.Toggle].isOn = System_Set_data.FiltrationChat[self.ToggleToChatType[i]]
		end
		if System_Set_data.FiltrationChat then
			self.view.Group[i][UI.Toggle].isOn = System_Set_data.FiltrationChat[self.ToggleToChatType[i]]
		end
	end
end
return View