local unionDonation = {}

local setUrgentItem = {
    id = 90006,
    value = 100,
}

function unionDonation:Start()
    self:initData()
    self:initUi()
end

function unionDonation:initData()
    self.idx = 1
end

function unionDonation:initUi()
    self.view = CS.SGK.UIReference.Setup(self.gameObject)
    CS.UGUIClickEventListener.Get(self.view.root.bg.closeBtn.gameObject).onClick = function()
        DialogStack.Pop()
    end
    CS.UGUIClickEventListener.Get(self.view.mask.gameObject, true).onClick = function()
        DialogStack.Pop()
    end
    CS.UGUIClickEventListener.Get(self.view.root.helpBtn.gameObject).onClick = function()
        utils.SGKTools.ShowDlgHelp(SGK.Localize:getInstance():getValue("guild_techDonate_info2"))
    end
    self:initGroup()
    self:initScrollView()
    self:upShowType(1)
end

function unionDonation:initGroup()
    for i = 1, #self.view.root.group do
        local _view = self.view.root.group[i]
        _view[UI.Toggle].onValueChanged:AddListener(function (value)
            if not value then
                _view.Text[UI.Text].color = {r = 1, g = 1, b = 1, a = 1}
            else
                _view.Text[UI.Text].color = {r = 0, g = 0, b = 0, a = 1}
            end
        end)
        CS.UGUIClickEventListener.Get(_view.gameObject, true).onClick = function()
            if self.idx ~= i then
                self:upShowType(i)
            end
        end
    end
end

function unionDonation:upDonationInfo()
    self.donationListInfo = {}
    self.donationInfo = module.unionScienceModule.GetDonationInfo()
    if self.donationInfo.setUrgentCount>0 then
        self.view.root.group.Toggle2.Background.tip:SetActive(true)
        module.RedDotModule.PlayRedAnim(self.view.root.group.Toggle2.Background.tip)
    else
        self.view.root.group.Toggle2.Background.tip:SetActive(false)
    end

   -- ERROR_LOG("捐献信息",sprinttb(self.donationInfo))
    for k,v in pairs(module.unionScienceModule.GetDonationInfo().itemList) do
        table.insert(self.donationListInfo, v)
    end
end

function unionDonation:upShowType(idx)
    if idx then
        self.idx = idx
    end
    self:upDonationInfo()
    self.view.root.donationInfo:SetActive(self.idx == 1)
    self.view.root.settingInfo:SetActive(self.idx == 2)

    local sciene_lev = module.unionScienceModule.GetScienceInfo(13) and module.unionScienceModule.GetScienceInfo(13).level or 0
    if self.idx == 1 then
        if (5+sciene_lev) - self.donationInfo.donationCount > 0 then
            self.view.root.donationInfo[UI.Text].text = SGK.Localize:getInstance():getValue("guild_techDonate_info1", "<color=#00FF00>"..(((5+sciene_lev) - self.donationInfo.donationCount) or 0).."/"..(5+sciene_lev).."</color>")
        else
            self.view.root.donationInfo[UI.Text].text = SGK.Localize:getInstance():getValue("guild_techDonate_info1", "<color=#FF0000>"..(((5+sciene_lev) - self.donationInfo.donationCount) or 0).."/"..(5+sciene_lev).."</color>")
        end
    end
    self.scrollView.DataCount = #(self.donationListInfo or {})
end

