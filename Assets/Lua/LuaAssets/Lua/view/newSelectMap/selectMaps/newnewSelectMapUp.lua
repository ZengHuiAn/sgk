local fightModule = require "module.fightModule"
local QuestModule = require "module.QuestModule"
local timeModule = require "module.Time"
local MapConfig = require "config.MapConfig"
local rewardModule = require "module.RewardModule"
local openLevel = require "config.openLevel"
local Time = require "module.Time"
local battleCfg = require "config.battle"
local UserDefault = require "utils.UserDefault"

local time_limit_boss = UserDefault.Load("time_limit_boss", true);

local chapterCfg = {
    [1] = {id = "One"},
    [2] = {id = "Two"},
    [3] = {id = "Three"},
    [4] = {id = "Four"},
    [5] = {id = "Five"},
    [6] = {id = "Six"},
    [7] = {id = "Seven"},
    [8] = {id = "Eight"},
}

local newSelectMapUp = {}
function newSelectMapUp:Start(data)
    --DialogStack.Pop()
    local player =module.playerModule.Get()
    --ERROR_LOG(player)
    if player then
        self.newPlayerFlag=true
        self:init()
    end
end

function newSelectMapUp:init(num)
    if num then
        ERROR_LOG("刷新副本")
    end
    local stack = DialogStack.Top()
    if stack and stack.name == "newSelectMap/selectMap" then
        DialogStack.Pop()
    end
    self.data = fightModule.GetNowSelectChapter()
    --ERROR_LOG(sprinttb(self.data))
    self.savedValues = {}
    self.doTweenList = {}
    self.chapterNum = self.data.chapterNum
    self.chapterId = self.data.chapterId
    --self.allQuestCfg=module.QuestModule.GetCfg()
    --print(sprinttb(self.allQuestCfg))
    self.ChapterIdxFlag = self.data.idx
    self.view = CS.SGK.UIReference.Setup(self.gameObject)
    self:dataInit(self.data)
    if not self.CurrencyChat then
        local CurrencyChat = CS.UnityEngine.GameObject.Instantiate(SGK.ResourcesManager.Load("prefabs/base/CurrencyChat.prefab"), self.view.root.transform)
        self.CurrencyChat = CS.SGK.UIReference.Setup(CurrencyChat.gameObject)
    end
    self.routeId = tonumber(self.battleCfg["route"])
    if self.ChapterRoot then
        CS.UnityEngine.GameObject.Destroy(self.ChapterRoot.gameObject)
    end
    local obj = CS.UnityEngine.GameObject.Instantiate(SGK.ResourcesManager.Load("prefabs/newSelectMap/selectMaps/Chapter"..chapterCfg[tonumber(self.battleCfg["route"])].id..".prefab"), self.view.root.middle.transform)
    obj.name = "Chapter";
    self.ChapterRoot = CS.SGK.UIReference.Setup(obj)
    --self.ChapterRoot.ScrollView.ScrollbarVertical[CS.UnityEngine.UI.Scrollbar].value=fightModule.SetScroolbarValue() or 0
    --print("zoe查看副本",sprinttb(self.battleCfg))
    self:initUi()
    SGK.Action.DelayTime.Create(0.2):OnComplete(function()
        module.EquipHelp.ResetFlag()
        module.EquipHelp.ShowQuickToHero()
        module.HeroHelper.ShowRecommendedItem()
    end)
    self:checkGuide()
    self:initGuide()
    self:newPlayer()
    if not module.QuestModule.Get(100108) or module.QuestModule.Get(100108).status == 0 then
        self:closeBack()
    end
    self.view.root.left.noteBtn.redDot.gameObject:SetActive(module.RedDotModule.GetStatus(module.RedDotModule.Type.CheckPoint.DailyCheckPointTask, nil,self.view.root.left.noteBtn.redDot))
end

function newSelectMapUp:checkGuide()
    for i,v in ipairs(module.guideModule.CreateCharacterGuideCfg) do
        if module.guideModule.GetStoryFlag(i) then
        elseif v.questId then
            local _quest = module.QuestModule.Accept(v.questId)
            if module.QuestModule.Get(v.questId) and module.QuestModule.Get(v.questId).status == 1 then
            elseif module.playerModule.Get() then
                if v.storyId then
                    --print("5555555555555")
                    module.guideModule.SetStoryFlag(i,true)
                    LoadStory(v.storyId, v.func,false,true,nil,true)
                    return
                end
            end
        end
    end
end

function newSelectMapUp:initQuestList()
    local _pic = self.battleCfg["pic1"]
    local _picTab = StringSplit(_pic, "|")
    local _type = self.battleCfg["type1"]
    local _typeTab = StringSplit(_type, "|")
    for i = 1, #_typeTab do
        if tonumber(_typeTab[i]) == 3 then
            if not module.QuestModule.Get(tonumber(_picTab[i])) then
                module.QuestModule.Accept(tonumber(_picTab[i]))
            end
        end
    end
end

function newSelectMapUp:closeBack()
    --self.CurrencyChat.UGUIResourceBar.BottomBar.back[UI.Button].interactable = false
    CS.UGUIClickEventListener.Get(self.CurrencyChat.UGUIResourceBar.BottomBar.back.gameObject).interactable=false
    self.CurrencyChat.UGUIResourceBar.BottomBar.back.gameObject:SetActive(false)
end

function newSelectMapUp:initGuide()
    module.guideModule.PlayByType(102)
    module.guideModule.PlayByType(1200)
end

function newSelectMapUp:initScrollbar()
    --print("zoe Scrollbar 1111",fightModule.GetScroolbarValue(self.savedValues.chapterId,self.savedValues.selectMapIndx))
    self.ChapterRoot.ScrollView[CS.UnityEngine.UI.ScrollRect].onValueChanged:AddListener(function ()
        --print(self.savedValues.chapterId,self.savedValues.selectMapIndx)
        --print("zoe Scrollbar kkkkk",self.ChapterRoot.ScrollView.ScrollbarVertical[CS.UnityEngine.UI.Scrollbar].value)
        fightModule.SetScroolbarValue(self.savedValues.chapterId,self.savedValues.selectMapIndx,self.ChapterRoot.ScrollView.ScrollbarVertical[CS.UnityEngine.UI.Scrollbar].value)
    end)
    self.ChapterRoot.ScrollView.ScrollbarVertical[CS.UnityEngine.UI.Scrollbar].value=fightModule.GetScroolbarValue(self.savedValues.chapterId,self.savedValues.selectMapIndx) or 0
