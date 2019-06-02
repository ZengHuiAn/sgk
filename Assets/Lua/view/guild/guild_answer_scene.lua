local View = {};
local WorldAnswerModule = require "module.WorldAnswerModule"
local WorldAnswerConfig = require "config.WorldAnswerConfig"
local Time = require "module.Time"
local UnionConfig = require "config.UnionConfig"
local guildTaskConfig = require  "config.guildTaskConfig"
local activity_Period = nil
function View:ShowUI( ... )
	local tempObj = SGK.ResourcesManager.Load("prefabs/base/WorldAnswer.prefab")
	local NGUIRoot =  UnityEngine.GameObject.Find("bottomUIRoot")
	local obj = nil;
	if NGUIRoot then
		obj = CS.UnityEngine.GameObject.Instantiate(tempObj, NGUIRoot.gameObject.transform)
		return obj
	end
end


function View:FreshSpine(root)
	local obj = SGK.UIReference.Setup(root);
	local spine = obj.goddess[CS.Spine.Unity.SkeletonAnimation];
	local spine1 = obj.goddess1[CS.Spine.Unity.SkeletonAnimation];
		--小人
	spine.skeletonDataAsset = SGK.ResourcesManager.Load("roles/mermaid/mermaid_bot_SkeletonData.asset");
	spine1.skeletonDataAsset = SGK.ResourcesManager.Load("roles/mermaid/mermaid_top_SkeletonData.asset");

	obj.goddess1[UnityEngine.MeshRenderer].sortingOrder = 101;
	
	spine:Initialize(true);
	spine1:Initialize(true);
  	if spine.state then
	  	spine.state:SetAnimation(0,"idle",true);
	end
	if spine1.state then
	  	spine1.state:SetAnimation(0,"idle",true);
	end
end
local effName = {
	"UI/fx_right",
	"UI/fx_wrong",
}
--answer  1 对和 0 错   --obj_status 状态
function View:LoadEffect(answer,obj_status)
	if not self.answer_err then
		local _obj = SGK.ResourcesManager.Load("prefabs/effect/"..effName[2] .. ".prefab")
		if _obj then
			local id = module.playerModule.Get().id;
			local character = self.content:Get(id) 
			local view = SGK.UIReference.Setup(character);
		
			-- print(view.name)
			local eff = UnityEngine.GameObject.Instantiate(_obj, view.Character.Label.gameObject.transform)


			eff.transform.localPosition = Vector3(0,100,0)
			eff:SetActive(false);
			self.answer_err = eff
		end
	end
	if not self.answer then
		local _obj = SGK.ResourcesManager.Load("prefabs/effect/"..effName[1] .. ".prefab")
		if _obj then
			local id = module.playerModule.Get().id;
			local character = self.content:Get(id) 
			local view = SGK.UIReference.Setup(character);
	
			-- print(view.name)
			local eff = UnityEngine.GameObject.Instantiate(_obj, view.Character.Label.gameObject.transform)
			eff.transform.localPosition = Vector3(0,100,0)
			eff:SetActive(false);
			self.answer = eff
		end
	end
	if answer == 1 then
		if self.answer.gameObject.activeInHierarchy == obj_status then
			return;
		end
		self.answer:SetActive(obj_status);
	else
		if self.answer_err.gameObject.activeInHierarchy == obj_status then
			return;
		end
		self.answer_err:SetActive(obj_status);
	end
	ERROR_LOG("玩家是否有头衔",module.playerModule.Get().honor);
	if module.playerModule.Get().honor ==0 then
		self.answer.transform.localPosition = Vector3(0,50,0)
		self.answer_err.transform.localPosition = Vector3(0,50,0)
	else
		self.answer.transform.localPosition = Vector3(0,90,0)
		self.answer_err.transform.localPosition = Vector3(0,90,0)
	end
end

