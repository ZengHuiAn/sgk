local ManorManufactureModule = require "module.ManorManufactureModule"
local Time = require "module.Time"
local ManorModule = require "module.ManorModule"
local MapConfig = require "config.MapConfig"
local HeroModule = require "module.HeroModule"
local npcConfig = require "config.npcConfig"
local UserDefault = require "utils.UserDefault"

local View = {};
local MAX_VISITOR = 1;
local bodyColor = {"#7E7E7EFF", "#BCC0C0FF", "#FFFFFFD8", "#D2D2D2FF", "#D8D8D8FF", "#9E9E9EFF", "#CACACAFF", "#C9C9C9FF"}
local text_color = {"#68FF00FF", "#0041FFFF"}
local id_index = 0;
local ID_Dictionary = {};
local building_name = {};
-- building_name[1] = "yjs_jy";
-- building_name[2] = "gc_jy";
building_name[11] = "kuang_jy";

function View:Start(data)
	self.view = CS.SGK.UIReference.Setup(self.gameObject)
	self:InitData();
	self:IntiView();
	DispatchEvent("ENTER_MANOR_SCENE")
end

function View:InitData()
	local mapInfo = SceneStack.MapId("all");
	print("庄园主人", mapInfo.mapRoom)
	local pid = mapInfo.mapRoom or module.playerModule.GetSelfID();
	self.pid = pid;
	self.isMaster = pid == module.playerModule.GetSelfID();
	self.day = true;
	self.updateTime = 0;
	self.updateTime2 = 0;
	ManorManufactureModule.SetInManorScene(true, pid);
	self.manorProductInfo = ManorManufactureModule.Get(pid);
	self.visitorManager = ManorManufactureModule.GetVisitorManager();
	self.manager = HeroModule.GetManager(pid);
	self.manorProductInfo:GetProductLineFromServer();
	if #self.manorProductInfo:GetProductList() == 0 then
		self.manorProductInfo:GetProductListFromServer();
	end
	if not self.isMaster then
		DispatchEvent("HIDE_TASK_LIST");
		ManorManufactureModule.CheckOthersProductlineState(pid);
	else
		self.manorProductInfo:CheckWorkerProperty(true);
	end
	self.jiayuan = CS.SGK.UIReference.Setup(UnityEngine.GameObject.Find("jiayuan"));
	self.doors = CS.SGK.UIReference.Setup(UnityEngine.GameObject.Find("fx_door_s"));
	self.InterObject = CS.SGK.UIReference.Setup(UnityEngine.GameObject.Find("InterObject"));
	self.npcView = CS.SGK.UIReference.Setup(UnityEngine.GameObject.Find("npcView"));
	self.controller = self.jiayuan[SGK.MapWayMoveController];
	self.content = self.view.MapSceneController;
	self.character = {};
	self.visitor_count = 0;
	self.visitor = {};
	self.hangout = {};
	
	self.visitorConfig = ManorModule.GetManorOutsideConfig();
	self.doing_task = {}; 
	self.end_task = {};
	self.leader = {};
	self.npcBuffer = {};
	self.thief = {};
	self.talker = {};
	self.friendNpc = {};
	self.maintalker = 0;
	self.cur_operate_npc = 0;

	local manorInfo = ManorModule.LoadManorInfo();
	for i,v in ipairs(manorInfo) do
		if v.line ~= 0 then
			self:UpdateBuildingState(v.line);
		end
	end
end