end

function newSelectMapUp:initUi()
    if not self.ChapterRoot then
        return
    end
    self.scrollbarFlag = false
    self:initGiftFx()
    self:initGiftBtn()
    self:initBtn()
    if module.QuestModule.Get(100108) and module.QuestModule.Get(100108).status == 1 then
        self:initSelectBtn()
    end
    self:upUi()
    self:initMisty()
    self:initBGM()
    self:initQuestList()
    self:initMainQuest()
    self:checkTimeBoss()
    self:checkChapterId()
end

function newSelectMapUp:initMisty()
    --self.ChapterRoot.Misty:SetActive(false)
    if self.ChapterRoot.Misty.transform.childCount == 0 and self.savedValues.chapterId == 1010 then
        SGK.ResourcesManager.LoadAsync("prefabs/effect/UI/fx_ui_map_cloud.prefab", function(obj)
            self.Misty = CS.UnityEngine.GameObject.Instantiate(obj.transform,self.ChapterRoot.Misty.transform)
            self.MistyAnimator = self.Misty.transform:GetChild(0):GetComponent(typeof(UnityEngine.Animator))
            --SGK.Action.DelayTime.Create():OnComplete(function()
                self.ChapterRoot.Misty:SetActive(true)
            --end)
            self:UpMisty(self.difficultyIdx,true)
        end)
    end
end

local taskLvLimitCfgId = 2211
function newSelectMapUp:checkChapterId()
    if (self.savedValues.chapterId and self.savedValues.chapterId == 1020) then
        self.view.root.bottom.toggle:SetActive(false)
        self.view.root.bottom.mainQuest:SetActive(false)
        self.view.root.left.noteBtn:SetActive(false)
    else
        self.view.root.bottom.toggle:SetActive(true)
        self.view.root.bottom.mainQuest:SetActive(true)
        self.view.root.left.noteBtn:SetActive(openLevel.GetStatus(taskLvLimitCfgId))
    end
end

function newSelectMapUp:checkTimeBoss()
    local bossList = {}
    for i,v in pairs(module.QuestModule.GetList(105)) do
        table.insert(bossList, v)
    end
    table.sort(bossList, function(a, b)
        return a.id < b.id
    end)
    local idx = 0;
    for i,v in ipairs(bossList) do
        local _quest = module.QuestModule.Get(v.id)
        if _quest and _quest.status == 0 then
            idx = i;
            break;
        end
    end
    if idx ~= 0 then
        local questCfg = bossList[idx];
        local boss = battleCfg.load(questCfg.event_id1).rounds[1].enemys[11];
        -- self.view.root.left.bossBtn.mask.icon[UI.Image]:LoadSprite("icon/"..boss.mode);
        local quest = module.QuestModule.Get(questCfg.id)
        local time = quest.accept_time + quest.extrareward_timelimit - Time.now();
        if time > 0 then
            self.timeLimit = quest.accept_time + quest.extrareward_timelimit;
            self.view.root.left.bossBtn.Text:SetActive(true);
            self.view.root.left.bossBtn.name:SetActive(false);
            self.view.root.left.bossBtn.Text[UI.Text].text = GetTimeFormat(time, 2, 2)
        else
            self.view.root.left.bossBtn.Text:SetActive(false);
            self.view.root.left.bossBtn.name:SetActive(true);
        end
        CS.UGUIClickEventListener.Get(self.view.root.left.bossBtn.gameObject).onClick = function()
            DialogStack.Push("mapSceneUI/timeBoss");
        end

        time_limit_boss.data = time_limit_boss.data or {};
        if time_limit_boss.data[questCfg.event_id1] and time_limit_boss.data[questCfg.event_id1] == 1 then
            self.view.root.left.bossBtn[UnityEngine.CanvasGroup].alpha = 1;
        else    
            time_limit_boss.data[questCfg.event_id1] = 1;
            DialogStack.PushPref("newSelectMap/bossTip", {role_id = boss.mode, endTime = time}, self.view.root.gameObject)
        end
    end
end

function newSelectMapUp:showTimeBoss()
    self.view.root.left.bossBtn[UnityEngine.CanvasGroup]:DOFade(1, 0.3);
end

function newSelectMapUp:initBGM()
    --print(self.battleCfg.battle_music)
    --SGK.BackgroundMusicService.RegisterSceneMusic("newSelectMapUp", "sound/"..self.battleCfg.battle_music)
    SGK.BackgroundMusicService.PlayMusic("sound/"..self.battleCfg.battle_music .. ".mp3")
end

function newSelectMapUp:initSelectBtn()
    local _list = {}
    for i,v in ipairs(self.battleList) do
        local _open = true
        if self.battleList[i - 1] then
            _open = self:isOpen(v.data, self.battleList[i - 1].data)
        end
        if _open then
            table.insert(_list, v)
        else
            --table.insert(_list, v)
            break
        end
    end
    self.chapterNum = #_list
    --self.selectBtnView.DataCount = #_list
    --self.selectBtnView:ScrollMove(self.nowIndex - 3)
end

function newSelectMapUp:upUi()
    self.ChapterRoot.bg[UI.Image].sprite = SGK.ResourcesManager.Load("guanqia/selectMap/"..self.battleCfg.background, typeof(UnityEngine.Sprite))
    --self.view.root.bg[UI.Image]:LoadSprite("guanqia/selectMap/"..self.battleCfg.background)
    self:initBottomToggle()
    self:initBoss()
    self:initGiftBtn()
    self:upTop()
    self:initRightEffert()
end

function newSelectMapUp:initBtn()
    CS.UGUIClickEventListener.Get(self.view.root.left.noteBtn.gameObject).onClick = function()
        DialogStack.Push("dailyCheckPointTask/dailyTaskList")
    end
    CS.UGUIClickEventListener.Get(self.view.root.left.rankBtn.gameObject).onClick = function()
        DialogStack.Push("rankList/rankListFrame", 2)
    end
    self.view.root.left.rankBtn:SetActive(openLevel.GetStatus(2204))
end

