local View = {}


function View:Start( data )
	-- migong_bengta
	DispatchEvent("PLAYSCREENEFFECT",{0.1,SGK.Localize:getInstance():getValue("migong_bengta"),function ( ... )
		self:RandomRoad();
		module.TreasureMapModule.FlySmallGame(self.currentRoad.gid)
	end}); 
end



function View:RandomRoad()
    local small_road =  CS.SGK.UIReference.Setup(UnityEngine.GameObject.Find("mig_1_small"))
    self.small_road = small_road
    self.currentRoad = module.TreasureMapModule.GetRandomRoad(2)
    

	for i=1,#small_road.road do
		local road = small_road.road[i];
		if road then
			local status = self.currentRoad.road[i] 
			road[UnityEngine.AI.NavMeshObstacle].enabled = status == 1
            road.mig_box:SetActive(status ~= 1);
			road.triggle.gameObject:SetActive(status ~= 1);
			road.triggle[CS.SGK.MapColliderMenu].LuaTextName = "migGame2"
            road.triggle[CS.SGK.MapColliderMenu].interDeltime = 0.0001
            module.TreasureMapModule.SavePosRoad(i,road)
		else
			ERROR_LOG(i.."this road is nil");
		end
	end
end


function View:DestroyOneRoad()
    
end

function View:listEvent()
	return{
        "LOCAL_GAME2_START"
	}
end

-- LOCAL_GAME2_START

function View:onEvent(event,data)

end


return View;