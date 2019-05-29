require "utils.init"

local BattlefieldSceneView = {}

SceneService:StartLoading();

local function InstantiatePrefab(name)
	local prefab = SGK.ResourcesManager.Load(name)
	if not prefab then
		print("load prefab failed", name)
		return;
	end

	local o = UnityEngine.GameObject.Instantiate(prefab);
	if not o then
		print("Instantiate failed", name)
		return
	end

	o.transform.localPosition = Vector3.zero;
	o.transform.localScale = Vector3.one;
	o.transform.localRotation = Quaternion.identity;

	return o
end

function BattlefieldSceneView:Start(args)
	args = args or {  }
	-- assert(args.fight_id, "fight id not exists");

	-- args.fight_id = args.fight_id;

	self.battle_info = args;

	local this = self;
	self.preload_co = StartCoroutine(function()
		this:preload();
	end)
end

function BattlefieldSceneView:OnDestroy()
	if self.preload_co then
		StopCoroutine(self.preload_co);
	end
end

function BattlefieldSceneView:listEvent()
	return {
		"BATTLE_VIEW_READY",
	}
end

function BattlefieldSceneView:onEvent(event, ...)
	if event == "BATTLE_VIEW_READY" then
		if self.waiting_battle_view_load then
			self.waiting_battle_view_load = false;
			DispatchEvent("BATTLE_VIEW_START_WITH_FIGHT", self.battle_info);
		end
	end
end

function BattlefieldSceneView:preload()
	-- load battle prefab
	DispatchEvent("LOADING_PROGRESS_UPDATE", 0.05, "加载战斗");
	WaitForEndOfFrame()
	local battle = UnityEngine.GameObject.FindWithTag("battle_root")
	print("BattlefieldSceneView", battle);
	if battle then
		DispatchEvent("BATTLE_VIEW_START_WITH_FIGHT", self.battle_info);
	end

	if not battle then
		Sync(function ( ... )
			local prefabName = "prefabs/battlefield/battle.prefab";
			local prefabName = "prefabs/battlefield/battle_v2.prefab";
			battle = InstantiatePrefab(prefabName)
			if not battle then
				DispatchEvent("LOADING_PROGRESS_MESSAGE", '加载战斗失败')
				return;
			end

			battle.name = "battle";
			battle.tag  = "battle_root";
			self.waiting_battle_view_load = true;
		end)
	end
end

return BattlefieldSceneView;
