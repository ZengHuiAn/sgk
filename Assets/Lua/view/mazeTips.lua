local View = {};
local mazeConfig = require "config.mazeConfig"
local mazeModule= require "module.mazeModule"
local Time = require "module.Time"
local ItemHelper = require "utils.ItemHelper"
local battle = require "config.battle"


local function getTimeHMS(time)
    local H = math.floor(time /3600);
    time = math.fmod(time ,3600)
    local M = math.floor(time/60);
    time = math.fmod(time ,60)
    local S = time

    if not time or time < 0 then
    	return 0,0,0;
    end
    return H,M,S
end

local function get_timezone()
    local now = os.time()
    return os.difftime(now, os.time(os.date("!*t", now)))/3600
end

local function getTimeByDate(year,month,day,hour,min,sec)

   local east8 = os.time({year = year, month = month, day = day, hour = hour, min = min, sec = sec})+ (get_timezone()-8) * 3600
   return east8
end

local function date(now)
    local now = now or Time.now();
    return os.date ("!*t", now + 8 * 3600);
end

function View:InitTips()
	-- print("tips",SGK.Localize:getInstance():getValue("maze_tip1"));

	self.uptips = self.uptips or {};
	for i=1,6 do
		self.uptips[i] = self.uptips[i] or {};
		self.uptips[i].id = i; 
		self.uptips[i].desc = SGK.Localize:getInstance():getValue("maze_tip"..i);
		self.uptips[i].lock = true;
	end

	-- ERROR_LOG("tips",sprinttb(self.uptips));
end


function View:ChangeLock(type)
	
	if type == 1 then
		self:InsertTips(self.uptips[4].desc);
		self:InsertTips(self.uptips[5].desc);
	elseif type == 2 then
		self:InsertTips(self.uptips[3].desc);
	elseif type == 3 then
		self:InsertTips(self.uptips[2].desc);
	else
		self:InsertTips(self.uptips[6].desc);
	end


end

function View:InsertTips(tips)
	if not self.unlock then
		self.unlock = self.unlock or {};
		table.insert(self.unlock,tips);
		return ;
	end


	for k,v in pairs(self.unlock) do
		if v == tips then
			return ;
		end
	end
	table.insert(self.unlock,tips);
end



function View:Start(data)
	self.view = SGK.UIReference.Setup(self.gameObject)
	self.Tips = nil;
	self.unlock = {};
	self:InitTips();--播放tips
	self.fresh = 0;
	--table.insert(self.unlock,self.uptips[1].desc);
	-- ERROR_LOG("提示信息",sprinttb(self.unlock));
	self.view.tips.Text[UI.Text].text = self.unlock[1];
	self.view.bg.content.gameObject.transform:DOLocalMoveX(-11,0.3):OnComplete(function ( ... )
      	self.Tips  = true;
    end);
	self.view.bg.content.title.title_image.btn[UI.Button].onClick:AddListener(function ()
		--如果是没有打开
		if not self.Tips then
			self.view.bg.content.gameObject.transform:DOLocalMoveX(-11,0.3):OnComplete(function ( ... )
              	self.Tips  = true;
            end);
		--如果打开了
		else
			self.view.bg.content.gameObject.transform:DOLocalMoveX(200,0.3):OnComplete(function ( ... )
              	self.Tips  = nil;
            end);
		end
	end);
	self.view.TipsBtn[UI.Button].onClick:AddListener(function ()
		utils.SGKTools.ShowDlgHelp(SGK.Localize:getInstance():getValue("maze"))
	end);
	self:UpdateMonsterCount();
	self:UpdateMazeCount();
	
	self.out_item = self.view.desc.ouritem;

	self.foe_item = self.view.desc.foeitem;

	self.this_startTime , self.end_time  = mazeModule.GetTime();

	if self.end_time and self.this_startTime then
		self.duration = self.end_time - self.this_startTime;
	end
	self.view.infoBtn:SetActive(true);
	local boss = mazeModule.GetBoss();

	
	if boss ~= nil then
		self:UpdateTarget(true);
	else
		self:UpdateTarget();
	end

	self.info = nil;


	self.view.infoBtn[UI.Button].onClick:AddListener(function ()
		--如果是没有打开信息栏
		if not self.info then
			self:ShowInterectInfo();
			-- self:ShowTipsNoneStatus();
			
			self:ShowReward(true);
		--打开了信息栏
		else
			self:ShowInterectInfo(true);
		end
	end);
	-- self.view.rewardBtn:SetActive(false);	
	self.view.rewardBtn[UI.Button].onClick:AddListener(function ()
		--如果是没有打开信息栏
		if not self.reward then

			self:ShowReward();
			self:ShowInterectInfo(true);
			
		--打开了信息栏
		else
			self:ShowReward(true);
		end
	end);
	--信息描述
	self.view.infoBtn.mazeDesc.click[UI.Button].onClick:AddListener(function ()
		self:ShowInterectInfo(true);
	end);
	self.view.rewardBtn.mazeShowReward.click[UI.Button].onClick:AddListener(function ()
		self:ShowReward(true);
	end);
	self.view.rewardBtn.mazeShowReward.mazeShowReward.tip.tips[UI.Text].text = SGK.Localize:getInstance():getValue("maze_reward_tip")

	self.view.Effect[CS.UGUIClickEventListener].onClick = function ( ... )
		if self.view.desc.gameObject.activeInHierarchy  then
			self.view.desc:SetActive(false);
			self.view.mask:SetActive(false);

			self.view.tag:SetActive(false);

			for k,v in pairs(self.ourlist or {}) do
				v:SetActive(false);
			end
			self.view.desc.foetag:SetActive(false)
		else
			self.view.mask:SetActive(true);
			self.view.desc:SetActive(true);

			self.view.tag:SetActive(true);
			self:FreshTips();
		end
	end

	self.view.mask[CS.UGUIClickEventListener].onClick = function ( ... )
		self.view.desc:SetActive(false);
		self.view.mask:SetActive(false);
		self.view.tag:SetActive(false);
	end

