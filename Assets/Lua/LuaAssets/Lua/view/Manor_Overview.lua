local ManorManufactureModule = require "module.ManorManufactureModule"
local ManorModule = require "module.ManorModule"
local ItemHelper = require "utils.ItemHelper"
local ItemModule = require "module.ItemModule"
local HeroModule = require "module.HeroModule"
local QuestModule = require "module.QuestModule"
local Time = require "module.Time"

local dialog_list = {};
dialog_list[0] = {1,2,3,4,5};
dialog_list[1] = {1};--酒馆
dialog_list[2] = {2};--矿洞1
dialog_list[3] = {3};--矿洞2
dialog_list[4] = {4};--矿洞3
dialog_list[5] = {5};--矿洞4
local text_color = {"474747FF","188100FF","007997FF","A814CDFF","A95000FF","B90007FF"}
local week_str = {"星期日","星期一","星期二","星期三","星期四","星期五","星期六"}

local View = {};
function View:Start(data)
    self.root = CS.SGK.UIReference.Setup(self.gameObject);
    self.view = self.root.content;
    self.dialog = self.root.dialog;
    self.init_interval = data and data.interval or 0;
    self.interval = self.init_interval;
    self.content = self.view.ScrollView.Viewport.Content;
    self.tabView = self.dialog.log.tabView.Viewport.Content;
    self.logView = self.dialog.log.logView.Viewport.Content;
    self.init = false;
    
	self:InitData();
    self:InitView();
    if data and data.callback then
        data.callback();
    end
    module.guideModule.PlayByType(21, 0.2);
end

function View:InitData()
    local isMaster,pid = ManorManufactureModule.GetManorStatus();
    self.isMaster = isMaster;
	self.manorInfo = ManorModule.LoadManorInfo();	
    self.manorProductInfo = ManorManufactureModule.Get(pid);

    self.unlock_line = 0;
    self.update_time = 0;
    self.refresh = false;
    self.enter = false;
    self.manorUI = {};
    self.dateUI = {};
    self.logUI = {};
    self.log = {};
    local log = ManorModule.GetLog();
    -- print("日志",sprinttb(log))
end

function View:InitView()
    self.view.top.Image:SetActive(self.isMaster);
    self.view.top.log:SetActive(self.isMaster);
    self:RefreshView(true);
    if #self.dialog_list ~= 1 then
        CS.UGUIClickEventListener.Get(self.view.title.close.gameObject).onClick = function (obj)
            self:DestroySelf();
        end
        CS.UGUIClickEventListener.Get(self.view.top.back.gameObject).onClick = function (obj)
            self.interval = 0;
            self:RefreshView(true);
        end
        CS.UGUIClickEventListener.Get(self.view.top.log.gameObject).onClick = function (obj)
            if not self.dialog.log.gameObject.activeSelf then
                self:ShowLogView();
            end
        end
    end
    CS.UGUIClickEventListener.Get(self.view.BG.gameObject, true).onClick = function (obj)        
        self:DestroySelf();
    end
end

