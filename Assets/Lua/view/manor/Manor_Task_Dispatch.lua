local ManorManufactureModule = require "module.ManorManufactureModule"
local ItemHelper = require "utils.ItemHelper"
local HeroModule = require "module.HeroModule"
local ManorModule = require "module.ManorModule"
local Time = require "module.Time"
local UserDefault = require "utils.UserDefault"

local card_id = 90020;
local View = {};
function View:Start(data)
	self.root = CS.SGK.UIReference.Setup(self.gameObject);
    self.view = self.root.view;
    self.dialog = self.root.dialog;
	self:InitData();
	self:InitView();
end

function View:InitData()
	self.manorProductInfo = ManorManufactureModule.Get();
	self.manorProductInfo:CheckWorkerProperty();
	self.manorProductInfo:QueryTask();
	self.manager = HeroModule.GetManager();
	self.manor_property = ManorModule.GetManorProperty();
	self.heros = self.manager:Get();
	self.taskView = self.view.bottom.ScrollView.Viewport.Content.gameObject;
	self.heroView = self.dialog.task_dispatch.bottom.dispatch.ScrollView[CS.UIMultiScroller];
    self.shopInfo = module.ShopModule.GetManager(2);
    self.manorProductInfo:GetStarBoxInfoFromServer();

	self.work_type_config = ManorModule.GetManorWorkType();
	self.task = {};
    self.staff = {};
    self.task_list = {};
	self.update_time = 0;
	self.begin_task = {}; 
	self.end_task = {};
	self.taskUI = {};
    self.dispatching = false;
    self.cancel = false;
    self.finish = false;
    self.refresh = false;
    self.buy = false;
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
	CS.UGUIClickEventListener.Get(self.root.BG.gameObject).onClick = function ( object )
        DialogStack.Pop()
   	end
    CS.UGUIClickEventListener.Get(self.view.title.close.gameObject).onClick = function ( object )
  	    DialogStack.Pop()
    end
    CS.UGUIClickEventListener.Get(self.view.bottom.refresh.icon.gameObject).onClick = function ( object )
        self.buy = true;
        DialogStack.PushPrefStact("ItemDetailFrame", {id = card_id, type = 41, InItemBag = 2}, self.dialog.gameObject)
    end
    self.view.bottom.refresh.icon[UnityEngine.UI.Image]:LoadSprite("icon/"..card_id.."_small");
    self.dialog.tip1.icon[UnityEngine.UI.Image]:LoadSprite("icon/"..card_id.."_small");
    self.dialog.tip2.confirm.icon[UnityEngine.UI.Image]:LoadSprite("icon/"..card_id.."_small");
    
    local task_starbox_cfg = ManorModule.GetManorTaskStarBoxConfig();
    for i,v in ipairs(task_starbox_cfg) do
        local box = self.view.top.reward["item"..i];
        if box then
            box.Text[UnityEngine.UI.Text].text = v.star_value;
            CS.UGUIClickEventListener.Get(box.gameObject).onClick = function ( object )
                local task = self.manorProductInfo:GetTask();
                if task.starBox then
                    if (task.starBox.count or 0) >= v.star_value then
                        if task.starBox.status[i] == 0 then
                            self.manorProductInfo:RewardStarBox(v.gid);
                        else
                            self:ShowReward(v);
                        end
                    else
                        -- showDlgError(nil, "星星数量不足");
                        self:ShowReward(v);
                    end
                end
            end
        end
    end
    
    CS.UGUIClickEventListener.Get(self.view.bottom.refresh.btn.gameObject).onClick = function ( object )
        local product = module.ShopModule.GetManager(2, card_id)[1];
        if product then
            local count = module.ItemModule.GetItemCount(card_id);
            if count > 0 then
                self.dialog.tip2.confirm.count[UnityEngine.UI.Text]:TextFormat("{0}/{1}", count, 1);
                self.dialog.tip2:SetActive(true);
            else
                -- self.dialog.tip1.confirm.count[UnityEngine.UI.Text].text = "X"..product.consume_item_value1;
                -- self.dialog.tip1:SetActive(true);
                self.buy = true;
                DialogStack.PushPrefStact("ItemDetailFrame", {id = card_id, type = 41, InItemBag = 2}, self.dialog.gameObject)
                showDlgError(nil, "您的 酒馆刷新令 数量不足")
            end
        end
    end
    
    CS.UGUIClickEventListener.Get(self.dialog.tip1.confirm.gameObject).onClick = function ( object )
        local product = module.ShopModule.GetManager(2, card_id)[1];
        if product then
            if module.ItemModule.GetItemCount(product.consume_item_id1) >= product.consume_item_value1 then
                SetButtonStatus(false, self.dialog.tip1.confirm)
                self.buy = true;
                module.ShopModule.Buy(2, product.gid, 1);
            else
                showDlgError(nil, "钻石不足");
            end
        end
    end

    CS.UGUIClickEventListener.Get(self.dialog.tip2.confirm.gameObject).onClick = function ( object )
        local product = module.ShopModule.GetManager(2, card_id)[1];
        if product then
            local count = module.ItemModule.GetItemCount(card_id);
            if count > 0 then
                SetButtonStatus(false, self.dialog.tip2.confirm)
                self.refresh = true;
                self.manorProductInfo:RefreshAllTask();
            else
                showDlgError(nil, "刷新卡不足")
            end
        end
    end

	self.heroView.RefreshIconCallback = function ( obj, idx )
		local heroinfo = self.heroInfo[idx + 1];
		local hero = self.manager:GetByUuid(heroinfo.id);
        local item = CS.SGK.UIReference.Setup(obj);
        utils.IconFrameHelper.Create(item.IconFrame,{type = 42, uuid = heroinfo.id, customCfg = {star = 0}})
        item.prop[UnityEngine.UI.Text].text = self.work_type_config[self.prop_type].work_type;
        item.num[UnityEngine.UI.Text].text = heroinfo.prop[self.prop_type];

        if heroinfo.state and heroinfo.state.task and heroinfo.state.task == 1 then
            item.tip:SetActive(false);
            item.lock:SetActive(true);
            item.lock.Text[UnityEngine.UI.Text]:TextFormat("执行中");
        else
            item.tip:SetActive(heroinfo.pass == 4 and self:GetGradeRank(hero.id, self.prop_type) == "S");
            item.lock:SetActive((heroinfo.index and heroinfo.index ~= 0) or heroinfo.pass ~= 4);
			item.lock.Text[UnityEngine.UI.Text].text = "";
        end
        item.select:SetActive(heroinfo.index and heroinfo.index ~= 0);
        if heroinfo.condition[4] ~= 1 and item.lock.Text[UnityEngine.UI.Text].text == "" then
			item.lock.Text[UnityEngine.UI.Text].text = "活力不足";
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
                item.lock:SetActive(true);
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
                item.lock:SetActive(false);
                item.select:SetActive(false);
                self:RefreshWorker();
            end
        end
        item:SetActive(true);
    end
