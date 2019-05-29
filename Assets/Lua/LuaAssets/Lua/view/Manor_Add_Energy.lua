local ManorManufactureModule = require "module.ManorManufactureModule"
local ItemHelper = require "utils.ItemHelper"
local ItemModule = require "module.ItemModule"
local Time = require "module.Time"
local HeroModule = require "module.HeroModule"
local ManorModule = require "module.ManorModule"

local View = {};
function View:Start(data)
    self.root = CS.SGK.UIReference.Setup(self.gameObject);
    self.view = self.root.view;
    self.heroView = self.view.right.ScrollView[CS.UIMultiScroller];
    self.lastid = data and data.lastid or 0;
    self.select_id = self.lastid;
    self.update_time = 0;

	self:InitData();
	self:InitView();
end

function View:InitData()
	self.manager = HeroModule.GetManager();
	self.heros = self.manager:Get();
    self.manorProductInfo = ManorManufactureModule.Get();
    self.work_energy =  ManorModule.GetManorWorkEnergy();
    self.onlyOne = false;
    self.select_food = 0;
    self.eating = false;
    self.querying = {};
    self.foodUI = {};
    self.heroInfo = self:SortHeroList(self.heros);
    if self.select_id == 0 then
		self.select_id = self.heroInfo[1].id;
	end
end

function View:SortHeroList(heros)
	local heroInfo = {};
	for _,v in pairs(heros) do
		local info = {};
		info = self.manorProductInfo:GetWorkerInfo(v.uuid,1);
		if info then
			info.id = v.uuid;
            info.state = self.manorProductInfo:GetWorkerInfo(v.uuid,2) or {state = 0, working = 0};
            info.cfg = v;
			table.insert(heroInfo, info);
		end
	end

	table.sort(heroInfo, function ( a,b )        
        if (a.powerlimit - a.power) ~= (b.powerlimit - b.power) then
            return (a.powerlimit - a.power) > (b.powerlimit - b.power)
        end
		return a.id < b.id
	end)
	--排序
	return heroInfo;
end

function View:updateHeroInfo(uuid)
	for i=1,#self.heroInfo do
		if self.heroInfo[i].id == uuid then
			local info = {};
            info = self.manorProductInfo:GetWorkerInfo(uuid,1);
			info.id = uuid;
            info.state = self.manorProductInfo:GetWorkerInfo(uuid,2) or {state = 0, working = 0};
            info.cfg = self.manager:GetByUuid(uuid);
			self.heroInfo[i] = info;
			if self.select_id == uuid  then
				self:SelectItem(self.heroInfo[i]);
            end
            -- print("测试",info.cfg.name,"变化", sprinttb(self.heroInfo[i]));
		end
	end
end

