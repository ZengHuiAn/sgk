local TeamActivityModule = require "module.TeamActivityModule"
local MapConfig = require "config.MapConfig"
local ProtectBaseModule = require "module.ProtectBaseModule"
local Time = require "module.Time"

local Point = {
	{-2.541,-0.06,8.535}, {-2.078,-0.06,7.217},  {-0.987,-0.06,5.385}, {0.983,-0.06,5.543}, {2.618,-0.06,4.881},
    {2.485,-0.06,3.288},{2.057,-0.06,1.952}, {3.401,-0.06,1.442}, {5.425,-0.06,1.270},{4.780,-0.06,0.560},
	{3.963,-0.06,-0.273},{2.891,-0.06,0.455},{2.203,-0.06,-0.502}, {2.992,-0.06,-2.046},{4.189,-0.06,-1.929},
	{5.697,-0.06,-0.920},{4.927,-0.06,-2.450}, {3.530,-0.06,-3.094}, {1.982,-0.06,-2.757},{-1.422,-0.06,-3.829},
    {-0.09,-0.06,-3.569},{-1.581,-0.06,-2.864}, {-3.32,-0.06,-2.879}, {-3.824,-0.06,-3.952},{-2.194,-0.06,-4.825},
    {-5.793,-0.06,-0.467},{-4.200,-0.06,-0.076}, {-2.901,-0.06,1.236}, {-1.249,-0.06,1.206},{-0.242,-0.06,3.719},
    {0.071,-0.06,-0.804},{0.997,-0.06,-1.608}, {-2.667,-0.06,3.136}, {-0.712,-0.06,-6.035},{1.712,-0.06,0.091},
}

local View = {};
function View:Start(data)
    self.view = CS.SGK.UIReference.Setup(self.gameObject);
    self.mapid = data and data.mapid or 0;
	self:InitData();
    self:InitView(true);
    DispatchEvent("ENTER_PROTECT_BASE");
end

function View:InitData()
    self.battleData = {};
    self.npcData = {};
    self.playerData = {};
    self.positions = {};
    self.updateTime = Time.now();
    for i,v in ipairs(Point) do
        self.positions[i] = v;
    end
    self.boomPrefab = SGK.ResourcesManager.Load("prefabs/monster/BoomPrefab.prefab");
    self.npc = CS.SGK.UIReference.Setup(UnityEngine.GameObject.Find("NPC_9067201"));
    self:UpdateData();
end

function View:InitView(create)
    if self.battleData then
        print("初始化", sprinttb(self.battleData))
        if self.battleData.npcs and self.battleData.npcs[1] then
            DispatchEvent("PROTECT_BASE_CONTINUE");
        end
        -- if not utils.SGKTools.isTeamLeader() and not module.TeamModule.getAFKMembers(module.playerModule.GetSelfID()) then
        --     module.TeamModule.TEAM_AFK_REQUEST();
        -- end
        if create then
            for k,v in pairs(self.battleData.npcs) do
                self:UpdateNpc(k);
            end
        end
    end
end

function View:UpdateData()
    self.battleData = TeamActivityModule.Get(2);
    self.npc.npcInfo.Root.Canvas.flag:SetActive(self.battleData == nil);
    print("刷新活动数据", sprinttb(self.battleData))
end

