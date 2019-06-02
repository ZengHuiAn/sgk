local QuestModule = require "module.QuestModule"
local NpcChatMoudle = require "module.NpcChatMoudle"
local ItemModule = require "module.ItemModule"

local View = {}
function View:Start(data)
	self.view = SGK.UIReference.Setup(self.gameObject);
	self.Data=data
	self.friendCfg=data.data
	self.npcCfg=data.npcCfg
	self.relation_value=nil
	self.needQuest=nil
	CS.UGUIClickEventListener.Get(self.view.root.close.gameObject).onClick = function ()
        --UnityEngine.GameObject.Destroy(self.gameObject)
        DialogStack.Pop()
    end
    CS.UGUIClickEventListener.Get(self.view.mask.gameObject).onClick = function ()
        --UnityEngine.GameObject.Destroy(self.gameObject)
        DialogStack.Pop()
    end
    --QuestModule.Accept(3160006)
    self.allQuestCfg=QuestModule.GetCfg()
    -- QuestModule.Finish(3161041)
    -- print("zoe npcEvent Getquest",sprinttb(QuestModule.Get(3161041)))
    self:InitUI()
end
function View:InitUI()
	self.relation_value = ItemModule.GetItemCount(self.friendCfg.arguments_item_id)
	--print("zoe 100000",ItemModule.GetItemCount(100000))
	local index=module.ItemModule.GetItemCount(self.friendCfg.stage_item)
	self.needQuest = StringSplit(self.friendCfg.quest_up,"|")
	self.questid=tonumber(self.needQuest[index+2])
	--print("zoe npcEvent",index,self.questid,sprinttb(self.needQuest))
	for i,v in pairs(self.allQuestCfg) do
 		--print("zoe npcEvent",self.needQuest[index+1])
	    if v.id == self.questid then
 	        print("zoe npcEvent",i,sprinttb(v))
 	        self.questCfg=v
 	    end
    end
    if self.questCfg and self.questCfg.type ~= 200 then
        -- if self.questCfg.type == 200 then
        --     return
        -- end
        self.view.root.ScrollView:SetActive(true)
        self.view.root.tip:SetActive(false)

        local _view=self.view.root.ScrollView.Viewport.Content
        _view[1].desc[UI.Text].text=self.questCfg.raw.name
        _view[1].reward.type1.Text[UI.Text].text="好感度升级事件"--"升级到"..self.questCfg.raw.desc1
        if self.relation_value >= self.questCfg.consume[1].value then
        	_view[1].yBtn[CS.UGUISpriteSelector].index=1
        	_view[1].yBtn.Text[UI.Text].text="前往"
        	CS.UGUIClickEventListener.Get(_view[1].yBtn.gameObject).onClick = function ()
                if self.questCfg.condition[1].type == 72 then
                    DialogStack.PushPrefStact("newrole/roleFramework",{heroid = self.npcCfg.npc_id,idx = 2})
                else
            	   DialogStack.PushPrefStact("newrole/roleFramework",{heroid = self.npcCfg.npc_id,idx = 1})
                end
        	end
            QuestModule.Accept(self.questid)
        	_view[1].mask.gameObject:SetActive(false)
        	if QuestModule.CanSubmit(self.questid) then --module.HeroModule.GetManager():Get(self.npcCfg.npc_id).level>=self.questCfg.condition[1].count then
        		--QuestModule.Accept(self.questid)
        		_view[1].yBtn[CS.UGUISpriteSelector].index=2
        		_view[1].yBtn.Text[UI.Text].text="完成"
        		CS.UGUIClickEventListener.Get(_view[1].yBtn.gameObject).onClick = function ()
        			--print("zoe2222222222",self.needQuest[index+1])
            		if QuestModule.Get(self.questid) then
            			--print("zoe1111111111")
            			QuestModule.Finish(self.questid)
            		end
        		end
        	end
        else
            _view[1].gameObject:SetActive(false)
        	_view[1].yBtn[CS.UGUISpriteSelector].index=0
        	_view[1].mask.gameObject:SetActive(true)
        	CS.UGUIClickEventListener.Get(_view[1].mask.gameObject).onClick = function ()
            	showDlgError(nil,"好感度未到达目标值")
        	end
            self.view.root.ScrollView:SetActive(false)
            self.view.root.tip:SetActive(true)
            self.view.root.tip.dialog.Text[UI.Text].text = SGK.Localize:getInstance():getValue("haogandu_tips_04")
        end
    else
        self.view.root.ScrollView:SetActive(false)
        self.view.root.tip:SetActive(true)
        self.view.root.tip.dialog.Text[UI.Text].text = SGK.Localize:getInstance():getValue("haogandu_tips_04")
    end
end

function View:OnDestory()

end

function View:listEvent()
    return {
    "QUEST_INFO_CHANGE",
    "HERO_INFO_CHANGE",
    }
end

function View:onEvent(event,data)
	if event == "QUEST_INFO_CHANGE" then
        if data.id == self.questid then
            if QuestModule.Get(self.questid) and QuestModule.Get(self.questid).status ==1 then
                print("zoe任务完成",sprinttb(data))
                DialogStack.PushPrefStact("npcChat/npcEventLvUp",{data=self.friendCfg,npcCfg=self.npcCfg})    
            end
            self.relation_value=nil
            self.needQuest=nil
            self:InitUI()
        end
		--print("zoe npcEvent",data,sprinttb(data))
    elseif event == "HERO_INFO_CHANGE" then
        self.relation_value=nil
        self.needQuest=nil
        self:InitUI()
	end
end


return View;