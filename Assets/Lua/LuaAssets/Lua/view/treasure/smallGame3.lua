local View = {}
local mazeConfig = require "config.mazeConfig"
local smallGameNPC = {
    {id =1602017},
    {id =1602018},
    {id =1602019},
    {id =1602020},
}

function View:Start( data )
    DispatchEvent("PLAYSCREENEFFECT",{0.1,SGK.Localize:getInstance():getValue("migong_yincang"),function ( ... )
        self:Init(data)
        module.TreasureMapModule.FlySmallGame(self.currentRoad.gid)
    end,SGK.Localize:getInstance():getValue("migong_game3")}); 
end

function View:Init( data )
    self:RandomRoad();
    -- self:RandomObstacle();
end

function View:RandomRoad()
    local small_road =  CS.SGK.UIReference.Setup(UnityEngine.GameObject.Find("mig_1_small"))
    self.small_road = small_road
	self.currentRoad = module.TreasureMapModule.GetRandomRoad(3)
	for i=1,#small_road.road do
		local road = small_road.road[i];
		if road then
			local status = self.currentRoad.road[i] 
			road[UnityEngine.AI.NavMeshObstacle].enabled = false
            road.mig_box:SetActive(false);
            road.triggle.gameObject:SetActive(status == 1);

            road.triggle[CS.SGK.MapColliderMenu].interDeltime = 0.0001
            road.triggle[CS.SGK.MapColliderMenu].LuaTextName = "migGame3";
		else
			ERROR_LOG(i.."this road is nil");
		end
	end
end


function View:RandomObstacle( ... )
    self.obstacle = {}
    for i=1,#smallGameNPC do

        local source = smallGameNPC[i]
        local index = math.random(  1,#self.currentRoad.point)
        local value = self.obstacle[self.currentRoad.point[index]]
        while value do 
            index = math.random(  1,#self.currentRoad.point)
            value = self.obstacle[self.currentRoad.point[index]]
        end

        print(self.currentRoad.point[index])
        self.obstacle[self.currentRoad.point[index]] = source
    end
    -- ERROR_LOG(sprinttb(self.obstacle))


    for k,v in pairs(self.obstacle) do
        if v then
            local info = mazeConfig.GetInfo(v.id);
            local pos = {self.small_road.road[k].gameObject.transform.position.x,self.small_road.road[k].gameObject.transform.position.y,self.small_road.road[k].gameObject.transform.position.z}
            local npc_view = module.TreasureMapModule.Load(3,info,pos);
            module.TreasureMapModule.SetGame1ObsStatus(v.id,3,npc_view.gameObject,1)
        end
    end

    -- local info = mazeConfig.GetInfo(npcid);
end

function View:Random_Num( ... )

    if #self.obstacle == 0 then
        return 1;
    end
    return math.random(  0,#self.obstacle)
end

function View:listEvent()
	return{
        "LOCAL_GAME3_CHANGE",
	}
end

function View:onEvent(event,data)
    if event == "LOCAL_GAME3_CHANGE" then
        self:ChangeBoxStatus(data);
    end
end

function View:ChangeBoxStatus( status )
    for i=1,#self.small_road.road do
		local road = self.small_road.road[i];
		if road then
            local cube_status = self.currentRoad.road[i] 
            -- ERROR_LOG("=========>>>",cube_status);
            if status and cube_status == 0 then
                road.mig_box:SetActive(status);
            else
                road.mig_box:SetActive(false);
            end
			-- road[UnityEngine.AI.NavMeshObstacle].enabled = false
            -- road.triggle.gameObject:SetActive(status);

            -- road.triggle[CS.SGK.MapColliderMenu].interDeltime = 0.0001
            -- road.triggle[CS.SGK.MapColliderMenu].LuaTextName = "migGame3";
		else
			ERROR_LOG(i.."this road is nil");
		end
	end
end


function View:OnDestroy( ... )
    -- module.TreasureMapModule.ClearGame1ObsStatus()
end

return View