function newSelectMapUp:initRightEffert()
    SGK.ResourcesManager.LoadAsync("prefabs/effect/UI/fx_ui_zhangjiexz.prefab", function(obj)
        if obj and self.view.root.top.right.gameObject.transform.childCount == 0 then
            CS.UnityEngine.GameObject.Instantiate(obj.transform,self.view.root.top.right.gameObject.transform)    
        end
    end)
    if self.view.root.top.right.gameObject.transform.childCount > 0 then
        self.view.root.top.right.gameObject.transform:GetChild(0).gameObject:SetActive((self.ChapterIdxFlag == self.chapterNum - 1))
    end
end

function newSelectMapUp:upTop()
    self.view.root.top.name[UI.Text].text = self.battleCfg.name
    self.view.root.top.desc[UI.Text].text = self.battleCfg.desc
    self.view.root.top.left.gameObject:SetActive(self.ChapterIdxFlag > 1)
    self.view.root.top.right.gameObject:SetActive(self.ChapterIdxFlag < self.chapterNum)
    if self.view.root.top.left.gameObject.activeInHierarchy then
        --local cfg = self.battleList[self.ChapterIdxFlag - 1].data    
        CS.UGUIClickEventListener.Get(self.view.root.top.left.gameObject).onClick = function()
            self:changeChapter(-1)
        end
    end
    if self.view.root.top.right.gameObject.activeInHierarchy then
        --local cfg = self.battleList[self.ChapterIdxFlag + 1].data
        CS.UGUIClickEventListener.Get(self.view.root.top.right.gameObject).onClick = function()
            self:changeChapter(1)   
        end
    end
end

function newSelectMapUp:changeChapter(num)
    local battleCfg = self.battleList[self.nowIndex+num].data
    if module.QuestModule.Get(battleCfg.map_quest) and module.QuestModule.Get(battleCfg.map_quest).status == 0 then
        utils.SGKTools.LockMapClick(true)
        DialogStack.Push("bigMap/bigMap",{idx = self.data.idx+num,from = battleCfg.from_map_id,to = battleCfg.to_map_id,func = function ()
            module.QuestModule.Finish(battleCfg.map_quest)
            if UnityEngine.SceneManagement.SceneManager.GetActiveScene().name == "newSelectMapUp" then
                utils.EventManager.getInstance():dispatch("Fresh_Select_map")
            else
                SceneStack.Push("newSelectMapUp")
            end
            utils.SGKTools.LockMapClick(false)
        end})
    end
    self.ChapterIdxFlag = self.ChapterIdxFlag + num
    self.data.idx = self.data.idx + num
    fightModule.SetNowSelectChapter(self.data) 
    self:dataInit(fightModule.GetNowSelectChapter())
    CS.UnityEngine.GameObject.Destroy(self.ChapterRoot.gameObject)
    local obj = CS.UnityEngine.GameObject.Instantiate(SGK.ResourcesManager.Load("prefabs/newSelectMap/selectMaps/Chapter"..chapterCfg[tonumber(self.battleCfg["route"])].id .. ".prefab"), self.view.root.middle.transform)
    obj.name = "Chapter";
    self.ChapterRoot = CS.SGK.UIReference.Setup(obj)
    self:initData(self.chapterId)
    self:initUi()
end

function newSelectMapUp:initGiftFx()
    SGK.ResourcesManager.LoadAsync("prefabs/effect/UI/fx_item_reward.prefab", function(obj)
        if obj and self.view.root.left.giftBtn.fx.transform.childCount == 0 then
            CS.UnityEngine.GameObject.Instantiate(obj.transform,self.view.root.left.giftBtn.fx.transform)    
        end
    end)
end

function newSelectMapUp:initGiftBtn()
    --self.view.root.top.number[UI.Text].text = tostring(self.starCount)
    if not rewardModule.GetConfigByType(2, self.battleCfg.battle_id) then
        ERROR_LOG("one_time_reward id:", self.battleCfg.battle_id, "error")
        return
    end
    local _count = 0
    for i = 1, 3 do
        --local _view = self.view.root.top.Slider.Container[i]
        local _cfg = rewardModule.GetConfigByType(2, self.battleCfg.battle_id)[i]
        local _checkFlag = rewardModule.Check(_cfg.id)
        if (_checkFlag == rewardModule.STATUS.DONE) then
            _count = _count + 1
        end
    end
    CS.UGUIClickEventListener.Get(self.view.root.left.giftBtn.gameObject).onClick = function()
        DialogStack.PushPrefStact("selectMap/selectMapGift", {chapterId = self.battleCfg.battle_id, star = self.starCount, index = 2},self.view.root)
    end
    local _cfg = nil
    if _count < 3 then
        _cfg = rewardModule.GetConfigByType(2, self.battleCfg.battle_id)[_count + 1]
    else
        _cfg = rewardModule.GetConfigByType(2, self.battleCfg.battle_id)[3]
    end
    local _value = 0
    if _cfg and self.starCount then
        if self.starCount < _cfg.condition_value then
            self.view.root.left.giftBtn.Text[UI.Text].text = self.starCount.."/".._cfg.condition_value
            self.view.root.left.giftBtn.fx.gameObject:SetActive(false)
        else
            self.view.root.left.giftBtn.Text[UI.Text].text = self.starCount.."/".._cfg.condition_value
            self.view.root.left.giftBtn.fx.gameObject:SetActive(true)
        end
    end
    if _count == 3 then
        self.view.root.left.giftBtn.fx.gameObject:SetActive(false)
    end
    --self.view.root.top.Slider[UI.Slider].value = _count + _value
end

local difficultyCfg = {
    [1] = {pic = "pic1",type = "type1",name = "name1"},
    [2] = {pic = "pic2",type = "type2",name = "name2"},
    [3] = {pic = "pic3",type = "type3",name = "name3"},
}