end

function View:ShowReward(cfg)
    for j=1,3 do
        local item = self.dialog.review.reward["item"..j];
        if cfg["reward_id"..j] ~= 0 then
            utils.IconFrameHelper.Create(item,{type = cfg["reward_type"..j], id = cfg["reward_id"..j], count = cfg["reward_value"..j], showDetail = true})
            item:SetActive(true);
        else
            item:SetActive(false);
        end
    end
    self.dialog.review:SetActive(true);
end

function View:ScreenHero(heros, taskInfo, sort)
	local heroInfo = {};
	for _,v in pairs(heros) do
		local info = {};
		info = self.manorProductInfo:GetWorkerInfo(v.uuid,1);
		if info then
			local pass = 0;
			local condition = {0 ,0, 0, 0};
			if v.level >= taskInfo.require1 then
				pass = pass + 1;
				condition[1] = 1;
			end
			if taskInfo.require2 == 0 or v.type & taskInfo.require2 ~= 0 then
				pass = pass + 1;
				condition[2] = 1;
			end
			if info.prop[self.prop_type] >= taskInfo.require3 then
				pass = pass + 1;
				condition[3] = 1;
			end
            if info.power >= taskInfo.require_energy then
                pass = pass + 1;
				condition[4] = 1;
            end

			info.id = v.uuid;
			info.pass = pass;
			info.condition = condition;
			info.index = 0;
            info.state = self.manorProductInfo:GetWorkerInfo(v.uuid,2) or {state = 0, working = 0, task = 0};
            -- info.effect = self:updateEffectDes(info,taskInfo);
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
			if a.prop[self.prop_type] ~= b.prop[self.prop_type] then
				return a.prop[self.prop_type] > b.prop[self.prop_type]
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

