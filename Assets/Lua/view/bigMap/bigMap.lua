local MapConfig = require "config.MapConfig"
local QuestModule = require "module.QuestModule"
local activityConfig = require "config.activityConfig"
local buildScienceConfig = require "config.buildScienceConfig"
local openMapNameId = {
    [1]=22,
    [2]=8,
    [3]=10,
    [4]=30,
    [5]=19,
    [6]=27,
    [7]=28,
    [8]=32,
};
local city = {
    [1]=22,
    [2]=8,
    [3]=10,
    [4]=30,
    [5]=19,
    [6]=27,
    [7]=28,
    [8]=32,
};
local cityType = {
    [1]=45,
    [2]=43,
    [3]=44,
    [4]=41,
    [5]=42,
    [6]=48,
    [7]=46,
    [8]=47,
};
local closeMapNameId = {
    [1]=35,
    [2]=43,
    [3]=20,
    [4]=36,
    [5]=44,
    [6]=46,
    [7]=45,
    [8]=33,
};
local secondMapNameId = {
    [1] = {
	    [1]=23,
    	[2]=49,
    	[3]=50,
    	[4]=51,
    	[5]=21,
    	[6]=22,
    	[7]=48,
  	},
	[2] = {
    	[1]=8,
    	[2]=13,
    	[3]=202,
    	[4]=201,
    	[5]=203,
    	[6]=204,
    	[7]=37,
    	[8]=6,
    	[9]=38,
	},
	[3] = {
		[1]=10,
    	[2]=9, 
	},
};
local numToText = {
    [2] = "two",
    [4] = "four",
    [5] = "five",
    [7] = "seven",
    [11] = "eleven",
}
local View = {}
function View:Start(data)
	self._view = SGK.UIReference.Setup(self.gameObject);
	self.view = SGK.UIReference.Setup(self._view.ScrollView.Viewport.Content.mask.gameObject);
	self.heroCfg = utils.ItemHelper.Get(utils.ItemHelper.TYPE.HERO, 11000)
	self.mapCfg=MapConfig.GetMapConf()
	--print("zoe查看gid对应地图",sprinttb(self.mapCfg[202]))
	self.allQuestCfg=QuestModule.GetCfg()
	-- for i,v in pairs(self.allQuestCfg) do
 --    	if v.id==101071 then
 --     	    print("zoe查看任务配置",sprinttb(v))
 --     	end
 --    end
    --print("zoe界面创建成功zoe界面创建成功",self.heroCfg.level)
    -- for i,v in pairs(self.mapCfg) do
    -- 	print("zoe查看地图名字",v.map_name,v.chat)
    -- end
    --print("zoe查看地图配置",sprinttb(self.mapCfg))
    self.levelquesttb = {}
    --self.questtb = {}
    self:initUI()
    self:initClick()
    --print("zoe0.0.0.0.0",sprinttb(QuestModule.Get(10100804)))
    local CurrencyChat = CS.UnityEngine.GameObject.Instantiate(SGK.ResourcesManager.Load("prefabs/base/CurrencyChat.prefab"), self._view.transform)
    self.CurrencyChat = CS.SGK.UIReference.Setup(CurrencyChat.gameObject)
    self.CurrencyChat.UGUIResourceBar.BottomBar.gameObject:SetActive(false)
    if data then
        self._view.closeBtn.gameObject:SetActive(false)
        self.CurrencyChat.gameObject:SetActive(false)
        self:playAnim(data)
    end
end

function View:playAnim(data)
    if not numToText[data.idx] then
        DialogStack.Pop()
        --print("111111111",data.idx)
        if data.func then
            data.func()
        end
        return
    end
    self._view.ScrollView[UI.ScrollRect].verticalNormalizedPosition = 0
    local animObj = self.view.anim[numToText[data.idx]]
    animObj.gameObject:SetActive(true)
    local findIdx = self:findFromOrToIdx(data.from)
    local toIdx = self:findFromOrToIdx(data.to)
    if findIdx == 999 then
        self.view.player.transform.position = self.view.home.node.transform.position
    else
        self.view.player.transform.position = self.view.nodeList["node"..findIdx].open.transform.position
    end
    self.view.player:SetActive(true)

    if toIdx == 999 then
        self.view.player.transform:DOMove(self.view.home.node.transform.position,1.5)
    else
        SGK.Action.DelayTime.Create(0.35):OnComplete(function()
            self.view.player.transform:DOMove(self.view.nodeList["node"..toIdx].open.transform.position,1.5)
        end)
    end
    SGK.Action.DelayTime.Create(0.35):OnComplete(function()
        animObj.bg.load[UnityEngine.RectTransform]:DOSizeDelta(UnityEngine.Vector2(0, 0), 1.5):OnComplete(function ()
            DialogStack.CleanAllStack()
            if data.func then
                data.func()
            end
        end)
    end)