function View:IntiView()
	local _t = os.date("*t", Time.now());
	if _t.hour > 5 and _t.hour < 19 then
		self.day = true;
		for i,v in ipairs(self.jiayuan) do
			if string.sub(tostring(v[UnityEngine.SpriteRenderer]), 1, 5) ~= "null:" then
				local _, _color = UnityEngine.ColorUtility.TryParseHtmlString("#FFFFFFFF");
				v[UnityEngine.SpriteRenderer].material.color = _color;
			end
		end
	else
		self.day = false;
		for i,v in ipairs(self.jiayuan) do
			if string.sub(tostring(v[UnityEngine.SpriteRenderer]), 1, 5) ~= "null:" then
				local _, _color = UnityEngine.ColorUtility.TryParseHtmlString(bodyColor[i]);
				v[UnityEngine.SpriteRenderer].material.color = _color;
			end
		end
	end

	self.controller:AddCallback("fade", function (obj)
		local npc = CS.SGK.UIReference.Setup(obj);
		--if string.sub(tostring(obj), 1, 5) == "null:" then
		if utils.SGKTools.GameObject_null(obj) then
			ERROR_LOG("obj is null");
		end
		npc.Character.Label[UnityEngine.CanvasGroup]:DOFade(0, 1);
		npc.Character.shadow[UnityEngine.SpriteRenderer].material:DOFade(0,1);
		npc.Character.Sprite[UnityEngine.MeshRenderer].material:DOFade(0,1):SetRelative(false):OnComplete(function ()
			if self.hangout[npc[SGK.MapPlayer].id] then
				local data = {};
				data.moving = false;
				data.outside = not self.hangout[npc[SGK.MapPlayer].id].goback;
				self.manorProductInfo:SetWorkerEvent(self.hangout[npc[SGK.MapPlayer].id].id, data);
				DispatchEvent("MANOR_NPC_END_MOVE", self.hangout[npc[SGK.MapPlayer].id]);
				self.hangout[npc[SGK.MapPlayer].id] = nil;
			elseif self.visitor[npc[SGK.MapPlayer].id] then
				local _visitor = self.visitorManager:GetVisitor(self.visitor[npc[SGK.MapPlayer].id].id);
				local next_move_time = {};
				for i,v in ipairs(_visitor.next_move_time) do
					if i == _visitor.pos + 1 then
						next_move_time[i] = Time.now() + math.random(10,15);
					else
						next_move_time[i] = v;
					end
				end
				self.visitorManager:SetVisitorInfo(self.visitor[npc[SGK.MapPlayer].id].id, {moving = false, next_move_time = next_move_time});
				DispatchEvent("MANOR_NPC_END_MOVE", self.visitor[npc[SGK.MapPlayer].id]);
				self.visitor[npc[SGK.MapPlayer].id] = nil;
			end
			self.controller:Remove(npc[SGK.MapPlayer].id)
		end);
		if self.leader[npc[SGK.MapPlayer].id] then
			for i,v in ipairs(self.leader[npc[SGK.MapPlayer].id].obj) do
				if i ~= 1 then
					v.Character.Label[UnityEngine.CanvasGroup]:DOFade(0, 1);
					v.Character.shadow[UnityEngine.SpriteRenderer].material:DOFade(0,1);
					v.Character.Sprite[UnityEngine.MeshRenderer].material:DOFade(0,1):SetRelative(false):OnComplete(function ()
						self.controller:Remove(v[SGK.MapPlayer].id);
					end)
				end
			end
			for i,v in ipairs(self.taskTeam) do
				if v.gid == self.leader[npc[SGK.MapPlayer].id].gid then
					ManorManufactureModule.SetTaskTeamInfo(v.gid, {enter_time = Time.now(), out_time = Time.now() + 6})
				end
			end
			DispatchEvent("MANOR_NPC_ENTER_TAVERN", {gid = self.leader[npc[SGK.MapPlayer].id].gid, staff = self.leader[npc[SGK.MapPlayer].id].staff});
			self.leader[npc[SGK.MapPlayer].id] = nil;
		end
	end)
	
	self.controller:AddCallback("teleport", function (obj)
		local npc = CS.SGK.UIReference.Setup(obj);
		local characterEffect = GetUIParent(SGK.ResourcesManager.Load("prefabs/effect/UI/fx_chuan_ren.prefab"),npc);
		characterEffect:SetActive(true);
		characterEffect.transform.localPosition = Vector3.zero;
		npc.Character.transform:DOScale(Vector3(0,1,1),0.25):OnComplete(function ()
			self.controller:Remove(npc[SGK.MapPlayer].id)
			if self.visitor[npc[SGK.MapPlayer].id] then
				-- self.visitor_count = self.visitor_count - 1;
				self.visitorManager:SetVisitorInfo(self.visitor[npc[SGK.MapPlayer].id].id, nil)
				self.visitor[npc[SGK.MapPlayer].id] = nil;
			end
		end):SetDelay(0.25)
		if self.leader[npc[SGK.MapPlayer].id] then
			for i,v in ipairs(self.leader[npc[SGK.MapPlayer].id].obj) do
				local characterEffect = GetUIParent(SGK.ResourcesManager.Load("prefabs/effect/UI/fx_chuan_ren.prefab"),v);
				characterEffect:SetActive(true);
				characterEffect.transform.localPosition = Vector3.zero;
				v.Character.transform:DOScale(Vector3(0,1,1),0.25):OnComplete(function ()
					self.controller:Remove(v[SGK.MapPlayer].id)
				end):SetDelay(0.25)
			end
			local gid = self.leader[npc[SGK.MapPlayer].id].gid;
			table.remove(self.taskTeam, 1)
			ManorManufactureModule.SetTaskTeamInfo(gid, nil);
			self.leader[npc[SGK.MapPlayer].id] = nil;
		end
	end)

	self.controller:AddCallback("npc_exit", function (obj)
		local npc = CS.SGK.UIReference.Setup(obj);
		local characterEffect = GetUIParent(SGK.ResourcesManager.Load("prefabs/effect/UI/fx_chuan_ren.prefab"),npc);
		characterEffect:SetActive(true);
		characterEffect.transform.localPosition = Vector3.zero;
		npc.Root.transform:DOScale(Vector3(0,1,1),0.25):OnComplete(function ()
			
			
		end):SetDelay(0.25)
	end)

	self.controller:AddCallback("addQuest", function (obj)
		local npc = CS.SGK.UIReference.Setup(obj);
		local id = npc[SGK.MapPlayer].id;
		local visitorConfig = self.visitorConfig[self.visitor[id].id]
		local visitor = self.visitorManager:GetVisitor(self.visitor[id].id);
		if visitor.quest_step ~= 0 then
			npc.Character.Label.quest:SetActive(true); 
			npc.Character.Label.quest.transform:DOLocalMove(Vector3(0,10,0),0.5):SetLoops(-1,CS.DG.Tweening.LoopType.Yoyo):SetRelative(true);
			UnityEngine.GameObject.Destroy(obj:GetComponent(typeof(CS.ModelClickEventListener)));
			npc[CS.SGK.MapInteractableMenu].enabled = true
			npc[CS.SGK.MapInteractableMenu].LuaTextName = "ManorNpcTalk"
			npc[CS.SGK.MapInteractableMenu].values = {visitorConfig["speak_id"..visitor.quest_step], visitorConfig["story_id"..visitor.quest_step], id, visitor.quest_step, visitorConfig["quest"..visitor.quest_step]}
			self.talker[id] = {{move_idx = id, obj = npc, quest_id = visitorConfig["quest"..visitor.quest_step]}};
		else
			self.controller:StartMove(id, "exit1", 0);
		end
	end)
	-- self.controller:AddCallback("exit", function (obj)
	-- 	local npc = CS.SGK.UIReference.Setup(obj);
	-- 	self.controller:StartMainWayJourney(npc[SGK.MapPlayer].id, "goout", "exit2", "out", 0);
	-- end)
	
	CS.ModelClickEventListener.Get(self.InterObject.manor_pub.gameObject).onClick = function (obj)
		DispatchEvent("Click_Something", self.doors.door_pub.gameObject.transform.position, self.doors.door_pub.gameObject)
	end
	CS.ModelClickEventListener.Get(self.InterObject.manor_pubTextLab.gameObject).onClick = function (obj)
		DispatchEvent("Click_Something", self.doors.door_pub.gameObject.transform.position, self.doors.door_pub.gameObject)
	end

	-- CS.ModelClickEventListener.Get(self.InterObject.manor_shop.gameObject).onClick = function (obj)
	-- 	DispatchEvent("Click_Something",self.doors.door_shop.gameObject.transform.position, self.doors.door_shop.gameObject)
	-- end

	-- CS.ModelClickEventListener.Get(self.InterObject.manor_shopTextLab.gameObject).onClick = function (obj)
	-- 	DispatchEvent("Click_Something",self.doors.door_shop.gameObject.transform.position, self.doors.door_shop.gameObject)
	-- end

	CS.ModelClickEventListener.Get(self.InterObject.manor_institute.gameObject).onClick = function (obj)
		DispatchEvent("Click_Something",self.doors.door_institute.gameObject.transform.position, self.doors.door_institute.gameObject)
	end
	CS.ModelClickEventListener.Get(self.InterObject.manor_instituteTextLab.gameObject).onClick = function (obj)
		DispatchEvent("Click_Something",self.doors.door_institute.gameObject.transform.position, self.doors.door_institute.gameObject)
	end

	CS.ModelClickEventListener.Get(self.InterObject.manor_smithy.gameObject).onClick = function (obj)
		DispatchEvent("Click_Something",self.doors.door_smithy.gameObject.transform.position, self.doors.door_smithy.gameObject)
	end
	CS.ModelClickEventListener.Get(self.InterObject.manor_smithyTextLab.gameObject).onClick = function (obj)
		DispatchEvent("Click_Something",self.doors.door_smithy.gameObject.transform.position, self.doors.door_smithy.gameObject)
	end

	CS.ModelClickEventListener.Get(self.InterObject.manor_mine.gameObject).onClick = function (obj)
		DispatchEvent("Click_Something",self.doors.door_mine.gameObject.transform.position, self.doors.door_mine.gameObject)
	end
	CS.ModelClickEventListener.Get(self.InterObject.manor_mineTextLab.gameObject).onClick = function (obj)
		DispatchEvent("Click_Something",self.doors.door_mine.gameObject.transform.position, self.doors.door_mine.gameObject)
	end
	CS.ModelClickEventListener.Get(self.InterObject.manor_mineSteal.gameObject).onClick = function (obj)
		DispatchEvent("Click_Something",self.doors.door_mine.gameObject.transform.position, self.doors.door_mine.gameObject)
	end
	if self.isMaster then
		self:CheckTalkers();
	else
		self:CheckFriendQuestNpc();
	end