function View:Start(data)
	--加载资源
	self.guildWorldAnswer = SGK.UIReference.Setup(UnityEngine.GameObject.Instantiate(SGK.ResourcesManager.Load("prefabs/guild/guildWorldAnswer.prefab")))

	self:FreshSpine(self.guildWorldAnswer);
	self.content = UnityEngine.GameObject.FindObjectOfType(typeof(SGK.MapSceneController));
	self.DuiPos = self.guildWorldAnswer.dui.transform.position
	self.CuoPos = self.guildWorldAnswer.cuo.transform.position
	-- print(self.guildWorldAnswer)
	local obj = self:ShowUI()
	if not obj then
		showDlgError(nil,"资源加载失败!");
		return
	end
	self.m_ui = SGK.UIReference.Setup(obj)
	--锁定摄像头
	utils.SGKTools.MapCameraMoveTo(2343101)
	WorldAnswerModule.GET();
	WorldAnswerModule.ResetGift();
	-- self.m_ui.gift.Image[UI.Button].onClick:RemoveAllListeners();
	self.m_ui.rankBtn[CS.UGUIClickEventListener].onClick = function ()
		DialogStack.PushPrefStact("guild/UnionActivityRank",{Period = activity_Period, activity_id = 6});
	end;

	self.m_ui.tipBtn[CS.UGUIClickEventListener].onClick = function ()
		utils.SGKTools.ShowDlgHelp(SGK.Localize:getInstance():getValue("guild_answer_info"))
	end;
	self.m_ui.leaveBtn[CS.UGUIClickEventListener].onClick = function ()
		SceneStack.EnterMap(1);
	end;
	-- 
	activity_Period = module.TreasureModule.GetNowPeriod(6);
	module.TreasureModule.GetUnionRank(6,nil,function ( _rank_data )
		local score = module.TreasureModule.GetActivityScore(6)
		self.m_ui.score.point[UI.Text].text = score;
	end);
	self:showActivityTime();
end

local function getTimeHMS(time)
    local H = math.floor(time /3600);
    time = math.fmod(time ,3600)
    local M = math.floor(time/60);
    time = math.fmod(time ,60)
    local S = time
    return H,M,S
end

function View:PlayEffect( )
	self.m_ui.tips.effect.glow[UnityEngine.ParticleSystem]:Stop(true);
	self.m_ui.tips.effect.glow[UnityEngine.ParticleSystem]:Play(true);
	 
end
function View:Update()
	--活动倒计时
	if self.m_endTime then
		self.activitytime = math.floor(self.m_endTime - Time.now())
		local H,M,S = getTimeHMS(self.activitytime)
		if self.activitytime >=0 then
			self.m_ui.activitytime:SetActive(true);
			self.m_ui.activitytime.Text[UI.Text].text = string.format("%02d:%02d",M,S);
		else
			self:ShowEndActivity(6);
		end
	end
	if self.waiting_time then
		local time = self.waiting_time - Time.now();
		if time > 0 then
			local H,M,S = getTimeHMS(time)
			self.m_ui.title.titlenum:SetActive(false);
			self.m_ui.tips:SetActive(false);

			-- self.m_ui.title.desc:SetActive(true);
			self.m_ui.title.desc[UI.Text].text = string.format(SGK.Localize:getInstance():getValue("guild_answer_wait"),math.floor(M),math.floor(S));
			-- print(time);

			return;
		else
			self.m_ui.title.desc:SetActive(false);
			self.m_ui.title.titlenum:SetActive(true);
			self.m_ui.tips:SetActive(true);
			self.m_ui.activitytime:SetActive(true);
			self.waiting_time = nil;	
		end
	end

	--答题倒计时
	if self.m_time and self.m_isOpen then
		self.m_time = self.m_time - UnityEngine.Time.deltaTime
		--本题剩余：
		if self.m_time > 6 then
			if self.m_ui.tips.gameObject.activeInHierarchy == false  then
				self.m_ui.tips:SetActive(true);
				self:PlayEffect();
			end
			self:LoadEffect(1,false);

			self:LoadEffect(0,false);
			self.m_ui.timenext.gameObject:SetActive(false)
			self.m_ui.title.title:SetActive(true)
			self.m_ui.timenow.gameObject:SetActive(true)
			self.m_ui.title.titlenum.gameObject:SetActive(true)
			self.m_ui.timenow.time[UI.Image].enabled = true;
			self.m_ui.timenow.time[CS.UGUISpriteSelector].index = math.floor(self.m_time - 6)
		--发送玩家选择的答案
		elseif self.m_time > 5 then
			self.m_ui.tips:SetActive(false);
			if not self.m_answer then
				self.m_answer = true;
				self.m_ui.timenow.time[UI.Image].enabled = false;
				self.m_ui.timenow.gameObject:SetActive(false)
				-- self.m_ui.title.lockanswer.gameObject:SetActive(true)
				self:updateObstacleActive(true)
				-- print("发起提交答案")
				self:answerQuestion()
			end
		--等待下一题：
		else
			self.m_ui.timenext.gameObject:SetActive(true)
			self.m_ui.title.title:SetActive(false)
			--公布答案和播放特效
			local answer =  WorldAnswerModule.GetAnswer();
			if self.m_answer then
				ERROR_LOG("====答案",answer);
				self.m_answer = nil
				self.m_ui.title.lockanswer.gameObject:SetActive(false)

				if self.right_answer1 == 1 then
					self.m_ui.timenext.Text[CS.UGUISpriteSelector].index = 0
					utils.SGKTools.loadSceneEffect("UI/fx_dati_lvse")
					
					utils.SGKTools.DestroySceneEffect("UI/fx_dati_lvse",2)
					if answer then
						self:LoadEffect(answer == 1 and 1 or 0,true);
					end
				else
					self.m_ui.timenext.Text[CS.UGUISpriteSelector].index = 1
					utils.SGKTools.loadSceneEffect("UI/fx_dati_hongse")
					utils.SGKTools.DestroySceneEffect("UI/fx_dati_hongse",2)
					if answer then
						self:LoadEffect(answer == 2 and 1 or 0,true);
					end
				end
				-- if self.result == 1 then
					
				-- 	-- self.m_ui.personalpoint.point.gameObject.transform:DOScale(Vector3(1.2,1.2,1),1):From()
				-- 	self.result = nil
				-- 	self.RightNum = WorldAnswerModule.GetRightnNum()
				-- 	self.m_ui.personalpoint.point[UI.Text].text = tonumber(self.RightNum or 0) * 10
				-- end
			end
			self.m_ui.timenext.time[UI.Text].text = math.floor(self.m_time).."秒"
		end
	end
