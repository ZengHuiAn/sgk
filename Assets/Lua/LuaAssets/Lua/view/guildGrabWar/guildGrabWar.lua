local GuildGrabWarModule = require "module.GuildGrabWarModule"
local playerModule = require "module.playerModule"
local Time = require "module.Time"

local buff_mode = {};
buff_mode[1] = "fx_jvdian_ball_gold"
buff_mode[2] = "fx_jvdian_ball_green"
buff_mode[3] = "fx_jvdian_ball_red"
buff_mode[4] = "fx_jvdian_ball_blue"

local test = true;
local function TLog(info, ...)
	if test then
		local _info = "<color=#FFB900FF>"..info.."</color>"
		print(_info, ...)
	end
end

local View = {};
function View:Start(data)
    self.controller = data and data.controller;
	self.map_id = data and data.map_id;
	self.pid = playerModule.GetSelfID();
	self.updateTime = 0;
	self.lastEnterTime = 0;
	self.addScore = SGK.ResourcesManager.Load("prefabs/guildGrabWar/addScore.prefab");
	self.redEffect = SGK.ResourcesManager.Load("prefabs/effect/jvdian_effect_red_role.prefab");
	self.blueEffect = SGK.ResourcesManager.Load("prefabs/effect/jvdian_effect_blue_role.prefab");
	self:InitData();
end

function View:InitData()
	self.point = {};
	self.buff = {};
	self.pos = -1;
	self.start = false;
	self.player_effect = {};
	self.buff_effect = {};
	-- GuildGrabWarModule.SetCurMap(self.map_id);
	self.guildGrabWarInfo = GuildGrabWarModule.Get(self.map_id);
	self.guildGrabWarInfo:Query();
	self:UpdateWarInfo();
	if self.start then
		self:UpdatePointInfo();
		self:UpdatePlayerInfo(true);
	end
end

function View:UpdateWarInfo()
	local war_info = self.guildGrabWarInfo:GetWarInfo(); 
	TLog("争夺赛决赛信息", sprinttb(war_info))
	local uninInfo = module.unionModule.Manage:GetSelfUnion();
	if war_info.attacker_gid and war_info.defender_gid and self.side == nil then
		if uninInfo and uninInfo.id then
			if war_info.attacker_gid == uninInfo.id then
				self.side = 1;
			elseif war_info.defender_gid == uninInfo.id then
				self.side = 2;
			else
				self.side = 0;
			end
		else
			self.side = 0;
		end
	end
	if war_info.finish_time then
		print("时间", war_info.finish_time > Time.now())
	end
	if war_info.finish_time and war_info.finish_time > Time.now() and self.guildGrabWarInfo.final_winner == -1 then
		if not self.start then
			self.start = true;
			DispatchEvent("GUILD_GRABWAR_START", self.side);
		end
	else
		self.start = false;
		-- if uninInfo and uninInfo.id and string.sub(playerModule.Get().name, 1, 5) == "windy" then
		-- 	ERROR_LOG("报名")
		-- 	self.guildGrabWarInfo:Apply();
		-- end
	end
end

-- function View:ChangeNameColor(change)
-- 	local colorString = {};
-- 	if change then
-- 		colorString[1] = "FF2424FF";
-- 		colorString[2] = "#35CDFFFF";
-- 	else
-- 		colorString[1] = "FFFFFFFF";
-- 		colorString[2] = "#FFFFFFF";
-- 	end
-- 	local war_info = self.guildGrabWarInfo:GetWarInfo();
-- 	if war_info.attacker_gid then
		
-- 	end
-- 	local player = self.controller:Get(self.pid)
-- 	if player then
-- 		local player_view = SGK.UIReference.Setup(player.gameObject);
-- 		if change then
-- 			local _, color =UnityEngine.ColorUtility.TryParseHtmlString(colorString[self.side]);
-- 			player_view.Character.Label.name[UI.Text].color = color;
-- 		else
-- 			player_view.Character.Label.name[UI.Text].color = UnityEngine.Color.white;
-- 		end
-- 	end
-- end

