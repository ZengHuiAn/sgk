local View = {}
local mazeConfig = require "config.mazeConfig"
local smallGameNPC = nil

function View:Start( data )
    DispatchEvent("PLAYSCREENEFFECT",{0.1,SGK.Localize:getInstance():getValue("migong_weixian"),function ( ... )
        if not smallGameNPC then
            smallGameNPC = {}

            for i=11,14 do
                local info = mazeConfig.GetTypeInfo(i);

                for k,v in pairs(info) do
                    table.insert( smallGameNPC,{id = v.id} )
                end
            end
        end
        self:Init(data)
        module.TreasureMapModule.FlySmallGame(self.currentRoad.gid)
        ERROR_LOG("当前小游戏GID",self.currentRoad.gid);
    end,SGK.Localize:getInstance():getValue("migong_game1")}); 

    
end

function View:Init( data )
    self:RandomRoad();
    self:RandomObstacle();
end

function View:RandomRoad()
    local small_road =  CS.SGK.UIReference.Setup(UnityEngine.GameObject.Find("mig_1_small"))
    self.small_road = small_road
	self.currentRoad = module.TreasureMapModule.GetRandomRoad(1)
	for i=1,#small_road.road do
		local road = small_road.road[i];
		if road then
			local status = self.currentRoad.road[i] 
            road[UnityEngine.AI.NavMeshObstacle].enabled = status == 1
            road.triggle[CS.SGK.MapColliderMenu].LuaTextName = "";
			road.mig_box:SetActive(status ~= 1);
		else
			ERROR_LOG(i.."this road is nil");
		end
	end
end


function View:RandomObstacle( ... )

    math.randomseed(module.Time.now())
    self.obstacle = {}
    for i=1,#smallGameNPC do

        local source = smallGameNPC[i]
        local index = math.random(  1,#self.currentRoad.point)
        print(index)
        local value = self.obstacle[self.currentRoad.point[index]]
        while value do 
            index = math.random(  1,#self.currentRoad.point)
            value = self.obstacle[self.currentRoad.point[index]]
        end
        self.obstacle[self.currentRoad.point[index]] = source
    end
    -- ERROR_LOG(sprinttb(self.obstacle))


    local function StartEffect(id,time,func)
        module.TreasureMapModule.Start(id,time,func)
    end
    for k,v in pairs(self.obstacle) do
        if v then
            local info = mazeConfig.GetInfo(v.id);
            local pos = {self.small_road.road[k].gameObject.transform.position.x,self.small_road.road[k].gameObject.transform.position.y,self.small_road.road[k].gameObject.transform.position.z}
            local npc_view = module.TreasureMapModule.Load(2,info,pos);
            -- ERROR_LOG(sprinttb(npc_view));

            if tonumber(info.type) == 11 then
                
                local effect = module.TreasureMapModule.LoadNpcEffect(tonumber(v.id),"fx_mig_fire");

                print(effect,"====================")
                module.TreasureMapModule.SetGame1ObsStatus(v.id,3,npc_view.obj,1,effect)
            else
                module.TreasureMapModule.SetGame1ObsStatus(v.id,3,npc_view.obj,1)
            end
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


function View:OnDestroy( ... )
    -- module.TreasureMapModule.ClearGame1ObsStatus()
end

return View