local View = {}

function View:Start(data)
	self.view = SGK.UIReference.Setup(self.gameObject);
	self:initView(data)
end

function View:initView(data)
	self:initData(data)
	self:initSlider()
	self:initClick()
	self:UpView()
end

function View:initData(data)
	self.item_id = data.id
	self.maxNum = data.max
	print("zuidazhi",self.maxNum)
end

function View:initClick()
	CS.UGUIClickEventListener.Get(self.view.mask.gameObject).onClick = function ()
		utils.EventManager.getInstance():dispatch("CLOSE_ADD_COUNT")
		CS.UnityEngine.GameObject.Destroy(self.view.gameObject)
	end
	CS.UGUIClickEventListener.Get(self.view.addCount.subBtn.gameObject).onClick = function()
		if self.selectCountnum > 1 then
			self.selectCountnum = self.selectCountnum - 1
        	self.view.addCount.InputField.count[UI.Text].text = self.selectCountnum
        end
    end
    CS.UGUIClickEventListener.Get(self.view.addCount.addBtn.gameObject).onClick = function()
    	if self.selectCountnum < self.maxNum then
    		self.selectCountnum = self.selectCountnum +1 
        	self.view.addCount.InputField.count[UI.Text].text = self.selectCountnum
        end
    end
    CS.UGUIClickEventListener.Get(self.view.addCount.maxBtn.gameObject).onClick = function()
		self.selectCountnum = self.maxNum
        self.view.addCount.InputField.count[UI.Text].text = self.selectCountnum
    end	
	CS.UGUIClickEventListener.Get(self.view.addCount.confirmBtn.gameObject).onClick = function ()
		utils.EventManager.getInstance():dispatch("SET_ADD_COUNT",{id = self.item_id,count = self.selectCountnum})
		CS.UnityEngine.GameObject.Destroy(self.view.gameObject)
	end
end

function View:initSlider()
    self.selectCount = self.view.addCount.InputField.count[UI.Text].text
    self.selectCountnum = 1
end

function View:UpView()
	utils.IconFrameHelper.Create(self.view.addCount.icon.IconFrame,{type = 41, id = self.item_id, count = 0,showDetail = false})
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