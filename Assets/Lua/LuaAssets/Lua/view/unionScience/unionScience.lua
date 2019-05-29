local unionScience = {}

function unionScience:Start()
    self:initData()
    self:initUi()
end

function unionScience:initData()
    self:upData()
end

function unionScience:upData()
    self.scienceList = module.unionScienceModule.GetScienceList()

    table.sort(self.scienceList, function(a, b)
        return a.id < b.id
    end)
    self.allLevel = 0
    for i,v in ipairs(self.scienceList) do
        self.allLevel = v.level + self.allLevel
    end
end

function unionScience:initUi()
    self.view = CS.SGK.UIReference.Setup(self.gameObject)
    -- CS.UGUIClickEventListener.Get(self.view.root.bg.closeBtn.gameObject).onClick = function()
    --     DialogStack.Pop()
    -- end
    CS.UGUIClickEventListener.Get(self.view.mask.gameObject, true).onClick = function()
        DialogStack.Pop()
    end
    CS.UGUIClickEventListener.Get(self.view.root.bottom.bg.Image1.DonateButton.gameObject).onClick=function()
        DialogStack.Push("unionScience/unionDonation")
    end
    CS.UGUIClickEventListener.Get(self.view.root.bottom.tipBtn.gameObject, true).onClick = function()
        utils.SGKTools.ShowDlgHelp(SGK.Localize:getInstance():getValue("guild_tech_info"))
    end
    -- --测试战斗说明
    -- CS.UGUIClickEventListener.Get(self.view.root.Image.gameObject).onClick=function()
    --     DialogStack.Push("battleInstructions",10);
    -- end





    self:upTop()
    self:initScrollView()
    if module.RedDotModule.Type.Union.Donation.check()==true then
        self.view.root.bottom.bg.Image1.DonateButton.tip.gameObject:SetActive(true)
        module.RedDotModule.PlayRedAnim(self.view.root.bottom.bg.Image1.DonateButton.tip)
    else
        self.view.root.bottom.bg.Image1.DonateButton.tip.gameObject:SetActive(false)
    end
end

function unionScience:upTop()
    local i = 1
    for k,v in pairs(module.unionScienceModule.GetDonationInfo().itemList) do
        local _view = self.view.root.bottom.itemList[i]
        if _view then
            local _item = utils.ItemHelper.Get(utils.ItemHelper.TYPE.ITEM, v.id)
            _view.icon[UI.Image]:LoadSprite(string.format("icon/%s", _item.icon))
            _view.number[UI.Text].text = tostring(v.value)
            _view.icon[UI.Image].raycastTarget = true;
            CS.UGUIClickEventListener.Get(_view.icon.gameObject).onClick = function()
                DialogStack.PushPrefStact("ItemDetailFrame", {InItemBag=2,id = v.id,type = utils.ItemHelper.TYPE.ITEM})
            end
        end
        i = i + 1
    end
    self.view.root.bottom.allNumber[UI.Text].text = tostring(self.allLevel)

end

function unionScience:Update()
    local now = math.floor(UnityEngine.Time.timeSinceLevelLoad);
    if self.last_update_time == now then
        return;
    end
    self.last_update_time = now
    if self.scrollView then
        self.scrollView:ItemRef()
    end
end

