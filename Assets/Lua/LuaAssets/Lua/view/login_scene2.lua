local NetworkService = require "utils.NetworkService";
local UserDefault = require "utils.UserDefault";
local SettingModule = require "module.gameSettingModule"
local PlayerModule = require "module.playerModule";

local View = {};

local server_config = {
	{_id = "108", _ip = "127.0.0.1", _port = 8911, _name = "开发测试服"},
	-- {_id = "107", _ip = "103.1.2.204", _port = 18810, _name = "SGK"},
	-- {_id = "34", _ip = "10.1.2.79", _port = 19890, _name = "archer"},
	-- {_id = "201", _ip = "192.168.195.128", _port = 18910, _name = "个人服务器"},
	-- {_id = "113", _ip = "10.1.2.23", _port = 18910, _name = "lan"},
	-- {_id = "35", _ip = "10.1.2.23", _port = 18911, _name = "dang"},
}

local videoRes = {
	"movie/op.mp4","movie/sgk_op.mp4"
}
local login_scene_data = UserDefault.Load("login_scene_data");

function View:Start()
	local this = self;

	self.view = SGK.UIReference.Setup();

	UnityEngine.Screen.sleepTimeout =  UnityEngine.SleepTimeout.NeverSleep
		-- UnityEngine.SleepTimeout.SystemSetting;

	if not UnityEngine.Application.isEditor then
		server_config = {};
	end

	local list = SGK.PatchManager.GetServerList();
	for i = 1, list.Length do
		local v = list[i-1];

		local find  = false;
		for _, vx in ipairs(server_config) do
			if vx._id == tostring(v.id) then
				find = true;
				break;
			end
		end

		if not find then
			table.insert(server_config, {
				_id = tostring(v.id),
				_ip = v.host,
				_port = v.port,
				_name = v.name,
			})
		end
	end

	self.view = SGK.UIReference.Setup();

	if SGK.PatchManager.serverTag == "dev" then
		self.view.Login.accountLabel:SetActive(true);
		self.view.Login.accountInput:SetActive(true);
		self.view.Login.passwordLabel:SetActive(true);
		self.view.Login.passwordInput:SetActive(true);
		if CS.SDKScript.isEnabled then
			self.view.Login.SDKLogin:SetActive(true);
			self.view.Login.ChangeServer:SetActive(true);
		end
		self.view.Login.ChangeServer.Text[UnityEngine.UI.Text].text = "切换至线上环境"
	else
		self.view.Login.ChangeServer.Text[UnityEngine.UI.Text].text = "切换至开发环境"
	end

	self.view.Login.accountInput[UnityEngine.UI.InputField].text = login_scene_data.username or "";

	local choose = 1;
	self.choose_server = server_config[1];
	for k, v in ipairs(server_config) do
		if v._id == login_scene_data.server_id then
			choose = k;
			break;
		end
	end
	self.view.versionText[UnityEngine.UI.Text].text = SGK.PatchManager.versionString;
	self:UpdateChoosen(choose);

	self:System_Setting()

	self.notice_index = 0;
	CS.UGUIClickEventListener.Get(self.view.noticeBtn.gameObject).onClick = function (obj)
		self.notice_index = self.notice_index + 1;
		if self.notice_index > 1 then
			self.view.Login.ChangeServer:SetActive(true);
		end
		DialogStack.PushPref("noticeFrame",nil,self.view)
	end

	self:SetSceneMusic();
	self:ShowOpenVideo(1)

	-- UnityEngine.GameObject.Instantiate(SGK.ResourcesManager.Load("loading/dl_bg_5.prefab"));
end

function View:ShowOpenVideo(type)
	if (login_scene_data.playVideo or 0) < type then
		SGK.BackgroundMusicService.Pause();
		login_scene_data.playVideo = type;
		self.view.video:SetActive(true);
		self.view.video[UnityEngine.CanvasGroup].alpha = 1;
		self.view.video.OpenVideo[SGK.MediaPlayerHelper]:Load(SGK.ResourcesManager.Load(videoRes[type]))
		self.view.video.OpenVideo[SGK.MediaPlayerHelper]:Play();
		self.view.video.OpenVideo[SGK.MediaPlayerHelper].OnFinshed = function ()
			self:CloseVideo(type);
		end;
		self.view.video.skip1:SetActive(type == 1);
		self.view.video.skip2:SetActive(type == 2);
		CS.UGUIClickEventListener.Get(self.view.video.skip1.gameObject).onClick = function (obj)
			self:CloseVideo(type);
		end
		CS.UGUIClickEventListener.Get(self.view.video.skip2.gameObject).onClick = function (obj)
			self:CloseVideo(type);
		end
		if type == 2 then
			if coroutine.isyieldable() then
				coroutine.yield();
			end
		end
	else
		if type == 1 then
			self.view.video[UnityEngine.CanvasGroup]:DOFade(0,0.4):OnComplete(function ()
				SGK.BackgroundMusicService.SwitchMusic();
				self.view.video:SetActive(false);
			end)
		end
	end