function View:RefreshView(tween)
    if self.interval == 0 and not self.isMaster then
        self.dialog_list = {2, 3, 4, 5};
    else
        self.dialog_list = dialog_list[self.interval];
    end
    if #self.dialog_list == 1 then
		local line = self.manorInfo[self.dialog_list[1]].line;
        local state = self.manorProductInfo:GetLineState(line)
        --print("状态", state)
		if state or line == 0 then
            self:EnterBuilding(self.dialog_list[1], true);
        else
			self:ShowUnlockDialog(line);
		end
    else
        self.view.top.quest:SetActive(false);
        self.view.top.name:SetActive(self.interval == 0);
        self.view.top.back:SetActive(self.interval ~= 0);
        if self.interval == 0 then
            -- self.view.title.name[UnityEngine.UI.Text]:TextFormat("<size=44>基</size>地总览");
            local quest_id = self.manorProductInfo:GetRandomTask();

            self.view.ScrollView[CS.UnityEngine.RectTransform]:SetSizeWithCurrentAnchors(UnityEngine.RectTransform.Axis.Vertical,753);
            if quest_id ~= 0 and self.isMaster then
                local quest = QuestModule.Get(quest_id);
                if quest then
                    self.view.top.quest.condition[UnityEngine.UI.Text]:TextFormat(quest.name);
                    -- local cfg = ItemHelper.Get(quest.reward[1].type, quest.reward[1].id, nil, quest.reward[1].value);
                    -- self.view.top.quest.item[SGK.newItemIcon]:SetInfo(cfg);
                    -- self.view.top.quest.item[SGK.newItemIcon].showDetail = true
                    utils.IconFrameHelper.Create(self.view.top.quest.IconFrame,{type = quest.reward[1].type, id = quest.reward[1].id, count = quest.reward[1].value, showDetail = true})
                    self.view.top.quest.Slider[UnityEngine.UI.Slider].maxValue = quest.condition[1].count;
                    self.view.top.quest.Slider[UnityEngine.UI.Slider].value = quest.records[1];
                    self.view.top.quest.Slider.count[UnityEngine.UI.Text]:TextFormat("{0}/{1}", quest.records[1], quest.condition[1].count)
                    CS.UGUIClickEventListener.Get(self.view.top.quest.reward.gameObject).onClick = function (obj)        
                        if QuestModule.CanSubmit(quest_id) then
                            QuestModule.Finish(quest_id);
                            SetButtonStatus(false, self.view.top.quest.reward, self.view.top.quest.reward[CS.UnityEngine.MeshRenderer].materials[0])
                        end
                    end
                    SetButtonStatus(QuestModule.CanSubmit(quest_id), self.view.top.quest.reward, self.view.top.quest.reward[CS.UnityEngine.MeshRenderer].materials[0])
                    if quest.status == 0 then
                        self.view.top.quest.reward.Text[UnityEngine.UI.Text]:TextFormat("领取");
                    else
                        self.view.top.quest.reward.Text[UnityEngine.UI.Text]:TextFormat("已领取");
                    end
                    self.view.top.quest:SetActive(true);
                    self.view.ScrollView[CS.UnityEngine.RectTransform]:SetSizeWithCurrentAnchors(UnityEngine.RectTransform.Axis.Vertical,620);
                end                
            end
        else
            self.view.ScrollView[CS.UnityEngine.RectTransform]:SetSizeWithCurrentAnchors(UnityEngine.RectTransform.Axis.Vertical,753);
            -- if self.interval == 4 then
            --     self.view.title.name[UnityEngine.UI.Text]:TextFormat("<size=44>工</size>坊");
            -- elseif self.interval == 7 then
            --     self.view.title.name[UnityEngine.UI.Text]:TextFormat("<size=44>矿</size>洞");
            -- end
        end
        for i,v in ipairs(self.dialog_list) do
            local item = nil;
            if self.manorUI[i] == nil then
                local obj = UnityEngine.Object.Instantiate(self.content.building.gameObject, self.content.gameObject.transform);
                obj.name = "manor"..i;
                item = CS.SGK.UIReference.Setup(obj);
                self.manorUI[i] = item;
            else
                item = self.manorUI[i];
            end
            item[CS.UnityEngine.UI.Image]:LoadSprite("manor/"..self.manorInfo[v].picture);
            local state = self.manorProductInfo:GetLineState(self.manorInfo[v].line)
            -- if self.interval == 0 and v == 4 then
            --     item.title.name[CS.UnityEngine.UI.Text]:TextFormat("工坊");
            --     item[CS.UnityEngine.UI.Image].material = nil;
            --     item.lock:SetActive(false);
            -- elseif self.interval == 0 and v == 7 then
            --     item.title.name[CS.UnityEngine.UI.Text]:TextFormat("矿洞");
            --     item[CS.UnityEngine.UI.Image].material = nil;
            --     item.lock:SetActive(false);
            -- else
            -- end
            local productline = self.manorProductInfo:GetLine(self.manorInfo[v].line);
            if productline then
                item.title.name[CS.UnityEngine.UI.Text]:TextFormat("{0} <color=#4EDF06FF>{1}级</color>",self.manorInfo[v].des_name, productline.level or 1);
            else
                item.title.name[CS.UnityEngine.UI.Text]:TextFormat("{0}",self.manorInfo[v].des_name);
            end

            if state then
                -- item[CS.UnityEngine.UI.Image].material = nil;
                item[CS.UnityEngine.UI.Image].color =  UnityEngine.Color.white;
            else
                item[CS.UnityEngine.UI.Image].color =  {r = 0.5, g = 0.5, b = 0.5, a = 1};
                -- item[CS.UnityEngine.UI.Image].material = item[CS.UnityEngine.MeshRenderer].materials[0];
            end

            item.lock:SetActive(not state);
            item.title.Image:SetActive(self.isMaster);
            local unlock_cfg = ManorModule.GetManorOpenConfig(self.manorInfo[v].line);
            if self.isMaster then
                if HeroModule.GetManager():Get(11000).level < unlock_cfg.open_level then
                    item.lock.Text[CS.UnityEngine.UI.Text]:TextFormat("{0}级可解锁",unlock_cfg.open_level);
                else
                    item.lock.Text[CS.UnityEngine.UI.Text]:TextFormat("点击解锁",unlock_cfg.open_level);
                end
            else
                item.lock.Text[CS.UnityEngine.UI.Text]:TextFormat("未解锁");
            end
            
            self:UpdateBuildingState(v,item.doing);
            CS.UGUIClickEventListener.Get(item.gameObject).onClick = function (obj)
                -- if self.interval == 0 then
                --     self.interval = v;
                --     self:RefreshView();
                -- else
                -- end

                if state then
                    self:EnterBuilding(v, true);
                else
                    if not self.isMaster then
                        return;
                    end
                    self:ShowUnlockDialog(self.manorInfo[v].line);
                end
            end
            if tween then
                item.gameObject.transform.localPosition = Vector3(600 + 327, -77 + (i - 1) * -141, 0);
                item.gameObject.transform:DOLocalMove(Vector3(327, -77 + (i - 1) * -141, 0),0.4):SetDelay(0.2 * (i - 1)):SetEase(CS.DG.Tweening.Ease.OutCubic);
            else
                item.gameObject.transform.localPosition = Vector3(327, -77 + (i - 1) * -141, 0);
            end
            item:SetActive(true);
            -- item.gameObject.transform.localScale = Vector3(1, 1, 1.1);
            -- item.gameObject.transform.localScale = Vector3(1, 1, 1);
            self.init = true;
        end
        if #self.manorUI > #self.dialog_list then
            for i=#self.dialog_list + 1,#self.manorUI do
                self.manorUI[i]:SetActive(false);
            end
        end
        self.view:SetActive(true);
    end
