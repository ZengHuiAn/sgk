local View = {};
local WorldAnswerModule = require "module.WorldAnswerModule"
local WorldAnswerConfig = require "config.WorldAnswerConfig"
local Time = require "module.Time"
local UnionConfig = require "config/UnionConfig"

local m_answer = nil

local function getTimeHMS(time)
    local H = math.floor(time /3600);
    time = math.fmod(time ,3600)
    local M = math.floor(time/60);
    time = math.fmod(time ,60)
    local S = time
    return H,M,S
end

function View:Start(data)
	local view = SGK.UIReference.Setup(self.gameObject)
	self.activitytime = nil
	self.m_time = nil
	self.m_ui = view;
	self.guildWorldAnswer = SGK.UIReference.Setup(data.guildWorldAnswer);
	-- self:updateObstacleActive(1);
	m_answer = nil
	self.m_flag = false
	self.m_Open = false
 	--初始化奖励
	WorldAnswerModule.ResetGift();
	self:showActivityTime();
	self.m_ui.rank.Image[UI.Button].onClick:RemoveAllListeners();
	self.m_ui.rank.Image[UI.Button].onClick:AddListener(function ()
		DialogStack.PushPrefStact("WorldAnswerGift");
	end);
end

function View:Update()
	if self.m_endTime then
		self.activitytime = math.floor(self.m_endTime - Time.now())
		local H,M,S = getTimeHMS(self.activitytime)
		self.m_ui.activitytime.Text[UI.Text].text = string.format("%02d:%02d",M,S);
	end
	if self.m_time then
		local time = self.m_time - Time.now()
		time = math.floor(time)
		--本题剩余：
		if time >= 5 then
			self.m_ui.next.gameObject:SetActive(false)
			self.m_ui.time.gameObject:SetActive(true)
			self.m_ui.time.time[UI.Text].text = tostring(time-5)
			self.m_ui.time.Slider[UnityEngine.UI.Slider].value = (15-time)/10
			--发送玩家选择的答案
			if time-5 < 0.3 then
				if not m_answer then
					m_answer = true;
					self:answerQuestion()
				end
			end
			self.lock_answer = WorldAnswerModule.GetAnswer();
		--等待下一题：
		elseif time >= 0 then
			self.m_ui.next.gameObject:SetActive(true)
			self.m_ui.time.gameObject:SetActive(false)
			if self.activitytime <= 5 then
				self.m_ui.next.bg1[UI.Text].text = "活动结束"
				self.m_ui.next.bg2[UI.Text].text = "后离开"
			else
				self.m_ui.next.gameObject:SetActive(false);
			end
			self.m_ui.next.time[UI.Text].text = tostring(time).."秒"
			if self.right_answer1 then
				if self.right_answer1 == 1 then
					self.m_ui.next.Text[UI.Text].text = "对"
					-- self.m_ui.next.Text[UI.Text].color = { r = 115/255,g = 162/255, b = 84/255,a = 1};
				else
					self.m_ui.next.Text[UI.Text].text = "错"
					-- self.m_ui.next.Text[UI.Text].color = { r = 115/255,g = 162/255, b = 84/255,a = 1};
				end
			end
		end
	end
end

function View:listEvent()
	return {
	"WORLDANSWER_GET_SUCCESS",
	"WORLDANSWER_QUESTION_NOTIFY",
	"WORLDANSWER_ANSWER_GET",
	"WORLDANSWER_QUESTION_END_NOTIFY",
	}
end

function View:onEvent( event,... )
	--第一次进入
	if event == "WORLDANSWER_GET_SUCCESS" then
		local v1 = select(1,...)
		print(v1)
		self.m_time = v1[6] + 5 + Time.now()
		print("倒计时",self.m_time)
		self.m_isOpen = true
		m_answer = nil;
		self:firstEnterWorldAnswer(v1)
	end
	--开始发题
	if event == "WORLDANSWER_QUESTION_NOTIFY" then
		local v1 = select(1,...)
		m_answer = nil;
		self:updateCurrentQuestion(v1)
	end
	--得到答案
	if event == "WORLDANSWER_ANSWER_GET" then
		local v1 = select(1,...)
		self:afterAnswerQuestion(v1)
		self.lock_answer = true
	end
	--收到答题结束的通知
	if event == "WORLDANSWER_QUESTION_END_NOTIFY" then
		self.m_flag = nil
		if not self.m_Open then
			self.m_open = true
		end
		WorldAnswerModule.SetAnswer(nil);
		DialogStack.PushPrefStact("WorldAnswerRank",module.WorldAnswerModule.GetRewardList());
		-- SceneStack.EnterMap(25)

	end