end

function View:UpdateBuildingState(line)
	if building_name[line] then
		local state = self.manorProductInfo:GetLineState(line);
		if not utils.SGKTools.GameObject_null(self.jiayuan[building_name[line]]) then
			self.jiayuan[building_name[line]]:SetActive(state);
		end
		if not utils.SGKTools.GameObject_null(self.jiayuan[building_name[line].."_0"]) then
			self.jiayuan[building_name[line].."_0"]:SetActive(not state);
		end
	end
end

function View:LoadAnimation(animation, mode)
	local resource = SGK.ResourcesManager.Load("roles_small/"..mode.."/"..mode.."_SkeletonData.asset")
	animation.skeletonDataAsset = resource or SGK.ResourcesManager.Load("roles_small/11001/11001_SkeletonData.asset");
	animation:Initialize(true);	
end

function View:ShowEmoji(qipao, name)
	qipao:SetActive(true);
	local animation = qipao.animation[CS.Spine.Unity.SkeletonGraphic];
	animation.skeletonDataAsset = SGK.ResourcesManager.Load("manor/qipao/"..name.."/"..name.."_SkeletonData.asset")
	animation.startingAnimation = "animation";
	animation.startingLoop = true;
	animation:Initialize(true);
	qipao[UnityEngine.CanvasGroup]:DOFade(1,0.5);
end

function View:RemoveNpc(data)
	if data.id then
		local character = self.controller:Get(data.id);
		if character then
			local npc = CS.SGK.UIReference.Setup(character.obj)
			if npc then
				self.controller:Remove(data.id, false)
				npc.Character.Label[UnityEngine.CanvasGroup]:DOFade(0, 1);
				npc.Character.shadow[UnityEngine.SpriteRenderer].material:DOFade(0,1);
				npc.Character.Sprite[UnityEngine.MeshRenderer].material:DOFade(0,1):OnComplete(function ()
					UnityEngine.GameObject.Destroy(character.obj);
				end)
			end
		end
	end
end

function View:AddCharacter(id, prefab, parent)
	if ID_Dictionary[id] then
		local obj = self.controller:Get(ID_Dictionary[id]);
		if obj then
			return obj.obj,ID_Dictionary[id];
		end
	end
	id_index = id_index + 1
	ID_Dictionary[id] = id_index;
	local obj = nil;
	if parent then
		obj = self.controller:Add(ID_Dictionary[id], prefab, self.npcView.gameObject.transform);
	else
		obj = self.controller:Add(ID_Dictionary[id], prefab);
	end
	return obj,ID_Dictionary[id];
end

function View:MoveNpc(data)
	local mode = 0;
	local chat_cfg = nil;
	local name = "";
	local id = 0;
	local move_type = data.type or "";
	if move_type == "visit"  then
		id = tonumber((tostring(os.time()):reverse():sub(1, 7)));
		mode = self.visitorConfig[data.uuid].role_id;
		chat_cfg = self.visitorConfig[data.uuid];
		name = self.visitorConfig[data.uuid].role_name;
	elseif move_type == "outside" or move_type == "eating" then
		local hero = self.manager:GetByUuid(data.uuid);
		id = data.uuid;
		mode = hero.mode;
		name = hero.name;
		chat_cfg = ManorModule.GetManorChat2(hero.id);
	else
		ERROR_LOG("未知类型",sprinttb(data))
		local hero = self.manager:GetByUuid(data.uuid);
		id = data.uuid;
		mode = hero.mode;
		name = hero.name;
		chat_cfg = ManorModule.GetManorChat2(hero.id);
	end
	local obj,move_idx  = self:AddCharacter(move_type..id, self.content.ManorNPCPrefab.gameObject, self.content.gameObject.transform);
	if obj then
		local item = CS.SGK.UIReference.Setup(obj);
		obj.name = "MoveNpc_"..move_idx;
		local animation = item.Character.Sprite[CS.Spine.Unity.SkeletonAnimation];     
		self:LoadAnimation(animation, mode);
		item.Character.Label.name[UnityEngine.UI.Text]:TextFormat(name);

		local taget = 0;	
		if data.args then
			if data.args.taget then
				taget = data.args.taget;
			elseif data.args.random then
				taget = -1;
			end
		end
		if move_type == "outside" or move_type == "visit" then
			if move_type == "outside" then
				local hangout = {};
				hangout.id = data.uuid;
				hangout.to = data.to;
				hangout.from = data.from;
				hangout.goback = data.args.goback;
				hangout.type = "outside";
				self.hangout[move_idx] = hangout; 
				DispatchEvent("MANOR_NPC_START_MOVE", hangout);
				self:ShowEmoji(item.Character.Label.qipao, "icon_jidi_fanhou");
			elseif move_type == "visit" then
				local visitor = {};
				visitor.next_time = Time.now() + math.random(8,15)
				visitor.to = data.to;
				visitor.from = data.from;
				visitor.roleID = id;
				visitor.id = data.uuid;
				visitor.type = "visit";
				self.visitor[move_idx] = visitor;
				DispatchEvent("MANOR_NPC_START_MOVE", visitor);
			end
			CS.ModelClickEventListener.Get(obj).onClick = function (obj)
				local character = self.controller:Get(move_idx);
				assert(character, move_idx.."不存在")
				if not character.pause and chat_cfg then
					self.controller:isStopped(move_idx, true);
					local effect = SGK.ResourcesManager.Load("prefabs/effect/UI/fx_xuanren.prefab")
					local effect_obj = CS.UnityEngine.GameObject.Instantiate(effect, character.obj.transform)
					effect_obj.transform.localPosition = Vector3(0,-0.1,0);
					coroutine.resume(coroutine.create( function ()
						Sleep(0.1)
						character.player:SetDirection(0);
						local name_text = CS.SGK.UIReference.Setup(character.obj).Character.Label.name;
						local _, color = UnityEngine.ColorUtility.TryParseHtmlString(text_color[2]);
						name_text[UnityEngine.UI.Text].color = color;
						self:NpcSpeak(move_idx, 1, chat_cfg["click_words"..math.random(1,3)], function ()
							self.controller:isStopped(move_idx, false);
							UnityEngine.GameObject.Destroy(effect_obj);
							local _, color = UnityEngine.ColorUtility.TryParseHtmlString(text_color[1]);
							name_text[UnityEngine.UI.Text].color = color;
						end, text_color[2])
					end));
				end
			end
		elseif move_type == "eating" then
			if data.from == "tavern" then
				self:ShowEmoji(item.Character.Label.qipao, "icon_jidi_xinxin");
			else
				self:ShowEmoji(item.Character.Label.qipao, "icon_jidi_fanzhong");
			end
		end

		obj:SetActive(true);
		if data.from then
			if data.from == "exit1" and taget == 0 then
				obj.transform.position = self.controller:GetWayPosition("exit1", 0);
				item.Character.transform.localScale = Vector3(0,1,1);
				local characterEffect = GetUIParent(SGK.ResourcesManager.Load("prefabs/effect/UI/fx_chuan_ren.prefab"),item);
				characterEffect:SetActive(true);
				characterEffect.transform.localPosition = Vector3.zero;
				item.Character.transform:DOScale(Vector3(1,1,1),0.25):OnComplete(function ()
					self.controller:StartMainWayJourney(move_idx, "main", data.from, data.to, taget);
				end):SetDelay(0.25);
			else
				self.controller:StartMainWayJourney(move_idx, "main", data.from, data.to, taget);
			end
		else
			self.controller:StartMove(move_idx, data.to, taget)
		end
	else
		ERROR_LOG("obj is null");
	end