function View:UpdateNpc(uuid)
    if self.battleData.npcs[uuid].dead == 1 then
        --删除
        if self.npcData[uuid] then
            self:RemoveBoom(uuid);
        end
    elseif self.npcData[uuid] == nil then
        --创建
        if uuid ~= 1 and Time.now() < self.battleData.npcs[uuid].value[1] and self.battleData.npcs[uuid].dead ~= 1 then
            local data = MapConfig.GetMapMonsterConf(self.battleData.npcs[uuid].id);
            if data then
                local obj = CS.UnityEngine.GameObject.Instantiate(self.boomPrefab)
                local npc = CS.SGK.UIReference.Setup(obj);
                if data.mode ~= 0 then
                    -- npc[SGK.MapPlayer].Default_Direction = data.face_to
                    -- local face_to = data.face_to
                    -- if face_to < 0 or face_to > 7 then
                    --     face_to = 0
                    -- end
                    -- if face_to > 4 then
                    --     face_to = 8 - face_to
                    -- end
                    -- npc.Root.spine[CS.Spine.Unity.SkeletonAnimation]:UpdateSkeletonAnimation("roles_small/"..data.mode.."/"..data.mode.."_SkeletonData",{"idle"..face_to+1},(data.face_to>4))
                    -- npc[SGK.MapPlayer].character = npc.Root.spine[SGK.CharacterSprite];
                    -- npc.Root.spine[SGK.CharacterSprite].enabled = true
                    -- npc[SGK.MapPlayer].enabled = true
                    -- npc[UnityEngine.AI.NavMeshAgent].enabled = true
                    -- local scale_rate = npc.Root.spine.transform.localScale.x * data.scale_rate
                    -- npc.Root.spine.transform.localScale = Vector3(scale_rate, scale_rate, scale_rate)
                    local NpcTransportConf = require "config.MapConfig";
                    local conf = NpcTransportConf.GetNpcTransport(data.mode)
                    local modename = conf.modename
                    if modename ~= "0" then
                        local effect = UnityEngine.GameObject.Instantiate(SGK.ResourcesManager.Load("prefabs/effect/UI/"..modename .. ".prefab"), npc.EffectBody.transform)
                        effect.transform.localPosition = Vector3.zero
                        local Collider = effect:GetComponent(typeof(UnityEngine.BoxCollider))
                        if utils.SGKTools.GameObject_null(Collider) == false then    
                            Collider = effect:GetComponent(typeof(UnityEngine.BoxCollider))
                            npc[UnityEngine.BoxCollider].center = Collider.center
                            npc[UnityEngine.BoxCollider].size = Collider.size
                            Collider.enabled = false
                        else
                            npc[UnityEngine.BoxCollider].center = Vector3(conf.centent_x,conf.centent_y,conf.centent_z)
                            npc[UnityEngine.BoxCollider].size = Vector3(conf.Size_x,conf.Size_y,conf.Size_z)
                        end
                        for i = 1,effect.transform.childCount do
                            if effect.transform:GetChild(i-1).gameObject.tag == "small_point" then
                                npc.Root.Canvas.transform:SetParent(effect.transform:GetChild(i-1).gameObject.transform,false)
                                npc.Root.Canvas.transform.localPosition = Vector3.zero
                            end
                        end
                    else
                        npc[UnityEngine.BoxCollider].center = Vector3(conf.centent_x,conf.centent_y,conf.centent_z)
                        npc[UnityEngine.BoxCollider].size = Vector3(conf.Size_x,conf.Size_y,conf.Size_z)
                    end
                    npc[CS.FollowCamera].enabled = false
                    npc.transform.localEulerAngles = Vector3(0,0,0)
                    npc.Root.Canvas[CS.FollowCamera].enabled = true
                end
                npc.Root.Canvas.name[UI.Text].text = data.name;
                obj.name = "Boom"..uuid;
                npc[CS.SGK.MapInteractableMenu].enabled = true
                npc[CS.SGK.MapInteractableMenu].LuaTextName = tostring(data.script)
                npc[CS.SGK.MapInteractableMenu].LuaCondition = tostring(data.is_born)
                npc[CS.SGK.MapInteractableMenu].values = {2 , data.gid, uuid}
                
                local teamInfo = module.TeamModule.GetTeamInfo();
                local pos = ProtectBaseModule.GetRandomPos(teamInfo.leader.pid + self.battleData.npcs[1].value[3], Point)[uuid - 1];
                obj.transform.localPosition = Vector3(pos[1], pos[2], pos[3]);
                -- print("位置", uuid, pos[1], pos[2], pos[3], obj.transform.localPosition, sprinttb(ProtectBaseModule.GetRandomPos(teamInfo.leader.pid + self.battleData.npcs[1].value[3])))
                obj.transform.localEulerAngles = Vector3(45,0,0);
                if pos[4] == 0 then
                    self:playEffect(npc, "fx_zhadan_chuxian")
                    pos[4] = 1;
                else
                    npc.EffectBody:SetActive(true);
                end
                self.npcData[uuid] = {};
                -- self.npcData[uuid].pos = {self.positions[index][1], self.positions[index][2], self.positions[index][3]};
                self.npcData[uuid].time = self.battleData.npcs[uuid].value[1];
                self.npcData[uuid].hurt = self.battleData.npcs[uuid].value[2];
                self.npcData[uuid].npc = npc;
                -- table.remove(self.positions, index);
                npc.Root.Canvas.time.Text[UnityEngine.UI.Text].text = math.floor(self.battleData.npcs[uuid].value[1] - Time.now()).."s";
                npc.Root.Canvas.time:SetActive(true)
            end
        end
    else
        --刷新
        self.npcData[uuid].time = self.battleData.npcs[uuid].value[1];
        self.npcData[uuid].hurt = self.battleData.npcs[uuid].value[2];
        self.npcData[uuid].npc.Root.Canvas.time.Text[UnityEngine.UI.Text].text = math.floor(self.npcData[uuid].time - Time.now()).."s";
    end   
