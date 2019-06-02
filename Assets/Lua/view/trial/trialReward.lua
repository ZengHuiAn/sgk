local View = {}
local trialModule = require "module.trialModule"
local battleCfg = require "config.battle"
local skill = require "config.skill"
local trialTowerConfig = require "config.trialTowerConfig"
local ItemHelper = require "utils.ItemHelper";
local Time = require "module.Time"
local EventManager = require 'utils.EventManager';
local NetworkService = require "utils.NetworkService";

local function getTimeHMS(time)
    local H = math.floor(time /3600);
    time = math.fmod(time ,3600)
    local M = math.floor(time/60);
    time = math.fmod(time ,60)
    local S = time
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

function View:UpdateBtn(status)
	self.view.bg.btnOK[CS.UGUISpriteSelector].index = ( status== true and 0 or 1);
	self.view.bg.btnOK[CS.UGUIClickEventListener].interactable= status;
	self.view.bg.time.gameObject:SetActive( status ~=true);

	if not status then
		DispatchEvent("TRIAL_SWEEPING_SUCCESS");
	end
end

function View:Start(data)
	self.view = SGK.UIReference.Setup(self.gameObject);

	self.gid = data and data.gid or 60000100;


	local cfg = trialTowerConfig.GetConfig(self.gid);
	-- print(sprinttb(cfg));

	self.view.bg.btnClose[CS.UGUIClickEventListener].onClick = function ()
		DialogStack.Pop();
	end
	


	

	local value = self:FreshBefore();
	self:Init(value)
	self:FreshReward();

	self:Fresh();
	self.start_time = Time.now(); 

	local dt = date(self.start_time);
	self.end_time = getTimeByDate(dt.year,dt.month,dt.day + 1,0,0,0);
	-- print(Time.now(),self.end_time);

	self:ChecTime();

end

function View:ChecTime()
	--第一波
	if self.gid == 60000001 then
		self.view.bg.btnOK[CS.UGUISpriteSelector].index = 1
		self.view.bg.btnOK[CS.UGUIClickEventListener].interactable= false;
		self.view.bg.time.gameObject:SetActive(false);

	end
end


function View:Fresh( )
	local num = module.ItemModule.GetItemCount(90168);
	print("是否可以扫荡",num);
	if num > 0 then
		local ret = trialModule.GetIsSweeping();
		if ret then
			self:UpdateBtn(true);
			
			local desc = SGK.Localize:getInstance():getValue("shilianta_meirijiangli_queren_02");
			local btn_name = SGK.Localize:getInstance():getValue("shilianta_meirijiangli_queren_03");
			local title = SGK.Localize:getInstance():getValue("shilianta_meirijiangli_queren_01");
			--可以扫荡
			self.view.bg.btnOK[CS.UGUIClickEventListener].onClick = function ()
				DlgMsg({msg = desc, confirm = function ( ... )
					--领取
					self:Sweeping();
				end, txtConfirm = btn_name,title = title})
			end
		else
			self:UpdateBtn();	
		end
		
	else
		self:UpdateBtn();
		--不可扫荡
	end
end

function View:Update()
	if self.end_time then

		local time = self.end_time - Time.now();

		if time >=0 then
			local H,M,S = getTimeHMS(time);
			self.view.bg.time.Text[UI.Text].text = string.format("%02d:%02d:%02d",H,M,S);
		end
	end
end
--刷新累计奖励
function View:FreshReward()

	self.view.bg.Consume.bottom.Text[UI.Text].text = SGK.Localize:getInstance():getValue("shilianta_meirijiangli_01");
	for i=1,3 do
		local item = self.view.bg.Consume.icons["ItemIcon"..i];

		local data = self.reward[i];

		if data then
			self:FreshIcon(item,data);
		else

		end
	end
end

--刷新奖励
function View:FreshIcon(parent,cfg)
	local item_cfg = utils.ItemHelper.Get(cfg.type,cfg.id);
	item_cfg.count = cfg.value;
	utils.IconFrameHelper.Create(parent, {customCfg = item_cfg, type = 41,showName = true,showDetail= true,func = function ( _obj)
			_obj.gameObject.transform.localScale = UnityEngine.Vector3(0.8,0.8,1);
		end});
end




function View:Init(value)
	self.reward = {};
	for k,v in pairs(value) do
		table.insert(self.reward,v);
	end
	ERROR_LOG(sprinttb(self.reward));
end

function View:FreshBefore()
	local mul_data = {};
	local cfg = trialTowerConfig.GetConfig(self.gid-1);

	self.quest_id = cfg.reward_quest;
	local rewardCfg = module.QuestModule.GetCfg(self.quest_id);
	ERROR_LOG(sprinttb(rewardCfg.reward));
	return rewardCfg and rewardCfg.reward or {};
end


function View:Sweeping()

	local ret = trialModule.GetIsSweeping();
	if ret then
		module.QuestModule.Submit(self.quest_id);
		 module.ShopModule.Buy(8,1080014,1,nil,function ()
	        	self:Fresh()
	        end);
	end
end

function View:OnDestory()

	if self.co and coroutine.status(self.co) =="running" then
		self.co = nil;
	end
end

function View:listEvent()
    return {
        "FIGHT_INFO_CHANGE",
        "LOCAL_FIGHT_SWEEPING",
        "QUEST_INFO_CHANGE",
    }
end

function View:onEvent(event,data)
	if event == "QUEST_INFO_CHANGE" then
		self:Fresh();
	end
end
-- LOCAL_FIGHT_SWEEPING --扫荡成功的通知


return View;