end

function View:GetNpcInfo(type,id)
	local npcSpeak = {
	[1] = {	[1] = SGK.Localize:getInstance():getValue("mazeTips1"),		--"出现，Boss出现了!"
			[2] = SGK.Localize:getInstance():getValue("mazeTips2")},	--"被解救，目标达成!"
	[2] = {	[1] = SGK.Localize:getInstance():getValue("mazeTips3"),		--"出现在迷宫中!"
			[2] = SGK.Localize:getInstance():getValue("mazeTips4")},	--"被击败，迷宫震动!"
	[3] = {	[1] = SGK.Localize:getInstance():getValue("mazeTips3"),		--"出现在迷宫中!"
			[2] = SGK.Localize:getInstance():getValue("mazeTips5")},	--"被击败!"
	[4] = {	[1] = SGK.Localize:getInstance():getValue("mazeTips3"),		--"出现在迷宫中!"
			[2] = SGK.Localize:getInstance():getValue("mazeTips6")},	--"离开了迷宫!"
	[5] = {	[1] = SGK.Localize:getInstance():getValue("mazeTips3"),		--"出现在迷宫中"
			[2] = SGK.Localize:getInstance():getValue("mazeTips7")},	--"被打开了！天降横财！"
	[6] = {	[1] = SGK.Localize:getInstance():getValue("mazeTips3"),		--"出现在迷宫中"
			[2] = SGK.Localize:getInstance():getValue("mazeTips8")},	--"被打开了！全队战斗力提升！"
	[7] = {	[1] = SGK.Localize:getInstance():getValue("mazeTips3"),		--"出现在迷宫中"
			[2] = SGK.Localize:getInstance():getValue("mazeTips9")},	--"消失了"
}
	local cfg = mazeConfig.GetInfo(id);
	local _type = cfg.type;
	if npcSpeak[_type] then
		if npcSpeak[_type][type+1] then
			return cfg.name..tostring(npcSpeak[_type][type+1]);
		end
	end
	return 
end