end

function View:playEffect(view, effectName, destroy, sortOrder)
    local prefab = SGK.ResourcesManager.Load("prefabs/effect/UI/" .. effectName .. ".prefab");
    local obj = prefab and UnityEngine.GameObject.Instantiate(prefab, view.Effect.gameObject.transform);
    if obj then
        obj.transform.localPosition = Vector3.zero;
        obj.transform.localRotation = Quaternion.identity;

        if sortOrder then
            SGK.ParticleSystemSortingLayer.Set(obj, sortOrder);
        end

        local _obj = obj:GetComponentInChildren(typeof(UnityEngine.ParticleSystem))
        _obj:Play()
        if destroy then
            UnityEngine.Object.Destroy(view.gameObject, _obj.main.duration)
        else
            UnityEngine.Object.Destroy(obj, _obj.main.duration)
            view.EffectBody.transform:DOLocalMove(Vector3(0,0,0), 1):OnComplete(function ()
                view.EffectBody:SetActive(true);
            end)
        end
    end
end

function View:RemoveBoom(uuid)
    if self.npcData[uuid] then
        if Time.now() >= self.battleData.npcs[uuid].value[1] and self.npcData[uuid].hurt > 0 then
            --爆炸特效
            self.npcData[uuid].npc[CS.SGK.MapInteractableMenu].enabled = false;
            self.npcData[uuid].npc.Root:SetActive(false);
            self.npcData[uuid].npc.EffectBody:SetActive(false);
            self:playEffect(self.npcData[uuid].npc, "fx_zhadan_baozha", true)
        else
            UnityEngine.GameObject.Destroy(self.npcData[uuid].npc.gameObject);
        end
        -- table.insert(self.positions, self.npcData[uuid].pos);
        self.npcData[uuid] = nil
    end
end

function View:Update()
    if Time.now() - self.updateTime >= 1 then
        self.updateTime = Time.now();
        for k,v in pairs(self.npcData) do
            if v.time - Time.now() >= 0 then
                v.npc.Root.Canvas.time.Text[UnityEngine.UI.Text].text = math.floor(v.time - Time.now()).."s";
                if v.time - Time.now() < 30 and not v.play then
                    v.play = true
                    SGK.Action.DelayTime.Create(1):OnComplete(function()
                        v.npc.Root.Canvas.time.Text[CS.DG.Tweening.DOTweenAnimation]:DOPlayForward();
                    end)
                end
            else
                self:RemoveBoom(k);
            end

            -- if Time.now() >= v.time + 5 then
            --     self:RemoveBoom(k, true);
            -- end
        end
    end
end

function View:OnDestroy()
    DispatchEvent("LEAVE_PROTECT_BASE");
end


function View:listEvent()
	return {
        "TEAM_ACTIVITY_START",
        "TEAM_ACTIVITY_NPC_CHANGE",
        "TEAM_ACTIVITY_FINISHED",
        "kICKTEAMSUCCESS",
        "BASE_NEXT_WAVE"
	}
end

function View:onEvent(event, ...)
    -- print("onEvent", event, ...);
    local data = ...;
	if event == "TEAM_ACTIVITY_START" then
        if data == 2 then
            self:UpdateData();
            self:InitView();
        end
    elseif event == "TEAM_ACTIVITY_NPC_CHANGE" then
        self:UpdateData();
        self:UpdateNpc(data)
        if data == 1 then
            DispatchEvent("BASE_INFO_CHANGE");
        end
    elseif event == "TEAM_ACTIVITY_FINISHED" then
        -- if data == 2 and not utils.SGKTools.isTeamLeader() and module.TeamModule.getAFKMembers(module.playerModule.GetSelfID()) then
        --     module.TeamModule.TEAM_AFK_RESPOND();
        -- end
    elseif event == "kICKTEAMSUCCESS" then
        if data == module.playerModule.GetSelfID() then
            SceneStack.EnterMap(10,{pos = {3.91,-0.02,5.33}});
        end
    elseif event == "BASE_NEXT_WAVE" then
        ShowNpcDesc_2(9067201,self.npc.npcInfo.Root.Canvas.dialogue,SGK.Localize:getInstance():getValue("protect_base_next3"), nil, 2, 3)
	end
end

return View;