end

function View:CloseVideo(type)
	self.view.video.OpenVideo[SGK.MediaPlayerHelper]:Pause();
	if type == 1 then
		self.view.video[UnityEngine.CanvasGroup]:DOFade(0,0.4):OnComplete(function ( )
			SGK.BackgroundMusicService.UnPause();
			SGK.BackgroundMusicService.SwitchMusic();
			self.view.video:SetActive(false);
		end)
	elseif type == 2 then
		SGK.BackgroundMusicService.UnPause();
		SGK.BackgroundMusicService.SwitchMusic();
		if self.login_co then
			coroutine.resume(self.login_co)
		end
	end
end


function View:SetToggle(toggle, server_info)
	if not server_info then
		toggle.gameObject:SetActive(true);
		return;
	end

	toggle.gameObject:SetActive(true);
	toggle.Text[UnityEngine.UI.Text].text = server_info._name;

	local this = self;
	local event = toggle[UnityEngine.UI.Toggle].onValueChanged;
	if event:GetPersistentEventCount() == 0 then
		toggle[UnityEngine.UI.Toggle].onValueChanged:AddListener(function(b)
			if b then
				this:CloseServerList(server_info._id);
			end
		end)
	end
end

function View:OnServerClick()
	self.view.Login.gameObject:SetActive(false);
	self.view.ServerList.gameObject:SetActive(true);

	for i = 1, #self.view.ServerList.recentServerList do
		local toggle = self.view.ServerList.recentServerList[i];
		if i == 1 then
			self:SetToggle(toggle, self.choose_server);
		else
			toggle.gameObject:SetActive(false);
		end
	end

	if self.server_list_setuped then
		return;
	end
	self.server_list_setuped = true;

	local parent =  self.view.ServerList.allServerList.Viewport.Content.gameObject.transform;
	local prefab = self.view.ServerList.allServerList.Viewport.Content.ServerPrefab;
	for i = 1, #server_config do
		local toggle = SGK.UIReference.Setup(UnityEngine.GameObject.Instantiate(prefab.gameObject, parent))
		self:SetToggle(toggle, server_config[i]);
	end
end

function View:OnLogin()
	if self.is_loging then
		return;
	end

	if SGK.PatchManager.serverTag ~= "dev" then
		return self:OnSdkLoginClicked();
	end

	-- do return CS.SDKScript.Login() end

	local account = self.view.Login.accountInput[UnityEngine.UI.InputField].text;
	if account == "" then
		self:ShowTips("请输入帐号");
		return;
	end

	if not CS.UnityEngine.Application.isEditor then
		local password = self.view.Login.passwordInput[UnityEngine.UI.InputField].text;
--[[
		if password ~= "12345" then
			self:ShowTips("密码错误");
			return;
		end
--]]
	end

	self:StartLogin(account, nil, "00");
end

function View:OnSdkLoginClicked()
	if self.is_loging then
		return;
	end

	if CS.SDKScript.isEnabled then
		self:ShowTips("登陆账号", true);
		CS.SDKScript.Login();
	else
		self:ShowTips("未接入SDK");
	end
end

function View:StartLogin(account, token, platform)
	if not self.choose_server then
		self.is_loging = false;
		self:ShowTips("请选择服务器");
		return
	end

	if account == nil or
		account == "" or
		string.len(account) < 1 or
		string.len(account) > 64
	then
		self.is_loging = false;
		self:ShowTips("帐号错误");
	end

	self.is_loging = true;

	token = token or "xxxxxxxxxxxxxxxxxxx";

	login_scene_data.server_id = self.choose_server._id;
	login_scene_data.username = account;

	self.login_co = coroutine.create(function ()
		-- self:ShowOpenVideo(2);
		self:ShowTips("登入服务器", true);
		PlayerModule.Login(account .. "@" .. platform, token,  self.choose_server._ip, self.choose_server._port, self.choose_server._id);
	end)
	coroutine.resume(self.login_co);
