


local activeReward = {}
function activeReward:Start(data)
    self.view = CS.SGK.UIReference.Setup(self.gameObject)
    self:initData(data)
    self:initUi()
end

function activeReward:initData(data)
    if not data then
        return
    else
        self.data=data
    end
    self.giftItemTab = nil
end
function activeReward:initUi()
    CS.UGUIClickEventListener.Get(self.view.root.bg.closeBtn.gameObject).onClick = function()
        DialogStack.Pop()
    end
    self:initScrollView()
    self:upScrollView(self.data)
end

function activeReward:initScrollView()

    self.scrollView = self.view.root.ScrollView[CS.UIMultiScroller]
    self.scrollView.RefreshIconCallback = function ( obj, idx )
        local _view = CS.SGK.UIReference.Setup(obj)
        if not self.giftItemTab then
             return
         end
        local _tab = self.giftItemTab[idx+1]
        --ERROR_LOG("_tab======>>>",sprinttb(_tab))
        if not _tab then
             return
         end
         utils.IconFrameHelper.Create(_view.IconFrame, {id = _tab.id, type = _tab.type, count = _tab.value, showDetail = true})
        obj.gameObject:SetActive(true)
    end
end
function activeReward:upScrollView(data)
   --ERROR_LOG("data======>>>",sprinttb(data))
   if data.type or data.name then
        self.view.root.bg.name[UI.Text].text=data.name
        self.view.root.bg.Text[UI.Text].text="活动奖励"
        if not self.giftItemTab then
            self.giftItemTab = {}
        end
        for i,v in ipairs(data.data) do
            table.insert(self.giftItemTab, v)
        end
        if self.giftItemTab then
            self.scrollView.DataCount = #self.giftItemTab
        end
   else
        local _reward = data.data[1].cfg.reward
        if not self.giftItemTab then
            self.giftItemTab = {}
        end
        for i,v in ipairs(_reward) do
            table.insert(self.giftItemTab, v)
        end
        if self.giftItemTab then
            self.scrollView.DataCount = #self.giftItemTab
        end
   end
end


return activeReward