end

function View:EnterBuilding(index, teleport)
    local func = function (index)
        if self.init_interval ~= 0 then
            self:DestroySelf();
        end
        if self.enter then
            return;
        end
        self.enter = true;
        if index == 1 then
            DialogStack.Push("manor/Manor_Tavern_View",{index = index});
        -- elseif index >= 2 and index <= 3 then
        --     DialogStack.Push("Manor_WorkStation_Dialog",{index = index});
        elseif index >= 2 and index <= 5 then
            DialogStack.Push("Manor_Mine_Dialog",{index = index});
        end
    end
    if ManorManufactureModule.GetInManorScene() and teleport then
        DispatchEvent("Player_Teleport",function ()
            func(index);
        end)
    else
        func(index);
    end
end

function View:ShowUnlockDialog(line)
    if self.unlock_line ~= 0 then
        return;
    end
    local unlock_cfg = ManorModule.GetManorOpenConfig(line);
    if HeroModule.GetManager():Get(11000).level < unlock_cfg.open_level and (unlock_cfg.consume_id1 == 0 and unlock_cfg.consume_id2 == 0 and unlock_cfg.consume_id2 == 0  ) then
        showDlgError(nil, "未达到解锁等级")
        return;
    end
	local count = 0;
	for i=1,3 do
		if unlock_cfg["consume_id"..i] ~= 0 then
			print("need",unlock_cfg["consume_id"..i])
			-- local item_cfg = ItemHelper.Get(unlock_cfg["consume_type"..i], unlock_cfg["consume_id"..i]);
            -- self.dialog.unlock.cost["cost"..i].item[SGK.newItemIcon]:SetInfo(item_cfg);
            -- self.dialog.unlock.cost["cost"..i].item[SGK.newItemIcon].Count = unlock_cfg["consume_value"..i];
            utils.IconFrameHelper.Create(self.dialog.unlock.cost["cost"..i].IconFrame,{type = unlock_cfg["consume_type"..i], id = unlock_cfg["consume_id"..i], count = unlock_cfg["consume_value"..i], showDetail = true})
            self.dialog.unlock.cost["cost"..i].count[CS.UnityEngine.UI.Text].text = ItemModule.GetItemCount(unlock_cfg["consume_id"..i]).."/"..unlock_cfg["consume_value"..i];
            if ItemModule.GetItemCount(unlock_cfg["consume_id"..i]) < unlock_cfg["consume_value"..i] then
                self.dialog.unlock.cost["cost"..i].count[CS.UnityEngine.UI.Text].color = UnityEngine.Color.red;
            else
                self.dialog.unlock.cost["cost"..i].count[CS.UnityEngine.UI.Text].color = UnityEngine.Color.black;
            end
            self.dialog.unlock.cost["cost"..i]:SetActive(true);
			count = count + 1;
		else
			self.dialog.unlock.cost["cost"..i]:SetActive(false);
		end
	end
	self.dialog.unlock.cost.plus1:SetActive(count > 1);
	self.dialog.unlock.cost.plus2:SetActive(count > 2);

	self.dialog.unlock.title.name[CS.UnityEngine.UI.Text].text = SGK.Localize:getInstance():getValue("biaoti_jiesuo_01", ManorModule.LoadManorInfo(line, 2).des_name);
	if HeroModule.GetManager():Get(11000).level < unlock_cfg.open_level then
		self.dialog.unlock.Text[CS.UnityEngine.UI.Text]:TextFormat("{0} <color=#FF0000FF>主角等级达到{1}级</color>",unlock_cfg.tip_des, unlock_cfg.open_level);
	else
		self.dialog.unlock.Text[CS.UnityEngine.UI.Text]:TextFormat("{0} <color=#FFFFFFFF>主角等级达到{1}级</color>",unlock_cfg.tip_des, unlock_cfg.open_level);
	end
	
	CS.UGUIClickEventListener.Get(self.dialog.unlock.confirm.gameObject).onClick = function (obj)
		if HeroModule.GetManager():Get(11000).level < unlock_cfg.open_level then
			showDlgError(nil, "主角等级不足");
			return;
		end
		for i=1,3 do
			if unlock_cfg["consume_id"..i] ~= 0 then
				if ItemModule.GetItemCount(unlock_cfg["consume_id"..i]) < unlock_cfg["consume_value"..i] then
					--print(unlock_cfg["consume_id"..i],  unlock_cfg["consume_value"..i])
					showDlgError(nil, "材料不足");
					return;
				end
			end
        end
		self.unlock_line = line;
        self.manorProductInfo:UnlockLine(line);
        self.dialog.unlock:SetActive(false);
    end
    CS.UGUIClickEventListener.Get(self.dialog.unlock.title.close.gameObject).onClick = function (obj)
        self.dialog.unlock:SetActive(false);
        if not self.view.gameObject.activeSelf then
            self:DestroySelf();
        end
    end
    CS.UGUIClickEventListener.Get(self.dialog.unlock.cancel.gameObject).onClick = function (obj)
        self.dialog.unlock:SetActive(false);
        if not self.view.gameObject.activeSelf then
            self:DestroySelf();
        end
    end
	self.dialog.unlock:SetActive(true);