function View:ShowTaskFrame(task, type)
    -- print("任务信息",sprinttb(task));
    self.task = task;
    local view = self.dialog.task_dispatch;
    if type == 1 then
        view.bottom.transform.localPosition = Vector3(2.8, -150, 0);
    elseif type == 2 then
        view.bottom.transform.localPosition = Vector3(2.8, -135, 0);
    end

	view.bottom.doing:SetActive(type == 1);
	view.bottom.dispatch:SetActive(type == 2);
	
    local taskInfo = ManorModule.GetManorTaskInfo(task.gid);
    local taskCfg = ManorModule.GetManorTaskConfig(task.gid);
    self.prop_type = taskInfo.task_work_type;
    view.top.tip.Text[CS.UnityEngine.UI.Text]:TextFormat(taskInfo.task_tittle2);
    view.top.des[CS.UnityEngine.UI.Text]:TextFormat(taskInfo.task_des);
    view.top.time[CS.UnityEngine.UI.Text].text = GetTimeFormat(taskCfg.hold_time, 2);
    for i=1,5 do
        local star = view.top.tip.stars["star"..i];
        star:SetActive(taskInfo.task_star >= i);
    end	

    for i=1,3 do
        if i < 3 and taskInfo["reward_id"..i] and taskInfo["reward_id"..i] ~= 0 then
            utils.IconFrameHelper.Create(view.top.reward.normal["item"..i],{type = taskInfo["reward_type"..i], id = taskInfo["reward_id"..i], count = taskInfo["reward_num_min"..i], showDetail = true})
            view.top.reward.normal["item"..i].gameObject:SetActive(true);
        else
            view.top.reward.normal["item"..i].gameObject:SetActive(false);
        end
        if taskInfo["require"..i] ~= 0 then
            if i == 1 then
				view.bottom.info.need.level[CS.UnityEngine.UI.Text].text = "Lv."..taskInfo["require"..i];
			elseif i == 3 then
				view.bottom.    info.need.Text[CS.UnityEngine.UI.Text].text = self.work_type_config[self.prop_type].work_type..": "
				view.bottom.info.need.num[CS.UnityEngine.UI.Text].text = taskInfo["require"..i];
            end 
        end
    end

    view.bottom.info.prop.Text[CS.UnityEngine.UI.Text]:TextFormat("上阵成员{0}值:", self.work_type_config[self.prop_type].work_type);
    if taskInfo.reward_id3 ~= 0 then
        view.top.reward.info.need[CS.UnityEngine.UI.Text]:TextFormat("【需要{0}: {1}】", self.work_type_config[self.prop_type].work_type, taskInfo.task_mark);
        utils.IconFrameHelper.Create(view.top.reward.extra.item1,{type = taskInfo.reward_type3, id = taskInfo.reward_id3, count = taskInfo.reward_num_min3, showDetail = true})
        view.top.reward.extra.item1:SetActive(true);
    else
        view.top.reward.info.need[CS.UnityEngine.UI.Text].text = "";
        view.top.reward.extra.item1:SetActive(false);
    end

	if type == 1 then
		local num = 0;
        for i=1,5 do
            if task.staff[i] then
				local hero = self.manager:GetByUuid(task.staff[i]);
				local info = self.manorProductInfo:GetWorkerInfo(task.staff[i], 1);
				num = num + info.prop[self.prop_type];
                utils.IconFrameHelper.Create(view.bottom.info.workers["worker"..i].IconFrame,{type = 42, uuid = task.staff[i], customCfg = {star = 0}})
                view.bottom.info.workers["worker"..i].IconFrame:SetActive(true);
                view.bottom.info.workers["worker"..i]:SetActive(true);
            else
                view.bottom.info.workers["worker"..i]:SetActive(false);
            end
        end
		view.bottom.info.prop.num[CS.UnityEngine.UI.Text].text = num;

        if task.state == 2 and task.end_time <= Time.now() then
            if task.success >= taskInfo.success_rate1 then
                LoadStory(1000021 + task.gid * 100);
            else
                LoadStory(1000011 + task.gid * 100);
            end
            view.bottom.doing.info.Text:SetActive(false);
			view.bottom.doing.info.time:SetActive(false);
			view.bottom.doing.info.finish:SetActive(true);
			view.bottom.doing.get:SetActive(true);
			view.bottom.doing.cancel:SetActive(false);
            view.bottom.doing.fast:SetActive(false);
            view.bottom.doing.info.Slider[UnityEngine.UI.Slider].value = 1; 
            CS.UGUIClickEventListener.Get(view.bottom.doing.get.gameObject).onClick = function ()
                self:UpdateButtonState(false);
                self.manorProductInfo:RewardTask(task.gid);
            end
        else
            view.bottom.doing.info.Text:SetActive(true);
			view.bottom.doing.info.time:SetActive(true);
			view.bottom.doing.info.finish:SetActive(false);
			view.bottom.doing.get:SetActive(false);
			view.bottom.doing.cancel:SetActive(true);
            view.bottom.doing.fast:SetActive(true);
            view.bottom.doing.info.Slider[UnityEngine.UI.Slider].value = 1 - (task.end_time - Time.now()) / (task.end_time - task.begin_time); 
            view.bottom.doing.info.time[CS.UnityEngine.UI.Text].text = GetTimeFormat(task.end_time - Time.now(),2);
            view.bottom.doing.fast.count[UnityEngine.UI.Text].text = "X"..math.ceil((task.end_time - Time.now()) / 1200)
			CS.UGUIClickEventListener.Get(view.bottom.doing.cancel.gameObject).onClick = function ()
                print("取消", task.gid);
                local data = {};
                data.msg = SGK.Localize:getInstance():getValue("jiuguan_tip_1");
                data.confirm = function ()
                    self.cancel = true;
                    self:UpdateButtonState(false);
                    self.manorProductInfo:CancelTask(task.gid);
                end;
                data.cancel = function () end;
                data.txtConfirm = SGK.Localize:getInstance():getValue("jiuguan_tip_2");
                data.title = "取消任务";
                DlgMsg(data)
			end
            CS.UGUIClickEventListener.Get(view.bottom.doing.fast.gameObject).onClick = function ()
                local need = math.ceil((task.end_time - Time.now()) / 1200);
                if need > 0 then
                    local count = module.ItemModule.GetItemCount(90003);
                    if count < need then
                        showDlgError(nil, "金币不足")
                    else
                        -- local data = {};
                        -- data.msg = SGK.Localize:getInstance():getValue("jiuguan_tip_3", need.."金币");
                        -- data.confirm = function ()
                            
                        -- end;
                        -- data.cancel = function () end;
                        -- data.title = "立刻完成";
                        -- DlgMsg(data)
                        self.dialog.fast.icon.count[UI.Text].text = need;
                        CS.UGUIClickEventListener.Get(self.dialog.fast.confirm.gameObject).onClick = function ()
                            self.finish = true;
                            self:UpdateButtonState(false);
                            self.manorProductInfo:FinishTask(task.gid);
                            self.dialog.fast:SetActive(false);
                        end
                        self.dialog.fast:SetActive(true);
                    end
                end
            end
        end
    elseif type == 2 then
        for i=1,5 do
            view.bottom.info.workers["worker"..i]:SetActive(true);
            view.bottom.info.workers["worker"..i].IconFrame:SetActive(false);
        end
        self.staff = {}; 
        self.heroInfo = self:ScreenHero(self.heros, taskInfo, true);
        self.heroView.DataCount = #self.heroInfo;
        -- self.heroView:ItemRef();
        CS.UGUIClickEventListener.Get(view.bottom.dispatch.go.gameObject).onClick = function ( object )
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
                self:UpdateButtonState(false)
                self.manorProductInfo:DispatchTask(task.gid, staff_id)
            end
        end	
        self:RefreshWorker();
    end
    view:SetActive(true);
	--self.manorProductInfo:QueryTask();