end

function View:updateObstacleActive(flag)
	-- self.guildWorldAnswer.dui.Cube[UnityEngine.AI.NavMeshObstacle].enabled = (flag ~= 1);
	-- self.guildWorldAnswer.cuo.Cube[UnityEngine.AI.NavMeshObstacle].enabled = (flag ~= 1);
	self.guildWorldAnswer.cuo.block1.gameObject:SetActive(true)
	self.guildWorldAnswer.cuo.block2.gameObject:SetActive(true)
	self.guildWorldAnswer.dui.block1.gameObject:SetActive(true)
	self.guildWorldAnswer.dui.block2.gameObject:SetActive(true)
end

--发送选择的答题
function View:answerQuestion()
	local answer =  WorldAnswerModule.GetAnswer();
	if answer then
		WorldAnswerModule.ANSWER(answer)
	end
end

function View:firstEnterWorldAnswer(data)
	if not data then
		self:showActivityTime();
		self.m_ui.tips.Text[UI.Text].text = "活动即将开始，请耐心等待"
	else
		self:showActivityTime();
		self.m_ui.tips.Text[UI.Text].text = "站在你认为正确答案的区域答题"
		self.m_ui.title.desc[UI.Text].text = "等待下一道题目"
		self.m_ui.next.gameObject:SetActive(false)
		self.m_ui.time.gameObject:SetActive(false)
	end
end

--得到题目
function View:updateCurrentQuestion(data)
	--复位
	utils.SGKTools.PlayerTransfer(-2.968,0.04,11.893)
	--更新积分
	self.RightNum = WorldAnswerModule.GetRightnNum()
	self.m_ui.personalpoint.point[UI.Text].text = tonumber(self.RightNum or 0) * 10
	--更新题目
	local config = WorldAnswerConfig.getBaseInfo(data[4], 1)
	self.right_answer1 = config.right_answer1;
	self.m_ui.title.desc[UI.Text].text = tostring(config.quest);
	--更新倒计时
	if (self.m_time - Time.now()) > 5 then
		self.m_ui.next.gameObject:SetActive(false)
		self.m_ui.time.gameObject:SetActive(true)
		self.m_ui.time.time[UI.Text].text = tostring(self.m_time - Time.now())
	elseif (self.m_time - Time.now()) > 0 then
		self.m_ui.next.gameObject:SetActive(true)
		self.m_ui.time.gameObject:SetActive(false)
		self.m_ui.next.time[UI.Text].text = tostring(self.m_time - Time.now())
	end
end

-- 得到答案
function View:afterAnswerQuestion(flag)
	-- print("111111111111111111111111111111111",flag)
	--积分变化
	if flag == 1 then
		self.m_ui.personalpoint.point.gameObject.transform:DOScale(Vector3(1.2,1.2,1),1):From()
	end
	self.RightNum = WorldAnswerModule.GetRightnNum()
	self.m_ui.personalpoint.point[UI.Text].text = tonumber(self.RightNum or 0) * 10

	if self.right_answer1 == 1 then
		self.m_ui.next.Text[UI.Text].text = "对"
		-- self.m_ui.next.Text[UI.Text].color = { r = 115/255,g = 162/255, b = 84/255,a = 1};
	else
		self.m_ui.next.Text[UI.Text].text = "错"
		-- self.m_ui.next.Text[UI.Text].color = { r = 115/255,g = 162/255, b = 84/255,a = 1};
	end
end

function View:showActivityTime()
	local _cfg = UnionConfig.GetActivity(1)
	if _cfg.begin_time >= 0 and _cfg.end_time >= 0 and _cfg.period >= 0 then
        local total_pass = Time.now() - _cfg.begin_time
        local period_pass = total_pass - math.floor(total_pass / _cfg.period) * _cfg.period
        local period_begin = Time.now() - period_pass
        self.m_endTime = period_begin + _cfg.loop_duration
    else
    	self.m_endTime = nil
    end
end

return View;