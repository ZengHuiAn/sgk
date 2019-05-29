local View = {}
local expModule = require "module.expModule"
local Time = require "module.Time"


local function date(now)
    local now = now or Time.now();
    return os.date ("!*t", now + 8 * 3600);
end

local function get_timezone()
    local now = os.time()
    return os.difftime(now, os.time(os.date("!*t", now)))/3600
end

local function getTimeByDate(year,month,day,hour,min,sec)

   local east8 = os.time({year = year, month = month, day = day, hour = hour, min = min, sec = sec})+ (get_timezone()-8) * 3600
   return east8
end

local function getTimeHMS(time)
    local H = math.floor(time /3600);
    time = math.fmod(time ,3600)
    local M = math.floor(time/60);
    time = math.fmod(time ,60)
    local S = time
    return H,M,S
end

local start_time = getTimeByDate(2018,6,1,5,0,0);

local duration = 19*3600;

local period = 24*3600;

local MoraleSpeed = {
	{speed = 0.5},
	{speed = 0.5},
	{speed = 0.5},
}

function View:Update()

	if self.time then
		if self.time>0 then
			self.time = self.time - UnityEngine.Time.deltaTime;
		else
			self.time = nil;
			self:WaitDone();
		end
	end

	if self.start_time then

		local time = self.end_time - Time.now();
		local H,M,S = getTimeHMS(time);

		if time < 0 then
			DialogStack.Pop();
		end

		
	end

	if self.dur_time then
		local inter_time = self.dur_time - Time.now();

		if inter_time < 0 then
			self.dur_time = nil;
			self:FreshTips();
			self:FreshHeroInfo();
			
		end
	end
	
end

function View:FreshTips( ... )

	-- print(self.dur_time)
	if not self.dur_time then
		self.current = expModule.GetCurrent();

		if self.current >15 then
			
		else
			self.view.content.flag.gameObject:SetActive(true);
			self.view.content.flag.Text[UI.Text].text = "活动已结束"
			self:FreshStatus(false);
		end
	end
end

function View:FreshStatus(flag)
	-- ERROR_LOG(flag);
	self.view.content.Morale.gameObject:SetActive(flag or false);
	self.view.content.Change.gameObject:SetActive(flag);	
end

function View:WaitDone()
	ERROR_LOG("结束========");
	self.view.mirror.fx_mirror_start.gameObject:SetActive(false);
end


function View:FreshStartEffect( ... )
	self.view.mirror.fx_mirror_start.gameObject:SetActive(true);
	self.time = 1.2;
end

local function GetTime(_end)
	return (math.floor((Time.now() - start_time)/period + (_end and 1 or 0))) * period + start_time;
end 

function View:DownHero( ... )
	local cutList = module.expModule.GetCutList();
	local new_list = nil
	for k, v in ipairs(module.HeroModule.GetManager():GetFormation()) do
		if v ~= 11000 then
			if cutList[v] and cutList[v] == 0 then
				v = 0;
				new_list = new_list or {}
				new_list[k] = 0
			else
				new_list = new_list or {}
				new_list[k] = v
			end
		else
			new_list = new_list or {}
			new_list[k] = v
		end
	end

	module.HeroModule.GetManager():SetFormation(new_list);
	
end

function View:FreshEndTime()
	self.start_time = GetTime();

	self.end_time = GetTime(true);

	self.dur_time = self.start_time + duration;

	if self.dur_time < Time.now() then
		self.dur_time = nil;
		self:FreshTips();
	end

	-- ERROR_LOG("当前周期开始时间",self.start_time,self.end_time,Time.now());