function View:UpdatePointInfo()
	local war_info = self.guildGrabWarInfo:GetWarInfo(); 
	if war_info.finish_time and war_info.finish_time > Time.now() then
		local point_info = self.guildGrabWarInfo:GetPointInfo(); 
		TLog("据点信息", sprinttb(point_info))
		if point_info then
			local scienceInfo = module.BuildScienceModule.GetScience(self.map_id)
			local CreateAllPoint = function (point_info, scienceInfo)
				for i,v in ipairs(point_info) do
					if self.point[i] == nil then
						local point_info = {};
						point_info.obj = self:CreatePoint(v, scienceInfo.title ~= 0);
						point_info.type = v.type;
						point_info.side = 0;
						point_info.which_more = 0;
						self.point[i] = point_info;
					end
				end
			end
			if scienceInfo then
				CreateAllPoint(point_info, scienceInfo)
			else
				module.BuildScienceModule.QueryScience(self.map_id, function (_scienceInfo)
					CreateAllPoint(point_info, _scienceInfo)
				end)
			end
		end
	end
end

function View:MoveSideTip(side, view, not_action)
	local y1,y2 = 0,0;
	if side == 1 then
		y1 = 15;
		y2 = -15;
	elseif side == 2 then
		y1 = -15;
		y2 = 15;
	end
	if not_action then
		view.Canvas.side2.transform.localPosition = Vector3(view.Canvas.side2.transform.localPosition.x, y2,0);
		view.Canvas.side1.transform.localPosition = Vector3(view.Canvas.side1.transform.localPosition.x, y1,0);
	else
		view.Canvas.side1.transform:DOLocalMove(Vector3(view.Canvas.side1.transform.localPosition.x, y1,0), 0.4):OnComplete(function ()
			view.Canvas.side1.transform:DOScale(Vector3.one * 1.1, 0.2):OnComplete(function ()
				view.Canvas.side1.transform:DOScale(Vector3.one, 0.2)
			end)
		end)
		view.Canvas.side2.transform:DOLocalMove(Vector3(view.Canvas.side2.transform.localPosition.x, y2,0), 0.4):OnComplete(function ()
			view.Canvas.side2.transform:DOScale(Vector3.one * 1.1, 0.2):OnComplete(function ()
				view.Canvas.side2.transform:DOScale(Vector3.one, 0.2)
			end)
		end)
	end
end

function View:UpdatePlayerInfo(not_action)
	local player_info = self.guildGrabWarInfo:GetPlayerInfo(); 
	local player_info_by_pos = {};
	for k,v in pairs(player_info) do	--统计各个据点双方的人数
		local side = v.is_attacker == 1 and 1 or 2;
		if v.status == 1 then
			player_info_by_pos[v.pos] = player_info_by_pos[v.pos] or {};
			player_info_by_pos[v.pos][side] = player_info_by_pos[v.pos][side] or 0 + 1;
		end
	end
	TLog("坐标人数",sprinttb(player_info_by_pos))
	for k,v in pairs(self.point) do
		local attacker_count, defender_count = 0, 0;
		if player_info_by_pos[k] then
			attacker_count, defender_count = player_info_by_pos[k][1] or 0, player_info_by_pos[k][2] or 0
		end
		TLog("据点人数", k, attacker_count, defender_count)
		local point_view = CS.SGK.UIReference.Setup(v.obj);
		point_view.Canvas.side1.num[UI.Text].text = attacker_count;
		point_view.Canvas.side2.num[UI.Text].text = defender_count;
		if attacker_count > defender_count and  self.point[k].which_more ~= 1 then
			self.point[k].which_more = 1;
			self:MoveSideTip(1, point_view, not_action);
		elseif attacker_count == defender_count and  self.point[k].which_more ~= 0 then
			self.point[k].which_more = 0;
			self:MoveSideTip(0, point_view, not_action);
		elseif attacker_count < defender_count and  self.point[k].which_more ~= 2 then
			self.point[k].which_more = 2;
			self:MoveSideTip(2, point_view, not_action);
		end
	end