function View:ShowInterectInfo(flag)
	if not flag then
		-- print("flag",flag);
		self.info = true
		self.view.infoBtn.mazeDesc.gameObject:SetActive(true);
		self.view.infoBtn.mazeDesc.click.gameObject:SetActive(true);
		self.view.infoBtn.mazeDesc.mazeDesc.tipsDesc.gameObject:SetActive(true);
		local npcinfo = mazeModule.GetInterNpc();
		-- print("npc信息",sprinttb(npcinfo));
		self.info = true;
		local data = {};

		if not npcinfo then return end
		for k,v in pairs(npcinfo) do
			for _k,_v in pairs(v.event) do
				table.insert(data,_v);
			end
		end

		table.sort( data, function (a,b)
			return a.time < b.time;
		end )

		-- print("信息的数量---->>",#data);
		-- ERROR_LOG("信息--->>",sprinttb(data));
		self.infoUIDrag = self.view.infoBtn.mazeDesc.mazeDesc.tipsDesc.scroll[CS.UIMultiScroller];
		self.infoUIDrag.DataCount = #data;
		self.infoUIDrag.RefreshIconCallback = function (obj, idx)
	    	obj.gameObject:SetActive(true);
	    	local item = SGK.UIReference.Setup(obj);
	    	local time =  data[idx+1].time - self.this_startTime;

	    	local H,M,S = getTimeHMS(time) 
	    	item.time[UI.Text].text = string.format("%02d:%02d",M,S);
	    	item.desc[UI.Text].text = self:GetNpcInfo(data[idx+1].status,data[idx+1].id);
		end
		self.infoUIDrag:ScrollMove(#data-1 or 0);

		self:ShowTipsNoneStatus();

	else
		-- print("flag",flag);
		self.view.infoBtn.mazeDesc.mazeDesc.tipsDesc.gameObject:SetActive(false);
		self.view.infoBtn.mazeDesc.gameObject:SetActive(false);
		self.info = nil;
	end 
end
function View:ShowReward(flag)
	if not flag then
		self.view.rewardBtn.mazeShowReward.gameObject:SetActive(true);
		self.view.rewardBtn.mazeShowReward.mazeShowReward.gameObject:SetActive(true);
		self:FreshReward();
		self.reward = true
	else
		self.view.rewardBtn.mazeShowReward.gameObject:SetActive(false);
		self.view.rewardBtn.mazeShowReward.mazeShowReward.gameObject:SetActive(false);
		self.reward = nil
	end
end

function View:FreshReward()
	--查询背包gid的数量
	local bag = module.ItemModule.GetItemCount(90154);
	local cfg = mazeConfig.GetNPCByID();
	local Scroller = self.view.rewardBtn.mazeShowReward.mazeShowReward.ScrollView[CS.UIMultiScroller];

	local result = {};

	Scroller.RefreshIconCallback = function (obj,idx)
		obj.gameObject:SetActive(true);
		local item = SGK.UIReference.Setup(obj);
		local cfg_item = cfg[idx+1];

		local ten_gid = cfg_item.item_ten;
		local ten = module.ItemModule.GetItemCount(ten_gid);
		local one_gid = cfg_item.item;
		local one = module.ItemModule.GetItemCount(one_gid);
		item.name[UI.Text].text = cfg_item.icon_id;
		item.ten.Text[UI.Text].text = tostring(ten).."/"..cfg_item.item_ten_num;
		item.one.Text[UI.Text].text = tostring(one).."/"..cfg_item.item_num;
	end
	Scroller.DataCount = #cfg;
end



function View:UpdateTime(time)
	if time then
		local H,M,S = getTimeHMS(time);
		self.view.bg.content.title.title_image.btn.Text[UI.Text].text = string.format("%02d:%02d",M,S);

		local slider = tonumber(time) / tonumber(self.duration);

		self.view.bg.content.title.title_image.slider.Slider[UI.Slider].value = slider;
	end
end

function View:UpdateMonsterCount(count)

	self.view.bg.content.bg.monster.num[UI.Text].text = tostring(count or (mazeModule.GetNpcCount() or 0));
end

function View:UpdateMazeCount(count)
	self.view.bg.content.bg.crystal.num[UI.Text].text = tostring(count or mazeModule.GetMazeCount());
end
--西风被打败
function View:UpdateTarget(flag)
	--西风被打败
	if flag then
		self.view.bg.content.bg.target.target[UI.Text].text = SGK.Localize:getInstance():getValue("mazeTarget_1");--目标达成
		self.view.bg.content.bg.btnarea.exit.Title[UI.Text].text = SGK.Localize:getInstance():getValue("mazeTarget_2");--离开副本
		CS.UGUIClickEventListener.Get(self.view.bg.content.bg.btnarea.exit.gameObject,true).onClick = function (obj)
			module.TeamModule.KickTeamMember()--解散队伍
			SceneStack.EnterMap(13,{pos = {-3.43,-0.02,9.82}});
		end
	else
		self.view.bg.content.bg.btnarea.exit.Title[UI.Text].text = SGK.Localize:getInstance():getValue("mazeTarget_3");--放弃副本
		CS.UGUIClickEventListener.Get(self.view.bg.content.bg.btnarea.exit.gameObject,true).onClick = function (obj)

			 showDlgMsg("是否离开副本？", function ()
               module.TeamModule.KickTeamMember()--解散队伍
               SceneStack.EnterMap(13,{pos = {-3.43,-0.02,9.82}});
            end, function ()
            end, SGK.Localize:getInstance():getValue("common_queding_01"), --确定
            SGK.Localize:getInstance():getValue("common_cancle_01"), --取消
            nil, nil)
		end
	end
	
end



function View:updateTips()
	local _tips = self.unlock[1];
	table.remove(self.unlock,1);
	table.insert(self.unlock,_tips);

	if self.fresh then
		self.view.tips.Text[UI.Text].text = self.unlock[1];
	end
	self.fresh = 0;
end


function View:Update()
	if self.end_time then
		self.this_time = Time.now();

		local ret = self.end_time - self.this_time ;

		if ret >=0 then
			self:UpdateTime(ret);
		end
	end
	
	--计时

	self.fresh  = self.fresh + UnityEngine.Time.deltaTime;

	if self.fresh >= 15 then
		self:updateTips();
	else
		self.view.tips.Text[UI.Text].text = self.unlock[1];
	end

end
function View:ShowTipsNoneStatus(flag)
	self.view.infoBtn.mazeDesc.mazeDesc.tipsNone.gameObject:SetActive(flag~=nil);
end

function View:ShowTipsNone(info)
	self.view.infoBtn.mazeDesc.gameObject:SetActive(true);
	self:ShowTipsNoneStatus(true);
	local tip = self:GetNpcInfo(info.status,info.id);

	self.view.infoBtn.mazeDesc.click.gameObject:SetActive(false);

	-- ERROR_LOG("tip",tip)
	self.view.infoBtn.mazeDesc.mazeDesc.tipsNone.desc[UI.Text].text = tostring(tip);

	StartCoroutine(function()
		WaitForSeconds(2)
		self.view.infoBtn.mazeDesc.click.gameObject:SetActive(true);
		self:ShowTipsNoneStatus();
	end)
end

function View:FreshTips( ... )
	self.buff,self.enemybuff = mazeModule.GetBuff();
	self.buff = self.buff or {};
	print(sprinttb(self.buff),sprinttb(self.enemybuff));
	self.ourlist = self.ourlist or {};
	local index = 0;
	for i,v in ipairs(self.buff) do
		local obj = self.ourlist[i]
		if not obj then
			obj = CS.UnityEngine.GameObject.Instantiate(self.out_item.gameObject, self.view.desc.gameObject.transform);
		end
		self:FreshBuffItem(obj,v);
		obj.gameObject:SetActive(true);

		obj.gameObject.transform:SetSiblingIndex(2);
		self.ourlist[i]	= obj;

	end
	if #self.ourlist == 0 then
		self.view.desc.foetag:SetActive(true)
	else
		self.view.desc.foetag:SetActive(false)
	end
	self.view.desc[UnityEngine.RectTransform].sizeDelta = UnityEngine.Vector2(300,55*((#self.buff == 0 and 1 or #self.buff)+1)+18);





	-- out_item
end

function View:FreshBuffItem(item,buff)
	local buff_view = SGK.UIReference.Setup(item);

	local cfg = battle.LoadBuffConfig(buff)
	buff_view.Text[UI.Text].text = cfg.desc;
	print("cfg",sprinttb(cfg));
	buff_view.icon[UI.Image]:LoadSprite("icon/"..cfg.icon)
	
end

function View:listEvent()
    return {
    "MAZENPCCHANGE",
    "MAZECUBECHANGE",
    "MAZEBOSSDEAD",
    "NPCINFOCHANGE", -- npc状态改变
    "ACTIVITYTIME",--活动时间
    };
end

function View:onEvent(event, ...)
	 if event == "MAZENPCCHANGE" then
        local count = select(1, ...)

        self:UpdateMonsterCount(count);
    end

    if event == "MAZECUBECHANGE" then
    	local count = select(1,...)
    	self:UpdateMazeCount(count);
    end
    --boss被打败
    if event == "MAZEBOSSDEAD" then
    	self:UpdateTarget(true);
    end

    if event == "NPCINFOCHANGE" then

    	local info = select(1,...);

    	if info then
    		local type = mazeConfig.GetInfo(info.id).type;
    		-- self:ChangeLock(type);
    		-- ERROR_LOG(sprinttb(info));
	    	self:ShowTipsNone(info);
	    end
    end
    if event == "ACTIVITYTIME" then
    	local time = select(1,...);
    	self.this_startTime = time[1];
    	self.end_time = time[2];
    	-- ERROR_LOG("接受到时间的通知",self.this_startTime,self.end_time);
    	self.duration = self.end_time - self.this_startTime;
    end



end

return View;