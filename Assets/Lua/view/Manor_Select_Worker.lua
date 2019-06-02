local ManorManufactureModule = require "module.ManorManufactureModule"
local HeroModule = require "module.HeroModule"
local ManorModule = require "module.ManorModule"
local ItemHelper = require "utils.ItemHelper"
local ParameterShowInfo = require "config.ParameterShowInfo"
local CommonConfig = require "config.commonConfig"
local Time = require "module.Time"
local TalentModule = require "module.TalentModule"

local View = {};

local element = {};
element[1] = "<color=#14D3C1FF>[风属性]</color> ";
element[2] = "<color=#5FACD3FF>[水属性]</color> ";
element[4] = "<color=#DC3331FF>[火属性]</color> ";
element[8] = "<color=#E1B98CFF>[土属性]</color> ";
element[16] = "<color=#F0ED43FF>[光属性]</color> ";
element[32] = "<color=#DB6DFFFF>[暗属性]</color> ";
element[64] = "[无属性] ";

local work_place = {"研究院","工坊","矿山","商铺"};

function View:Start(data)
	self.root = CS.SGK.UIReference.Setup(self.gameObject);
	self.view = self.root.view;
    self.dialog = self.root.dialog;
    self.heroView = self.view.right.ScrollView[CS.UIMultiScroller];
    self.propView = self.view.left.info3.ScrollView.Viewport.Content;
    self.line = data and data.line or self.savedValues.select_line or 1;--属于生产线
    self.lastid = data and data.lastid or self.savedValues.select_lastid or 0;--原来位置上的角色id
    self.pos = data and data.pos or self.savedValues.select_pos or 0;--工作职位
    self.select_id = self.lastid;
    self.saveValue = false;
    
	self.update_time = 0;

	self:InitData();
	self:InitView();
end

function View:OnDestroy()
	if self.saveValue then
		self.savedValues.select_line = self.line;
		self.savedValues.select_lastid = self.select_id;
		self.savedValues.select_pos = self.pos;
	end
end

function View:InitData()
	self.manager = HeroModule.GetManager();
	self.heros = self.manager:Get();
	self.manorProductInfo = ManorManufactureModule.Get();
	self.manorInfo = ManorModule.LoadManorInfo();
	self.manorProductInfo:GetProductLineFromServer();
	self.manor_property = ManorModule.GetManorProperty();
	self.work_type_config = ManorModule.GetManorWorkType();
	self.productline = self.manorProductInfo:GetLine(self.line);
	self.line_cfg = ManorModule.GetManorLineConfig();
    self.onlyOne = false;
    self.mainpropUI = {};
	self.otherpropUI = {};
	self.querying = {};
	self.cur_fight_cfg = nil;
	self.prop_type = self.line_cfg[self.line].prop_effect[self.pos].type;
    self.heroInfo = self:SortHeroList(self.heros);
    print("self.heroInfo", sprinttb(self.heroInfo))	
	
    local grade_cfg = ManorModule.GetManorGradeConfig();
	self.grade_rank = {};
	for i,v in ipairs(grade_cfg) do
		local data = {};
		data.score = v.down;
		data.rank = v.grade;
		self.grade_rank[i] = data;
	end

	self.fight_add_grade = {};
	for _,k in ipairs(self.line_cfg[self.line].prop_effect) do
		local fight_add = ManorModule.GetManorFightAdd(1,k.type);
		local grade = 0;
		for i,v in pairs(fight_add) do
			grade = grade + (v.add_property * v.win_times);
		end
		self.fight_add_grade[k.type] = grade;
    end
    if self.select_id == 0 then
		self.select_id = self.heroInfo[1] and self.heroInfo[1].id or 0;
	end
end