end

function View:WaitNpc(data)
	for i,v in ipairs(data) do
		local hero = self.manager:GetByUuid(v.uuid)
		local obj,move_idx = self:AddCharacter("eating"..v.uuid, self.content.ManorNPCPrefab.gameObject, self.content.gameObject.transform);
		if obj then
			obj.name = "MoveNpc_"..move_idx;
			local item = CS.SGK.UIReference.Setup(obj);
			local animation = item.Character.Sprite[CS.Spine.Unity.SkeletonAnimation];     
			self:LoadAnimation(animation, hero.mode);
			item.Character.Label.name[UnityEngine.UI.Text]:TextFormat(hero.name);
			item[SGK.MapPlayer]:SetDirection(6);
			item.gameObject.transform.position = self.controller:GetWayPosition("list"..i, 0);
			self:ShowEmoji(item.Character.Label.qipao, "icon_jidi_fanzhong");
			obj:SetActive(true);
		end
	end
end

function View:AddVisitor(gid)
	local idx = math.random(1,3)
	local visitor = self.visitorConfig[gid];

	local roleID = tonumber((tostring(os.time()):reverse():sub(1, 7)))
	local obj,move_idx = self:AddCharacter("visit"..roleID, self.content.ManorNPCPrefab.gameObject, self.content.gameObject.transform);
	if obj then
		obj.name = "MoveNpc_"..move_idx;
		local item = CS.SGK.UIReference.Setup(obj);
		local animation = item.Character.Sprite[CS.Spine.Unity.SkeletonAnimation];     
		self:LoadAnimation(animation, visitor.role_id);
		item.Character.Label.name[UnityEngine.UI.Text]:TextFormat(visitor.role_name);
		item[UnityEngine.AI.NavMeshAgent].speed = 0.8;
		obj.transform.position = self.controller:GetWayPosition("visitor"..idx, 0);
		item.Character.transform.localScale = Vector3(0,1,1);
		obj:SetActive(true);
		local characterEffect = GetUIParent(SGK.ResourcesManager.Load("prefabs/effect/UI/fx_chuan_ren.prefab"),item);
		characterEffect:SetActive(true);
		characterEffect.transform.localPosition = Vector3.zero;
		item.Character.transform:DOScale(Vector3(1,1,1),0.25):OnComplete(function ()
			self.visitor[move_idx] = {next_time = Time.now() + math.random(8,15), roleID = roleID, id = visitor.gid};
			self.controller:StartMove(move_idx, "visitor"..idx, 0);
		end):SetDelay(0.25);
		CS.ModelClickEventListener.Get(obj).onClick = function (obj)
			local character = self.controller:Get(move_idx);
			assert(character, move_idx.."不存在")
			if not character.pause then
				self.controller:isStopped(move_idx, true);
				local effect = SGK.ResourcesManager.Load("prefabs/effect/UI/fx_xuanren.prefab")
				local effect_obj = CS.UnityEngine.GameObject.Instantiate(effect, character.obj.transform)
				effect_obj.transform.localPosition = Vector3(0,-0.1,0);
				coroutine.resume(coroutine.create( function ()
					Sleep(0.1)
					character.player:SetDirection(0);
					local name_text = CS.SGK.UIReference.Setup(character.obj).Character.Label.name;
					local _, color = UnityEngine.ColorUtility.TryParseHtmlString(text_color[2]);
					name_text[UnityEngine.UI.Text].color = color;
					self:NpcSpeak(move_idx, 1, visitor["click_words"..math.random(1,3)], function ()
						self.controller:isStopped(move_idx, false);
						UnityEngine.GameObject.Destroy(effect_obj);
						local _, color = UnityEngine.ColorUtility.TryParseHtmlString(text_color[1]);
						name_text[UnityEngine.UI.Text].color = color;
					end, text_color[2])
				end));
			end
			-- self.controller:isStopped(roleID, true);
			-- character.player:SetDirection(0);
		end
	end
end

function View:AddQuestNpc(quest_id, startPos, endPos)
	local questCfg = module.QuestModule.GetCfg(quest_id);
	if questCfg and questCfg.accept_npc_id ~= 0 then
		local id = questCfg.accept_npc_id;
		local data = MapConfig.GetMapMonsterConf(id);
		if data and self.npcBuffer[id] == nil then
			local pos = self.controller:GetWayPosition(startPos, 0);
			LoadNpc(data, pos);
			self.npcBuffer[id] = {};
			self.npcBuffer[id].startPos = startPos;
			self.npcBuffer[id].endPos = endPos;
		end
	end
end

