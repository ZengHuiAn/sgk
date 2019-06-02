local answerModule = require "module.answerModule"
local ItemHelper= require"utils.ItemHelper"
local playerModule = require "module.playerModule"
local weekRanking = {}

function weekRanking:Start()
    self:initData()
    self:initUi()
end

function weekRanking:initData()
    self.rankingTab = answerModule.GetRankingInfo()
    -- self.rankingTab = {
    --     [1] = {score = 36, id = 463856567992},
    --     [2] = {score = 24, id = 1510305696},
    --     [3] = {score = 22, id = 1510305692},
    --     [4] = {score = 3, id = 15103056961},
    --     [5] = {score = 1, id = 15103056963},
    -- }
end

function weekRanking:initUi()
    self.view = CS.SGK.UIReference.Setup(self.gameObject)
    CS.UGUIClickEventListener.Get(self.view.weekRankingRoot.closeBtn.gameObject).onClick = function()
        DialogStack.Pop()
    end
    self:initScrollView()
end

function weekRanking:utf8sub(size, input)
    local len  = string.len(input)
    local left = len
    local cnt  = 0
    local _count = 0
    local arr  = {0, 0xc0, 0xe0, 0xf0, 0xf8, 0xfc}
    while left ~= 0 do
        local tmp = string.byte(input, -left)
        local i   = #arr
        while arr[i] do
            if tmp >= arr[i] then
                left = left - i
                break
            end
            i = i - 1
        end
        if i ~= 1 then
            _count = _count + i
        else
            cnt = cnt + 1
        end
        if (cnt + _count) >= size then
            return string.sub(input, 1, cnt + _count)
        end
    end
    return input;
end

function weekRanking:initScrollView()
    self.ScrollView = self.view.weekRankingRoot.ScrollView[CS.UIMultiScroller]
    self.ScrollView.RefreshIconCallback = function (obj,idx)
        local _view = CS.SGK.UIReference.Setup(obj)
        local _tab = self.rankingTab[idx + 1]
        local _index = idx + 1
        if self.rankingTab[idx + 1] and self.rankingTab[idx] then
            if self.rankingTab[idx + 1].score == self.rankingTab[idx].score then
                local _obj = self.ScrollView:GetItem(idx-1)
                local _viewObj = CS.SGK.UIReference.Setup(_obj)
                _index = _viewObj.ranking[UI.Text].text
            end
        end
        _view.ranking[UI.Text].text = tostring(_index)
        _index=tonumber(_index)
        _view.firstBg:SetActive(_index == 1)
        _view.bg:SetActive(_index ~= 1)
        _view.one:SetActive(_index==1)
        _view.two:SetActive(_index==2)
        _view.three:SetActive(_index==3)
        
        if _tab.name then
            _view.name[UI.Text].text = _tab.name
            utils.IconFrameHelper.Create(_view.IconFrame, {customCfg={
                    icon    = _tab.icon,
                    quality = 0,
                    star    = 0,
                    level   = 0,
            }, type = 42})
        else
            if playerModule.IsDataExist(_tab.id) then
                _view.name[UI.Text].text = playerModule.IsDataExist(_tab.id).name
                utils.IconFrameHelper.Create(_view.IconFrame, {customCfg={
                        icon    = playerModule.IsDataExist(_tab.id).head,
                        quality = 0,
                        star    = 0,
                        level   = 0,
                }, type = 42})
            else
                playerModule.Get(_tab.id,(function( ... )
                    _view.name[UI.Text].text = playerModule.IsDataExist(_tab.id).name
                    utils.IconFrameHelper.Create(_view.IconFrame, {customCfg={
                            icon    = playerModule.IsDataExist(_tab.id).head,
                            quality = 0,
                            star    = 0,
                            level   = 0,
                    }, type = 42})
                end))
            end
        end
        _view.score[UI.Text].text = tostring(_tab.score)

        local _scrollView = _view.ScrollView[CS.UIMultiScroller]
        _scrollView.RefreshIconCallback = function (_objItem, _idx)
            local _viewItem = CS.SGK.UIReference.Setup(_objItem)
            local _valueTab = answerModule.GetRankingItem(_tab.id)[_idx+1]
            --local _valueTab = {type = 41, id = 90002, value = 10}

            utils.IconFrameHelper.Create(_viewItem.IconFrame, {type = _valueTab.type, id = _valueTab.id, count = _valueTab.value})
            _objItem.gameObject:SetActive(true)
        end
        _scrollView.DataCount = #answerModule.GetRankingItem(_tab.id)
        --_scrollView.DataCount = 5


        obj.gameObject:SetActive(true)
    end
    self.ScrollView.DataCount = #self.rankingTab
end

function weekRanking:deActive()
	utils.SGKTools.PlayDestroyAnim(self.gameObject)
	return true;
end

return weekRanking
