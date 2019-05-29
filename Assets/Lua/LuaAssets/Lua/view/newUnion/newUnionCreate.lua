local itemModule=require "module.ItemModule"
local TipCfg = require "config.TipConfig"
local ItemHelper = require "utils.ItemHelper"
local unionConfig = require "config.unionConfig"
local unionModule = require "module.unionModule"

local newUnionCreate = {}

function newUnionCreate:initData()

end

function newUnionCreate:initUi()
    self.view = CS.SGK.UIReference.Setup(self.gameObject)
    CS.UGUIClickEventListener.Get(self.view.root.closeBtn.gameObject).onClick = function()
        DialogStack.Pop()
    end
    CS.UGUIClickEventListener.Get(self.view.root.cancelBtn.gameObject).onClick = function()
        DialogStack.Pop()
    end
    CS.UGUIClickEventListener.Get(self.view.mask.gameObject, true).onClick = function()
        DialogStack.Pop()
    end
    self:initLabel()
    self:initCreateBtn()
    self:initCost()
end

function newUnionCreate:initCost()
    self.view.root.costNode.count[UI.Text].text = tostring(TipCfg.GetConsumeConfig(4).item_value)
    local item = ItemHelper.Get(TipCfg.GetConsumeConfig(4).type, TipCfg.GetConsumeConfig(4).item_id)
    self.view.root.costNode.icon[UI.Image]:LoadSprite("icon/" ..item.icon.."_small")
end

function newUnionCreate:initCreateBtn()
    CS.UGUIClickEventListener.Get(self.view.root.createBtn.gameObject).onClick = function()
        if self.nameLab.text == "" then
            showDlgError(nil, "请输入要创建的公会名")
            return
        end
        if GetUtf8Len(self.nameLab.text) > 12 then
            showDlgError(nil, "公会名字过长")
            return
        end
        if GetUtf8Len(self.nameLab.text) < 3 then
            showDlgError(nil, "公会名字过短")
            return
        end
        if GetUtf8Len(self.descLab.text) > 80 then
            showDlgError(nil, "公会宣言过长")
            return
        end
        if itemModule.GetItemCount(TipCfg.GetConsumeConfig(4).item_id) < TipCfg.GetConsumeConfig(4).item_value then
            showDlgError(nil, "资源不足")
            return
        end
        unionModule.SetUnionDesc(self.descLab.text)
        unionModule.Create(self.nameLab.text, 1)
    end
end

function newUnionCreate:initLabel()
    self.nameLab = self.view.root.nameNode.InputField[UI.InputField]
    self.descLab = self.view.root.descNode.InputField[UI.InputField]
    self.nameLab.onValueChanged:AddListener(function()
        if GetUtf8Len(self.nameLab.text) > 12 then
            self.view.root.nameNode.textSize[UI.Text].text = "<color=#FF0000>"..GetUtf8Len(self.nameLab.text).."</color>".."/".."12"
        else
            self.view.root.nameNode.textSize[UI.Text].text = GetUtf8Len(self.nameLab.text).."/".."12"
        end
    end)
    self.descLab.onValueChanged:AddListener(function()
        if GetUtf8Len(self.descLab.text) > 80 then
            self.view.root.descNode.textSize[UI.Text].text = "<color=#FF0000>"..GetUtf8Len(self.descLab.text).."</color>".."/".."80"
        else
            self.view.root.descNode.textSize[UI.Text].text = GetUtf8Len(self.descLab.text).."/".."80"
        end
    end)
end

function newUnionCreate:Start()
    self:initData()
    self:initUi()
end

function newUnionCreate:listEvent()
    return {
        "LOCAL_CREATE_UOION",
    }
end

function newUnionCreate:onEvent(event, data)
    if event == "LOCAL_CREATE_UOION" then
        DialogStack.Pop()
    end
end

function newUnionCreate:deActive()
	utils.SGKTools.PlayDestroyAnim(self.gameObject)
	return true;
end

return newUnionCreate