end

function View:ShowTips(str, hold)
	self.view.TipsPanel.gameObject:SetActive(true);
	self.view.TipsPanel.Tips.Text[UnityEngine.UI.Text].text = str;
	self.tips_hold = hold;
end

function View:CloseServerList(id)
	for k, v in ipairs(server_config) do
		if v._id == id then
			View:UpdateChoosen(k);
			break;
		end
	end

	self.view.Login.gameObject:SetActive(true);
	self.view.ServerList.gameObject:SetActive(false);
end

function View:UpdateChoosen(idx)
	if not server_config[idx] then
		return;
	end

	self.choose_server = server_config[idx]
	self.view.Server.name[UnityEngine.UI.Text].text = self.choose_server._name;
	-- self.view.Server.newTips[UnityEngine.UI.Text].text = "";
end

function View:OnTipClick()
	if not self.tips_hold then
		self.view.TipsPanel.gameObject:SetActive(false);
	end
end

function View:System_Setting()
	local System_Set_data=UserDefault.Load("System_Set_data");
	SGK.AudioSourceVolumeController.effectVolume = System_Set_data.EffectVoice or 0.75;
	SGK.AudioSourceVolumeController.voiceVolume = System_Set_data.StoryVoice or 0.75;
	SGK.BackgroundMusicService.SetAudioListenerVolume(System_Set_data.BgVoice or 0.75)
	DATABASE.ForEach("sound_type", function(row)
		if row.sound_type == 1 then
			SGK.AudioSourceVolumeController.AddVoiceName(row.name);
		end
	end)
	SGK.BackgroundMusicService.GetAudio(System_Set_data.BgVoice or 0.75)
end

function View:listEvent()
	return {
		"NEED_TO_CHOOSE_ROLE",
		"PLAYER_INFO_CHANGE",
		"LOGIN_FAILED",
		"server_respond_closed",
		"server_respond_connecting",
		"server_respond_connected",
		"SDK_LOGIN_SUCCESS",
		"SDK_LOGIN_FAILED",
	}
end

function View:onEvent(event, ...)
	if event == "NEED_TO_CHOOSE_ROLE" then
		self.is_create_player = true;
		UnityEngine.Screen.sleepTimeout = UnityEngine.SleepTimeout.NeverSleep;
		module.StatisticsModule.SetServerInfo(self.choose_server._id, self.choose_server._name);
		--创建角色界面
		-- coroutine.resume(coroutine.create(function()
        --     local _data = utils.NetworkService.SyncRequest(7, {nil, "<SGK>"..module.playerModule.GetSelfID().."</SGK>", 11048})
        --     if _data[2] == 0 then
        --     	utils.NetworkService.SyncRequest(51, {nil,"",11048})
		-- 		StartScene('main_scene', 'view/main_scene.lua', {first = true})
        --     end
		-- end))
		StartScene('newSelectMapUp', 'view/create_character.lua');
		--SceneStack.EnterMap(999, {fightGuideMode = true})
	elseif event == "SDK_LOGIN_SUCCESS" then
		self:OnSDKLogin(...);
	elseif event == "SDK_LOGIN_FAILED" then
		self.is_loging = false;
		self:ShowTips("账号登陆失败")
	elseif event == "PLAYER_INFO_CHANGE" then
		if not self.login_is_finished and not self.is_create_player then
			self.login_is_finished = true;
			UnityEngine.Screen.sleepTimeout = UnityEngine.SleepTimeout.NeverSleep;
			module.StatisticsModule.SetServerInfo(self.choose_server._id, self.choose_server._name);
			StartScene('main_scene', 'view/main_scene.lua');
		end
	elseif event == "LOGIN_FAILED" then
		self:ShowTips("登陆失败");
		self.is_loging = false;
	elseif event == "server_respond_connecting" then
		self:ShowTips("连接服务器", true);
	elseif event == "server_respond_connected" then
		self:ShowTips("登入中", true);
	elseif event == "server_respond_closed" then
		self:ShowTips("连接服务器失败");
		self.is_loging = false;
	end
