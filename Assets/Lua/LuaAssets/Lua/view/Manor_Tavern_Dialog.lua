local ManorManufactureModule = require "module.ManorManufactureModule"
local ItemHelper = require "utils.ItemHelper"
local HeroModule = require "module.HeroModule"
local ManorModule = require "module.ManorModule"
local Time = require "module.Time"
local TipConfig = require "config.TipConfig"
local UserDefault = require "utils.UserDefault"

local task_type = {"日常","节日","周末","本周"}
local require_prop = {};
require_prop[1] = {{id = 802, ratio = 0.8}, {id = 803, ratio = 0.2}}
require_prop[2] = {{id = 803, ratio = 0.75}, {id = 801, ratio = 0.25}}
require_prop[3] = {{id = 801, ratio = 0.85}}
require_prop[4] = {{id = 804, ratio = 0.95}}


local MAX_COUNT = 5;
local MOVEPOINT_COUNT = 9

local View = {};
function View:Start(data)
    self.view = CS.SGK.UIReference.Setup(self.gameObject);
    self.dialog = self.view.dialog;
	self:InitData();
	self:InitView();
    if data and data.callback then
		data.callback();
    end
    self:GetTaskTeamInfo();

end

function View:InitData()
	self.manorProductInfo = ManorManufactureModule.Get();
	self.manorProductInfo:CheckWorkerProperty();
    self.manorProductInfo:GetProductLineFromServer();
    self.manorProductInfo:QueryTask();
    self.manager = HeroModule.GetManager();
    self.manor_property = ManorModule.GetManorProperty();
    self.heros = self.manager:Get();
    self.taskView = self.view.bottom.ScrollView.Viewport.Content.gameObject;
    self.heroView = self.dialog.task_dispatch.bottom.ScrollView[CS.UIMultiScroller];
    
    self.work_type_config = ManorModule.GetManorWorkType();
    self.task = {};
    self.staff = {};
    self.update_time = 0;
    self.begin_task = {}; 
    self.end_task = {};
    self.productLine = {};
    self.taskUI = {};
    self.character = {};
    self.dispatching = false;
    self.init = false;
    self.guide = true;
    self.taskTeam = {};
    self.haveTeam = 0;
    self.npc = {next_move_time = Time.now() + math.random(5,10), pos = 1};
    self.movePoint = {};
    for i=1,MOVEPOINT_COUNT do
        self.movePoint[i] = 1;
    end

    local grade_cfg = ManorModule.GetManorGradeConfig();
	self.grade_rank = {};
	for i,v in ipairs(grade_cfg) do
		local data = {};
		data.score = v.down;
		data.rank = v.grade;
		self.grade_rank[i] = data;
	end
end

