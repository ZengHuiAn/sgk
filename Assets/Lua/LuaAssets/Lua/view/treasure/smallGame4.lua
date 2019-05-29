local View = {}
local mazeConfig = require "config.mazeConfig"
local smallGameNPC = {


}

function View:Start( data )
    module.TreasureMapModule.GetTopic(true)
    DispatchEvent("PLAYSCREENEFFECT",{0.1,SGK.Localize:getInstance():getValue("migong_24"),function ( ... )
        self:Init(data)
        module.TreasureMapModule.FlySmallGame(self.currentRoad.gid)
    end,SGK.Localize:getInstance():getValue("migong_game4")}); 
    -- self:PlayScreenEffect(3,SGK.Localize:getInstance():getValue("migong_24"));    
    SGK.Action.DelayTime.Create(5.5):OnComplete(function()
        DialogStack.PushPrefStact("treasure/TreasureSmall4");
    end)
end

function View:Init( data )
    self:InitRoad();
    self:RandomObstacle();
end

function View:InitRoad()
    local small_road =  CS.SGK.UIReference.Setup(UnityEngine.GameObject.Find("mig_1_small"))
    self.small_road = small_road
	self.currentRoad = module.TreasureMapModule.GetRandomRoad(4)
	for i=1,#small_road.road do
		local road = small_road.road[i];
        if road then
			local status = self.currentRoad.road[i] 
			road[UnityEngine.AI.NavMeshObstacle].enabled = (status == 1) or i >21
            road.mig_box:SetActive((status ~= 1) and i <=21);
            road.triggle[CS.SGK.MapColliderMenu].LuaTextName = "";
            road.triggle.gameObject:SetActive(false);
		else
			ERROR_LOG(i.."this road is nil");
		end
	end
end


function View:RandomObstacle( ... )
    self.obstacle = {
        [3] =  {id = 1602201},
        [5] =  {id = 1602202},
        [17] = {id = 1602203},
        [19] = {id = 1602204},
    }

    for k,v in pairs(self.obstacle) do
        if v then
            local info = mazeConfig.GetInfo(v.id);
            -- ERROR_LOG(sprinttb(info))
            local pos = {self.small_road.road[k].gameObject.transform.position.x,self.small_road.road[k].gameObject.transform.position.y,self.small_road.road[k].gameObject.transform.position.z}
            local npc_view = module.TreasureMapModule.Load(4,info,pos);
            local born = module.TreasureMapModule.GetNPCOBJ(tonumber(v.id)).born;

            local born_view = CS.SGK.UIReference.Setup(born.gameObject);
            born_view.fx_mig_box_light.mig_box_ani[UnityEngine.Animator]:SetInteger("status",2)
            npc_view.obj:SetActive(true);
        end
    end

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


function View:DoActive( status )
    self.obstacle = {
        [3] =  {id = 1602201},
        [5] =  {id = 1602202},
        [17] = {id = 1602203},
        [19] = {id = 1602204},
    }

    
    for k,v in pairs(self.obstacle) do
        -- module.TreasureMapModule.SetAnswer(tonumber(v.id))
        module.TreasureMapModule.SetNPCStatus(v.id,status);
    end
end

function View:onEvent(event,data)
    if event == "LOCAL_TREASURE_SMALL_SUCCESS" then
        showDlgError(nil,SGK.Localize:getInstance():getValue("migong_24dui"))
        local offest = 0;
        utils.SGKTools.StopPlayerMove()
        utils.SGKTools.LockMapClick()
        utils.SGKTools.MapCameraMoveToTarget(self.small_road.road[39].transform)
        if self.currentRoad then
            for i=1,#self.small_road.road do
                local road = self.small_road.road[i];
                if road then
                    local status = self.currentRoad.road[i] 
                    road[UnityEngine.AI.NavMeshObstacle].enabled = (status == 1)
                    road.mig_box:SetActive((status ~= 1) );
                    road.triggle.gameObject:SetActive(false);
                    if status ~= 1 and i > 21 then
                        road.mig_box.gameObject.transform.localPosition = UnityEngine.Vector3(0,-100,0)
                        if offest == 0 then
                            road.mig_box.gameObject.transform:DOLocalMove(UnityEngine.Vector3.zero, 1.5);
                        else
                            SGK.Action.DelayTime.Create((offest+1)*1):OnComplete(function()
                                road.mig_box.gameObject.transform:DOLocalMove(UnityEngine.Vector3.zero, 1);
                            end)  
                        end

                        offest  = offest +1
                    end
                else
                    ERROR_LOG(i.."this road is nil");
                end
                SGK.Action.DelayTime.Create(5.5):OnComplete(function()
                    utils.SGKTools.LockMapClick()
                    utils.SGKTools.MapCameraMoveTo()
                end)
            end

            self:DoActive(false);
        end
    elseif event == "LOACAL_SMALL4_RESTART" then
        showDlgError(nil,SGK.Localize:getInstance():getValue("migong_24cuowu"))
        self:RandomObstacle();
        self:DoActive(true);
    end
end

function View:listEvent()
	return{
        "LOCAL_TREASURE_SMALL_SUCCESS",
        "LOACAL_SMALL4_RESTART",
	}
end

return View