end

function View:CreatePoint(point_info, have_owner)
	local mode = point_info.type == 2 and "jvdian_big" or "jvdian_small";
	local obj = UnityEngine.GameObject.Instantiate(SGK.ResourcesManager.Load("prefabs/effect/UI/"..mode .. ".prefab"))
	obj.transform.localPosition = Vector3(point_info.pos[1], point_info.pos[2], point_info.pos[3]);
	obj.transform.localEulerAngles = Vector3.zero;
	local point = SGK.UIReference.Setup(obj);
	point.Canvas.side1.Image[CS.UGUISpriteSelector].index = have_owner and 0 or 1;
	point.Canvas.side2.Image[CS.UGUISpriteSelector].index = have_owner and 0 or 1;
	return obj;
end

function View:CreateBuff(buff_info)
	TLog("创建buff", sprinttb(buff_info))
	local mode = buff_mode[buff_info.type];
	local obj = UnityEngine.GameObject.Instantiate(SGK.ResourcesManager.Load("prefabs/effect/UI/jvdian_buff.prefab"))
	local buff = SGK.UIReference.Setup(obj);
	local _obj = UnityEngine.GameObject.Instantiate(SGK.ResourcesManager.Load("prefabs/effect/"..mode..".prefab"), buff.EffectBody.transform);
	buff.Root.Canvas.name[UI.Text].text = SGK.Localize:getInstance():getValue("shuxingqiu0"..buff_info.type);
	buff[CS.SGK.MapInteractableMenu].values = {self.map_id, buff_info.uuid};
	obj.transform.localPosition = Vector3(buff_info.pos[1], buff_info.pos[2], buff_info.pos[3]);
	obj.transform.localEulerAngles = Vector3(45, 0, 0);
	return obj;
end

function View:RemoveBuff(uuid)
	if self.buff[uuid] then
		UnityEngine.GameObject.Destroy(self.buff[uuid].obj);
		self.buff[uuid] = nil;
	end
end
--utils.SGKTools.SynchronousPlayStatus({5, {2, module.playerModule.GetSelfID(),"pick",time}})
--module.TeamModule.SetmapPlayStatus(pid,{0, pid, "pick"})
--DispatchEvent("UpdataPlayteStatus",{pid})
function View:GetBuff(data)
	local time = data.take_effect_time - Time.now() - 1;
	if time > 0 then
		local _item = SGK.ResourcesManager.Load("prefabs/effect/UI/fx_working_ui_n.prefab")
		local _obj = CS.UnityEngine.GameObject.Instantiate(_item,UnityEngine.GameObject.FindWithTag("UGUIRootTop").transform)
		local _view = CS.SGK.UIReference.Setup(_obj)
		self.pickEffect = {view = _view, data = data};
		_view.fx_working_ui_n.gzzing_ani.ui.text_working[UI.Text].text = SGK.Localize:getInstance():getValue("zhuangyuan_caiji_01")
		_view.fx_working_ui_n.gzzing_ani.ui.icon_working[UI.Image]:LoadSprite("icon/79013")
		utils.SGKTools.LockMapClick(true, 1)
		DispatchEvent("LOCAL_MAPSCENE_STOPPLAYER_MOVE");
		_view.fx_working_ui_n.gzzing_ani.ui.huan[UI.Image]:DOFillAmount(1,time):OnComplete(function()
			_view.fx_working_ui_n.gzzing_ani[UnityEngine.Animator]:Play("ui_working_2")
			self.pickEffect = nil;
			_item.transform:DOScale(Vector3.one,1):OnComplete(function()
				CS.UnityEngine.GameObject.Destroy(_obj)
			end)
			self:PlayBuffEffect(data);
		end)
	else
		self:PlayBuffEffect(data);
	end
end

