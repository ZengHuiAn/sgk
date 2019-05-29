local StoryConfig = require "config.StoryConfig"
local fightModule = require "module.fightModule"
local selectChapter = {}

function selectChapter:Start(data)
    self:init(data)
end

function selectChapter:init(data)
    if data then
        self.data = data
    else
        return
    end
    self:initData(data)
    self:initUi()
    module.guideModule.PlayByType(100, 0.2)
end

function selectChapter:initData(data)
    self.cfg = {}
    if data and data.chapterId then
        self.cfg = fightModule.GetConfig(data.chapterId)
    end
    self.chapterId = data.chapterId
    self.difficultyIdx = module.guideModule.SelectChapterDifficulty[self.chapterId] or 1
    self.battleList = {}
    for k,v in pairs(self.cfg.battleConfig or {}) do
        table.insert(self.battleList, v)
    end
    if #self.battleList > 0 then
        table.sort(self.battleList, function(a, b)
            return a.battle_id < b.battle_id
        end)
    end
end

function selectChapter:initUi()
    self.view = CS.SGK.UIReference.Setup(self.gameObject)
    self:initTop()
    self:initScrollView()
    self:initToggle()
    self:upUi()
end

function selectChapter:initToggle()
    for i = 1, #self.view.root.toggle do
        local _view = self.view.root.toggle[i]
        _view[UI.Toggle].onValueChanged:RemoveAllListeners()
        _view[UI.Toggle].onValueChanged:AddListener(function (value)
            _view.arraw:SetActive(value)
        end)
        CS.UGUIClickEventListener.Get(_view.gameObject).onClick = function()
            self.difficultyIdx = i
            module.guideModule.SelectChapterDifficulty[self.chapterId] = self.difficultyIdx
        end
    end
    self.view.root.toggle[self.difficultyIdx][UI.Toggle].isOn = true
    self.view.root.toggle[self.difficultyIdx].arraw:SetActive(true)
end

function selectChapter:initTop()
    CS.UGUIClickEventListener.Get(self.view.root.top.rankBtn.gameObject).onClick = function()
        DialogStack.Push("rankList/rankListFrame", 2)
    end
    CS.UGUIClickEventListener.Get(self.view.root.top.addBtn.gameObject).onClick = function()
        DialogStack.Push("ShopFrame", {index = 2})
    end
    self.haveStar = self.view.root.top.haveStar[UI.Text]
    self.rankNumber = self.view.root.top.rankNumber[UI.Text]
    self:upTop()
end

function selectChapter:upTop()
    local _data = module.RankListModule.GetSelfStarInfo()
    self.haveStar.text = tostring(_data[1])
    if _data[2] then
        self.rankNumber.text = tostring(_data[2])
    else
        self.rankNumber.text = "未上榜"
    end
end