function View:InitView()
    for i=1,5 do
        local obj = UnityEngine.Object.Instantiate(self.view.left.info2.item_food.gameObject);
        obj.transform:SetParent(self.view.left.info2.gameObject.transform,false);
        obj.name = tostring(self.work_energy[i].id);
        local item = CS.SGK.UIReference.Setup(obj)
        local cfg = ItemHelper.Get(ItemHelper.TYPE.ITEM,self.work_energy[i].id);
        item.info.name[CS.UnityEngine.UI.Text].text = self.work_energy[i].name;
        item.info.add[CS.UnityEngine.UI.Text].text = "+"..self.work_energy[i].add_energy;
        -- item.newItemIcon[SGK.newItemIcon]:SetInfo(cfg);
        utils.IconFrameHelper.Create(item.IconFrame,{type = ItemHelper.TYPE.ITEM, id = self.work_energy[i].id});
        item.icon[UnityEngine.UI.Image]:LoadSprite("icon/"..cfg.icon.."_small");
        CS.UGUIClickEventListener.Get(item.IconFrame.gameObject).onClick = function ( object )
            local cfg = ItemHelper.Get(ItemHelper.TYPE.ITEM,self.work_energy[i].id);
            local heroinfo = self.manorProductInfo:GetWorkerInfo(self.select_id);
            if cfg.count <= 0 then
                showDlgError(nil, "食物数量不足");
            elseif heroinfo.powerlimit - heroinfo.power == 0 then
                showDlgError(nil, "活力已满");
            elseif not self.eating then
                self.select_food = self.work_energy[i];
                self.eating = true;
                self.manorProductInfo:AddWorkerEnergy(self.select_id ,self.select_food);
            end
        end
        item:SetActive(true);
        self.foodUI[self.work_energy[i].id] = item;
    end

	self.heroView.DataCount = #self.heroInfo;
    self.heroView.RefreshIconCallback = function ( obj, idx )
        local heroinfo = self.heroInfo[idx + 1];
        local hero = self.manager:GetByUuid(heroinfo.id);
        local item = CS.SGK.UIReference.Setup(obj);

        -- local hero_cfg = ItemHelper.Get(ItemHelper.TYPE.HERO,hero.id);
        -- item.newCharacterIcon[SGK.newCharacterIcon]:SetInfo(hero_cfg);
        utils.IconFrameHelper.Create(item.IconFrame,{type = 42, uuid = heroinfo.id, func = function (item)
            item.Star:SetActive(false);
            item.Frame:SetActive(false);
		end})
        --item.select.gameObject:SetActive(self.select_id == heroinfo.id);
        item[CS.UnityEngine.UI.Toggle].isOn = (self.select_id == heroinfo.id);
    
        local state = 0	
        if heroinfo.state.state and heroinfo.state.state ~= 0 then
            state = heroinfo.state.state;
        else
            if heroinfo.event and heroinfo.event == 1 then
                state = 4
            end
        end
        item.state[CS.UnityEngine.UI.Image]:LoadSprite("icon/bg_zy_zhiye"..state);
        item.Slider[CS.UnityEngine.UI.Slider].value = heroinfo.power/heroinfo.powerlimit;
        item.Slider.FillArea.Fill[UI.Image].color = self:GetColor(heroinfo.power/heroinfo.powerlimit);

        CS.UGUIClickEventListener.Get(item.gameObject,true).onClick = function ( object )
            print("选择"..idx + 1)
            self:SelectItem(self.heroInfo[idx + 1]);
        end
        obj:SetActive(true);
    end
    CS.UGUIClickEventListener.Get(self.view.left.change.gameObject).onClick = function ( object )
        if self.select_id == 0 then
			return;
        end
        print("休息")
        local heroInfo = self.manorProductInfo:GetWorkerInfo(self.select_id,1);
        heroInfo.state = self.manorProductInfo:GetWorkerInfo(self.select_id,2) or {state = 0, working = 0};
        if heroInfo.state.line then
            local productline = self.manorProductInfo:GetLine(heroInfo.state.line);
            local pos = 0;
            local count = 0;
            for i,v in ipairs(productline.worker) do
                if v ~= 0 then
                    count = count + 1;
                end
                if v == self.select_id then
                    pos = i;
                end
            end
            if count == 1 and heroInfo.state.working == 1 then
                showDlgError(nil, "该英雄正在工作，至少保留一个人员在岗位上");
                return;
            end
            if heroInfo.state.state == 0 then
                showDlgError(nil, "该英雄正在休息中");
                return;
            end
            self.onlyOne = true;
            self.manorProductInfo:AddWorker(heroInfo.state.line, 0, pos, self.select_id);
        end
    end
    CS.UGUIClickEventListener.Get(self.view.title.close.gameObject).onClick = function (obj)
        DialogStack.Pop();
    end
    
    CS.UGUIClickEventListener.Get(self.root.BG.gameObject, true).onClick = function (obj)
        DialogStack.Pop();
    end

    CS.UGUIPointerEventListener.Get(self.view.left.info1.state.gameObject).onPointerDown = function(go, pos)
        self.view.left.tip:SetActive(true);
    end
    CS.UGUIPointerEventListener.Get(self.view.left.info1.state.gameObject).onPointerUp = function(go, pos)
		self.view.left.tip:SetActive(false);
    end

    self:updateHeroInfo(self.select_id);
	self:refreshHeroView();
end

function View:refreshHeroView(uuid)
	if uuid == nil then
		self.heroView:ItemRef();
	else
		for i,v in ipairs(self.heroInfo) do
			if v.id == uuid then
				local obj =  self.heroView:GetItem(i - 1);
				if obj then
					local item = CS.SGK.UIReference.Setup(obj);
					item.Slider[CS.UnityEngine.UI.Slider].value = v.power/v.powerlimit;
                    item.Slider.FillArea.Fill[UI.Image].color = self:GetColor(v.power/v.powerlimit);
                    local state = 0;
                    if v.state.state and v.state.state ~= 0 then
                        state = v.state.state;
                    else
                        if v.event and v.event == 1 then
                            state = 4;
                        end
                    end
                    item.state[CS.UnityEngine.UI.Image]:LoadSprite("icon/bg_zy_zhiye"..state);
				end
				break;
			end
		end
		
	end
end

function View:GetColor(value)
    local str = ""
    if value > 0.6 then
        str = "#00E9B4FF"
    elseif value > 0.3 then
        str = "#FFD200FF"
    else
        str = "#E80027FF"
    end
    local _, color= UnityEngine.ColorUtility.TryParseHtmlString(str);
    return color;
