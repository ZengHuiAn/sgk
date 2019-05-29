local MapConfig = require "config.MapConfig"
local QuestModule = require "module.QuestModule"
local activityConfig = require "config.activityConfig"
local buildScienceConfig = require "config.buildScienceConfig"
local BuildScienceModule = require "module.BuildScienceModule"
local View = {}

function View:Start(data)
	self.view = SGK.UIReference.Setup(self.gameObject);

    self.tweenFlag = true

    self.mapCfg=MapConfig.GetMapConf()
    self.mapId = data.mapId

    self.cityId = data.cityId; 
    self:initClick()

    local info = BuildScienceModule.QueryScience(self.cityId);
    if info then
        self.science = info;
        self.title = info.title;
        self:FreshAll();
    end

    self.Tip = self.view.Bottom.Tip
    self.list = module.HuntingModule.GetMapList()
    self:initUi()
end

function View:initClick()
    CS.UGUIClickEventListener.Get(self.view.closeBtn.gameObject).onClick=function() 
        --DialogStack.Pop()
        utils.EventManager.getInstance():dispatch("Second_BigMap_Close")
        CS.UnityEngine.GameObject.Destroy(self.view.gameObject)
    end
    CS.UGUIClickEventListener.Get(self.view.mask.gameObject).onClick=function() 
        --DialogStack.Pop()
        utils.EventManager.getInstance():dispatch("Second_BigMap_Close")
        CS.UnityEngine.GameObject.Destroy(self.view.gameObject)
    end
end

function View:initUi()
    --self:initCurrencyChat()
    self.clickFlag = false
    self:FreshAll()
    self:initScollView()
end

function View:initCurrencyChat()
    local CurrencyChat = CS.UnityEngine.GameObject.Instantiate(SGK.ResourcesManager.Load("prefabs/base/CurrencyChat.prefab"), self.view.transform)
    self.CurrencyChat = CS.SGK.UIReference.Setup(CurrencyChat.gameObject)
    self.CurrencyChat.UGUIResourceBar.BottomBar.gameObject:SetActive(false)
end

function View:initScollView()
    --print(sprinttb(self.list))
    self.ScrollView = self.view.Bottom.ScrollView[CS.UIMultiScroller]
    self.mapList = self:GetSecondMapList(self.mapId)
    table.sort(self.mapList, function(a,b) 
        return a.depend_level < b.depend_level;
    end)
    self.ScrollView.RefreshIconCallback = function (obj,idx)
        self:UpdateOneMap(SGK.UIReference.Setup(obj), self.mapList[idx + 1],idx);
    end
    self.ScrollView.DataCount = #self.mapList
end

