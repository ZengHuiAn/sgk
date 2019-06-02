local ItemHelper = require "utils.ItemHelper"
local GiftBoxPre = {}

function GiftBoxPre:initData(data)
    self.itemTab = {}
    self.textName = ""
    self.textDesc = ""
    self.fun = nil
    if data then
        self.itemTab = data.itemTab or {}
        self.textName = data.textName or ""
        self.textDesc = data.textDesc or ""
        self.fun = data.fun or nil
    end
end

function GiftBoxPre:initUi(data)
    self.view = CS.SGK.UIReference.Setup(self.gameObject)
    self.view.root.bg.name[UI.Text].text = self.textName
    self.view.root.bg.desc[UI.Text].text = self.textDesc
    CS.UGUIClickEventListener.Get(self.view.root.closeBtn.gameObject).onClick = function()
        CS.UnityEngine.GameObject.Destroy(self.gameObject)
    end
    if data and data.not_exit then
        self.view.root.closeBtn:SetActive(false)
    end
    -- CS.UGUIClickEventListener.Get(self.view.mask.gameObject, true).onClick = function()
    --     -- if data and data.not_exit then
    --     --     return
    --     -- end
    --     -- DialogStack.Pop()
    --     CS.UnityEngine.GameObject.Destroy(self.gameObject)
    -- end
    if self.fun then
        self.view.root.yBtn[CS.UGUIClickEventListener].onClick = function ( ... )
            self.fun()
            DispatchEvent("GiftBoxPre_to_FlyItem",self.itemTab)
            CS.UnityEngine.GameObject.Destroy(self.gameObject)
        end
        self.view.root.yBtn:SetActive(true)
        if data and data.interactable ~= nil then
            self.view.root.yBtn[CS.UGUIClickEventListener].interactable = data.interactable
        end
        self.view.root.bg.desc.transform.localPosition = Vector3(0,-85,0)
    else
        self.view.root.yBtn:SetActive(false)
    end
    self:initScrollView()
end

function GiftBoxPre:initScrollView()
    local _itemI = SGK.ResourcesManager.Load("prefabs/base/ItemIcon.prefab")
    local _item = CS.UnityEngine.GameObject.Instantiate(_itemI, self.view.gameObject.transform)
    local _rect = _item:GetComponent(typeof(UnityEngine.RectTransform))
    _rect.pivot = CS.UnityEngine.Vector2(0, 1)
    _item:AddComponent(typeof(CS.UIMultiScrollIndex))
    _item:SetActive(false)
    _item.transform.localScale = Vector3(0.8, 0.8, 0.8)

    self.scrollView = self.view.root.ScrollView[CS.UIMultiScroller]
    self.scrollView.itemPrefab = _item
    self.scrollView.RefreshIconCallback = function ( obj, idx )
        local _view = CS.SGK.UIReference.Setup(obj)
        local _tab = self.itemTab[idx+1]
        local _item = ItemHelper.Get(_tab.type, _tab.id, nil, _tab.count or 0)
        if _item then
            CS.UGUIClickEventListener.Get(_view.gameObject).onClick = function()

            end
            _view[SGK.ItemIcon]:SetInfo(_item, true)
            _view[SGK.ItemIcon].showDetail=true
            _view[SGK.ItemIcon].GetType = _tab.mark or 0
            --self.itemTab[idx+1]._view = _view
            local tran = _view.transform
            local vec3 = Vector3(tran.localPosition.x+96/2,tran.localPosition.y-96/2,tran.localPosition.z)
            tran.localPosition = vec3
            self.itemTab[idx+1].pos = {tran.position.x,tran.position.y,tran.position.z}
            obj.gameObject:SetActive(true)
        end
    end
    self.scrollView.DataCount = #self.itemTab
end

function GiftBoxPre:deActive()
	utils.SGKTools.PlayDestroyAnim(self.gameObject)
	return true;
end

function GiftBoxPre:Start(data)
    self:initData(data)
    self:initUi(data)
    module.guideModule.PlayByType(1300, 0.2)
end

return GiftBoxPre