end

function View:UpdateButtonState(state)
    SetButtonStatus(state, self.dialog.task_dispatch.bottom.dispatch.go)
    SetButtonStatus(state, self.dialog.task_dispatch.bottom.doing.get)
    SetButtonStatus(state, self.dialog.task_dispatch.bottom.doing.cancel)
    SetButtonStatus(state, self.dialog.task_dispatch.bottom.doing.fast)
end

function View:RefreshWorker()
	local num = 0;
	for i=1,5 do
		local item = self.dialog.task_dispatch.bottom.info.workers["worker"..i];
		if self.staff[i] then
			local heroInfo = self.staff[i];
			local hero = self.manager:GetByUuid(heroInfo.id);
			num = num + heroInfo.prop[self.prop_type];
            utils.IconFrameHelper.Create(item.IconFrame,{type = 42, uuid = heroInfo.id, customCfg = {star = 0}})
            item.IconFrame:SetActive(true);
		else
			item.IconFrame:SetActive(false);
		end
    end
    self.dialog.task_dispatch.bottom.info.prop.num[CS.UnityEngine.UI.Text].text = num;
end

function View:CheckNewTip(task, reset)
    local manor_task_data = UserDefault.Load("manor_task_data", true);
    local _t = os.date("*t", Time.now())
    if manor_task_data.newTip == nil then
        manor_task_data.newTip = {};
        manor_task_data.newTip.day = _t.day;
    end
    if manor_task_data.newTip.task == nil or manor_task_data.newTip.day ~= _t.day or reset then
        manor_task_data.newTip.day = _t.day;
        manor_task_data.newTip.task = {};
        for k,v in pairs(task.list) do
            manor_task_data.newTip.task[v.gid] = 0;
        end
    end
    return manor_task_data;