function View:UpdateOneMap(view, _map,idx)
    if _map.mapImage then
        view.Image[UnityEngine.UI.Image]:LoadSprite("guanqia/gq_icon/".._map.mapImage);
    else
        view.Image[UnityEngine.UI.Image]:LoadSprite("guanqia/gq_icon/gq_icon_6");
    end
    view.pos[UI.Text].text = _map.map_name
    local map = self.list[_map.gid]
    if map then 
        view.pos.Limit.Text:TextFormat("狩猎推荐等级 {0}+", map.depend_level_id);
        if map.depend_level_id > module.playerModule.Get().level then
            view.pos.Limit.Text[UI.Text].color = UnityEngine.Color.red
        else
            view.pos.Limit.Text[UI.Text].color = UnityEngine.Color.yellow
        end

        view.Lock:SetActive(_map.depend_level > module.playerModule.Get().level);
    else
        view.pos.Limit.Text:TextFormat("狩猎推荐等级 {0}+", 199);
        if 199 > module.playerModule.Get().level then
            view.pos.Limit.Text[UI.Text].color = UnityEngine.Color.red
        else
            view.pos.Limit.Text[UI.Text].color = UnityEngine.Color.yellow
        end
        view.Lock:SetActive(_map.depend_level > module.playerModule.Get().level);
    end

    -- view.Flag:SetActive(map.duration ~= 0);
    if _map.use_icon == "0" then
        view.ImageFrame3.gameObject:SetActive(false)
    else
        view.ImageFrame3.gameObject:SetActive(true)
        local productList = StringSplit(_map.use_icon,"|")
        for i=1,3 do
            if productList[i] then
                view["Element"..i][UnityEngine.UI.Image]:LoadSprite("icon/"..productList[i].."_small")
                view["Element"..i].gameObject:SetActive(true)
            end
        end
    end
    -- local elements = map.monster_property1 | map.monster_property2 | map.monster_property3;

    -- local n = 1;
    -- for i = 0, 5 do
    --     if (elements & (1<<i)) ~= 0 then
    --         view['Element' .. n]:SetActive(true);
    --         view['Element' .. n][CS.UGUISpriteSelector].index = i;
    --         n = n + 1;
    --     end
    -- end

    -- for i = n, 3 do
    --     view['Element' .. i]:SetActive(false);
    -- end


    if self.clickFlag then
        CS.UGUIClickEventListener.Get(view.gameObject).onClick = function()
            if _map.depend_level <= module.playerModule.Get().level then
                SceneStack.EnterMap(_map.gid)
            else
                self.Tip:SetActive(false);
                self.Tip.transform:SetParent(view.gameObject.transform, true);
                self.Tip.Text[UI.Text]:TextFormat("{0}级解锁", _map.depend_level);
                self.Tip[UnityEngine.CanvasGroup]:DOKill();
                self.Tip[UnityEngine.CanvasGroup].alpha = 1;
                local pos = self.Tip.transform.position;
                self.Tip.transform.position = Vector3(pos.x, view.gameObject.transform.position.y, pos.z);
                self.Tip:SetActive(true);
                self.Tip[UnityEngine.CanvasGroup]:DOFade(0, 1):SetDelay(1);
            end
        end
    end
    
    if self.tweenFlag then
        view.transform:DOLocalMove(UnityEngine.Vector3(-750,view[UnityEngine.RectTransform].anchoredPosition.y,0),0.05):OnComplete(function ()
            view:SetActive(true);
            view.transform:DOLocalMove(UnityEngine.Vector3(0,view[UnityEngine.RectTransform].anchoredPosition.y,0),0.4):OnComplete(function ()
                self.clickFlag = (idx == #self.mapList - 1) or idx >= 6 
                if (idx == #self.mapList - 1) or idx >= 6 then
                    self.ScrollView:ItemRef()
                end
            end)
        end):SetDelay(idx*0.05)
        if #self.mapList >= 7 and idx >= 6  then
            self.tweenFlag = false
        else
            self.tweenFlag = (idx ~= #self.mapList - 1)
        end
    else
        view:SetActive(true);
    end
end

function View:FreshAll()
    self:FreshTop();
    self:FreshUnion();
    self:FreshQuiaty();
end

function View:FreshUnion()
    coroutine.resume( coroutine.create( function ( ... )

        if self.title == 0 then
            self.view.Top.topinfo.baseInfo.unionName.Text[UI.Text].text = SGK.Localize:getInstance():getValue("chengshitongzhi_"..self.cfg.type)
            return;
        end
        -- GetSelfUnion
        local unionInfo = module.unionModule.Manage:GetUnion(self.title)

        --print("刷新公会",sprinttb(unionInfo))
        if unionInfo then
            self.view.Top.topinfo.baseInfo.unionName.Text[UI.Text].text = unionInfo.unionName or ""
        -- else
        --     ERROR_LOG("union is nil,id")
        end
    end ) )
end


function View:FreshQuiaty()
    self.view.Top.topinfo.changePoint[CS.UGUISpriteSelector].index = self.cfg.city_quality - 1;
    self.view.CityTip.Text[UI.Text].text = SGK.Localize:getInstance():getValue("daditu_0"..(self.cfg.city_quality))
    self.view.CityTip:SetActive(true)
    self.view.CityTip:SetActive(false)
    self.view.CityTip[UnityEngine.CanvasGroup].alpha = 1
    --self.view.CityTip[UnityEngine.RectTransform].sizeDelta = CS.UnityEngine.Vector2(self.view.CityTip[UnityEngine.RectTransform].sizeDelta.x,self.view.CityTip.Text[UnityEngine.RectTransform].sizeDelta.y + 25)
    CS.UGUIPointerEventListener.Get(self.view.Top.topinfo.changePoint.gameObject).onPointerDown = function()
        self.view.CityTip:SetActive(true)
    
        self.view.CityTip[UnityEngine.RectTransform].sizeDelta = CS.UnityEngine.Vector2(self.view.CityTip[UnityEngine.RectTransform].sizeDelta.x,self.view.CityTip.Text[UI.Text].preferredHeight + 30)
    end

    CS.UGUIPointerEventListener.Get(self.view.Top.topinfo.changePoint.gameObject).onPointerUp = function()
        self.view.CityTip:SetActive(false)
    end
end

function View:FreshTop()
    self.view.Top.mapName[UI.Text].text = MapConfig.GetMapConf(self.mapId).map_name

    self.info = QuestModule.CityContuctInfo()
    
    self.cfg = activityConfig.GetCityConfig(self.cityId)
    
    if not self.info or not self.info.boss or not next(self.info.boss)  then

        -- print("信息不足",sprinttb(self.info));
        return;
    end

    -- print("=====刷新繁荣度======",sprinttb(self.info),sprinttb(self.cfg));
    local lastLv,exp,_value = activityConfig.GetCityLvAndExp(self.info,self.cfg.type);

    -- GetCityLvAndExp
    --print("城市等级",lastLv,exp,_value);

    self.lastLv = lastLv;
    if self.lastLv then
        --todo
        self.view.Top.topinfo.baseInfo.Slider.Text[UI.Text].text =exp.."/".._value;
        self.view.Top.topinfo.baseInfo.lv[UI.Text].text = self.lastLv;

        self.view.Top.topinfo.baseInfo.Slider[UI.Slider].value = exp/_value;
    end
    
end

function View:GetSecondMapList(mapId)
    local mapList = {}
    for k,v in pairs(self.mapCfg) do
        if v.chat == MapConfig.GetMapConf(mapId).chat and v.map_type ~= 6 then
            mapList[#mapList+1]=v
        end
    end
    return mapList
end

function View:OnDestory()

end

function View:listEvent()
    return {
    }
end

function View:onEvent(event,data)
    if event == "LOCAL_SLESET_MAPID_CHANGE" then
        self.cityId = data; 
        BuildScienceModule.QueryScience(self.cityId);
        self:FreshAll();
    elseif event == "CITY_CONTRUCT_INFO_CHANGE" then
        self:FreshTop();
    elseif event == "QUERY_SCIENCE_SUCCESS" then
        --print("查到科技信息","=================")
        if data == self.cityId then
            local info = BuildScienceModule.GetScience(self.cityId);

            self.science = info;
            self.title = info.title;
            self:FreshAll();
        end
    elseif event == "UPGRADE_SUCCESS" then
        if data == self.cityId then
            local info = BuildScienceModule.GetScience(self.cityId);

            self.science = info;
            --公会
            self.title = info.title;
            self:FreshAll();
        end
    end
end


return View;