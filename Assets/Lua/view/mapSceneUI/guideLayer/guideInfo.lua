local guideInfo = {}

function guideInfo:Start(data)
    self:initData(data)
    self:initUi()
end

function guideInfo:initData(data)
    self.questId = data.questId
end

function guideInfo:initUi()
    self.view = CS.SGK.UIReference.Setup(self.gameObject)
    self.quest = module.QuestModule.Get(self.questId)
    if self.quest then
        self.view.root.desc[UI.Text].text = self.quest.desc1
        if self.quest.icon ~= 0 then
            self.view.root.icon[UI.Image]:LoadSprite("guideLayer/"..self.quest.icon, function()
                self.view.root.icon[UI.Image]:SetNativeSize()
            end)
            self.view.root.icon:SetActive(true);
        else
            self.view.root.icon:SetActive(false);
        end
    end
    CS.UGUIClickEventListener.Get(self.view.mask.gameObject, true).onClick = function()
        DialogStack.Pop()
    end
end

return guideInfo
