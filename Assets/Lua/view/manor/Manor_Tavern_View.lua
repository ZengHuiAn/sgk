local ManorManufactureModule = require "module.ManorManufactureModule"
local ItemHelper = require "utils.ItemHelper"
local HeroModule = require "module.HeroModule"
local ManorModule = require "module.ManorModule"
local Time = require "module.Time"
local TipConfig = require "config.TipConfig"
local UserDefault = require "utils.UserDefault"

local MAX_COUNT = 5;
local MOVEPOINT_COUNT = 9

local View = {};

function View:OnPreload(data)
    self.update_time = 0;
    self.character = {};
    self.npc = {next_move_time = Time.now() + math.random(5,10), pos = 1};
end

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
    self.manorInfo = ManorModule.LoadManorInfo();
    self.manorProductInfo:GetProductLineFromServer();
    self.manorProductInfo:QueryTask();
    self.manager = HeroModule.GetManager();
    self.begin_task = {}; 
    self.end_task = {};
    self.init = false;
    self.taskTeam = {};
    self.haveTeam = 0;
    self.movePoint = {};
    for i=1,MOVEPOINT_COUNT do
        self.movePoint[i] = 1;
    end
end

function View:InitView()
    self.controller = self.view.top.content[SGK.DialogPlayerMoveController];
    self.controller:Add(0, self.view.top.content.npc.gameObject);
    CS.UGUIClickEventListener.Get(self.view.BG.gameObject, true).onClick = function (obj)        
        self:SaveData();
        DialogStack.Pop();
    end
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
        utils.SGKTools.ShowDlgHelp(TipConfig.GetAssistDescConfig(55001).info, nil, self.dialog)
    end 
    CS.UGUIClickEventListener.Get(self.view.top.dispatch.gameObject).onClick = function (obj)        
        DialogStack.PushPrefStact("manor/Manor_Task_Dispatch");
    end   
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
    animation.skeletonDataAsset = utils.SGKTools.loadExistSkeletonDataAsset("roles_small/", id, mode,"_SkeletonData.asset");
    animation:Initialize(true);	
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
        module.RedDotModule.GetStatus(module.RedDotModule.Type.Manor.Tavern, nil, self.view.top.dispatch.red)
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
	end
end

return View;