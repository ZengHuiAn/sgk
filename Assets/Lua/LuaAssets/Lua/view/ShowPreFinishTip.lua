local ItemHelper = require "utils.ItemHelper"
local ShowPreFinishTip = {}

function ShowPreFinishTip:Start(data)
    self:initData(data)
    self:initUi(data)
    module.guideModule.PlayByType(1300, 0.2)
end

function ShowPreFinishTip:initData(data)
    self.itemTab = {}
    self.fun = nil
    if data then
        self.itemTab = data.itemTab or {}
        self.fun = data.fun or nil
    end
end

function ShowPreFinishTip:initUi(data)
    self.root = CS.SGK.UIReference.Setup(self.gameObject)
    self.view = self.root.view

    if self.fun then
        self.view.GetBtn[CS.UGUIClickEventListener].onClick = function ( ... )
            self.fun()
            for i=1,#self.itemTab do
                self.itemTab[i].pos = {self.itemTab[i].view.transform.position.x,self.itemTab[i].view.transform.position.y,0}
            end

            DispatchEvent("GiftBoxPre_to_FlyItem",self.itemTab)
            CS.UnityEngine.GameObject.Destroy(self.gameObject)
        end
    end
    self:initView()
end

function ShowPreFinishTip:initView()
    local parent = self.view.Content
    local prefab = self.view.Content.IconFrame

    for i=1,#self.itemTab do
        local _view = utils.SGKTools.GetCopyUIItem(parent,prefab,i)
        local _tab = self.itemTab[i]
        self.itemTab[i].view = _view
        utils.IconFrameHelper.Create(_view,{type=_tab.type,id=_tab.id,count =_tab.count or 0,showDetail=true,showName =true});
    end
end

function ShowPreFinishTip:deActive()
	utils.SGKTools.PlayDestroyAnim(self.gameObject)
	return true;
end

return ShowPreFinishTip
