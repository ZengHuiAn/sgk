local TAG = "WorldAnswerModule"
local EventManager = require 'utils.EventManager';
local NetworkService = require "utils.NetworkService";
local Time = require "module.Time"

local RightNum = nil
local gift = {}

local gid = nil   --记录当前第几轮答题
local function date(now)
    local now = now or Time.now();
    return os.date ("!*t", now + 8 * 3600);
end

-- 17039/17040
-- request[1] = sn

-- respond[1] = sn
-- respond[2] = 返回码
-- respond[3] = 第几轮答题
-- respond[4] = 题目id
-- respond[5] = 答题时间
-- respond[6] = 倒计时时间
-- respond[7] = 答对数量
local function getQuestionInfo()
	NetworkService.Send(17039)
end
EventManager.getInstance():addListener("server_respond_17040",function ( event,cmd,data )
	ERROR_LOG("server_respond_17040",sprinttb(data));
	local ret = data[2];
	RightNum = data[7]--答对数量
	if ret ~= 0 then 
		return DispatchEvent("WORLDANSWER_GET_SUCCESS",false);
	end
	gid = data[4];
	DispatchEvent("WORLDANSWER_GET_SUCCESS",data);
end)

-- 17041/17042
-- request[1] = sn
-- request[2] = 答案

-- respond[1] = sn
-- respond[2] = 返回码
-- respond[3] = 0代表不正确，1代表正确

local function answerQuestion(num)
	NetworkService.Send(17041,{nil,num})
end
EventManager.getInstance():addListener("server_respond_17042",function ( event,cmd,data )
	ERROR_LOG("server_respond_17042",sprinttb(data));
	local ret = data[2]
	if ret~=0 then
		return
	end
	if data[3] == 1 then
		RightNum = RightNum + 1
		gift[gid] = 1;
	end
	DispatchEvent("WORLDANSWER_ANSWER_GET",data[3])
end)

--获取答对数量和题库数量
local function getRightnNum()
	return RightNum
end

local function checkOpen()
	local time = date();
	local cacheTime = time.min * 60 + time.sec;
	cacheTime = math.fmod(cacheTime, 600)
	if 0 <= cacheTime and cacheTime <= 400 then
		return true
	end
	return false
end

--  发题通知
EventManager.getInstance():addListener("server_notify_17043",function ( event,cmd,data )
	-- ERROR_LOG("server_notify_17043",sprinttb(data));
	local ret = data[2]
	local info = {}
	info.qNO = data[3] --第几轮答题
	info.id = data[4]  -- 题目id 
	info.players = data[5] -- 上一轮正确的玩家人数
	info.playerTotal = data[6] -- 参与答题的玩家总人数
	gid = data[3]
	DispatchEvent("WORLDANSWER_QUESTION_NOTIFY",data)
end)
-- server_notify_

-- 答题结束
local reward = nil
EventManager.getInstance():addListener("server_notify_17044",function ( event,cmd,data )
	-- ERROR_LOG("server_notify_17044",sprinttb(data));
	local ret = data[2]
	reward = {}
	for k,v in pairs(data[3]) do
		reward[v[1]] = {
				playerId 	= v[1], -- 玩家id 
				count		= v[2], -- 答题正确数
				totalNum	= v[3], -- 总答题数
			}
	end
	reward.title = "公会答题"
	DispatchEvent("WORLDANSWER_QUESTION_END_NOTIFY",reward)
end)

local function getWorldAnswerRewardList()
	if reward then
		return reward
	else
		return {}
	end
end

--获取当前答题奖励
local function getGift()
	local temp = {}
	for k,v in pairs(gift) do
		print(k,v);
		table.insert( temp, k );
	end

	return temp;
end 
--还原奖励
local function resetGift()
	gift = {}	
end

local answer = nil
local function setAnswer(_answer)
	answer = _answer;
	print(answer,"===============设置答案");
end 

local function getAnswer()
	return answer;
end 

return {
	GET					= getQuestionInfo,
	ANSWER 				= answerQuestion,
	GetRewardList 	 	= getWorldAnswerRewardList,
	GetRightnNum 		= getRightnNum,
	CheckOpen 			= checkOpen,
	date 				= date,
	SetAnswer 			= setAnswer,
	GetAnswer 			= getAnswer,
	GetGift				= getGift,
	ResetGift			= resetGift,
}