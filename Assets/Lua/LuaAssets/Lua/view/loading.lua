local LoadingView = {}
function LoadingView:Start()
	local ref = self.gameObject:GetComponent(typeof(CS.SGK.UIReference));
	self.progressBar = ref:Get("progress", typeof(CS.UnityEngine.UI.Slider));
	self.messageLabel = ref:Get("message", typeof(CS.UnityEngine.UI.Text));
	self.loading = ref:Get("LoadingView");
	self.DlgErrornum = 0
	self.ErrorView = nil
	self.Itemnum = 0
	self.ItemView = nil
    self.showDlgMsgTab = {}
    self.showDlgMsgList = {}--提示框
    self.showDlgMsgView = nil
    self.capacityChangeView = nil

    local BG = ref:Get("BG", typeof(SGK.LuaBehaviour));
    if BG then
        BG.enabled = true;
    end
end

function LoadingView:Update()
    if self.showDlgMsgTab then
        for k,v in pairs(self.showDlgMsgTab) do
            if v and v.item and v.nextTime and v.cancelText then
                if v.nextTime > module.Time.now() then
                    v.cancelText.text = v.desc.."("..math.ceil(v.nextTime - module.Time.now())..")"
                else
                    if v.fun then
                        v.fun()
                    end
                    self:loadShowDlgMsg(v.item)
                    self.showDlgMsgTab[k] = nil
                end
            end
        end
    end
end

function LoadingView:showDlgMsg(data)
    local tempObj = SGK.ResourcesManager.Load("prefabs/base/ShowDlgFrame.prefab")
    local obj = nil;
    local NGUIRoot = UnityEngine.GameObject.FindWithTag("UITopRoot")
    if NGUIRoot then
        obj = CS.UnityEngine.GameObject.Instantiate(tempObj, NGUIRoot.gameObject.transform)
    elseif UnityEngine.GameObject.FindWithTag("UGUIRootTop") then
        obj = CS.UnityEngine.GameObject.Instantiate(tempObj,UnityEngine.GameObject.FindWithTag("UGUIRootTop").gameObject.transform)
    elseif UnityEngine.GameObject.FindWithTag("UGUIRoot") then
        obj = CS.UnityEngine.GameObject.Instantiate(tempObj,UnityEngine.GameObject.FindWithTag("UGUIRoot").gameObject.transform)
    else
        obj = CS.UnityEngine.GameObject.Instantiate(tempObj)
    end
    local TipsView = CS.SGK.UIReference.Setup(obj)
    self.showDlgMsgView = TipsView
    TipsView.Dialog.Content.confirmBtn.gameObject:SetActive(data.confirm ~= nil)
    TipsView.Dialog.Content.cancelBtn.gameObject:SetActive(data.cancel ~= nil)
    if data.cancel == nil then
        TipsView.Dialog.Content.confirmBtn.gameObject.transform.localPosition = Vector3(0,-90,0)
    else
        TipsView.Dialog.Content.confirmBtn.gameObject.transform.localPosition = Vector3(178,-90,0)
    end
    TipsView.Dialog.Content.confirmBtn[CS.UGUIClickEventListener].onClick = (function ()
        data.confirm()
        if data.time then
            self.showDlgMsgTab[TipsView] = nil
        end
        self:loadShowDlgMsg(TipsView)
    end)
    TipsView.Dialog.Content.cancelBtn[CS.UGUIClickEventListener].onClick = (function ()
        data.cancel()
        if data.time then
            self.showDlgMsgTab[TipsView] = nil
        end
        self:loadShowDlgMsg(TipsView)
    end)
    TipsView.Dialog.Close[CS.UGUIClickEventListener].onClick = (function ()
        -- if data.cancel then
        --     data.cancel()
        -- elseif data.confirm then
        --     data.confirm()
        -- end
        if not data.NotExit then
            if data.time then
                self.showDlgMsgTab[TipsView] = nil
            end
            self:loadShowDlgMsg(TipsView)
        end
    end)
    TipsView.mask[CS.UGUIClickEventListener].onClick = (function ()
        if not data.NotExit then
            if data.time then
                self.showDlgMsgTab[TipsView] = nil
            end
            self:loadShowDlgMsg(TipsView)
        end
    end)
    if data.desc then
        TipsView.Dialog.Content.desc[UI.Text].text = data.desc
        TipsView.Dialog.Content.desc.gameObject:SetActive(true)
    end
    TipsView.Dialog.Content.describe[UI.Text].alignment = data.alignment ~= nil and data.alignment or UnityEngine.TextAnchor.MiddleCenter
    TipsView.Dialog.Content.confirmBtn.confirmBtnLab[UnityEngine.UI.Text].text = data.txtConfirm ~= nil and data.txtConfirm or "确定"
    TipsView.Dialog.Content.cancelBtn.cancelBtnLab[UnityEngine.UI.Text].text = data.txtCancel ~= nil and data.txtCancel or "取消"
    TipsView.Dialog.Content.describe[UnityEngine.UI.Text].text = data.msg ~= nil and data.msg or ""
    TipsView.Dialog.Title[UI.Text].text = data.title ~= nil and utils.SGKTools.get_title_frame(data.title) or utils.SGKTools.get_title_frame("提示")
    if data.confirmInfo then
        TipsView.Dialog.Content.confirmInfo:SetActive(true)
        TipsView.Dialog.Content.confirmInfo[UI.Text].text = data.confirmInfo
    end

    if data.time and data.time > 0 then
        self.showDlgMsgTab[TipsView] = {
            item = TipsView,
            nextTime = module.Time.now() + data.time,
            cancelText = TipsView.Dialog.Content.cancelBtn.cancelBtnLab[UnityEngine.UI.Text],
            fun = data.cancel,
            desc = TipsView.Dialog.Content.cancelBtn.cancelBtnLab[UnityEngine.UI.Text].text
        }
        if not data.cancel then
            self.showDlgMsgTab[TipsView].cancelText = TipsView.Dialog.Content.confirmBtn.confirmBtnLab[UnityEngine.UI.Text]
            self.showDlgMsgTab[TipsView].desc = TipsView.Dialog.Content.confirmBtn.confirmBtnLab[UnityEngine.UI.Text].text
            self.showDlgMsgTab[TipsView].fun = data.confirm
        end
    end
    return obj