end

function View:findFromOrToIdx(id)
    if id == 1 then
        return 999
    else
        for i=1,8 do
            if openMapNameId[i] == id then
                return i
            end
        end
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

function View:GetFisrtMapLimitLV(mapList)
    local minLimit = nil
    local maxLimit = nil
    for k,v in pairs(mapList) do
        if minLimit == nil then
            minLimit = v.depend_level
        end
        if maxLimit == nil then
            maxLimit = v.depend_level
        end
        if v.depend_level > maxLimit then
            maxLimit = v.depend_level
        end
        if v.depend_level < minLimit then
            minLimit = v.depend_level
        end
    end
    return minLimit, maxLimit
end

function View:initUI()
	local v = nil
	for i=1,#self.view.levelList do
		--for j,v in pairs(self.mapCfg) do
			--if self.view.levelList[i].bg.bgText[UI.Text].text==v.map_name then
				v = self.mapCfg[openMapNameId[i]]
                self.view.levelList[i].bg.bgText[UI.Text].text=v.map_name
                --print("zoe查看地图配置",v,v.map_name,sprinttb(v))
                --local num = tonumber(v.chat)
                --self.view.levelList[i].No.text.numText2[CS.UGUISpriteSelector].index=num%10
                --self.view.levelList[i].No.text.numText1[CS.UGUISpriteSelector].index=math.floor(num/10)
                local secondMapList = self:GetSecondMapList(openMapNameId[i])
                local min, max = self:GetFisrtMapLimitLV(secondMapList)
                --print("zoe查看二级地图列表",min, max,sprinttb(secondMapList))
                self.view.levelList[i].No.Text.Lv[UI.Text].text = min.."~"..max
                --break
		    --end 
		--end
	end
end

function View:GoHome()
    CS.UGUIClickEventListener.Get(self.view.home.level.gameObject).onClick=function()
        if utils.SGKTools.Athome() then 
            DialogStack.Pop()
        else
            SceneStack.EnterMap(1)
        end
    end
end

function View:initClick()
	CS.UGUIClickEventListener.Get(self._view.closeBtn.gameObject).onClick=function() 
        DialogStack.Pop()
    end
    for i=1,#self.view.levelList do
    	if not self.view.levelList[i].mask.gameObject.activeInHierarchy then
    	    CS.UGUIClickEventListener.Get(self.view.levelList[i].gameObject).onClick=function()
                self._view.closeBtn.gameObject:SetActive(false)
                DialogStack.PushPref("bigMap/bigMapSecond",{mapId = openMapNameId[i],cityId = city[i]},self._view.secondRoot.transform)
            end
        end    
    end
    self:GoHome()
    self:initInfoBtnClick()
end

function View:UnionInfo(i)
    
    local info = QuestModule.CityContuctInfo(nil,true)
    if info and info.boss and next(info.boss)~=nil then
        --local cityCfg= activityConfig.GetCityConfig()
        local _mapId=city[i]
        local map_info_confi = activityConfig.GetCityConfig(_mapId);
        coroutine.resume( coroutine.create( function ()
            local _unionInfo = module.BuildScienceModule.QueryScience(_mapId)
            if _unionInfo.title == 0 then
                --print("i无工会");
                -- self.cfg.type   --地图类型
                self.view.levelList[i].info.unionName[UI.Text].text = SGK.Localize:getInstance():getValue("chengshitongzhi_"..map_info_confi.type)
            else
                --print("iyou工会");
                local unionInfo = module.unionModule.Manage:GetUnion(_unionInfo.title)
                --print("i占领工会",sprinttb(unionInfo));
                self.view.levelList[i].info.unionName[UI.Text].text= unionInfo and  unionInfo.unionName or '-'
            end
            --print("zoe bigmap",_mapId,sprinttb(map_info_confi))
            local buildLV = activityConfig.GetCityLvAndExp(info,nil,_mapId)
            self.view.levelList[i].info.Lv[UI.Text].text="Lv"..buildLV
        end ) )
        self.view.levelList[i].info.LvStage[CS.UGUISpriteSelector].index=tonumber(map_info_confi.city_quality) - 1
        --print("zoe查看地图配置",sprinttb(map_info_confi),self.view.levelList[i].info.LvStage[CS.UGUISpriteSelector].index)

    else
        QuestModule.CityContuctInfo(true)
    end