function View:LoadNpc(id)
	if self.npcBuffer and self.npcBuffer[id] then
		local obj,move_idx = self:AddCharacter("quest"..id, self.npcBuffer[id].npc.gameObject);
		self.npcBuffer[id].move_idx = move_idx;
		obj.name = "MoveNpc_"..move_idx;
		local item = CS.SGK.UIReference.Setup(obj);
		item[UnityEngine.AI.NavMeshAgent].speed = 0.8;
		item[UnityEngine.AI.NavMeshAgent].stoppingDistance = 0.05;
		obj:SetActive(true);
		if self.npcBuffer[id].startPos ~= self.npcBuffer[id].endPos then
			local characterEffect = GetUIParent(SGK.ResourcesManager.Load("prefabs/effect/UI/fx_chuan_ren.prefab"),item);
			characterEffect:SetActive(true);
			characterEffect.transform.localPosition = Vector3.zero;
			item.transform:DOScale(Vector3(1,1,1),0.25):OnComplete(function ()
				-- self.controller:StartMove(move_idx, "patrol", 0);
				self.controller:StartMainWayJourney(move_idx, "main", self.npcBuffer[id].startPos, self.npcBuffer[id].endPos, 0);
			end):SetDelay(0.25);
		end
	elseif self.talker and id == self.maintalker and self.talker[id] then
		if self.talker[id].cfg["rumour_id"..self.talker[id].step] ~= 0 then
			self:TalkerSpeak(self.talker[id].cfg["rumour_id"..self.talker[id].step]);
		end
	end
end

function View:AddThief(line, endTime)
	local point = "";
	local npc_id = 0;
	if line == 1 then
		point = "thief1"
		npc_id = 9026730
	elseif line == 2 then
		point = "thief2"
		npc_id = 9026731
	elseif line == 11 then
		point = "thief11"
		npc_id = 9026732
	end
	local data = MapConfig.GetMapMonsterConf(npc_id);
	if data then
		local pos = self.controller:GetWayPosition(point, 0);
		LoadNpc(data, pos);
		self.thief[line] = {};
		self.thief[line].endTime = endTime;
		self.thief[line].npc_id = npc_id;
	else
		ERROR_LOG("小偷NPC配置不存在")
	end
end

function View:RemoveThief(line)	
	local npc = self.thief[line].npc;
	module.NPCModule.RemoveNPC(self.thief[line].npc_id);
	local characterEffect = GetUIParent(SGK.ResourcesManager.Load("prefabs/effect/UI/fx_chuan_ren.prefab"),npc);
	characterEffect:SetActive(true);
	characterEffect.transform.localPosition = Vector3.zero;
	npc.gameObject.transform:DOScale(Vector3(0,1,1),0.25):OnComplete(function ()
		UnityEngine.GameObject.Destroy(npc.gameObject);
	end):SetDelay(0.25)
	self.thief[line] = nil;
end

-- function View:AddOtherTalker(talker_id, step)
-- 	local visitorConfig = self.visitorConfig[self.visitor[talker_id].id]
-- 	local others = StringSplit(visitorConfig["npc"..step],"|")
-- 	for i,v in ipairs(others) do
-- 		local npc_id = tonumber(v);
-- 		if self.talker[talker_id] ~= nil and self.talker[talker_id][npc_id] == nil then
-- 			local npc_cfg = npcConfig.GetnpcList()[npc_id];
-- 			if npc_cfg then
-- 				local obj,move_idx  = self:AddCharacter("otherTalker"..npc_id, self.content.ManorNPCPrefab.gameObject, self.content.gameObject.transform);
-- 				if obj then
-- 					local item = CS.SGK.UIReference.Setup(obj);
-- 					obj.name = "MoveNpc_"..move_idx;
-- 					if i == 1 then
-- 						item[UnityEngine.AI.NavMeshAgent].speed = 1.8;
-- 					else
-- 						item[UnityEngine.AI.NavMeshAgent].speed = 3;
-- 					end
-- 					local animation = item.Character.Sprite[CS.Spine.Unity.SkeletonAnimation];     
-- 					self:LoadAnimation(animation, npc_cfg.mode);
-- 					item.Character.Label.name[UnityEngine.UI.Text]:TextFormat(npc_cfg.name);
-- 					obj.transform.position = self.controller:GetWayPosition("talk1_"..i, 0);
-- 					self.controller:StartMove(move_idx, "talk1_"..i, 0);
-- 					obj:SetActive(true);
-- 					self.talker[talker_id][npc_id] = {move_idx = move_idx, obj = item}
-- 				end
-- 			end
-- 		elseif self.talker[talker_id] and self.talker[talker_id][npc_id] then
-- 			print("其他对话者已存在");
-- 		end
-- 	end
-- end

-- function View:TalkersLeave(talker_id)
-- 	if self.talker[talker_id] then
-- 		self.talker[talker_id][1].obj.Character.Label.quest:SetActive(false);
-- 		self.talker[talker_id][1].obj[CS.SGK.MapInteractableMenu].enabled = false;
-- 		for i,v in pairs(self.talker[talker_id]) do
-- 			v.obj[UnityEngine.AI.NavMeshAgent].speed = 1;
-- 			self.controller:StartMove(v.move_idx, "exit1", 0)
-- 		end
-- 	end
-- end

function View:CheckTalkers()
	local talker = ManorManufactureModule.CheckTalker();
	if talker and talker.step then
		local npc_id = talker.cfg["npc_id"..talker.step];
		local data = MapConfig.GetMapMonsterConf(npc_id);
		if data then
			local pos = self.controller:GetWayPosition("talk1", 1);
			self.maintalker = npc_id;
			LoadNpc(data, pos);
			print("加载Talker NPC", npc_id)
			self.talker[npc_id] = {};
			self.talker[npc_id].step = talker.step;
			self.talker[npc_id].cfg = talker.cfg;
			local others = StringSplit(talker.cfg["npc"..talker.step],"|")
			for i,v in ipairs(others) do
				local _npc_id = tonumber(v);
				local _data = MapConfig.GetMapMonsterConf(_npc_id);
				if _data then
					local _pos = self.controller:GetWayPosition("talk1_"..i, 1);
					self.talker[_npc_id] = {};
					LoadNpc(_data, _pos);
				end
			end
		end
	end
end

function View:TalkerSpeak(speak_id)
	local rumourConfig = ManorModule.GetManorRumourConfig(speak_id);
	if rumourConfig then
		local npc_id = rumourConfig.npc_id;
		if self.talker[npc_id] and self.talker[npc_id].npc then
			if rumourConfig.next_id ~= 0 then
				ShowNpcDesc(self.talker[npc_id].npc.Root.Canvas.dialogue, rumourConfig.dialog, function ()
					if rumourConfig.delay ~= 0 then
						SGK.Action.DelayTime.Create(rumourConfig.delay):OnComplete(function()
							self:TalkerSpeak(rumourConfig.next_id);
						end)
					else
						self:TalkerSpeak(rumourConfig.next_id);
					end
				end, 1)
			else
				ShowNpcDesc(self.talker[npc_id].npc.Root.Canvas.dialogue, rumourConfig.dialog, nil, 1)
			end
		else
			print("NPC不存在", npc_id)
		end	
	else
		print("对话不存在", speak_id)
	end