end
function View:Start(data)
	self.root = SGK.UIReference.Setup(self.gameObject)
	self.view = self.root.bg;
	local init_obj = CS.UnityEngine.GameObject.Instantiate(SGK.ResourcesManager.Load("prefabs/base/CurrencyChat.prefab"), self.view.transform);

	

	self:SetOnClick();
	self:ResetEffect();
	expModule.GetPrepare();

	self.view.mirror.fx_mirror_start.gameObject:SetActive(true);
	self.time = 1.2;
 


	self.current = expModule.GetCurrent();
	self.SelfBuffList = {};
	self.foeBuffList = {};

	self:FreshGhost();

	self.current = expModule.GetCurrent();
	self:FreshProgess();

	self.ourBuff = self.view.content.desc.ouritem;
	self.ourBuff.gameObject:SetActive(false);
	self.foeBuff = self.view.content.desc.foeitem;
	self.foeBuff.gameObject:SetActive(false);

	for i=1,2 do
		local obj = CS.UnityEngine.GameObject.Instantiate(self.ourBuff.gameObject, self.view.content.desc.gameObject.transform);
		obj.gameObject:SetActive(false);
		self.SelfBuffList[i] = obj;
	end


	for i=1,2 do
		local obj = CS.UnityEngine.GameObject.Instantiate(self.foeBuff.gameObject, self.view.content.desc.gameObject.transform);
		obj.gameObject:SetActive(false);
		self.foeBuffList[i] = obj;
	end

	self:QueryBoxInfo();
	self:FreshBuffList();

	self:FreshEndTime();
	self:initGuide()
end

function View:initGuide()
    module.guideModule.PlayByType(127,0.1)
end

function View:QueryBoxInfo()
	expModule.QueryBoxInfo();
end

local Desc = {
	{tip = "得到buff" ,UI= "expOnline/expHappen" },
	{tip ="给敌人加buff",UI= "expOnline/expHappen"  },
	{tip ="得到奖励"},
	{tip ="跳过本轮" },
}