end

function View:OnSDKLogin(uid, token)
	if self.is_www_loging then
		print('www requesting')
		return;
	end

	self:ShowTips("登入游戏", true);

	self.is_www_loging = true;
	assert(coroutine.resume(coroutine.create(function()
		local url =  SGK.PatchManager.gameURL
		if url == nil or url == "" then
			url = "http://10.1.2.79/sgk/tools/public";
		end

		print("login url", url .. "/login/index.php");

		local data, err = HTTPRequest(url .. "/login/index.php", {account=uid, token=token})
		print('data =>', data)
		print('err  =>', err);
		self.is_www_loging = false;

		self:StartLogin(uid, data, "an");
	end)));
end

local load_class_list = {
	{"UnityEngine","Vector3"},
	{"UnityEngine","Vector2"},
	{"UnityEngine","Canvas"},
	{"UnityEngine","ColorUtility"},
	{"UnityEngine","WaitForEndOfFrame"},
	{"UnityEngine","Sprite"},
	{"UnityEngine","BoxCollider"},
	{"UnityEngine","Time"},

	{"Spine","Unity","SkeletonAnimation"},
	{"Spine","Unity","SkeletonGraphic"},

	{"UnityEngine","UI","Button"},
	{"UnityEngine","UI","Image"},
	{"UnityEngine","UI","VerticalLayoutGroup"},
	{"UnityEngine","UI","HorizontalLayoutGroup"},
	{"UnityEngine","UI","CanvasScaler"},
	{"UnityEngine","UI","Toggle"},
	{"UnityEngine","UI","Dropdown"},
	{"UnityEngine","UI","Scrollbar"},
	{"DG","Tweening","LoopType"},
	{"DG","Tweening","Ease"},

	{"InlineText"},
	{"CameraClickEventListener"},
	{"UGUIColorSelector"},
	{"FollowCamera"},
	{"NumberMovement"},
	{"FollowSpineBone"},
	{"UGUIClickEventListener"},
	{"UGUIPointerEventListener"},
	{"ModelClickEventListener"},
	{"UGUISpriteSelector"},
	{"UGUIColorSelector"},
	{"UGUISelectorGroup"},
	{"UGUICanvasRendererColorSelector"},
	{"UGUISelector"},
	{"UGUISelectorGroup"},

	{"UIMultiScroller"},

	-- {"SGK","newCharacterIcon"},
	-- {"SGK","newCharacterIcon","ColorInfo"},
	-- {"SGK","newEquipIcon"},
	-- {"SGK","newEquipIcon","ColorInfo"},
	-- {"SGK","newItemIcon"},
	-- {"SGK","newItemIcon","ColorInfo"},

	{"SGK","MapClickableObject"},
	{"SGK","MapClickableScript"},
	{"SGK","MapController"},
	{"SGK","MapHelper"},
	{"SGK","MapInteractableMenu"},
	{"SGK","MapInteractableMenuPlayer"},
	{"SGK","MapInteractableObject"},
	{"SGK","MapMonster"},
	{"SGK","MapNpcScript"},
	{"SGK","SunnyLoad"},
	{"SGK","MapPlayer"},
	{"SGK","MapPlayerCamera"},
	{"SGK","MapPortal"},
	{"SGK","MapSceneController"},
	{"SGK","MapWayMoveController"},
	{"SGK","MapWayMoveController","Character"},
	{"SGK","MapWayMoveController","Delegate"},
	{"SGK","MapWayMoveController","RepeatType"},
	{"SGK","MapWayMoveController","WayInfo"},
	{"SGK","MapWaypointMovement"},

	{"SGK", "Action", "DelayTime"},
	{"SGK","CharacterIcon"},
	{"SGK","CharacterIcon","ColorInfo"},
	{"SGK","CharacterSprite"},
	{"SGK","CoroutineService"},
	{"SGK","CoroutineServiceConfig"},
	{"SGK","CreateCharacterLoad"},
	{"SGK","Database"},
	{"SGK","Database","BattlefieldCharacterConfig"},
	{"SGK","Database","Row"},
	{"SGK","Database","Table"},
	{"SGK","DialogPlayer"},
	{"SGK","DialogPlayerMoveController"},
	{"SGK","DialogPlayerMoveController","Delegate"},
	{"SGK","DialogPlayerMoveController","PointInfo"},
	{"SGK","DialogService"},
	{"SGK","DialogService","DialogInfo"},
	{"SGK","DialogSprite"},
	{"SGK","DropdownController"},
	{"SGK","dropdownView"},
	{"SGK","EncounterFight"},
	{"SGK","EquipPrefixIcon"},
	{"SGK","EquipPrefixIcon","ColorInfo"},
	{"SGK","FileUtils"},
	{"SGK","FollowMovement3d"},
	{"SGK","FormationSlots"},
	{"SGK","GameObjectPool"},
	{"SGK","GameObjectPoolManager"},
	{"SGK","GuideMask"},
	{"SGK","ImageExtension"},
	{"SGK","ImageLoader"},
	{"SGK","InscIcon"},
	{"SGK","IService"},
	{"SGK","ItemIcon"},
	{"SGK","ItemIcon","ColorInfo"},
	{"SGK","LuaBehaviour"},
	{"SGK","LuaBehaviour","LuaObjectAction"},
	{"SGK","LuaController"},
	{"SGK","LuaController","DispatchEventDelegate"},
	{"SGK","LuaController","StartLuaCoroutineDelegate"},
	{"SGK","LuaLoader"},
	{"SGK","MaskableGameObject"},
	{"SGK","MaskableSkeletonAnimation"},
	{"SGK","MediaPlayerHelper"},
	{"SGK","MediaPlayerHelper","EventDelegate"},
	{"SGK","MiniMapFollowPlayer"},
	{"SGK","NetworkService"},
	{"SGK","NonBreakingSpaceText"},
	{"SGK","ParticleSystemSortingLayer"},
	{"SGK","PatchManager"},
	{"SGK","PatchManager","ServerInfo"},
	{"SGK","PlayerIcon"},
	{"SGK","QualityConfig"},
	{"SGK","QualityConfig","ColorInfo"},
	{"SGK","RecycleObject"},
	{"SGK","ResourcesManager"},
	{"SGK","RotateNumber"},
	{"SGK","SceneService"},
	{"SGK","SortChinese"},
	{"SGK","SpriteOutline"},
	{"SGK","TextEffect"},
	{"SGK","TitleIcon"},
	{"SGK","TitleItem"},
	{"SGK","UIButtonStyle"},
	{"SGK","UIDialogStyle"}, 	
	{"SGK","UIDotCounter"},
	{"SGK","UIReference"},
	-- {"SGK","UIStyle"},
	-- {"SGK","UIStyleConfig"},

}