function newSelectMapUp:upBottomToggle()
    for i = 1, #self.view.root.bottom.toggle do
        local _view = self.view.root.bottom.toggle[i]
        local _pic = self.battleCfg[difficultyCfg[i].pic]
        local _picTab = StringSplit(_pic, "|")
        local _type = self.battleCfg[difficultyCfg[i].type]
        local _typeTab = StringSplit(_type, "|")
        local _picFlag = 0
        if i ~= 1 then
            for k,p in ipairs(_typeTab) do
                if tonumber(p) ~= 3 then
                    _picFlag = tonumber(_picTab[k])
                    --print(sprinttb(_typeTab),k,_picTab[k])
                    break
                end
            end
            --local _cfg = MapConfig.GetMapMonsterConf(tonumber(_picTab[1]))
            local _info = fightModule.GetFightInfo(_picFlag)
                -- if self.difficultyIdx == i and _info:IsOpen() then
                --     _view[UI.Toggle].isOn = true
                -- else
                --     _view[UI.Toggle].isOn = _info:IsOpen()
                -- end
            _view[UI.Toggle].interactable = _info:IsOpen()
        else
            _view[UI.Toggle].interactable = true
        end
        if _view[UI.Toggle].interactable then
            self.difficultyIdx = i
            _view.Text[UI.Text].color = {r = 1, g = 1, b = 1, a = 1}
            _view.Text[CS.Outline].OutlineColor = {r = 0, g = 0, b = 0, a = 255}
        else
            _view.Text[UI.Text].color = {r = 0.5, g = 0.5, b = 0.5, a = 0.5}
            _view.Text[CS.Outline].OutlineColor = {r = 0, g = 0, b = 0, a = 144}
            -- if (self.difficultyIdx >= i) and (i > 1) then
            --     self.difficultyIdx = i - 1
            -- end
            --break
        end
    end
    self.view.root.bottom.toggle[self.difficultyIdx][UI.Toggle].isOn = true
    self.savedValues.difficultyIdx = self.difficultyIdx
    --self:UpMisty(self.difficultyIdx,true)
end

function newSelectMapUp:UpMisty(idx,init)
    if self.savedValues.chapterId ~= 1010 then
        return
    end
    if init then
        if idx == 1 then
            self:SetMistyValue(false,false,0)
        elseif idx == 2 then
            self:SetMistyValue(true,false,2)
        elseif idx == 3 then
            self:SetMistyValue(false,true,1)
        end
    else
        if self.difficultyIdx == 1 then
            if idx == 2 then
                self:SetMistyValue(true,false,2)
            elseif idx == 3 then
                self:SetMistyValue(false,true,1)
            end
        elseif self.difficultyIdx == 2 then
            if idx == 1 then
                self:SetMistyValue(false,false,0)
            elseif idx == 3 then
                self:SetMistyValue(false,true,1)
            end
        elseif self.difficultyIdx == 3 then
            if idx == 1 then
                self:SetMistyValue(false,false,0)
            elseif idx == 2 then
                self:SetMistyValue(true,false,2)
            end
        end
    end
end

function newSelectMapUp:SetMistyValue(white,red,num)
    if not self.MistyAnimator then
        ERROR_LOG("没有动画控制器")
        return
    end
    self.MistyAnimator:SetBool("white",white);
    self.MistyAnimator:SetBool("red",red);
    self.MistyAnimator:SetInteger("num",num);
end

function newSelectMapUp:initBottomToggle()
    for i = 1, #self.view.root.bottom.toggle do
        local _view = self.view.root.bottom.toggle[i]
        self.view.root.bottom.toggle[i][UI.Toggle].isOn = false
        CS.UGUIClickEventListener.Get(_view.gameObject).onClick = function()
            if _view[UI.Toggle].interactable then
                self:UpMisty(i)
                self.difficultyIdx = i
                self.savedValues.difficultyIdx = self.difficultyIdx
                self:initBoss()
            else
                local _pic = self.battleCfg[difficultyCfg[i].pic]
                local _picTab = StringSplit(_pic, "|")
                local _type = self.battleCfg[difficultyCfg[i].type]
                local _typeTab = StringSplit(_type, "|")
                local _picFlag = 0
                for k,p in ipairs(_typeTab) do
                    if tonumber(p) ~= 3 then
                        _picFlag = tonumber(_picTab[k])
                        break
                    end
                end
                --local _cfg = MapConfig.GetMapMonsterConf(tonumber(_picTab[1]))
                local _info = fightModule.GetFightInfo(_picFlag)
                if _info then
                    local _,desc = _info:IsOpen()
                    showDlgError(nil,desc)
                end
                -- if i == 2 then
                --     showDlgError(nil, SGK.Localize:getInstance():getValue("huiyilu_tips_05"))
                -- elseif i == 3 then
                --     showDlgError(nil, SGK.Localize:getInstance():getValue("huiyilu_tips_06"))
                -- end
            end
        end
    end
    --self.view.root.bottom.toggle[self.difficultyIdx][UI.Toggle].isOn = true
    self:upBottomToggle()
end

function newSelectMapUp:getStarCount()
    local _count = 0
    for i,v in ipairs(difficultyCfg) do
        local _pic = self.battleCfg[difficultyCfg[i].pic]
        local _picTab = StringSplit(_pic, "|")
        local _type = self.battleCfg[difficultyCfg[i].type]
        local _typeTab = StringSplit(_type, "|")
        --print("zoe star",sprinttb(_picTab),sprinttb(_typeTab))
        for k,v in pairs(_typeTab) do
            if tonumber(v) ~= 3 then
                --local _cfg = MapConfig.GetMapMonsterConf(tonumber(p))
                --print("zoe ",_picTab[5])
                local _info = fightModule.GetFightInfo(tonumber(_picTab[k]))
                for j = 1, 3 do
                    if fightModule.GetOpenStar(_info.star, j) ~= 0 then
                        _count = _count + 1
                    end
                end
            end
        end
        --print("zoe star",_count,sprinttb(_picTab))
        -- for k,p in pairs(_picTab) do
        --     local _cfg = MapConfig.GetMapMonsterConf(tonumber(p))
        --     if _cfg then
        --         local _info = fightModule.GetFightInfo(_cfg.fight_config)
        --         for j = 1, 3 do
        --             if fightModule.GetOpenStar(_info.star, j) ~= 0 then
        --                 _count = _count + 1
        --             end
        --         end
        --     end
        -- end
    end
    return _count
end