end


function View:SelectItem(info)
	local hero = self.manager:GetByUuid(info.id);
	self.select_id = info.id;
    print("heroInfo",self.select_id, sprinttb(info));
	self.view.left.info1.name[CS.UnityEngine.UI.Text].text = hero.name;

	local state = 0	
	if info.state and info.state.state and info.state.state ~= 0 then
		state = info.state.state;
	else
		if info.event and info.event == 1 then
			state = 4;
		end
	end

	self.view.left.info1.state[CS.UnityEngine.UI.Image]:LoadSprite("icon/bg_zy_zhiye"..state);
	self.view.left.info1.energy[CS.UnityEngine.UI.Text].text = info.power.."/"..info.powerlimit;
    self.view.left.info1.Slider[CS.UnityEngine.UI.Slider].value = info.power/info.powerlimit;
    self.view.left.info1.Slider.FillArea.Fill[UI.Image].color = self:GetColor(info.power/info.powerlimit);
    -- if info.delta < 0 then
    --     self.view.left.Text[CS.UnityEngine.UI.Text]:TextFormat("工作状态：每分钟消耗活力"); 
    --     self.view.left.num[CS.UnityEngine.UI.Text].text = tostring(math.floor(-info.delta));
    -- else
    --     self.view.left.Text[CS.UnityEngine.UI.Text]:TextFormat("自然恢复：每分钟恢复活力"); 
    --     self.view.left.num[CS.UnityEngine.UI.Text].text = tostring(info.delta);
    -- end
end

function View:refreshFood(id)
    local item = self.foodUI[id];
    local cfg = ItemHelper.Get(ItemHelper.TYPE.ITEM,id);
    -- item.newItemIcon[SGK.newItemIcon]:SetInfo(cfg);
    utils.IconFrameHelper.Create(item.IconFrame,{type = ItemHelper.TYPE.ITEM, id = id});
    item.icon:SetActive(true);
    item.icon.gameObject.transform:DOLocalMove(Vector3(0,70,0),0.8);
    item.icon[UnityEngine.UI.Image]:DOFade(0,0.5):SetDelay(0.3):OnComplete(function ()
        item.icon:SetActive(false);
        item.icon.gameObject.transform.localPosition = Vector3(0,28,0);
        item.icon[UnityEngine.UI.Image].color = UnityEngine.Color.white;
    end)
    item:SetActive(cfg.count > 0);
end

function View:GetTime(time)
	local time_str = "";
	local min,sec = 0;
	if time < 60 then
		sec = time;
	else
		min = math.floor(time/60);
		sec = math.floor(time%60);
	end
	time_str = string.format("%02d"..":".."%02d",min,sec);
	return time_str;
end

function View:Update()
    if self.select_id ~= 0 and Time.now() - self.update_time >= 1 then
        self.update_time = Time.now();
        for i,v in ipairs(self.heroInfo) do
            local time = v.nextchange - Time.now() + 1;
            if time <= 0 and not self.querying[v.id] then
                self.querying[v.id] = true;
                --print("测试查询",v.cfg.name, v.nextchange)
                self.manorProductInfo:QueryWorkerInfo(v.id);
                if time == 0 and v.id == self.select_id then
                    self.view.left.info1.time[UnityEngine.UI.Text].text = self:GetTime(time);
                end      
            elseif time > 0 and v.id == self.select_id then
                self.view.left.info1.time[UnityEngine.UI.Text].text = self:GetTime(time);
            end
        end
    end
end

function View:deActive()
	utils.SGKTools.PlayDestroyAnim(self.gameObject)
	return true;
end

function View:listEvent()
	return {
        "MANOR_MANUFACTURE_PRODUCT_LINE_CHANGE",
        "MANOR_MANUFACTURE_WORKER_INFO_CHANGE",
        "MANOR_MANUFACTURE_EAT_FOOD",
	}
end

function View:onEvent(event, ...)
    print("onEvent", event, ...);
    local data = ...;
	if event == "MANOR_MANUFACTURE_PRODUCT_LINE_CHANGE"  then
        self.productline = self.manorProductInfo:GetLine(self.line);
    elseif event == "MANOR_MANUFACTURE_WORKER_INFO_CHANGE" then
        self.querying[data.uuid] = false;
        self:updateHeroInfo(data.uuid);
        self:refreshHeroView(data.uuid);
    elseif event == "MANOR_MANUFACTURE_EAT_FOOD" then
        self.eating = false;
        self:refreshFood(data.food_id);
	end
end

return View;