function unionDonation:initScrollView()
    self.scrollView = self.view.root.ScrollView[CS.UIMultiScroller]
    self.scrollView.RefreshIconCallback = function(obj, idx)
        local _view = CS.SGK.UIReference.Setup(obj.gameObject)
        local _cfg = self.donationListInfo[idx + 1]
        --ERROR_LOG("ding=======>>>公会物品设置信息",sprinttb(_cfg))
        --print("=======",_cfg.id)
        local _info = module.unionScienceModule.GetDonationCfg(_cfg.id)
        print("_cfg",sprinttb(_cfg))
        if not _info then
            return
        end
        _view.donation:SetActive(self.idx == 1)
        _view.setting:SetActive(not _view.donation.activeSelf)
        if self.idx == 1 then
            utils.IconFrameHelper.Create(_view.donation.item.IconFrame, {type = utils.ItemHelper.TYPE.ITEM, id = _cfg.id, count = _info.expend_value, showDetail = true,pos = 2,
                onClickFunc = function ( ... )
                    DialogStack.PushPrefStact("ItemDetailFrame", {InItemBag=2,id = _cfg.id,type = utils.ItemHelper.TYPE.ITEM})
                end
            })
            _view.donation.item.need:SetActive(_cfg.urgent)
            _view.donation.info.addIcon[UI.Image]:LoadSprite("icon/".._info.product_urgent_id.."_small")
            _view.donation.info.addNumber[UI.Text].text = "+"..(_cfg.urgent ==true and _info.product_urgent_value or _info.product_value )
            if _cfg.urgent then
                _view.donation.info.addNumber[UI.Text].text="<color=#00FF00>" .."+"..(_cfg.urgent ==true and _info.product_urgent_value or _info.product_value ).."</color>"
            end

            local sciene_lev = module.unionScienceModule.GetScienceInfo(13) and module.unionScienceModule.GetScienceInfo(13).level or 0
            if ((5 + sciene_lev) - self.donationInfo.donationCount > 0) and (module.ItemModule.GetItemCount(_cfg.id) >= _info.expend_value) then
                _view.donation.donationBtn[UI.Button].interactable = true
            else
                _view.donation.donationBtn[UI.Button].interactable = false
                -- _view.donation.donationBtn[UI.Image].material = SGK.QualityConfig.GetInstance().grayMaterial
            end

            if (module.ItemModule.GetItemCount(_cfg.id) >= _info.expend_value) then
                _view.donation.info.haveNumber[UI.Text].text = SGK.Localize:getInstance():getValue("guild_techDonate_list", "<color=#00FF00>"..module.ItemModule.GetItemCount(_cfg.id).."</color>")
            else
                _view.donation.info.haveNumber[UI.Text].text = SGK.Localize:getInstance():getValue("guild_techDonate_list", "<color=#FF0000>"..module.ItemModule.GetItemCount(_cfg.id).."</color>")
            end

            CS.UGUIClickEventListener.Get(_view.donation.donationBtn.gameObject).onClick = function()
                if self.donationInfo.donationCount >= (5+sciene_lev) then
                    showDlgError(nil, "今日剩余捐献次数不足")
                    return
                end
                if module.ItemModule.GetItemCount(_cfg.id) < _info.expend_value then
                    local _item = utils.ItemHelper.Get(utils.ItemHelper.TYPE.ITEM, _cfg.id)
                showDlgError(nil, SGK.Localize:getInstance():getValue("tips_ziyuan_buzu_01", _item.name))
                    return
                end
                _view.donation.donationBtn[CS.UGUIClickEventListener].interactable = false
                _view.donation.donationBtn[UI.Image].material = SGK.QualityConfig.GetInstance().grayMaterial
                coroutine.resume(coroutine.create( function()
                    local _data = module.unionScienceModule.AddItem(_cfg.donate_id)
                    if _data[2] == 0 then
                        showDlgError(nil, "捐献成功")
                    end
                    _view.donation.donationBtn[CS.UGUIClickEventListener].interactable = true
                    _view.donation.donationBtn[UI.Image].material = nil
                end))
            end
        else
            _view.setting.info.inventory[UI.Text].text = SGK.Localize:getInstance():getValue("guild_techDonate_list2", _cfg.value)
            utils.IconFrameHelper.Create(_view.setting.item.IconFrame, {type = utils.ItemHelper.TYPE.ITEM, id = _cfg.id, count = 0, showDetail = true,pos = 2,
                onClickFunc = function ( ... )
                    DialogStack.PushPrefStact("ItemDetailFrame", {InItemBag=2,id = _cfg.id,type = utils.ItemHelper.TYPE.ITEM})
                end
            })
            _view.setting.settingInfo.icon[UI.Image]:LoadSprite("icon/"..setUrgentItem.id.."_small")
            _view.setting.settingInfo.number[UI.Text].text = tostring(setUrgentItem.value)
            _view.setting.item.need:SetActive(_cfg.urgent)
            
           -- ERROR_LOG("ding====>>>可设置急需物资的个数",self.donationInfo.setUrgentCount)
            _view.setting.settingBtn.Text[UI.Text].text = _cfg.urgent and "已设置" or SGK.Localize:getInstance():getValue("guild_techDonate_btn2")
            -- settingBtn

            _view.setting.info.desc[UI.Text].text=SGK.Localize:getInstance():getValue("guild_techDonate_urgent")
            if self.donationInfo.setUrgentCount > 0 then
                _view.setting.settingBtn[UI.Button].interactable = true
                _view.setting.settingInfo:SetActive(true);
                
                CS.UGUIClickEventListener.Get(_view.setting.settingBtn.gameObject).onClick = function()
                    

                    showDlgMsg(SGK.Localize:getInstance():getValue("急需物资每日只能设置1次，设置后无法更改，请谨慎选择。"), 
                    function ()
                        if not (module.unionModule.Manage:GetSelfTitle() == 1 or module.unionModule.Manage:GetSelfTitle() == 2) then
                            showDlgError(nil, "您的权限不足，请联系会长或副会长进行设置")
                            return
                        end
                        if module.ItemModule.GetItemCount(setUrgentItem.id) < setUrgentItem.value then
                            local _item = utils.ItemHelper.Get(utils.ItemHelper.TYPE.ITEM, setUrgentItem.id)
                            showDlgError(nil, SGK.Localize:getInstance():getValue("tips_ziyuan_buzu_01", _item.name))
                            return
                        end
                        if self.donationInfo.setUrgentCount > 0 then
                            _view.setting.settingBtn[CS.UGUIClickEventListener].interactable = false
                        -- _view.setting.settingBtn[UI.Image].material = SGK.QualityConfig.GetInstance().grayMaterial
                        --ERROR_LOG("ding==========>>设置急需物资")
                            coroutine.resume(coroutine.create( function()
                                local _data = module.unionScienceModule.SetUrgentItem(_cfg.donate_id)
                                if _data[2] == 0 then
                                    showDlgError(nil, "设置成功")
                                    _view.setting.settingBtn:SetActive(false)
                                    self.view.root.group.Toggle2.Background.tip:SetActive(false)
                                end
                                _view.setting.settingBtn[CS.UGUIClickEventListener].interactable = true
                                _view.setting.settingBtn[UI.Image].material = nil
                            end))
                        end
                    end,
                    function ()
                       
                    end, 
                    SGK.Localize:getInstance():getValue("确定设置"), --确定
                    SGK.Localize:getInstance():getValue("取消") --取消
                    )
                end
            else
                -- _view.setting.settingBtn[UI.Image].material = SGK.QualityConfig.GetInstance().grayMaterial
                _view.setting.settingBtn[UI.Button].interactable = false
                _view.setting.settingBtn:SetActive(false)
                _view.setting.settingInfo:SetActive(false);
                if _cfg.urgent then
                    _view.setting.settings:SetActive(true)
                    _view.setting.info.desc[UI.Text].text="<color=#FF7600FF>" .."捐献此物资所获公会币提高100%" .."</color>"
                end  
            end

            -- function newUnionActivity:checkRed( view,id )
            --     if self.checkRedConfig[id] and self.checkRedConfig[id].red and self.checkRedConfig[id].red == true then
            --         view.tip:SetActive(true)
            --         module.RedDotModule.PlayRedAnim(view.tip)
            --     else
            --         view.tip:SetActive(false)
            --     end
            
            -- end



            
        end
        obj:SetActive(true)
	end
end

function unionDonation:deActive()
    utils.SGKTools.PlayDestroyAnim(self.gameObject)
    return true;
end

function unionDonation:listEvent()
    return {
        "LOCAL_DONATION_CHANGE",
    }
end

function unionDonation:onEvent(event, data)
    if event == "LOCAL_DONATION_CHANGE" then
        self:upShowType()
    end
end


return unionDonation
