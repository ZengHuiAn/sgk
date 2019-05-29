local ManorManufactureModule = require "module.ManorManufactureModule"
local ItemHelper = require "utils.ItemHelper"
local HeroModule = require "module.HeroModule"
local ManorModule = require "module.ManorModule"
local Time = require "module.Time"
local ItemModule = require "module.ItemModule"
local TipConfig = require "config.TipConfig"

local View = {};
local direction = {};
direction[1] = {6,0};--研究院
direction[2] = {2,5,1,2};--工坊
local MAX_TALK = 1;
local interval = {}
local character_info1,character_info2 = {},{};
character_info1[0] = {name = "fangke", max = 4};
character_info1[1] = {name = "cuiqu", max = 2};
character_info1[2] = {name = "jinglian", max = 3};
character_info1[3] = {name = "duanzao", max = 3};
character_info1[10] = {name = "wfangke", max = 4};

character_info2[0] = {name = "fangke", max = 4};
character_info2[1] = {name = "chuida", max = 3};
character_info2[2] = {name = "shaolu", max = 3};
character_info2[3] = {name = "cuihuo", max = 3};
character_info2[4] = {name = "paoguang", max = 2};
character_info2[10] = {name = "wfangke", max = 3};

local qipao_anime1 = {};
qipao_anime1[1] = "icon_yanjiuyuan_pingzi/icon_yanjiuyuan_pingzi";
qipao_anime1[2] = "icon_yanjiuyuan_jinglian/icon_yanjiuyuan_jinglian";
qipao_anime1[3] = "icon_yanjiuyuan_duanzao/icon_yanjiuyuan_duanzao";
qipao_anime1[10] = "icon_jidi_heshui/icon_jidi_heshui";

local qipao_anime2 = {};
qipao_anime2[1] = "icon_tiejiang_fuzi/icon_tiejiang_fuzi";
qipao_anime2[2] = "icon_tiejiang_huolu/icon_tiejiang_huolu";
qipao_anime2[3] = "icon_tiejiang_cuihuo/icon_tiejiang_cuihuo";
qipao_anime2[4] = "icon_tiejiang_shalun/icon_tiejiang_shalun";
qipao_anime2[10] = "icon_jidi_heshui/icon_jidi_heshui";

local text_color = {"#43FF00FF", "#0041FFFF"}

function View:Start(data)
    self.view = CS.SGK.UIReference.Setup(self.gameObject);
    self.dialog = self.view.dialog;
    self.index = data and data.index or self.savedValues.Manorindex or 2;
	self:InitData();
	self:InitView();
    if data and data.callback then
        data.callback();
    end
end

function View:InitData()
    local isMaster,pid = ManorManufactureModule.GetManorStatus();
    self.isMaster = isMaster;
    self.manorProductInfo = ManorManufactureModule.Get(pid);
    self.manorProductInfo:GetProductLineFromServer();
	self.manorInfo = ManorModule.LoadManorInfo();
	self.chatInfo = ManorModule.GetManorChat();
    self.manager = HeroModule.GetManager(pid);
    self.visitorConfig = ManorModule.GetManorOutsideConfig();
    if self.isMaster then
        self.manorProductInfo:CheckWorkerProperty();
    end
    self.update_time = Time.now() + math.random(3,6);
    self.update_time2 = Time.now();
    self.worker_move_time = Time.now() + math.random(2,5);
    self.drink_time = Time.now() + math.random(15,30);
    self.monster_speak = Time.now() + math.random(4,6)

    self.productLine = {};
    self.frame_list = {};
    self.outside_man = {};
    self.worker = {};
    self.monster = {};
    self.visitor = {};
    self.talk_num = 0;
    self.character = {};
    self.controller = {};
    self.speak_end = {};
    self.worker_pause = {};
    self.speedup_order = 0;
    self.free = true;
    self.gathering = false;
    self.pos = 0;
    self.work_num = 0;
    self.special_index = 2; --特殊处理研究院
    self.dialog_list = {};
    self.manor_event_cfg = nil;
    local dialog_list = ManorModule.GetDialogList(self.index);
    if #dialog_list == 1 then
        self.dialog_list = dialog_list;
        self.pos = 1; 
    else
        for i,v in ipairs(dialog_list) do
            if self.manorProductInfo:GetLineState(self.manorInfo[v].line) then
                table.insert(self.dialog_list, v);
                if v == self.index then
                    self.pos = i;
                end
            end
        end
    end

	if self.pos == 0 then
		self.index = self.dialog_list[1];
		self.pos = 1;
    end
    
    self.line = self.manorInfo[self.index].line;
    self.productLine = self.manorProductInfo:GetLine(self.line);
end

function View:InitView()    
    self:createFrame(self.index,true);
    CS.UGUIClickEventListener.Get(self.view.BG.gameObject, true).onClick = function (obj)        
        DialogStack.Pop();
    end
    -- self:RefreshFrame();
end

