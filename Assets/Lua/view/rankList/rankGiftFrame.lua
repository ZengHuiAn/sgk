local RankListModule = require "module.RankListModule"
local ItemModule = require "module.ItemModule"
local ItemHelper = require "utils.ItemHelper"
local rankGiftFrame = {}

local Type = {
    Level = 1,
    Star = 2,
    Wealth=3,
    TrialTower=4,--爬塔
}
local WeekType = {
    Day = 0,
    Week = 1,  
}
local FirstWeekType = {
    No = 0,
    First = 1,   
}
function rankGiftFrame:Start(data)
    self.root = CS.SGK.UIReference.Setup(self.gameObject)
    self.view=self.root.view
    self.view.title[UI.Text].text=SGK.Localize:getInstance():getValue("biaoti_jiangli_01")
    self.rewardType = data and data.type or Type.Level
    self.notPop = data and data.notPop or 0;
    self:initUi()
end

function rankGiftFrame:initUi()
    CS.UGUIClickEventListener.Get(self.root.mask.gameObject, true).onClick = function()
        if self.notPop == 0 then
            DialogStack.Pop()
        else
            UnityEngine.GameObject.Destroy(self.gameObject);
        end
    end
    CS.UGUIClickEventListener.Get(self.view.closeBtn.gameObject).onClick = function()
        if self.notPop == 0 then
            DialogStack.Pop()
        else
            UnityEngine.GameObject.Destroy(self.gameObject);
        end
    end

    
    local weekType = WeekType.Week

    --是否为首周
    self.firstWeekType=module.Time.now()-module.Time.openServerTime()>86400*7 and 0 or 1
    if self.rewardType == Type.Wealth then
        self.list = module.PVPArenaModule.GetRankReward()
    else    
        self.list = RankListModule.GetRankRewardCfg(self.rewardType) 
    end

    self:InDropDownShow() 
    self:upRewardList(self.rewardType==Type.Wealth and weekType+1 or weekType)
end
local rankRewardType = {{[1]="每日",[2]="每周"},{[1]="每日",[2]="每周"},{[1]="周六",[2]="周日",[3]="段位提升"},{[1]="每日",[2]="每周"}}
local weekDayTab = {[0]="日","一","二","三","四","五","六"}
function rankGiftFrame:InDropDownShow()
    local _DropDown = self.view.bottom.filter.DropdownTime
    _DropDown[UnityEngine.UI.Dropdown]:ClearOptions(); 
    if self.rewardType==Type.Wealth then 
        for i=1,#self.list do
            _DropDown[SGK.DropdownController]:AddOpotion(rankRewardType[self.rewardType][i])
        end
        _DropDown[UI.Dropdown].value = 0
        _DropDown.Label[UI.Text].text = rankRewardType[self.rewardType][1]

        _DropDown[UI.Dropdown].onValueChanged:AddListener(function (value)
            self:upRewardList(value+1)
        end)
    else    
        for i=1,#self.list.weekTypeList do
            _DropDown[SGK.DropdownController]:AddOpotion(SGK.Localize:getInstance():getValue(self.list.weekTypeList[i].name))
        end

        _DropDown[UI.Dropdown].value=0
        _DropDown.Label[UI.Text].text=SGK.Localize:getInstance():getValue(self.list.weekTypeList[1].name)

        _DropDown[UI.Dropdown].onValueChanged:AddListener(function (value)
            self:upRewardList(self.list.weekTypeList[value+1].type)
        end)
    end
    self.view.bottom.Tip:SetActive(self.rewardType ~= Type.Wealth)
    local timeTab = RankListModule.GetRankListSentRewardTime(self.rewardType)
    if timeTab then
        local _time = timeTab.starTime + timeTab.duration
        if timeTab.duration == 86400 then
            local starTime = os.date("%H:%M:%S",_time)
            self.view.bottom.Tip[UI.Text].text = SGK.Localize:getInstance():getValue("paihangbang_jiangli_04",starTime)
        elseif timeTab.duration == 604800 then
            local HMS_time = os.date(" %H:%M:%S",_time)
            local week_day = tonumber(os.date("%w",timeTab.starTime))
            self.view.bottom.Tip[UI.Text].text = SGK.Localize:getInstance():getValue("paihangbang_jiangli_03",string.format("%s %s ",weekDayTab[week_day],HMS_time))
        else
            self.view.bottom.Tip:SetActive(false)
        end
    end
end

local rewardItemUI={}
function rankGiftFrame:upRewardList(type)
    local list={}
    if self.rewardType==Type.Wealth then
        table.sort(self.list[type],function (a,b)
            return a.Rank1>b.Rank1
        end)
        list=self.list[type]
    else
        list=self.list[type][self.firstWeekType].list
    end
    
    self.UIDragIconScript = self.view.ScrollView.Viewport.Content[CS.ScrollViewContent]
    self.UIDragIconScript.RefreshIconCallback = function (obj, idx)
        obj:SetActive(true)
        local Item = CS.SGK.UIReference.Setup(obj.gameObject)
        local _cfg = list[idx + 1]

        local _UIDragIconScript = Item.giftContent.Viewport.Content[CS.ScrollViewContent]
        local dataList={}
        _UIDragIconScript.RefreshIconCallback = function (_obj, _idx)
            _obj:SetActive(true)
            local rewardIcon = CS.SGK.UIReference.Setup(_obj)
            local rewardCfg = dataList[_idx+1]
            local _itemCfg = ItemHelper.Get(rewardCfg[1],rewardCfg[2],nil,rewardCfg[3])
            utils.IconFrameHelper.Create(rewardIcon.IconFrame, {customCfg=_itemCfg,showDetail=true,pos=2});
            rewardIcon.Text[UI.Text].text=_itemCfg.name
        end

        if self.rewardType==Type.Wealth then
            Item.rankPlace[UI.Text].text=_cfg.rank_name
            for i=1,2 do
                if _cfg["Item_id"..i] ~= 0 then
                   table.insert(dataList,{_cfg["Item_type"..i],_cfg["Item_id"..i],_cfg["Item_value"..i]})
                end
            end
           _UIDragIconScript.DataCount =#dataList
        else    
            Item.rankPlace[UI.Text].text=string.format(_cfg.rank_lower == _cfg.rank_upper and "第%s名" or "第%s-%s名",_cfg.rank_lower,_cfg.rank_upper)
            if  _cfg.reward_type==44 then--服务器用直接打开的礼包
                local packageId=_cfg.reward_id
                ItemModule.GetGiftItem(packageId, function(data)
                    dataList=data
                    _UIDragIconScript.DataCount =#data
                end)
            end
        end   
    end
    self.UIDragIconScript.DataCount =#list
end

return rankGiftFrame