end

function View:listEvent()
	return {
		"WORLDANSWER_GET_SUCCESS",
		"WORLDANSWER_QUESTION_NOTIFY",
		"WORLDANSWER_ANSWER_GET",
		"WORLDANSWER_QUESTION_END_NOTIFY",
		"GUILD_SCORE_INFO_CHANGE",
	}
end

function View:onEvent( event,... )
	--第一次进入
	if event == "WORLDANSWER_GET_SUCCESS" then
		-- ERROR_LOG("活动开始===========");
		local v1 = select(1,...)
		self:updateObstacleActive(false)
		self:firstEnterWorldAnswer(v1)
	end
	--得到题目
	if event == "WORLDANSWER_QUESTION_NOTIFY" then
		local v1 = select(1,...)
		ERROR_LOG("收到题目",sprinttb(v1));
		self:updateObstacleActive(false)
		self:updateCurrentQuestion(v1)
	end
	--得到答案
	if event == "WORLDANSWER_ANSWER_GET" then
		local v1 = select(1,...)
		-- print("是否正确",v1)
		self.result = v1
	end
	--收到答题结束的通知
	if event == "GUILD_ACTIVITY_ENDNOTIFY" then
		local data = ...
		if data == 6 then
			-- ERROR_LOG("答题结束");
			local v1 = select(1,...)
			self.m_ui.activitytime.Text[UI.Text].text = string.format("已结束");
			-- self.m_ui.activitytime.gameObject:SetActive(false)
			self:ShowEndActivity(6)
		end
	end

	if event == "GUILD_TASK_SCROE_CHANGE" then
		local quest_id = ...
		local all_cfg = guildTaskConfig.GetguildTask();
		local cfg = cfg[quest_id];
		-- print("活动配置",sprinttb(cfg))
	end

	if event == "GUILD_SCORE_INFO_CHANGE" then
		local data = ...

		if data == 6 then
			local score = module.TreasureModule.GetActivityScore(6)
			self.m_ui.score.point[UI.Text].text = score;
		end
	end
end