function View:PlayBuffEffect(data)
	local player = self.controller:Get(data.pid);
	if player == nil then
		return;
	end
	self.buff_effect[data.pid] = self.buff_effect[data.pid] or {};
	if self.buff_effect[data.pid][data.type] == nil then
		local effect_obj = CS.UnityEngine.GameObject.Instantiate(SGK.ResourcesManager.Load("prefabs/effect/"..buff_mode[data.type].."_hit.prefab"), player.gameObject.transform);
		self.buff_effect[data.pid][data.type] = effect_obj;
	end
	self.buff_effect[data.pid][data.type]:SetActive(true);
	if data.type == 2 then
		showDlgError(nil, SGK.Localize:getInstance():getValue("shuxingqiu08"))
	elseif data.type == 3 then
		showDlgError(nil, SGK.Localize:getInstance():getValue("shuxingqiu06"))
	elseif data.type == 4 then
		showDlgError(nil, SGK.Localize:getInstance():getValue("shuxingqiu07"))
	end
	local particle = self.buff_effect[data.pid][data.type]:GetComponentInChildren(typeof(UnityEngine.ParticleSystem));
	SGK.Action.DelayTime.Create(particle.main.duration):OnComplete(function()
		self.buff_effect[data.pid][data.type]:SetActive(false);     
	end) 
	self.curPickBuff = nil;
end

function View:DestroyPointAndBuff()
	for k,v in pairs(self.point) do
		UnityEngine.GameObject.Destroy(v.obj);
	end
	for k,v in pairs(self.buff) do
		UnityEngine.GameObject.Destroy(v.obj);
	end
	self.point = {};
	self.buff = {};
	self.start = false;
end

function View:AddScore(pid, score)
	local player = self.controller:Get(pid);
	if player == nil then
		return;
	end
	local player_view = SGK.UIReference.Setup(player.gameObject);
	if self.addScore then
		local obj = CS.UnityEngine.GameObject.Instantiate(self.addScore, player_view.Character.Label.transform);
		obj.transform.localPosition = Vector3(-36, 0, 0);
		obj:GetComponent(typeof(UnityEngine.UI.Text)).text = "+"..score;
		obj:SetActive(true);
		obj.transform:DOLocalMove(Vector3(0,50,0),0.8):SetRelative(true);
		obj:GetComponent(typeof(CS.UnityEngine.CanvasGroup)):DOFade(0, 0.6):SetDelay(0.2):OnComplete(function ()
			UnityEngine.GameObject.Destroy(obj);
		end)
	end
	if self.player_effect[self.pid] == nil then
		local player_info = self.guildGrabWarInfo:GetPlayerInfo(pid);
		if player_info.is_attacker == 1 and self.redEffect then
			local effect_obj = CS.UnityEngine.GameObject.Instantiate(self.redEffect, player.gameObject.transform);
			self.player_effect[self.pid] = effect_obj;
		elseif player_info.is_attacker == 0 and self.blueEffect then
			local effect_obj = CS.UnityEngine.GameObject.Instantiate(self.blueEffect, player.gameObject.transform);
			self.player_effect[self.pid] = effect_obj;
		else
			ERROR_LOG("加载角色特效失败")
			return;
		end
	end
	self.player_effect[self.pid]:SetActive(true); 
	local particle = self.player_effect[self.pid]:GetComponentInChildren(typeof(UnityEngine.ParticleSystem));
	SGK.Action.DelayTime.Create(particle.main.duration):OnComplete(function()
		self.player_effect[self.pid]:SetActive(false);     
	end) 
end

