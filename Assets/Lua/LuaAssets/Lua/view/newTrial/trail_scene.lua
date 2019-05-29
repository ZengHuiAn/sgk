local trialTowerConfig = require "config.trialTowerConfig"

local View = {}

function View:Start(data)
	self.view = SGK.UIReference.Setup(self.gameObject);
	print("试炼塔.................")
	--utils.SGKTools.PlayerTransfer(module.trialModule.GetPos()[1],module.trialModule.GetPos()[2],module.trialModule.GetPos()[3])
end

function View:move(data)
	if self.player_view then
		self.player_view[SGK.MapPlayer]:MoveTo(data.x,data.y,data.z)
		if data.func then
			local func = data.func
			self.player_view[SGK.MapPlayer].onStop = (function (v3)
				if func then
					func()
				end
				func = nil
			end)
		end
	else
		ERROR_LOG("角色未加载")
	end
end

function View:initClick()
	-- CS.UGUIClickEventListener.Get(self.view.bottom.challenge.gameObject).onClick = function ()
	-- 	--CS.UnityEngine.GameObject.Destroy(self.view.gameObject)
	-- end
end

function View:listEvent()
    return {
    	"MAP_SCENE_READY",
    	"NEW_TRAIL_WLAK",
    	"CONFIRM_TRIAL_SWEEP",
    	"OVER_TRIAL_SWEEP",
    }
end

function View:onEvent(event,data)
	if event == "MAP_SCENE_READY"then

		local id = module.playerModule.Get().id;
        self.character = self.view.MapSceneController[CS.SGK.MapSceneController]:Get(id) 
        self.player_view = CS.SGK.UIReference.Setup(self.character)
        self.player_view[UnityEngine.Transform].localScale = UnityEngine.Vector3(1.5,1.5,1.5)

        self.view.MapSceneController.MainCamera[CS.CameraClickEventListener].enabled = false
        -- self.view.MapSceneController.MainCamera[SGK.MapPlayerCamera].enabled = false
        -- self.view.MapSceneController.MainCamera[UnityEngine.Transform].position = UnityEngine.Vector3(-20,50,50)

        self.player_view[UnityEngine.AI.NavMeshAgent].speed = 5
        self.view.MapSceneController.MainCamera[SGK.MapPlayerCamera].speed = 4.5

        local MapId = SceneStack.MapId()
	    if MapId == 501 then
	    	utils.EventManager.getInstance():dispatch("MAP_SCENE_REDY")
	        utils.EventManager.getInstance():dispatch("TRIAL_SCENE_READY")
	    end
		--DialogStack.PushPref("newTrial/newTrailFrame",nil, UnityEngine.GameObject.Find("bottomUIRoot"))
	elseif event == "NEW_TRAIL_WLAK" then
		self:move(data)
	elseif event == "CONFIRM_TRIAL_SWEEP" then
		self.player_view[UnityEngine.AI.NavMeshAgent].speed = 10
        self.view.MapSceneController.MainCamera[SGK.MapPlayerCamera].speed = 9.5
    elseif event == "OVER_TRIAL_SWEEP" then
    	self.player_view[UnityEngine.AI.NavMeshAgent].speed = 5
        self.view.MapSceneController.MainCamera[SGK.MapPlayerCamera].speed = 4.5
	end
end


return View;