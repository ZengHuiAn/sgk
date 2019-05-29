local AwardModule = require "module.AwardModule"
local ItemHelper = require"utils.ItemHelper"
local ItemModule = require"module.ItemModule"
local View = {};

function View:Start(data)
    self.root = CS.SGK.UIReference.Setup(self.gameObject);
    self.view = self.root.view;
    self.awardList = data and data.list or {};
    self.reward_count = 0;
    self.allItem = {};
    self.allItemTab = {};
    self.content = self.view.top.ScrollView.Viewport.Content;
    self.allItemView = self.view.bottom.allGift.ScrollView[CS.UIMultiScroller];
    self.reward_item = {};

	self:InitData();
    self:InitView();
    SetTipsState(false);
    self.doing = true;
    self:StartGetOfflineAward(0.5);
end

function View:InitData()
    -- local offlineAward = AwardModule.GetOfflineAward();
    -- local allItem = {};
    -- if offlineAward[3] then
    --     for i,v in ipairs(offlineAward[3]) do
    --         if allItem[v[2]] == nil then
    --             allItem[v[2]] = 0;
    --         end
    --         allItem[v[2]] = allItem[v[2]] + v[3]
    --     end
    --     local sort = {};
    --     for k,v in pairs(allItem) do
    --         local info = {};
    --         info.type = 41;
    --         info.id = k;
    --         info.count = v;
    --         table.insert(sort, info);
    --     end
    --     table.sort(sort, function ( a,b )
    --         return a.id < b.id;
    --     end)
    --     self.allItem = sort;
    -- end
    
end

function View:InitView()
    self.allItemView.RefreshIconCallback = function (obj, idx)
        local _objView = CS.SGK.UIReference.Setup(obj)
        local _cfg = self.allItemTab[idx + 1];
        -- local _itemCfg = ItemHelper.Get(_cfg[1], _cfg[2], nil, _cfg[3])
        -- _objView[SGK.newItemIcon]:SetInfo(_itemCfg)
        -- _objView[SGK.newItemIcon].showDetail = true;
        utils.IconFrameHelper.Create(_objView,{type = _cfg[1], id = _cfg[2], count = _cfg[3], showDetail = true});
        obj.gameObject:SetActive(true)
    end

    CS.UGUIClickEventListener.Get(self.view.title.close.gameObject).onClick = function()
        self.doing = false;
        -- UnityEngine.Object.Destroy(self.gameObject)
        DialogStack.Pop();
    end
    CS.UGUIClickEventListener.Get(self.root.mask.gameObject, true).onClick = function()
        self.doing = false;
        -- UnityEngine.Object.Destroy(self.gameObject)
        DialogStack.Pop();
    end
    CS.UGUIClickEventListener.Get(self.view.bottom.stopBtn.gameObject).onClick = function()
        self.doing = false;
        self.view.bottom.finishBtn:SetActive(true);
        self.view.bottom.stopBtn:SetActive(false);
    end
    CS.UGUIClickEventListener.Get(self.view.bottom.finishBtn.gameObject).onClick = function()
        -- UnityEngine.Object.Destroy(self.gameObject)
        DialogStack.Pop();
    end
    -- CS.UGUIClickEventListener.Get(self.view.bg.help.gameObject).onClick = function()
    --     local data = {};
    --     data.msg = SGK.Localize:getInstance():getValue("offline_reward");
    --     data.confirm = function () end;
    --     data.title = SGK.Localize:getInstance():getValue("zhaomu_shuoming_01");
    --     DlgMsg(data)
    -- end
end