function View:InitView()
    self.controller = self.view.top.content[SGK.DialogPlayerMoveController];
    self.controller:Add(0, self.view.top.content.npc.gameObject);

    CS.UGUIClickEventListener.Get(self.view.title.close.gameObject).onClick = function (obj)
        self:SaveData();
        DialogStack.Pop();
    end
    CS.UGUIClickEventListener.Get(self.view.BG.gameObject, true).onClick = function (obj)        
        self:SaveData();
        DialogStack.Pop();
    end
    -- CS.UGUIClickEventListener.Get(self.dialog.task_info.title.close.gameObject).onClick = function (obj)
	-- 	self.dialog.task_info.gameObject:SetActive(false);
    -- end
    -- CS.UGUIClickEventListener.Get(self.dialog.task_dispatch.title.close.gameObject).onClick = function (obj)
	-- 	self.dialog.task_dispatch.gameObject:SetActive(false);
    -- end
    CS.UGUIClickEventListener.Get(self.view.top.help.gameObject).onClick = function ( object )
        -- if ItemHelper.Get(41, 79000).count > 0 and module.playerModule.Get().honor == 9999 then
        --     utils.NotificationCenter.AddNotification(10, "测试", function ()
        --         print("--------------启动--------------")
        --         showDlgError(nil, "--------------启动--------------")
        --     end,function ()
        --         print("--------------收到--------------")
        --         showDlgError(nil, "--------------收到--------------")
        --     end)
        -- end
        -- self.dialog.illustration.gameObject:SetActive(true);
        utils.SGKTools.ShowDlgHelp(TipConfig.GetAssistDescConfig(55001).info, nil, self.dialog)
    end
    
    -- CS.UGUIClickEventListener.Get(self.dialog.illustration.content.close.gameObject).onClick = function ( object )
	-- 	self.dialog.illustration.gameObject:SetActive(false);
    -- end
    -- self.dialog.illustration.content.BG.Text[UnityEngine.UI.Text]:TextFormat(TipConfig.GetAssistDescConfig(55001).info);

    self.heroView.RefreshIconCallback = function ( obj, idx )
		local heroinfo = self.heroInfo[idx + 1];
		local hero = self.manager:GetByUuid(heroinfo.id);
        local item = CS.SGK.UIReference.Setup(obj);
        -- local hero_cfg = ItemHelper.Get(ItemHelper.TYPE.HERO,hero.id);
        -- item.newCharacterIcon[SGK.newCharacterIcon]:SetInfo(hero_cfg);
        utils.IconFrameHelper.Create(item.IconFrame,{type = 42, uuid = heroinfo.id, func = function (item)
			item.Star:SetActive(false);
		end})
        -- item.level[UnityEngine.UI.Text].text = "Lv"..hero.level;
        item.power[UnityEngine.UI.Text]:TextFormat("活力{0}", heroinfo.power);
        item.prop[UnityEngine.UI.Text]:TextFormat("{0}{1}",self.work_type_config[self.prop_type[1].id].work_type, heroinfo.prop[self.prop_type[1].id])
        
        -- local state = 0;
		-- if heroinfo.state.state and heroinfo.state.state ~= 0 then
		-- 	state = heroinfo.state.state;
		-- else
		-- 	if heroinfo.event and heroinfo.event == 1 then
		-- 		state = 4;
		-- 	end
        -- end
        if heroinfo.state and heroinfo.state.task and heroinfo.state.task == 1 then
            item.state:SetActive(true);
            item.state[CS.UnityEngine.UI.Image]:LoadSprite("icon/bg_zy_zhiye4");
            item.top:SetActive(false);
            item.drak:SetActive(true);
            item.Text:SetActive(true);
            item.Text[UnityEngine.UI.Text]:TextFormat("执行中");
        else
            item.state:SetActive(false);
            item.top:SetActive(self:GetGradeRank(hero.id, self.prop_type[1].id) == "S");
            item.drak:SetActive((heroinfo.index and heroinfo.index ~= 0) or heroinfo.pass ~= 4);
            item.Text:SetActive(false);
        end
        item.select:SetActive(heroinfo.index and heroinfo.index ~= 0);
        if heroinfo.condition[4] == 1 then
           item.power[UnityEngine.UI.Text].color = UnityEngine.Color.white;
        else
            item.power[UnityEngine.UI.Text].color = UnityEngine.Color.red;
        end
        if heroinfo.condition[3] == 1 then
            item.prop[UnityEngine.UI.Text].color = UnityEngine.Color.white;
        else
            item.prop[UnityEngine.UI.Text].color = UnityEngine.Color.red;
        end
        CS.UGUIClickEventListener.Get(item.click.gameObject, true).onClick = function (obj)
            if not item.select.gameObject.activeSelf then
                if heroinfo.pass ~= 4 then
                    showDlgError(nil, "未满足任务条件");
                    return;
                end
                -- if heroinfo.state.state and heroinfo.state.state ~= 0 then
                --     showDlgError(nil, "英雄已有其他工作");
                --     return;
                -- end
                if heroinfo.state and heroinfo.state.task and heroinfo.state.task == 1 then
                    showDlgError(nil, "正在执行任务中");
                    return;
                end

                local index = 0;
                for i=1,5 do
                    if self.staff[i] == nil then
                        index = i;
                        break;
                    end
                end
                if index == 0 then
                    showDlgError(nil, "没有空位了");
                    return;
                end
                self.staff[index] = heroinfo;
                self.heroInfo[idx + 1].index = index;
                item.drak:SetActive(true);
                item.select:SetActive(true);
                self:RefreshWorker();
            else
                for i,v in ipairs(self.staff) do
                    if v.id == heroinfo.id then
                        table.remove(self.staff, i);
                        break;
                    end
                end
               
                -- self.staff[heroinfo.index] = nil;
                self.heroInfo[idx + 1].index = 0;
                item.drak:SetActive(false);
                item.select:SetActive(false);
                self:RefreshWorker();
            end
        end
        item:SetActive(true);
    end
    
end

function View:ScreenHero(heros, taskInfo, sort)
	local heroInfo = {};
	for _,v in pairs(heros) do
		local info = {};
		info = self.manorProductInfo:GetWorkerInfo(v.uuid,1);
		if info then
			local pass = 0;
			local condition = {0 ,0, 0, 0};
			if taskInfo.require1 ~= 0 and v.level >= taskInfo.require1 or taskInfo.require1 == 0 then
				pass = pass + 1;
				condition[1] = 1;
			end
			if taskInfo.require2 ~= 0 and v.type & taskInfo.require2 ~= 0 or taskInfo.require2 == 0 then
				pass = pass + 1;
				condition[2] = 1;
			end
			if taskInfo.require3 ~= 0 and info.prop[self.prop_type[1].id] >= taskInfo.require3 or taskInfo.require3 == 0 then
				pass = pass + 1;
				condition[3] = 1;
			end
            if taskInfo.require_energy ~= 0 and info.power >= taskInfo.require_energy then
                pass = pass + 1;
				condition[4] = 1;
            end

			info.id = v.uuid;
			info.pass = pass;
			info.condition = condition;
			info.index = 0;
            info.state = self.manorProductInfo:GetWorkerInfo(v.uuid,2) or {state = 0, working = 0, task = 0};
            info.effect = self:updateEffectDes(info,taskInfo);
			table.insert(heroInfo, info);
		end
	end

	if sort then
		table.sort(heroInfo, function ( a,b )
            if (a.state.task or 0) ~= (b.state.task or 0) then
                if (a.state.task or 0) == 0 then
                    return true;
                end
                if (b.state.task or 0) then
                    return false;
                end
            end
			if a.pass ~= b.pass then
				return a.pass > b.pass;
			end
			if a.prop[self.prop_type[1].id] ~= b.prop[self.prop_type[1].id] then
				return a.prop[self.prop_type[1].id] > b.prop[self.prop_type[1].id]
			end

			return a.id < b.id
		end)
	end
	return heroInfo;