function unionScience:initScrollView()

    local count = math.floor( #self.scienceList / 3 );
    self.scrollView = self.view.root.ScrollView[CS.UIMultiScroller]
    self.scrollView.RefreshIconCallback = function(obj, idx)
        local _view = CS.SGK.UIReference.Setup(obj.gameObject)
        for i = 1, 3 do
            -- print(math.floor( (count *(i-1)+1 )+idx+1)
            -- ( (4 *(v-1)+1 )+i)
            local _info = self.scienceList[math.floor( (count *(i-1)+1 )+idx)]

            --ERROR_LOG("物品信息",sprinttb(_info))
            local _cfg = module.unionScienceModule.GetScienceCfg(_info.id)
            local _level = _info.level
            if _level == 0 then
                _level = _level + 1
            end
            _view.root.itemList[i].maxInfo[UI.Text].text = "";
            local flag = nil
            if _cfg and _cfg[_level] then
                _view.root.itemList[i].name[UI.Text].text = _cfg[_level].name
                _view.root.itemList[i].level[UI.Text].text = "^".._info.level
                _view.root.itemList[i].icon[UI.Image]:LoadSprite("icon/".._cfg[_level].icon)
                _view.root.itemList[i].learning:SetActive(_info.time > module.Time.now())
                if _cfg[_info.level + 1] then
                    _view.root.itemList[i].lock:SetActive(_cfg[_info.level + 1].guild_level > module.unionModule.Manage:GetSelfUnion().unionLevel)
                    _view.root.itemList[i].lock.lockInfo[UI.Text].text = string.format("公会%s级解锁", _cfg[_info.level + 1].guild_level)
                else
                   
                end

                if _view.root.itemList[i].learning.activeSelf then
                    _view.root.itemList[i].maxInfo:SetActive(false);
                    _view.root.itemList[i].lock:SetActive(false)
                    _view.root.itemList[i].learning[UI.Scrollbar].size = (_cfg[_info.level + 1].need_time - (_info.time - module.Time.now())) / _cfg[_info.level + 1].need_time
                else
                    _view.root.itemList[i].maxInfo:SetActive(true); 
                end

                CS.UGUIClickEventListener.Get(_view.root.itemList[i].icon.gameObject).onClick = function()
                    DialogStack.PushPrefStact("unionScience/unionScienceInfo", {id = _info.id,isLock=_cfg[_info.level + 1]})
                    self.IsPlayEffect=true
                    self.ScenceId=_info.id
                    self.ScenceLevel=_info.level
                    self.ScenceIndex=i
                    self.ScenceObj=_view.root.itemList[i]
                end
                coroutine.resume( coroutine.create( function ( ... )
                    if _view.root.itemList[i] and _cfg[_info.level + 1] then
                        if ( not (_cfg[_info.level + 1].guild_level <= module.unionModule.Manage:GetSelfUnion().unionLevel)) or _view.root.itemList[i].learning.activeSelf then
                            _view.root.itemList[i].maxInfo:SetActive(false);
                        else
                            _view.root.itemList[i].maxInfo:SetActive(true);
                        end
                    end
                end ) )

                 --ERROR_LOG("科技最大等级=====>>>",(#module.unionScienceModule.GetScienceCfg(_info.id)))
                --ERROR_LOG(_view.root.itemList[i].level[UI.Text].text)

                if _info.level==0 then
                    _view.root.itemList[i].maxInfo[UI.Text].text=SGK.Localize:getInstance():getValue("guild_tech_deblocking")
                elseif _info.level==(#module.unionScienceModule.GetScienceCfg(_info.id)) then
                   -- ERROR_LOG("物品满级",_info.level)
                    _view.root.itemList[i].maxInfo[UI.Text].text=SGK.Localize:getInstance():getValue("guild_tech_levelMax")
                else
                 --   ERROR_LOG("物品未满级",_info.level)
                    _view.root.itemList[i].maxInfo[UI.Text].text=SGK.Localize:getInstance():getValue("guild_tech_upgrade")
                    --_view.root.itemList[i].maxInfo[UI.Text].text = (not (_cfg and _cfg[_info.level + 1])) and SGK.Localize:getInstance():getValue("guild_tech_levelMax") or SGK.Localize:getInstance():getValue("guild_tech_upgrade") 
                end
                if self.IsPlayEffect then
                   -- ERROR_LOG("isplay=========>>",self.IsPlayEffect,self.ScenceId,self.ScenceLevel, self.ScenceIndex,self.ScenceObj.gameObject.name)
                 if self.ScenceId==_info.id then
                     if self.ScenceLevel+1==_info.level then
                       -- ERROR_LOG("ding============>>>",sprinttb(_info))
                        self.effectNode = self:playEffect("fx_guild_t_up", nil, self.ScenceObj.gameObject)
                        self.IsPlayEffect=false
                     elseif self.effectNode then
                         UnityEngine.Object.Destroy(self.effectNode)
                     end
                 end
                end
            end
            -- guild_tech_upgrade
          --_view.root.itemList[i].maxInfo[UI.Text].text = (not (_cfg and _cfg[_info.level + 1])) and SGK.Localize:getInstance():getValue("guild_tech_levelMax") or SGK.Localize:getInstance():getValue("guild_tech_upgrade")
          
        end
        obj:SetActive(true)
    end
    self.scrollView.DataCount = (#self.scienceList / 3)
end

function unionScience:playEffect(effectName, position, node, delete, sortOrder)
    local prefab = SGK.ResourcesManager.Load("prefabs/effect/UI/" .. effectName..".prefab");
    local o = prefab and UnityEngine.GameObject.Instantiate(prefab, node.transform);
    if o then
        local transform = o.transform;
        transform.localPosition = position or Vector3.zero;
        --transform.localScale = Vector3.zero
        transform.localRotation = Quaternion.identity;
        if sortOrder then
            SGK.ParticleSystemSortingLayer.Set(o, sortOrder);
        end
        if delete then
            local _obj = o:GetComponentInChildren(typeof(UnityEngine.ParticleSystem))
            UnityEngine.Object.Destroy(o, _obj.main.duration)
        end
    end
    return o
end


function unionScience:listEvent()
    return {
        "LOCAL_DONATION_CHANGE",
        "LOCAL_SCIENCEINFO_CHANGE",
    }
end

function unionScience:onEvent(event, data)
    if event == "LOCAL_DONATION_CHANGE" then
        print("LOCAL_DONATION_CHANGE")
        self:upTop()
    elseif event == "LOCAL_SCIENCEINFO_CHANGE" then
        self:upData()
        self:upTop()
        self.scrollView.DataCount = (#self.scienceList / 3)
    end
end


return unionScience