function View:AddAward(info)
    local date = os.date("%Y/%m/%d",math.floor(info.time));
    self.date = date;
    local _scrollView = nil;
    if  self.reward_item[date] == nil then
        local object = UnityEngine.Object.Instantiate(self.content.rewardItem.gameObject);
        object.transform:SetParent(self.content.gameObject.transform,false);
        local item = CS.SGK.UIReference.Setup(object);
        item.count[UnityEngine.UI.Text]:TextFormat("{0} 补偿奖励",date);
        _scrollView = item.ScrollView[CS.UIMultiScroller];
        _scrollView.RefreshIconCallback = function (obj, idx)
            local _objView = CS.SGK.UIReference.Setup(obj)
            local _cfg = self.reward_item[date].list[idx + 1];
            -- local _itemCfg = ItemHelper.Get(_cfg[1], _cfg[2], nil, _cfg[3])
            -- _objView[SGK.newItemIcon]:SetInfo(_itemCfg)
            -- _objView[SGK.newItemIcon].showDetail = true;
            utils.IconFrameHelper.Create(_objView,{type = _cfg[1], id = _cfg[2], count = _cfg[3], showDetail = true});
            obj.gameObject:SetActive(true)
        end
        item:SetActive(true);
        self.reward_item[date] = {};
        self.reward_item[date].obj = item;
        self.reward_item[date].list = info.list;
        self.reward_item[date].index = {};
        for i,v in ipairs(info.list) do
            self.reward_item[date].index[v[2]] = i;
        end
    else
        print("重复", date, sprinttb(self.reward_item[date]))
        _scrollView = self.reward_item[date].obj.ScrollView[CS.UIMultiScroller];
        for i,v in ipairs(info.list) do
            local index = self.reward_item[date].index[v[2]];
            if index then
                self.reward_item[date].list[index][3] = self.reward_item[date].list[index][3] + v[3];
            else
                table.insert(self.reward_item[date].list, v);
                self.reward_item[date].index[v[2]] = #self.reward_item[date].list;
            end
        end
    end

    _scrollView.DataCount = #self.reward_item[date].list
    print("添加",sprinttb(self.reward_item))
end

function View:UpdateAllItem(info)
    for i,v in ipairs(info.list) do
        if self.allItem[v[2]] == nil then
            self.allItem[v[2]] = {};
            for k,j in ipairs(v) do
                self.allItem[v[2]][k] = j;
            end
        else
            self.allItem[v[2]][3] = self.allItem[v[2]][3] + v[3]
        end
    end

    local _allItem = {};
    for k,v in pairs(self.allItem) do
        table.insert(_allItem, v)
    end
    print("总计",sprinttb(_allItem))
    self.allItemTab = _allItem;
    -- print("总共", sprinttb(self.allItemTab))
    self.allItemView.DataCount = #self.allItemTab;
    self.allItemView:ItemRef();
end

function View:StartGetOfflineAward(time)
    StartCoroutine(function()
        WaitForSeconds(time)
        if self.doing then
            AwardModule.GetOfflineAward(self.awardList[self.reward_count + 1].time)
        end
    end)
end

function View:OnDestroy()
    if #self.allItemTab > 0 then
        SetItemTipsState(true)
        for i,v in ipairs(self.allItemTab) do
            PopUpTipsQueue(1,{v[2], v[3], v[1]})
        end
        self.allItemTab = {};
    end
    SetTipsState(true);
    AwardModule.GetOfflineAwardList(true);
end

function View:deActive()
	utils.SGKTools.PlayDestroyAnim(self.gameObject)
	return true;
end

function View:listEvent()
	return {
		"OFFLINE_REWARD_CHANGE",
	}
end

function View:onEvent(event, ...)
    print("onEvent", event, ...);
    local data = ...;
    if event == "OFFLINE_REWARD_CHANGE"  then
        self.reward_count = self.reward_count + 1;
        self:AddAward(data);
        self:UpdateAllItem(data);
        if self.reward_count < #self.awardList then
            self:StartGetOfflineAward(0.5);
        else
            self.doing = false;
            self.view.bottom.finishBtn:SetActive(true);
            self.view.bottom.stopBtn:SetActive(false);
        end
	end
end

return View;