end

function View:GetGradeRank(id, type)
    local prop_cfg = self.manor_property[id][type];
    for i,v in ipairs(self.grade_rank) do
        if prop_cfg.factor >= v.score then
            -- print("成长等级", id, type, v.rank)
            return v.rank;
        end
    end
    return nil;
end

function View:CheckIsFree(uuid)
    local isFree = true;
    local worker_info = self.manorProductInfo:GetWorkerInfo(uuid, 1);
    local worker_state = self.manorProductInfo:GetWorkerInfo(uuid, 2);
    local worker_event = self.manorProductInfo:GetWorkerInfo(uuid, 3);
    if worker_info and worker_info.event == 1 then
        isFree = false;
    end
    if worker_state and worker_state.state == 4 then
        isFree = false;
    end
    if worker_event and (worker_event.where ~= -1 or worker_event.moving) then
        isFree = false;
    end
    return isFree;
end

function View:RefreshFrame()
    local newCharacter = {};
    local init_count = 0;
    if not self.init then
        local manor_character_move_data = UserDefault.Load("character_move_data", true);
        if manor_character_move_data.data == nil then
            manor_character_move_data.data = {};
        end
        for k,v in pairs(manor_character_move_data.data) do
            local isFree = self:CheckIsFree(k);
            if isFree and v.pos ~= 0 then
                local character = UnityEngine.Object.Instantiate(self.view.top.content.dialog_character.gameObject, self.view.top.content.gameObject.transform);
                character.name = tostring(k);
                local hero = self.manager:GetByUuid(k);
                
                local info = {};
                info.obj = CS.SGK.UIReference.Setup(character);
                info.uuid = k;
                info.nextMoveTime = Time.now() + math.random(5,15);
                info.pos = v.pos;
                info.obj[UnityEngine.CanvasGroup].alpha = 1;
                local pointInfo = self.controller:GetPointInfo("pos"..v.pos);
                info.obj.gameObject.transform.localPosition = pointInfo.position;
                self.movePoint[v.pos] = 0;
                info.obj:SetActive(true);
                self:LoadAnimaion(info.obj, hero.id, hero.mode);
                info.obj.spine[SGK.DialogSprite]:SetDirty();
                if pointInfo.direction == -1 then
                    info.obj.spine[SGK.DialogSprite].direction = v.direction or 0;
                else
                    info.obj.spine[SGK.DialogSprite].direction = pointInfo.direction;
                end
                newCharacter[k] = info;
                self.controller:Add(k, character);
                init_count = init_count + 1;
            end
        end
        self.init = true;
    else
        for k,v in pairs(self.character) do
            local isFree = self:CheckIsFree(k);
            if isFree then
                newCharacter[k] = v;
                init_count = init_count + 1;
            end
        end
    end

    local pick_num = MAX_COUNT - init_count;
    if pick_num > 0 then
        local freeWorker = {}
        local allworkers = self.manorProductInfo:GetAllWorker();
        for k,v in pairs(allworkers) do
            if newCharacter[k] == nil then
                local isFree = self:CheckIsFree(k);
                if isFree then
                    table.insert(freeWorker,k)
                end
            end
        end

        -- print("筛选",sprinttb(freeWorker));
        local count = 0;
        local pick = self:RandomPickup(freeWorker, pick_num)
        for i,v in ipairs(pick) do --添加新增角色
            local character = UnityEngine.Object.Instantiate(self.view.top.content.dialog_character.gameObject, self.view.top.content.gameObject.transform);
            character.name = tostring(v);
            local hero = self.manager:GetByUuid(v);
            local info = {};
            info.obj = CS.SGK.UIReference.Setup(character);
            info.uuid = v;
            info.nextMoveTime = Time.now() + count * 2 + (count - 1) * math.random(1,3) + 2;
            info.pos = 0;
            newCharacter[v] = info;

            character:SetActive(true);
            self:LoadAnimaion(info.obj, hero.id, hero.mode);
            self.controller:Add(v, character);
            count = count + 1;
        end

    end

    for k,v in pairs(self.character) do
        if newCharacter[k] == nil then  --删除已显示但未选中的角色
            v.obj[UnityEngine.CanvasGroup]:DOFade(0, 1):OnComplete(function ()
                if self.character[k] then
                    self.character[k] = nil;
                end
                self.controller:Remove(k);
            end)
        end
    end

    self.character = newCharacter;   
end

function View:LoadAnimaion(item, id, mode)
    -- item[SGK.DialogPlayer]:UpdateSkeleton(tostring(mode));
    local animation = item.spine[CS.Spine.Unity.SkeletonGraphic];
    animation.skeletonDataAsset = utils.SGKTools.loadExistSkeletonDataAsset("roles_small/", id, mode,"_SkeletonData");
    animation:Initialize(true);	
end

