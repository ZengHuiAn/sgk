local TipCfg = require "config.TipConfig"
local openLevel = require "config.openLevel"
local UnionConfig = require "config.unionConfig"
local GuildPVPGroupModule = require "guild.pvp.module.group"
local activityModule = require "module.unionActivityModule"
local questModule = require "module.QuestModule"
local newUnionActivity = {}



function newUnionActivity:getActivityTab(data)
    local _idx = 1
    if data and data.idx then
        _idx = data.idx
    end
    local _tab = {}
    for i,v in pairs(UnionConfig.GetActivity()) do
        if v.activity_type == _idx then

            if _idx == 1 and v.id == 3 then
                if module.unionScienceModule.GetScienceInfo(12) and module.unionScienceModule.GetScienceInfo(12).level ~=0 then
                    v.isOpen = true;
                else
                    v.isOpen = false;
                end
                table.insert(_tab, v)
            else
                v.isOpen = true;
                table.insert(_tab, v)
            end
        end
    end
    return _tab
end

function newUnionActivity:initData(data)
    self.activityTab = self:getActivityTab(data)
    table.sort(self.activityTab, function(a, b)
        local _aId = a.id
        local _bId = b.id
        if not self:isOpen(a) then
            _aId = _aId + 1000
        end
        if not self:isOpen(b) then
            _bId = _bId + 1000
        end
        return _aId < _bId
    end)
    for k,v in pairs(self.activityTab) do
        v.reward = {}
        for i = 1, 3 do
            if v["show_reward_id"..i] ~= 0 and v["show_reward_type"..i] ~= 0 then
                table.insert(v.reward, {type = v["show_reward_type"..i], id = v["show_reward_id"..i], count = v["show_reward_count"..i]})
            end
        end
    end
end

function newUnionActivity:initUi()
    self.view = CS.SGK.UIReference.Setup(self.gameObject)
    self:initScrollView()
end

function newUnionActivity:isOpen(_cfg)
    if _cfg.begin_time >= 0 and _cfg.end_time >= 0 and _cfg.period >= 0 then
        local total_pass = module.Time.now() - _cfg.begin_time
        local period_pass = total_pass - math.floor(total_pass / _cfg.period) * _cfg.period
        local period_begin = module.Time.now() - period_pass
        if (module.Time.now() > period_begin and module.Time.now() < (period_begin + _cfg.loop_duration)) then
            return true
        end
    end
    return false
end

function newUnionActivity:checkExploreRed()
    
    for k,v in pairs(activityModule.ExploreManage:GetMapEventList()) do
        for j,p in pairs(v) do
            for h,l in pairs(p) do
                if l.beginTime < module.Time.now() then
                    return true
                end
            end
        end
    end
end


function newUnionActivity:checkRed( view,id )
    if self.checkRedConfig[id] and self.checkRedConfig[id].red and self.checkRedConfig[id].red == true then
        view.tip:SetActive(true)
        module.RedDotModule.PlayRedAnim(view.tip)
    else
        view.tip:SetActive(false)
    end

end
local function isAlreadyJoined()
    local guild = module.unionModule.Manage:GetSelfUnion();
    if guild == nil then
        return false;
    end

    local list = GuildPVPGroupModule.GetGuildList();
    for _, v in ipairs(list) do
        if v.id == guild.id then
            return true
        end
    end
    return false;
end


