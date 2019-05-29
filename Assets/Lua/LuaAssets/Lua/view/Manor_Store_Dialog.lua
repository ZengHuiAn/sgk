local ManorManufactureModule = require "module.ManorManufactureModule"
local ItemHelper = require "utils.ItemHelper"
local HeroModule = require "module.HeroModule"
local ManorModule = require "module.ManorModule"
local Time = require "module.Time"
local UserDefault = require "utils.UserDefault"
local ShopModule = require "module.ShopModule"
local TipConfig = require "config.TipConfig"

local View = {};
local manor_store_data = UserDefault.Load("manor_store_data", true);
local direction = {6,2,0,2};--商铺
local MAX_TALK = 1;
local character_info = {};
character_info[0] = {name = "fangke", max = 5};
character_info[1] = {name = "dianzhang", max = 3};
character_info[2] = {name = "shouyin", max = 2};
character_info[3] = {name = "tuixiao", max = 3};
character_info[4] = {name = "lihuo", max = 2};
character_info[5] = {name = "shangren", max = 5};
character_info[6] = {name = "wfangke", max = 5};
local qipao_anime = {};
qipao_anime[1] = "icon_shangdian_dianzhang/icon_shangdian_dianzhang";
qipao_anime[2] = "icon_shangdian_shouyinyuan/skeleton";
qipao_anime[3] = "icon_shangdian_tuixiaoyuan/icon_shangdian_tuixiaoyuan";
qipao_anime[4] = "icon_shangdian_lihuoyuan1/icon_shangdian_lihuoyuan1";
qipao_anime[5] = "icon_jidi_heshui/icon_jidi_heshui";
local text_color = {"#43FF00FF", "#0041FFFF"}

function View:Start(data)
    self.view = CS.SGK.UIReference.Setup(self.gameObject);
    self.index = data and data.index or self.savedValues.Manorindex or 2;
    self.dialog = self.view.dialog;
	self:InitData();
    self:InitView();
    if data and data.callback then
        data.callback();
    end
end

function View:InitData()
	self.manorProductInfo = ManorManufactureModule.Get();
	self.manorProductInfo:CheckWorkerProperty();
    self.manorProductInfo:GetProductLineFromServer();
	self.manorInfo = ManorModule.LoadManorInfo();
	self.chatInfo = ManorModule.GetManorChat();
    self.manager = HeroModule.GetManager();
    self.visitorConfig = ManorModule.GetManorOutsideConfig();

    self.line = self.manorInfo[self.index].line;
    self.update_time = Time.now() + math.random(3,6);
    self.update_time2 = Time.now();
    self.worker_move_time = Time.now() + math.random(2,5);
    self.drink_time = Time.now() + math.random(15,30);

    self.productLine = {};
    self.character = {};
    self.worker = {};
    self.item_UI = {};
    self.outside_man = {};
    self.visitor = {};
    self.talk_num = 0;
	self.NPC_talk = false;
    self.free = true;
    self.gathering = false;
    self.worker_pause = {};
    self.speak_end = {}

end