function View:ShowTaskFrame(task, type)
    -- print("任务信息",sprinttb(task));
    self.task = task;
    local view = nil;
    if type == 1 then
        view = self.dialog.task_info;
    elseif type == 2 then
        view = self.dialog.task_dispatch;
    end

    local taskInfo = ManorModule.GetManorTaskInfo(task.gid);
    local taskCfg = ManorModule.GetManorTaskConfig(task.gid);
    self.prop_type = ManorModule.GetManorTaskEquationConfig(taskInfo.task_type);
    view.top.tip.Text[CS.UnityEngine.UI.Text]:TextFormat(taskInfo.task_tittle2);
    view.top.des[CS.UnityEngine.UI.Text]:TextFormat(taskInfo.task_des);
    view.top.time[CS.UnityEngine.UI.Text].text = GetTimeFormat(taskCfg.hold_time, 2);

    local request = "";
    local num = 0;
    local data = {};
    for i=1,3 do
        if taskInfo["reward_id"..i] and taskInfo["reward_id"..i] ~= 0 then
            utils.IconFrameHelper.Create(view.top.reward["item"..i],{type = taskInfo["reward_type"..i], id = taskInfo["reward_id"..i], count = taskInfo["reward_num_min"..i], showDetail = true})
            view.top.reward["item"..i].gameObject:SetActive(true);
        else
            view.top.reward["item"..i].gameObject:SetActive(false);
        end
        if taskInfo["require"..i] ~= 0 then
            if i == 1 then
                request =  request.."等级"..taskInfo["require"..i].."   ";
            elseif i == 2 then
                request = request..self:getElement(taskInfo["require"..i]).."属性".."   ";
            elseif i == 3 then
                request = request..self.work_type_config[self.prop_type[1].id].work_type..taskInfo["require"..i].."   ";
            end 
        end
    end
    if taskInfo.require_energy > 0 then
        request = request.."活力"..taskInfo.require_energy;
    end
    view.top.require[CS.UnityEngine.UI.Text]:TextFormat(request);

    if type == 1 then
        for i=1,5 do
            if task.staff[i] then
                local hero = self.manager:GetByUuid(task.staff[i]);
                local animation =  view.bottom.workers["worker"..i].character[CS.Spine.Unity.SkeletonGraphic];
                animation.skeletonDataAsset = utils.SGKTools.loadExistSkeletonDataAsset("roles_small/", hero.id, hero.mode,"_SkeletonData");
                animation.startingAnimation = "idle1";
                animation.startingLoop = true;
                animation:Initialize(true);
                view.bottom.workers["worker"..i]:SetActive(true);
            else
                view.bottom.workers["worker"..i]:SetActive(false);
            end
        end
        view.bottom.info.chance[CS.UnityEngine.UI.Text]:TextFormat("成功率{0}%",math.floor(task.success > 100 and 100 or task.success))
        if task.state == 2 and task.end_time <= Time.now() then
            if task.success >= taskInfo.success_rate1 then
                LoadStory(1000021 + task.gid * 100);
                view.top.none:SetActive(false);
                view.top.reward:SetActive(true);
                view.receive.Text[UnityEngine.UI.Text]:TextFormat("领取");
                view.title.name[CS.UnityEngine.UI.Text].text = SGK.Localize:getInstance():getValue("biaoti_renwuxinxi_01");
            else
                LoadStory(1000011 + task.gid * 100);
                view.top.none:SetActive(true);
                view.top.reward:SetActive(false);
                view.receive.Text[UnityEngine.UI.Text]:TextFormat("确认");
                view.title.name[CS.UnityEngine.UI.Text]:TextFormat("<size=44>失</size>败");
            end
            view.title[CS.UnityEngine.RectTransform]:SetSizeWithCurrentAnchors(UnityEngine.RectTransform.Axis.Vertical,770);
            view.bottom.info.time[CS.UnityEngine.UI.Text].text = "00:00:00";
            view.bottom.info.Text[CS.UnityEngine.UI.Text]:TextFormat("任务已完成");
            view.receive:SetActive(true);
            CS.UGUIClickEventListener.Get(view.receive.gameObject).onClick = function ()
                self:UpdateButtonState(false);
                self.manorProductInfo:RewardTask(task.gid);
            end
        else
            view.title.name[CS.UnityEngine.UI.Text].text = SGK.Localize:getInstance():getValue("biaoti_renwuxinxi_01");
            view.title[CS.UnityEngine.RectTransform]:SetSizeWithCurrentAnchors(UnityEngine.RectTransform.Axis.Vertical,730);
            view.bottom.info.time[CS.UnityEngine.UI.Text].text = GetTimeFormat(task.end_time - Time.now(),2);
            view.bottom.info.Text[CS.UnityEngine.UI.Text]:TextFormat("任务派遣中...");
            view.receive:SetActive(false);
        end
    elseif type == 2 then
        self.staff = {}; 
        self.heroInfo = self:ScreenHero(self.heros, taskInfo, true);
        self.heroView.DataCount = #self.heroInfo;
        -- self.heroView:ItemRef();
        CS.UGUIClickEventListener.Get(view.bottom.dispatch.gameObject).onClick = function ( object )
            if self.dispatching then
                return;
            end
            local staff_id = {};
            for k,v in ipairs(self.staff) do
                if v.id then
                    table.insert(staff_id, v.id);
                end
            end
            if #staff_id == 0 then
                showDlgError(nil, "没有派遣人员");
            else
                self.dispatching = true;
                self.manorProductInfo:DispatchTask(task.gid, staff_id)
            end
        end	
        self:RefreshWorker();
    end
    view:SetActive(true);
	--self.manorProductInfo:QueryTask();