function View:createFrame(index,init)
    local view = nil;
    local info = self.manorInfo[index];
    self.work_num = info.work_num;
    if self.frame_list[index] == nil then
        if init then
            view = self.view.view;
        else
            local obj = UnityEngine.Object.Instantiate(self.view.view.gameObject);
			obj.transform:SetParent(self.view.content.gameObject.transform,false);
			obj:SetActive(true);
			obj.name = "WorkStation"..(index-6);
            view = CS.SGK.UIReference.Setup(obj);
            local _, color = UnityEngine.ColorUtility.TryParseHtmlString(text_color[1]);
            for i=0,self.work_num  do
                view.top.content["character"..i]:SetActive(false);
                view.top.content["character"..i].Label.dialogue[UnityEngine.CanvasGroup].alpha = 0;
                view.top.content["character"..i].Label.qipao[UnityEngine.CanvasGroup].alpha = 0;
                view.top.content["character"..i].Label.name[UnityEngine.UI.Text].color = color;
            end
            for i=1,4 do
                view.bottom.workers["worker"..i]:SetActive(false);
            end
            view.top.content.monster:SetActive(false);
        end
        view.title.name[CS.UnityEngine.UI.Text].text = SGK.Localize:getInstance():getValue(info.title);
        view.top.info.Button:SetActive(self.isMaster);
        view.bottom.nowork.make:SetActive(self.isMaster);
        view.bottom.working.board.Text1:SetActive(self.isMaster);
        view.bottom.working.make:SetActive(self.isMaster);
        view.bottom.working.complete:SetActive(self.isMaster);
        view.bottom.working.steal:SetActive(not self.isMaster);
        if self.isMaster then
            view.bottom.nowork.board.Text.gameObject.transform.localPosition = Vector3(-200, 0, 0);
            view.bottom.working.board.IconFrame.gameObject.transform.localPosition = Vector3(-92, 12, 0);
        else
            self.manorProductInfo:CheckWorkerProperty(true, info.line);
            view.bottom.nowork.board.Text.gameObject.transform.localPosition = Vector3(0, 0, 0);
            view.bottom.working.board.IconFrame.gameObject.transform.localPosition = Vector3(-92, 0, 0);
        end
        self.speak_end[index] = {};
        self.worker_pause[index] = {};
        self.outside_man[index] = {};
        self.character[index] = {};
        self.worker[index] = {};
        self.visitor[index] = {};
        if index == self.special_index then
            self.controller[index] = view.top.content2[SGK.DialogPlayerMoveController];
        else
            self.controller[index] = view.top.content[SGK.DialogPlayerMoveController];
        end

        CS.UGUIClickEventListener.Get(view.bottom.working.board.IconFrame.gameObject).onClick = function (obj)
            if not self.isMaster then
                return;
            end
            if self.productLine then
                local worker_num = 0;
                for i=1,5 do
                    if self.productLine.worker[i] ~= 0 then
                        worker_num = worker_num + 1;
                    end
                end
                if worker_num > 0 then
                    DialogStack.Push("Manor_WorkStation_Production",{line = info.line});
                else
                    showDlgError(nil, "请先派遣工作人员");
                end
            else
                ERROR_LOG("未获取到生产线数据");
            end
        end

        CS.UGUIClickEventListener.Get(view.bottom.working.make.gameObject).onClick = function (obj)
            if not self.isMaster then
                return;
            end
            self:UseWorkerSpeedUp();
        end
        
        CS.UGUIClickEventListener.Get(view.bottom.working.steal.gameObject).onClick = function (obj)
            self.manorProductInfo:Steal(self.line)
        end

        CS.UGUIClickEventListener.Get(view.bottom.nowork.make.gameObject).onClick = function (obj)
            if not self.isMaster then
                return;
            end
            if self.productLine then
                local worker_num = 0;
                for i=1,5 do
                    if self.productLine.worker[i] ~= 0 then
                        worker_num = worker_num + 1;
                    end
                end
                if worker_num > 0 then
                    DialogStack.Push("Manor_WorkStation_Production",{line = info.line});
                else
                    showDlgError(nil, "请先派遣工作人员");
                end
            else
                ERROR_LOG("未获取到生产线数据");
            end
        end

        CS.UGUIClickEventListener.Get(view.bottom.working.complete.gather.gameObject).onClick = function (obj)
            if not self.isMaster then
                return;
            end
            local canGather = false;
            for k,v in pairs(self.productLine.orders) do
                if v.gather_count > 0 then
                    canGather = true;
                    break;
                end
            end
            if canGather then
                SetButtonStatus(false, self.frame_list[self.index].bottom.working.complete);
                -- self.frame_list[self.index].bottom.working.complete.gather.bg[CS.UnityEngine.UI.Image].material = self.frame_list[self.index].bottom.working.complete[CS.UnityEngine.MeshRenderer].materials[1];
                self.frame_list[self.index].bottom.working.complete.gather[CS.UGUISelectorGroup]:setGray();
                self.manorProductInfo:Gather(info.line);
            else
                showDlgError(nil,"工坊空闲中");
            end   
        end
        
        CS.UGUIClickEventListener.Get(view.bottom.working.complete.fast.gameObject).onClick = function (obj)
            if not self.isMaster then
                return;
            end
            self:ShowCompleteDialog();
        end
        
        view.top.content:SetActive(index ~= self.special_index);
        view.top.content2:SetActive(index == self.special_index);
    
        CS.UGUIClickEventListener.Get(view.title.close.gameObject).onClick = function (obj)
            DialogStack.Pop();
        end
        
        CS.UGUIClickEventListener.Get(view.top.help.gameObject).onClick = function ( object )
            if self.isMaster then
                utils.SGKTools.ShowDlgHelp(TipConfig.GetAssistDescConfig(55002 + self.line).info, nil, self.dialog)
            else
                utils.SGKTools.ShowDlgHelp(TipConfig.GetAssistDescConfig(55008).info, nil, self.dialog)
            end
        end

        if index ~= self.special_index then
            -- view.top.content.BG[CS.UnityEngine.UI.Image]:LoadSprite("manor/manufacture/gf_"..(info.line - 1).."/tjp_0"..(info.line - 1).."_h");

            -- local animation_bg = view.top.content.bg[CS.Spine.Unity.SkeletonGraphic];
            -- SGK.ResourcesManager.LoadAsync(animation_bg, "manor/manufacture/gf_"..(info.line - 1).."/tjp_0"..(info.line - 1).."_bg_SkeletonData", function(o)
            --     animation_bg.skeletonDataAsset = o;
            --     animation_bg:Initialize(true)
            -- end)

            -- local animation_tielu = view.top.content.tielu[CS.Spine.Unity.SkeletonGraphic];
            -- SGK.ResourcesManager.LoadAsync(animation_tielu, "manor/manufacture/gf_"..(info.line - 1).."/tjp_0"..(info.line - 1).."_tielu_SkeletonData", function(o)
            --     animation_tielu.skeletonDataAsset = o;
            --     animation_tielu:Initialize(true)
            -- end)

            -- local animation_lengque = view.top.content.lengque[CS.Spine.Unity.SkeletonGraphic];
            -- SGK.ResourcesManager.LoadAsync(animation_lengque, "manor/manufacture/gf_"..(info.line - 1).."/tjp_0"..(info.line - 1).."_lengque_SkeletonData", function(o)
            --     animation_lengque.skeletonDataAsset = o;
            --     animation_lengque:Initialize(true)
            -- end)

            -- local animation_tiezhen = view.top.content.tiezhen[CS.Spine.Unity.SkeletonGraphic];
            -- SGK.ResourcesManager.LoadAsync(animation_tiezhen, "manor/manufacture/gf_"..(info.line - 1).."/tjp_0"..(info.line - 1).."_tiezan_SkeletonData", function(o)
            --     animation_tiezhen.skeletonDataAsset = o;
            --     animation_tiezhen:Initialize(true)
            -- end)

            -- local animation_jiqi = view.top.content.jiqi[CS.Spine.Unity.SkeletonGraphic];
            -- local res_str, mat_str = "", "";
            -- if info.line == 3 then
            --     res_str = "manor/manufacture/gf_"..(info.line - 1).."/tjp_0"..(info.line - 1).."_damo_SkeletonData";
            -- else
            --     res_str = "manor/manufacture/gf_"..(info.line - 1).."/tjp_0"..(info.line - 1).."_jiqi_SkeletonData";
            -- end
            -- SGK.ResourcesManager.LoadAsync(animation_jiqi, res_str, function(o)
            --     animation_jiqi.skeletonDataAsset = o;
            --     animation_jiqi:Initialize(true)
            -- end)

            self:AddCharacter(0, view.top.content.character0, character_info2[0].name, character_info2[0].max);
            self:AddCharacter(10, view.top.content.visitor, character_info2[10].name, character_info2[10].max);

            CS.UGUIClickEventListener.Get(view.top.content.monster.gameObject, true).onClick = function ( object )
                local data = {};
                data.msg = "准备开始战斗了吗？";
                data.confirm = function ()
                    if utils.SGKTools.GetTeamState() then
                        showDlgError(nil, "请先解散队伍");
                    else
                        self.manorProductInfo:StartTroubleManFight(self.line)
                    end
                end;
                data.title = "战斗确认";
                DlgMsg(data)
            end
        else
            self:AddCharacter(0, view.top.content2.character0, character_info1[0].name, character_info1[0].max);
            self:AddCharacter(10, view.top.content2.visitor, character_info1[10].name, character_info1[10].max);

            CS.UGUIClickEventListener.Get(view.top.content2.monster.gameObject, true).onClick = function ( object )
                local data = {};
                data.msg = "准备开始战斗了吗？";
                data.confirm = function ()
                    if utils.SGKTools.GetTeamState() then
                        showDlgError(nil, "请先解散队伍");
                    else
                        self.manorProductInfo:StartTroubleManFight(self.line)
                    end
                end;
                data.title = "战斗确认";
                DlgMsg(data)
            end
        end
    
        for i=1,self.work_num do
            local worker_item = view.bottom.workers["worker"..i];
            local name = info["job_name"..i];
            self.worker_pause[index][i] = false;
            if name and name ~= "" then
                worker_item.info.name[CS.UnityEngine.UI.Text]:TextFormat(name);
                local unlock_cfg = ManorModule.GetManorOpenConfig(info.line, i);
                worker_item.lock:SetActive(module.playerModule.Get().level < unlock_cfg.open_level and self.isMaster);
                worker_item.lock.Text[UnityEngine.UI.Text]:TextFormat("{0}级解锁", unlock_cfg.open_level);
                worker_item:SetActive(true);
                local worker_view = nil;
                if index == self.special_index then
                    worker_view = view.top.content2["character"..i];
                    self:AddWorker(i, worker_view, character_info1[i].name, character_info1[i].max);
                    self:UpdateQipao(worker_view.Label, qipao_anime1[i]);
                else
                    worker_view = view.top.content["character"..i];
                    self:AddWorker(i, worker_view, character_info2[i].name, character_info2[i].max);
                    self:UpdateQipao(worker_view.Label, qipao_anime2[i]);
                end
                worker_view.Label.name:TextFormat(name);

                CS.UGUIClickEventListener.Get(worker_view.gameObject, true).onClick = function (obj)
                    -- if not self.isMaster then
                    --     return;
                    -- end
                    local worker_label = worker_view.Label;
                    local hero = self:GetHero(self.productLine.worker[i], i);
                    local worker = self.manorProductInfo:GetWorkerInfo(self.productLine.worker[i],1);
                    local talk_cfg = ManorModule.GetManorChat(hero.id, self.line, i);
                    local text = "";
                    
                    if worker.power == 0 then
                        text = talk_cfg.en_empty_click_words[math.random(1,#talk_cfg.en_empty_click_words)]
                    elseif self.free then
                        text = talk_cfg.blank_click_words[math.random(1,#talk_cfg.blank_click_words)]
                    else
                        text = talk_cfg.working_click_words[math.random(1,#talk_cfg.working_click_words)]
                    end
                    if text == "" then
                        print("对话为空")
                        return;
                    end
                    text = "<color=#0041FFFF>"..text.."</color>";
                    local _index = self.index;
                    self.worker_pause[_index][i] = true;
                    local _, color = UnityEngine.ColorUtility.TryParseHtmlString(text_color[2]);
                    worker_label.name[UnityEngine.UI.Text].color = color;

                    if worker_label.dialogue[UnityEngine.CanvasGroup].alpha > 0 then
                        self.speak_end[_index][i] = function ()
                            self:ShowNpcDesc(worker_label, text, math.random(1,3), function ()
                                local _, color = UnityEngine.ColorUtility.TryParseHtmlString(text_color[1]);
                                worker_label.name[UnityEngine.UI.Text].color = color;
                                self.worker_pause[_index][i] = false;
                                self.speak_end[_index][i] = nil;
                            end)
                        end;
                    else
                        self:ShowNpcDesc(worker_label, text, math.random(1,3), function ()
                            local _, color = UnityEngine.ColorUtility.TryParseHtmlString(text_color[1]);
                            worker_label.name[UnityEngine.UI.Text].color = color;
                            self.worker_pause[_index][i] = false;
                        end)
                    end
                end

                worker_item.click:SetActive(self.isMaster);
                CS.UGUIClickEventListener.Get(worker_item.click.gameObject).onClick = function (obj)
                    if not self.isMaster then
                        return;
                    end
                    --员工管理
                    if info.line == 1 then
                        DialogStack.Push("Manor_Select_Worker",{line = info.line, pos = i, lastid = self.productLine.worker[i]});
                    else
                        DialogStack.Push("Manor_Select_Worker",{line = info.line, pos = i, lastid = self.productLine.worker[i]});
                    end
                end
                worker_item:SetActive(true);
            else
                worker_item:SetActive(false);
            end
        end
       

        CS.UGUIClickEventListener.Get(view.top.info.Button.gameObject).onClick = function (obj)
            local empty = true;
            for i,v in ipairs(self.productLine.worker) do
                if v ~= 0 then
                    empty = false;
                    break;
                end
            end
            if empty then
                showDlgError(nil,"没有员工,先派遣员工吧")
            else
               --添加活力
               DialogStack.Push("Manor_Add_Energy");
            end
        end

        CS.UGUIClickEventListener.Get(view.top.left.gameObject).onClick = function (obj)
           if self.pos - 1 < 1 then
                return;
            end    
            self:FrameMove(self.frame_list[self.index].gameObject, 2,false);
            self.pos = self.pos - 1;
            self.index = self.dialog_list[self.pos];
            self.line = self.manorInfo[self.index].line;
            local view = self:createFrame(self.index);
            self:RefreshFrame();
            self:FrameMove(view.gameObject, 2,true);
            
            print("self.index",self.index)
        end
    
        CS.UGUIClickEventListener.Get(view.top.right.gameObject).onClick = function (obj)
            if self.pos + 1 > #self.dialog_list then
                return;
            end
    
            self:FrameMove(self.frame_list[self.index].gameObject, 1,false);
            self.pos = self.pos + 1;
            self.index = self.dialog_list[self.pos];
            self.line = self.manorInfo[self.index].line;
            local view = self:createFrame(self.index);
            self:RefreshFrame();
            self:FrameMove(view.gameObject, 1,true);
            
            print("self.index",self.index)
        end

        self.frame_list[index] = view;
    else
        view = self.frame_list[index];
    end
    return view;
end

function View:UpdateQipao(worker_item, anime)
    local animation = worker_item.qipao.animation[CS.Spine.Unity.SkeletonGraphic];
    self:LoadAnimaion(animation, nil, anime, nil, 2);
end

function View:AddCharacter(id , node, name, max)
    if self.character[self.index][id] then
        return;
    end
    node:SetActive(false);
    node[UnityEngine.CanvasGroup].alpha = 0;
    node.gameObject.transform:SetSiblingIndex(2);
    self.controller[self.index]:Add(id, node.gameObject);
    self.controller[self.index]:SetPoint(id, name.."1")

    local character = {};
    character.id = id;
    character.node = node;
    character.name = name;
    character.max = max;
    character.pos = 1;
    character.nextMoveTime = Time.now() + math.random(2, 5);
    self.character[self.index][id] = character;
end

function View:AddWorker(id , node, name, max)
    for i,v in ipairs(self.worker[self.index]) do
        if v.id == id then
            return;
        end
    end
    self.controller[self.index]:Add(id, node.gameObject);
    local worker = {};
    worker.id = id;
    worker.node = node;
    worker.name = name;
    worker.max = max;
    worker.pos = 1;
    table.insert(self.worker[self.index], worker)
end

function View:FrameMove(obj,type,inOrOut)
    if inOrOut then
        if type == 1 then
            obj.transform.localPosition = Vector3(1000, 0, 0);
        elseif type == 2 then
            obj.transform.localPosition = Vector3(-1000, 0, 0);
        end
		obj:SetActive(true);
		obj.transform:DOLocalMove(Vector3(0, 0, 0),0.2)
    else
        if type == 1 then
            obj.transform:DOLocalMove(Vector3(-1000, 0, 0),0.2):OnComplete(function ()
                obj:SetActive(false);
            end)
        elseif type == 2 then
            obj.transform:DOLocalMove(Vector3(1000, 0, 0),0.2):OnComplete(function ()
                obj:SetActive(false);
            end)
        end
	end
end

function View:UseWorkerSpeedUp()
    if self.free then
        self.dialog.speedup:SetActive(false);
        return;
    end
    for k,v in pairs(self.productLine.orders) do
        if v.left_count > 0 then
            local product = self.productList[v.gid];
            local productCfg = ItemHelper.Get(product.reward[1].type,product.reward[1].id);
            utils.IconFrameHelper.Create(self.dialog.speedup.item.IconFrame,{type = product.reward[1].type, id = product.reward[1].id, count = product.reward[1].value})
            self.dialog.speedup.item.info.name[CS.UnityEngine.UI.Text]:TextFormat(productCfg.name);
            self.dialog.speedup.item.info.Slider[UnityEngine.UI.Slider].value = 0;
            self.dialog.speedup.item.info.Slider[UnityEngine.UI.Slider].maxValue = self.productLine.next_gather_time - self.productLine.order_start_time;
            self.dialog.speedup.item.info.time[UnityEngine.UI.Text].text = "00:00:00";
            break;
        end
    end
    local info = self.manorInfo[self.index];
    for i=1,4 do
        local worker_item = self.dialog.speedup.worker["woker"..i];
        local name = info["job_name"..i];
        if name and name ~= "" and self.productLine.worker[i] ~= 0 then
            worker_item.info.name[CS.UnityEngine.UI.Text]:TextFormat(name);
            local worker = self.manorProductInfo:GetWorkerInfo(self.productLine.worker[i],1);
            if worker then
                worker_item.Slider[UnityEngine.UI.Slider].value = worker.power/worker.powerlimit;
                worker_item.Slider.num[UnityEngine.UI.Text].text = worker.power;
                local prop_id = ManorModule.GetManorLineConfig(self.line).prop_effect[i].type;
                local effect_time = (10 + math.max((worker.prop[prop_id] or 0) - 500, 0)/100) * 60
                worker_item.effect[UnityEngine.UI.Text].text = self:GetTime(effect_time, 1);
                utils.IconFrameHelper.Create(worker_item.IconFrame,{type = 42, uuid = self.productLine.worker[i], func = function (item)
                    item.Star:SetActive(false);
                end})
                worker_item.dark:SetActive(worker.power < 50);
                CS.UGUIClickEventListener.Get(worker_item.IconFrame.gameObject).onClick = function (obj)
                    local _worker = self.manorProductInfo:GetWorkerInfo(self.productLine.worker[i],1);
                    if _worker.power < 50 then
                        showDlgError(nil, "活力不足50点，无法加速");
                        return;
                    end
                    if self.productLine.next_gather_gid ~= 0 then
                        self.speedup_order = self.productLine.next_gather_gid
                        self.manorProductInfo:SpeedUpByWorker(self.line, self.productLine.worker[i]);
                    else
                        showDlgError(nil, "订单已完成");
                        self.dialog.speedup:SetActive(false);
                    end
                end
                worker_item:SetActive(true);
            else
                ERROR_LOG("员工信息不存在", self.productLine.worker[i])
                worker_item:SetActive(false);
            end
        else
            worker_item:SetActive(false);
        end
    end
    self.dialog.speedup:SetActive(true);
end

function View:RefreshFrame()
    local index = self.index
	local view = self.frame_list[index];
	self.free = true;

    self.productLine = self.manorProductInfo:GetLine(self.line);
    self.productList = self.manorProductInfo:GetProductList(self.line);
    print("self.productLine"..self.line,sprinttb(self.productLine))
    print("self.productList"..self.line,sprinttb(self.productList))

    view.top.left:SetActive(self.pos - 1 > 0);
    view.top.right:SetActive(self.pos + 1 <= #self.dialog_list);

    local canGather = false;
    for k,v in pairs(self.productLine.orders) do
        if v.left_count > 0 then
            self.free = false;
            local product = self.productList[v.gid];
            local productCfg = ItemHelper.Get(product.reward[1].type,product.reward[1].id);
            -- view.bottom.working.board.newItemIcon[SGK.newItemIcon]:SetInfo(productCfg);
            -- view.bottom.working.board.newItemIcon[SGK.newItemIcon].Count = product.reward[1].value;
            utils.IconFrameHelper.Create(view.bottom.working.board.IconFrame,{type = product.reward[1].type, id = product.reward[1].id, count = product.reward[1].value})
            view.bottom.working.board.name[CS.UnityEngine.UI.Text]:TextFormat(productCfg.name);
            view.bottom.working.board.Text[CS.UnityEngine.UI.Text].text = "";
            view.bottom.working.board.time:SetActive(true);
            break;
        end
        if v.gather_count > 0 then
            canGather = true;
            local product = self.productList[v.gid];
            local productCfg = ItemHelper.Get(product.reward[1].type,product.reward[1].id);
            -- view.bottom.working.board.newItemIcon[SGK.newItemIcon]:SetInfo(productCfg);
            -- view.bottom.working.board.newItemIcon[SGK.newItemIcon].Count = product.reward[1].value;
            utils.IconFrameHelper.Create(view.bottom.working.board.IconFrame,{type = product.reward[1].type, id = product.reward[1].id, count = product.reward[1].value})
            view.bottom.working.board.Text[CS.UnityEngine.UI.Text]:TextFormat("{0} (可收获)",productCfg.name);
            view.bottom.working.board.name[CS.UnityEngine.UI.Text].text = "";
            view.bottom.working.board.time:SetActive(false);
            break;
        end
    end

    if self.free then
        if canGather then
            view.bottom.working:SetActive(true);
            view.bottom.nowork:SetActive(false);
            view.bottom.working.complete.gather:SetActive(true);
            view.bottom.working.complete.fast:SetActive(false);
        else
            view.bottom.working:SetActive(false);
            view.bottom.nowork:SetActive(true);
        end
    else
        view.bottom.working:SetActive(true);
        view.bottom.nowork:SetActive(false);
        view.bottom.working.complete.gather:SetActive(false);
        view.bottom.working.complete.fast:SetActive(true);
    end
    SetButtonStatus(not self.free, view.bottom.working.make);

    local frame_content = nil;
    if index == self.special_index then
        frame_content = view.top.content2;
        if self.free then
            frame_content.jiqi1[CS.Spine.Unity.SkeletonGraphic].AnimationState:SetAnimation(0,"nowork",true);
        else
            frame_content.jiqi1[CS.Spine.Unity.SkeletonGraphic].AnimationState:SetAnimation(0,"work",true);
        end
        frame_content.jiqi2[CS.Spine.Unity.SkeletonGraphic].AnimationState:SetAnimation(0,"nowork",true);
        frame_content.jiqi3[CS.Spine.Unity.SkeletonGraphic].AnimationState:SetAnimation(0,"nowork",true);
        frame_content.jiqi4[CS.Spine.Unity.SkeletonGraphic].AnimationState:SetAnimation(0,"nowork",true);
        view.bottom.nowork.make.Text[CS.UnityEngine.UI.Text]:TextFormat("开始研究");
        view.bottom.effect.Text[CS.UnityEngine.UI.Text]:TextFormat("<color=#FFD731FF>研究时间缩短为：{0}%</color>", math.floor(self.productLine.effect_time * 100));  
    else
        frame_content = view.top.content;
        frame_content.tielu[CS.Spine.Unity.SkeletonGraphic].AnimationState:SetAnimation(0,"nowork",true);
        frame_content.cuihuo[CS.Spine.Unity.SkeletonGraphic].AnimationState:SetAnimation(0,"nowork",true);
        frame_content.jiqi[CS.Spine.Unity.SkeletonGraphic].AnimationState:SetAnimation(0,"nowork",true);
        view.bottom.nowork.make.Text[CS.UnityEngine.UI.Text]:TextFormat("开始制作");
        view.bottom.effect.Text[CS.UnityEngine.UI.Text]:TextFormat("<color=#FFD731FF>制作时间缩短为：{0}%</color>", math.floor(self.productLine.effect_time * 100));
    end
    
    if self.isMaster then
        self:UpdateWorkerInfo(view);
        self:CheckHangoutMan();
        self:CheckVisitor();
    else
        SetButtonStatus(self.manorProductInfo:CanSteal(self.line), view.bottom.working.steal);
    end
    

    if self.productLine.event.line_produce_rate_extra_data ~= 0 and self.productLine.event.line_produce_rate_end_time > Time.now() then
        self.manor_event_cfg = ManorModule.GetManorEventConfig(self.productLine.event.line_produce_rate_extra_data);
        frame_content.monster.Label.name[UnityEngine.UI.Text]:TextFormat(self.manor_event_cfg.npc_name);
        local animation = frame_content.monster.spine[CS.Spine.Unity.SkeletonGraphic];
        self:LoadAnimaion(animation, nil, self.manor_event_cfg.npc_id, function ()
            frame_content.monster.spine[SGK.DialogSprite].idle = true;
        end);	
        frame_content.monster.Label.effect.Text[UnityEngine.UI.Text]:TextFormat("产量降低{0}%", math.abs(self.productLine.event.line_produce_rate))
        frame_content.monster:SetActive(true);
        self.monster[index] = frame_content.monster;
    else
        self.monster[index] = nil;
        frame_content.monster:SetActive(false);
    end
end

function View:UpdateWorkerInfo(view)
    local powerNum = 0;
	local workerNum = 0;
    local frame_content = nil;
    if self.index == self.special_index then
        frame_content = view.top.content2;
    else
        frame_content = view.top.content;
    end
    local worker_num = self.manorInfo[self.index].work_num
    local power, limit = 0,0;
    local effect_prop = {};	
    for i=1,worker_num do  
        local worker_item = view.bottom.workers["worker"..i];
        if self.productLine.worker[i] ~= 0 then
            workerNum = workerNum + 1;
            local hero = self:GetHero(self.productLine.worker[i], i);
            local worker = self.manorProductInfo:GetWorkerInfo(self.productLine.worker[i],1);
            local worker_event = self.manorProductInfo:GetWorkerInfo(self.productLine.worker[i],3);
            if hero then
                if worker_event and worker_event.outside then
                    frame_content["character"..i]:SetActive(false);
                else
                    local animation = frame_content["character"..i].spine[CS.Spine.Unity.SkeletonGraphic];
                    self:LoadAnimaion(animation, hero.id, hero.mode, function ()
                        animation.startingAnimation = "idle1";
                        frame_content["character"..i].spine[SGK.DialogSprite].idle = true;
                        if not self.free then
                            -- local _direction = 0;
                            -- if self.line == 1 then
                            --     _direction = direction[1][i];
                            -- else
                            --     _direction = direction[2][i];
                            -- end
                            -- frame_content["character"..i].spine[SGK.DialogSprite].direction = _direction or 0;
                            frame_content["character"..i].Label.qipao:SetActive(true);
                            frame_content["character"..i].Label.qipao[UnityEngine.CanvasGroup]:DOFade(1,0.5);
                        else
                            frame_content["character"..i].Label.qipao:SetActive(false);
                        end
                    end);	
                    frame_content["character"..i]:SetActive(true);
                    if not self.free then
                        if self.index == self.special_index then
                            if i == 1 then
                                frame_content.jiqi4[CS.Spine.Unity.SkeletonGraphic].AnimationState:SetAnimation(0,"work",true);
                            elseif i == 2 then
                                -- frame_content.jiqi2[CS.Spine.Unity.SkeletonGraphic].startingAnimation = "work";
                                frame_content.jiqi2[CS.Spine.Unity.SkeletonGraphic].AnimationState:SetAnimation(0,"work",true);
                            elseif i == 3 then
                                frame_content.jiqi3[CS.Spine.Unity.SkeletonGraphic].AnimationState:SetAnimation(0,"work",true);
                            end
                        else
                            if i == 1 then
								frame_content.jiqi[CS.Spine.Unity.SkeletonGraphic].AnimationState:SetAnimation(0,"work",true);
                            elseif i == 2 then
								frame_content.tielu[CS.Spine.Unity.SkeletonGraphic].AnimationState:SetAnimation(0,"work",true);					
							elseif i == 3  then
								frame_content.cuihuo[CS.Spine.Unity.SkeletonGraphic].AnimationState:SetAnimation(0,"work",true);
							end	
                        end    
                    end
                end
                
                if worker then
                    power = power + worker.power;
                    limit = limit + worker.powerlimit;
                    local prop_id = ManorModule.GetManorLineConfig(self.line).prop_effect[i].type;
                    local num = worker.prop[prop_id] or 0;
                    if effect_prop[prop_id] then
                       effect_prop[prop_id] = effect_prop[prop_id] + num;
                    else
                        effect_prop[prop_id] = num;
                    end
                    worker_item.info.prop[UnityEngine.UI.Text]:TextFormat(ManorModule.GetManorWorkType(prop_id).work_type..num);
                    local animation = worker_item.character[CS.Spine.Unity.SkeletonGraphic];
                    self:LoadAnimaion(animation, hero.id, hero.mode, function ()
                        animation.startingAnimation = "idle1";
                        animation:Initialize(true);	
                    end);
                    
                    
                    worker_item.character:SetActive(true);
                    worker_item.click.plus:SetActive(false);
                    worker_item.info.prop:SetActive(true);
                end
            else
                ERROR_LOG(self.productLine.worker[i].." hero not found");
                frame_content["character"..i]:SetActive(false);
            end
        else
            frame_content["character"..i]:SetActive(false);
            worker_item.character:SetActive(false);
            worker_item.click.plus:SetActive(true);
            worker_item.info.prop:SetActive(false);
        end
    end

    if power ~= 0 and limit ~= 0 then
        powerNum = power/limit;
    else
        powerNum = 0;
    end    

    view.top.info.Slider[CS.UnityEngine.UI.Slider].value = powerNum;
    view.top.info.num[CS.UnityEngine.UI.Text].text = math.ceil(powerNum * 100).."%";

    if workerNum == 0 then
        view.bottom.nowork.make[CS.UGUISelectorGroup]:setGray();
    else
        view.bottom.nowork.make[CS.UGUISelectorGroup]:reset();
    end
end

function View:GetHero(uuid, pos)
    if self.isMaster then
        return self.manager:GetByUuid(uuid)
    elseif pos then
        local hero = {};
        hero.id = self.productLine.worker[pos + 5];
        local mode = self.manager:GetHeroFashionSuit(uuid);
        if mode then
            hero.mode = mode;
        else
            hero.mode = hero.id or 11000;
        end
        return hero
    end    
end

function View:CheckHangoutMan()
    local _outsideWorker = ManorManufactureModule.GetOutsideWorker();
    for i,v in ipairs(_outsideWorker) do
        if v.outside and v.where == self.line and not v.moving then
            self:ShowCharacter(v.uuid, true, "outside")
        end
    end
end

function View:CheckVisitor()
    local _visitor = ManorManufactureModule.GetVisitorManager():GetVisitor();
    for i,v in pairs(_visitor) do
        if v.where == self.line and not v.moving then
            self:ShowCharacter(v.gid, true, "visit")
        end
    end
end

function View:ShowCharacter(id, show, type)
    local character = nil;
    local name = "";
    local mode = 0;
    local gid = nil;
    if type == "outside" then
        if self.line == 1 then
            character = self.frame_list[self.index].top.content2.character0;
        else
            character = self.frame_list[self.index].top.content.character0;
        end 
        -- character[UnityEngine.CanvasGroup].alpha = 0;
        local hero = self:GetHero(id);
        mode = hero.mode;
        name = hero.name;
        gid = hero.id;
        if self.outside_man[self.index] == nil then
            self.outside_man[self.index] = {};
        end
        self.outside_man[self.index][id] = character;
    elseif type == "visit" then
        if self.line == 1 then
            character = self.frame_list[self.index].top.content2.visitor;
        else
            character = self.frame_list[self.index].top.content.visitor;
        end 
        mode = self.visitorConfig[id].role_id;
        name = self.visitorConfig[id].role_name;
        if self.visitor[self.index] == nil then
            self.visitor[self.index] = {};
        end
        self.visitor[self.index][id] = character;
    end

    character.Label.name[UnityEngine.UI.Text]:TextFormat(name);
    local animation = character.spine[CS.Spine.Unity.SkeletonGraphic];
    self:LoadAnimaion(animation, gid, mode, function ()
        character.spine[SGK.DialogSprite].idle = true;
        animation:Initialize(true);	
        -- character.spine[SGK.DialogSprite]:SetDirty();
    end);
    character:SetActive(true);
    if show then
        character[UnityEngine.CanvasGroup].alpha = 1;
    else
        character[UnityEngine.CanvasGroup]:DOFade(1,0.5);
    end
end

function View:LoadAnimaion(animation, gid, mode, callback, type)
    type = type or 1;
    if type == 1 then
        -- local resource = SGK.ResourcesManager.Load("roles_small/"..mode.."/"..mode.."_SkeletonData") or SGK.ResourcesManager.Load("roles_small/11001/11001_SkeletonData");
        local resource = utils.SGKTools.loadExistSkeletonDataAsset("roles_small/", gid, mode,"_SkeletonData");
        animation.skeletonDataAsset = resource;
    elseif type == 2 then
        local resource = SGK.ResourcesManager.Load("manor/qipao/"..mode.."_SkeletonData.asset");
        animation.skeletonDataAsset = resource;
    end
	
	animation:Initialize(true);	
	if callback then
		callback();
	end
	-- SGK.ResourcesManager.LoadAsync(animation, "roles_small/"..mode.."/"..mode.."_SkeletonData",function (resource)
	-- 	if not resource then
	-- 		resource = SGK.ResourcesManager.Load("roles_small/11001/11001_SkeletonData");
	-- 	end
	-- 	animation.skeletonDataAsset = resource;
	-- 	animation:Initialize(true);
	-- 	if callback then
	-- 		callback();
	-- 	end
	-- end)
end

function View:ShowCompleteDialog()
	CS.UGUIClickEventListener.Get(self.dialog.tip.confirm.gameObject).onClick = function (obj)
		local time = self.productLine.next_gather_time - Time.now();
		local count = math.ceil(time/60);
		if ItemModule.GetItemCount(90006) >= count then
			self.manorProductInfo:Speedup(self.line,100);
		else
			showDlgError(nil, "钻石不足");
		end
		self.dialog.tip.gameObject:SetActive(false);
	end
	self.dialog.tip:SetActive(true)
end

function View:GetTime(time,format)
	local time_str = "";
	if format == 1 then		
		if time < 60 then
			time_str = time.."秒";
		elseif time < 3600 then
			time_str = math.floor(time/60).."分"..math.floor(time%60).."秒";
		else --if productInfo.time.max < 86400  then
			time_str = math.floor(time/3600).."小时"..math.floor((time%3600)/60).."分";
		end
	elseif format == 2 then
		local hour,sec = 0;
		local min = 0;
		if time < 60 then
			sec = time;
		elseif time < 3600 then
			min = math.floor(time/60);
			sec = math.floor(time%60);
		else --if productInfo.time.max < 86400  then
			hour = math.floor(time/3600);
			min = math.floor((time%3600)/60);
			sec =  math.floor(time%60);
		end
		time_str = string.format("%02d"..":".."%02d"..":".."%02d",hour,min,sec);
	end
	return time_str;
end

function View:ShowDrink(worker_item, idx, _index)
    local anime = {};
    if _index == self.special_index then
        anime = qipao_anime1;
    else
        anime = qipao_anime2;
    end
    if worker_item.qipao.activeSelf then
        self:UpdateQipao(worker_item, anime[10]);
        StartCoroutine(function ()
            WaitForSeconds(math.random(2,3))
            self:UpdateQipao(worker_item,anime[idx]);
            self.worker_pause[_index][idx] = false;
        end)
    else
        self:UpdateQipao(worker_item, anime[10]);
        worker_item.qipao:SetActive(true);
        worker_item.qipao[UnityEngine.CanvasGroup]:DOFade(1,1):OnComplete(function ()
            worker_item.qipao[UnityEngine.CanvasGroup]:DOFade(0,1):OnComplete(function ()
                self:UpdateQipao(worker_item,anime[idx]);
                worker_item.qipao:SetActive(false);
                self.worker_pause[_index][idx] = false;
            end):SetDelay(math.random(2,3));
        end)
    end
end

function View:Update()
	if not self.free and self.productLine and  self.productLine.next_gather_time and self.productLine.next_gather_time ~= 0  then
		local time = self.productLine.next_gather_time - Time.now();
		--print("time",self.productline.next_gather_time, Time.now(),time)
		if time <= 0 then
            self.free = true;
            self.manorProductInfo:GetProductLineFromServer();
            if self.dialog.tip.gameObject.activeSelf then
                self.dialog.tip.gameObject:SetActive(false);
            end
        end
        self.dialog.tip.icon.count[CS.UnityEngine.UI.Text].text = tostring(math.ceil(time/60));
        self.frame_list[self.index].bottom.working.complete.fast.count[CS.UnityEngine.UI.Text].text = tostring(math.ceil(time/60));
        self.frame_list[self.index].bottom.working.board.time[CS.UnityEngine.UI.Text].text = self:GetTime(time,2);
        if self.dialog.speedup.gameObject.activeSelf then
            if time <= 0 then
                self.dialog.speedup.item.info.time[CS.UnityEngine.UI.Text].text = "00:00:00";
                self.dialog.speedup.item.info.Slider[UnityEngine.UI.Slider].value = self.dialog.speedup.item.info.Slider[UnityEngine.UI.Slider].maxValue;
            else
                self.dialog.speedup.item.info.time[CS.UnityEngine.UI.Text].text = self:GetTime(time,2);
                self.dialog.speedup.item.info.Slider[UnityEngine.UI.Slider].value = self.dialog.speedup.item.info.Slider[UnityEngine.UI.Slider].maxValue - time;
            end
        end
    end

    --喝水事件
    if self.isMaster and Time.now() >= self.drink_time then
        self.drink_time = Time.now() + math.random(15, 30);
        for i=1,5 do
            local uuid = self.productLine.worker[i];
            if uuid ~= 0 then
                local hero = self:GetHero(uuid, i);
                local life_cfg = ManorModule.GetManorLifeConfig(hero.id, 6);
                if (self.free and life_cfg.unworking_rate >= math.random(1,100)) or (not self.free and life_cfg.working_rate >= math.random(1,100)) then
                    local _index = self.index;
                    self.worker_pause[_index][i] = true;
                    local worker_item = nil;
                    if self.line == 1 then
                        worker_item = self.frame_list[self.index].top.content2["character"..i].Label;
                    else
                        worker_item = self.frame_list[self.index].top.content["character"..i].Label;
                    end
                    if worker_item.dialogue[UnityEngine.CanvasGroup].alpha > 0 then
                        self.speak_end[_index][i] = function ()
                            self:ShowDrink(worker_item, i, _index);
                        end;
                    else
                        self:ShowDrink(worker_item, i, _index);
                    end
                end
            end
        end
    end

    --小人移动
    if Time.now() >= self.update_time2 + 1 then
        self.update_time2 = Time.now();
        local index = self.index;
        if self.character[index] and self.controller[index] then
            for i,v in pairs(self.character[index]) do
                if v.node and v.node.gameObject and v.node.gameObject.activeSelf and Time.now() >= v.nextMoveTime then
                    self.character[index][i].nextMoveTime = Time.now() + 100;
                    local next_pos = v.pos + 1;
                    if next_pos > v.max then
                        next_pos = 1;
                    end
                    self.character[index][i].pos = next_pos;
                    self.controller[index]:MoveCharacter(v.id, v.name..next_pos, function ()
                        self.character[index][i].nextMoveTime = Time.now() + math.random(2, 5);
                    end);
                end
            end
        end
    end

    --工人移动
    if Time.now() >= self.worker_move_time then
        self.worker_move_time = Time.now() + math.random(2,5);
        local index = self.index;
        local _worker = {};
        for i,v in ipairs(self.worker[index]) do
            if v.node and v.node.gameObject and v.node.gameObject.activeSelf and not self.worker_pause[self.index][i] then
                table.insert(_worker, {info = v, idx = i});
            end
        end
        if #_worker ~= 0 then
            local select = _worker[math.random(1, #_worker)];
            local next_pos = select.info.pos + 1;
            if next_pos > select.info.max then
                next_pos = 1;
            end
            self.worker[index][select.idx].pos = next_pos;
            self.controller[index]:MoveCharacter(select.info.id, select.info.name..next_pos);
        end
    end

    --捣乱小人说话
    if self.productLine.event and self.productLine.event.line_produce_rate_extra_data and self.manor_event_cfg and Time.now() >= self.monster_speak then
        local str = self.manor_event_cfg["describe"..math.random(1,3)];
        local npc = self.monster[self.index];
        self:ShowNpcDesc(npc.Label, str, 2)
        self.monster_speak = Time.now() + 3;
    end

    --小人说话
	if self.isMaster and self.productLine.worker and self.talk_num < MAX_TALK and Time.now() >= self.update_time then
		local worker_pos = {};
		for i,v in ipairs(self.productLine.worker) do
			if v ~= 0 and i <= 5 then
				table.insert( worker_pos, {type = 1, pos = i});
			end
		end
        
        if self.outside_man[self.index] then
            for k,v in pairs(self.outside_man[self.index]) do
                table.insert( worker_pos, {type = 2, id = k});
            end
        end

        if self.visitor[self.index] then
            for k,v in pairs(self.visitor[self.index]) do
                table.insert( worker_pos, {type = 3, id = k});
            end
        end

        if #worker_pos ~= 0 then
            local info = worker_pos[math.random(1,#worker_pos)];
            self.update_time = Time.now() + math.random(4,8);
            if info.type == 2 then --访客
                local uuid = info.id;
                local hero = self:GetHero(uuid);
                if hero then
                    local talk_cfg = ManorModule.GetManorChat2(hero.id);
                    assert(talk_cfg,hero.id.." chat2 config not found");
                    self.talk_num = self.talk_num + 1;
                    local str = talk_cfg.hanging_out[math.random(1,#talk_cfg.hanging_out)];
                    local npc = self.outside_man[self.index][uuid];
                    self:ShowNpcDesc(npc.Label, str, math.random(1,3),function () 
                        self.talk_num = self.talk_num - 1;
                    end)
                end
            elseif info.type == 3 then --外来访客
                local gid = info.id;
                local cfg = self.visitorConfig[gid];
                if cfg then
                    self.talk_num = self.talk_num + 1;
                    local str = cfg["hanging_out"..math.random(1,2)];
                    local npc = self.visitor[self.index][gid];
                    self:ShowNpcDesc(npc.Label, str, math.random(1,3),function () 
                        self.talk_num = self.talk_num - 1;
                    end)
                end
            elseif info.type == 1 then
                local hero = self:GetHero(self.productLine.worker[info.pos], info.pos);
                if hero and not self.worker_pause[self.index][info.pos] then
                    local talk_cfg = ManorModule.GetManorChat(hero.id,self.line, info.pos);
                    assert(talk_cfg,hero.id.." "..self.line.." "..info.pos.." chat config not found");
                    self.talk_num = self.talk_num + 1;
                    --print("NPC说话",self.free);
                    local str = self.free and talk_cfg.blank_words[math.random(1,#talk_cfg.blank_words)] or  talk_cfg.working_words[math.random(1,#talk_cfg.working_words)];
                    local npc = nil;
                    if self.line == 1 then
                        npc = self.frame_list[self.index].top.content2["character"..info.pos];
                    else
                        npc = self.frame_list[self.index].top.content["character"..info.pos];
                    end
                    self:ShowNpcDesc(npc.Label, str, math.random(1,3),function () 
                        self.talk_num = self.talk_num - 1;
                        if self.speak_end[self.index][info.pos] then
                            self.speak_end[self.index][info.pos]();
                            self.speak_end[self.index][info.pos] = nil;
                        end
                    end)
                end
            end
        end
	end
end

function View:ShowNpcDesc(npc_view,desc,type, fun)
	npc_view.dialogue.bg1:SetActive(type == 1)
	npc_view.dialogue.bg2:SetActive(type == 2)
    npc_view.dialogue.bg3:SetActive(type == 3)
    npc_view.qipao[UnityEngine.CanvasGroup]:DOKill();
    npc_view.dialogue.desc[UnityEngine.UI.Text].text = desc

    if npc_view.qipao.activeSelf then
        npc_view.qipao[UnityEngine.CanvasGroup]:DOFade(0,0.5):OnComplete(function()
            npc_view.dialogue[UnityEngine.CanvasGroup]:DOFade(1,1):OnComplete(function()
                npc_view.dialogue[UnityEngine.CanvasGroup]:DOFade(0,1):OnComplete(function()
                    -- npc_view.dialogue.desc[UnityEngine.UI.Text].text = "";
                    if fun then
                        fun()
                    end
                    npc_view.qipao[UnityEngine.CanvasGroup]:DOFade(1,0.5);
                end):SetDelay(1)
            end)        
        end)
    else
        npc_view.dialogue[UnityEngine.CanvasGroup]:DOFade(1,1):OnComplete(function()
            npc_view.dialogue[UnityEngine.CanvasGroup]:DOFade(0,1):OnComplete(function()
                -- npc_view.dialogue.desc[UnityEngine.UI.Text].text = "";
                if fun then
                    fun()
                end
            end):SetDelay(1)
        end)
    end
end

function View:deActive()
	for i=#self.dialog,1,-1 do
		if self.dialog[i].active then
			self.dialog[i]:SetActive(false);
			return false;
		end
	end
    --ManorManufactureModule.SetInManorScene(false);
    --utils.SGKTools.PlayDestroyAnim(self.gameObject)
	return true;
end

function View:OnDestroy()
	self.savedValues.Manorindex = self.index;	
end

function View:listEvent()
	return {
        "MANOR_MANUFACTURE_PRODUCT_LINE_CHANGE",
        "MANOR_MANUFACTURE_SPEEDUP_FAILED",
        "MANOR_NPC_START_MOVE",
        "MANOR_NPC_END_MOVE",
        "MANOR_MANUFACTURE_GATHER_SUCCESS",
        "MANOR_MANUFACTURE_SPEEDUPBYWORKER_SUCCESS",
        "MANOR_MANUFACTURE_WORKER_INFO_CHANGE",
        "MANOR_MANUFACTURE_CHECK_WORKER_INFO_SUCCESS",
        "HERO_FASHION_CHANGE"
	}
end

function View:onEvent(event, ...)
	print("onEvent", event, ...);
    if event == "MANOR_MANUFACTURE_SPEEDUP_FAILED"  then
        showDlgError(nil, "加速失败");
    elseif event == "MANOR_MANUFACTURE_PRODUCT_LINE_CHANGE" then
        self:RefreshFrame();
    elseif event == "MANOR_NPC_START_MOVE" then
        local data = ...;
        if data.from == (self.line == 1 and "institute" or "manufacture") then
            local outside_man = self.outside_man[self.index];
            local visitor = self.visitor[self.index];
            if data.type == "outside" and outside_man and outside_man[data.id] and outside_man[data.id].gameObject.activeSelf then
                outside_man[data.id][UnityEngine.CanvasGroup]:DOFade(0,0.5):OnComplete(function ()
                    outside_man[data.id]:SetActive(false);
                    if self.line == 1 then
                        outside_man[data.id].gameObject.transform:SetSiblingIndex(8);
                    else
                        outside_man[data.id].gameObject.transform:SetSiblingIndex(9);
                    end
                    self.controller[self.index]:SetPoint(0, "fangke1")
                    self.outside_man[self.index][data.id] = nil;
                end);
            elseif data.type == "visit" and visitor and visitor[data.id] and visitor[data.id].gameObject.activeSelf then
                visitor[data.id][UnityEngine.CanvasGroup]:DOFade(0,0.5):OnComplete(function ()
                    visitor[data.id]:SetActive(false);
                    if self.line == 1 then
                        visitor[data.id].gameObject.transform:SetSiblingIndex(9);
                        self.controller[self.index]:SetPoint(10, "wfangke1")
                    else
                        visitor[data.id].gameObject.transform:SetSiblingIndex(10);
                        self.controller[self.index]:SetPoint(10, "wfangke1")
                    end
                    self.visitor[self.index][data.id] = nil;
                end);
            end
        end
    elseif event == "MANOR_NPC_END_MOVE" then
        local data = ...;
        if data.to == (self.line == 1 and "institute" or "manufacture") then
            self:ShowCharacter(data.id, false, data.type)
        end
    elseif event == "MANOR_MANUFACTURE_GATHER_SUCCESS" then
        SetButtonStatus(true, self.frame_list[self.index].bottom.working.complete);
        self.frame_list[self.index].bottom.working.complete.gather[CS.UGUISelectorGroup]:reset();
    elseif event == "MANOR_MANUFACTURE_SPEEDUPBYWORKER_SUCCESS" then
        if self.dialog.speedup.gameObject.activeSelf then
            local productLine = self.manorProductInfo:GetLine(self.line);
            if productLine.orders[self.speedup_order] == nil or productLine.orders[self.speedup_order].gather_count > 0 then
                self.dialog.speedup:SetActive(false);
            end
        end
    elseif event == "MANOR_MANUFACTURE_WORKER_INFO_CHANGE" then
        local data = ...;
        if data then
            local power, limit, powerNum = 0,0,0;
            for i,v in ipairs(self.productLine.worker) do
                if v ~= 0 and i <= 5 then
                    local worker = self.manorProductInfo:GetWorkerInfo(v,1);
                    if worker then
                        if data and data.uuid == v and self.dialog.speedup.gameObject.activeSelf then
                            self.dialog.speedup.worker["woker"..i].Slider[UnityEngine.UI.Slider].value = worker.power/worker.powerlimit;
                            self.dialog.speedup.worker["woker"..i].Slider.num[UnityEngine.UI.Text].text = worker.power;
                            self.dialog.speedup.worker["woker"..i].dark:SetActive(worker.power < 50);
                        end
                        power = power + worker.power;
                        limit = limit + worker.powerlimit
                    end
                end
            end
            if power ~= 0 and limit ~= 0 then
                powerNum = power/limit;
            else
                powerNum = 0;
            end    
            self.frame_list[self.index].top.info.Slider[CS.UnityEngine.UI.Slider].value = powerNum;
            self.frame_list[self.index].top.info.num[CS.UnityEngine.UI.Text].text = math.ceil(powerNum * 100).."%";
        end
    elseif event == "MANOR_MANUFACTURE_CHECK_WORKER_INFO_SUCCESS" then
        self:UpdateWorkerInfo(self.frame_list[self.index])
    elseif event == "HERO_FASHION_CHANGE" then
        local uuid = ...;
        if uuid then
            for i,v in ipairs(self.productLine.worker) do
                if v == uuid and i <= 5 then
                    local mode = self.manager:GetHeroFashionSuit(uuid);
                    local frame_content = nil;
                    local worker_item = self.frame_list[self.index].bottom.workers["worker"..i];
                    if self.index == self.special_index then
                        frame_content = self.frame_list[self.index].top.content2;
                    else
                        frame_content = self.frame_list[self.index].top.content;
                    end
                    local animation = frame_content["character"..i].spine[CS.Spine.Unity.SkeletonGraphic];
                    self:LoadAnimaion(animation, self.productLine.worker[i + 5], mode, function ()
                        frame_content["character"..i].spine[SGK.DialogSprite].idle = true;
                    end);
                    local animation = worker_item.character[CS.Spine.Unity.SkeletonGraphic];
                    self:LoadAnimaion(animation, self.productLine.worker[i + 5], mode, function ()
                        --animation.state:SetAnimation(0,"idle3",true);
                    end);
                    break
                end
            end
        end
	end
end

return View;