function newSelectMapUp:initBoss()
    local CurrentFlag = true
    local _root = self.ChapterRoot.ScrollView.Viewport.Content
    local _pic = self.battleCfg.pic
    if (self.savedValues.chapterId and self.savedValues.chapterId == 1020) then
        self.difficultyIdx = 1
    end
    if difficultyCfg[self.difficultyIdx] then
        _pic = self.battleCfg[difficultyCfg[self.difficultyIdx].pic]
    end
    -- if self.difficultyIdx == 2 then
    --     if fightModule.GetFightInfo(self.battleList[self.nowIndex].data.finish_id):IsPassed() then
    --         _pic = self.battleCfg.pic2
    --     else
    --         self.difficultyIdx = 1
    --     end
    -- end
    local _picTab = StringSplit(_pic, "|")
    local _type = self.battleCfg[difficultyCfg[self.difficultyIdx].type]
    local _typeTab = StringSplit(_type, "|")
    local _name = self.battleCfg[difficultyCfg[self.difficultyIdx].name]
    local _nameTab = StringSplit(_name, "|")
    local _chapter_id = self.battleCfg.chapter_name
    local _chapter_idTab = StringSplit(_chapter_id, "|")
    local _mode = self.battleCfg.type_mode
    local _modeTab = StringSplit(_mode, "|")
    self.starCount = self:getStarCount()
    local _showPosCount = 0
    for i,v in ipairs(self.doTweenList) do
        v:Kill()
    end
    self.doTweenList = {}
    self.isOpenList = {}
    for i = 1, #_typeTab do
        if tonumber(_typeTab[i]) ~= 3 then
            local _picCfg = _picTab[i]
            if tonumber(_picCfg) then
                --local _cfg = MapConfig.GetMapMonsterConf(tonumber(_picCfg))
                local _info = fightModule.GetFightInfo(tonumber(_picCfg))
                if _info then
                    local _fightCfg = fightModule.GetConfig(nil, nil, tonumber(_picCfg))
                    local _bossView = _root.bossList["item"..i]
                    -- if tonumber(_cfg.script) ~= 1 then
                    --     _bossView = self.view.root.middle.bossList["item"..i].unPt
                    --     utils.IconFrameHelper.Create(_bossView.IconFrame, {id = _cfg.mode, type = 41, count = 0 })
                    -- end
                    for p = 1, 3 do
                        _bossView.icon["item"..p].gameObject:SetActive(false)
                    end
                    local activeIdx = 0
                    if tonumber(_typeTab[i]) == 0 then
                        _bossView.icon["item"..1].gameObject:SetActive(true)
                        activeIdx = 1
                    elseif tonumber(_typeTab[i]) == 1 then
                        _bossView.icon["item"..3].gameObject:SetActive(true)
                        _bossView.icon["item"..3].mask.icon[UI.Image]:LoadSprite("icon/".._modeTab[i])
                        activeIdx = 3
                    end
                    for j = 1, 3 do
                        local _idx = 1
                        if fightModule.GetOpenStar(_info.star, j) ~= 0 then
                            _idx = 0
                        end
                        _bossView.icon["item"..activeIdx].star["star"..j][CS.UGUISpriteSelector].index = _idx
                    end
                    -- if _bossView.icon["item"..activeIdx].star["star"..1][CS.UGUISpriteSelector].index == 1 then
                    --     self.view.root.middle.bossList["item"..i].pos[CS.UGUISpriteSelector].index = 1
                    -- end
                    _bossView.title[UI.Text].text = _chapter_idTab[i]
                    _bossView.name[UI.Text].text = _nameTab[i]
                    -- if tonumber(_cfg.script) == 2 then
                    --     _bossView.bg[CS.UGUISpriteSelector].index = 0
                    -- elseif tonumber(_cfg.script) == 3 then
                    --     _bossView.bg[CS.UGUISpriteSelector].index = 1
                    -- end
                    local _openStatus, _closeInfo = _info:IsOpen()
                    _bossView.lock:SetActive(not _openStatus)
                    if _openStatus then
                        _bossView.icon["item"..activeIdx][CS.UGUISpriteMaterialSelector].index = 0
                        _bossView.icon["item"..3].mask.icon[CS.UGUISpriteMaterialSelector].index = 0
                    else
                        _bossView.icon["item"..activeIdx][CS.UGUISpriteMaterialSelector].index = 1
                        _bossView.icon["item"..3].mask.icon[CS.UGUISpriteMaterialSelector].index = 1
                    end
                    _root.bossList["item"..i][UnityEngine.CanvasGroup]:DORewind()
                    _root.bossList["item"..i][UnityEngine.CanvasGroup].alpha = 1
                    _bossView.combatRoot:SetActive(_info:IsOpen() and not _info:IsPassed())
                    self.isOpenList[i] = (_info:IsOpen() and not _info:IsPassed())
                    if _bossView.combatRoot.gameObject.transform.childCount == 0 and (_info:IsOpen() and not _info:IsPassed()) then
                        if CurrentFlag then
                            local obj = CS.UnityEngine.GameObject.Instantiate(SGK.ResourcesManager.Load("prefabs/effect/UI/fx_ui_suoding.prefab"),_bossView.combatRoot.gameObject.transform)
                            obj.transform.localPosition = Vector3(0, 0, 0);
                            CurrentFlag = false
                        end
                        self:UpCurrentPointScrollBar(_typeTab,i)
                    end
                    _bossView:SetActive(true)

                    _root.bossList["item"..i].transform:DORewind()
                    _root.bossList["item"..i]:SetActive(false)
                    local _do = _root.bossList["item"..i].transform:DOLocalMoveZ(0, _showPosCount / 30):OnComplete(function()
                        _root.bossList["item"..i]:SetActive(true)
                    end)
                    table.insert(self.doTweenList, _do)

                    -- if not _openStatus then
                    --     self.view.root.middle.bossList["item"..i].pos[CS.UGUISpriteSelector].index = 0
                    -- end
                    CS.UGUIClickEventListener.Get(_bossView.icon["item"..activeIdx].gameObject).onClick = function()
                        _info:IsOpen()
                        --print(tonumber(_picCfg))
                        if not _openStatus then
                            showDlgError(nil, _closeInfo)
                        else
                            --print("zoe查看滚动位置",self.ChapterRoot.ScrollView[CS.UnityEngine.UI.ScrollRect].verticalNormalizedPosition)
                            DialogStack.PushPrefStact("newSelectMap/newGoCheckpoint", {gid = tonumber(_picCfg)}, self.view.root.gameObject)
                        end
                    end
                    CS.UGUIClickEventListener.Get(_bossView.icon["item"..activeIdx].gameObject).tweenStyle = 2
                end
            end
        else
            local _picCfg = _picTab[i]
            local _bossView = _root.bossList["item"..i]
            for p = 1, 3 do
                _bossView.icon["item"..p].gameObject:SetActive(false)
            end
            _bossView.icon["item"..2].gameObject:SetActive(true)
            _bossView.title[UI.Text].text = _chapter_idTab[i]
            _bossView.name[UI.Text].text = _nameTab[i]
            local questCfg = self:getQuest(tonumber(_picCfg))
            local _openStatus, _closeInfo = self:storyQuestIsOpen(tonumber(_picCfg))
            _bossView.lock:SetActive(not _openStatus)
            if _openStatus then
                _bossView.icon["item"..2][CS.UGUISpriteMaterialSelector].index = 0
            else
                _bossView.icon["item"..2][CS.UGUISpriteMaterialSelector].index = 1
            end
            _bossView.combatRoot:SetActive(self:getStoryQuestFlag(tonumber(_picCfg)))
            self.isOpenList[i] = self:getStoryQuestFlag(tonumber(_picCfg))
            if _bossView.combatRoot.gameObject.transform.childCount == 0 and self:getStoryQuestFlag(tonumber(_picCfg)) then
                if CurrentFlag then
                    local obj = CS.UnityEngine.GameObject.Instantiate(SGK.ResourcesManager.Load("prefabs/effect/UI/fx_ui_suoding.prefab"),_bossView.combatRoot.gameObject.transform)
                    obj.transform.localPosition = Vector3(-1.5, 0, 0);
                    CurrentFlag = false
                end
                self:UpCurrentPointScrollBar(_typeTab,i)
            end
            _bossView:SetActive(true)
            CS.UGUIClickEventListener.Get(_bossView.icon["item"..2].gameObject).onClick = function()
                if not _openStatus then
                    showDlgError(nil, _closeInfo)
                else
                    module.QuestModule.Accept(tonumber(_picCfg))
                    DialogStack.PushPrefStact("newSelectMap/newGoStroyPoint", {story_id = tonumber(questCfg.story_id),state = true,questId = tonumber(_picCfg)}, self.view.root.gameObject)
                    --LoadGuideStory(tonumber(questCfg.story_id),nil,true)
                end
            end
            CS.UGUIClickEventListener.Get(_bossView.icon["item"..2].gameObject).tweenStyle = 2
        end
    end
    for k,v in pairs(self.isOpenList) do
        if v then
            self.scrollbarFlag = true
        end
    end
    if not self.scrollbarFlag then
    --print("kkkkkkkkkkkkkkkkk",sprinttb(self.isOpenList))
        self:initScrollbar()
    end
    self.isOpenList = {}
