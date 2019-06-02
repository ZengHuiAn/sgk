local dailyTaskBox = {}

function dailyTaskBox:Start(data)
    self:initData(data)
    self:initUi()
end

function dailyTaskBox:initData(data)
    self.data = data or {}
end

function dailyTaskBox:initUi()
    self.view = CS.SGK.UIReference.Setup(self.gameObject)
    CS.UGUIClickEventListener.Get(self.view.mask.gameObject, true).onClick = function()
        DialogStack.Pop()
    end
    CS.UGUIClickEventListener.Get(self.view.root.closeBtn.gameObject).onClick = function()
        DialogStack.Pop()
    end
    self.view.root.bg.name[UI.Text].text = self.data.textName or ""
    for i = 1, #self.view.root.itemList do
        local _view = self.view.root.itemList[i]
        _view:SetActive(self.data.itemTab[i] and true)
        if _view.activeSelf then
            utils.IconFrameHelper.Create(_view, {type = self.data.itemTab[i].type, id = self.data.itemTab[i].id, count = self.data.itemTab[i].value, showDetail = true})
        end
    end
end

return dailyTaskBox