function View:InitView()
    self.controller = self.view.top.content[SGK.DialogPlayerMoveController];

    CS.UGUIClickEventListener.Get(self.view.title.close.gameObject).onClick = function (obj)        
        DialogStack.Pop();
    end
    CS.UGUIClickEventListener.Get(self.view.BG.gameObject, true).onClick = function (obj)        
        DialogStack.Pop();
    end

    CS.UGUIClickEventListener.Get(self.view.bottom.make.gameObject).onClick = function (obj)
        local haveWorker = false;
        for i,v in ipairs(self.productLine.worker) do
            if v ~= 0 then
                haveWorker = true;
                break;
            end
        end
        if haveWorker then
            DialogStack.Push("Manor_Store_Sale");
        else
            showDlgError(nil,"商铺内没有员工,先派遣员工吧")
        end
    end

    for i=1,4 do
        local worker_item = self.view.bottom.workers["worker"..i];
        worker_item.info.name[CS.UnityEngine.UI.Text]:TextFormat(self.manorInfo[self.index]["job_name"..i]);
        local unlock_cfg = ManorModule.GetManorOpenConfig(self.line, i);
        worker_item.lock:SetActive(module.playerModule.Get().level < unlock_cfg.open_level);
        self.view.top.content["character"..i].Label.name:TextFormat(self.manorInfo[self.index]["job_name"..i]);
        self.worker_pause[i] = false;
        self:UpdateQipao(i,i);
        self:AddWorker(i, self.view.top.content["character"..i], character_info[i].name, character_info[i].max);
        CS.UGUIClickEventListener.Get(self.view.top.content["character"..i].gameObject, true).onClick = function (obj)
            local worker_item = self.view.top.content["character"..i].Label;
            local hero = self.manager:GetByUuid(self.productLine.worker[i]);
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
            self.worker_pause[i] = true;
            local _, color = UnityEngine.ColorUtility.TryParseHtmlString(text_color[2]);
            worker_item.name[UnityEngine.UI.Text].color = color;

            if worker_item.dialogue[UnityEngine.CanvasGroup].alpha > 0 then
                self.speak_end[i] = function ()
                    self:ShowNpcDesc(worker_item, text, math.random(1,3), function ()
                        local _, color =UnityEngine.ColorUtility.TryParseHtmlString(text_color[1]);
                        worker_item.name[UnityEngine.UI.Text].color = color;
                        self.worker_pause[i] = false;
                        self.speak_end[i] = nil;
                    end)
                end;
            else
                self:ShowNpcDesc(worker_item, text, math.random(1,3), function ()
                    local _, color =UnityEngine.ColorUtility.TryParseHtmlString(text_color[1]);
                    worker_item.name[UnityEngine.UI.Text].color = color;
                    self.worker_pause[i] = false;
                end)
            end
        end
        CS.UGUIClickEventListener.Get(worker_item.click.gameObject).onClick = function (obj)
            --员工管理
            DialogStack.Push("Manor_Select_Worker",{line = 31, pos = i, lastid = self.productLine.worker[i]});
        end
    end

    CS.UGUIClickEventListener.Get(self.view.top.info.Button.gameObject).onClick = function (obj)
        local empty = true;
        for i,v in ipairs(self.productLine.worker) do
            if v ~= 0 then
                empty = false;
                break;
            end
        end
        if empty then
            showDlgError(nil,"商铺内没有员工,先派遣员工吧")
        else
           --添加活力
           DialogStack.Push("Manor_Add_Energy");
        end
    end
    CS.UGUIClickEventListener.Get(self.view.top.content.npc.gameObject, true).onClick = function (obj)
        print("商店")
        DialogStack.Push("ShopFrame",{index = 32});
    end
    CS.UGUIClickEventListener.Get(self.view.top.help.gameObject).onClick = function ( object )
		self.dialog.illustration.gameObject:SetActive(true);
	end
    CS.UGUIClickEventListener.Get(self.dialog.illustration.content.close.gameObject).onClick = function ( object )
		self.dialog.illustration.gameObject:SetActive(false);
    end
    self.dialog.illustration.content.BG.Text[UnityEngine.UI.Text]:TextFormat(TipConfig.GetAssistDescConfig(55002).info);
    
    self:AddCharacter(0, self.view.top.content.character0, character_info[0].name, character_info[0].max);
    self:AddCharacter(5, self.view.top.content.npc, character_info[5].name, character_info[5].max);
    self:AddCharacter(6, self.view.top.content.visitor, character_info[6].name, character_info[6].max);

    self:RefreshFrame();
end

function View:UpdateQipao(worker_idx, anime_idx)
    local animation = self.view.top.content["character"..worker_idx].Label.qipao.animation[CS.Spine.Unity.SkeletonGraphic];
    self:LoadAnimaion(animation, qipao_anime[anime_idx], nil, 2);
end

function View:AddCharacter(id , node, name, max)
    if self.character[id] then
        return;
    end
    local character = {};
    character.id = id;
    character.node = node;
    character.name = name;
    character.max = max;
    character.pos = 1;
    character.nextMoveTime = Time.now() + math.random(2, 5);
    node.gameObject.transform.localPosition = self.controller:GetPoint(name.."1");

    self.controller:Add(id, node.gameObject);
    -- table.insert(self.character, character)
    self.character[id] = character;
end

function View:AddWorker(id , node, name, max)
    for i,v in ipairs(self.worker) do
        if v.id == id then
            return;
        end
    end
    self.controller:Add(id, node.gameObject);
    local worker = {};
    worker.id = id;
    worker.node = node;
    worker.name = name;
    worker.max = max;
    worker.pos = 1;
    table.insert(self.worker, worker)