end

function View:UpdateStarBox()
    local task = self.manorProductInfo:GetTask();
    if task.starBox then
        local count = task.starBox.count or 0;
        self.view.top.count.Text[UnityEngine.UI.Text].text = count;
        self.view.top.Slider[UnityEngine.UI.Slider].value = count;
        if task.starBox.status then
            local task_starbox_cfg = ManorModule.GetManorTaskStarBoxConfig();
            for i,v in ipairs(task_starbox_cfg) do
                local box = self.view.top.reward["item"..i];
                if box then
                    local status = task.starBox.status[i] or 0;
                    box.get:SetActive(status == 1);
                    box.red:SetActive(status == 0 and count >= v.star_value)
                    if status == 1 then
                        box[CS.UGUISelectorGroup].index = 2;
                    elseif count >= v.star_value then
                        box[CS.UGUISelectorGroup].index = 1;
                    else
                        box[CS.UGUISelectorGroup].index = 0;
                    end
                end
            end
        end
    end
end

function View:RefreshTask(refresh)
	local task = self.manorProductInfo:GetTask();
    local manor_task_data = self:CheckNewTip(task, refresh)

    local count = module.ItemModule.GetItemCount(card_id);
    if count > 0 then
        self.view.bottom.refresh.count[UnityEngine.UI.Text]:TextFormat("{0}/{1}", count, 1);
    else
        self.view.bottom.refresh.count[UnityEngine.UI.Text]:TextFormat("<color=#FF0000FF>{0}</color>/{1}", count, 1);
    end
    self.view.bottom.refresh.num[UnityEngine.UI.Text].text = 6 - task.compelet_count;

	for k,v in pairs(self.taskUI) do
		v:SetActive(false);
	end
	print("self.taskUI",sprinttb(task))

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
    
	print("挑选任务", sprinttb(task_list))
	if #task_list == 0 then
		self.view.bottom.Text:SetActive(true);
	else
		self.view.bottom.Text:SetActive(false);
	end
    self.task_list = task_list;
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
            task_item.name[CS.UnityEngine.UI.Text]:TextFormat(taskInfo.task_tittle2);
            task_item.bg[CS.UGUISpriteSelector].index = (v.sort == 3) and 1 or 0;
            task_item.time[CS.UGUIColorSelector].index = (v.sort == 3) and 1 or 0;
            task_item.type[CS.UGUISpriteSelector].index = taskInfo.task_work_type - 801;
            local heroCfg = HeroModule.GetConfig(taskInfo.icon);
            if heroCfg then
                task_item.icon[UI.Image]:LoadSprite("icon/"..heroCfg.icon);
                task_item.icon.Text[UI.Text].text = heroCfg.name;
            end
            task_item.tip:SetActive(taskInfo.task_star >= 5 and v.sort == 2);
            task_item.red:SetActive(v.sort == 1);
            task_item.finish:SetActive(v.sort == 1);
            task_item.doing:SetActive(v.sort == 3);
            if v.state == 2 then
                local time = v.end_time - Time.now();
                if time > 0 then
                    task_item.time[CS.UnityEngine.UI.Text].text = GetTimeFormat(time, 2);
                else
                    task_item.time[CS.UnityEngine.UI.Text].text = "00:00:00"
                end
            else
                task_item.time[CS.UnityEngine.UI.Text].text = GetTimeFormat(taskCfg.hold_time, 2);
            end

            if v.sort == 2 and (manor_task_data.newTip.task[v.gid] == nil or manor_task_data.newTip.task[v.gid] == 0)then
                task_item.new:SetActive(true);
                manor_task_data.newTip.task[v.gid] = 1;
            else
                task_item.new:SetActive(false);
            end
            for i=1,5 do
                local star = task_item.stars["star"..i];
                star:SetActive(taskInfo.task_star >= i);
            end	
            
            CS.UGUIClickEventListener.Get(obj).onClick = function ()
                if v.sort == 1 then
                    self:ShowTaskFrame(v, 1);
                elseif v.sort == 2 then
                    --派遣
                    local _task = self.manorProductInfo:GetTask();
                    if _task.compelet_count >= 6 then
                        showDlgError(nil, "今日派遣次数已用完");
                    else
                        task_item.new:SetActive(false);
                        self:ShowTaskFrame(v, 2);
                        LoadStory(1000001 + v.gid * 100);
                    end
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