end

function newSelectMapUp:UpCurrentPointScrollBar(_typeTab,i)
    self.recordScrollValue = nil
    if self.routeId == 7 then
        if i == 1 or i == 2 or i == 3 then
            self.recordScrollValue = 0.0
        elseif i == 4 or i == 5 or i == 6 then
            self.recordScrollValue = 0.45
        elseif i == 7 then
            self.recordScrollValue = 0.65
        elseif i == 8 then
            self.recordScrollValue = 0.8
        else
            self.recordScrollValue = 1.0
        end
    else
        if #_typeTab < 8 then
            if i == 1 or i == 2 or i == 3 then
                self.recordScrollValue = 0.0
            elseif i == 4 then
                self.recordScrollValue = 0.35
            elseif i == 5 then
                self.recordScrollValue = 0.85
            else
                self.recordScrollValue = 1.0
            end
        else
            if i == 1 or i == 2 or i == 3 then
                self.recordScrollValue = 0.0
            elseif i == 4 or i == 5  then
                self.recordScrollValue = 0.3
            elseif i == 6 then
                self.recordScrollValue = 0.55
            elseif i == 7 then
                self.recordScrollValue = 0.8
            else
                self.recordScrollValue = 1.0
            end
        end
    end
    self.ChapterRoot.ScrollView.ScrollbarVertical[CS.UnityEngine.UI.Scrollbar].value = self.recordScrollValue
    fightModule.SetScroolbarValue(self.savedValues.chapterId,self.savedValues.selectMapIndx,self.recordScrollValue)
end

function newSelectMapUp:getStoryQuestFlag(questid)
    --print("zoe查看任务配置",questid,sprinttb(module.QuestModule.Get(questid)))
    --if module.QuestModule.Get(questid) then
        local questCfg = module.QuestModule.Get(questid)
        if questCfg and questCfg.status == 1 then
            return false
        else
            questCfg = self:getQuest(questid)
        end
        --print("zoe查看任务配置",questid,sprinttb(questCfg))
        if not questCfg then
            return false
        end
        if questCfg.depend_fight_id ~=0 then
            if not module.fightModule.GetFightInfo(questCfg.depend_fight_id):IsPassed() then
                return false
            end
        end
        if questCfg.depend_quest_id ~=0 then
            if not module.QuestModule.Get(questCfg.depend_quest_id) or module.QuestModule.Get(questCfg.depend_quest_id).status == 0 then
                return false
            end
        end
        return true
    -- else
    --     return false
    -- end
end

function newSelectMapUp:getQuest(questid)
    --print("zoe查看任务配置",questid)
    local questCfg = nil
    if questid~=0 then
        -- for i,v in pairs(self.allQuestCfg) do
        --     if v.id == questid then
        --         --print("zoe查看任务配置",questid)
        --         return v
        --     end
        -- end
        questCfg = module.QuestModule.GetCfg(questid)
    end
    if questCfg then
        return questCfg
    else
        return nil
    end
end

function newSelectMapUp:dataInit(data)
    self.difficultyIdx = 1
    if data and data.chapterId and data.idx then
        self.savedValues.chapterId = data.chapterId -- 1010 历练 1020 伙伴
        self.savedValues.selectMapIndx = data.idx -- 1到n 表示第几章节
        if data.difficultyIdx then
            --print(sprinttb(data),data.difficultyIdx)
            self.difficultyIdx = data.difficultyIdx -- 难度标识 1 简单 2 困难 3 噩梦
            self.savedValues.difficultyIdx = self.difficultyIdx
        end
    end
    if self.savedValues.difficultyIdx then
        self.difficultyIdx = self.savedValues.difficultyIdx
    end
    self.updateTime = 0;
    --print("5sssssss555555dsd55",self.updateTime)
    self.timeLimit = 0;
    self:initBaseData()
    self:initData()
end

function newSelectMapUp:getLastIndex()
    for i,v in ipairs(self.battleList) do
        local _info = fightModule.GetFightInfo(v.data.finish_id)
        if fightModule.GetOpenStar(_info.star, 1) == 0 then
            if v.data.quest_id ~= 0 then
                local _quest = module.QuestModule.Get(v.data.quest_id)
                if _quest and _quest.status == 1 then
                    return i
                else
                    return i - 1
                end
            else
                return i
            end
        end
    end
    return #self.battleList