end

function View:ShowCharacter(id, show, type)
    local character = nil;
    local name = "";
    local mode = 0;
    if type == "outside" then
        character = self.view.top.content.character0;
        local hero = self.manager:GetByUuid(id);
        mode = hero.mode;
        name = hero.name;
        self.outside_man[id] = character;
    elseif type == "visit" then
        character = self.view.top.content.visitor;
        mode = self.visitorConfig[id].role_id;
        name = self.visitorConfig[id].role_name;
        self.visitor[id] = character;
    end

    character.Label.name[UnityEngine.UI.Text]:TextFormat(name);
    local animation = character.spine[CS.Spine.Unity.SkeletonGraphic];
    self:LoadAnimaion(animation, mode, function ()
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

function View:RefreshFrame()
	self.free = true
	local powerNum = 0;
	local workerNum = 0;
	local emptyPower = false;
    self.productLine = self.manorProductInfo:GetLine(self.line);
    self.productList = self.manorProductInfo:GetProductList(self.line);
    print("self.productLine"..self.line,sprinttb(self.productLine), Time.now())
    print("self.productList"..self.line,sprinttb(self.productList))

    local power, limit = 0,0;	
    local reward = 0;
    if manor_store_data and manor_store_data.today_reward and manor_store_data.lastday == Time.day() then
        reward = manor_store_data.today_reward;
    end
    local view = self.view;
    local effect_prop = {};

    local sold_count = 0
    for k,v in pairs(self.productLine.orders) do
        if self.productList[v.gid] then
            if v.left_count > 0 then
                sold_count = sold_count + v.left_count;
                local item = nil;
                if self.item_UI[v.gid] == nil then
                    local obj = UnityEngine.Object.Instantiate(view.bottom.good.Viewport.Content.IconFrame.gameObject);
                    obj.transform:SetParent(view.bottom.good.Viewport.Content.gameObject.transform,false);
                    obj:SetActive(true);
                    obj.name = "gid"..v.gid;
                    item = CS.SGK.UIReference.Setup(obj);
                    -- local cfg = ItemHelper.Get(self.productList[v.gid].consume[1].type, self.productList[v.gid].consume[1].id);
                    -- item[SGK.newItemIcon]:SetInfo(cfg);
                    self.item_UI[v.gid] = item;
                else
                    item = self.item_UI[v.gid];
                end
                -- item[SGK.newItemIcon].Count = v.left_count * self.productList[v.gid].consume[1].value;
                utils.IconFrameHelper.Create(item,{type = self.productList[v.gid].consume[1].type, id = self.productList[v.gid].consume[1].id, count = v.left_count * self.productList[v.gid].consume[1].value});
            elseif self.item_UI[v.gid] then
                self.item_UI[v.gid]:SetActive(false);
            end
        end
    end

    self.free = (sold_count == 0);

    for i=1,4 do        
        local worker_item = self.view.bottom.workers["worker"..i];
        if self.productLine.worker[i] ~= 0 then
            workerNum = workerNum + 1;
            local hero = self.manager:GetByUuid(self.productLine.worker[i]);
            local worker = self.manorProductInfo:GetWorkerInfo(self.productLine.worker[i],1);
            local worker_event = self.manorProductInfo:GetWorkerInfo(self.productLine.worker[i],3);
            if hero then
                if worker_event and worker_event.outside then
                    view.top.content["character"..i]:SetActive(false);
                else
                    local animation = view.top.content["character"..i].spine[CS.Spine.Unity.SkeletonGraphic];
                    self:LoadAnimaion(animation, hero.mode, function ()
                        view.top.content["character"..i].spine[SGK.DialogSprite].idle = true;
                        -- view.top.content["character"..i].spine[SGK.DialogSprite]:SetDirty();
                        if sold_count > 0 then
                            -- view.top.content["character"..i].spine[SGK.DialogSprite].direction = direction[i] or 0;
                            view.top.content["character"..i].Label.qipao:SetActive(true);
                            view.top.content["character"..i].Label.qipao[UnityEngine.CanvasGroup]:DOFade(1,0.5);
                        else
                            -- view.top.content["character"..i].spine[SGK.DialogSprite].direction = 0;
                            view.top.content["character"..i].Label.qipao:SetActive(false);
                        end
                    end);	
                    view.top.content["character"..i]:SetActive(true);
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
                    self:LoadAnimaion(animation, hero.mode, function ()
                        -- animation.AnimationState:SetAnimation(0,"idle1",true);
                        animation.startingAnimation = "idle1";
	                    animation.startingLoop = true;
                    end);

                    worker_item.character:SetActive(true);
                    worker_item.click.plus:SetActive(false);
                    worker_item.info.prop:SetActive(true);
                end
            else
                ERROR_LOG(self.productLine.worker[i].." hero not found");
                view.top.content["character"..i]:SetActive(false);
            end
        else
            view.top.content["character"..i]:SetActive(false);
            worker_item.character:SetActive(false);
            worker_item.click.plus:SetActive(true);
            worker_item.info.prop:SetActive(false);
        end
    end

    if power ~= 0 and limit ~= 0 then
        powerNum = power/limit;
    else
        emptyPower = true;
        powerNum = 0;
    end

    
    view.bottom.good.Text:SetActive(self.free);
    view.top.info.count[CS.UnityEngine.UI.Text].text = tostring(reward);
    view.bottom.effect.effect1[CS.UnityEngine.UI.Text]:TextFormat("{0}{1} <color=#FFD731FF>(销售时间缩短为: {2}%)</color>",ManorModule.GetManorWorkType(501).work_type, effect_prop[501] or 0, math.floor(self.productLine.effect_time * 100));
    view.bottom.effect.effect2[CS.UnityEngine.UI.Text]:TextFormat("{0}{1} <color=#FFD731FF>(商品单价提升为: {2}%)</color>",ManorModule.GetManorWorkType(502).work_type, effect_prop[502] or 0, math.floor(self.productLine.effect_gather * 100));
    --view.bottom.effect.Text[CS.UnityEngine.UI.Text]:TextFormat("<color=#FFD731FF>矿产量提升为: {0}%</color>", math.floor(self.productLine.effect_gather * 100));
    view.top.info.Slider[CS.UnityEngine.UI.Slider].value = powerNum;
    view.top.info.num[CS.UnityEngine.UI.Text].text = math.ceil(powerNum * 100).."%";

    if workerNum == 0 then
        view.bottom.make[CS.UGUISelectorGroup].index = 4;
        -- SetButtonStatus(false, view.bottom.make, nil, true);
    else
        view.bottom.make[CS.UGUISelectorGroup].index = 1;
        -- SetButtonStatus(true, view.bottom.make);
    end


    ShopModule.Query(32);
    self:CheckHangoutMan();
    self:CheckVisitor();
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



function View:LoadAnimaion(animation,mode,callback, type)
    type = type or 1;
    if type == 1 then
        local resource = SGK.ResourcesManager.Load("roles_small/"..mode.."/"..mode.."_SkeletonData.asset") or SGK.ResourcesManager.Load("roles_small/11001/11001_SkeletonData.asset");
        animation.skeletonDataAsset = resource;
    elseif type == 2 then
        local resource = SGK.ResourcesManager.Load("manor/qipao/"..mode.."_SkeletonData.asset");
        animation.skeletonDataAsset = resource;
    end
	-- animation:Initialize(true);	
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

function View:ShowDrink(worker_item, idx)
    if worker_item.qipao.activeSelf then
        self:UpdateQipao(idx,5);
        StartCoroutine(function ()
            WaitForSeconds(math.random(2,3))
            self:UpdateQipao(idx,idx);
            self.worker_pause[idx] = false;
        end)
    else
        self:UpdateQipao(idx,5);
        worker_item.qipao:SetActive(true);
        worker_item.qipao[UnityEngine.CanvasGroup]:DOFade(1,1):OnComplete(function ()
            worker_item.qipao[UnityEngine.CanvasGroup]:DOFade(0,1):OnComplete(function ()
                self:UpdateQipao(idx,idx);
                worker_item.qipao:SetActive(false);
                self.worker_pause[idx] = false;
            end):SetDelay(math.random(2,3));
        end)
    end
end

function View:Update()
	if self.productLine and  self.productLine.next_gather_time and self.productLine.next_gather_time ~= 0  then
		local time = self.productLine.next_gather_time - Time.now();
		--print("time",self.productline.next_gather_time, Time.now(),time)
		if time == 0 and not self.gathering then
			self.gathering = true;
			self.manorProductInfo:Gather(31);
		elseif time < 0 then
			return;
		end
    end

    --喝水事件
    if Time.now() >= self.drink_time then
        self.drink_time = Time.now() + math.random(15, 30);
        for i,v in ipairs(self.productLine.worker) do
            if v ~= 0 then
                local hero = self.manager:GetByUuid(v);
                local life_cfg = ManorModule.GetManorLifeConfig(hero.id, 6);
                if (self.free and life_cfg.unworking_rate >= math.random(1,100)) or (not self.free and life_cfg.working_rate >= math.random(1,100)) then
                    self.worker_pause[i] = true;
                    local worker_item = self.view.top.content["character"..i].Label;
                    if worker_item.dialogue[UnityEngine.CanvasGroup].alpha > 0 then
                        self.speak_end[i] = function ()
                            self:ShowDrink(worker_item, i);
                        end;
                    else
                        self:ShowDrink(worker_item, i);
                    end
                end
            end
        end
    end

    --小人移动
    if Time.now() >= self.update_time2 + 1 then
        self.update_time2 = Time.now();
        for i,v in pairs(self.character) do
            if v.node and v.node.gameObject and v.node.gameObject.activeSelf and Time.now() >= v.nextMoveTime then
                self.character[i].nextMoveTime = Time.now() + 100;
                local next_pos = v.pos + 1;
                if next_pos > v.max then
                    next_pos = 1;
                end
                self.character[i].pos = next_pos;
                self.controller:MoveCharacter(v.id, v.name..next_pos, function ()
                    self.character[i].nextMoveTime = Time.now() + math.random(2, 5);
                end);
            end
        end
    end

    --工人移动
    if Time.now() >= self.worker_move_time then
        self.worker_move_time = Time.now() + math.random(2,5);
        local _worker = {};
        for i,v in ipairs(self.worker) do
            if v.node and v.node.gameObject and v.node.gameObject.activeSelf and not self.worker_pause[i] then
                table.insert(_worker, {info = v, idx = i});
            end
        end
        if #_worker ~= 0 then
            local select = _worker[math.random(1, #_worker)];
            local next_pos = select.info.pos + 1;
            if next_pos > select.info.max then
                next_pos = 1;
            end
            self.worker[select.idx].pos = next_pos;
            self.controller:MoveCharacter(select.info.id, select.info.name..next_pos);
        end
    end

    -- if Time.now() > self.character.nextMoveTime then
    --     self.character.nextMoveTime = Time.now() + math.random(5,10)
    --     local pos = "npc"..math.random(1,4);
    --     self.controller:MoveCharacter(1,pos);
    -- end

    --小人说话
	if self.productLine.worker and self.talk_num < MAX_TALK and Time.now() >= self.update_time then
		local worker_pos = {};
		for i,v in ipairs(self.productLine.worker) do
			if v ~= 0 then
				table.insert( worker_pos, {type = 1, pos = i});
			end
		end
        
        if self.view.top.content.npc.gameObject.activeSelf then
            table.insert( worker_pos, {type = 2, pos = 5});
        end

        for k,v in pairs(self.outside_man) do
            table.insert( worker_pos, {type = 3, id = k});
        end

        for k,v in pairs(self.visitor) do
            table.insert( worker_pos, {type = 4, id = k});
        end

        if #worker_pos ~= 0 then
            local info = worker_pos[math.random(1,#worker_pos)];
            self.update_time = Time.now() + math.random(4,8);
            if info.type == 2 then --流浪商人
                local talk_cfg = ManorModule.GetManorChat(0, self.line, info.pos);
                assert(talk_cfg,"0 "..self.line.." "..info.pos.." chat config not found");
                self.talk_num = self.talk_num + 1;
                local str = self.free and talk_cfg.blank_words[math.random(1,#talk_cfg.blank_words)] or  talk_cfg.working_words[math.random(1,#talk_cfg.working_words)];
                local npc = self.view.top.content.npc;
                self:ShowNpcDesc(npc.Label, str, math.random(1,3),function () 
                    self.talk_num = self.talk_num - 1;
                end)
            elseif info.type == 3 then --访客
                local uuid = info.id;
                local hero = self.manager:GetByUuid(uuid);
                if hero then
                    local talk_cfg = ManorModule.GetManorChat2(hero.id);
                    assert(talk_cfg,hero.id.." chat2 config not found");
                    self.talk_num = self.talk_num + 1;
                    local str = talk_cfg.hanging_out[math.random(1,#talk_cfg.hanging_out)];
                    local npc = self.outside_man[uuid];
                    self:ShowNpcDesc(npc.Label, str, math.random(1,3),function () 
                        self.talk_num = self.talk_num - 1;
                    end)
                end
            elseif info.type == 4 then --外来访客
                local gid = info.id;
                local cfg = self.visitorConfig[gid];
                if cfg then
                    self.talk_num = self.talk_num + 1;
                    local str = cfg["hanging_out"..math.random(1,2)];
                    local npc = self.visitor[gid];
                    self:ShowNpcDesc(npc.Label, str, math.random(1,3),function () 
                        self.talk_num = self.talk_num - 1;
                    end)
                end
            elseif info.type == 1 then --工人
                local hero = self.manager:GetByUuid(self.productLine.worker[info.pos]);
                if hero and not self.worker_pause[info.pos] then
                    local talk_cfg = ManorModule.GetManorChat(hero.id, self.line, info.pos);
                    assert(talk_cfg,hero.id.." "..self.line.." "..info.pos.." chat config not found");
                    self.talk_num = self.talk_num + 1;
                    local str = self.free and talk_cfg.blank_words[math.random(1,#talk_cfg.blank_words)] or  talk_cfg.working_words[math.random(1,#talk_cfg.working_words)];
                    local npc = self.view.top.content["character"..info.pos];
                    self:ShowNpcDesc(npc.Label, str, math.random(1,3),function () 
                        self.talk_num = self.talk_num - 1;
                        if self.speak_end[info.pos] then
                            print("说话结束")
                            self.speak_end[info.pos]();
                            self.speak_end[info.pos] = nil;
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
    npc_view.dialogue.desc[UnityEngine.UI.Text].text = desc

    if npc_view.qipao and npc_view.qipao.activeSelf then
        npc_view.qipao[UnityEngine.CanvasGroup]:DOFade(0,0.5):OnComplete(function()
            npc_view.dialogue[UnityEngine.CanvasGroup]:DOFade(1,1):OnComplete(function()
                npc_view.dialogue[UnityEngine.CanvasGroup]:DOFade(0,1):OnComplete(function()
                    npc_view.dialogue.desc[UnityEngine.UI.Text].text = "";
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
                npc_view.dialogue.desc[UnityEngine.UI.Text].text = "";
                if fun then
                    fun()
                end
            end):SetDelay(1)
        end)
    end
end

function View:listEvent()
	return {
		"MANOR_SHOP_OPEN",
        "MANOR_MANUFACTURE_PRODUCT_LINE_CHANGE",
        "MANOR_NPC_START_MOVE",
        "MANOR_NPC_END_MOVE"
	}
end

function View:onEvent(event, ...)
	print("onEvent", event, ...);
    if event == "MANOR_SHOP_OPEN"  then
        print("商店开启")
        self.view.top.content.npc:SetActive(true);
    elseif event == "MANOR_MANUFACTURE_PRODUCT_LINE_CHANGE" then
        if self.gathering then
            self.gathering = false;
        end
        self:RefreshFrame();
    elseif event == "MANOR_NPC_START_MOVE" then
        local data = ...;
        if data.from == "store" then
            if data.type == "outside" and  self.outside_man[data.id] and self.outside_man[data.id].gameObject.activeSelf then
                self.outside_man[data.id][UnityEngine.CanvasGroup]:DOFade(0,0.5):OnComplete(function ()
                    self.outside_man[data.id]:SetActive(false);
                    self.outside_man[data.id].gameObject.transform:SetSiblingIndex(3);
                    self.controller:SetPoint(0, "fangke1")
                    self.outside_man[data.id] = nil;
                end);
            elseif data.type == "visit" and  self.visitor[data.id] and self.visitor[data.id].gameObject.activeSelf then
                self.visitor[data.id][UnityEngine.CanvasGroup]:DOFade(0,0.5):OnComplete(function ()
                    self.visitor[data.id]:SetActive(false);
                    self.visitor[data.id].gameObject.transform:SetSiblingIndex(3);
                    self.controller:SetPoint(6, "wfangke1")
                    self.visitor[data.id] = nil;
                end);
            end
        end
    elseif event == "MANOR_NPC_END_MOVE" then
        local data = ...;
        if data.to == "store" then
            self:ShowCharacter(data.id, false, data.type)
        end
	end
end

return View;