function View:Update()
    if Time.now() - self.update_time >= 1 then
        self.update_time = Time.now();
        if #self.begin_task > 0 then
            for i,v in ipairs(self.begin_task) do
                local time = v.end_time - Time.now();
                if time > 0 then
                    if self.dialog.task_dispatch.gameObject.activeSelf and self.dialog.task_dispatch.bottom.doing.gameObject.activeSelf and v.gid == self.task.gid then
                        self.dialog.task_dispatch.bottom.doing.info.time[CS.UnityEngine.UI.Text].text = GetTimeFormat(time,2);
                        self.dialog.task_dispatch.bottom.doing.info.Slider[UnityEngine.UI.Slider].value = 1 - time / (v.end_time - v.begin_time); 
                        self.dialog.task_dispatch.bottom.doing.fast.count[UnityEngine.UI.Text].text = "X"..math.ceil((v.end_time - Time.now()) / 1200)
                    end
                elseif time == 0 then
					--刷新任务		
					self:ShowTaskFrame(self.task,1);		
                    self.manorProductInfo:QueryTask();
                end
            end
        end
        if #self.task_list > 0 then
            for i,v in ipairs(self.task_list) do
                if v.state == 2 then
                    local time = v.end_time - Time.now();
                    local task_item = CS.SGK.UIReference.Setup(self.taskUI[i]);
                    if time > 0 then
                        task_item.time[CS.UnityEngine.UI.Text].text = GetTimeFormat(time, 2);
                    else
                        task_item.time[CS.UnityEngine.UI.Text].text = "00:00:00"
                    end
                end
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
	return true;
