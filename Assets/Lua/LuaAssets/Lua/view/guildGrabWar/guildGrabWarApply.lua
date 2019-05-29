local GuildSeaElectionModule = require "module.GuildSeaElectionModule"
local GuildGrabWarModule = require "module.GuildGrabWarModule"
local activityConfig = require "config.activityConfig"
local buildScienceConfig = require "config.buildScienceConfig"
local Time = require "module.Time"
local View = {};
function View:Start(data)
	self.root = CS.SGK.UIReference.Setup(self.gameObject);
    self.view = self.root.view;
    self.updateTime = 0;
    self.cityInfo = {};
	self:InitView();
	self:UpdateData();
end

function View:InitView()
	CS.UGUIClickEventListener.Get(self.root.BG.gameObject).onClick = function ( object )
        DialogStack.Pop();
        -- UnityEngine.GameObject.Destroy(self.gameObject);
   	end
    CS.UGUIClickEventListener.Get(self.view.title.close.gameObject).onClick = function ( object )
        DialogStack.Pop();
        -- UnityEngine.GameObject.Destroy(self.gameObject);
    end
    self.view.ScrollView[CS.UIMultiScroller].RefreshIconCallback = function ( obj,idx )
        local info = self.cityInfo[idx + 1];
        local item = CS.SGK.UIReference.Setup(obj);
        item.icon[UI.Image]:LoadSprite("icon/buildCity/"..info.cfg.city_picture);
        item.icon.stage[CS.UGUISpriteSelector].index = info.cfg.city_quality - 1;
        local technologyGroup = StringSplit(info.cfg.core_technology,"|");
        for i=1,3 do
            if technologyGroup[i] then
                local technologyType = tonumber(technologyGroup[i]);
                local technologyCfgGroup = buildScienceConfig.GetScienceConfig(info.map_id,technologyType);
                local technologyCfg = technologyCfgGroup and technologyCfgGroup[#technologyCfgGroup];
                item.technology["item"..i][UI.Image]:LoadSprite("icon/"..technologyCfg.icon);
                CS.UGUIPointerEventListener.Get(item.technology["item"..i].gameObject,true).onPointerDown = function(go, pos)
                    self.view.info.Text[UI.Text].text = SGK.Localize:getInstance():getValue("guanqiakejiyulan0"..technologyType);
                    local pos1 = self.view.info.Image.transform.position;
                    local pos2 = item.technology["item"..i].transform.position;
                    local pos3 = self.view.info.transform.position;
                    self.view.info.Image.transform.position = Vector3(pos2.x, pos1.y, pos1.z);
                    self.view.info.transform.position = Vector3(pos3.x, pos2.y, pos3.z);
                    self.view.info.transform.localPosition = self.view.info.transform.localPosition + Vector3(0, 30, 0);
                    self.view.info:SetActive(true);
                end
    
                CS.UGUIPointerEventListener.Get(item.technology["item"..i].gameObject,true).onPointerUp = function(go, pos)
                    self.view.info:SetActive(false);
                end
                item.technology["item"..i]:SetActive(true);
            else
                item.technology["item"..i]:SetActive(false);
            end
        end
        if info.science.title ~= 0 then
            coroutine.resume(coroutine.create(function ()
                local unionInfo = module.unionModule.Manage:GetUnion(info.science.title)
                if unionInfo then
                    item.name[UI.Text].text = unionInfo.unionName or "";
                    item.num[UI.Text].text = "Lv "..unionInfo.unionLevel;
                end
            end))
        else
            item.name[UI.Text].text = SGK.Localize:getInstance():getValue("chengshitongzhi_"..info.cfg.type);
        end
        local flag = GuildSeaElectionModule.CheckApply(info.map_id);
        if flag == 0 then
            item.apply:SetActive(true);
            item.status:SetActive(false);
        else
            item.apply:SetActive(false);
            item.status:SetActive(true);
            item.status[CS.UGUISpriteSelector].index = flag - 1;
        end
        SetButtonStatus(Time.now() > info.apply_begin_time and Time.now() < info.apply_end_time, item.apply);
        CS.UGUIClickEventListener.Get(item.apply.gameObject).onClick = function ( object )
            local uninInfo = module.unionModule.Manage:GetSelfUnion();
            local memberInfo = module.unionModule.Manage:GetSelfInfo()
            if uninInfo and uninInfo.id then
                if memberInfo == nil or memberInfo.title ~= 1 then
                    showDlgError(nil, "你不是公会会长")
                    return;
                end
                local flag = GuildSeaElectionModule.CanApply();
                if flag == 0 then
                    if self:CheckHaveCity() then
                        showDlg(self.view, SGK.Localize:getInstance():getValue("guanqiazhengduo39"), function()
                            GuildSeaElectionModule.Apply(info.map_id)
                        end, function() end)
                    else
                        showDlg(self.view,"确定要报名参加争夺战吗？",function()
                            GuildSeaElectionModule.Apply(info.map_id)
                        end, function() end)
                    end
                elseif flag == 1 then
                    showDlgError(nil, "你的公会已经报名了今天的争夺战");
                elseif flag == 2 then
                    showDlgError(nil, "你的公会已经作为防守方参加了今天的争夺战");
                end
            else
                showDlgError(nil, "尚未加入公会")
            end
        end
        item:SetActive(true);
    end
end

function View:CheckAlreadyApply()
    local flag = 3;
    for i,v in ipairs(self.cityInfo) do
        local _flag = GuildSeaElectionModule.CheckApply(v.map_id);
        if _flag ~= 0 and flag > _flag then
            flag = _flag;
        end
    end
    return flag;
end

function View:CheckHaveCity()
	local uninInfo = module.unionModule.Manage:GetSelfUnion();
	if uninInfo and uninInfo.id then
		local cityCfg = activityConfig.GetCityConfig().map_id;
		for k,v in pairs(cityCfg) do
			local cityInfo = module.BuildScienceModule.QueryScience(v.map_id);
			local owner = cityInfo and cityInfo.title or 0;
			if owner == uninInfo.id then
			   return true; 
			end		
		end
	end
	return false;
end

function View:UpdateData()
    coroutine.resume(coroutine.create( function ()
        local allInfo = GuildSeaElectionModule.GetAll();
        local cityCfg = activityConfig.GetCityConfig().map_id;
        self.cityInfo = {};
        for k,v in pairs(allInfo) do
            local mapInfo = v;
            mapInfo.cfg = cityCfg[k];
            mapInfo.science = module.BuildScienceModule.QueryScience(k);
            table.insert(self.cityInfo, mapInfo);
        end
        table.sort(self.cityInfo, function (a, b)
            if a.cfg.city_quality ~= b.cfg.city_quality then
                return a.cfg.city_quality > b.cfg.city_quality;
            end
            return a.cfg.map_id < b.cfg.map_id;
        end)
        self.view.ScrollView[CS.UIMultiScroller].DataCount = #self.cityInfo;
    end))
    print("城市信息", sprinttb(self.cityInfo))
end

function View:Update()
    if Time.now() - self.updateTime >= 1 then
        self.updateTime = Time.now();
        if self.cityInfo[1] then
            if Time.now() <= self.cityInfo[1].apply_begin_time then
                self.view.title.time[UI.Text]:TextFormat("距离报名开始：{0}", GetTimeFormat(self.cityInfo[1].apply_begin_time - Time.now(), 2));
            elseif Time.now() < self.cityInfo[1].apply_end_time then
                self.view.title.time[UI.Text]:TextFormat("距离报名结束：{0}", GetTimeFormat(self.cityInfo[1].apply_end_time - Time.now(), 2));
            else
                self.view.title.time[UI.Text]:TextFormat("报名已结束");
            end
        end
    end
end

function View:listEvent()
	return {
		"GUILD_APPLY_FOR_SEA_ELECTION",
	}
end

function View:onEvent(event, ...)
    -- print("onEvent", event, ...);
    local data = ...;
	if event == "GUILD_APPLY_FOR_SEA_ELECTION"  then
        local uninInfo = module.unionModule.Manage:GetSelfUnion();
		if uninInfo and uninInfo.id and uninInfo.id == data then
            self.view.ScrollView[CS.UIMultiScroller]:ItemRef();
		end
	end
end

return View;