end

function View:techInfo(i)
    
    local info = QuestModule.CityContuctInfo(nil,true)
    if info and info.boss and next(info.boss)~=nil then
        
        local _mapId=city[i]

        assert(coroutine.resume( coroutine.create( function ()
            local _unionInfo = module.BuildScienceModule.QueryScience(_mapId)
            local questGroup = info.boss[cityType[i]] and info.boss[cityType[i]].quest_group
            local taskCfg = activityConfig.GetCityTaskGroupConfig(questGroup)
            local text ="今日任务："..taskCfg.name
            local cfg = buildScienceConfig.GetConfig(_mapId);
            if not cfg then
                print("不是争夺战地图")
                return;
            end
--获取地图的今日任务
            local guild_cfg = buildScienceConfig.GetScienceConfig(_mapId,8);
            if not guild_cfg then
                text=text.."\n关卡领主：无\n"
                text=text.."\n关卡科技："
            else
                local _unionInfo = module.BuildScienceModule.QueryScience(_mapId)
                if _unionInfo.data[8] == 0 then
                    text=text.."\n关卡领主：未激活\n"
                else
                    text=text.."\n关卡领主：已激活\n"
                end
                text=text.."\n关卡科技："
            end
            local lastLv = activityConfig.GetCityLvAndExp(info,nil,_mapId)--self.science.data[v. technology_type];
            for k,v in pairs(cfg) do
                local _guild_CFG = buildScienceConfig.GetScienceConfig(_mapId,v.technology_type);
                local lockLev = _guild_CFG[1].city_level;
                if not lastLv or lastLv < lockLev then
                    text=text.."\n"..v.name..":未解锁"
                else
                    local _unionInfo = module.BuildScienceModule.QueryScience(_mapId)
                    if _unionInfo.data[v.technology_type] == 0 then
                        text=text.."\n"..v.name..":未解锁"
                    else
                        text=text.."\n"..v.name..":Lv".._unionInfo.data[v.technology_type]
                    end
                end
            end

            self.view.detailInfo.bg.Text[UI.Text].text=text
            if _unionInfo.title == 0 then
                local map_info_confi = activityConfig.GetCityConfig(_mapId);
                -- self.cfg.type   --地图类型
                self.view.levelList[i].info.unionName[UI.Text].text = SGK.Localize:getInstance():getValue("chengshitongzhi_"..map_info_confi.type)
            else
                --print("iyou工会");
                local unionInfo = module.unionModule.Manage:GetUnion(_unionInfo.title)
                --print("i占领工会",sprinttb(unionInfo));
                if unionInfo then
                    self.view.levelList[i].info.unionName[UI.Text].text=unionInfo.unionName
                end   
                --print("zoe mapSceceUI    ",_mapId,sprinttb(unionInfo))
            end
        end )))
        -- local buildLV = activityConfig.GetCityLvAndExp(info,nil,_mapId)
        -- self.view.levelList[i].info.Lv[UI.Text].text="Lv"..buildLV
    else
        QuestModule.CityContuctInfo(true)
    end
end

function View:checkPos(_objRect,maxHeight)
	if _objRect.anchoredPosition.y<0 and (_objRect.sizeDelta.y+math.abs(_objRect.anchoredPosition.y))*2>maxHeight then
		--print("zoe查看背景宽度",_objRect.sizeDelta.y)
		_objRect.anchoredPosition=UnityEngine.Vector2(_objRect.anchoredPosition.x,_objRect.anchoredPosition.y+_objRect.sizeDelta.y+25)
	end
end