function selectChapter:initScrollView()
    local _list = {}
    for i,v in ipairs(self.battleList) do
        local _open = true
        if self.battleList[i - 1] then
            _open = self:isOpen(v, self.battleList[i - 1])
        end
        if _open then
            table.insert(_list, v)
        else
            table.insert(_list, v)
            break
        end
    end
    self.scrollView = self.view.root.middle.ScrollView1[CS.UIMultiScroller]
    self.scrollView.RefreshIconCallback = function (obj, idx)
        local _view = CS.SGK.UIReference.Setup(obj.gameObject)
        local _cfg = self.battleList[idx + 1]
        local _have, _count = self:getHaveStar(_cfg, self.cfg.count)
        _view.root.star.star[UI.Text].text = string.format("%s/%s", _count, _have)
        _view.root.name[UI.Text].text = _cfg.name
        _view.root.story.star[UI.Text].text = self:getStoryCompleted(_cfg)
        _view.root.IconMask.icon[UI.Image]:LoadSpriteWithExt("guanqia/".._cfg.bg_xditu .. ".jpg")
        if _cfg.bg_xditu_2 and _cfg.bg_xditu_2 ~= "" and _cfg.bg_xditu_2 ~= "0" then
            _view.root.IconMask.icon2:SetActive(true)
            _view.root.IconMask.icon2[UI.Image]:LoadSpriteWithExt("guanqia/".._cfg.bg_xditu_2 .. ".png")
        else
            _view.root.IconMask.icon2:SetActive(false)
        end
        local _starStatus = module.RewardModule.GetConfigByType(2, _cfg.battle_id)

        local _status, _idx = self:isOpen(_cfg, self.battleList[idx])
        _view.root.star:SetActive(_status and _starStatus)
        _view.root.bg:SetActive(_status)
        _view.root.name:SetActive(_status)
        _view.root.story:SetActive(_status)

        if not _status then
            _view.root.IconMask.icon[UI.Image].color = {r = 68/255, g = 68/255, b = 68/255, a = 1}
            _view.root.IconMask.icon2[UI.Image].color = {r = 68/255, g = 68/255, b = 68/255, a = 1}
        else
            _view.root.IconMask.icon[UI.Image].color = {r = 1, g = 1, b = 1, a = 1}
            _view.root.IconMask.icon2[UI.Image].color = {r = 1, g = 1, b = 1, a = 1}
        end

        local _rewardStatus = false
        local _doneCount = 0
        for i,v in ipairs(_starStatus or {}) do
            if module.RewardModule.Check(v.id) == module.RewardModule.STATUS.READY then
                _rewardStatus = true
                break
            end
            if module.RewardModule.Check(v.id) == module.RewardModule.STATUS.DONE then
                _doneCount = _doneCount + 1
            end
        end
        local _infoCfg = self:openInfo(_cfg, self.battleList[idx]) or {}
        --_view.root.lock.info[UI.Text].text = ""
        _view.root.lock.info.info1:SetActive(false)
        _view.root.lock.info.info2:SetActive(false)
        _view.root.lock.info.info3:SetActive(false)
        --print("zoechakankaiqitioajian",sprinttb(_infoCfg))
        if #_infoCfg >= 1 then
            for i,v in ipairs(_infoCfg) do
                --if not v.status then
                    if v.idx == 1 then
                        _view.root.lock.info.info1.finish.gameObject:SetActive(v.status)
                        _view.root.lock.info.info1.lock.gameObject:SetActive(not v.status)
                        if v.status then
                            _view.root.lock.info.info1.info[UI.Text].text = v.name
                        else
                            _view.root.lock.info.info1.info[UI.Text].text ="<color=red>"..v.name.."</color>"
                        end
                        _view.root.lock.info.info1:SetActive(true)
                        --break
                    elseif v.idx == 2 then
                        _view.root.lock.info.info2.finish.gameObject:SetActive(v.status)
                        _view.root.lock.info.info2.lock.gameObject:SetActive(not v.status)
                        if v.status then
                            _view.root.lock.info.info2.info[UI.Text].text = v.name
                            _view.root.lock.info.info2.info.Image.info[UI.Text].text ="后开启"
                        else
                            _view.root.lock.info.info2.info[UI.Text].text ="<color=red>"..v.name.."</color>"
                            _view.root.lock.info.info2.info.Image.info[UI.Text].text ="<color=red>后开启</color>"
                        end
                        _view.root.lock.info.info2:SetActive(true)
                    elseif v.idx == 3 then
                        _view.root.lock.info.info3.finish.gameObject:SetActive(v.status)
                        _view.root.lock.info.info3.lock.gameObject:SetActive(not v.status)
                        if v.status then
                            _view.root.lock.info.info3.info[UI.Text].text = v.name
                        else
                            _view.root.lock.info.info3.info[UI.Text].text ="<color=red>"..v.name.."</color>"
                        end
                        _view.root.lock.info.info3:SetActive(true)
                    end
                --end
            end
        end

        _view.root.star.btn.tip:SetActive(_rewardStatus)

        _view.root.star.btn:SetActive(_rewardStatus or (_doneCount ~= #(_starStatus or {})))
        CS.UGUIClickEventListener.Get(_view.root.star.btn.gameObject).onClick = function()
            DialogStack.PushPrefStact("selectMap/selectMapGift", {chapterId = _cfg.battle_id, star = _have, index = 2})
        end
        _view.root.lock:SetActive(not _status)
        CS.UGUIClickEventListener.Get(_view.root.IconMask.icon.gameObject).onClick = function()
            if not _view.root.lock.activeSelf then
                if module.QuestModule.Get(_cfg.map_quest) and module.QuestModule.Get(_cfg.map_quest).status == 0 then
                    utils.SGKTools.LockMapClick(true)
                    module.guideModule.SelectChapterGuide[self.chapterId] = idx + 1
                    fightModule.SetNowSelectChapter({chapterId = _cfg.chapter_id, idx = idx + 1, difficultyIdx = self.difficultyIdx, chapterNum = #_list})
                    DialogStack.Push("bigMap/bigMap",{idx = idx + 1,from = _cfg.from_map_id,to = _cfg.to_map_id,func = function ()
                        module.QuestModule.Finish(_cfg.map_quest)
                        if UnityEngine.SceneManagement.SceneManager.GetActiveScene().name == "newSelectMapUp" then
                            utils.EventManager.getInstance():dispatch("Fresh_Select_map")
                        else
                            SceneStack.Push("newSelectMapUp")
                        end
                        utils.SGKTools.LockMapClick(false)
                    end})
                else
                    module.guideModule.SelectChapterGuide[self.chapterId] = idx + 1
                    --DialogStack.Push("newSelectMap/newSelectMap", {chapterId = _cfg.chapter_id, idx = idx + 1})
                    fightModule.SetNowSelectChapter({chapterId = _cfg.chapter_id, idx = idx + 1, difficultyIdx = self.difficultyIdx, chapterNum = #_list})
                    if UnityEngine.SceneManagement.SceneManager.GetActiveScene().name == "newSelectMapUp" then
                        SceneStack.savedValues.OpenSelectMap = false
                        DialogStack.Pop()
                        utils.EventManager.getInstance():dispatch("Fresh_Select_map")
                    else
                        SceneStack.Push("newSelectMapUp")
                    end
                    --SceneStack.Push("map_jjc","view/newSelectMap/selectMaps/MapTouchMove.lua")
                end
            end
        end
        obj:SetActive(true)
    end
    self.scrollView.DataCount = #_list
    --print(module.guideModule.GetOnlyOneFlag())
    if module.guideModule.GetOnlyOneFlag() then
        self.scrollView:ScrollMove(#_list-1)
    end
end

-- function selectChapter:initScrollView()
--     self.scrollView = self.view.root.middle.ScrollView[CS.UIMultiScroller]
--     self.scrollView.RefreshIconCallback = function (obj, idx)
--         local _view = CS.SGK.UIReference.Setup(obj.gameObject)
--         local _cfg = self.battleList[idx + 1]
--         local _have, _count = self:getHaveStar(_cfg, self.cfg.count)
--         _view.root.openNode.star[UI.Text].text = string.format("%s/%s", _count, _have)
--         _view.root.name[UI.Text].text = _cfg.name
--         _view.root.icon[UI.Image]:LoadSpriteWithExt("guanqia/".._cfg.bg_xditu .. ".jpg")
--
--         local _starStatus = module.RewardModule.GetConfigByType(2, _cfg.battle_id)
--
--         local _status, _idx = self:isOpen(_cfg, self.battleList[idx])
--         _view.root.openNode:SetActive(_status and _starStatus)
--         _view.closeNode:SetActive(not _status)
--
--         local _rewardStatus = false
--         local _doneCount = 0
--         for i,v in ipairs(_starStatus or {}) do
--             if module.RewardModule.Check(v.id) == module.RewardModule.STATUS.READY then
--                 _rewardStatus = true
--                 break
--             end
--             if module.RewardModule.Check(v.id) == module.RewardModule.STATUS.DONE then
--                 _doneCount = _doneCount + 1
--             end
--         end
--         _view.root.openNode.tip:SetActive(_rewardStatus)
--         _view.root.openNode.Button:SetActive(_rewardStatus or (_doneCount ~= #(_starStatus or {})))
--
--         CS.UGUIClickEventListener.Get(_view.root.openNode.Button.gameObject).onClick = function()
--             DialogStack.PushPrefStact("selectMap/selectMapGift", {chapterId = _cfg.battle_id, star = _have, index = 2})
--         end
--         CS.UGUIClickEventListener.Get(_view.root.gameObject).onClick = function()
--             if not _view.closeNode.activeSelf then
--                 module.guideModule.SelectChapterGuide[self.chapterId] = idx + 1
--                 DialogStack.Push("newSelectMap/newSelectMap", {chapterId = _cfg.chapter_id, idx = idx + 1})
--             end
--         end
--         CS.UGUIClickEventListener.Get(_view.closeNode.gameObject, true).onClick = function()
--             local _infoCfg = self:openInfo(_cfg, self.battleList[idx])
--             if #_infoCfg >= 1 then
--                 _view.lock:SetActive(true)
--                 self.view.root.maskLock:SetActive(true)
--                 for i = 1, 2 do
--                     _view.lock["info"..i]:SetActive(_infoCfg[i] and true)
--                     if _infoCfg[i] then
--                         _view.lock["info"..i][UI.Text].text = _infoCfg[i].name
--                         _view.lock["lock"..i]:SetActive(not _infoCfg[i].status)
--                         _view.lock["pass"..i]:SetActive(_infoCfg[i].status)
--                     else
--                         _view.lock["lock"..i]:SetActive(false)
--                         _view.lock["pass"..i]:SetActive(false)
--                     end
--                 end
--                 _view.lock:SetActive(true)
--                 _view.transform:DOLocalRotate(Vector3(0, 0, 0), 0.8):OnComplete(function()
--                     _view.lock:SetActive(false)
--                     self.view.root.maskLock:SetActive(false)
--                 end)
--             end
--         end
--
--
--         obj:SetActive(true)
--     end
--     self.scrollView.DataCount = #self.battleList
--
--     local _idx = #self.battleList
--     if module.guideModule.SelectChapterGuide[self.chapterId] then
--         _idx = module.guideModule.SelectChapterGuide[self.chapterId]
--     else
--         for i,v in ipairs(self.battleList) do
--             if not self:isOpen(v, self.battleList[i - 1]) then
--                 _idx = i
--                 break
--             end
--         end
--     end
--     self.scrollView:ScrollMove(_idx - 1 - 1)
--     module.guideModule.SelectChapterGuide[self.chapterId] = _idx
--
--     -- CS.UGUIClickEventListener.Get(self.view.root.maskLock.gameObject, true).onClick = function()
--     --     self.view.root.lock:SetActive(false)
--     --     self.view.root.maskLock:SetActive(false)
--     -- end
-- end

function selectChapter:openInfo(battleCfg, _battleCfg)
    local _tab = {}
    if battleCfg.lev_limit and battleCfg.lev_limit ~= 0 then
        local _status = true
        if battleCfg.lev_limit > module.HeroModule.GetManager():Get(11000).level then
            _status = false
        end
        table.insert(_tab, {idx = 1, name = battleCfg.lev_limit.."级解锁", status = _status})
    end
    if battleCfg.depend_star_count then
        local _status = true
        if battleCfg.depend_star_count > module.playerModule.Get().starPoint then
            _status = false
        end
        table.insert(_tab, {idx = 2, name = SGK.Localize:getInstance():getValue("huiyilu_tips_04", battleCfg.depend_star_count), status = _status})
    end
    if _battleCfg then
        if battleCfg.rely_battle ~= nil and battleCfg.rely_battle ~= 0 then
            local _status = true
            if _battleCfg.finish_id ~= nil and _battleCfg.finish_id ~= 0 then

                if not fightModule.GetFightInfo(_battleCfg.finish_id):IsPassed() then
                    _status = false
                end
            end
            if tonumber(_battleCfg.finish_quest) ~= nil and tonumber(_battleCfg.finish_quest) ~= 0 then
                if not module.QuestModule.Get(tonumber(_battleCfg.finish_quest)) or module.QuestModule.Get(tonumber(_battleCfg.finish_quest)).status == 0 then
                    _status = false
                end
            end
            table.insert(_tab, {idx = 3, name = "完成上一章", status = _status})
        end
    end
    if battleCfg.quest_id ~= nil and battleCfg.quest_id ~= 0 then
        local _name = module.QuestModule.GetCfg(battleCfg.quest_id).name
        local _status = true
        if module.QuestModule.Get(battleCfg.quest_id) == nil or module.QuestModule.Get(battleCfg.quest_id).status ~= 1 then
            _status = false
        end
        table.insert(_tab, {idx = 4, name = _name, status = _status})
    end
    return _tab
end

function selectChapter:isOpen(battleCfg, _battleCfg)
    if battleCfg.quest_id ~= nil and battleCfg.quest_id ~= 0 then
        if module.QuestModule.Get(battleCfg.quest_id) == nil or module.QuestModule.Get(battleCfg.quest_id).status ~= 1 then
            return false, 2
        end
    end
    if _battleCfg then
        if battleCfg.rely_battle ~= nil and battleCfg.rely_battle ~= 0 then
            if _battleCfg.finish_id ~= nil and _battleCfg.finish_id ~= 0 then
                if not fightModule.GetFightInfo(_battleCfg.finish_id):IsPassed() then
                    return false, 1
                end
            end
            --print(_battleCfg.finish_quest,type(_battleCfg.finish_quest))
            if tonumber(_battleCfg.finish_quest) ~= nil and tonumber(_battleCfg.finish_quest) ~= 0 then
                if not module.QuestModule.Get(tonumber(_battleCfg.finish_quest)) or module.QuestModule.Get(tonumber(_battleCfg.finish_quest)).status == 0 then
                    return false, 1
                end
            end
        end
    end
    if battleCfg.consume_type1 ~= 0 and battleCfg.consume_id1 ~= 0 then
        local _count = module.ItemModule.GetItemCount(battleCfg.consume_id1)
        if _count < battleCfg.consume_count1 then
            return false, 3
        end
    end
    if battleCfg.lev_limit and battleCfg.lev_limit ~= 0 then
        if battleCfg.lev_limit > module.HeroModule.GetManager():Get(11000).level then
            return false, 4
        end
    end
    if battleCfg.depend_star_count then
        if battleCfg.depend_star_count > module.playerModule.Get().starPoint then
            return false, 5
        end
    end
    return true
end

function selectChapter:getHaveStar(_cfg, count)
    local _allStar = 0
    local _haveStar = 0
    for k,v in pairs(_cfg.pveConfig) do
        _haveStar = _haveStar + self:openStar(fightModule.GetFightInfo(k).star)
        _allStar = _allStar + 3
    end
    return _allStar, _haveStar
end

function selectChapter:openStar(star)
    local _counst = 0
    for i = 1, 3 do
        if fightModule.GetOpenStar(star, i) ~= 0 then
            _counst = _counst + 1
        end
    end
    return _counst
end

function selectChapter:getStoryCompleted(_cfg)
    local list = self:getAllStoryPointChoose(_cfg)

    if list and #list > 0 then
        local completed = 0
        for k,v in pairs(list) do
            if module.QuestModule.Get(v) and module.QuestModule.Get(v).status == 1 then
                completed = completed + 1
            end 
        end
        return math.floor((completed*100)/(#list)).."%"
    else
        return "---"
    end
end

function selectChapter:getAllStoryPointChoose(_cfg)
    local _pic = _cfg.pic1
    local _picTab = StringSplit(_pic, "|")
    local _type = _cfg.type1
    local _typeTab = StringSplit(_type, "|")

    local list = {}
    for i = 1, #_typeTab do
        if tonumber(_typeTab[i]) == 3 then
            self:getStoryChoose(list,tonumber(_picTab[i]))
        end
    end
    return list
end

function selectChapter:getStoryChoose(list,quest_id)
    local cfg = StoryConfig.GetStoryChooseConf(nil,quest_id)

    if cfg and #cfg > 0 then
        for k,v in pairs(cfg) do
            list[#list+1]=v.quest_id1
        end
    end
end

function selectChapter:upUi()
    self.view.root.top.number[UI.Text].text = string.format("%s/150", module.ItemModule.GetItemCount(90010))
end

function selectChapter:listEvent()
    return {
        "ONE_TIME_REWARD_INFO_CHANGE",
        "LOCAL_GUIDE_CHANE",
        "GUIDE_SHOW_MASK",
    }
end

function selectChapter:onEvent(event, data)
    if event == "ONE_TIME_REWARD_INFO_CHANGE" then
        if self.scrollView then
            self.scrollView:ItemRef()
        end
    elseif event == "LOCAL_GUIDE_CHANE" then
        module.guideModule.PlayByType(100, 0.2)
    elseif event == "GUIDE_SHOW_MASK" then
        self.scrollView:ScrollMove(0)
    end
end

return selectChapter