end

function View:Speak(npc_view, type, str, func, color)
	if str == "" then
		if func then
			func()
		end
		return;
	end
	if npc_view then
		npc_view.dialogue:SetActive(true);
		npc_view.dialogue.bg1:SetActive(type == 1)
		npc_view.dialogue.bg2:SetActive(type == 2)
		npc_view.dialogue.bg3:SetActive(type == 3)
		local _str,row =  self:utf8sub(str, 39);
		if color then
			_str = "<color="..color..">".._str.."</color>"
		end
		-- print("说话", _str)
		npc_view.dialogue.desc[UnityEngine.UI.Text].text =_str

		if npc_view.qipao and npc_view.qipao.activeSelf then
			npc_view.qipao[UnityEngine.CanvasGroup]:DOFade(0,0.5):OnComplete(function()
				npc_view.dialogue[UnityEngine.CanvasGroup]:DOFade(1,1):OnComplete(function()
					npc_view.dialogue[UnityEngine.CanvasGroup]:DOFade(0,1):OnComplete(function()
						npc_view.dialogue.desc[UnityEngine.UI.Text].text = "";
						if func then
							func()
						end
						npc_view.qipao[UnityEngine.CanvasGroup]:DOFade(1,0.5);
					end):SetDelay(row)
				end)        
			end)
		else
			npc_view.dialogue[UnityEngine.CanvasGroup]:DOFade(1,1):OnComplete(function()
				npc_view.dialogue[UnityEngine.CanvasGroup]:DOFade(0,1):OnComplete(function()
					npc_view.dialogue.desc[UnityEngine.UI.Text].text = "";
					if func then
						func()
					end
				end):SetDelay(row)
			end)
		end
	else
		ERROR_LOG("npc_view not exist")
	end
end

function View:NpcSpeak(id, type, str, func, color)
	local npc = self.controller:Get(id);
	if npc then
		local npc_view = CS.SGK.UIReference.Setup(npc.obj).Character.Label;
		self:Speak(npc_view, type, str, func, color)
	end
end

function View:CreateTeam(gid,staff,start)
	local staff_obj = {};
	local team_id = {};
	for i,v in ipairs(staff) do
		local hero = self.manager:GetByUuid(v);
		local roleID = v;
		local obj,move_idx  = self:AddCharacter("team"..roleID, self.content.ManorNPCPrefab.gameObject, self.content.gameObject.transform);
		table.insert(team_id, move_idx)
		if obj then
			obj.name = "MoveNpc_"..move_idx;
			local item = CS.SGK.UIReference.Setup(obj);
			local animation = item.Character.Sprite[CS.Spine.Unity.SkeletonAnimation];     
			self:LoadAnimation(animation, hero.mode);
			item.Character.Label.name[UnityEngine.UI.Text]:TextFormat(hero.name);
			item[UnityEngine.AI.NavMeshAgent].speed = 0.7;
			item.Character.Label.leader:SetActive(i == 1);
			if start then
				obj.transform.position = self.controller:GetWayPosition("patrol", 0);
			else
				obj.transform.position = self.controller:GetWayPosition("tavern", 0);
			end
			obj:SetActive(true);
			if i ~= 1 then
				item.Character.Sprite[SGK.CharacterSprite].minStatusChangeTime = 0;
				local folow = obj:AddComponent(typeof(CS.SGK.FollowMovement3d));
				folow.TargetTF = staff_obj[i - 1].gameObject.transform;
				folow.RecordGap = 0.01;
				-- folow.StartRunCount = 30;
				folow.StopCount = 20;
				folow.WalkSpeed = 0.7;
				-- folow:Reset();
			end
			staff_obj[i] = item;
			item.Character.Sprite[SGK.CharacterSprite].enabled = false;
			item.Character.Sprite[SGK.CharacterSprite].enabled = true;
		end
	end
	local info = {};
	info.obj = staff_obj;
	info.gid = gid;
	info.staff = staff;
	info.speak_time = start and 0 or Time.now() + math.random(5,6)
	info.team_id = team_id;
	self.leader[staff_obj[1][SGK.MapPlayer].id] = info;

	if start then
		self.controller:StartMove(staff_obj[1][SGK.MapPlayer].id, "tavern", 0);	
	else
		local way = math.random(1,2);
		if way == 1 then
			self.controller:StartMove(staff_obj[1][SGK.MapPlayer].id, "exit1", 0);
		else
			self.controller:StartMove(staff_obj[1][SGK.MapPlayer].id, "exit2", 0);
		end
		-- self.controller:StartMove(staff_obj[1][SGK.MapPlayer].id, "patrol", 0);
	end
end

function View:CheckFriendQuestNpc()
	local quest = module.QuestModule.GetList(23, 0)[1];
	local manor_friend_quest = UserDefault.Load("manor_friend_quest", true);
	if quest == nil or Time.now() >= quest.accept_time + quest.time_limit then
		return;
	end
	if manor_friend_quest.quest and manor_friend_quest.quest[quest.id] then
		-- print("好友任务",sprinttb(manor_friend_quest.quest))
		for _,v in ipairs(manor_friend_quest.quest[quest.id]) do
			if v.pid == self.pid then
				for npc_id,j in pairs(v.npc) do
					if j.active then
						local cfg = MapConfig.GetMapMonsterConf(npc_id);
						if cfg then
							local time = quest.accept_time + quest.time_limit;
							print("加载好友任务NPC", cfg.name, time)
							LoadNpc(cfg);
							self.friendNpc[npc_id] = {dead_time = time}
						else
							print("npc配置不存在", npc_id)
						end
					end
				end
			end
		end
	end
end

-- function View:RemoveTeam(gid)
-- 	if self.taskTeam[gid] then
-- 		for i,v in ipairs(self.taskTeam[gid].obj) do
-- 			if i == 1 then
-- 				self.controller:Remove(v[SGK.MapPlayer].id);
-- 			else
-- 				UnityEngine.GameObject.Destroy(v.gameObject);
-- 			end
-- 		end
-- 		self.taskTeam[gid] = nil;
-- 		ManorManufactureModule.SetTaskTeamInfo(gid, nil);
-- 	end
-- end

function View:UpdateNpcStatus()	--刷新庄园总管头上的感叹号
	if self.isMaster then
		local npc_id = 2026000;
		local tavern = module.RedDotModule.Type.Manor.Tavern.check();
		if tavern then
			DispatchEvent("localNpcStatus",{gid = npc_id, icon = "bn_ts3"})
		else
			local _canOperate, _canGather, _overView = module.RedDotModule.Type.Manor.Manufacture.check();
			if _overView then
				DispatchEvent("localNpcStatus",{gid = npc_id, icon = "bn_ts3"})
			else
				DispatchEvent("localNpcStatus",{gid = npc_id, icon = 0})
			end
		end
	end