function View:changeInfoAndPos(obj)
	local x = obj.bg[UnityEngine.RectTransform].sizeDelta.x
	local y = obj.bg.Text[UI.Text].preferredHeight+30
	--print("zoe查看preferredHeight",obj.bg.Text[UI.Text].preferredHeight,y)
    obj.bg[UnityEngine.RectTransform].sizeDelta=UnityEngine.Vector2(x,y)
end

function View:initInfoBtnClick()
	local obj = self.view.detailInfo
	CS.UGUIClickEventListener.Get(obj.mask.gameObject).onClick=function()
        obj.gameObject:SetActive(false)
    end
    local maxHeight = self.view.bg[UnityEngine.RectTransform].sizeDelta.y
	for i=1,#self.view.levelList do
        self:UnionInfo(i)
        CS.UGUIClickEventListener.Get(self.view.levelList[i].info.infoBtn.gameObject).onClick=function()
            obj.bg.gameObject.transform:SetParent(self.view.levelList[i].info.gameObject.transform)
            --print("zoe查看btn位置",self.view.levelList[i].info.infoBtn[UnityEngine.RectTransform].anchoredPosition,self.view.levelList[i].info.infoBtn[UnityEngine.RectTransform].anchoredPosition.x)
            self:techInfo(i)
			--obj.bg.Text[UI.Text].text="暂无领主".."\n".."暂无领主".."\n".."暂无领主".."\n".."暂无领主"--.."\n".."暂无领主".."\n".."暂无领主".."\n".."暂无领主".."\n".."暂无领主".."\n".."暂无领主".."\n".."暂无领主".."\n".."暂无领主".."\n".."暂无领主".."\n".."暂无领主".."\n".."暂无领主".."\n".."暂无领主".."\n".."暂无领主".."\n".."暂无领主"
    		obj.bg[UnityEngine.RectTransform].anchoredPosition=UnityEngine.Vector2(self.view.levelList[i].info.infoBtn[UnityEngine.RectTransform].anchoredPosition.x-106,self.view.levelList[i].info.infoBtn[UnityEngine.RectTransform].anchoredPosition.y-10)
            obj.bg.gameObject.transform:SetParent(obj.gameObject.transform)
            --self.view.levelList[i].info.bg.gameObject.transform:SetParent(obj.gameObject.transform)
            obj.gameObject:SetActive(true)
            --self:changeInfoAndPos(obj)
            --print("zoe查看背景宽度",obj.bg[UnityEngine.RectTransform].sizeDelta.y)
            self:checkPos(obj.bg[UnityEngine.RectTransform],maxHeight)
        end
	end
end

function View:getQuestName(questid)
    --print("zoe查看任务配置",questid)
	if questid~=0 then
	    for i,v in pairs(self.allQuestCfg) do
    	    if v.id == questid then
     	        --print("zoe查看任务配置",questid)
     	        return v.desc
     	    end
        end
    end
    return "获取任务错误"
end

function View:chooseClick(gid,gameObject)
	local _level=nil
    local _quest=nil
    for i,v in pairs(self.levelquesttb) do
        if gid == v[1] then
        	--print("zoezoezeozeoze",v,sprinttb(v))
        	_level = v[2]
        	_quest = v[3]
        	break
      	end
    end
    if self.heroCfg.level < tonumber(_level) then
    	CS.UGUIClickEventListener.Get(gameObject).onClick=function()
        	showDlgError(nil, string.format("<color=#ffd800>%d</color> 级开启",_level))
        end	    
    elseif not self:checkQuest(tonumber(_quest)) then
    	local questName=nil 
    	questName = self:getQuestName(_quest)
    	CS.UGUIClickEventListener.Get(gameObject).onClick=function()
            showDlgError(nil, string.format("任务 <color=#ffd800>%s</color> 未完成",questName))
        end        
   	end
end

function View:checkQuest(id)
	if id ~= 0 then
	    local questCfg=QuestModule.Get(id)
        if questCfg == nil or questCfg.status == 0 then
        	return false
        end 
    end
    return true
end

function View:OnDestory()

end

function View:listEvent()
    return {
    "Second_BigMap_Close",
    }
end

function View:onEvent(event,data)
    if event == "Second_BigMap_Close" then
        self._view.closeBtn.gameObject:SetActive(true)
    end
end


return View;