local equipModule = require "module.equipmentModule"
local Decompose = {}

function Decompose:initData(data)
    if data then
        self.uuid = data.uuid
    end
    self.cfg = equipModule.GetByUUID(self.uuid or 0)
end

function Decompose:initBtn()
    CS.UGUIClickEventListener.Get(self.view.root.closeBtn.gameObject).onClick = function()
        DialogStack.Pop()
    end
    CS.UGUIClickEventListener.Get(self.view.root.cancelBtn.gameObject).onClick = function()
        DialogStack.Pop()
    end
    CS.UGUIClickEventListener.Get(self.view.root.decomposeBtn.gameObject).onClick = function()
        if self.uuid and module.equipmentModule.GetByUUID(self.uuid) then
            module.equipmentModule.Decompose(self.uuid)
        else
            showDlgError(nil, "装备不存在")
        end
    end
end

function Decompose:initIcon()
    utils.IconFrameHelper.Create(self.view.root.newEquipIcon, {uuid = self.uuid})
end

function Decompose:initUi()
    self.view = CS.SGK.UIReference.Setup(self.gameObject)
    self:initBtn()
    self:initIcon()
end

function Decompose:Start(data)
    self:initData(data)
    self:initUi()
end

function Decompose:onEvent(event,data)
    if event == "LOCAL_DECOMPOSE_OK" then
        DispatchEvent("LOCAL_DECOMPOSE_OK_",self.uuid)
        DialogStack.Pop()
    end
end

function Decompose:listEvent()
	return {
    	"LOCAL_DECOMPOSE_OK",
    }
end

return Decompose