end

function LoadingView:showDlgError(parent,msg,type)
    parent = nil
    if utils.SGKTools.GameObject_null(self.ErrorView) then
        local tempObj = SGK.ResourcesManager.Load("prefabs/base/ErrorTipsFrame.prefab")
        local obj = nil;
        if utils.SGKTools.GameObject_null(parent) == false then
            obj = CS.UnityEngine.GameObject.Instantiate(tempObj, parent.gameObject.transform)
        else
            local NGUIRoot = UnityEngine.GameObject.FindWithTag("UITopRoot")
            if NGUIRoot then
                 obj = CS.UnityEngine.GameObject.Instantiate(tempObj, NGUIRoot.gameObject.transform)
            elseif UnityEngine.GameObject.FindWithTag("UGUIRootTop") then
                obj = CS.UnityEngine.GameObject.Instantiate(tempObj,UnityEngine.GameObject.FindWithTag("UGUIRootTop").gameObject.transform)
            elseif UnityEngine.GameObject.FindWithTag("UGUIRoot") then
                obj = CS.UnityEngine.GameObject.Instantiate(tempObj,UnityEngine.GameObject.FindWithTag("UGUIRoot").gameObject.transform)
            else
                obj = CS.UnityEngine.GameObject.Instantiate(tempObj)
            end
        end
        self.ErrorView = CS.SGK.UIReference.Setup(obj)
    end
    self.DlgErrornum = self.DlgErrornum + 1
    self.ErrorView.Group[1][CS.UGUISpriteSelector].index = type or 0
    self.ErrorView.Group[1].desc[UnityEngine.UI.Text].text = msg
    --print(self.ErrorView.Group[1].desc[UnityEngine.RectTransform].sizeDelta.y)
    --self.ErrorView.Group[1][UnityEngine.RectTransform].sizeDelta = CS.UnityEngine.Vector2(685,30 + self.ErrorView.Group[1].desc[UnityEngine.RectTransform].sizeDelta.y)
    local descObj = CS.UnityEngine.GameObject.Instantiate(self.ErrorView.Group[1].gameObject, self.ErrorView.Group.gameObject.transform)
    local descView = CS.SGK.UIReference.Setup(descObj)
    descView:SetActive(true)
    descView[UnityEngine.CanvasGroup]:DOFade(0,1):OnComplete(function( ... )

        CS.UnityEngine.GameObject.Destroy(descObj)
        self.DlgErrornum = self.DlgErrornum -1
        if self.DlgErrornum == 0 then
            CS.UnityEngine.GameObject.Destroy(self.ErrorView.gameObject)
            self.ErrorView = nil
        end
    end):SetDelay(2)