function View:Update()
	if load_class_list[1] then
		local list = load_class_list[1];
		local t = CS;
		for _, v in ipairs(list) do
			if not t then break end;
			t = t[v]
		end

		table.remove(load_class_list, 1);
	end
end

local function IsNullOrEmpty(str)
	return str == nil or str == "";
end

function View:SetSceneMusic()
	SGK.BackgroundMusicService.CleanMusicConfig()
	local cfg = DATABASE.Load("music_map")
	for _, row in ipairs(cfg) do
		local sceneName = row.scene_map;
		local audioName = row.music;
		if not IsNullOrEmpty(audioName) and not IsNullOrEmpty(sceneName) then
			audioName = "sound/" .. audioName .. ".mp3";

			if sceneName == "battle" then
				sceneName = row.battle_map;
				if not IsNullOrEmpty(sceneName) then
					SGK.BackgroundMusicService.RegisterBattleMusic(sceneName, audioName);
				end
			elseif sceneName == "battle_default" then
				SGK.BackgroundMusicService.RegisterSceneMusic("battle", audioName);
			elseif sceneName == "scene_default" then
				SGK.BackgroundMusicService.RegisterSceneMusic("*", audioName, 0);
			else
				SGK.BackgroundMusicService.RegisterSceneMusic(sceneName, audioName, row.scene_map_id);
			end
		end
	end

	-- SGK.BackgroundMusicService.SwitchMusic();
end

function View:ChangeServer()
	if SGK.PatchManager.serverTag == "dev" then
		UnityEngine.PlayerPrefs.SetString("gameURL", "http://ysdir.ksgame.com/public/")
	else
		UnityEngine.PlayerPrefs.SetString("gameURL", "http://ndss.cosyjoy.com/sgk/")
	end

	SceneService:Reload();
end

return View;
