local View = {}

function View:Start(data)
    self.selected_tab=data and data[1] or self.savedValues.SelectedPlayerInfoMainTab or 1
    self.InfoTab={}
    self.InfoTab[self.selected_tab]=data and data[2] or self.savedValues.SelectedPlayerInfoSubSelect or 1

    self.SelectId=data and data[3] or self.savedValues.SelectId

    self:initUi()
end

--local nameTextTab={"信息","形象"}
function View:initUi()
    self.root=CS.SGK.UIReference.Setup(self.gameObject)
    self.view =self.root.view
    self.view.Title[UI.Text].text=SGK.Localize:getInstance():getValue("biaoti_gerenxinxi_01")
    
    self.itemNode = self.view.Content.itemNode
    self.itemNode.newPlayInfo.gameObject:SetActive(false)
    self.itemNode.newQImageInfo.gameObject:SetActive(false)

    self.nowSelectItem =self.selected_tab==1 and self.itemNode.newPlayInfo or self.itemNode.newQImageInfo
    for i = 1, 2 do
        self.view.Content.topTab[i+1][UI.Toggle].isOn=i==self.selected_tab 
        self.view.Content.topTab[i+1].SelectArrow:SetActive(i==self.selected_tab)
        --self.view.Content.topTab[i].Text[UI.Text].text=tostring(nameTextTab[i])---{[i]={false,1},[2]={false,1}}
    end
    self.nowSelectItem.gameObject:SetActive(true)
    self.nowSelectItem[SGK.LuaBehaviour]:Call("Init",self.InfoTab[self.selected_tab],self.SelectId)

    self:initTopTab()
    self:initCloseBtn()
end

function View:initTopTab()
    self.toggleGroup = self.view.Content.topTab[UI.ToggleGroup]
    
    for i = 1, 2 do
        local _view = self.view.Content.topTab[i+1]
        self.InfoTab[i]=self.InfoTab[i] or 1

        CS.UGUIClickEventListener.Get(_view.gameObject,true).onClick = function()
            if self.nowSelectItem then
                self.nowSelectItem.gameObject:SetActive(false)
            end
            self.view.Content.topTab[self.selected_tab+1].SelectArrow:SetActive(false)
            self.view.Content.topTab[i+1].SelectArrow:SetActive(true)
            self.selected_tab=i

            self.nowSelectItem = i==1 and self.itemNode.newPlayInfo or self.itemNode.newQImageInfo
            self.nowSelectItem.gameObject:SetActive(true)
            self.nowSelectItem[SGK.LuaBehaviour]:Call("Init",self.InfoTab[self.selected_tab],self.SelectId)
        end
    end
end

function View:OnDestroy( ... )
    self.savedValues.SelectedPlayerInfoMainTab=self.selected_tab;
    self.savedValues.SelectedPlayerInfoSubSelect=self.InfoTab[self.selected_tab];
    self.savedValues.SelectId=self.SelectId
    DispatchEvent("DESTROY_QPLAYER_NODE");
end

function View:initCloseBtn()
    CS.UGUIClickEventListener.Get(self.view.closeBtn.gameObject).onClick = function()
        DialogStack.Pop()
    end
    CS.UGUIClickEventListener.Get(self.root.mask.gameObject,true).onClick = function()
        DialogStack.Pop()
    end
end

function View:listEvent()
    return {
        "PLAYER_INFO_IDX_CHANGE",--角色信息TabIdx
    }
end

local ItemIdxTabType={1,73,74,99,76}
function View:onEvent(event,data)
    if event == "PLAYER_INFO_IDX_CHANGE" then
        self.InfoTab[self.selected_tab]=data and data[1]
        for i=1,#ItemIdxTabType do
            if ItemIdxTabType[i]==data[1] then
                self.SelectId=data and data[2] and data[2][i]
                break
            end
        end
        
    end
end


return View