end

function View:CheckLineState(productLine)
    if productLine == nil then
        ERROR_LOG("生产线为空");
        return true, false, false;
    end
    local empty = true;
    for i,v in ipairs(productLine.worker) do
        if v ~= 0 then
            empty = false;
            break;
        end
    end
    local doing = productLine.next_gather_gid ~= 0;
    local canGather = false;
    for k,j in pairs(productLine.orders) do
        if j.gather_count > 0 then
            canGather = true;
        end
    end
    return doing, canGather, empty;
end

function View:CanSteal(productLine)
    if self.isMaster then
        return false;
    end
    local line_cfg = ManorModule.GetManorLineConfig(productLine.idx).cfg;
    if productLine and line_cfg then
        if line_cfg.steal_item ~= 0 and module.ItemModule.GetItemCount(line_cfg.steal_item) <= 0 then
            return false
        end
        if #productLine.thieves > 0 and Time.now() < productLine.thieves[1].end_time then
            return false;
        end
        for k,v in pairs(productLine.orders) do
            for i=1,6 do
                if v["count"..i] ~= 0 then
                    if v["count"..i]/(v["count"..i] + v["stolen_value"..i]) > line_cfg.steal_guarantee/10000 then
                        if math.floor(v["count"..i] * line_cfg.every_steal / 10000) >= 1 then
                            return true;
                        end
                    end
                end
            end
            for i,j in ipairs(v.product_pool) do
                if j[3]/(j[3] + j[4]) > line_cfg.steal_guarantee/10000 then
                    if math.floor(j[3] * line_cfg.every_steal / 10000) >= 1 then
                        return true;
                    end
                end
            end
        end
    end
    return false