function View:SortHeroList(heros)
	local _npc_table = ManorModule.GetManorNpcTable();
	-- print("测试", _npc_table, sprinttb(_npc_table))
	local heroInfo = {};
	for _,v in pairs(heros) do
		local info = {};
		info = self.manorProductInfo:GetWorkerInfo(v.uuid,1);
		local npc_table = ManorModule.GetManorNpcTable(v.id);
		if info and npc_table then
			info.id = v.uuid;
			info.state = self.manorProductInfo:GetWorkerInfo(v.uuid,2) or {state = 0, working = 0};
			table.insert(heroInfo, info);
		end
	end

	table.sort(heroInfo, function ( a,b )
		if a.state.state ~= b.state.state then
            if a.state.state == 0 then
                return true;
            end
            if b.state.state == 0 then
                return false;
            end
        end
        if a.prop[self.prop_type] ~= b.prop[self.prop_type] then
            return a.prop[self.prop_type] > b.prop[self.prop_type]
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
			self.heroInfo[i] = info;
			if self.select_id == uuid  then
				self:SelectItem(info);
			end
		end
	end
end

function View:InitView()
    self.item_workerprop = self.view.left.info3.item_prop.gameObject;
    for i,v in pairs(self.line_cfg) do
        if i == self.line then
            for j,k in ipairs(v.prop_effect) do
                local obj = UnityEngine.Object.Instantiate(self.item_workerprop);
                obj.transform:SetParent(self.view.left.info3.needProp.gameObject.transform,false);
                obj.name = tostring(k.type);
                self.mainpropUI[k.type] = obj;
                -- CS.UGUIPointerEventListener.Get(obj).onPointerDown = function(go, pos)
                --     self:ShowPropTip();
                -- end
                -- CS.UGUIPointerEventListener.Get(obj).onPointerUp = function(go, pos)
                --     self.view.main.workerinfo.info3.tip.gameObject:SetActive(false);
                -- end
            end
        else
            for j,k in ipairs(v.prop_effect) do
                local obj = UnityEngine.Object.Instantiate(self.item_workerprop);
                obj.transform:SetParent(self.propView.gameObject.transform,false);
                obj.name = tostring(k.type);
                obj.transform:Find("Slider").gameObject:SetActive(false);
                self.otherpropUI[k.type] = obj;
            end
        end
    end

    self.heroView.DataCount = #self.heroInfo;

    self.heroView.RefreshIconCallback = function ( obj, idx )
		local heroinfo = self.heroInfo[idx + 1];
		local hero = self.manager:GetByUuid(heroinfo.id);
		local item = CS.SGK.UIReference.Setup(obj);

		-- local hero_cfg = ItemHelper.Get(ItemHelper.TYPE.HERO,hero.id);
		-- item.newCharacterIcon[SGK.newCharacterIcon]:SetInfo(hero_cfg);

		utils.IconFrameHelper.Create(item.IconFrame,{type = 42, uuid = heroinfo.id, customCfg = {star = 0}})
		--item.select.gameObject:SetActive(self.select_id == heroinfo.id);
		item[CS.UnityEngine.UI.Toggle].isOn = (self.select_id == heroinfo.id);
	
		local state = 0	
		if heroinfo.state.state then
			state = heroinfo.state.state;
		end
		item.state[CS.UnityEngine.UI.Image]:LoadSprite("icon/bg_zy_zhiye"..state);
		CS.UGUIClickEventListener.Get(item.gameObject,true).onClick = function ( object )
			print("选择"..idx + 1)
			self:SelectItem(heroinfo);
			-- item.Checkmark.gameObject:SetActive(true);
		end
		obj:SetActive(true);
    end
	
    CS.UGUIClickEventListener.Get(self.view.left.change.gameObject).onClick = function ( object )
		if self.select_id == 0 then
			return;
		end
		if self.select_id ~= self.productline.worker[self.pos] then --更换
			print("更换")
			local heroInfo = self.manorProductInfo:GetWorkerInfo(self.select_id,1);
			heroInfo.state = self.manorProductInfo:GetWorkerInfo(self.select_id,2) or {state = 0, working = 0};
			-- if (heroInfo.event and heroInfo.event == 1) or (heroInfo.state and heroInfo.state.task == 1) then
			-- 	showDlgError(self.view, "英雄外出中，不能工作");
			-- 	return;
			-- end
			if heroInfo.state.working == 1 and self.productline.worker[self.pos] == 0 then
				local productline = self.manorProductInfo:GetLine(heroInfo.state.line);
				local count = 0;
				for i,v in ipairs(productline.worker) do
					if v ~= 0 and i <= 5 then
						count = count + 1;
					end
				end
				if count == 1 and heroInfo.state.line ~= self.line then
					showDlgError(self.view, "该英雄正在工作，至少保留一个人员在岗位上");
					return;
				end
				
			end
			print("self.pos", self.pos)
			if heroInfo.state.state ~= 0 and self.productline.worker[self.pos] ~= 0 and heroInfo.state.line ~= self.line then
				local hero1 = self.manager:GetByUuid(heroInfo.id);
                local hero2 = self.manager:GetByUuid(self.productline.worker[self.pos]);
                showDlg(nil,"是否将"..hero1.name.."与"..hero2.name.."工作位置互换？\n提示：更换人员后可能会影响正在进行的工作",function ()                   
					self.manorProductInfo:AddWorker(self.line, self.select_id, self.pos);
                end,function ()end);

				-- self.dialog.tip.Text[CS.UnityEngine.UI.Text]:TextFormat("是否将{0}与{1}工作位置互换？\n提示：更换人员后可能会影响正在进行的工作", hero1.name, hero2.name);
				-- CS.UGUIClickEventListener.Get(self.dialog.tip.confirm.gameObject).onClick = function ( object )
				-- 	self.onlyOne = true;
				-- 	self.manorProductInfo:AddWorker(self.line, self.select_id, self.pos);
				-- 	self.dialog.tip:SetActive(false);
				-- end
				-- CS.UGUIClickEventListener.Get(self.dialog.tip.cancel.gameObject).onClick = function ( object )
				-- 	self.dialog.tip:SetActive(false);
				-- end
				-- self.dialog.tip:SetActive(true);
			else
				self.onlyOne = true;
				self.manorProductInfo:AddWorker(self.line, self.select_id, self.pos, self.select_id);
			end
		else --休息
			print("休息")
			local heroInfo = self.manorProductInfo:GetWorkerInfo(self.select_id,1);
			heroInfo.state = self.manorProductInfo:GetWorkerInfo(self.select_id,2) or {state = 0, working = 0};
			if heroInfo.state.line then
				local productline = self.manorProductInfo:GetLine(heroInfo.state.line);
				local pos = 0;
				local count = 0;
				for i,v in ipairs(productline.worker) do
					if v ~= 0 and i <= 5 then
						count = count + 1;
					end
					if v == self.select_id then
						pos = i;
					end
				end
				if count == 1 and heroInfo.state.working == 1 then
					showDlgError(self.view, "该英雄正在工作，至少保留一个人员在岗位上");
					return;
				end
				if heroInfo.state.state == 0 then
					showDlgError(self.view, "该英雄正在休息中");
					return;
				end
				self.onlyOne = true;
				self.manorProductInfo:AddWorker(heroInfo.state.line, 0, pos, self.select_id);
			end
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

	CS.UGUIClickEventListener.Get(self.view.left.info3.needProp.fight.gameObject).onClick = function ( object )
		if self.cur_fight_cfg then
			local heroInfo = self.manorProductInfo:GetWorkerInfo(self.select_id,1);
			local hero = self.manager:GetByUuid(self.select_id);
			if hero.level < self.cur_fight_cfg.open_level then
				showDlgError(nil, "等级不足");
				return;
			elseif heroInfo.prop[self.prop_type] < self.cur_fight_cfg.condition then
				showDlgError(nil, "属性未达到要求");
				return;
			end
			self:ShowBattleFrame();
		end
    end
	
    CS.UGUIClickEventListener.Get(self.dialog.fight.confirm.gameObject).onClick = function ( object )
		local gid = self.manager:GetByUuid(self.select_id).id;
		local fightInfo = ManorModule.GetManorFightAdd(1, self.prop_type, self.curRank);
		for i=1,4 do
			if fightInfo["consume_item_id"..i] ~= 0 then
				local cfg = ItemHelper.Get(fightInfo["consume_item_type"..i], fightInfo["consume_item_id"..i]);
				if cfg.count < fightInfo["consume_item_value"..i] then
					showDlgError("物品不足");
					return;
				end
			end
		end
		self.dialog.fight.gameObject:SetActive(false);
		if fightInfo.role_num > 1 then
			self.saveValue = true;
			print("选人")
			local obj = DialogStack.Push('FormationDialog', {type = 3, role_num = fightInfo.role_num, master = gid, prop_type = self.prop_type, online = {gid, 0,0,0,0}, condition = self.curRank});
		else
			self.saveValue = true;
			self.manorProductInfo:StartFight(self.prop_type,self.select_id, {self.select_id}, self.curRank);
		end
		-- showDlgError(nil, "请提升角色属性，可通过：升级、进阶、升星")

    end
    
    CS.UGUIClickEventListener.Get(self.dialog.fight.cancel.gameObject).onClick = function ( object )
		self.dialog.fight.gameObject:SetActive(false);
    end
	

	self:updateHeroInfo(self.select_id);
	self:refreshHeroView();
	self:CheckButtonState();
end

function View:CheckButtonState()
    if self.productline and self.select_id == self.productline.worker[self.pos] then
        self.view.left.change.Text[CS.UnityEngine.UI.Text]:TextFormat("休息");
    elseif self.productline and self.productline.worker[self.pos] == 0 then
		self.view.left.change.Text[CS.UnityEngine.UI.Text]:TextFormat("派遣");
	else
        self.view.left.change.Text[CS.UnityEngine.UI.Text]:TextFormat("更换");
    end
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
					local state = 0	;
					if v.state.state then
						state = v.state.state;
					end
					item.state[CS.UnityEngine.UI.Image]:LoadSprite("icon/bg_zy_zhiye"..state);
				end
				break;
			end
		end
		
	end
	self:CheckButtonState();
end

function View:GetCurRank()
	local heroInfo = self.manorProductInfo:GetWorkerInfo(self.select_id,1);
    local curRank = 0;
    local fight_id = 0;

	--根据战斗次数匹配战斗
    local fightadd = ManorModule.GetManorFightAdd(1, self.prop_type);
    local fight_cfg = {}
    for k,v in pairs(fightadd) do
        table.insert(fight_cfg,v);
    end
    table.sort(fight_cfg,function ( a,b )
        return a.condition < b.condition;
    end)

	local cur_fight_cfg = nil;
    for i,v in ipairs(fight_cfg) do
        local prop_fight_count = heroInfo.fight_count[self.prop_type] and heroInfo.fight_count[self.prop_type][v.condition] or 0;
        if prop_fight_count == 0 then
            cur_fight_cfg = v;
            break;
        end
	end
	return cur_fight_cfg;
end

function View:CheckFightState()
	local heroInfo = self.manorProductInfo:GetWorkerInfo(self.select_id,1);
	local hero = self.manager:GetByUuid(self.select_id);
	self.cur_fight_cfg = self:GetCurRank();
	local fightBtn = self.view.left.info3.needProp.fight;
	if self.cur_fight_cfg then
		fightBtn[CS.UnityEngine.UI.Image].material = nil;
		fightBtn[CS.UGUIClickEventListener].interactable = true;
		fightBtn[CS.UGUIClickEventListener].disableTween = false;
		if hero.level < self.cur_fight_cfg.open_level then
			fightBtn.Text[UnityEngine.UI.Text]:TextFormat("LV{0}可考级", self.cur_fight_cfg.open_level);
		elseif heroInfo.prop[self.prop_type] < self.cur_fight_cfg.condition then
			fightBtn.Text[UnityEngine.UI.Text]:TextFormat("{0}{1}分可考级", self.work_type_config[self.prop_type].work_type, self.cur_fight_cfg.condition);
		else
			fightBtn.Text[UnityEngine.UI.Text]:TextFormat("申请考级");
		end
	else
		fightBtn[CS.UGUIClickEventListener].interactable = false;
		fightBtn[CS.UGUIClickEventListener].disableTween = true;
		fightBtn[CS.UnityEngine.UI.Image].material = fightBtn[CS.UnityEngine.MeshRenderer].materials[0];
		fightBtn.Text[UnityEngine.UI.Text]:TextFormat("评定战斗已通关");
	end
end

function View:ShowBattleFrame() 
	local heroInfo = self.manorProductInfo:GetWorkerInfo(self.select_id,1);
	local curRank = 0;
	local fight_id = 0;
	if self.cur_fight_cfg then
		curRank = self.cur_fight_cfg.condition;
		fight_id = self.cur_fight_cfg.fight_id;
	end
    print("curRank", curRank,fight_id);

    if fight_id == 0 then
        showDlgError(nil, "评定战斗已通关");
        return;
    end

    self.fight_id = fight_id;
    self.curRank = curRank;
    local fightInfo = ManorModule.GetManorFightAdd(1, self.prop_type, curRank);
    local fight_config = ManorModule.GetManorFightConfig();
    
	self.dialog.fight.Text[CS.UnityEngine.UI.Text]:TextFormat(fightInfo.work_add_tips1);
	self.dialog.fight.Text1[CS.UnityEngine.UI.Text]:TextFormat(fightInfo.work_add_tips2);
    self.dialog.fight.prop.Text[CS.UnityEngine.UI.Text]:TextFormat("当前：{0}{1}",self.work_type_config[self.prop_type].work_type, heroInfo.prop[self.prop_type]);
    self.dialog.fight.prop.add[CS.UnityEngine.UI.Text]:TextFormat("通过：+{0}",fightInfo.add_property);
    -- self.dialog.fight.tip[CS.UnityEngine.UI.Text]:TextFormat("要求：{0}{1}分",self.work_type_config[self.prop_type].work_type, curRank);
    if heroInfo.prop[self.prop_type] >= curRank then
		-- self.dialog.fight.tip[CS.UnityEngine.UI.Text].color = UnityEngine.Color.white;
		SetButtonStatus(true, self.dialog.fight.confirm);
    else
		-- self.dialog.fight.tip[CS.UnityEngine.UI.Text].color = UnityEngine.Color.red;
		SetButtonStatus(false, self.dialog.fight.confirm);		
    end
	for i=1,4 do
		if fightInfo["consume_item_id"..i] ~= 0 then
			utils.IconFrameHelper.Create(self.dialog.fight.consume["item"..i],{type = fightInfo["consume_item_type"..i], id = fightInfo["consume_item_id"..i], count = fightInfo["consume_item_value"..i], showDetail = true})
			self.dialog.fight.consume["item"..i]:SetActive(true);
		else
			self.dialog.fight.consume["item"..i]:SetActive(false)
		end
	end
    self.dialog.fight.info.name[CS.UnityEngine.UI.Text].text = fightInfo.name;
    local str = "";
    local element_type = {};
    for i=1,3 do
        if fightInfo["npc_type"..i] ~= 0 then
            --str = str..element[fightInfo["npc_type"..i]]
            if element_type[fightInfo["npc_type"..i]] == nil then
                element_type[fightInfo["npc_type"..i]] = 0;
            end
        end
	end
	
    for k,v in pairs(element_type) do
        str = str..element[k];
    end
    self.dialog.fight.info.element[CS.UnityEngine.UI.Text].text = str;
    self.dialog.fight.info.num[CS.UnityEngine.UI.Text].text = tostring(fight_config[fightInfo.fight_id].capacity);
	-- self.dialog.fight.info.newCharacterIcon[SGK.newCharacterIcon].icon = tostring(fightInfo.display);
	self.dialog.fight.info.monster.icon[UnityEngine.UI.Image]:LoadSprite("icon/"..fightInfo.display);
	print("icon", fightInfo.display);
    self.dialog.fight.gameObject:SetActive(true);
end

function View:SelectItem(info)
	local hero = self.manager:GetByUuid(info.id);
	self.select_id = info.id;
	print("heroInfo",self.select_id, sprinttb(info));
	self:CheckButtonState();
	self:CheckFightState();
	self.view.left.info1.name[CS.UnityEngine.UI.Text].text = hero.name;

	local state = 0	
	if info.state and info.state.state then
		state = info.state.state;
	end

	self.view.left.info1.state[CS.UnityEngine.UI.Image]:LoadSprite("icon/bg_zy_zhiye"..state);
	self.view.left.info1.energy[CS.UnityEngine.UI.Text].text = info.power.."/"..info.powerlimit;
	
	-- local title_info = TalentModule.GetCurrentTitleDesc(hero);
	-- if #title_info ~= 0 then
	-- 	self.view.left.info2.name[CS.UnityEngine.UI.Text]:TextFormat(title_info[1]);
	-- 	self.view.left.info2.effect[CS.UnityEngine.UI.Text]:TextFormat(title_info[2]);
	-- else
	-- 	self.view.left.info2.name[CS.UnityEngine.UI.Text]:TextFormat("未转职");
	-- 	self.view.left.info2.effect[CS.UnityEngine.UI.Text]:TextFormat("暂无生产增益");
	-- end
	local prop_level_cfg = ManorModule.GetManorPropertyLevel(self.prop_type);
	local level = 1;
	for i,v in ipairs(prop_level_cfg) do
		if info.prop[self.prop_type] <= v.property_value then
			level = v.work_level;
			break;
		end
	end
	self.view.left.info2.name[CS.UnityEngine.UI.Text]:TextFormat("{0}{1}级({2}分)", self.work_type_config[self.prop_type].work_type, level, info.prop[self.prop_type]);

	for i,v in pairs(self.line_cfg) do
		if i == self.line then
			for j,k in ipairs(v.prop_effect) do
				local obj = self.mainpropUI[k.type];
				obj:SetActive(true);
				local item = CS.SGK.UIReference.Setup(obj);
				item.name[CS.UnityEngine.UI.Text].text = self.work_type_config[k.type].work_type;
				local prop_cfg = self.manor_property[hero.id][k.type];
				for i,v in ipairs(self.grade_rank) do
					if prop_cfg.factor >= v.score then
						item.rank[CS.UnityEngine.UI.Text].text = v.rank;
						break;
					end
				end
				-- print(prop_cfg.init1 , prop_cfg.lv_value1 , CommonConfig.Get(6).para1 , prop_cfg.rank_value1 , CommonConfig.Get(7).para1 , prop_cfg.star_value1 , CommonConfig.Get(8).para1 , self.fight_add_grade[k] , prop_cfg.factor)
				-- local grade_limit = prop_cfg.init1 + prop_cfg.lv_value1 * CommonConfig.Get(6).para1 + prop_cfg.rank_value1 * CommonConfig.Get(7).para1 + prop_cfg.star_value1 * CommonConfig.Get(8).para1 + self.fight_add_grade[k.type] * prop_cfg.factor;
				item.Slider[CS.UnityEngine.UI.Slider].value = info.prop[k.type] / 2160;
				if k.type == self.prop_type then
					local _, color= UnityEngine.ColorUtility.TryParseHtmlString('#FFD800FF');
					item.Slider.FillArea.Fill[UI.Image].color = color;
				else
					local _, color= UnityEngine.ColorUtility.TryParseHtmlString('#00E9B4FF');
					item.Slider.FillArea.Fill[UI.Image].color = color;
				end
				
				item.num[CS.UnityEngine.UI.Text].text = tostring(info.prop[k.type]);
			end
		else
			for j,k in ipairs(v.prop_effect) do
				local obj = self.otherpropUI[k.type];
				obj:SetActive(true);
				local item = CS.SGK.UIReference.Setup(obj);
				item.name[CS.UnityEngine.UI.Text].text = self.work_type_config[k.type].work_type;
				item.Slider.gameObject:SetActive(false);
				local prop_cfg = self.manor_property[hero.id][k.type];
				for i,v in ipairs(self.grade_rank) do
					if prop_cfg.factor >= v.score then
						item.rank[CS.UnityEngine.UI.Text].text = v.rank;
						break;
					end
				end
				item.num[CS.UnityEngine.UI.Text].text = tostring(info.prop[k.type]);
			end
		end
	end
end

function View:Update()
	if self.select_id ~= 0 and Time.now() - self.update_time >= 1 then
		self.update_time = Time.now();
		for i,v in ipairs(self.heroInfo) do
			local time = v.nextchange - Time.now();
			if time <= 0 and not self.querying[v.id] then
				self.querying[v.id] = true;
				self.manorProductInfo:QueryWorkerInfo(v.id);
			-- elseif time > 0 and v.id == self.select_id then
			-- 	self.view.main.workerinfo.info5.energy.time[UnityEngine.UI.Text].text = self:GetTime(time);
			end
		end
	end
end

function View:deActive()
	for i=#self.dialog,1,-1 do
		if self.dialog[i].active then
			self.dialog[i]:SetActive(false);
			return false;
		end
	end
	utils.SGKTools.PlayDestroyAnim(self.gameObject)
	return true;
end

function View:listEvent()
	return {
		"HERO_INFO_CHANGE",
		"MANOR_MANUFACTURE_WORKER_CHANGE",
		"MANOR_MANUFACTURE_PRODUCT_LINE_CHANGE",
		"MANOR_MANUFACTURE_WORKER_INFO_CHANGE",
		"MANOR_MANUFACTURE_WORKER_FIGHT_INFO"
	}
end

function View:onEvent(event, ...)
	print("onEvent", event, ...);
	local data = ...;
	if event == "HERO_INFO_CHANGE" then
		self:InitData();
		self:refreshHeroView();
	elseif event == "MANOR_MANUFACTURE_PRODUCT_LINE_CHANGE" then
		self.productline = self.manorProductInfo:GetLine(self.line);
	elseif event == "MANOR_MANUFACTURE_WORKER_CHANGE" then
		self.productline = self.manorProductInfo:GetLine(self.line);
		if self.onlyOne then			
			self.onlyOne = false;
			if data and data.select then
				self:updateHeroInfo(data.select);
				self:refreshHeroView(data.select);	
			end
		else
			--self.heroInfo = self:SortHeroList(self.heros);
			self:refreshHeroView();	
			self:updateHeroInfo(self.select_id);
		end
		if data then
			if data.id ~= 0 then
				showDlgError(nil,"派遣成功");
			end
			DialogStack.Pop();
		end
	elseif event == "MANOR_MANUFACTURE_WORKER_INFO_CHANGE" then
		self.querying[data.uuid] = false;
		self:updateHeroInfo(data.uuid);
		self:refreshHeroView(data.uuid);

	end
end

return View;