end

local curr_Id_List = {} --该次获得物品列表
local ItemViewStatus = nil
function LoadingView:CreateGetItemTips(id,count,Type,uuid,fun,flag)
    -- ERROR_LOG("=====",self.ItemView,id,count,Type,uuid,fun,flag)
    uuid = uuid ~=0 and uuid
    fun = fun ~=0 and fun
    if self.ItemView then
        self:GetItemTips(id,count,Type,uuid,fun,flag)
        return
    end

    assert(self.ItemView == nil);
    curr_Id_List = {}
    if self.item_tips_queue then
        table.insert(self.item_tips_queue, {id,count,Type,uuid,fun});
        return;
    end

    self.item_tips_queue = {};
    table.insert(self.item_tips_queue, {id,count,Type,uuid,fun});

    SGK.ResourcesManager.LoadAsync(self.gameObject:GetComponent(typeof(SGK.LuaBehaviour)), "prefabs/Tips/GetAndFinishTip.prefab", function(tempObj)
        if not tempObj then
            OperationQueueNext();
            return;
        end

        local _item_tips_queue={}
        for k,v in pairs(self.item_tips_queue) do
            _item_tips_queue[k]=v
        end
        self.item_tips_queue = nil;

        local obj = nil
        if utils.SceneStack.CurrentSceneName() == 'battle' then
            obj = CS.UnityEngine.GameObject.Instantiate(tempObj,UnityEngine.GameObject.FindWithTag("UGUIRoot").gameObject.transform)
        else
            if UnityEngine.GameObject.FindWithTag("UITopRoot") then
                obj = CS.UnityEngine.GameObject.Instantiate(tempObj,UnityEngine.GameObject.FindWithTag("UITopRoot").gameObject.transform)
            elseif UnityEngine.GameObject.FindWithTag("UGUIRootTop") then
                obj = CS.UnityEngine.GameObject.Instantiate(tempObj,UnityEngine.GameObject.FindWithTag("UGUIRootTop").gameObject.transform)
            elseif UnityEngine.GameObject.FindWithTag("UGUIRoot") then
                obj = CS.UnityEngine.GameObject.Instantiate(tempObj,UnityEngine.GameObject.FindWithTag("UGUIRoot").gameObject.transform)
            else
                obj = CS.UnityEngine.GameObject.Instantiate(tempObj)
            end
        end
        self.ItemView = CS.SGK.UIReference.Setup(obj)

        self.ItemView[SGK.LuaBehaviour]:Call("OnClearItemTip",function ()
                if fun then
                    fun()
                else
                    ERROR_LOG("fun is nil ")
                end
                self.ItemView = nil
                OperationQueueNext();
            end)

        CS.UGUIClickEventListener.Get(self.ItemView.Btns.SetBtn.gameObject).onClick = function (obj)
            if self.ItemView then
                self.ItemView[SGK.LuaBehaviour]:Call("SetItemClick")
            end
        end

        CS.UGUIClickEventListener.Get(self.ItemView.view.mask.gameObject).onClick = function (obj)
            if self.ItemView then
                self.ItemView[SGK.LuaBehaviour]:Call("GetItemClick")
            end
        end
        --屏蔽 恭喜获得界面 5秒自动关闭
        self.ItemView.tips:SetActive(false)
        -- local delay = 6
        -- for i=delay,1,-1 do
        --     self.ItemView.transform:DOScale(Vector3.one, i):OnComplete(function()
        --         self.ItemView.tips[UI.Text].text = string.format("%ss后关闭",delay-i)
        --     end)
        -- end
   
        -- self.ItemView.transform:DOScale(Vector3.one,delay):OnComplete(function()
        --     if not self.DontClose and self.ItemView then
        --         self.ItemView[SGK.LuaBehaviour]:Call("DestroyGetAndFinishTipItem")
        --     end
        -- end)

        self.ItemView.gameObject:SetActive(true)

        self.UpdateReward=false
        --self.DontClose=false
        for _,v in pairs(_item_tips_queue) do
            self:GetItemTips(v[1],v[2],v[3],v[4],v[5],v[6]);
        end
        ItemViewStatus = nil
    end)
