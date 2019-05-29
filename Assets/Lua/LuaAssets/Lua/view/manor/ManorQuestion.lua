local openLevel = require "config.openLevel"
local ChatManager = require 'module.ChatModule'
local Time = require "module.Time"

local View = {};
function View:Start(data)
	self.view = CS.SGK.UIReference.Setup(self.gameObject);
    self.npc_id = data and data.npc_id;
    self.quest_id = data and data.quest;
	self:InitData();
	self:InitView();
end

function View:InitData()
    self.riddle_cfg = module.ManorModule.GetManorRiddle(self.npc_id);
    -- local mapInfo = SceneStack.MapId("all");
    -- self.owner_pid = mapInfo.mapRoom or module.playerModule.GetSelfID();
    -- self.manager = module.ManorRandomQuestNPCModule.GetManager(self.owner_pid);
    -- self.manager:QueryNPC()
end

function View:InitView()
    self.view.Text[UI.Text].text = self.riddle_cfg.riddle;
    CS.UGUIClickEventListener.Get(self.view.BG.gameObject, true).onClick = function()
        CS.UnityEngine.GameObject.Destroy(self.gameObject);
    end
    CS.UGUIClickEventListener.Get(self.view.btn1.gameObject).onClick = function()
        self.view.help:SetActive(not self.view.help.activeSelf);
    end
    CS.UGUIClickEventListener.Get(self.view.btn2.gameObject).onClick = function()
        if self.view.InputField[UI.InputField].text == self.riddle_cfg.answer then
            module.ManorRandomQuestNPCModule.Interact(nil, self.npc_id, 0);
        else
            showDlgError(nil, "回答错误")
        end
    end
    CS.UGUIClickEventListener.Get(self.view.help.world.gameObject).onClick = function()
        local desc = string.format( "基地谜语求助：\n %s", self.riddle_cfg.riddle)
        local cd =  math.floor(Time.now() - ChatManager.GetChatMessageTime(1))
        if cd < 10 then
            showDlgError(nil,"您说话太快，请在"..(10 - cd).."秒后发送")
            return;
        end
        if openLevel.GetStatus(2801) then
            ChatManager.ChatMessageRequest(1, desc);
            ChatManager.SetChatMessageTime(1, Time.now());
        else
            showDlgError(nil, openLevel.GetCfg(2801).open_lev.."级后开启世界发言")
        end
    end
    CS.UGUIClickEventListener.Get(self.view.help.guild.gameObject).onClick = function()
        local desc = string.format( "基地谜语求助：\n %s", self.riddle_cfg.riddle)
        local cd =  math.floor(Time.now() - ChatManager.GetChatMessageTime(3))
        if cd < 10 then
            showDlgError(nil,"您说话太快，请在"..(10 - cd).."秒后发送")
            return;
        end
        if module.unionModule.Manage:GetUionId() == 0 then
            showDlgError(nil, "您需要先加入一个公会")
        else
            ChatManager.ChatMessageRequest(3, desc)
            ChatManager.SetChatMessageTime(3, Time.now())
        end
    end
    CS.UGUIClickEventListener.Get(self.view.help.friend.gameObject).onClick = function()
        local desc = string.format( "基地谜语求助：\n %s", self.riddle_cfg.riddle)
        DialogStack.Push('TeamInviteFrame', {tips = "已发送", callback = function (tempData, addData, isall, func)
            func();
            utils.NetworkService.Send(5009,{nil,tempData.pid,3,desc,""})
            ChatManager.SetManager({fromid = tempData.pid,fromname = tempData.name,title = desc},1,3)

        end});--,"UGUIRootTop"
    end
end

function View:listEvent()
	return {
		"QUEST_INFO_CHANGE",
	}
end

function View:onEvent(event, ...)
	print("onEvent", event, ...);
	if event == "QUEST_INFO_CHANGE"  then
        local quest = ...;
        if quest and quest.id == self.quest_id and quest.status == 0 then
            print("完成任务", self.quest_id)
            module.QuestModule.Submit(self.quest_id);
            CS.UnityEngine.GameObject.Destroy(self.gameObject);
        end
	end
end

return View;