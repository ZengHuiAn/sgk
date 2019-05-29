local View = {}

function View:Start(data)
	self.root = SGK.UIReference.Setup(self.gameObject);
	self.view = self.root.root
	self.idx = 1
	self.childCfg = {
        [1] = {name = "roleReborn/RoleReborn"},
        [2] = {name = "roleReborn/FragmentChange"},
    }
	self:initScrollView()
	DialogStack.PushPref("CurrencyChat",nil,self.root);
end

function View:initScrollView()
    for idx=0,1 do
        local obj = self.view.bottom.itemNode["item"..(idx+1)]
        local _view = CS.SGK.UIReference.Setup(obj)
        _view.Toggle1.namePng[CS.UGUISpriteSelector].index = idx
      	_view.Toggle1.namePng[UnityEngine.UI.Image]:SetNativeSize();
        _view.Toggle1[UI.Toggle].onValueChanged:RemoveAllListeners()
        _view.Toggle1[UI.Toggle].onValueChanged:AddListener(function(value)
            if value then
                self.view.bottom.image.transform:DOMove(Vector3(_view.Toggle1.transform.position.x, self.view.bottom.image.transform.position.y, self.view.bottom.image.transform.position.z), 0.2):SetEase(CS.DG.Tweening.Ease.OutBack)
            end
            _view.Toggle1.arr:SetActive(value)
        end)
        _view.Toggle1[UI.Toggle].isOn = ((idx + 1) == self.idx)
        CS.UGUIClickEventListener.Get(_view.Toggle1.gameObject).onClick = function()
        	if self.idx ~= idx + 1 then
	        	self.idx = idx + 1 
	            self.savedValues.idx = self.idx
	            self:showChilde(self.idx)
	        end
        end
        obj:SetActive(true)
    end
    local _obj = self.view.bottom.itemNode["item1"]
    if _obj then
        local _view = CS.SGK.UIReference.Setup(_obj)
        _view.Toggle1[UI.Toggle].isOn = true
        _view.Toggle1.arr:SetActive(true)
        self.view.bottom.image.transform.position = Vector3(_view.Toggle1.transform.position.x, self.view.bottom.image.transform.position.y, self.view.bottom.image.transform.position.z)
    end
    self:showChilde(self.idx)
end

function View:showChilde(idx)
	if self.view.childRoot.transform.childCount > 0 then
		CS.UnityEngine.GameObject.Destroy(self.view.childRoot.transform:GetChild(0).gameObject)
	end
	self.view.bg[CS.UGUISpriteSelector].index = idx - 1
	DialogStack.PushPref(self.childCfg[idx].name,nil,self.view.childRoot.gameObject)
end

function View:InitBottom()
	-- body
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