end

function View:listEvent()
	return {
		"MANOR_TASK_INFO_CHANGE",
		"MANOR_SHOW_REWARD",
        "MANOR_DISPATCH_TASK_SUCCEED",
        "SHOP_INFO_CHANGE",
        "MANOR_REFRESH_ALLTASK_SUCCESS",
        "SHOP_BUY_SUCCEED",
        "MANOR_TASK_STARBOX_CHANGE",
        "MANOR_FINISH_TASK_FAILED"
	}
end

function View:onEvent(event, ...)
    print("onEvent", event, ...);
    local data = ...;
	if event == "MANOR_TASK_INFO_CHANGE"  then
        self.view.bottom.loading:SetActive(false);
        self:RefreshTask(self.refresh);
        self:UpdateStarBox();
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

        --self.view.top.content.task[CS.Spine.Unity.SkeletonGraphic]:Initialize(true);
        if self.dispatching then
            self.task = task.list[self.task.gid]
            self.dispatching = false;
            -- self.dialog.task_dispatch:SetActive(false);
            self:UpdateButtonState(true)
            self:ShowTaskFrame(self.task,1);
        end
        if self.cancel then
            self.cancel = false;
            self:UpdateButtonState(true);
            self.dialog.task_dispatch:SetActive(false);
        end
        if self.finish then
            self.finish = false;
            self:UpdateButtonState(true);
            -- self.dialog.task_dispatch:SetActive(false);
            self.task = task.list[self.task.gid]
            self:ShowTaskFrame(self.task,1);
        end
        if self.refresh then
            self.refresh = false;
        end
	elseif event == "MANOR_SHOW_REWARD" then
        self:UpdateButtonState(true);
        if self.dialog.task_dispatch.gameObject.activeSelf then
            self.dialog.task_dispatch:SetActive(false);
        end
	elseif event == "MANOR_DISPATCH_TASK_SUCCEED" then
        self.manorProductInfo:QueryTask();   
    elseif event == "SHOP_INFO_CHANGE" then
        if data.id == 2 then
			self.shopInfo = module.ShopModule.GetManager(2);
        end
    elseif event == "MANOR_REFRESH_ALLTASK_SUCCESS" then
        SetButtonStatus(true, self.dialog.tip2.confirm)
        self.dialog.tip2:SetActive(false);
        showDlgError(nil, "刷新成功");
    elseif event == "SHOP_BUY_SUCCEED" then
        if self.buy then
            self.buy = false;
            SetButtonStatus(true, self.dialog.tip1.confirm)
            self.dialog.tip1:SetActive(false);
            local count = module.ItemModule.GetItemCount(card_id);
            if count > 0 then
                self.view.bottom.refresh.count[UnityEngine.UI.Text]:TextFormat("{0}/{1}", count, 1);
            else
                self.view.bottom.refresh.count[UnityEngine.UI.Text]:TextFormat("<color=#FF0000FF>{0}</color>/{1}", count, 1);
            end
        end
    elseif event == "MANOR_TASK_STARBOX_CHANGE" then
        self:UpdateStarBox();
    elseif event == "MANOR_FINISH_TASK_FAILED" then
        if self.finish then
            self.finish = false;
            self:UpdateButtonState(true);
            showDlgError(nil, "快速完成失败 "..data)
        end
	end
end

return View;