function newUnionActivity:initScrollView()
    table.sort(self.activityTab , function(a,b)
        return b.sort>a.sort
    end)
    local OpenList = {}
        local OffList = {}
        for i,v in ipairs(self.activityTab) do
            if v.type==1 then
                if v.isOpen then
                    table.insert( OpenList,v )
                    -- ERROR_LOG("ding===>>open_sort",v.sort)
                    -- ERROR_LOG("ding===>>open_isopen",v.isOpen)
                 else
                     table.insert(OffList, v)
                    --  ERROR_LOG("ding===>>off_sort",v.sort)
                    --  ERROR_LOG("ding===>>off_isopen",v.isOpen)
                 end
            else
                if  v.isOpen and self:isOpen(v) then
                    table.insert( OpenList,v )
                    -- ERROR_LOG("ding===>>open_sort",v.sort)
                    -- ERROR_LOG("ding===>>open_isopen",v.isOpen)
                 else
                     table.insert(OffList, v)
                    --  ERROR_LOG("ding===>>off_sort",v.sort)
                    --  ERROR_LOG("ding===>>off_isopen",v.isOpen)
                 end
            end
        end
        table.sort(OpenList , function(a,b)
            return b.sort>a.sort
        end)
        table.sort(OffList , function(a,b)
            return b.sort>a.sort
        end)
        for i,v in ipairs(OffList) do
            table.insert(OpenList,v)
        end
    self.scrollView = self.view.root.ScrollView[CS.UIMultiScroller]
    self.scrollView.RefreshIconCallback = function (obj, idx)
        local _view = CS.SGK.UIReference.Setup(obj)
        local _tab = OpenList[idx+1]
    --    ERROR_LOG("活动========>>>>>>1",sprinttb(_tab))
    --    ERROR_LOG("_tab.active_task========>>>>>>",_tab.active_task)
        if _tab.active_task and _tab.active_task ~=0 then
            _view.bg.liveness:SetActive(true)
           --questModule.Accept(_tab.active_task)
           --ERROR_LOG("status========>>>"..idx,questModule.Get(_tab.active_task).status)
           --ERROR_LOG("getCfg========>>>"..idx,sprinttb(questModule.Get(_tab.active_task)))
            local MostActive =questModule.GetCfg(_tab.active_task)
            if MostActive then
                if questModule.Get(_tab.active_task).status == 1 and questModule.Get(_tab.active_task) and _tab.isOpen then
                    --ERROR_LOG("_viewName======>>>",_view.gameObject.name)
                   -- ERROR_LOG("idx=====>>",MostActive.name)
                    _view.bg.liveness.Text[UI.Text].text="<color=#F49C00FF>".. MostActive.raw.desc2 .."</color>".. "/" .. MostActive.raw.desc2
                else
                    _view.bg.liveness.Text[UI.Text].text="<color=#F49C00FF>0</color>".. "/" .. MostActive.raw.desc2
                end 
                
            end
        else
            _view.bg.liveness:SetActive(false)
        end
       -- ERROR_LOG("活动======>>>>ding",sprinttb(_tab))
        --_view.name[UI.Text].text = SGK.Localize:getInstance():getValue(_tab.tittle)
        _view.desc[UI.Text].text = SGK.Localize:getInstance():getValue(_tab.client_desc)
       -- ERROR_LOG("_view",sprinttb(_view))
        _view[UnityEngine.RectTransform].localPosition=CS.UnityEngine.Vector3(0,(idx+1)*150,0)
        if _tab.client_time ~= "0" then
            _view.time[UI.Text].text = SGK.Localize:getInstance():getValue(_tab.client_time)
            _view.openLevel[UI.Text].text = SGK.Localize:getInstance():getValue(_tab.client_time)
        else
            _view.time[UI.Text].text = ""
        end
        _view.bg.Image:SetActive(false)
        _view.icon:SetActive(true)
        _view.icon[UI.Image]:LoadSprite("guideLayer/" .. _tab.use_icon)
        _view.bg[UI.Image]:LoadSprite("union/".._tab.pic)
        _view.mask[UI.Image]:LoadSprite("union/".._tab.pic)
        
        local _open = self:isOpen(_tab)
        
        if _tab.activity_type == 1 then

            if _open == true then
                _open = _tab.isOpen;
                _view.openLevel[UI.Text].text = SGK.Localize:getInstance():getValue("guild_tech_lock");
            else
                
            end
            self:checkRed(_view,_tab.id)
        end
        if _tab.id==1 then
            ERROR_LOG("_tab------->>>",sprinttb(_tab))
            for i=1,3 do
                local _conditionValue = UnionConfig.GetTeamAward(i, module.unionModule.Manage:GetSelfUnion().unionLevel).condition_value
                if _conditionValue <= module.unionModule.Manage:GetSelfUnion().todayAddExp then
                    module.RedDotModule.PlayRedAnim(_view.tip)
                    local _memb = module.unionModule.Manage:GetSelfInfo().awardFlag
                    if _memb[i] == 1 then
                        _view.tip:SetActive(false)
                    else
                        _view.tip:SetActive(true)
                    end
                end
            end
        end

        for i = 1, 3 do
            local _reward = _tab.reward[i]
            _view.list[i]:SetActive(_reward ~= nil)
            if _view.list[i].activeSelf then
                utils.IconFrameHelper.Create(_view.list[i], {id = _reward.id, type = _reward.type, showDetail = true, count = _reward.count})
            end
        end

        

        _view.mask:SetActive(not _open)
        _view.bg.goImage:SetActive(_open)
        _view.openLevel:SetActive(not _open)
        _view.time:SetActive(_open)
        if not _open then
            _view.bg.liveness:SetActive(false)
        end

        CS.UGUIClickEventListener.Get(_view.gameObject).onClick = function()

            if not _open then

                if _tab.activity_type == 1 then
                    showDlgError(nil, SGK.Localize:getInstance():getValue("guild_tech_lock"))
                else

                    showDlgError(nil, "活动未开放")
                end
                return
            end
            if _tab.openLevel and _tab.openLevel ~= 0 then
                if not openLevel.GetStatus(_tab.openLevel) then
                    showDlgError(nil, SGK.Localize:getInstance():getValue("tips_lv_02", openLevel.GetCfg(_tab.openLevel).open_lev))
                    return
                end
            end
            --DialogStack.Pop()
            if _tab.type == 3 then
                SceneStack.EnterMap(tonumber(_tab.fuction))
                
            elseif _tab.type == 1 then
                if _tab.fuction == "ShopFrame" then
                    DialogStack.Push(_tab.fuction, {index = 4})
                elseif _tab.id == 12 then
                    local status, fight_status = GuildPVPGroupModule.GetStatus();
                    ERROR_LOG("status------>>>",status)
                    if status==0 then
                      DialogStack.Push("guild_pvp/GuildPVPJoinPanel")
                    else
                     
                      if isAlreadyJoined() then
                        SceneStack.Push("GuildPVPPreparation", "view/guild_pvp/GuildPVPPreparation.lua");
                      else
                        DialogStack.Push("guild_pvp/GuildPVPJoinPanel")
                      end
                    end
                    -- if isAlreadyJoined() then
                    --     SceneStack.Push("GuildPVPPreparation", "view/guild_pvp/GuildPVPPreparation.lua");
                    -- elseif status==0 then
                    --     DialogStack.Push("guild_pvp/GuildPVPJoinPanel")
                    -- else
                    --     SceneStack.Push("GuildPVPPreparation", "view/guild_pvp/GuildPVPPreparation.lua");
                    -- end
                else
                    DialogStack.Push(_tab.fuction)
                end
            elseif _tab.type == 2 then
                utils.SGKTools.Map_Interact(tonumber(_tab.fuction))
            end
        end
        obj:SetActive(true)
    end
    self.scrollView.DataCount = #self.activityTab
end

function newUnionActivity:Start(data)
    self.checkRedConfig = {
        [3] = { red = module.RedDotModule.Type.Union.Explore.check()},
        [4] = { red = module.RedDotModule.Type.Union.Wish.check()},
        [1] = { red = module.RedDotModule.Type.Union.Investment.check()},
        [2] = {red = module.RedDotModule.Type.Union.Donation.check() }
    }
    self:initData(data)
    self:initUi()
    
end


function newUnionActivity:onEvent( ... )
    -- body
end

return newUnionActivity
