local Strongerdialog = {}

function Strongerdialog:Start(data)
    self:initData(data)
    self:initUi()
end

function Strongerdialog:initData(data)
    if data then
        self.item = data.item
        self.func = data.func
        self.title = data.title
        self.btnName = data.btnName
        self.info = data.info
        self.levelupExp = data.levelupExp
    end
end

function Strongerdialog:initUi()
    self.view = CS.SGK.UIReference.Setup(self.gameObject)
    CS.UGUIClickEventListener.Get(self.view.gameObject, true).onClick = function()
        DialogStack.Pop()
    end
    CS.UGUIClickEventListener.Get(self.view.title.close.gameObject).onClick = function()
        DialogStack.Pop()
    end
    CS.UGUIClickEventListener.Get(self.view.cancel.gameObject).onClick = function()
        DialogStack.Pop()
    end
    CS.UGUIClickEventListener.Get(self.view.confirm.gameObject).onClick = function()
        if self.func then
            self.func()
            DialogStack.Pop()
        else
            DialogStack.Pop()
        end
    end
    local _count = 1
    for i,v in ipairs(self.item or {}) do
        if v.value > 0 then
            self.view.cost[_count]:SetActive(true)
            --local _item = utils.ItemHelper.Get(v.type, v.id)
            utils.IconFrameHelper.Create(self.view.cost[_count], {id = v.id, type = v.type, showDetail = true, count = v.value})
            --self.view.cost[_count][SGK.newItemIcon]:SetInfo(_item, false, v.value)
            _count = _count + 1
        end
    end
    if self.levelupExp and #self.item < 1 then
        self.view.levelupExp[UI.Text].text = "溢出经验<color=#00A32AFF>"..self.levelupExp.."</color>点"
    end
    if self.title then
        self.view.title.name[UI.Text].text = self.title
    end
    if self.btnName then
        self.view.confirm.text[UI.Text].text = self.btnName
    end
    self.view.Text[UI.Text].text = self.info or ""
end

return Strongerdialog