end

function View:UpdateStealButton()
	if self.isMaster then
		return;
	end	
	self.InterObject.manor_mineSteal:SetActive(false);
	local pos = ManorModule.GeyPosByInterval(4);
	local manorInfo = ManorModule.LoadManorInfo();
	for i,v in ipairs(pos) do
		local canSteal = self.manorProductInfo:CanSteal(manorInfo[v].line);
		if canSteal then
			self.InterObject.manor_mineSteal:SetActive(true);
			break;
		end
	end
end

function View:utf8sub(input,size)
	local len  = string.len(input)
	local str = "";
	local cut = 1;
	local nextcut = 1;
    local left = len
    local cnt  = 0
    local _count = 0
    local arr  = {0, 0xc0, 0xe0, 0xf0, 0xf8, 0xfc}
    while left ~= 0 do
        local tmp = string.byte(input, -left)
        local i   = #arr
        while arr[i] do
            if tmp >= arr[i] then
                left = left - i
                break
            end
            i = i - 1
        end

        if i ~= 1 then
            _count = _count + i
        else
            cnt = cnt + i
		end

		if left ~= 0 then
			if (cnt + _count) >= (size * cut) then
				str = str..string.sub(input, nextcut, cnt + _count).."\n"
				--print("截取", cut, str, "从"..nextcut.."到"..cnt + _count, string.sub(input, nextcut, cnt + _count))
				nextcut = cnt + _count + 1;
				cut = cut + 1;
			end
		else
			str = str..string.sub(input, nextcut, len)
		end
    end
    return str, cut;
end