end

function newSelectMapUp:initData(chapterId)
    self.battleList = {}
    self.ringAnimator = nil
    local _chapterId = chapterId
    if not chapterId then
        _chapterId = self.savedValues.chapterId or self:getLastChapter()
    end
    self.savedValues.chapterId = _chapterId
    local _list = fightModule.GetConfig(_chapterId).battleConfig
    for k,v in pairs(_list) do
        table.insert(self.battleList, {id = k, data = v})
    end
    table.sort(self.battleList, function(a, b)
        return a.id < b.id
    end)
    if not chapterId then
        if not self.savedValues.selectMapIndx then
            self.nowIndex = self:getLastIndex()
        else
            self.nowIndex = self.savedValues.selectMapIndx
        end
    end
    self.savedValues.selectMapIndx = self.nowIndex
    self.battleCfg = self.battleList[self.nowIndex].data
    --print("zoe查看副本 _list",self.nowIndex,sprinttb(self.battleCfg))
end


function newSelectMapUp:initBaseData()
    local _list = fightModule.GetConfig()
    self.battleListIdx = {}
    for k,v in pairs(_list) do
        table.insert(self.battleListIdx, {id = k, data = v})
    end
    table.sort(self.battleListIdx, function(a, b)
        return a.id < b.id
    end)
    self.baseBattleList = {}
    for i,v in ipairs(self.battleListIdx) do
        self.baseBattleList[v.id] = {idx = i, data = v.data}
    end
end

function newSelectMapUp:isOpen(battleCfg, _battleCfg)
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
        local data = module.RankListModule.GetSelfStarInfo()
        if battleCfg.depend_star_count > data[1] then
            return false,5
        end
    end
    return true
end

function newSelectMapUp:storyQuestIsOpen(questid)
    local questCfg = self:getQuest(questid)
    --print(questCfg)
    if questCfg then
        if questCfg.depend_fight_id ~=0 then
            if not module.fightModule.GetFightInfo(questCfg.depend_fight_id):IsPassed() then
                --return false,"前置战斗关卡未完成"
                return false,SGK.Localize:getInstance():getValue("huiyilu_tips_08",module.fightModule.GetPveConfig(questCfg.depend_fight_id).scene_name)
            end
        end
        if questCfg.depend_quest_id ~=0 then
            if not module.QuestModule.Get(questCfg.depend_quest_id) or module.QuestModule.Get(questCfg.depend_quest_id).status == 0 then
                --return false,"前置剧情关卡未完成"
                return false,SGK.Localize:getInstance():getValue("huiyilu_tips_08",self:getQuest(questCfg.depend_quest_id).name)
            end
        end
        return true,nil
    else
        return false,"任务不存在"
    end
end

function newSelectMapUp:openStar(star)
    local _counst = 0
    for i = 1, 3 do
        if fightModule.GetOpenStar(star, i) ~= 0 then
            _counst = _counst + 1
        end
    end
    return _counst
end

function newSelectMapUp:isOpenBase(battleCfg)
    if battleCfg.rely_battle ~= nil and battleCfg.rely_battle ~= 0 then
        local _cfg = fightModule.GetBattleConfig(battleCfg.rely_battle)
        if _cfg then
             for k,v in pairs(_cfg.pveConfig) do
                 if not fightModule.GetFightInfo(k):IsPassed() then
                     return false
                 end
             end
        end
    end
    if battleCfg.quest_id ~= nil and battleCfg.quest_id ~= 0 then
        if module.QuestModule.Get(battleCfg.quest_id) == nil or module.QuestModule.Get(battleCfg.quest_id).status ~= 1 then
            return false
        end
    end
    return true
end