end

function View:UpdateButtonState(state)
    -- local gray_material = self.dialog.task_info.receive[CS.UnityEngine.MeshRenderer].materials[0];
    if self.dialog.task_info.activeSelf then
        SetButtonStatus(state, self.dialog.task_info.receive)
    end
    for i,v in ipairs(self.taskUI) do
        if v.activeSelf then
            local task_item = CS.SGK.UIReference.Setup(v);
            if task_item.receive.activeSelf then
                SetButtonStatus(state, task_item.receive)
            end
        end
    end
end

function View:RefreshWorker()
	local effect = 0;
	for i=1,5 do
		local item = self.dialog.task_dispatch.bottom.workers["worker"..i];
		if self.staff[i] then
			local heroInfo = self.staff[i];
			local hero = self.manager:GetByUuid(heroInfo.id);
            local animation = item.character[CS.Spine.Unity.SkeletonGraphic];
            animation.skeletonDataAsset = utils.SGKTools.loadExistSkeletonDataAsset("roles_small/", hero.id, hero.mode,"_SkeletonData");
            animation.startingAnimation = "idle1";
	        animation.startingLoop = true;
            animation:Initialize(true);
            item.character:SetActive(true);
            item.click:SetActive(false);
            effect = effect + heroInfo.effect;
		else
			item.character:SetActive(false);
            item.click:SetActive(true);
		end
    end
    
	effect = effect > 100 and 100 or effect;
    self.dialog.task_dispatch.bottom.info.chance[CS.UnityEngine.UI.Text]:TextFormat("成功率：{0}%", math.floor(effect));
end

function View:updateEffectDes(heroInfo,taskInfo)
	local string = ""
	local des = self.work_type_config[self.prop_type[1].id].effect_des;
	local value = 0;
	for i,v in ipairs(self.prop_type) do
		value = value + heroInfo.prop[v.id] * v.ratio;
		-- print("updateEffectDes", value, heroInfo.prop[v.id], v.ratio,taskInfo.task_mark);
	end
	value = value / taskInfo.task_mark;
	value = value > 1 and 100 or (value * 100);
	string = "效果："..string.format(des, string.format("%.2f",value)).."%。";

	return value;
end


function View:RefreshTask()
	local task = self.manorProductInfo:GetTask();
	local free_count, cost = 0, 0;
	if 3 - task.change_count > 0 then
		free_count = 3 - task.change_count;
	else
		cost = math.floor((task.change_count - 3)/10) * 10 + 2;
	end
	for k,v in pairs(self.taskUI) do
		v:SetActive(false);
	end
	print("self.taskUI",sprinttb(task))
	-- self.dialog.task.bg.middle.info.count[CS.UnityEngine.UI.Text].text = free_count.."/3";
	-- self.dialog.task.bg.middle.info.today[CS.UnityEngine.UI.Text].text = (task.compelet_count or 0).."/10";
	-- self.dialog.task.bg.middle.info.cost[CS.UnityEngine.UI.Text].text = tostring(cost);

	local task_list = {};
	for k,v in pairs(task.list) do
        local info = {};
        info = v;
        if v.state == 1 then    
            info.sort = 2;--未开始
        elseif v.state == 2 then
            if v.end_time <= Time.now() then
                info.sort = 1;--已完成
            else
                info.sort = 3;--正在进行
            end
        end
        table.insert(task_list, info);
    end
    
    table.sort(task_list, function ( a,b )
        if a.sort ~= b.sort then
            return a.sort < b.sort;
        end
		if a.gid ~= b.gid then
			return a.gid < b.gid;
		end
    end)
    
	-- print("挑选任务", sprinttb(task_list))
	if #task_list == 0 then
		self.view.bottom.Text:SetActive(true);
	else
		self.view.bottom.Text:SetActive(false);
	end

	for i,v in ipairs(task_list) do
		local obj = nil;
		if self.taskUI[i] == nil then
            obj = UnityEngine.Object.Instantiate(self.view.bottom.task.gameObject);
            obj.transform:SetParent(self.taskView.transform,false);        
			self.taskUI[i] = obj;
		else
			obj = self.taskUI[i];
        end 
        obj.name = "task"..i--tostring(v.gid);
        local taskInfo = ManorModule.GetManorTaskInfo(v.gid);
        local taskCfg = ManorModule.GetManorTaskConfig(v.gid);
        local task_item = CS.SGK.UIReference.Setup(obj);
        if taskInfo and taskCfg then
            task_item.tip1:SetActive(taskCfg.task_type == 1);
            task_item.tip2:SetActive(taskCfg.task_type ~= 1);
            task_item.name[CS.UnityEngine.UI.Text]:TextFormat(taskInfo.task_tittle2);
            task_item.des[CS.UnityEngine.UI.Text].text = self:utf8sub(taskInfo.task_des);
            task_item.des[CS.UnityEngine.UI.Text].text = task_item.des[CS.UnityEngine.UI.Text].text.."...";
            task_item.bg:SetActive(v.sort ~= 2)
            task_item.go:SetActive(v.sort == 2);
            task_item.receive:SetActive(v.sort == 1);
            task_item.Text:SetActive(v.sort == 3);
            
            CS.UGUIClickEventListener.Get(task_item.receive.gameObject).onClick = function ()
                local task = self.manorProductInfo:GetTask(v.gid);
                if task.state == 2 and task.end_time <= Time.now() then
                    local story_id = 0;
                    if task.success >= taskInfo.success_rate1 then
                        story_id = 1000021 + v.gid * 100;
                    else
                        story_id = 1000011 + v.gid * 100;
                    end
                    LoadStory(story_id, function ()
                        self:UpdateButtonState(false);
                        self.manorProductInfo:RewardTask(v.gid);
                    end, true);
                else
                    showDlgError(nil, "任务未完成");
                end
            end
            
            -- CS.UGUIClickEventListener.Get(task_item.refresh.gameObject).onClick = function ()
            -- 	if task.change_count >= 100 then
            -- 		showDlgError(nil, "今日已经达到刷新上限");
            -- 		return;
            -- 	end
            -- 	if ItemModule.GetItemCount(90006) < cost then
            -- 		showDlgError(nil, "钻石不足");
            -- 		return;
            -- 	end
            -- 	self.manorProductInfo:ChangeTask(v.gid);
            -- end	
    
            CS.UGUIClickEventListener.Get(obj).onClick = function ()
                if v.sort == 1 then
                    self:ShowTaskFrame(v, 1);
                elseif v.sort == 2 then
                    --派遣
                    self:ShowTaskFrame(v, 2);
                    LoadStory(1000001 + v.gid * 100);
                elseif v.sort == 3 then
                    --查看任务信息
                    self:ShowTaskFrame(v, 1);
                end
            end	
            obj:SetActive(true);
        else
            obj:SetActive(false);  
            ERROR_LOG("任务配置未找到", v.gid)          
        end
    end
    if #self.taskUI > #task_list then
        for i=#task_list + 1,#self.taskUI do
            self.taskUI[i]:SetActive(false);
        end
    end