function View:PlayPointEffect(is_attacker, pos)
	if self.point[pos] then
		local point_view = SGK.UIReference.Setup(self.point[pos].obj);
		if is_attacker == 1 and not point_view.jvdian_effect_red.activeSelf then
			point_view.jvdian_effect_red:SetActive(true);
			local time = point_view.jvdian_effect_red.kuos_guangtiao[UnityEngine.ParticleSystem].main.duration
			SGK.Action.DelayTime.Create(time):OnComplete(function()
				if point_view.jvdian_effect_red and not utils.SGKTools.GameObject_null(point_view.jvdian_effect_red.gameObject) then
					point_view.jvdian_effect_red:SetActive(false);
				end
			end)
		elseif is_attacker == 0 and not point_view.jvdian_effect_blue.activeSelf then
			point_view.jvdian_effect_blue:SetActive(true);
			local time = point_view.jvdian_effect_blue.kuos_guangtiao[UnityEngine.ParticleSystem].main.duration
			SGK.Action.DelayTime.Create(time):OnComplete(function()
				if point_view.jvdian_effect_blue and not utils.SGKTools.GameObject_null(point_view.jvdian_effect_blue.gameObject) then
					point_view.jvdian_effect_blue:SetActive(false);
				end
			end)
		end
	end
end

function View:InitMoveTip(view)
	if utils.SGKTools.GameObject_null(view.gameObject) then
		return;
	end
	local followTargetTips = view[SGK.FollowTargetTips];
	followTargetTips:Init(self.controller:Get(self.pid).gameObject);
	for k,v in pairs(self.point) do
		local obj = CS.UnityEngine.GameObject.Instantiate(view.tip.gameObject, view.transform);
		local tip = CS.SGK.UIReference.Setup(obj);
		tip.icon[CS.UGUISpriteSelector].index = v.type - 1;
		followTargetTips:Add(k, {tip = tip.gameObject, target = v.obj, arrow = tip.circle.gameObject})
	end
end

function View:OnApplicationPause(status)
	if not status then
		self.pos = -1;
		local war_info = self.guildGrabWarInfo:GetWarInfo(); 
		if war_info.finish_time and war_info.finish_time > Time.now() then
			SGK.Action.DelayTime.Create(1):OnComplete(function()
				self:UpdatePlayerInfo();
			end)
		end
	end
end

function View:Update()
	if Time.now() - self.updateTime >= 1 then
		self.updateTime = Time.now();
		if self.start and self.side ~= 0 then
			local isEnter = false;
			for i,v in ipairs(self.point) do
				local player = self.controller:Get(self.pid)
				if player then
					local distance = Vector3.Distance(v.obj.transform.position, player.gameObject.transform.position)
					if distance <= 1.5 then
						isEnter = true;
						if self.pos ~= i or (Time.now() - self.lastEnterTime >= 5) then
							self.lastEnterTime = Time.now()
							self.guildGrabWarInfo:Enter(i);
						end
						break;	
					else					
						-- TLog("距离", i, distance)
					end
				end
			end
			if not isEnter and self.pos ~= 0 then
				self.guildGrabWarInfo:Enter(0);
			end
		end
	end
end

function View:OnDestroy()
	if self.start then
		self.guildGrabWarInfo:Enter(0);
	end
end

function View:listEvent()
	return {
		"GUILD_GRABWAR_ENTER_POINT",
		"GUILD_GRABWAR_WARINFO_CHANGE",
		"GUILD_GRABWAR_FINISH",
		"GUILD_GRABWAR_POINTINFO_CHANGE",
		"GUILD_GRABWAR_PLAYERINFO_REFRESH",
		"GUILD_GRABWAR_PLAYERINFO_CHANGE",
		"GUILD_GRABWAR_QUERY_FAILED",
		"GUILD_GRABWAR_BUFFINFO_REFRESH",
		"GUILD_GRABWAR_BUFFINFO_CHANGE",
		"GUILD_GRABWAR_BUFF_DISAPPEAR",
		"GUILD_GRABWAR_BUFF_IS_FETCHING",
		"GUILD_GRABWAR_FIGHT_END",
		"GUILD_GRABWAR_FIGHT_EFFECT_END",
		"GUILD_GRABWAR_INIT_MOVE_TIP"
	}
end

