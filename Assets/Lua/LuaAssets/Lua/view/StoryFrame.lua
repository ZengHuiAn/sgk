local StoryConfig = require "config.StoryConfig"
local HeroWeaponStage = require "hero.HeroWeaponStage"
local ItemHelper = require "utils.ItemHelper";
local UserDefault = require "utils.UserDefault";
local Time = require "module.Time"
local npcConfig = require "config.npcConfig"
local System_Set_data=UserDefault.Load("System_Set_data");
local View = {};
local ExitV3 = setmetatable({
	cfg = {
		["1"]= {-2000,0,0},
		["2"]= {2000,0,0},
		["3"]= {0,-2000,0},
	}
}, {__index=function(t, k)
	local c = t.cfg[k]
	if c then
		return UnityEngine.Vector3(c[1], c[2], c[3]);
	end
end});
function View:Start(data)
	DispatchEvent("LOCAL_SOTRY_DIALOG_START") --storyDialogFlag=true

	self.mainFrame = CS.SGK.UIReference.Setup(self.gameObject)

	self.mainFrame.transform.localPosition = Vector3(0, -1000, 0);

	self.view = self.mainFrame.Canvas.StoryFrame_ORG;

	local new_data = StoryConfig.GetStoryData()
	if new_data then
		data = new_data;
		StoryConfig.ChangeStoryData(nil);
	end
	if data then
		self.Data = data
	else
		self.Data = self.savedValues.Data
	end
	self.savedValues.Data = self.Data
	--跳过按钮点击事件赋值
	self.savedAutomationStatus = false
	self.simulateMaskBtn = false
	self.btnInit = true
	self.view.skipBtn[CS.UGUIClickEventListener].onClick = function ( ... )
		self.view.mask[CS.UGUIClickEventListener].interactable = false
		self.view.skipBtn[CS.UGUIClickEventListener].interactable = false
		if self.Data.skipFlag then
			while StoryConfig.GetStoryConf(self.StoryData.next_id) do
				if self.StoryData.comics ~= "0" then
					break
				end
				if self.StoryData.story_choices ~= 0 then
					break
				end
				self.old_storydata = self.StoryData
				self.StoryData = StoryConfig.GetStoryConf(self.StoryData.next_id)
			end
			if self.StoryData.story_choices ~= 0 then
				--self.view.mask[CS.UGUIClickEventListener].interactable = false
				self:UIRef()
				self:StoryChoose()
				return
			end
			if not self.Data.state and self.StoryData.story_choices == 0 and self.StoryData.comics == "0" then
				self.old_storydata = self.StoryData
				self.StoryData = StoryConfig.GetStoryConf(self.StoryData.next_id)
				--DispatchEvent("StoryFrameMaskBtn")
			end
			self:UIRef()
		else
			self.view.mask[CS.UGUIClickEventListener].interactable = true
			self.view.skipBtn[CS.UGUIClickEventListener].interactable = true
			self:StoryReset()
			if self.Data.Function then
				self.Data.Function()
			end
			self:LoadOptions()
		end	
	end
	self.old_storydata = nil
	self.view.mask[CS.UGUIClickEventListener].onClick = function ( ... )
		self:MaskBtn()
	end
	self.automationStatus = false --自动状态
	self.automationTime = nil
	self.isShowHero = false --是否在展示角色
	self.isShowing = false;
	--自动按钮点击事件赋值
	self.view.automationBtn[CS.UGUIClickEventListener].onClick = function ( ... )
		--自动播放
		self.automationStatus = not self.automationStatus
		if self.automationStatus then
			self.automationTime = Time.now()
		else
			self.automationTime = nil
		end
		self.view.automationBtn:SetActive(false)
		self.view.skipBtn:SetActive(false)
		self.view.resetBtn:SetActive(false)
		self.view.TopMask.automation:SetActive(true)
	end

	--回顾按钮点击事件赋值
	self.view.resetBtn[CS.UGUIClickEventListener].onClick = function ( ... )
		--回顾
		DialogStack.PushPref("StoryRecall",{id = self.Data.id,now_id = self.StoryData.story_id},UnityEngine.GameObject.FindWithTag("UITopRoot"))
		--self:StoryPlayback()--回顾2
	end
	self.StoryData = StoryConfig.GetStoryConf(self.Data.id)
	if self.StoryData == nil then
		if self.Data.id then
			showDlgMsg("剧情id "..self.Data.id.."数据库中不存在", function()end)
			ERROR_LOG("剧情id "..self.Data.id.."数据库中不存在")
		end
	else
		DispatchEvent("HeroCamera_DOOrthoSize",true)
		DispatchEvent("LOCAL_NOTIFY_CLOSE_BOTTOMBAR")
	end
	self.HeroOBJ1= self.view.HeroPos1.boss1 -- UnityEngine.GameObject("boss"..1)--UnityEngine.GameObject("hero"..self.StoryData[self.Count].role);
	self.HeroOBJ2 = self.view.HeroPos2.boss1 -- UnityEngine.GameObject("boss"..1)--UnityEngine.GameObject("hero"..self.StoryData[self.Count].role);
	self.HeroOBJ3 = self.view.HeroPos3.boss1
	-- self.HeroOBJ.transform.parent = self.view.HeroPos.gameObject.transform;
	-- self.HeroOBJ.transform.localScale = Vector3(0.8,0.8,0.8)
	-- self.HeroOBJ.transform.localPosition = Vector3(0,-1000,0)
	self.HeroAnimation1= self.HeroOBJ1[CS.Spine.Unity.SkeletonGraphic];
	self.HeroAnimation2 = self.HeroOBJ2[CS.Spine.Unity.SkeletonGraphic];
	self.HeroAnimation3 = self.HeroOBJ3[CS.Spine.Unity.SkeletonGraphic];
	self.DOTweenAnimation = self.view.Root.gameObject:GetComponent("DOTweenAnimation")--对话框
	--print(#self.StoryData)
	self.StoryEffect = {}--特效组
	self.Count = 1
	self:UIRef()
	self.animationIdx = 1
	--cg按钮下一步点击事件
	self.mainFrame.Canvas.CGNext[CS.UGUIClickEventListener].onClick = function ( ... )
		-- if self.automationStatus then
		-- 	self.automationStatus = false
			
		-- 	self.view.TopMask.automation:SetActive(false)

		-- 	self.view.automationBtn:SetActive(not (self.StoryData.auto == 1 or self.StoryData.auto == 3 or self.StoryData.auto == 5 or self.StoryData.auto == 7))
		-- 	self.view.resetBtn:SetActive(not (self.StoryData.auto == 2 or self.StoryData.auto == 3 or self.StoryData.auto == 6 or self.StoryData.auto == 7))
		-- 	self.view.skipBtn:SetActive(not (self.StoryData.auto == 4 or self.StoryData.auto == 5 or self.StoryData.auto == 6 or self.StoryData.auto == 7))
		-- else
		 	self:CG_next()
		-- end
	end
end

function View:listEvent()
	return {
		"STORYFRAME_CONTENT_CHANGE",
		"KEYDOWN_ESCAPE",
		"CloseStoryReset",
		"stop_automationBtn",
		"StoryFrameMaskBtn",
		"StoryFrameRecall",
		"QUEST_INFO_CHANGE",
		"story_frame_hide_camera",
		"STORY_FULL_SCREEN_EFFECT",
		"STORY_SHOW_HERO"
	}
end

function View:DOPause_Text(fun)
	if self.descView and self.StoryData then
		local desc = self.StoryData.dialog..self.StoryData.dialog_look
		if self.descView.text == desc or self.descView.text == self.StoryData.dialog then
			if fun then
				fun()
			end
		else
			self.descView:DOPause();
			self.descView.text = desc
			-- if not StoryConfig.GetStoryConf(self.StoryData.next_id) then
			-- 	self:LoadOptions()
			-- end
		end
	end
end
function View:StoryReset()
	--print("剧情重置")
	local level = module.playerModule.Get() and module.playerModule.Get().level or 101
	if level and level <= 100 then
		self.view[UnityEngine.AudioSource]:Stop()
		self.view[UnityEngine.AudioSource].clip = nil
		self.view.mask[UnityEngine.AudioSource].clip = nil
		self.mainFrame.Camera.Effect[UnityEngine.AudioSource].clip = nil
		self.gameObject:SetActive(false)
		DispatchEvent("HeroCamera_DOOrthoSize",false)
		self.view.HeroPos1.transform.localPosition = Vector3(-2000,0,0)
		self.view.HeroPos2.transform.localPosition = Vector3(2000,0,0)
		self.view.HeroPos3.transform.localPosition = Vector3(0,-2000,0)
		self.view.cg_Image:SetActive(false)
		self.mainFrame.Camera.CG:SetActive(false)
		self.mainFrame.Camera[UnityEngine.Camera].clearFlags = UnityEngine.CameraClearFlags.Depth;
		self.view.bg:SetActive(false)
		self.view.automationBtn:SetActive(true)
		self.view.skipBtn:SetActive(false)
		self.view.resetBtn:SetActive(true)
		self.view.TopMask.automation:SetActive(false)
		local childCount = self.mainFrame.Camera.Effect.transform.childCount
		for i = 1,childCount do
			UnityEngine.GameObject.Destroy(self.mainFrame.Camera.Effect.transform:GetChild(i-1).gameObject)
		end
		self.automationStatus = false
		self.view.Root.desc[CS.InlineText].text = ""
		self.HeroAnimation1.skeletonDataAsset = nil
		self.HeroAnimation1.material = nil
		self.HeroAnimation1.color = {r= 1,g=1,b=1,a=0}
		self.HeroAnimation2.skeletonDataAsset = nil
		self.HeroAnimation2.material = nil
		self.HeroAnimation2.color = {r= 1,g=1,b=1,a=0}
		self.HeroAnimation3.skeletonDataAsset = nil
		self.HeroAnimation3.material = nil
		self.HeroAnimation3.color = {r= 1,g=1,b=1,a=0}
		UnityEngine.GameObject.Destroy(self.gameObject)
	else
		--DispatchEvent("KEYDOWN_ESCAPE")
		UnityEngine.GameObject.Destroy(self.gameObject)
	end
	utils.SGKTools.LockMapClick(true,0.25)--剧情关闭，0.25秒内不可点击
	--SGK.BackgroundMusicService.UnPause()
	SGK.BackgroundMusicService.GetAudio(System_Set_data.BgVoice or 0.75)
	SGK.BackgroundMusicService.SwitchMusic();
	if self.descView then
		self.descView:DOPause();
	end
	--DeleteStoryOptions()--切换地图清除任务选项
	SceneStack.savedValues.NotMenuFlag = false
	DispatchEvent("LOCAL_SOTRY_DIALOG_CLOSE")

	if self.Data.onClose then
		self.Data.onClose();
	end
end
function View:onEvent(event, ...)
	local data = select(1, ...)
	--print(event, data);
	if event == "STORYFRAME_CONTENT_CHANGE" then
		self.Data = data
		self.StoryData = StoryConfig.GetStoryConf(self.Data.id)
		if self.StoryData == nil then
			showDlgMsg("剧情id "..self.Data.id.."数据库中不存在", function()end)
			ERROR_LOG("剧情id "..self.Data.id.."数据库中不存在")
		else
			DispatchEvent("HeroCamera_DOOrthoSize",true)
		end
		self.savedValues.Data = self.Data
		self.Count = 1
		self.old_storydata = nil
		self:UIRef()
		StoryConfig.ChangeStoryData(nil)
	elseif event == "KEYDOWN_ESCAPE" or event == "CloseStoryReset" then
		self:StoryReset()
	elseif event == "stop_automationBtn" then
		print("消息", sprinttb(data))
		if data.mandatory then
			self.automationStatus = data.automation
			if self.automationStatus then
				self.automationTime = Time.now()
			else
				self.automationTime = nil
			end
		else
			if self.automationStatus then
			else
				self:MaskBtn()
			end
		end
	elseif event == "StoryFrameMaskBtn" then
		self.simulateMaskBtn = true
		self:MaskBtn()
	elseif event == "StoryFrameRecall" then
		if data then
			self.view.resetBtn[CS.UGUIClickEventListener]:BtnAnimate(data)
		else
			self.view.resetBtn[CS.UGUIClickEventListener]:BtnReset()
			DialogStack.PushPref("StoryRecall",{id = self.Data.id,now_id = self.StoryData.story_id},UnityEngine.GameObject.FindWithTag("UITopRoot"))
		end
	elseif event == "QUEST_INFO_CHANGE" then
		--print("zoe juqingrenwu",sprinttb(data))
		-- if data and data.id and data.cfg.cfg.type and data.cfg.cfg.type == 110 then
		-- 	module.QuestModule.Finish(data.id)
		-- end
		--self:StoryChoose()
	elseif event == "story_frame_hide_camera" then
		self.mainFrame.Camera:SetActive(not data)
	elseif event == "STORY_FULL_SCREEN_EFFECT" then
		local name, Vec3, time, lock, fun, scale = ...
		local prefab = SGK.ResourcesManager.Load("prefabs/effect/"..name..".prefab")
		local parent = self.mainFrame.Camera.Effect.transform;
		local rt = prefab:GetComponent(typeof(UnityEngine.RectTransform));
		local bgActive = self.view.bg.activeSelf;
		if rt then
			parent = self.view.transform;
		else
			self.view.bg:SetActive(false);
		end

		local eff = UnityEngine.GameObject.Instantiate(prefab, parent);
		local _scale = scale or 1
		eff.transform.localScale = Vector3(_scale,_scale,_scale)
		if lock then
			utils.SGKTools.LockMapClick(true, time);
		end

		SGK.Action.DelayTime.Create(time):OnComplete(function()
			if fun then
				fun()
			end
			self.view.bg:SetActive(bgActive);
			UnityEngine.GameObject.Destroy(eff.gameObject)
		end)
	elseif event == "STORY_SHOW_HERO" then
		self.isShowHero = true;
		self:HideAndShowRoleInfo(true, data.roleID);
	end
end

function View:HideAndShowRoleInfo(hide, id)
	if self.action_node == nil then
		self.action_node = {
			[1] = {node = self.view.skipBtn, pos = self.view.skipBtn.gameObject.transform.localPosition},
			[2] = {node = self.view.automationBtn, pos = self.view.automationBtn.gameObject.transform.localPosition},
			[3] = {node = self.view.resetBtn, pos = self.view.resetBtn.gameObject.transform.localPosition},
			[4] = {node = self.view.Root, pos = self.view.Root.gameObject.transform.localPosition},
			[5] = {node = self.view.TopMask, pos = self.view.TopMask.gameObject.transform.localPosition},
		}
	end
	self.isShowing = true;
	if hide then
		self.tweens = {}
		for i,v in ipairs(self.action_node) do
			v.node[CS.DG.Tweening.DOTweenAnimation]:DOPlayForwardById("hide");
		end
		local info_cfg = module.HeroModule.GetInfoConfig(id);
		if info_cfg then
			if self.roleInfo == nil then
				local obj = CS.UnityEngine.GameObject.Instantiate(SGK.ResourcesManager.Load("prefabs/base/roleInfo.prefab"), self.view.roleInfo.gameObject.transform);
				self.roleInfo = CS.SGK.UIReference.Setup(obj);
			end
			self.view.info_bg:SetActive(true);
			self.view.info_bg[CS.DG.Tweening.DOTweenAnimation]:DOPlayForward();
			self.view.info_bg[UnityEngine.UI.Image]:LoadSpriteWithExt("cartoon_bg/juese_bg.jpg")
			self.roleInfo.name.Text1[UI.Text].text = info_cfg.name;
			self.roleInfo.name.Text2[UI.Text].text = info_cfg.pinYin;
			for i=1,4 do
				if info_cfg["info"..i] and info_cfg["info"..i] ~= "" then
					self.roleInfo["info"..i].Text[UI.Text].text = info_cfg["info"..i];
					self.roleInfo["info"..i]:SetActive(true);
				else
					self.roleInfo["info"..i]:SetActive(false);
				end
			end
		end
	else
		for i,v in ipairs(self.action_node) do
			v.node[CS.DG.Tweening.DOTweenAnimation]:DOPlayBackwardsById("hide");
		end
		self.view.info_bg[CS.DG.Tweening.DOTweenAnimation]:DOPlayBackwards()
		if self.roleInfo then
			self.roleInfo[UnityEngine.Animator]:Play("FX_roleInfo_end")
			UnityEngine.GameObject.Destroy(self.roleInfo.gameObject, 0.5);
			self.roleInfo = nil;
		end
	end	
	SGK.Action.DelayTime.Create(0.5):OnComplete(function() 
		self.isShowing = false;
	end)
end

--点击mask之后推进剧情
function View:MaskBtn()
	--点击遮罩后的处理
	if self.isShowing then
		return;
	end
	if self.isShowHero then
		self.isShowHero = false;
		if self.automationStatus then
			self.automationTime = Time.now()
		end
		self:HideAndShowRoleInfo(false);
		-- self:NextStory()
		self:DOPause_Text(function ( ... )
			if self.StoryData then
				self.StoryData = StoryConfig.GetStoryConf(self.StoryData.next_id)
				--print(self.StoryData)
			else
				self.StoryData = nil
			end
			self:UIRef()
		end)
	elseif self.automationStatus and not self.simulateMaskBtn then
		self.automationStatus = false
		self.view.TopMask.automation:SetActive(false)

		self.view.automationBtn:SetActive(not (self.StoryData.auto == 1 or self.StoryData.auto == 3 or self.StoryData.auto == 5 or self.StoryData.auto == 7))
		self.view.resetBtn:SetActive(not (self.StoryData.auto == 2 or self.StoryData.auto == 3 or self.StoryData.auto == 6 or self.StoryData.auto == 7))
		self.view.skipBtn:SetActive(not (self.StoryData.auto == 4 or self.StoryData.auto == 5 or self.StoryData.auto == 6 or self.StoryData.auto == 7))
	else
		self:DOPause_Text(function ( ... )
			if self.StoryData then
				self.StoryData = StoryConfig.GetStoryConf(self.StoryData.next_id)
				--print(self.StoryData)
			else
				self.StoryData = nil
			end
			self:UIRef()
		end)
	end
	self.simulateMaskBtn = false
end

local function cleanSpineAsset(animation)
	if animation ~= nil then
		animation.skeletonDataAsset = nil;
		animation:Initialize(true);
	end
end

function View:OnDisable()
	cleanSpineAsset(self.mainFrame.Camera.CG.animation[CS.Spine.Unity.SkeletonAnimation]);
	cleanSpineAsset(self.HeroAnimation1)
	cleanSpineAsset(self.HeroAnimation2)
	cleanSpineAsset(self.HeroAnimation3)
	SGK.BackgroundMusicService.SwitchMusic()
	self:CleanENV();
end

function View:GetAnimate()
	local animate = {
		obj = self.mainFrame.Camera.CG.animation,
		Script = self.mainFrame.Camera.CG.animation[CS.Spine.Unity.SkeletonAnimation],
		scale = 1,
	}

	--[[
	if SceneStack.CurrentSceneName() == "battle" then
		animate = {
			obj = self.view.cg.animationGraphic,
			Script = self.view.cg.animationGraphic[CS.Spine.Unity.SkeletonGraphic],
			hide = self.view.cg.animation,
			scale = 1,
			cameraActive = false,
		}
	end
	--]]
	animate.obj:SetActive(true);

	return animate;
end

function View:LoadENV(name)
	if self.last_env then
		if self.last_env.name == name then
			if self.last_env.obj then
				self.last_env.obj:SetActive(true);
				return;
			end
		else
			self:CleanENV();
		end
	end

	self.last_env = {name = name}

	SGK.ResourcesManager.LoadAsync("prefabs/battlefield/environment/".. name,function(o)
		if not o then
			return;
		end

		if self.last_env.name ~= name then
			return;
		end

		self.last_env.obj = SGK.UIReference.Instantiate(o, self.mainFrame.ENV.transform);
		local c = self.last_env.obj.transform:Find("MainCamera_avg_point")
		if c then
			CS.FollowTarget.Follow(self.mainFrame.Camera.gameObject, c, -1, true)
		end
	end)
end

function View:CleanENV()
	if self.last_env then
		if self.last_env.obj then
			UnityEngine.GameObject.Destroy(self.last_env.obj.gameObject);
			self.last_env = nil;
		end
	end
end

function View:UIRef(skip)--是否点击跳过
	local animate = self:GetAnimate();
		self.view.mask[CS.UGUIClickEventListener].interactable = true
		self.view.skipBtn[CS.UGUIClickEventListener].interactable = true
		--print(self.StoryData.story_id,sprinttb(animate))
	--if self.StoryData then
		if self.old_storydata and self.old_storydata.script and self.old_storydata.script ~= "0" and self.old_storydata.script ~= "" then
			AssociatedLuaScript("guide/"..self.old_storydata.script..".lua",{id = self.old_storydata.story_id,Function = self.Data.Function,state = self.Data.state,skipFlag = self.Data.skipFlag})
		--if self.old_storydata and self.old_storydata.script then
			--AssociatedLuaScript("guide/10009.lua",{id = self.old_storydata.story_id,Function = self.Data.Function,state = self.Data.state})
			if self.old_storydata.break_story and self.old_storydata.break_story == 1 then
				self:StoryReset()
			end
		end
		--print("zoe查看StoryData",sprinttb(self.StoryData))
		if self.StoryData then
			--ERROR_LOG(self.StoryData.story_id)
			-- local conf = {
			-- 	FontSize = 30,
			-- 	bgColor = {r= 230/255,g=1,b=0,a=1},
			-- 	DescDOTween = 1,
			-- 	HeroPos = Vector3(0,-700,0),
			-- 	role_size = Vector3(0.8,0.8,0.8),
			-- 	bgDOTween = 1,
			-- 	active_role = 1,
			-- 	}
			utils.SGKTools.StopPlayerMove()--播放剧情停止主角移动
			if self.btnInit then
				self.view[UnityEngine.RectTransform].anchoredPosition = UnityEngine.Vector2(0,0)
				self.view.skipBtn[UnityEngine.RectTransform].anchoredPosition = UnityEngine.Vector2(-83.8,-81.7)
				self.btnInit = false
			end
			self.view.TopMask.gameObject:SetActive(true)
			local desc = self.StoryData.dialog
			--if desc ~= "" then
				self.view.Root:SetActive(false)
				local old_storydata = self.old_storydata
				local role_id = self.StoryData.role
				if role_id ~= 0 then
					self:StoryUIChange(1,role_id,skip,old_storydata)
				else
					self:StoryRoleExit(1)
				end
				local role_id2 = self.StoryData.role2
				-- if self.view.Root.RightLiking.transform.childCount == 0 then
				-- 	DialogStack.PushPref("likingValue",{key = "right",id = role_id2},self.view.Root.RightLiking.gameObject)
				-- else
				-- 	DispatchEvent("update_likingValue_Key",{key = "right",id = role_id2})
				-- end
				if role_id2 ~= 0 then
					self:StoryUIChange(2,role_id2,skip,old_storydata)
				else
					self:StoryRoleExit(2)
				end

				local role_id3 = self.StoryData.role3 or 0
				if role_id3 ~= 0 then
					self:StoryUIChange(3,role_id3,skip,old_storydata)
				else
					self:StoryRoleExit(3)
				end
				--self.view.HeroPos.boss1.transform.localPosition = conf.HeroPos
				for k,v in pairs(self.StoryEffect)do
					if v and self.StoryEffect[k].remaining > 0 then
						local count = self.StoryEffect[k].remaining - 1
						if count > 0 then
							self.StoryEffect[k].remaining = self.StoryEffect[k].remaining - 1
						else
							UnityEngine.GameObject.Destroy(self.StoryEffect[k].gameObject)
							self.StoryEffect[k] = nil
						end
					end
				end
				if not self.automationStatus then
					if self.StoryData.auto == 0 then
						self.view.automationBtn:SetActive(true)
						self.view.resetBtn:SetActive(true)
						self.view.skipBtn:SetActive(true)
					else
						self.view.automationBtn:SetActive(not (self.StoryData.auto == 1 or self.StoryData.auto == 3 or self.StoryData.auto == 5 or self.StoryData.auto == 7))
						self.view.resetBtn:SetActive(not (self.StoryData.auto == 2 or self.StoryData.auto == 3 or self.StoryData.auto == 6 or self.StoryData.auto == 7))
						self.view.skipBtn:SetActive(not (self.StoryData.auto == 4 or self.StoryData.auto == 5 or self.StoryData.auto == 6 or self.StoryData.auto == 7))
					end
				end
				if self.StoryData.effect ~= "" then
					SGK.ResourcesManager.LoadAsync(self.view[SGK.UIReference],"prefabs/effect/".. self.StoryData.effect ..".prefab",function(o)
						local eff = GetUIParent(o,self.mainFrame.Camera.Effect)
           				eff.transform.localPosition = Vector3(self.StoryData.position_x,self.StoryData.position_y,0)
					   self.StoryEffect[self.StoryData.story_id] = {gameObject = eff,remaining = self.StoryData.stay}
					end)
				end
				if self.StoryData.cg_image ~= "0" and self.StoryData.cg_image_animation > 0 then
					if old_storydata and old_storydata.cg_image_animation == self.StoryData.cg_image_animation and old_storydata.cg_image == self.StoryData.cg_image then
						--ERROR_LOG("上下图一致")
					else
						for i = 1,self.view.cg_Image.transform.childCount do
							self.view.cg_Image[i]:SetActive(false)
						end
						self.view.cg_Image:SetActive(true)
						self.view.cg_Image[self.StoryData.cg_image_animation][UnityEngine.UI.Image]:LoadSpriteWithExt("cartoon_bg/" .. self.StoryData.cg_image)
						self.view.cg_Image[self.StoryData.cg_image_animation]:SetActive(true)
					end
				else
					for i = 1,self.view.cg_Image.transform.childCount do
						self.view.cg_Image[i]:SetActive(false)
					end
					self.view.cg_Image:SetActive(false)
				end
				-------------------------------------------------------------------------
				local liking_role_id = (self.StoryData.active_role == 1 and role_id or role_id2 or role_id3)
				-- ERROR_LOG('liking_role_id', liking_role_id);
				local npc_Friend_cfg = npcConfig.GetNpcFriendList()[liking_role_id]
				if npc_Friend_cfg then
					self.view.Root.NameGroup[1].bg:SetActive(false)
				else
					self.view.Root.NameGroup[1].bg:SetActive(true)
				end
				if self.view.Root.LeftLiking.transform.childCount == 0 then
					DialogStack.PushPref("likingValue",{key = "left",id = liking_role_id},self.view.Root.LeftLiking.gameObject)
				else
					DispatchEvent("update_likingValue_Key",{key = "left",id = liking_role_id})
				end
				-------------------------------------------------------------------------
				if self.StoryData.bg == "" or self.StoryData.bg == "0" then
					self.view.bg:SetActive(false)
					self:CleanENV();
				else
					local ending = '.prefab';
					if self.StoryData.bg:sub(-#ending) == ending then
						self.view.bg:SetActive(false)
						self:LoadENV(self.StoryData.bg);
					else
						self.view.bg:SetActive(true)
						self:CleanENV();
						if self.StoryData.bg ~= "" then
							self.view.bg[UnityEngine.UI.Image]:LoadSpriteWithExt("cartoon_bg/"..self.StoryData.bg,function ( ... )
								self.view.bg[UnityEngine.UI.Image]:SetNativeSize();
							end)
						end
					end
				end

				--对话框名字显示
				if self.StoryData.active_role == 1 then
					self.view.Root.NameGroup[1].name[UnityEngine.UI.Text].text = self.StoryData.name
					--self.view.Root.NameGroup[2].name[UnityEngine.UI.Text].text = self.StoryData.name
				elseif self.StoryData.active_role == 2 then
					self.view.Root.NameGroup[1].name[UnityEngine.UI.Text].text = self.StoryData.role2_name
					--self.view.Root.NameGroup[2].name[UnityEngine.UI.Text].text = self.StoryData.role2_name
				elseif self.StoryData.active_role == 3 then
					self.view.Root.NameGroup[1].name[UnityEngine.UI.Text].text = self.StoryData.role3_name
				else
					self.view.Root.NameGroup[1].name[UnityEngine.UI.Text].text = ""
					--self.view.Root.NameGroup[2].name[UnityEngine.UI.Text].text = ""
				end
				
				if self.StoryData.frame_type ~= 5 then
					self.descView = self.view.Root.desc[CS.InlineText]
				else
					self.descView = self.view.Root.BgGroup[5].desc[CS.InlineText]
				end
				self.view.Root.NameGroup[1]:SetActive(self.StoryData.frame_type ~= 5)
				self.view.Root.desc:SetActive(self.StoryData.frame_type ~= 5)
				self.descView.text = ""
				self.descView.fontSize = self.StoryData.font_size

				self.view.Root.NameGroup.gameObject:SetActive(self.StoryData.frame_type ~= 6)

				if self.StoryData.frame_type == 6 or self.StoryData.frame_type == 5 then
					self.descView.color = {r = 1,g = 1,b = 1,a = 1}
				else
					self.descView.color = {r = 0,g = 0,b = 0,a = 1}
				end

				for i = 1, 6 do
					self.view.Root.BgGroup[i]:SetActive(i == self.StoryData.frame_type)
					if i == self.StoryData.frame_type then
						self.view.Root.BgGroup[i][UnityEngine.UI.Image].color = {r= self.StoryData.frame_color_r/255,g=self.StoryData.frame_color_g/255,b=self.StoryData.frame_color_b/255,a=self.StoryData.frame_color_a/255}
					end
				end
				-- if self.StoryData.name ~= "" then
				-- 	desc = self.StoryData.name..":\n"..desc
				-- end
				self.descView:DOPause();
				if self.StoryData.font_show_type == 0 then
					self.descView.text = desc..self.StoryData.dialog_look
				else
					self.descView:DOText(desc,1);
					SGK.Action.DelayTime.Create(1):OnComplete(function()
						if self.StoryData and self.StoryData.dialog_look ~= "" then
							self.descView.text = desc..self.StoryData.dialog_look
						end
						if not self.StoryData or not StoryConfig.GetStoryConf(self.StoryData.next_id) then
							self:LoadOptions()
						end
					end)
				end
				self.view.Root:SetActive(true)
				self.view.mask[UnityEngine.AudioSource]:Stop()
				self.view.mask[UnityEngine.AudioSource].clip = nil
				if self.StoryData.sound ~= "0" then
					self.view.mask[SGK.AudioSourceVolumeController]:Play("sound/"..self.StoryData.sound .. ".mp3")
					self.view.mask[UnityEngine.AudioSource].volume = 1
					self.view[UnityEngine.AudioSource].volume = 0.5
					SGK.BackgroundMusicService.GetAudio(0.5)
					--DispatchEvent("PlayAudioSource",{playName = self.StoryData.sound})
				else
					self.view[UnityEngine.AudioSource].volume = 1
					SGK.BackgroundMusicService.GetAudio(System_Set_data.BgVoice or 0.75)
				end
				if self.StoryData.music == "1" then
					self.view[UnityEngine.AudioSource]:Stop()
					self.view[UnityEngine.AudioSource].clip = nil
				elseif self.StoryData.music ~= "0" then
					--self.view[SGK.AudioSourceVolumeController]:Play("sound/"..self.StoryData.music)
					--SGK.BackgroundMusicService.Pause()
					SGK.BackgroundMusicService.PlayMusic("sound/"..self.StoryData.music .. ".mp3");
				end
				if self.StoryData.sound_effect ~= "0" then
					self.mainFrame.Camera.Effect[SGK.AudioSourceVolumeController]:Play("sound/"..self.StoryData.sound_effect .. ".mp3")
				end
				self.old_storydata = self.StoryData
				self.view.mask:SetActive(true)
				self.view.HeroPos1:SetActive(true)
				self.view.HeroPos2:SetActive(true)
				self.view.HeroPos3:SetActive(true)
				self.view.Root:SetActive(true)
			-- else
			-- 	self.view.mask:SetActive(false)
			-- 	self.view.HeroPos:SetActive(false)
			-- 	self.view.HeroPos2:SetActive(false)
			-- 	self.view.Root:SetActive(false)
			-- end
			self.view.Root:SetActive(desc ~= "")
			if self.automationStatus then
				self.automationTime = Time.now()
			else
				self.automationTime = nil
			end
			local comicsName = self.StoryData.comics
			self.view.mask:SetActive(comicsName == "0")
			-- if self.Count == 2 then
			-- 	comicsName = "cg_comic1"
			-- 	self.view.mask:SetActive(false)
			-- 	self.view.HeroPos:SetActive(false)
			-- 	self.view.Root:SetActive(false)
			-- end
			if comicsName ~= "0" then
				--ERROR_LOG(comicsName)
				self.animationIdx = 1

				local FollowSpineBone = self.mainFrame.Camera.CG.animation.Effect[CS.FollowSpineBone]
				FollowSpineBone.boneName = ""
				local loader = animate.Script:UpdateSkeletonAnimation("cg/"..comicsName.."/"..comicsName.."_SkeletonData", {"animation1", ""})
				if loader then
					loader.onLoad = function()
						animate.obj[CS.SpineEventListener]:Watch();
					end
				end

				--self.view.cg.animation[SGK.BattlefieldObject]:Start()--切换spine重新注册event
				animate.obj[CS.SpineEventListener].onSpineEvent = function(eventName, strValue, intValue, floatValue)
					-- ERROR_LOG(eventName..">"..strValue..">"..intValue..">"..floatValue)
					--print(eventName, strValue, intValue, floatValue)
					self.mainFrame.Camera.CG.animation.Effect[CS.FollowSpineBone].boneName = ""
					if eventName == "u3d" then
						self.mainFrame.Camera.CG.animation.Effect[CS.FollowSpineBone].boneName = "u3d_"..intValue
						SGK.ResourcesManager.LoadAsync(animate.Script,"prefabs/effect/"..strValue..".prefab", function(o)
							local Effect = GetUIParent(o,self.mainFrame.Camera.CG.animation.Effect)
							Effect.transform.localPosition = Vector3.zero
						end);
					elseif eventName == "bgm" then
						--DispatchEvent("PlayAudioEffectSource",{playName = strValue})
						self.mainFrame.Camera.Effect[SGK.AudioSourceVolumeController]:Play("sound/"..strValue .. ".mp3")
					elseif eventName == "Loop" and not animate.Script.loop then
						animate.Script.AnimationState:SetAnimation(0,"animation"..self.animationIdx,true);
						animate.Script.loop = true
					elseif eventName == "break" then
						self:CG_next()
						-- self.StoryData = StoryConfig.GetStoryConf(self.StoryData.next_id)
						-- self:UIRef()
					end
				end
				-- self.mainFrame.Camera.CG.animation.transform.localPosition = Vector3(0,0,-1)
				-- self.mainFrame.Camera.CG.animation.transform.localScale = Vector3(animate.scale,animate.scale,animate.scale)
				-- self.mainFrame.Camera.CG[UnityEngine.UI.Image].color = self.StoryData.back == 0 and {r= 0,g=0,b=0,a=1} or {r= 0,g=0,b=0,a=0}
				self.mainFrame.Camera.CG:SetActive(true)
				self.mainFrame.Camera[UnityEngine.Camera].clearFlags = UnityEngine.CameraClearFlags.SolidColor;
				self.mainFrame.Canvas.CGNext:SetActive(true);
				self.view.TopMask.gameObject:SetActive(false)
				self.view.bg:SetActive(false);
				self.savedAutomationStatus = self.automationStatus
				self.automationStatus = false
				self.automationTime = Time.now()
				return
			else
				cleanSpineAsset(self.mainFrame.Camera.CG.animation[CS.Spine.Unity.SkeletonAnimation]);
				self.mainFrame.Camera.CG:SetActive(false)
				self.mainFrame.Camera[UnityEngine.Camera].clearFlags = UnityEngine.CameraClearFlags.Depth;
				self.mainFrame.Canvas.CGNext:SetActive(false);
			end
			if self.StoryData.story_choices ~= 0 then
				--self.view.mask[CS.UGUIClickEventListener].interactable = false
				--self:UIRef(true)
				self:StoryChoose()
				return
			end
			self.Count = self.Count + 1
			self.view.Root.next:SetActive(StoryConfig.GetStoryConf(self.StoryData.next_id) ~= nil and self.StoryData.frame_type ~= 5)
			if not StoryConfig.GetStoryConf(self.StoryData.next_id) and self.Data.state then
				if self.Data.Function then
					self.Data.Function()
					self.Data.Function = nil
				end
				self:LoadOptions()
				-- if self.StoryData.font_show_type == 0 then
				-- 	self:LoadOptions()
				-- else
				-- 	SGK.Action.DelayTime.Create(1):OnComplete(function()
				-- 		self:LoadOptions()
				-- 	end)
				-- end
			end
		else
			--print("11111")
			if self.old_storydata and tonumber(self.old_storydata.quest_id) ~= 0 then
				--print("zoe",sprinttb(self.old_storydata))
				local _cfg = module.QuestModule.Get(tonumber(self.old_storydata.quest_id))
				if _cfg and _cfg.is_show_on_task == 1 then
					_cfg.is_show_on_task = 0
				end
				module.QuestModule.Finish(tonumber(self.old_storydata.quest_id))
			end
			self:StoryReset()
			self.btnInit = true
			if self.Data.Function then
				self.Data.Function()
			end
			self:LoadOptions()
			-- LoadNpcDesc(10080004,"测试消息测试、\n消息测试消息测试",nil,2)
			-- LoadNpcDesc(nil,"测试消息测试、\n消息测试消息测试",nil,3)
		end
	--end
end

function View:LoadOptions()
	if not SceneStack.savedValues.NotMenuFlag then
		LoadStoryOptions()
	end
end

function View:NextStory()
	self.automationTime = Time.now()
	if self.mainFrame.Camera.CG.activeSelf then
		self:CG_next()
	else
		if self.StoryData then
			if self.StoryData.time > 0 then
				self.StoryData = StoryConfig.GetStoryConf(self.StoryData.next_id)
				self:UIRef()
			end
		else
			self.StoryData = nil
			self:UIRef()
		end
	end
end

function View:Update()
	if self.automationStatus and not self.isShowHero and self.StoryData.time > 0 and self.automationTime and Time.now() > self.automationTime + self.StoryData.time then
		self:NextStory()
	end
end

function View:CG_next()
	local animate = self:GetAnimate();

	for i = 1,self.mainFrame.Camera.CG.animation.Effect.transform.childCount do
		CS.UnityEngine.GameObject.Destroy(self.mainFrame.Camera.CG.animation.Effect.transform:GetChild(0).gameObject)
	end
	self.animationIdx = self.animationIdx + 1
	if animate.Script.skeletonDataAsset and animate.Script.skeletonDataAsset:GetSkeletonData():FindAnimation("animation"..self.animationIdx) then
		animate.Script.AnimationState:SetAnimation(0,"animation"..self.animationIdx,false);
		if self.automationStatus then
			self.automationTime = Time.now()
		else
			self.automationTime = nil
		end
	else
		self.StoryData = StoryConfig.GetStoryConf(self.StoryData.next_id)
		self:UIRef()
		self.automationStatus = self.savedAutomationStatus
		if self.automationStatus then
			self.automationTime = Time.now()
		else
			self.automationTime = nil
		end
	end
end
function View:StoryPlayback()
	local animate = self:GetAnimate();

	if self.view.resetBtn[UI.Button].interactable and self.old_storydata then
		self.automationStatus = false
		if self.mainFrame.Camera.CG.activeSelf then
			for i = 1,self.mainFrame.Camera.CG.animation.Effect.transform.childCount do
				CS.UnityEngine.GameObject.Destroy(self.mainFrame.Camera.CG.animation.Effect.transform:GetChild(0).gameObject)
			end
			self.animationIdx = self.animationIdx - 1
			if animate.Script.skeletonDataAsset:GetSkeletonData():FindAnimation("animation"..self.animationIdx) then
				animate.Script.AnimationState:SetAnimation(0,"animation"..self.animationIdx,false);
				if self.automationStatus then
					self.automationTime = Time.now()
				else
					self.automationTime = nil
				end
			else
				self.mainFrame.Camera.CG:SetActive(false)
				self.mainFrame.Canvas.CGNext:SetActive(false);
				self.mainFrame.Camera[UnityEngine.Camera].clearFlags = UnityEngine.CameraClearFlags.Depth;
				self:StoryPlayback()
			end
		else
			self.StoryData = StoryConfig.GetStoryConf_old(self.StoryData.story_id)
			self.old_storydata = StoryConfig.GetStoryConf_old(self.StoryData.story_id)
			if self.old_storydata then
				self.view.resetBtn[UI.Button].interactable = true
			else
				self.view.resetBtn[UI.Button].interactable = false
			end
			self:UIRef()
		end
	end
end
function View:HeroWaggle(obj,vec3,move_type)
	--ERROR_LOG(vec3.x)
	--local vec3 = obj[UnityEngine.RectTransform].localPosition
	if move_type == 0 then
		--obj[CS.Spine.Unity.SkeletonGraphic].color = {r= 1,g=1,b=1,a=1}
	elseif move_type == 1 then--角色下沉
	elseif move_type == 2 then--小幅度抖动
		self.DOTweenAnimation = obj.gameObject:GetComponent("DOTweenAnimation")
		self.DOTweenAnimation:DORewind()
		obj[UnityEngine.RectTransform].localPosition = Vector3(vec3.x-10,vec3.y,0)
		--DOTweenAnimation.duration = 10
		self.DOTweenAnimation.endValueV3 = Vector3(vec3.x + 10,vec3.y,0)
		self.DOTweenAnimation.loops = 0
		--self.DOTweenAnimation.tween:Rewind()
		--self.DOTweenAnimation.tween:Kill()
		if self.DOTweenAnimation.isValid then
			self.DOTweenAnimation:CreateTween()
			--self.DOTweenAnimation.tween:Play()
			self.DOTweenAnimation.tween:Play():OnComplete(function ( ... )
				obj[UnityEngine.RectTransform].localPosition = vec3
			end)
		end
	elseif move_type == 3 then--大幅度抖动
		self.DOTweenAnimation = obj.gameObject:GetComponent("DOTweenAnimation")
		self.DOTweenAnimation:DORewind()
		obj[UnityEngine.RectTransform].localPosition = Vector3(vec3.x-20,vec3.y,0)
		self.DOTweenAnimation.endValueV3 = Vector3(vec3.x + 20,vec3.y,0)
		self.DOTweenAnimation.loops = 0
		if self.DOTweenAnimation.isValid then
			self.DOTweenAnimation:CreateTween()
			self.DOTweenAnimation.tween:Play():OnComplete(function ( ... )
				obj[UnityEngine.RectTransform].localPosition = vec3
			end)
		end
	elseif move_type == 4 then--持续抖动
		self.DOTweenAnimation = obj.gameObject:GetComponent("DOTweenAnimation")
		self.DOTweenAnimation:DORewind()
		obj[UnityEngine.RectTransform].localPosition = Vector3(vec3.x-10,vec3.y,0)
		self.DOTweenAnimation.endValueV3 = Vector3(vec3.x + 10,vec3.y,0)
		self.DOTweenAnimation.loops = -1
		if self.DOTweenAnimation.isValid then
			self.DOTweenAnimation:CreateTween()
			self.DOTweenAnimation.tween:Play():OnComplete(function ( ... )
				obj[UnityEngine.RectTransform].localPosition = vec3
			end)
		end
	elseif move_type == 5 then--静止
		obj[CS.Spine.Unity.SkeletonGraphic].startingAnimation = ""
		obj[CS.Spine.Unity.SkeletonGraphic]:Initialize(true);
	elseif move_type == 6 then--黑影
		obj[CS.Spine.Unity.SkeletonGraphic].color = {r= 0,g=0,b=0,a=1}
	elseif move_type == 7 then--石化

	else
		self.DOTweenAnimation = obj.gameObject:GetComponent("DOTweenAnimation")
		self.DOTweenAnimation:DORewind()
	end
end

function View:StoryChoose()
	local check = {}
	local chooseId = nil
	if not self.StoryData or self.StoryData.story_choices == 0 then
		return
	end
	self.view.mask[CS.UGUIClickEventListener].interactable = false
	if not chooseId then
		chooseId=self.StoryData.story_choices
	end
	if self.automationStatus then
		self.automationStatus = false
		self.view.TopMask.automation:SetActive(false)

		self.view.automationBtn:SetActive(not (self.StoryData.auto == 1 or self.StoryData.auto == 3 or self.StoryData.auto == 5 or self.StoryData.auto == 7))
		self.view.resetBtn:SetActive(not (self.StoryData.auto == 2 or self.StoryData.auto == 3 or self.StoryData.auto == 6 or self.StoryData.auto == 7))
		self.view.skipBtn:SetActive(not (self.StoryData.auto == 4 or self.StoryData.auto == 5 or self.StoryData.auto == 6 or self.StoryData.auto == 7))
	end
	local consumeQuest = nil
	local chooseCfg = StoryConfig.GetStoryChooseConf(chooseId)
	for k,v in pairs(module.QuestModule.GetCfg()) do
        if v.id == chooseCfg[1].quest_id2 then
            --print("zoe查看任务配置",questid)
            consumeQuest = v
        end
	end
	local rewardCount = 0
	for i=1,3 do
		self.view.Root.chooseGroup["bg"..i].gameObject:SetActive(false)
	end
	for i=1,#chooseCfg do
		check["bg"..i] = nil 
		self.view.Root.chooseGroup["bg"..i].gameObject:SetActive(true)
	end
	for i=1,#chooseCfg do
		local quest_id = tonumber(chooseCfg[i].quest_id1)
		if module.QuestModule.Get(quest_id) and module.QuestModule.Get(quest_id).status == 1 then
		--if check["bg"..i] then
			rewardCount = rewardCount + 1
			check["bg"..i] = true
		end
		CS.UGUIClickEventListener.Get(self.view.Root.chooseGroup["bg"..i].gameObject).interactable = true
		self.view.Root.chooseGroup["bg"..i].desc[UI.Text].text = chooseCfg[i].desc1
		self.view.Root.chooseGroup["bg"..i].reward[UI.Text].text = chooseCfg[i].desc2
	end
	--print("zoe查看选项配置",rewardCount,sprinttb(chooseCfg))
	if rewardCount == 0 then
		for i=1,#chooseCfg do
			self.view.Root.chooseGroup["bg"..i][CS.UGUISpriteSelector].index = 0
			self.view.Root.chooseGroup["bg"..i].lock.gameObject:SetActive(false)
			self.view.Root.chooseGroup["bg"..i].reward[UI.Text].text = "<color=#ffd800>"..chooseCfg[i].desc2.."</color>"
			CS.UGUIClickEventListener.Get(self.view.Root.chooseGroup["bg"..i].gameObject).onClick = function()
				check["bg"..i] = true
				local obj = CS.UnityEngine.GameObject.Instantiate(SGK.ResourcesManager.Load("prefabs/effect/UI/fx_ui_xuanzhekuang.prefab"),self.view.Root.chooseGroup["bg"..i].gameObject.transform)
				local _obj = {}
				for j=1,#chooseCfg do
					CS.UGUIClickEventListener.Get(self.view.Root.chooseGroup["bg"..j].gameObject).interactable = false
					self.view.Root.chooseGroup["bg"..i][CS.UGUISpriteSelector].index = 1
					self.view.Root.chooseGroup["bg"..i].reward[UI.Text].text = "<color=#95fc19>已领取</color>"
					
					if i ~= j and not check["bg"..j] then
						--print(i,j)
						_obj[j] = CS.UnityEngine.GameObject.Instantiate(SGK.ResourcesManager.Load("prefabs/effect/UI/fx_ui_shangsuo.prefab"),self.view.Root.chooseGroup["bg"..j].lock.gameObject.transform)
						self.view.Root.chooseGroup["bg"..j].lock.gameObject:SetActive(true)
						self.view.Root.chooseGroup["bg"..j][CS.UGUISpriteSelector].index = 2
					end
				end

				module.QuestModule.Accept(tonumber(chooseCfg[i].quest_id1))
				self.view.mask[CS.UGUIClickEventListener].interactable = true
		        self.old_storydata = self.StoryData
				self.StoryData = StoryConfig.GetStoryConf(chooseCfg[i].story_id)
				SGK.Action.DelayTime.Create(0.6):OnComplete(function()
					self.view.Root.chooseGroup.gameObject:SetActive(false)
					self.view.Root.chooseGroup[UnityEngine.CanvasGroup].alpha = 0
					if obj then
						CS.UnityEngine.GameObject.Destroy(obj)
					end
					for k,v in pairs(_obj) do
						CS.UnityEngine.GameObject.Destroy(v)
					end
					self:MaskBtn()
			   	end)
			end
		end
	else
		for i=1,#chooseCfg do
			if check["bg"..i] then
				self.view.Root.chooseGroup["bg"..i][CS.UGUISpriteSelector].index = 1
				self.view.Root.chooseGroup["bg"..i].reward[UI.Text].text = "<color=#95fc19>已领取</color>"
				self.view.Root.chooseGroup["bg"..i].lock.gameObject:SetActive(false)
				CS.UGUIClickEventListener.Get(self.view.Root.chooseGroup["bg"..i].gameObject).onClick = function()
					for j=1,#chooseCfg do
						CS.UGUIClickEventListener.Get(self.view.Root.chooseGroup["bg"..j].gameObject).interactable = false
					end
					local obj = CS.UnityEngine.GameObject.Instantiate(SGK.ResourcesManager.Load("prefabs/effect/UI/fx_ui_xuanzhekuang.prefab"),self.view.Root.chooseGroup["bg"..i].gameObject.transform)
			        self.old_storydata = self.StoryData
					self.StoryData = StoryConfig.GetStoryConf(chooseCfg[i].story_id)
					-- self.view.Root.chooseGroup[UnityEngine.CanvasGroup]:DOFade(0,0.5):OnComplete(function ()
					-- 	self.view.Root.chooseGroup.gameObject:SetActive(false)
					-- end)
					self.view.mask[CS.UGUIClickEventListener].interactable = true
					SGK.Action.DelayTime.Create(0.4):OnComplete(function()
						self.view.Root.chooseGroup.gameObject:SetActive(false)
						self.view.Root.chooseGroup[UnityEngine.CanvasGroup].alpha = 0
						if obj then
							CS.UnityEngine.GameObject.Destroy(obj)
						end
						self:MaskBtn()
				   	end)
				end
			else
				self.view.Root.chooseGroup["bg"..i][CS.UGUISpriteSelector].index = 2
				self.view.Root.chooseGroup["bg"..i].lock.gameObject:SetActive(true)
				self.view.Root.chooseGroup["bg"..i].reward[UI.Text].text = "<color=#FFFFFFFF>"..chooseCfg[i].desc2.."</color>"
				local _desc = nil
				if module.ItemModule.GetItemCount(consumeQuest.consume_id1) < consumeQuest.consume_value1 then
	                _desc = "拥有"..module.ItemModule.GetConfig(consumeQuest.consume_id1).name..":<color=red>"..module.ItemModule.GetItemCount(consumeQuest.consume_id1).."</color>/"..consumeQuest.consume_value1
	            else
	            	_desc = "拥有"..module.ItemModule.GetConfig(consumeQuest.consume_id1).name..":<color=green>"..module.ItemModule.GetItemCount(consumeQuest.consume_id1).."</color>/"..consumeQuest.consume_value1
				end
				CS.UGUIClickEventListener.Get(self.view.Root.chooseGroup["bg"..i].gameObject).onClick = function()
					DispatchEvent("showDlgMsg",{
	                    msg = chooseCfg[i].desc3,
	                    confirm = function ( ... )
	                    	if module.ItemModule.GetItemCount(consumeQuest.consume_id1) < consumeQuest.consume_value1 then
	                    		showDlgError(nil,"所需物品不足")
	                    	else
	                    		check["bg"..i] = true
		                    	for j=1,#chooseCfg do
									CS.UGUIClickEventListener.Get(self.view.Root.chooseGroup["bg"..j].gameObject).interactable = false
								end
								local obj = nil
								SGK.Action.DelayTime.Create(0.1):OnComplete(function()	
									obj = CS.UnityEngine.GameObject.Instantiate(SGK.ResourcesManager.Load("prefabs/effect/UI/fx_ui_jiesuo.prefab"),self.view.Root.chooseGroup["bg"..i].lock.gameObject.transform)
							   	end)
								SGK.Action.DelayTime.Create(0.25):OnComplete(function()
		                    		self.view.Root.chooseGroup["bg"..i][CS.UGUISpriteSelector].index = 1
									self.view.Root.chooseGroup["bg"..i].reward[UI.Text].text = "<color=#95fc19>已领取</color>"
									self.view.Root.chooseGroup["bg"..i].lock.gameObject:SetActive(false)	
							   	end)

		                    	module.QuestModule.Accept(tonumber(chooseCfg[i].quest_id1))
		                    	module.QuestModule.Accept(tonumber(chooseCfg[i].quest_id2))
						        self.old_storydata = self.StoryData
								self.StoryData = StoryConfig.GetStoryConf(chooseCfg[i].story_id)

								-- self.view.Root.chooseGroup[UnityEngine.CanvasGroup]:DOFade(0,0.5):OnComplete(function ()
								-- 	self.view.Root.chooseGroup.gameObject:SetActive(false)
								-- end)
								SGK.Action.DelayTime.Create(0.7):OnComplete(function()
									self.view.Root.chooseGroup.gameObject:SetActive(false)
									self.view.Root.chooseGroup[UnityEngine.CanvasGroup].alpha = 0
									if obj then
										CS.UnityEngine.GameObject.Destroy(obj)
									end
									self:MaskBtn()
							   	end)    
								self.view.mask[CS.UGUIClickEventListener].interactable = true
							end
	                    end,
	                    cancel = function ( ... )
	                        DialogStack.Pop()
	                    end,
	                    desc = _desc,
	                    txtConfirm = "是",
	                    txtCancel = "否"})
				end
			end
		end
	end
	self.view.Root.chooseGroup.gameObject:SetActive(true)
	self.view.Root.chooseGroup[UnityEngine.CanvasGroup]:DOFade(1,1)
end

function View:StoryUIChange(id_S,roleid,skip,old_storydata)
	--print("zoe11111111",self.StoryData.story_id)
	local time = 0
	local setDelay = false
		local walk_off_vec3 = Vector3(self.StoryData["role"..id_S.."_posX"],self.StoryData["role"..id_S.."_posY"],0)
		if self.StoryData["role"..id_S] ~= 0 and self.old_storydata and self.old_storydata["role"..id_S] ~= self.StoryData["role"..id_S] or skip then--新人入场
			time = 0.15
			if self.StoryData["role"..id_S.."_exit_type"] == 1 then
				walk_off_vec3 = Vector3(self.StoryData["role"..id_S.."_posX"],-1000,0)
			elseif self.StoryData["role"..id_S.."_exit_type"] == 2 then
				walk_off_vec3 = ExitV3[""..1]
			elseif self.StoryData["role"..id_S.."_exit_type"] == 3 then
				walk_off_vec3 = ExitV3[""..2]
			elseif self.StoryData["role"..id_S.."_exit_type"] == 4 then
				--print("zoe_exit_type",self.StoryData.story_id)
				self.view["HeroPos"..id_S].boss1[UnityEngine.CanvasGroup]:DOFade(0,0.15)
				self.view.Root[UnityEngine.CanvasGroup]:DOFade(0,0.15)
				setDelay = true
			elseif self.StoryData["role"..id_S.."_exit_type"] == 0 then
				walk_off_vec3 = ExitV3[""..id_S]  --默认右退场
			end
		end
		if setDelay then
			--print("111111")
			SGK.Action.DelayTime.Create(0):OnComplete(function ()
				self:tweenAnim(id_S,roleid,skip,old_storydata,walk_off_vec3,time)
			end)
		else
			--print("222")
			self:tweenAnim(id_S,roleid,skip,old_storydata,walk_off_vec3,time)
		end
			
end

function View:tweenAnim(id_S,roleid,skip,old_storydata,walk_off_vec3,time)
	self.view["HeroPos"..id_S].transform:DOLocalMove(walk_off_vec3,time):OnComplete(function ( ... )
		-- self.view["HeroPos"..id_S].boss1.transform.localScale = Vector3(self.StoryData["role"..id_S.."_size"],self.StoryData["role"..id_S.."_size"],self.StoryData["role"..id_S.."_size"])
		self.view["HeroPos"..id_S].boss1.transform:DOScale(Vector3(self.StoryData["role"..id_S.."_size"],self.StoryData["role"..id_S.."_size"],self.StoryData["role"..id_S.."_size"]), 0.1);

		local actionName = nil;
		if not old_storydata or self.StoryData["role"..id_S.."_action"] ~= old_storydata["role"..id_S.."_action"] or old_storydata["role"..id_S] ~= self.StoryData["role"..id_S] or skip then
			actionName = self.StoryData["role"..id_S.."_action"];
		end
		if roleid == 11048 then
			self["HeroAnimation"..id_S].initialSkinName = "yuanshi"
		else
			self["HeroAnimation"..id_S].initialSkinName = "default"
		end
		if not old_storydata or (old_storydata and old_storydata["role"..id_S] ~= self.StoryData["role"..id_S]) or skip then--新人入场
			self["HeroAnimation"..id_S]:UpdateSkeletonAnimation("roles/"..roleid.."/"..roleid.."_SkeletonData", {"idle",actionName});
		elseif actionName then
			self["HeroAnimation"..id_S].startingAnimation = actionName
			self["HeroAnimation"..id_S].startingLoop = true
			self["HeroAnimation"..id_S]:Initialize(true);
		end
		--local Position,Scale = DATABASE.GetBattlefieldCharacterTransform(tostring(self.StoryData[self.Count].role), "ui");
		local pos = SGK.BattlefieldObject.GetskeletonGraphicBonePosition(self["HeroAnimation"..id_S], "hitpoint");
		--ERROR_LOG(pos.x..">"..pos.y..">"..pos.z)
		local now_pos = self.view["HeroPos"..id_S].boss1.transform.localPosition-- - pos
		--self.view.HeroPos2.boss1[UnityEngine.RectTransform].localPosition = now_pos
		self["HeroAnimation"..id_S].color = self.StoryData.active_role == id_S and {r= 1,g=1,b=1,a=1} or {r= 130/255,g=130/255,b=130/255,a=1}
		self.view["HeroPos"..id_S].boss1[UnityEngine.RectTransform].localPosition = self.StoryData.active_role == id_S and Vector3(now_pos.x,now_pos.y,-1) or Vector3(now_pos.x,now_pos.y,0)
		self.view["HeroPos"..id_S].boss1[UnityEngine.RectTransform].localEulerAngles = self.StoryData["role"..id_S.."_is_turn"] == 0 and Vector3.zero or Vector3(0,180,0)
		if self.StoryData["role"..id_S.."_enter_type"] == 4 then
			self.view["HeroPos"..id_S].boss1[UnityEngine.CanvasGroup].alpha=0
		end
		if self.StoryData["role"..id_S.."_enter_type"] == 4 then
			SGK.Action.DelayTime.Create(0.05):OnComplete(function ()
				self.view.Root[UnityEngine.CanvasGroup].alpha=1
			end)
		else
			self.view.Root[UnityEngine.CanvasGroup].alpha=1
		end
		if not old_storydata or (old_storydata and old_storydata["role"..id_S] ~= self.StoryData["role"..id_S]) or skip then--新人入场
			--print("zoe_enter_type",self.StoryData.story_id,self.StoryData["role"..id_S.."_enter_type"])
			if self.StoryData["role"..id_S.."_enter_type"] == 1 then
				self.view["HeroPos"..id_S].transform.localPosition = Vector3(self.StoryData["role"..id_S.."_posX"],-1000,0)
				self.view["HeroPos"..id_S].boss1[UnityEngine.CanvasGroup].alpha=1
			elseif self.StoryData["role"..id_S.."_enter_type"] == 2 then
				self.view["HeroPos"..id_S].transform.localPosition = ExitV3[""..1]
				self.view["HeroPos"..id_S].boss1[UnityEngine.CanvasGroup].alpha=1
			elseif self.StoryData["role"..id_S.."_enter_type"] == 3 then
				self.view["HeroPos"..id_S].transform.localPosition = ExitV3[""..2]
				self.view["HeroPos"..id_S].boss1[UnityEngine.CanvasGroup].alpha=1
			elseif self.StoryData["role"..id_S.."_enter_type"] == 4 then
				self.view["HeroPos"..id_S].boss1[UnityEngine.CanvasGroup].alpha=0
			elseif self.StoryData["role"..id_S.."_enter_type"] == 0 then
				self.view["HeroPos"..id_S].transform.localPosition = ExitV3[""..id_S]--默认右进场
				self.view["HeroPos"..id_S].boss1[UnityEngine.CanvasGroup].alpha=1
			end
		end
		if self.StoryData["role"..id_S.."_move_type"] == 6 or self.StoryData["role"..id_S.."_move_type"] == 0 then
			self:HeroWaggle(self.view["HeroPos"..id_S].boss1,now_pos,self.StoryData["role"..id_S.."_move_type"])
		end
		self.view["HeroPos"..id_S].transform:DOLocalMove(Vector3(self.StoryData["role"..id_S.."_posX"],self.StoryData["role"..id_S.."_posY"],0),0.15):OnComplete(function ( ... )
			if self.StoryData then
				if self.StoryData["role"..id_S.."_enter_type"] == 4 then
					self.view["HeroPos"..id_S].boss1[UnityEngine.CanvasGroup]:DOFade(1,0.15)
				end
				if self.StoryData["role"..id_S.."_move_type"] ~= 6 and self.StoryData["role"..id_S.."_move_type"] ~= 0 then
					self:HeroWaggle(self.view["HeroPos"..id_S].boss1,now_pos,self.StoryData["role"..id_S.."_move_type"])
				end
				if self.StoryData["role"..id_S.."_effect_point"] ~= "" and self.StoryData["role"..id_S.."_effect_name"] ~= "" then
					SGK.ResourcesManager.LoadAsync(self.view[SGK.UIReference],"prefabs/effect/"..self.StoryData["role"..id_S.."_effect_name"]..".prefab", function(o)
						local Effect = GetUIParent(o,self.view["HeroPos2"..id_S].boss1)
						Effect.transform.localPosition = SGK.BattlefieldObject.GetskeletonGraphicBonePosition(self["HeroAnimation"..id_S], self.StoryData["role"..id_S.."_effect_point"])*100
					end)
				end
				if self.StoryData["role"..id_S.."_look_point"] ~= "" and self.StoryData["role"..id_S.."_look_name"] ~= "" then
					self.view["HeroPos"..id_S].boss1.emoji[UnityEngine.UI.Image]:LoadSprite("Emoji/"..self.StoryData["role"..id_S.."_look_name"])
					self.view["HeroPos"..id_S].boss1.emoji[CS.FollowSpineBone].boneName = self.StoryData["role"..id_S.."_look_point"]
					self.view["HeroPos"..id_S].boss1.emoji[UnityEngine.UI.Image]:DOFade(1,0.5):OnComplete(function ( ... )
						self.view["HeroPos"..id_S].boss1.emoji[UnityEngine.UI.Image]:DOFade(0,0.5):OnComplete(function ( ... )
						end):SetDelay(1)
					end)
				end
			end
		end)
	end)
end

function View:StoryRoleExit(id_E)
	if self["HeroAnimation"..id_E].SkeletonDataAsset then--右边退场
	    self:HeroWaggle(self.view["HeroPos"..id_E].boss1,self.view["HeroPos"..id_E].boss1[UnityEngine.RectTransform].localPosition,self.StoryData["role"..id_E.."_move_type"])
		self["HeroAnimation"..id_E].color = self.StoryData.active_role == id_E and {r= 1,g=1,b=1,a=1} or {r= 130/255,g=130/255,b=130/255,a=1}
	end
	self.view["HeroPos"..id_E].transform:DOLocalMove(ExitV3[""..id_E],0.15)
end
function View:OnDestroy()
	DialogStack.Destroy("StoryFrame")
	SceneStack.savedValues.NotMenuFlag = false
	DispatchEvent("LOCAL_SOTRY_DIALOG_CLOSE")
	DispatchEvent("HeroCamera_DOOrthoSize",false)
end

return View