end

function View:utf8sub(input)
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
        
        -- cnt = cnt + 1
        -- if cnt == 19 then
       	-- 	return string.sub(input, 1, -left)
        -- end
        if i ~= 1 then
            _count = _count + i
        else
            cnt = cnt + 1
        end
        if (cnt + _count) >= 57 then
            return string.sub(input, 1, cnt + _count)
        end
    end
    return input;
end


function View:RandomPickup(_tab,count)
	local tab = _tab;
	local result = {};
	if #tab > count then
		for i=1,count do
			local pos = math.random(1,#tab);
			table.insert(result, tab[pos]);
			table.remove(tab, pos);
		end
	else
		return tab;
	end	
	return result;
end

function View:Update()
    if Time.now() - self.update_time >= 1 then
        self.update_time = Time.now();
        if #self.begin_task > 0 then
            for i,v in ipairs(self.begin_task) do
                local time = v.end_time - Time.now();
                if time > 0 then
                    if self.dialog.task_info.gameObject.activeSelf and v.gid == self.task.gid then
                        self.dialog.task_info.bottom.info.time[CS.UnityEngine.UI.Text].text = GetTimeFormat(time,2);
                    end
                elseif time == 0 then
                    if self.dialog.task_info.gameObject.activeSelf then
                        self.dialog.task_info:SetActive(false);
                    end
                    ERROR_LOG("重新查询")
                    self.manorProductInfo:QueryTask();
                end
            end
        end
        --酒馆小人动画
        for k,v in pairs(self.character) do
            if Time.now() >= (v.nextMoveTime or 0) and self.init then
                self.character[k].nextMoveTime = Time.now() + math.random(10,25)
                local canMovePoint = {};
                for i,v in ipairs(self.movePoint) do
                    if v == 1 then
                        table.insert(canMovePoint,i);
                    end
                end
                if self.character[k].pos and self.character[k].pos ~= 0 then
                    self.movePoint[self.character[k].pos] = 1;
                end
                if #canMovePoint < 1 then
                    ERROR_LOG("canMovePoint", sprinttb(self.movePoint))
                else
                    local pos = canMovePoint[math.random(1,#canMovePoint)];
                    self.movePoint[pos] = 0;
                    self.character[k].pos = pos;
    
                    if self.character[k].obj[UnityEngine.CanvasGroup].alpha == 0 then
                        self.character[k].obj[UnityEngine.CanvasGroup]:DOFade(1, 1):OnComplete(function ()
                            self.controller:MoveCharacter(k,"pos"..pos);
                        end)
                    else
                        self.controller:MoveCharacter(k,"pos"..pos);
                    end
                end
            end
        end
        if Time.now() >= self.npc.next_move_time then
            self.npc.next_move_time = Time.now() + math.random(5,10)
            local pos = self.npc.pos + 1;
            if pos > 4 then
                pos = 1;
            end
            self.npc.pos = pos;
            self.controller:MoveCharacter(0, "renwu"..pos);
        end
    end    
end

function View:NpcSpeak(npc_view, type, str, func)
	if str == "" then
		return;
	end
    npc_view.dialogue.bg1:SetActive(type == 1)
    npc_view.dialogue.bg2:SetActive(type == 2)
    npc_view.dialogue.bg3:SetActive(type == 3)
    npc_view.dialogue.desc[UnityEngine.UI.Text].text = str;

    if npc_view.qipao and npc_view.qipao.activeSelf then
        npc_view.qipao[UnityEngine.CanvasGroup]:DOFade(0,0.5):OnComplete(function()
            npc_view.dialogue[UnityEngine.CanvasGroup]:DOFade(1,1):OnComplete(function()
                npc_view.dialogue[UnityEngine.CanvasGroup]:DOFade(0,1):OnComplete(function()
                    npc_view.dialogue.desc[UnityEngine.UI.Text].text = "";
                    if func then
                        func()
                    end
                    npc_view.qipao[UnityEngine.CanvasGroup]:DOFade(1,0.5);
                end):SetDelay(1)
            end)        
        end)
    else
        npc_view.dialogue[UnityEngine.CanvasGroup]:DOFade(1,1):OnComplete(function()
            npc_view.dialogue[UnityEngine.CanvasGroup]:DOFade(0,1):OnComplete(function()
                npc_view.dialogue.desc[UnityEngine.UI.Text].text = "";
                if func then
                    func()
                end
            end):SetDelay(1)
        end)
    end
end

function View:MoveTeam(gid)
    -- coroutine.resume(coroutine.create( function ()
    --     for i,v in ipairs(self.taskTeam) do
    --         Sleep(0.2);
    --         v.obj[UnityEngine.CanvasGroup]:DOFade(1, 1):OnComplete(function ()
    --             if i == 1 then
    --                 self.controller:MoveCharacter(v.uuid,"list"..i, function ()
    --                     local taskInfo = ManorModule.GetManorTaskInfo(gid);
    --                     self:NpcSpeak(v.obj.Label, 1, taskInfo.task_tittle2, function ()
    --                         self:NpcSpeak(self.view.top.content.npc.Label, 1, "预祝好运！", function ()
    --                             for _,j in ipairs(self.taskTeam) do
    --                                 self.controller:MoveCharacter(j.uuid,"start", function ()
    --                                     j.obj[UnityEngine.CanvasGroup]:DOFade(0, 1):OnComplete(function ()
    --                                         self.controller:Remove(j.uuid);
    --                                     end)
    --                                 end);
    --                                 Sleep(0.2);
    --                             end
    --                         end)
    --                     end)
    --                 end);
    --             else
    --                 self.controller:MoveCharacter(v.uuid,"list"..i);
    --             end
    --         end)
    --     end
    -- end));
    self.npc.next_move_time = Time.now() + 10000;
    self.controller:MoveCharacter(0,"renwu1");
    for i,v in ipairs(self.taskTeam) do
        v.obj[UnityEngine.CanvasGroup]:DOFade(1, 1):OnComplete(function ()
            if i == 1 then
                v.obj.Label.leader:SetActive(true);
                self.controller:MoveCharacter(v.uuid,"list"..i, function ()
                    local taskInfo = ManorModule.GetManorTaskInfo(gid);
                    self:NpcSpeak(v.obj.Label, 1, taskInfo.task_tittle2, function ()
                        self:NpcSpeak(self.view.top.content.npc.Label, 1, "预祝好运！", function ()
                            print("返回")
                            for k,j in ipairs(self.taskTeam) do
                                j.obj[UnityEngine.CanvasGroup]:DOFade(1, 0.1):OnComplete(function ()
                                    self.controller:MoveCharacter(j.uuid,"start", function ()
                                        j.obj[UnityEngine.CanvasGroup]:DOFade(0, 1):OnComplete(function ()
                                            if k == 1 then
                                                ManorManufactureModule.SetTaskTeamInfo(gid, {enter = true, out_time = Time.now()})
                                                self.haveTeam = 0;
                                            end
                                            self.controller:Remove(j.uuid);
                                            self.npc.next_move_time = Time.now() + math.random(5,10);
                                        end)
                                    end);
                                end):SetDelay(0.7 * k );
                            end
                        end)
                    end)
                end);
            else
                self.controller:MoveCharacter(v.uuid,"list"..i);
            end
        end):SetDelay(0.5 * i);
    end
end

function View:GetTaskTeamInfo()
    local info = ManorManufactureModule.GetTaskTeamInfo();
    self.taskTeam = {};
    -- local info = {};
    -- local tt = {};
    -- tt.gid = 21;
    -- tt.moving = true;
    -- tt.staff = {1,2,3,4,5};
    -- info[1] = tt;
    for k,v in pairs(info) do
        if v.moving then
            if self.haveTeam == 0 then
                self.haveTeam = v.gid;
                ManorManufactureModule.SetTaskTeamInfo(v.gid, {enter = true, out_time = Time.now() + 100})
                for i,j in ipairs(v.staff) do
                    local character = UnityEngine.Object.Instantiate(self.view.top.content.dialog_character.gameObject, self.view.top.content.gameObject.transform);
                    character.name = tostring(j);
                    local hero = self.manager:GetByUuid(j);
                    local item = CS.SGK.UIReference.Setup(character);
                    local info = {};
                    info.obj = item;
                    info.uuid = j
                    self.taskTeam[i] = info;
                    character:SetActive(true);
                    self:LoadAnimaion(item, hero.id, hero.mode);
                    self.controller:Add(j, character);
                end
                self:MoveTeam(v.gid)
            end
            break;
        end
    end
end

function View:SaveData()
    local character = {};
    for k,v in pairs(self.character) do
        local info = {};
        info.pos = v.pos;
        info.direction = v.obj.spine[SGK.DialogSprite].direction;
        info.uuid = v.uuid;
        character[k] = info;
    end
    local manor_character_move_data = UserDefault.Load("character_move_data", true);
    manor_character_move_data.data = {};
    manor_character_move_data.data = character;

    UserDefault.Save();
end

function View:deActive()
	for i=#self.dialog,1,-1 do
		if self.dialog[i].active then
			self.dialog[i]:SetActive(false);
			return false;
		end
    end
    if self.haveTeam ~= 0 and #self.taskTeam ~= 0 then
        ManorManufactureModule.SetTaskTeamInfo(self.haveTeam, {enter = true, out_time = Time.now() + math.random(1,2)})
    end
    utils.SGKTools.PlayDestroyAnim(self.gameObject)
	return true;
end

function View:listEvent()
	return {
        "MANOR_MANUFACTURE_PRODUCT_LINE_CHANGE",
        "MANOR_TASK_INFO_CHANGE",
        "MANOR_TASK_EMPTY",
        "MANOR_SHOW_REWARD",
        "MANOR_DISPATCH_TASK_SUCCEED",
        "MANOR_NPC_START_MOVE",
        "MANOR_NPC_END_MOVE",
        "MANOR_NPC_ENTER_TAVERN",
        "LOCAL_GUIDE_CHANE"
	}
end

function View:onEvent(event, ...)
	-- print("onEvent", event, sprinttb(...));
	if event == "MANOR_MANUFACTURE_PRODUCT_LINE_CHANGE"  then
        self:RefreshFrame();
    elseif event == "MANOR_TASK_INFO_CHANGE" then
        self.view.bottom.loading:SetActive(false);
        self:RefreshTask();
        local task = self.manorProductInfo:GetTask();
		self.begin_task, self.end_task = {},{};
		local canStart = 0;
		for i,v in pairs(task.list) do
			if v.state == 1 then
				canStart = canStart + 1;
			end
			if v.state == 2 then
				table.insert(self.begin_task, v);			
				if v.end_time and v.end_time <= Time.now() then
					table.insert(self.end_task, v);	
				end
			end
		end
        -- print("任务信息", canStart, sprinttb(task))
        if canStart > 0 then
            self.view.top.content.task[CS.Spine.Unity.SkeletonGraphic].AnimationState:SetAnimation(0,"work",true);
            self.view.top.content.npc.Label.qipao[UnityEngine.CanvasGroup]:DOFade(1,0.5);
        else
            self.view.top.content.task[CS.Spine.Unity.SkeletonGraphic].AnimationState:SetAnimation(0,"nowork",true);
            self.view.top.content.npc.Label.qipao[UnityEngine.CanvasGroup]:DOFade(0,0.5);
        end

        --self.view.top.content.task[CS.Spine.Unity.SkeletonGraphic]:Initialize(true);
        if self.dispatching then
            self.task = task.list[self.task.gid]
            self.dispatching = false;
            self.dialog.task_dispatch:SetActive(false);
            self:ShowTaskFrame(self.task,1);
        end
        self:RefreshFrame();
        if self.guide then
            self.guide = false;
            module.guideModule.PlayByType(22, 0.2);
        end
        --view.bottom.tip1[CS.UnityEngine.UI.Text]:TextFormat("今日已完成（{0}）", (task.compelet_count or 0).."/10");
        -- view.bottom.manage.count[CS.UnityEngine.UI.Text].text = #self.end_task.."/"..#self.begin_task;
    elseif event == "MANOR_SHOW_REWARD" then
        -- local data = ...;
        -- if #data.reward == 0 then
        --     showDlgError(nil, "很遗憾，任务失败了");
        -- end
        self:UpdateButtonState(true);
        if self.dialog.task_info.gameObject.activeSelf then
            self.dialog.task_info:SetActive(false);
        end
    elseif event == "MANOR_DISPATCH_TASK_SUCCEED" then
        self.manorProductInfo:QueryTask();       
    elseif event == "MANOR_NPC_START_MOVE" then
        local data = ...;
        if data.from == "tavern" then
            self:RefreshFrame();
        end
    elseif event == "MANOR_NPC_END_MOVE" then
        local data = ...;
        if data.to == "tavern" then
            self:RefreshFrame();
        end
    elseif event == "MANOR_NPC_ENTER_TAVERN" then
        self:GetTaskTeamInfo();
    elseif event == "LOCAL_GUIDE_CHANE" then
        module.guideModule.PlayByType(22, 0.2);
	end
end

return View;