function View:onEvent(event, ...)
	-- print("onEvent", event, ...);
	local data = ...
	if event == "GUILD_GRABWAR_ENTER_POINT"  then
		self.pos = data;
	elseif event == "GUILD_GRABWAR_WARINFO_CHANGE" or event == "GUILD_GRABWAR_QUERY_FAILED" then
		if data == self.map_id then
			self:UpdateWarInfo();
		end
	elseif event == "GUILD_GRABWAR_POINTINFO_CHANGE" then
		self:UpdatePointInfo();
	elseif event == "GUILD_GRABWAR_PLAYERINFO_REFRESH" then
		if data == self.map_id then
			self:UpdatePlayerInfo(true);
		end
	elseif event == "GUILD_GRABWAR_PLAYERINFO_CHANGE" then
		if data.map_id == self.map_id then
			local player_info = data.player_info;
			if player_info then
				if player_info.pid == self.pid then
					TLog("个人信息变化", playerModule.Get(player_info.pid).name, player_info.last_status, player_info.status, sprinttb(player_info))
				end
				if player_info.last_pos ~= player_info.pos or player_info.last_status ~= player_info.status then
					self:UpdatePlayerInfo();
				end
				if player_info.last_score ~= player_info.score then
					if player_info.pid == self.pid then
						self:AddScore(player_info.pid, player_info.score - player_info.last_score);
					end
					if player_info.pos ~= 0 then
						self:PlayPointEffect(player_info.is_attacker, player_info.pos);
					end
				end
			end
		end
	elseif event == "GUILD_GRABWAR_FINISH" then
		if data.map_id == self.map_id then
			self:DestroyPointAndBuff();
		end
	elseif event == "GUILD_GRABWAR_BUFFINFO_REFRESH" then
		TLog("刷新buff", data)
		if data == self.map_id then
			local buff_info = self.guildGrabWarInfo:GetBuffInfo();
			TLog("buff信息",sprinttb(buff_info))
			for k,v in pairs(buff_info) do
				if self.buff[k] == nil then
					self.buff[k] = {obj = self:CreateBuff(v)}
				end
			end
		end
	elseif event == "GUILD_GRABWAR_BUFFINFO_CHANGE" then
		if data.map_id == self.map_id then
			local buff_info = self.guildGrabWarInfo:GetBuffInfo(data.uuid);
			if self.buff[data.uuid] == nil then
				self.buff[data.uuid] = {obj = self:CreateBuff(buff_info)}
			end
		end
	elseif event == "GUILD_GRABWAR_BUFF_DISAPPEAR" then
		if data.map_id == self.map_id then
			if self.pickEffect and self.pickEffect.data.uuid == data.uuid then
				showDlgError(nil, "下手慢了，buff消失了")
				self.pickEffect.view.fx_working_ui_n.gzzing_ani.ui.huan[UI.Image]:DOKill();
				CS.UnityEngine.GameObject.Destroy(self.pickEffect.view.gameObject);
				self.pickEffect = nil;
				self.curPickBuff = nil;
			end
			self:RemoveBuff(data.uuid);
		end
	elseif event == "GUILD_GRABWAR_BUFF_IS_FETCHING" then
		if data.map_id == self.map_id and data.pid == self.pid then
			self.curPickBuff = data;
			self:GetBuff(data);
		end
	elseif event == "GUILD_GRABWAR_FIGHT_END" then
		if data.map_id == self.map_id  and (data.attacker_pid == self.pid or data.defender_pid == self.pid)then
			if self.pickEffect then
				self.pickEffect.view.fx_working_ui_n.gzzing_ani.ui.huan[UI.Image]:DOKill();
				CS.UnityEngine.GameObject.Destroy(self.pickEffect.view.gameObject);
				self.pickEffect = nil;
			end
		end
	elseif event == "GUILD_GRABWAR_FIGHT_EFFECT_END" then
		if self.curPickBuff then
			self:PlayBuffEffect(self.curPickBuff)
		end
	elseif event == "GUILD_GRABWAR_INIT_MOVE_TIP" then
		self:InitMoveTip(data);
	end
end

return View;