function View:GetRandomStory(list)
	list = list or {};
	-- ERROR_LOG("对话数据",sprinttb(list or{}));
	math.randomseed(module.Time.now());
	local current = math.random(#list);

	return list[current];
end


function View:FreshPlayerNode(mode)
	local playerNode = self.view.content.Hero.bossModeRoot.bossMode;
	
	mode = mode or 11048;
	playerNode.gameObject.transform.localScale = UnityEngine.Vector3(1.5,1.5,1.5)
	-- print("角色形象",mode);
	local _obj = playerNode.gameObject;
    local _boss = playerNode[CS.Spine.Unity.SkeletonGraphic];

    local path = "roles_small/";
    -- print(path..cfg.mode.."/"..cfg.mode.."_SkeletonData");
    local _dataAsset = SGK.ResourcesManager.Load(path..mode.."/"..mode.."_SkeletonData.asset")

    if _dataAsset then
    	_boss.skeletonDataAsset = _dataAsset
        _boss:Initialize(true)
        _boss.startingLoop = true
        
		_boss.AnimationState:SetAnimation(0, "idle1", true)
	else
		_boss.skeletonDataAsset = nil;
		-- ERROR_LOG("not exits spine",mode);
	end
	playerNode.gameObject:SetActive(true);

end

--刷新敌人信息

function View:FreshHeroInfo(pid)

	self.current = expModule.GetCurrent();

	-- print(self.dur_time);
	if not self.dur_time then
		self.view.content.Hero.bossModeRoot.bossMode.gameObject:SetActive(false);
		-- ERROR_LOG("刷新玩家");
		return;
	end

	if self.current >15 then
		self.view.content.Hero.bossModeRoot.bossMode.gameObject:SetActive(false);
		return
	end
	local battle = expModule.GetBattle();
	if not battle then
		return
	end
	-- ERROR_LOG("战斗信息",battle.pid);
	-- getPlayer(pid,callback,init)
	-- QueryPlayerAddData(pid,type,func,Reget)

	local ActorShow = 11048;
	if battle.pid <= 500000 then
		local playerdata = module.traditionalArenaModule.GetNpcCfg(battle.pid)
		-- ERROR_LOG(sprinttb(playerdata));
		if playerdata then

			ActorShow = playerdata.icon;
		end
	else
		local data = utils.PlayerInfoHelper.GetPlayerAddData(battle.pid,99);
		if data then
			ActorShow = data.ActorShow;
		end
	end

	self:FreshPlayerNode(ActorShow);
end

function View:FreshGhost()
	local data = expModule.GetGhostsData();
	-- ERROR_LOG( sprinttb(data) );
	for i=1,#data do
		-- print("====")
		self.view.ghosts["ghost"..i][CS.UGUIClickEventListener].onClick = function ()
			-- print(i);
			self:CloseBuff();
			self:PointGhost(i);
			self:InterGhosts(i);
			self.view.ghosts["ghost"..i].gameObject:SetActive(false);
		end
	end
end

local ghostConfig = {
	19205,
	19206,
	19205,
}
function View:FreshSpine( item,index )

	local playerNode = item.bossModeRoot.bossMode;
	local mode = ghostConfig[index]

	playerNode.gameObject.transform.localScale = UnityEngine.Vector3(1.2,1.2,1.2)
	-- print("角色形象",mode);
    local _boss = playerNode[CS.Spine.Unity.SkeletonGraphic];

    local path = "roles/";
    -- print(path..cfg.mode.."/"..cfg.mode.."_SkeletonData");
    local _dataAsset = SGK.ResourcesManager.Load(path..mode.."/"..mode.."_SkeletonData.asset")

    if _dataAsset then
    	_boss.skeletonDataAsset = _dataAsset
        _boss:Initialize(true)
        _boss.startingLoop = true
        
		_boss.AnimationState:SetAnimation(0, "idle", true)
	else
		_boss.skeletonDataAsset = nil;
		-- ERROR_LOG("not exits spine",mode);
	end
	playerNode.gameObject:SetActive(true);
end

function View:ResetEffect()
	for i=1,3 do
		local ghost = self.view.ghosts["ghost"..i];
		local item = self.view.effects["fx"..i];

		self:FreshSpine(ghost,i);
		item[UnityEngine.RectTransform].anchoredPosition = ghost[UnityEngine.RectTransform].anchoredPosition;

		item.fx_exp_lizi_touch.gameObject:SetActive(false);
		item.fx_exp_lizi_hit.gameObject:SetActive(false);
		item.fx_exp_lizi.gameObject:SetActive(false);
	end
end

function View:PointGhost(index)
	-- print("点击")
	local item = self.view.effects["fx"..index];
	item.fx_exp_lizi_touch.gameObject:SetActive(true);
	item.fx_exp_lizi.gameObject:SetActive(true);
end


function View:MoveGlass(index,func)
	local item = self.view.effects["fx"..index];
	
	item.fx_exp_lizi.gameObject:SetActive(true);
	item[UnityEngine.RectTransform]:DOLocalMove(UnityEngine.Vector3(0,150,0),MoraleSpeed[index].speed):OnComplete(function ( ... )
		item.fx_exp_lizi_hit.gameObject:SetActive(true);
		
		item.fx_exp_lizi.gameObject:SetActive(false);
		func();
	end);
end

function View:InterGhosts( index )
	SetItemTipsStateAndShowTips(false);
	expModule.InterGhosts(index,function (_data)
		if _data[2] == 0 then
			local gid = _data[4][1];
			local cfg = expModule.GetBuffConfig(gid);
			local story = self:GetRandomStory(cfg.storys);

			LoadStory(story,nil,nil,nil,function()
				-- print("=====>>>")
				self:MoveGlass(index,function ( ... )
					-- self:GetFreshData();

					self:FreshGhost();
					-- self:FreshData();

					if _data[3] == 1 then
						--查询自己的buff
						self:QueryBuffInfo();
					elseif _data[3] == 2 then
						self:QueryBuffInfo(true);
					elseif _data[3] == 4 then
						--跳过本轮
						expModule.GetPrepare();
					end

					-- self:FreshProgess();
					if Desc[_data[3]].UI then
						DialogStack.PushPrefStact(Desc[_data[3]].UI,{type = _data[3],value = _data[4]});
					else
						SetItemTipsStateAndShowTips(true);
						
						showDlgError(nil,Desc[_data[3]].tip);
						self:ResetEffect();
					end
				end);
			end)
		else
			-- ERROR_LOG("交互失败");

		end
	end);
end

function View:FreshBoxStatus(info)
	-- ERROR_LOG("宝箱数据",sprinttb(info));

	for i=1,5 do
		local item = self.view.activeNode.rewardList["item"..i];
		
		if self.current > i*3 then
			if not info[i] or info[i] ==0 then
				item[CS.UGUISpriteSelector].index = 1;
				item.fx_item_reward.gameObject:SetActive(true);
			elseif info[i][2] == 1 then
				item.fx_item_reward.gameObject:SetActive(false);
				item[CS.UGUISpriteSelector].index = 0;
			end
		else
			item.fx_item_reward.gameObject:SetActive(false);
			item[CS.UGUISpriteSelector].index = 2;
		end
	end
end

function View:OnDestroy( ... )
	SetItemTipsStateAndShowTips(true);
end

function View:FreshGhostStatus()
	local ghosts = expModule.GetGhostsData();
	-- ERROR_LOG(sprinttb(ghosts));
	for i=1,3 do
		local v = ghosts[i];
		if  not v or (v and v[2] == 1) then

			if not v then
				self.view.ghosts["ghost"..i].gameObject:SetActive(false);
			else
				if self.view.ghosts["ghost"..v[1]].gameObject.activeInHierarchy == true then
					self.view.ghosts["ghost"..v[1]].gameObject:SetActive(false);
				end
			end
			
		else
			if self.view.ghosts["ghost"..i].gameObject.activeInHierarchy == false then
				self.view.ghosts["ghost"..i].gameObject:SetActive(true);
			end
		end
	end
end

--flag true 敌方  flag false 我方
function View:QueryBuffInfo(flag)
	expModule.QueryBuffInfo(flag);
end

function View:FreshHero()
	self.online = {};
	for k, v in ipairs(module.HeroModule.GetManager():GetFormation()) do
		self.online[k] = v or 0;
	end
end

function View:SetOnClick()


	self.root.mask[CS.UGUIClickEventListener].onClick = function ( ... )
		self:CloseBuff();
	end
	self.view.content.helpBtn[CS.UGUIClickEventListener].onClick = function ( ... )
		self:CloseBuff();
		utils.SGKTools.ShowDlgHelp(SGK.Localize:getInstance():getValue("yuanzheng_tip"))
	end
	--鼓舞士气
	self.view.content.Morale[CS.UGUIClickEventListener].onClick = function ()
		self:CloseBuff();

		if self.current >15 then
			return
		end
		self:ChangeMorale();
	end

	self.view.content.Hero.bossModeRoot.bossMode[CS.UGUIClickEventListener].onClick = function ()
		self:CloseBuff();
		self.current = expModule.GetCurrent();
		if self.current >15 then
			return
		else
			DialogStack.PushPrefStact("expOnline/expBattle");
		end
	end
	--更换对手
	self.view.content.Change[CS.UGUIClickEventListener].onClick = function ()
		self:CloseBuff();
		self.current = expModule.GetCurrent();
		if self.current >15 then
			return;
		end
		-- print("更换对手");
		local count = expModule.GetChangeCount(); 
		local cfg = expModule.GetConsumeConfig(2,count+1);

		if not cfg then
			showDlgError(nil,"更换对手次数用尽");
			return;
		end

		local item_cfg = module.ItemModule.GetConfig(cfg.consume_id);
		-- ERROR_LOG(sprinttb(item_cfg));

		DlgMsg({msg = "是否消耗<color=red>"..item_cfg.name..cfg.consume_value.."</color>进行更换对手", confirm = function ( ... )
			local _count = module.ItemModule.GetItemCount(cfg.consume_id);

			_count = _count or 0;
			if _count >= tonumber(cfg.consume_value) then

				expModule.ChangeEnemy();

			else
				showDlgError(nil,item_cfg.name.."不足!");
			end

			end,cancel = function ( ... )
				
			end, txtConfirm = "确定",txtCancel = "取消",title = "更换对手"})

	end

	self.view.content.Effect[CS.UGUIClickEventListener].onClick = function ()
		if self.view.content.desc.gameObject.activeInHierarchy == true then
			self.view.content.desc.gameObject:SetActive(false);
			self.view.content.tag.gameObject:SetActive(false);
		else
			self.view.content.desc.gameObject:SetActive(true);
			self.view.content.tag.gameObject:SetActive(true);
			self:FreshBuffList();
		end
		
	end
end
 -- 鼓舞士气
function View:ChangeMorale()
	local count = expModule.GetChangeBuffCount();	
		local cfg = expModule.GetConsumeConfig(1,count+1);

		if not cfg then
			showDlgError(nil,"鼓舞士气次数用尽");
			return;
		end

		local item_cfg = module.ItemModule.GetConfig(cfg.consume_id);

		DlgMsg({msg = "是否消耗<color=red>"..item_cfg.name..cfg.consume_value.."</color>进行鼓舞士气\n增加15%攻击(持续全场)", confirm = function ( ... )
			local _count = module.ItemModule.GetItemCount(cfg.consume_id);
			_count = _count or 0;

			-- ERROR_LOG(_count,cfg.consume_value);
			if _count > tonumber(cfg.consume_value) then
				expModule.GetMorale(function (err)
					showDlgError(nil,err==0 and "鼓舞士气成功" or "鼓舞士气失败");
				end);
			else
				showDlgError(nil,item_cfg.name.."不足!");
			end

			end,cancel = function ( ... )
				
			end, txtConfirm = "确定",txtCancel = "取消",title = "鼓舞士气"})
end

function View:CloseBuff()
	self.view.content.desc.gameObject:SetActive(false);
	self.view.content.tag.gameObject:SetActive(false);
end

function View:FreshBuffItem(item,buff)
	local buff_view = SGK.UIReference.Setup(item);

	if buff.id == 0 then
		local config = expModule.GetBuffConfig(buff.id);
		buff_view.Text[UI.Text].text = (buff.id == 0 and "攻击增加"..15*(buff.value +1).."%" or config.desc).. (buff.id == 0 and "(持续全场)" or ("(持续"..buff.value.."场)"));

		buff_view.icon[UI.Image]:LoadSprite("icon/buff/"..config.icon)

		return
	end

	buff_view.Text[UI.Text].text = ( buff.desc..math.floor(buff.rate)..buff.status.. ("(持续"..buff.value.."场)"));

	buff_view.icon[UI.Image]:LoadSprite("icon/buff/"..buff.icon)
	
end

function View:FreshBuffEffect(flag)
	
end

function View:FreshBuffList()
	local lenth = #(self.buff or {}) + #(self.enemyBuff or {}) + 2; 
	-- ERROR_LOG("刷新buff");

	self.view.content.desc[UnityEngine.RectTransform].sizeDelta = UnityEngine.Vector2(393,55*lenth+18);

	for k,v in pairs(self.SelfBuffList) do
		v.gameObject:SetActive(false);
	end

	for k,v in pairs(self.foeBuffList) do
		v.gameObject:SetActive(false);
	end
	local flag = nil;
	-- ERROR_LOG(table.maxn(self.buff or {}),sprinttb(self.buff or {}));

	if self.buff then
		for k,v in pairs(self.buff) do
			if v.id ~=0 then
				flag = true;
			end
		end
	end
	-- print(flag);
	self.view.mirror.mirror_buff.gameObject:SetActive(flag);
	if self.buff then


		for i=1,#self.buff do
			local itemBuff = self.buff[i];
			local obj = self.SelfBuffList[i];
			-- ERROR_LOG(obj);
			if obj == nil then
				 obj = CS.UnityEngine.GameObject.Instantiate(self.ourBuff.gameObject, self.view.content.desc.gameObject.transform);
				 self.SelfBuffList[i] = obj;
			end
			-- ERROR_LOG(sprinttb(itemBuff));
			obj.gameObject:SetActive(true);

			obj.gameObject.transform:SetSiblingIndex(2);
			--填充数据
			self:FreshBuffItem(obj,itemBuff);
		end
	end
	if self.enemyBuff then

		for i=1,#self.enemyBuff do
			local itemBuff = self.enemyBuff[i];
			local obj = self.foeBuffList[i];
			if obj == nil then
				 obj = CS.UnityEngine.GameObject.Instantiate(self.foeBuff.gameObject, self.view.content.desc.gameObject.transform);
				 self.foeBuffList[i] = obj;
			end
			obj.gameObject:SetActive(true);
			obj.gameObject.transform:SetAsLastSibling();
			--填充数据
			self:FreshBuffItem(obj,itemBuff);
		end
	end
end

function View:FreshProgess()
	self.current = expModule.GetCurrent();
	self.view.activeNode.Slider[UI.Slider].value = self.current - 1;
	self.view.activeNode.number[UI.Text].text = self.current - 1;

	if self.current == 16 then
		self.view.activeNode.lun:SetActive(false);
	end
	self.view.activeNode.lun[UI.Text].text = string.format(SGK.Localize:getInstance():getValue("yuanzheng_lun"),self.current)
	self:FreshButtenStatus();
	local quo = (self.current-1) /3 ;
	-- print(quo);
	for i=1,5 do
		local item = self.view.activeNode.rewardList["item"..i];
		if i>quo then
			item[CS.UGUIClickEventListener].onClick = function ()
				self:CloseBuff();
				--steps 当前点击的步数 flag 当前的步数是否超过当前级别的宝箱
				DialogStack.PushPrefStact("expOnline/expBoxReward",{steps = i,flag =true});
			end
		else
			item[CS.UGUIClickEventListener].onClick = function ()
				self:CloseBuff();
				DialogStack.PushPrefStact("expOnline/expBoxReward",{steps = i});
			end
		end
	end
end

function View:FreshButtenStatus( )
	if self.current >15 then
		self.view.content.Morale.gameObject:SetActive(false);
		self.view.content.Change.gameObject:SetActive(false);
		self.view.content.flag.gameObject:SetActive(true);
	end
end

function View:listEvent()
    return {
    	--交互影子结果
    	"GHOSTS_RESULT",
    	"GET_READY_DATA",
		"MORALE_SUCCUSS",
		"GET_BOX_REWARD",
		"EXP_CHANGE_SUCCUSS",
		"PLAYER_ADDDATA_CHANGE",
		"EXP_CHANGE_ENEMY",  --更换对手成功
		"EXP_QUERY_BUFF",   --查询buff返回
		"LOCAL_GUIDE_CHANE",
    }
end

function View:FreshCount( ... )
	local changeCount = expModule.GetChangeCount();
	local buffCount = expModule.GetChangeBuffCount();
	self.view.content.Morale.bg.Text[UI.Text].text = (10 - (buffCount or 0)).."/10";
	self.view.content.Change.bg.Text[UI.Text].text = (10 - (changeCount or 0)).."/10";

end

function View:FreshData()
	self.buff = expModule.GetSelfBuff();
	-- ERROR_LOG(sprinttb(self.buff));
	self.enemyBuff = expModule.GetEnemyBuff();
	
end
function View:onEvent(event,data)
	if event == "GET_READY_DATA" then
		--准备数据成功
		self:FreshData();
		self:FreshProgess();

		self:FreshGhostStatus();

		self:FreshGhost();
		self:FreshBuffList();
		self:FreshHeroInfo();
		self:FreshCount();
		local info = expModule.GetBoxInfo();
		self:DownHero();
		-- ERROR_LOG("查询以获取奖励",sprinttb(info));
		
		self:FreshBoxStatus(info);
	elseif event == "MORALE_SUCCUSS" then
		--鼓舞士气成功
		if data == 0 then
			--重新查询我方buff数据
			self:QueryBuffInfo();
			-- self:FreshData();

			self:FreshCount();
		end
	elseif event =="GET_BOX_REWARD" then
		local info = expModule.GetBoxInfo();
		-- ERROR_LOG("查询以获取奖励",sprinttb(info));

		self:FreshBoxStatus(info);
	elseif event == "EXP_CHANGE_SUCCUSS" then
		self:ResetEffect();
		self:FreshStartEffect();
	elseif event == "PLAYER_ADDDATA_CHANGE" then
		self:FreshHeroInfo(data);
	elseif event == "EXP_CHANGE_ENEMY" then

		if data == 0 then
			self:FreshStartEffect();
			self:FreshHeroInfo();
			self:FreshCount();
		else
			showDlgError("更换对手失败");
		end
	elseif event == "EXP_QUERY_BUFF" then
		self:FreshData();
		self:FreshBuffList();
	elseif event == "LOCAL_GUIDE_CHANE" then
        self:initGuide()
	end
end




return View;