function View:ShowEndActivity(activity_id)
	self.m_isOpen = nil
	self.m_endTime = nil;
	self.m_ui.activitytime.Text[UI.Text].text = string.format("已结束");
	WorldAnswerModule.SetAnswer(nil);
	local stack = DialogStack.GetPref_stact();

	local top = stack[#stack];

	if not DialogStack.GetPref_list("guild/guildEnd") then
		DialogStack.PushPref("guild/guildEnd",{Period = activity_Period, activity_id = 6});
	end

end

--发送选择的答题
function View:answerQuestion()
	local answer =  WorldAnswerModule.GetAnswer();
	print("选择的答案",answer)
	if answer then
		WorldAnswerModule.ANSWER(answer)
	end
end

function View:firstEnterWorldAnswer(data)
	if not data or not self.m_endTime or self.m_endTime - Time.now() <6 then
		ERROR_LOG("答题活动未准备好");
		self.m_isOpen = nil
		-- self:showActivityTime();
		-- self.m_ui.activitytime.gameObject:SetActive(false)
		self.m_ui.title.title.gameObject:SetActive(false)
		self.m_ui.title.desc.gameObject:SetActive(true)
		self.m_ui.title.desc[UI.Text].text = "活动未开始"
	else
		
		ERROR_LOG("开始答题",sprinttb(data));
		self.m_isOpen = true
		self.m_ui.activitytime.gameObject:SetActive(true)
		self.m_ui.title.desc.gameObject:SetActive(false)
		self.m_ui.tips.Text[UI.Text].text = "站在你认为正确答案的区域答题"
		self.m_answer = nil;
		self.m_ui.title.titlenum[UI.Text].text = data[3].."/"..math.floor(self.maxtitle).."题"
		self.m_time = data[5]
		print("倒计时-------------------------------------",self.m_time)
		if self.m_time > 3 then
			self.m_time = self.m_time + 5
			local config = WorldAnswerConfig.getBaseInfo(data[4], 1)
			self.m_ui.title.title.gameObject:SetActive(true)
			self.m_ui.title.title[UI.Text].text = tostring(config.quest);
		else
			self.m_time = nil
			self.m_ui.title.title.gameObject:SetActive(false)
			self.m_ui.title.desc.gameObject:SetActive(true)
			self.m_ui.title.desc[UI.Text].text = "请耐心等待下一道题目"
			self.m_ui.timenow.gameObject:SetActive(false)
			self.m_ui.timenext.gameObject:SetActive(false)
		end
	end
end

function View:updateObstacleActive(flag)
	-- self.guildWorldAnswer.dui.Cube[UnityEngine.AI.NavMeshObstacle].enabled = flag
	-- self.guildWorldAnswer.cuo.Cube[UnityEngine.AI.NavMeshObstacle].enabled = flag
	print(sprinttb(self.guildWorldAnswer))
	self.guildWorldAnswer.bai.Cube[UnityEngine.AI.NavMeshObstacle].enabled = flag
	if flag then
		utils.SGKTools.loadSceneEffect("UI/fx_dati_zuge")
	else
		utils.SGKTools.DestroySceneEffect("UI/fx_dati_zuge",0.1)
	end
end

function View:updateCurrentQuestion(data)
	--复位
	ERROR_LOG("题目通知");
	-- utils.SGKTools.PlayerTransfer(1,0,2.9)
	-- print("====",self.m_endTime,Time.now());
	if not self.m_endTime or self.m_endTime - Time.now() <6 then
		return;
	end
	print(sprinttb(data))
	self.m_answer = nil;
	self.m_time = 15
	--更新活动倒计时
	self.m_ui.title.titlenum:SetActive(true);
	self.m_ui.title.desc.gameObject:SetActive(false)
	self.m_ui.activitytime.gameObject:SetActive(true)
	-- self:showActivityTime();
	self.m_ui.title.titlenum[UI.Text].text = data[3].."/"..math.floor(self.maxtitle).."题"
	--更新积分
	self.RightNum = WorldAnswerModule.GetRightnNum()
	-- self.m_ui.personalpoint.point[UI.Text].text = tonumber(self.RightNum or 0) * 10
	--更新题目
	local config = WorldAnswerConfig.getBaseInfo(data[4], 1)
	self.right_answer1 = config.right_answer1;
	self.m_ui.title.title.gameObject:SetActive(true)
	self.m_ui.title.title[UI.Text].text = tostring(config.quest);
end

function View:showActivityTime()
	local _cfg = UnionConfig.GetActivity(6)
	if _cfg and _cfg.loop_duration then
		self.maxtitle = (_cfg.loop_duration - 300) / 15
	end

	ERROR_LOG("最大答题数量",self.maxtitle);
	if _cfg and _cfg.begin_time >= 0 and _cfg.end_time >= 0 and _cfg.period >= 0 then
        local total_pass = Time.now() - _cfg.begin_time
        local count = math.floor(total_pass / _cfg.period) * _cfg.period
        self.m_endTime = count + _cfg.loop_duration + _cfg.begin_time

        self.waiting_time = count + 300 + _cfg.begin_time
        self.open = true
        self.m_ui.title.titlenum:SetActive(true);
        self.m_ui.tips:SetActive(true);
        self.m_ui.activitytime:SetActive(true);
        if self.m_endTime < Time.now() then
        	self.m_isOpen = false
        	self.m_endTime = nil;
        	self.waiting_time = nil
        	self.m_ui.title.titlenum:SetActive(false);
        	self.m_ui.tips:SetActive(false);
        	-- self.m_ui.activitytime:SetActive(false);
    	end

    	if self.waiting_time and self.waiting_time <= Time.now() then
    		self.waiting_time = nil
        	self.m_ui.title.titlenum:SetActive(false);
    	end
    	ERROR_LOG("等待时间",self.waiting_time);
    else
    	self.m_endTime = nil
    end
end

return View