end

local LocalItemList = {}
function LoadingView:GetItemTips(id,count,Type,uuid,fun,flag)
    -- ERROR_LOG(id,count,Type,uuid,fun,flag)
    if self.ItemView == nil then
        uuid = uuid or 0
        fun = fun or 0
        LocalItemList = LocalItemList or {}
        table.insert(LocalItemList,{id,count,Type,uuid,fun,flag})

        if ItemViewStatus == "loading" then
            return
        else
            ItemViewStatus = "loading"
            if LocalItemList[1] then
                local _id,_count,_Type,_uuid,_fun,_flag = table.unpack(LocalItemList[1])
                table.remove(LocalItemList,1)
                return OperationQueuePush(LoadingView.CreateGetItemTips, self,_id,_count,_Type,_uuid,_fun,_flag)
            end
        end
    else
        if LocalItemList[1] then
            local _id,_count,_Type,_uuid,_fun,_flag = table.unpack(LocalItemList[1])
            table.remove(LocalItemList,1)
            self:GetItemTips(_id,_count,_Type,_uuid,_fun,_flag)
        end
	end

    if id ==11000 then--角色经验变化
        self.ItemView.gameObject:SetActive(true)
        self.ItemView[SGK.LuaBehaviour]:Call("ShowCharacterExpChange",{count,Type})
        return
    end

    if not id and not count and not Type then--任务完成
        if self.ItemView then
            self.ItemView.gameObject:SetActive(true)
            self.ItemView[SGK.LuaBehaviour]:Call("ShowFinishQuestTextImage",nil)
        end
        return
    end

    if not self.UpdateReward then
        self.UpdateReward=true
        --self.DontClose=true
        self.ItemView[SGK.LuaBehaviour]:Call("ShowGetItemTextImage")
    end

    if Type==utils.ItemHelper.TYPE.HERO and count >=10 then
        self.ItemView[SGK.LuaBehaviour]:Call("ShowHeroToFrameTip",nil)
        Type=utils.ItemHelper.TYPE.ITEM
    end
    --特殊处理一次获得相同英雄
    if Type==utils.ItemHelper.TYPE.HERO and curr_Id_List[id] then
        id = id +10000
        count = 10
        self.ItemView[SGK.LuaBehaviour]:Call("ShowHeroToFrameTip",nil)
        Type=utils.ItemHelper.TYPE.ITEM
    end
    curr_Id_List[id] = true



    self.ItemView[SGK.LuaBehaviour]:Call("UpdateShowItem",Type,id,count,uuid)
end

function LoadingView:loadShowDlgMsg(view)
    if view ~= nil then
        CS.UnityEngine.GameObject.Destroy(view.gameObject)
        self.showDlgMsgView = nil
    end
    if self.showDlgMsgView == nil and #self.showDlgMsgList > 0 then
        self:showDlgMsg(self.showDlgMsgList[1])
        table.remove(self.showDlgMsgList,1)
    end
end

function LoadingView:OnClickIcon(item,tab)
    local parent = nil
    if UnityEngine.GameObject.FindWithTag("UITopRoot") then
        parent=UnityEngine.GameObject.FindWithTag("UITopRoot").gameObject
    elseif UnityEngine.GameObject.FindWithTag("UGUIRootTop") then
        parent=UnityEngine.GameObject.FindWithTag("UGUIRootTop").gameObject
    elseif UnityEngine.GameObject.FindWithTag("UGUIRoot") then
        parent=UnityEngine.GameObject.FindWithTag("UGUIRoot").gameObject
    end

    if item then
        local type = item.type--道具 41 其他
        if type == utils.ItemHelper.TYPE.HERO then
            if item.func and item.func~=0 then
                item.func()
            else
                utils.SGKTools.HeroShow(item.id)
            end
        elseif type == utils.ItemHelper.TYPE.SUIT then
            if item.func and item.func~=0 then
                item.func()
            else
                DialogStack.PushPrefStact("dataBox/suitsManualFrame", {suitId = item.id,hideSuits = true})
            end
        else
            if item.ItemType and item.ItemType~=0  then
                type=item.ItemType
            end
            if type== 0 then
                type=utils.ItemHelper.TYPE.EQUIPMENT
            elseif type== 1 then
                type= utils.ItemHelper.TYPE.INSCRIPTION
            end

            local _tab=setmetatable({InItemBag=tab[0],count=tab[1],type=type}, {__index=item})
            if item.func and item.func~=0 then
                item.func()
            else
                DialogStack.PushPrefStact("ItemDetailFrame",_tab,parent)
            end
        end
    else--头像点击
        if tab.func and tab.func~=0 then
            tab.func()
        else
            utils.SGKTools.HeroShow(tab.icon and tonumber(tab.icon) or 11000)
        end
    end