function newSelectMapUp:getLastChapter()
    --print("1111111111")
    local _battleList = {}
    local _list = fightModule.GetConfig()
    for k,v in pairs(_list) do
        table.insert(_battleList, {id = k, data = v})
    end
    table.sort(_battleList, function(a, b)
        return a.id < b.id
    end)
    local _starBattle = nil
    local _chapter_id = nil
    for k,v in ipairs(_battleList) do
        for p,j in pairs(v.data.battleConfig) do
            if not _starBattle then
                for a,z in pairs(j.pveConfig) do
                    if self:openStar(fightModule.GetFightInfo(a).star) ~= 3 then
                        _starBattle = v.data.chapter_id
                    end
                end
            end
            if not self:isOpenBase(j) then
                if not _chapter_id then
                    return j.chapter_id
                end
                return _chapter_id
            end
            _chapter_id = j.chapter_id
        end
    end
    if not _starBattle then
        return _battleList[#_battleList].id
    end
    return _starBattle
end

function newSelectMapUp:initMainQuest()
    local _questList = module.QuestModule.GetList(10, 0)
    self.view.root.bottom.mainQuest:SetActive(#_questList > 0)
    if self.view.root.bottom.mainQuest.activeSelf then
        self.view.root.bottom.mainQuest.root.name[UI.Text].text =_questList[1].name
        if _questList[1].name_color ~= "" then
            self.view.root.bottom.mainQuest.root.name[UI.Text].text ="<color=#".._questList[1].name_color.."FF>".._questList[1].name.."</color>"
        end
        self.view.root.bottom.mainQuest.root.des[UI.Text].text =_questList[1].desc1
        self.view.root.bottom.mainQuest.root.IconFrame:SetActive(true)
        if _questList[1].priority ~= 0 and _questList[1].reward[1] then
            utils.IconFrameHelper.Create(self.view.root.bottom.mainQuest.root.IconFrame,{type = _questList[1].reward[1].type, id = _questList[1].reward[1].id, count = _questList[1].reward[1].value, showDetail = true})
        end
        if module.QuestModule.CanSubmit(_questList[1].id) then
            self.view.root.bottom.mainQuest.root.canCommit.gameObject:SetActive(true)
            self.view.root.bottom.mainQuest.root.name[UI.Text].text = "<color=#59FF94FF>".._questList[1].name.." [完成]".."</color>"
        else
            self.view.root.bottom.mainQuest.root.canCommit.gameObject:SetActive(false)
        end
        self.view.root.bottom.mainQuest.root.icon[UI.Image]:LoadSprite("icon/".._questList[1].icon)
        CS.UGUIClickEventListener.Get(self.view.root.bottom.mainQuest.root.gameObject).onClick = function()
            if module.QuestModule.CanSubmit(_questList[1].id) then
                module.QuestModule.Finish(_questList[1].id)
            else
                DialogStack.PushPrefStact("mapSceneUI/newQuestList", {hideBtn = true, questId = _questList[1].id},self.view.root)
            end
        end
    end
end

function newSelectMapUp:Update()
    if not self.updateTime then
        --print(self.updateTime)
        return
    end 
    if self.timeLimit ~= 0 and Time.now() - self.updateTime >= 1 then
        self.updateTime = Time.now();
        local time = self.timeLimit - Time.now();
        if time > 0 then
            self.view.root.left.bossBtn.Text:SetActive(true);
            self.view.root.left.bossBtn.Text[UI.Text].text = GetTimeFormat(time, 2, 2);
        elseif time == 0 then
            self.view.root.left.bossBtn.Text:SetActive(false);
            self.view.root.left.bossBtn.name:SetActive(false);
        end
    end
end

function newSelectMapUp:newPlayer()
    if module.QuestModule.Get(100108) and module.QuestModule.Get(100108).status == 1 and module.QuestModule.Get(10004).status == 0 and self.newPlayerFlag then
        self.newPlayerFlag = false
        LoadStory(10000401, function()
            DialogStack.PushPref("mapSceneUI/guideLayer/createCharacter", {func = function()
                module.QuestModule.Accept(20001)
                utils.SGKTools.CloseFrame()
            end}, UnityEngine.GameObject.FindWithTag("UGUIRootTop"))
        end,false,true)
    end
end

function newSelectMapUp:listEvent()
    return {
        "ONE_TIME_REWARD_INFO_CHANGE",
        "QUEST_INFO_CHANGE",
        "LOCAL_GUIDE_CHANE",
        "BOSS_TIP_CLOSE",
        "LOCLA_MAPSCENE_SHOW_QUICKTOHERO",
        "UPDATE_LOCAL_NOTE_REDDOT",
        "AFTER_ITEM_INFO_CHANGE",
        "server_respond_8",
        "START_CREATE_STORY",
        "NEW_PALYER_STORY_OVER",
        "AFTER_QUEST_INFO_CHANGE",
        "GiftBoxPre_to_FlyItem",
        "Fresh_Select_map",
        "LOCAL_SOTRY_DIALOG_CLOSE",
    }
end

function newSelectMapUp:onEvent(event, data)
    --ERROR_LOG("=========",event);
    if event == "ONE_TIME_REWARD_INFO_CHANGE" then
        self:initGiftBtn()
    elseif event == "QUEST_INFO_CHANGE" then
        --if data.status and data.status == 1 then
        -- if data and data.id and (data.id == 100102 or data.id == 100103) then
        --     self:init()
        -- end
        if data and module.QuestModule.Get(100103) and module.QuestModule.Get(100103).status == 1 and data.cfg and data.cfg.cfg.type and (data.cfg.cfg.type == 10 or data.cfg.cfg.type == 11) then
            if data.id == 100103 then
                --print("zoe查看任务change",sprinttb(data))
                return
            end
            self:initData(self.chapterId)
            self:initUi()
            --print("zoe55555555") 
            self:newPlayer()
        end
        --end
        if data and data.id and tonumber(data.id) == 10004 and tonumber(data.status) == 1 then
            SceneStack.EnterMap(1,nil,true)
        end
    elseif event == "AFTER_QUEST_INFO_CHANGE" then
        self:initGuide()
    elseif event == "LOCLA_MAPSCENE_SHOW_QUICKTOHERO" then
        --print("zoe123456789")
        if self.view.quickToHeroNode.transform.childCount > 0 or not GetGetItemTipsState() then
            return
        end
        local _ic = module.EquipHelp.QuickToHero(data)
        if _ic then
            local _equip = module.equipmentModule.GetByUUID(_ic.newUuid)
            if _equip.heroid ~= 0 then
                return
            end
            if _ic.oldUuid then
                DialogStack.PushPref("mapSceneUI/item/quickToHeroChange", module.EquipHelp.QuickToHero(data), self.view.quickToHeroNode)
            else
                DialogStack.PushPref("mapSceneUI/item/quickToHero", module.EquipHelp.QuickToHero(data), self.view.quickToHeroNode)
            end
            module.EquipHelp.OpenFlag()
        end
    elseif event == "LOCAL_GUIDE_CHANE" then
        self:initGuide()
    elseif event == "BOSS_TIP_CLOSE" then
        self.view.root.left.bossBtn[UnityEngine.CanvasGroup]:DOFade(1, 0.3);
    elseif event == "UPDATE_LOCAL_NOTE_REDDOT" then
        self.view.root.left.noteBtn.redDot.gameObject:SetActive(module.RedDotModule.GetStatus(module.RedDotModule.Type.CheckPoint.DailyCheckPointTask, nil,self.view.root.left.noteBtn.redDot))
    elseif event == "AFTER_ITEM_INFO_CHANGE" then
        if data then
            for k,v in pairs(data) do
                local _cfg = utils.ItemHelper.Get(utils.ItemHelper.TYPE.ITEM, v[1])
                if _cfg.sub_type == 21 and v[1] == 21000 then
                    self:initGuide()
                end
            end
        end
    -- elseif event == "server_respond_8" then    
    -- --     module.QuestModule.Accept(100102)
    -- --     module.QuestModule.Accept(100103)
    --     ERROR_LOG("server_respond_8",module.Time.now())
    --     module.fightModule.SetNowSelectChapter({chapterId=1010, idx = 1, difficultyIdx = 1, chapterNum = 1})
    --     self:init(1111)
    elseif event == "NEW_PALYER_STORY_OVER" then
        self:init()
    elseif event == "START_CREATE_STORY" then
        self:init()
    elseif event == "GiftBoxPre_to_FlyItem" then
        local targetObj =  UnityEngine.GameObject.FindWithTag("UGUIRootTop")
        if targetObj then
            local ScreenHeight = UnityEngine.Screen.height /  UnityEngine.Screen.width * 750;
            local localPos = targetObj.transform:TransformPoint(Vector3(-750/3+20,-ScreenHeight/2+50,0))
            utils.SGKTools.FlyItem({localPos.x,localPos.y,0},data)
        end
    elseif event == "Fresh_Select_map" then
        self:init()
    elseif event == "LOCAL_SOTRY_DIALOG_CLOSE" then
        self:initBGM()
    end
end

return newSelectMapUp
