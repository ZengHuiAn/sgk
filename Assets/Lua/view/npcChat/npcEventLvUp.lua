local View = {}
function View:Start(data)
	self.view = SGK.UIReference.Setup(self.gameObject);
	CS.UGUIClickEventListener.Get(self.view.root.bg.commitBtn.gameObject).onClick = function ()
        DialogStack.Pop()
    end
    CS.UGUIClickEventListener.Get(self.view.root.mask.gameObject).onClick = function ()
        DialogStack.Pop()
    end
    self:initView(data)
end

function View:initView(data)
	self.allQuestCfg=module.QuestModule.GetCfg()
	self.friendCfg=data.data
	self.npcCfg=data.npcCfg
	local stageNum = module.ItemModule.GetItemCount(self.friendCfg.stage_item)
	local buffid = StringSplit(self.friendCfg.quest_buff,"|")
	self.view.root.bg.LvUpBefore[CS.UGUISpriteSelector].index=stageNum-1
	self.view.root.bg.LvUpAfter[CS.UGUISpriteSelector].index=stageNum
	for j,v in pairs(self.allQuestCfg) do
        if v.id ==tonumber(buffid[stageNum+1]) then
            self.view.root.bg.effect.Text[UI.Text].text=v.raw.name
            break
        end
    end
end

function View:OnDestory()

end

function View:listEvent()
    return {
    }
end

function View:onEvent(event,data)

end


return View;