end

function View:UpdateBuildingState(index,textUI)
    textUI:SetActive(true);
    textUI.red:SetActive(false);
    local TextUI = textUI.Text;
    if self.interval == 0 then
        if index == 1 then
            local task = self.manorProductInfo:GetTask();
			-- print("任务信息",sprinttb(task))
            local doing,complete = 0,0;
            if task.list then
                for k,v in pairs(task.list) do
                    if v.state ~= 1 and v.begin_time ~= 0 then
                        doing = doing + 1;
                        if v.end_time <= Time.now() then
                            complete = complete + 1;
                        end
                    end
                end
                if doing > 0 then
                    TextUI[UnityEngine.UI.Text]:TextFormat("任务进行中({0}/{1})", complete, doing);
                else
                    TextUI[UnityEngine.UI.Text]:TextFormat("今日已完成({0}/{1})", task.compelet_count, 10);
                end
            else
                TextUI[UnityEngine.UI.Text]:TextFormat("今日已完成({0}/{1})", 0, 10);
            end
            textUI.red:SetActive(self.isMaster and module.RedDotModule.GetStatus(module.RedDotModule.Type.Manor.Tavern));
        -- elseif index == 2 then--商铺描述
        --     local state = self.manorProductInfo:GetLineState(self.manorInfo[index].line);
        --     if not state then
        --         TextUI[UnityEngine.UI.Text]:TextFormat("未解锁");
        --         return;
        --     end
        --     local productline = self.manorProductInfo:GetLine(self.manorInfo[index].line);
        --     local doing, canGather, empty = self:CheckLineState(productline);
        --     if doing then
        --         -- TextUI[UnityEngine.UI.Text]:TextFormat("商品出售中({0}/{1})", sold_count, productline.order_limit);
        --         TextUI[UnityEngine.UI.Text]:TextFormat("热销中");
        --     elseif empty then
        --         TextUI[UnityEngine.UI.Text]:TextFormat("销售人员紧缺");
        --     else
        --         TextUI[UnityEngine.UI.Text]:TextFormat("货架空空如也");
        --     end
        -- elseif index == 2 then--研究院描述
        --     local state = self.manorProductInfo:GetLineState(self.manorInfo[index].line);
        --     if not state then
        --         TextUI[UnityEngine.UI.Text]:TextFormat("未解锁");
        --         return;
        --     end
        --     local productline = self.manorProductInfo:GetLine(self.manorInfo[index].line);
        --     local productlist = self.manorProductInfo:GetProductList(self.manorInfo[index].line);
        --     local doing, canGather, empty = self:CheckLineState(productline);
        --     local canSteal = self:CanSteal(productline);
        --     if self.isMaster then
        --         textUI.red:SetActive(canGather);
        --     else
        --         textUI.red:SetActive(canSteal);
        --     end
        --     if canSteal then
        --         TextUI[UnityEngine.UI.Text]:TextFormat("可偷取");
        --     elseif canGather then
        --         TextUI[UnityEngine.UI.Text]:TextFormat("研发完毕");
        --     elseif doing then
        --         TextUI[UnityEngine.UI.Text]:TextFormat("研究中");
        --     elseif empty then
        --         TextUI[UnityEngine.UI.Text]:TextFormat("研究人员稀缺");
        --     else
        --         TextUI[UnityEngine.UI.Text]:TextFormat("灵感已枯竭");
        --     end
        -- elseif index == 3 then--工坊描述
        --     local unlock_count = 0;
        --     local _canGather, _empty, _doing, _canSteal = false, false, false, false;
        --     for i,v in ipairs(dialog_list[index]) do
        --         local state = self.manorProductInfo:GetLineState(self.manorInfo[v].line);
        --         if state then
        --             unlock_count = unlock_count + 1;
        --             local productline = self.manorProductInfo:GetLine(self.manorInfo[index].line);
        --             local doing, canGather, empty = self:CheckLineState(productline);
        --             local canSteal = self:CanSteal(productline);
        --             _canGather = _canGather or canGather;
        --             _empty = _empty or empty;
        --             _doing = _doing or doing;
        --             _canSteal = _canSteal or canSteal;
        --         end
        --     end
        --     if self.isMaster then
        --         textUI.red:SetActive(_canGather);
        --     else
        --         textUI.red:SetActive(_canSteal);
        --     end
        --     if _canSteal then
        --         TextUI[UnityEngine.UI.Text]:TextFormat("可偷取");
        --     elseif _canGather then
        --         TextUI[UnityEngine.UI.Text]:TextFormat("可收取");
        --     elseif _empty then
        --         TextUI[UnityEngine.UI.Text]:TextFormat("匠人空缺");
        --     elseif not _doing then
        --         TextUI[UnityEngine.UI.Text]:TextFormat("炉火已熄");
        --     else
        --         TextUI[UnityEngine.UI.Text]:TextFormat("制作中");
        --     end
            -- TextUI[UnityEngine.UI.Text]:TextFormat("已解锁({0}/{1})", unlock_count, #dialog_list[index]);
        elseif index >= 2 and index <= 5 then--矿洞描述
            local _canGather, _empty, _doing, _canSteal, _monster = false, false, false, false, false;
            for i,v in ipairs(dialog_list[index]) do
                local state = self.manorProductInfo:GetLineState(self.manorInfo[v].line);
                if state then
                    local productline = self.manorProductInfo:GetLine(self.manorInfo[v].line);
                    print("生产线", productline.idx, sprinttb(productline))
                    -- local doing, canGather, empty = self:CheckLineState(productline);
                    -- local canSteal = self:CanSteal(productline);
                    local canGather, empty, doing, canSteal, monster = ManorManufactureModule.CheckProductlineStatus(self.manorInfo[v].line)
                    _canGather = _canGather or canGather;
                    _empty = _empty or empty;
                    _doing = _doing or doing;
                    _canSteal = _canSteal or canSteal;
                    _monster = _monster or monster;
                end
            end
            if self.isMaster then
                textUI.red:SetActive(_canGather or _monster);
            else
                textUI.red:SetActive(_canSteal);
            end
            if _canSteal then
                TextUI[UnityEngine.UI.Text]:TextFormat("可偷取");
            elseif _monster then
                TextUI[UnityEngine.UI.Text]:TextFormat("有人捣乱");
            elseif _canGather then
                TextUI[UnityEngine.UI.Text]:TextFormat("开采完毕");
            elseif _empty then
                TextUI[UnityEngine.UI.Text]:TextFormat("苦力招募中");
            elseif not _doing then
                TextUI[UnityEngine.UI.Text]:TextFormat("休矿期");
            else
                TextUI[UnityEngine.UI.Text]:TextFormat("开采中");
            end
        end
    else--二级菜单描述（现已废弃）
        local state = self.manorProductInfo:GetLineState(self.manorInfo[index].line);
        if not state then
            TextUI[UnityEngine.UI.Text]:TextFormat("未解锁");
            return;
        end
        local productline = self.manorProductInfo:GetLine(self.manorInfo[index].line);
        local productlist = self.manorProductInfo:GetProductList(self.manorInfo[index].line);
        if index == 4 or index == 5 or index == 6 then
            local doing, canGather, empty = self:CheckLineState(productline);
            -- redActive = canGather;
            textUI.red:SetActive(canGather);
            if canGather then
                TextUI[UnityEngine.UI.Text]:TextFormat("制作完毕");
            elseif doing then
                TextUI[UnityEngine.UI.Text]:TextFormat("制作中");
            elseif empty then
                TextUI[UnityEngine.UI.Text]:TextFormat("匠人空缺");
            else
                TextUI[UnityEngine.UI.Text]:TextFormat("炉火已熄");
            end
        elseif index == 7 or index == 8 or index == 9 or index == 10 then
            local doing, canGather, empty = self:CheckLineState(productline);
            -- redActive = (canGather and not doing);
            textUI.red:SetActive(canGather and not doing);
            if canGather and not doing then
                TextUI[UnityEngine.UI.Text]:TextFormat("开采完毕");
            elseif doing then
                TextUI[UnityEngine.UI.Text]:TextFormat("开采中");
            elseif empty then
                TextUI[UnityEngine.UI.Text]:TextFormat("苦力招募中");
            else
                TextUI[UnityEngine.UI.Text]:TextFormat("休矿期");
            end
        end
    end
end

function View:DestroySelf()
    -- if ManorManufactureModule.GetInManorScene() then
    -- end
    DialogStack.Pop();
	--UnityEngine.Object.Destroy(self.gameObject)
end

function View:ShowLogView()
    local log = ManorModule.GetLog();
    self.log = {};
    local _log = {};
    for k,v in pairs(log) do
        table.insert(_log, v);
    end
    table.sort(_log, function ( a,b )
        if a.day ~= b.day then
            return a.day < b.day
        end
        return a.log[1].id < b.log[1].id;
    end )
    for i,v in ipairs(_log) do
        table.insert(self.log, {dateUI = true, str = os.date("%Y年%m月%d日",math.floor(v.log[1].time)).." "..week_str[v.week + 1]});
        table.sort(v.log, function ( a,b )
            if a.time ~= b.time then
                return a.time < b.time
            end
           return a.id < b.id
        end)
        
        for _,k in ipairs(v.log) do
            if k.show then
                table.insert(self.log, k);
            else
                print("屏蔽", k.id);
            end
        end
    end
    -- for i,v in ipairs(self.log) do
    --     local item = nil;
    --     if self.dateUI[i] == nil then
    --         local obj = UnityEngine.Object.Instantiate(self.tabView.date.gameObject, self.tabView.gameObject.transform);
    --         obj.name = "date"..i;
    --         item = CS.SGK.UIReference.Setup(obj);
    --         self.dateUI[i] = item;
    --         item:SetActive(true);
    --     else
    --         item = self.dateUI[i];
    --     end
    --     item.day[UnityEngine.UI.Text]:TextFormat(v.date);
    --     item.week[UnityEngine.UI.Text]:TextFormat(week_str[v.week + 1]);
    --     CS.UGUIClickEventListener.Get(item.gameObject).onClick = function ( obj )
    --         if item[UnityEngine.UI.Toggle].isOn then
    --             self.logView[UnityEngine.RectTransform].anchoredPosition = UnityEngine.Vector2(0,0);
    --             self:UpdateLogView(i);
    --         end
    --     end
    -- end
    -- self.dateUI[1][UnityEngine.UI.Toggle].isOn = true;
    CS.UGUIClickEventListener.Get(self.dialog.log.BG.gameObject, true).onClick = function ( obj )
        self.dialog.log:SetActive(false);
        for i,v in ipairs(self.dateUI) do
            UnityEngine.GameObject.Destroy(v.gameObject);
        end
        self.dateUI = {};
        for i,v in ipairs(self.logUI) do
            UnityEngine.GameObject.Destroy(v.gameObject);
        end
        self.logUI = {};
    end

    CS.UGUIClickEventListener.Get(self.dialog.log.title.close.gameObject).onClick = function ( obj )
        self.dialog.log:SetActive(false);
        for i,v in ipairs(self.dateUI) do
            UnityEngine.GameObject.Destroy(v.gameObject);
        end
        self.dateUI = {};
        for i,v in ipairs(self.logUI) do
            UnityEngine.GameObject.Destroy(v.gameObject);
        end
        self.logUI = {};
    end
    self:UpdateLogView();
    self.dialog.log:SetActive(true);
end

function View:UpdateLogView()
    local loginfo = self.log;
    for i,v in ipairs(loginfo) do
        local item = nil;
        if self.logUI[i] == nil then
            local obj = UnityEngine.Object.Instantiate(self.logView.log.gameObject, self.logView.gameObject.transform);
            obj.name = "date"..i;
            item = CS.SGK.UIReference.Setup(obj);
            self.logUI[i] = item;
        else
            item = self.logUI[i];
        end
        if v.dateUI == nil then
            item.Text[UnityEngine.UI.Text]:TextFormat(v.str);
            item.time[UnityEngine.UI.Text]:TextFormat(v.hour);
            item.date:SetActive(false);
        else
            item.Text[UnityEngine.UI.Text].text = "";
            item.time[UnityEngine.UI.Text].text = "";
            item.date.Text[UnityEngine.UI.Text]:TextFormat(v.str);
            item.date:SetActive(true);
        end

        if v.reward then
            item.itemview:SetActive(true);
            if item.itemview.gameObject.transform.childCount - 1 > #v.reward then
                for idx=#v.reward + 1,item.itemview.gameObject.transform.childCount - 1 do
                    local obj = item.itemview.gameObject.transform:Find("item"..idx);
                    if obj then
                        UnityEngine.GameObject.Destroy(obj.gameObject);
                    end
                end
            end
            for j,k in ipairs(v.reward) do
                local obj = item.itemview.gameObject.transform:Find("item"..j);
                local reward_item = nil;
                if obj then
                    reward_item = CS.SGK.UIReference.Setup(obj);
                else
                    local _obj = UnityEngine.Object.Instantiate(item.itemview.item.gameObject, item.itemview.gameObject.transform);
                    _obj.name = "item"..j;
                    reward_item = CS.SGK.UIReference.Setup(_obj);
                    _obj:SetActive(true);
                end
                local cfg = ItemHelper.Get(k[1], k[2]);
                assert(cfg, k[2].."物品不存在");
                if cfg then
                    -- reward_item.icon[UnityEngine.UI.Image]:LoadSprite("icon/"..cfg.icon.."_small");
                    utils.IconFrameHelper.Create(reward_item.IconFrame,{type = cfg.type, id = cfg.id, count = 0})

                    reward_item.Text[UnityEngine.UI.Text]:TextFormat("<color=#"..text_color[cfg.quality + 1]..">{0}{1}个</color>",cfg.name, k[3])
                    --reward_item.gameObject:SetActive(true);
                end
            end
        elseif item.itemview.gameObject.transform.childCount > 1 then
            item.itemview:SetActive(false);
            for idx = 1,item.itemview.gameObject.transform.childCount - 1 do
                local obj = item.itemview.gameObject.transform:Find("item"..idx);
                if obj then
                    UnityEngine.GameObject.Destroy(obj.gameObject);
                end
            end
        end
        item:SetActive(true);
    end
    if #self.logUI > #loginfo then
        for i=#loginfo + 1,#self.logUI do
            self.logUI[i]:SetActive(false);
        end
    end
end

function View:deActive()
    if self.unlock_line ~= 0 then
        return true;
    end
	if self.view.gameObject.activeSelf then
		for i=#self.dialog,1,-1 do
            if self.dialog[i].active then
                local name = self.dialog[i].name;    
                self.dialog[i]:SetActive(false);
                return false;
            end
        end
	end
	return true;
end

function View:Update()
    if self.init and Time.now() - self.update_time >= 5 then
        local _t = os.date("*t", Time.now());
        self.update_time = Time.now();
        self.manorProductInfo:GetProductLineFromServer();  
        if self.interval == 0 and self.isMaster then
            self.manorProductInfo:QueryTask();
        end
    end
end

function View:OnDestroy()
	self.savedValues.dialog_interval = self.interval;
end

function View:deActive()
	utils.SGKTools.PlayDestroyAnim(self.gameObject)
	return true;
end

function View:listEvent()
	return {
        "MANOR_LOG_CHANGE",
		"MANOR_MANUFACTURE_PRODUCT_LINE_CHANGE",
		"MANOR_TASK_INFO_CHANGE",
        "MANOR_UNLOCK_LINE_SUCCEED",
        "LOCAL_GUIDE_CHANE",
        "MANOR_RANDOM_TASK_CHANGE",
        "QUEST_INFO_CHANGE"
	}
end

function View:onEvent(event, ...)
	print("onEvent", event, ...);
	local data = ...;
	if event == "MANOR_UNLOCK_LINE_SUCCEED" then
		if self.unlock_line == data.line then
			if self.manorProductInfo:GetLineState(self.unlock_line) then
				-- local index = ManorModule.LoadManorInfo(self.unlock_line, 2).location;
                -- self:EnterBuilding(index);
                showDlgError(nil, "解锁成功");
                self.unlock_line = 0;
                if not self.view.gameObject.activeSelf then
                    self:DestroySelf();
                else
                    self:RefreshView();
                end
			end
        end
    elseif event == "MANOR_MANUFACTURE_PRODUCT_LINE_CHANGE" then
        if self.interval == 0 then
            local start = self.isMaster and 2 or 1;
            for i=start,#self.dialog_list do
                self:UpdateBuildingState(self.dialog_list[i], self.manorUI[i].doing);
            end
        else
            for i,v in ipairs(dialog_list[self.interval]) do
                self:UpdateBuildingState(v, self.manorUI[i].doing);
            end
        end
    elseif event == "MANOR_TASK_INFO_CHANGE" then
        if self.interval == 0 and self.isMaster then
            self:UpdateBuildingState(1, self.manorUI[1].doing);
        end
    elseif event == "MANOR_LOG_CHANGE" then
    elseif event == "LOCAL_GUIDE_CHANE" then
        module.guideModule.PlayByType(21, 0.2);
    elseif event == "MANOR_RANDOM_TASK_CHANGE" or "QUEST_INFO_CHANGE" then
        self:RefreshView();
	end
end

return View;