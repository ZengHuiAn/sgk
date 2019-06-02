local newUnionNoticeEdit = {}

function newUnionNoticeEdit:initData(data)
    self.idx = 1
    self.descInfo = ""
    self.noticeInfo = ""
    if data then
        self.idx = data.idx
        self.descInfo = data.desc or ""
        self.noticeInfo = data.notice or ""
    end
end

function newUnionNoticeEdit:initTop()
    if self.idx == 1 then
        self.view.root.bg.name[UI.Text].text = SGK.Localize:getInstance():getValue("juntuan_gonggao_02")
        self.view.root.bg.Text[UI.Text].text = SGK.Localize:getInstance():getValue("juntuan_gonggao_01")
    else
        self.view.root.bg.name[UI.Text].text = SGK.Localize:getInstance():getValue("juntuan_xuanyan_01")
        self.view.root.bg.Text[UI.Text].text = SGK.Localize:getInstance():getValue("juntuan_xuanyan_02")
    end
    self.desc = self.view.root.InputField[UI.InputField]
    self.desc.onValueChanged:AddListener(function()
        if GetUtf8Len(self.desc.text) > 80 then
            self.view.root.textSize[UI.Text].text = "<color=#FF0000>"..GetUtf8Len(self.desc.text).."</color>".."/".."80"
        else
            self.view.root.textSize[UI.Text].text = GetUtf8Len(self.desc.text).."/".."80"
        end
    end)
    if self.idx == 1 then
        self.desc.text = self.descInfo
    else
        self.desc.text = self.noticeInfo
    end

    CS.UGUIClickEventListener.Get(self.view.root.saveBtn.gameObject).onClick = function()
        if self.desc.text == "" then
            showDlgError(nil, SGK.Localize:getInstance():getValue("tips_xiugaichenggong_02"))
            return
        end
        if GetUtf8Len(self.desc.text) > 80 then
            showDlgError(nil, SGK.Localize:getInstance():getValue("tips_zishu_01"))
            return
        end
        if self.idx == 1 then
            module.unionModule.SetDesc(self.desc.text)
        else
            module.unionModule.SetNotice(self.desc.text)
        end
    end
end

function newUnionNoticeEdit:initUi()
    self.view = CS.SGK.UIReference.Setup(self.gameObject)
    CS.UGUIClickEventListener.Get(self.view.root.closeBtn.gameObject).onClick = function()
        DialogStack.Pop()
    end
    self:initTop()
end

function newUnionNoticeEdit:Start(data)
    self:initData(data)
    self:initUi()
end

function newUnionNoticeEdit:listEvent()
    return {
        "LOCAL_UNION_NOTICE_CHANGE",
    }
end

function newUnionNoticeEdit:onEvent(event, data)
    if event == "LOCAL_UNION_NOTICE_CHANGE" then
        showDlgError(nil, SGK.Localize:getInstance():getValue("tips_xiugaichenggong_01"))
        DialogStack.Pop()
    end
end

function newUnionNoticeEdit:deActive()
	utils.SGKTools.PlayDestroyAnim(self.gameObject)
	return true;
end


return newUnionNoticeEdit