end

function LoadingView:showCapacityChange(from,to)
    -- print("战力变化", from,to)
    if from == to then
        return;
    end
    if SceneStack.GetBattleStatus() then
        return;
    end
    
    if self.capacityChangeView and not utils.SGKTools.GameObject_null(self.capacityChangeView.gameObject) and not utils.SGKTools.GameObject_null(self.capacityChangeView.rotateNum.gameObject) and self.capacityChangeView.rotateNum[SGK.RotateNumber] then
        self.capacityChangeView.rotateNum[SGK.RotateNumber]:Change(from, to);
    else
        local prefabs = SGK.ResourcesManager.Load("prefabs/base/CapacityTip.prefab")
        local obj = nil
        if UnityEngine.GameObject.FindWithTag("UGUITopRoot") then
            obj = CS.UnityEngine.GameObject.Instantiate(prefabs,UnityEngine.GameObject.FindWithTag("UGUITopRoot").gameObject.transform)
        elseif UnityEngine.GameObject.FindWithTag("UGUIRootTop") then
            obj = CS.UnityEngine.GameObject.Instantiate(prefabs,UnityEngine.GameObject.FindWithTag("UGUIRootTop").gameObject.transform)
        elseif UnityEngine.GameObject.FindWithTag("UGUIRoot") then
            obj = CS.UnityEngine.GameObject.Instantiate(prefabs,UnityEngine.GameObject.FindWithTag("UGUIRoot").gameObject.transform)
        else
            obj = CS.UnityEngine.GameObject.Instantiate(prefabs);
        end
        self.capacityChangeView = CS.SGK.UIReference.Setup(obj);
        self.capacityChangeView[UnityEngine.CanvasGroup]:DOFade(1, 0.1);
        self.capacityChangeView.rotateNum[SGK.RotateNumber].OnComplete = function()
            self.capacityChangeView[UnityEngine.CanvasGroup]:DOFade(0, 0.1):SetDelay(0.5):OnComplete(function ()
                CS.UnityEngine.GameObject.Destroy(obj);
            end);
            self.capacityChangeView[UnityEngine.AudioSource]:Stop()
            self.capacityChangeView = nil;
        end
        self.capacityChangeView.rotateNum[SGK.RotateNumber]:Change(from, to);
        self.capacityChangeView[UnityEngine.AudioSource]:Play()
    end
end

function LoadingView:listEvent()
	return {
		"LOADING_PROGRESS_UPDATE",
		"LOADING_PROGRESS_MESSAGE",
		"LOADING_PROGRESS_DONE",
		"showDlgError",
        "showDlgMsg",
		"GetItemTips",
        "OnClickItemIcon",
        "showCapacityChange",
	}
end

function LoadingView:onEvent(event, percent, msg)
	if event == "LOADING_PROGRESS_UPDATE" then
        SceneService:SetPercent(percent, msg);
	elseif event == "LOADING_PROGRESS_MESSAGE" then
		-- self.loading.gameObject:SetActive(true)
		self.messageLabel.text = msg
	elseif event == "LOADING_PROGRESS_DONE" then
		self.progressBar.value = 1
		SceneService:FinishLoading();
	elseif event == "showDlgError" then
		self:showDlgError(percent[1],percent[2],percent[3])
	elseif event == "GetItemTips" then
		self:GetItemTips(percent[1],percent[2],percent[3],percent[4],msg,percent[5])
    elseif event == "showDlgMsg" then
        if percent then
            self.showDlgMsgList[#self.showDlgMsgList + 1] = percent
            self:loadShowDlgMsg()
        end
    elseif event == "OnClickItemIcon" then
        self:OnClickIcon(percent,msg)
    elseif event == "showCapacityChange" then
        self:showCapacityChange(percent[1], percent[2])
	end
end

function LoadingView:RELOAD()
    UnityEngine.PlayerPrefs.SetString("gameURL", "")
    SceneService:Reload();
end

return LoadingView;