function View:Update()
	if Time.now() - self.updateTime > 1 then
		self.updateTime = Time.now();
		local _t = os.date("*t", Time.now());
		if _t.hour > 5 and _t.hour < 19 then
			if not self.day  then
				for i,v in ipairs(self.jiayuan) do
					if string.sub(tostring(v[UnityEngine.SpriteRenderer]), 1, 5) ~= "null:" then
						local _, _color = UnityEngine.ColorUtility.TryParseHtmlString("#FFFFFFFF");
						v[UnityEngine.SpriteRenderer].material:DOColor(_color,1);
					end
				end
				self.day = true;
			end
		else
			if self.day then
				for i,v in ipairs(self.jiayuan) do
					if string.sub(tostring(v[UnityEngine.SpriteRenderer]), 1, 5) ~= "null:" then
						local _, _color = UnityEngine.ColorUtility.TryParseHtmlString(bodyColor[i]);
						v[UnityEngine.SpriteRenderer].material:DOColor(_color,1);
					end
				end
				self.day = false;
			end
		end
		-- if self.test == Time.now() then
		if _t.hour%2 == 0 and _t.min == 0 and _t.sec == 0 then
			for k,v in pairs(self.npcBuffer) do
				module.NPCModule.RemoveNPC(k);
				self.controller:Remove(v.move_idx);
			end
			self.npcBuffer = {};
		end
		--访客说话
		for k,v in pairs(self.visitor or {}) do
			if v then
				local npc = self.controller:Get(k);
				if npc and npc.process < 0.9 and v.next_time <= Time.now() then
					self.visitor[k].next_time = Time.now() + math.random(8,15); --math.random(8,15)
					if not npc.pause then
						local npc_view = CS.SGK.UIReference.Setup(npc.obj);
						local chat_cfg = self.visitorConfig[v.id];
						if chat_cfg then
							self:NpcSpeak(k,1, chat_cfg["hanging_out"..math.random(1,2)]);
						else
							print("说话配置未找到", v.id)
						end
					end
				end
			end
		end
		--任务小队说话
		for k,v in pairs(self.leader or {}) do
			local leader = self.controller:Get(k);
			if leader and leader.process < 0.9 and v.speak_time ~= 0 and Time.now() >= v.speak_time then
				self.leader[k].speak_time = Time.now() + math.random(5,6);
				local pos = math.random(1, #v.staff);
				local hero = self.manager:GetByUuid(v.staff[pos]);
				local talk_cfg = ManorModule.GetManorChat2(hero.id);
				if talk_cfg then
					self:NpcSpeak(v.team_id[pos], 1, talk_cfg["task_ing"..math.random(1,2)]);
				else
					print("说话配置未找到", hero.id)
				end
			end
		end

		--任务小人
		for i,v in ipairs(self.taskTeam or {}) do
			if not v.moving then
				if not v.enter then
					ManorManufactureModule.SetTaskTeamInfo(v.gid, {moving = true})
					self:CreateTeam(v.gid, v.staff, true);
				end
			else
				if v.out_time ~= 0 and Time.now() >= v.out_time then
					if v.enter then
						ManorManufactureModule.SetTaskTeamInfo(v.gid, {moving = false})
					else
						ManorManufactureModule.SetTaskTeamInfo(v.gid, {moving = false, enter = true})
					end
					self:CreateTeam(v.gid, v.staff, false);
				end
				break;
			end
		end
		--小偷
		for k,v in pairs(self.thief or {}) do
			if Time.now() >= v.endTime then
				self:RemoveThief(k);
				break;
			end
		end
		--好友任务NPC
		for k,v in pairs(self.friendNpc or {}) do
			if Time.now() >= v.dead_time then
				module.NPCModule.deleteNPC(k);
				self.friendNpc[k] = nil;
			end
		end
	end
	-- if Time.now() - self.updateTime2 > 10 then
	-- 	self.updateTime2 = Time.now();
	-- 	self.manorProductInfo:QueryTask();
	-- end
end

function View:OnDestroy()
	ManorManufactureModule.SetInManorScene(false);
	ManorManufactureModule.SaveWorkerEvent();
end

function View:OnApplicationPause(status)
	ManorManufactureModule.SetPauseActive(status)
end

function View:listEvent()	
	return {
		"MANOR_NPC_MOVE",
		"MANOR_REMOVE_NPC",
		"MANOR_NPC_WAIT",
		"MANOR_NPC_SPEAK",
		"MANOR_ADD_VISITOR",
		"MANOR_TASK_INFO_CHANGE",
		"MANOR_DISPATCH_TASK_SUCCEED",
		"MANOR_TASK_TEAM_CHANGE",
		"npc_init_succeed",
		"MANOR_SET_NPC_MOVE_STATE",
		"LOCAL_SOTRY_DIALOG_CLOSE",
		"LOCAL_SOTRY_DIALOG_START",
		"MANOR_ADD_QUEST_NPC",
		"MANOR_MANUFACTURE_PRODUCT_LINE_CHANGE",
		"MANOR_LINE_STATE_CHANGE",
		"MANOR_UNLOCK_LINE_SUCCEED",
		"ENTER_MANOR_BUILDING",
		"MANOR_REMOVE_FRIEND_NPC",
		"ITEM_INFO_CHANGE",
		"NPC_OBJ_INFO_CHANGE",
		--"MANOR_ADD_OTHER_TALKER",
		--"MANOR_TALKER_LEAVE",
	}
end

function View:onEvent(event, ...)
	local data = ...;
	-- if data ~= nil then
	-- 	print("onEvent",event, sprinttb(data))
	-- end
	-- print("onEvent",event)
	if event == "MANOR_NPC_MOVE" then
		self:MoveNpc(data);
	elseif event == "MANOR_REMOVE_NPC" then
		self:RemoveNpc(data);
	elseif event == "MANOR_NPC_WAIT" then
		self:WaitNpc(data.waiting)
	elseif event == "MANOR_ADD_VISITOR" then
		self:AddVisitor(data);
	elseif event == "MANOR_NPC_SPEAK" then
		self:NpcSpeak(...)
	elseif event == "MANOR_ADD_QUEST_NPC" then
		self:AddQuestNpc(...)
	-- elseif event == "MANOR_ADD_OTHER_TALKER" then
	-- 	self:AddOtherTalker(...)
	-- elseif event == "MANOR_TALKER_LEAVE" then
	-- 	self.talkerleave = ...;
	elseif event == "MANOR_TASK_TEAM_CHANGE" then
		for i,v in ipairs(self.taskTeam) do
			if v.gid == data.gid then
				for k,j in pairs(data.data) do
					if v[k] then
						self.taskTeam[i][k] = j;
					end
				end
			end
		end
	elseif event == "MANOR_DISPATCH_TASK_SUCCEED" then
		local task = ManorManufactureModule.GetTaskTeamInfo(data.gid);
		if task then
			table.insert(self.taskTeam, task);	
		end
		self:UpdateNpcStatus();
	elseif event == "npc_init_succeed" then
		self:LoadNpc(data)
	elseif event == "MANOR_SET_NPC_MOVE_STATE" then
		if data.id and self.npcBuffer[data.id] then
			local character = self.controller:Get(self.npcBuffer[data.id].move_idx);
			if character and character.moving then
				self.cur_operate_npc = data.id;
				self.controller:isStopped(self.npcBuffer[data.id].move_idx, data.state);
				if data.state then
					coroutine.resume(coroutine.create( function ()
						Sleep(0.1)
						local player = self.content[SGK.MapSceneController]:Get(module.playerModule.GetSelfID());
						self.npcBuffer[data.id].npc[SGK.MapPlayer]:UpdateDirection((player.gameObject.transform.position - self.npcBuffer[data.id].npc.gameObject.transform.position).normalized , true)
					end));
				end
			end
		end
	elseif event == "LOCAL_SOTRY_DIALOG_CLOSE" then
		if self.cur_operate_npc ~= 0 and self.npcBuffer and self.npcBuffer[self.cur_operate_npc] then
			local character = self.controller:Get(self.npcBuffer[self.cur_operate_npc].move_idx);
			if character and character.moving then
				self.controller:isStopped(self.npcBuffer[self.cur_operate_npc].move_idx, false);
			end
		end
		-- if self.talkerleave then
		-- 	self:TalkersLeave(self.talkerleave);
		-- 	self.talkerleave = nil;
		-- end
	elseif event == "MANOR_MANUFACTURE_PRODUCT_LINE_CHANGE" then
		if data and data.pid and data.pid ~= self.pid then
			return;
		end
		local productLine = self.manorProductInfo:GetLine();
		for k,v in pairs(productLine) do
			if #v.thieves > 0 then
				if v.thieves[1].end_time > Time.now() and self.thief[v.idx] == nil then
					self:AddThief(v.idx, v.thieves[1].end_time)
				end
			elseif self.thief and self.thief[v.idx] then
				self:RemoveThief(v.idx);
			end
		end
		self:UpdateNpcStatus();
		self:UpdateStealButton();
	elseif event == "MANOR_LINE_STATE_CHANGE" then
		if self.pid == data.pid then
			self:UpdateBuildingState(data.line)
			self:UpdateNpcStatus();
		end
	elseif event == "MANOR_UNLOCK_LINE_SUCCEED" then
		if building_name[data.line] then
			self.jiayuan.jiayuan_build.transform.position = self.jiayuan[building_name[data.line]].transform.position;
			self.jiayuan.jiayuan_build:SetActive(true);
			self.jiayuan.jiayuan_build.jianzao[UnityEngine.ParticleSystem]:Play();
			local time = self.jiayuan.jiayuan_build.jianzao[UnityEngine.ParticleSystem].main.duration
			self.jiayuan[building_name[data.line]]:SetActive(true);
			self.jiayuan[building_name[data.line]][UnityEngine.SpriteRenderer].material:DOFade(0, 2):From();
			self.jiayuan[building_name[data.line].."_0"][UnityEngine.SpriteRenderer].material:DOFade(0, 2);
		end
	elseif event == "ENTER_MANOR_BUILDING" then
		if data == 1 then
			DispatchEvent("Click_Something",self.doors.door_institute.gameObject.transform.position, self.doors.door_institute.gameObject)
		elseif data == 2 then
			DispatchEvent("Click_Something",self.doors.door_smithy.gameObject.transform.position, self.doors.door_smithy.gameObject)
		elseif data == 11 then
			DispatchEvent("Click_Something",self.doors.door_mine.gameObject.transform.position, self.doors.door_mine.gameObject)
		end
	elseif event == "MANOR_REMOVE_FRIEND_NPC" then
		if self.friendNpc[data] then
			module.NPCModule.deleteNPC(data);
			self.friendNpc[data] = nil;
		end
	elseif event == "ITEM_INFO_CHANGE" then
		self:UpdateStealButton();
	elseif event == "NPC_OBJ_INFO_CHANGE" then
		local npc_id, npc = ...;
		if self.npcBuffer[npc_id] then
			self.npcBuffer[npc_id].npc = npc;
			if self.npcBuffer[npc_id].startPos ~= self.npcBuffer[npc_id].endPos then
				npc.gameObject.transform.localScale = Vector3(0,1,1);
			end
		elseif self.talker[npc_id] then
			self.talker[npc_id].npc = npc;
		elseif self.friendNpc[npc_id] then
			self.friendNpc[npc_id].npc = npc;
		else
			for k,v in pairs(self.thief) do
				if v.npc_id == npc_id then
					self.thief[k].npc = npc;
				end
			end
		end
	end
end



return View
