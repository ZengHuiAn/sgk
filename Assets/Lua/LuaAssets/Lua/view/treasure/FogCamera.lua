local View = {}
local mazeConfig = require "config.mazeConfig"
local UserDefault = require "utils.UserDefault"

local LeftMapX; 
local LeftMapY; 

local MiniMapWidth = 210;
local MiniMapHeight = 330;

local MapCenter;

local scaleWidth 

local scaleHeight



function View:Start(data )
    -- Minimap
    self.view = CS.SGK.UIReference.Setup(self.gameObject)

    local id = module.playerModule.Get().id;
    self.MapSceneController = UnityEngine.GameObject.FindObjectOfType(typeof(SGK.MapSceneController));
    local character = self.MapSceneController:Get(id) 
    self.character = character

    local mig_1 = UnityEngine.GameObject.Find("mig_1")
    self.miniMap_Obj_parent = mig_1
	local pos = CS.SGK.UIReference.Setup(mig_1)
    self.point1 = pos.point_1
    self.point2 = pos.point_2
    local pos1 = self.point1.gameObject.transform.localPosition
    local pos2 = self.point2.gameObject.transform.localPosition

    local center_pos = (pos1+pos2)/2
    MapCenter = {x = center_pos.x,y = center_pos.y,z = center_pos.z }
    LeftMapX = pos1.x
    LeftMapY = pos2.z


    -- ERROR_LOG("存档数据",sprinttb(self.miniMap_data));
    self.today = math.floor(module.Time.now()/3600/24)
    
    scaleWidth = MiniMapWidth/2/(MapCenter.x - LeftMapX);

    scaleHeight = MiniMapHeight / 2 / (MapCenter.z - LeftMapY);

    self.miniMap = self.view.MiniMap.mask.miniMap;
    -- print(string.format( "MapCenter:%s scaleWidth : %s scaleHeight: %s LeftMapY: %s LeftMapX: %s",MapCenter,scaleWidth ,scaleHeight,LeftMapX,LeftMapY))

    self:ClickEvent();

    self.updateNpcList = {};
    self:InitTexture();

    self.eventQuest = mazeConfig.GetTypeInfo(10)    
    for k,v in pairs(self.eventQuest) do
        if v.fight_id and v.fight_id ~=0  then
            self:FreshDoneQuest(v.fight_id);
        end
    end
    
    DispatchEvent("SCENE_READY_LOCAL");
    self:PlayScreenEffect(0.1,SGK.Localize:getInstance():getValue("migong_kaishi"));
    self.black_mask = self.view.black_mask.gameObject.transform.localScale
end



function View:FreshDoneQuest( quest_id ,playerEffect)
    local index = 0;
    for i=1,#self.eventQuest do
        if self.eventQuest[i].fight_id == quest_id then
            index = i;
            break;
        end
    end

    if index == 0 then
        return;
    end
    
    local npc_id = self.eventQuest[index].id

    local npc_info = module.TreasureMapModule.GetNPCOBJ(npc_id)

    -- npc_info.obj.gameObject.transform.position

    -- print(index,"============>>>>")
    self.allMap = self.allMap or {}
    if not module.QuestModule.Get(quest_id) or module.QuestModule.Get(quest_id).status ~= 1 then
        self.view.MapRoot["Map"..index]:SetActive(false);
        self.allMap[index] = nil
    else
        self.allMap[index] = true

        SGK.Action.DelayTime.Create(1):OnComplete(function()
        
            self.view.MapRoot["Map"..index]:SetActive(true);
        end)
    end
    self:CheckAllMap()
end


function View:CheckAllMap( ... )
    for i=1,4 do
        if not self.allMap[i] then
            -- self.view.Root.AllMap:SetActive(false);
            -- self.view.Root.MapRoot:SetActive(true);
            return
        end
    end

    local openMap = mazeConfig.GetTypeInfo(100)
    if not module.QuestModule.Get(openMap[1].fight_id) or module.QuestModule.Get(openMap[1].fight_id).status ~= 1 then

        if not DialogStack.GetPref_list("treasure/TreasureMap") then
            DialogStack.Push("treasure/TreasureMap",true);
            SGK.Action.DelayTime.Create(3):OnComplete(function()
                local npc_data = module.TreasureMapModule.GetNPCOBJ(openMap[1].id);
                
                if npc_data and npc_data.obj then
                    npc_data.obj.gameObject.transform.position = self.character.gameObject.transform.position
                    self:CreateNPC(openMap[1].id);
                end
            end)
        end
    else

    end	


    -- self.view.Root.AllMap:SetActive(true);
    -- self.view.Root.MapRoot:SetActive(false);
end



local scale = 5

function View:InitTexture(  )

    self.pid = math.floor(module.playerModule.Get().id)
    self.path =UnityEngine.Application.persistentDataPath .."/"..tostring(self.pid)..tostring(self.today)..".png";
    -- path
    self.texture_fow_bytes = CS.MinimapSystem.GetTexture(self.path );
    ERROR_LOG("===========",self.texture_fow_bytes);

    self.texture_fow = UnityEngine.Texture2D(math.floor( MiniMapWidth )/scale,math.floor(MiniMapHeight)/scale,UnityEngine.TextureFormat.ARGB32,true);
    if not self.texture_fow_bytes then
        for x=0,math.floor(MiniMapWidth)/scale-1 do
            for y=0,math.floor(MiniMapHeight)/scale-1 do
                self.texture_fow:SetPixel(x, y, UnityEngine.Color.black);
            end
        end
        self.texture_fow:Apply();
        self.view.MiniMap.mask.fow[UI.Image].sprite = UnityEngine.Sprite.Create(self.texture_fow,UnityEngine.Rect(0,0,math.floor(MiniMapWidth)/scale,math.floor(MiniMapHeight)/scale),UnityEngine.Vector2(0.5,0.5));
    else
        CS.MinimapSystem.LoadImage(self.texture_fow,self.texture_fow_bytes);
        self.texture_fow:Apply();
         self.view.MiniMap.mask.fow[UI.Image].sprite = UnityEngine.Sprite.Create(self.texture_fow,UnityEngine.Rect(0,0,math.floor(MiniMapWidth)/scale,math.floor(MiniMapHeight)/scale),UnityEngine.Vector2(0.5,0.5));
    end

end



function View:OnDestroy( ... )
    -- print("存档")
    CS.MinimapSystem.SaveTexture(self.texture_fow,self.path)
end


function View:ClickEvent( ... )
    CS.UGUIClickEventListener.Get(self.view.MapRoot.gameObject).onClick = function ( ... )
        -- TreasureMap
        -- print("============>>>>")
        DialogStack.Push("treasure/TreasureMap");
    end
    self.view.black_mask:SetActive(true);
    self.view.OpenFow[CS.UGUISpriteSelector].index = 0
    CS.UGUIClickEventListener.Get(self.view.OpenFow.gameObject).onClick = function ( ... )
        -- TreasureMap
        -- index
        
        if self.view.OpenFow[CS.UGUISpriteSelector].index == 1 then
            self.view.OpenFow[CS.UGUISpriteSelector].index = 0
            self.view.black_mask[UI.RawImage].raycastTarget = false
            DispatchEvent("LOCAL_GAME3_CHANGE");
        else
            DispatchEvent("LOCAL_GAME3_CHANGE",true);
            self.view.OpenFow[CS.UGUISpriteSelector].index = 1
            self.view.black_mask[UI.RawImage].raycastTarget = true
        end 
    end
    
    self:SelectBtn();
    -- CS.UGUIClickEventListener.Get(self.view.OpenFow.gameObject).onClick();
    
end

function View:SelectBtn( ... )

    self.view.leave[CS.UGUISpriteSelector].index = self.isFollow and 1 or 0
    CS.UGUIClickEventListener.Get(self.view.leave.gameObject).onClick = function ( ... )
        if not self.isFollow then
            SceneStack.EnterMap(1);
        else
            module.TreasureMapModule.ExitSmallGame();
        end
    end
end

function View:SetMiniMapPos( character ,minimap )
    local local_chararor = self.miniMap_Obj_parent.transform:InverseTransformPoint(character.gameObject.transform.position) 
    local offest =  local_chararor - UnityEngine.Vector3(MapCenter.x,MapCenter.y,MapCenter.z);


    if minimap then
        minimap[UnityEngine.RectTransform].anchoredPosition = UnityEngine.Vector2(- offest.x * scaleWidth, - offest.z * scaleHeight)
    end
end

function View:GetFowPOS( character )
    local local_chararor = self.miniMap_Obj_parent.transform:InverseTransformPoint(character.gameObject.transform.position) 
    local offest =  local_chararor - UnityEngine.Vector3(MapCenter.x,MapCenter.y,MapCenter.z) - UnityEngine.Vector3(LeftMapX,0,LeftMapY);

    return  UnityEngine.Vector2(offest.x * scaleWidth, offest.z * scaleHeight);
end

function View:SetDone( x,y )
     if self.texture_fow:GetPixel(x, y) == UnityEngine.Color.clear then
        return;
    end
    -- if x < self.texture_fow.width or y < self.texture_fow.height then
    --     return
    -- end
    self.texture_fow:SetPixel(x, y, UnityEngine.Color.clear);
end

local radius = 5

function View:SetPixels( ... )
    local pos = self:GetFowPOS(self.character);

    -- print(math.floor( pos.x/scale ), math.floor(pos.y/scale))
    local _posx = math.floor( pos.x/scale )-1
    local _posy = math.floor( pos.y/scale )-3


    self:SetDone(_posx,_posy);
    for x=-radius,radius do
        for y=-radius,radius do
            self:SetDone(_posx+x,_posy+y);
        end
    end
    

    self.texture_fow:Apply();
end

function View:CreateNPC(id)
    self.icons = self.icons or {}
    if not self.updateNpcList[id] then
        if self.icons[id] then
            self:UpdateNPCPos(id);
            self.icons[id].obj:SetActive(true);
        else
            self.icons[id] = self.icons[id] or {}
    
            self.icons[id].obj = UnityEngine.GameObject.Instantiate((self.view.MiniMap.mask.miniMap.npcRoot.npc_icon.gameObject),self.view.MiniMap.mask.miniMap.npcRoot.gameObject.transform);
            
            local info = mazeConfig.GetInfo(id);


            self.icons[id].obj:GetComponent(typeof(CS.UGUISpriteSelector)).index = tonumber(info.icon) - 1
            self:UpdateNPCPos(id);
            self.icons[id].obj:SetActive(true);
        end
    else
        if self.icons[id] then
            self.icons[id].obj:SetActive(false);
        end
    end
end

function View:UpdateNPCPos( id )
    local npc_obj = module.TreasureMapModule.GetNPCOBJ(id);
    -- print("更新NPC位置",id)
    if npc_obj and npc_obj.obj then
        local local_chararor = self.miniMap_Obj_parent.transform:InverseTransformPoint(npc_obj.obj.transform.position) 

        local offest =  local_chararor - UnityEngine.Vector3(MapCenter.x,MapCenter.y,MapCenter.z);


        if self.icons[id] and self.icons[id].obj then
            self.icons[id].obj:GetComponent(typeof(UnityEngine.RectTransform)).anchoredPosition = UnityEngine.Vector2(offest.x * scaleWidth, offest.z * scaleHeight)
        end
    end
    
end

function View:Update( ... )

    self.time = self.time or 0
    if not self.offest_time then
        self.offest_time = self.offest_time or self.time
        return;
    end
    self.offest_time = self.offest_time + UnityEngine.Time.deltaTime
    if self.offest_time - self.time >10 then
        self.offest_time = self.time
        print("自动存档",self.path)
        CS.MinimapSystem.SaveTexture(self.texture_fow,self.path)        
    end
    

    if not self.isFollow then
        -- print("===========")
        self:SetMiniMapPos(self.character,self.miniMap);
        self:SetMiniMapPos(self.character,self.view.MiniMap.mask.fow);
        -- self:UpdateAllNPC();
        self:SetPixels();
    end
end

function View:UpdateAllNPC( ... )
    -- if self.updateNpcList then
    --     for k,v in pairs(self.updateNpcList) do
    --         if v == 1 then
    --             self:UpdateNPCPos(k);
    --         end
    --     end
    -- end
end

function View:onEvent(event,data)
    if event == "PLAYER_FILED_CUT" then
        if data then
            self.view.black_mask.gameObject.transform.localScale = self.black_mask
        else
            self.view.black_mask.gameObject.transform.localScale = self.view.black_mask.gameObject.transform.localScale - UnityEngine.Vector3(0.1,0.1,0.1)
        end
    elseif event == "PLAYSCREENEFFECT" then
        local time,content,callback,tips = table.unpack(data)
        print("PLAYSCREENEFFECT",sprinttb(data))
        self:PlayScreenEffect(time,content,callback,tips);
    elseif event =="LOCAL_UPDATE_NPC"  then
        if data then
            self.updateNpcList = self.updateNpcList or {}
            if self.updateNpcList then
                self.updateNpcList[data.id] = data.status == true and 1 or nil 
            end
            print("=====>>>更新小地图状态",self.updateNpcList[data.id] )
            self:CreateNPC(data.id);
        end
    elseif event == "MOVE_TO_SMALL_GAME" then
        -- print("========>>",event,data)
        self.view.OpenFow.gameObject:SetActive(module.TreasureMapModule.GetGameStatus() and module.TreasureMapModule.GetGameStatus() == 3);
        self.isFollow = data
        if data then
            self:CloseMiniMap(false);
        else
            self.view.tips:SetActive(false);
            self:CloseMiniMap(true);
        end
        
        if DialogStack.GetPref_list("treasure/TreasureSmall4") then
            DialogStack.Pop();
        end
        self:SelectBtn()
    elseif event == "QUEST_INFO_CHANGE" then
        if data and data.npc_id then
            local info = mazeConfig.GetInfo(data.npc_id);
            -- print("任务",sprinttb(info))
			if  not info  or info.type ~= 10 then
				return
            end
            self:FreshDoneQuest(info.fight_id,true);
        end
    elseif event == "LOCAL_CLOSE_MINIMAP" then
        self.isFollow = true
        self:CloseMiniMap(false);
        self.view.tips:SetActive(false);
        self:SelectBtn()
    elseif event == "LOCAL_PLAY_FLY" then
        self:PlayerFly(data);
    elseif event == "CLEAR_ALL_ROAD" then

        self.view.OpenFow.gameObject:SetActive(false)
    end
end

function View:CloseMiniMap( status )
    self.view.MiniMap.gameObject:SetActive(status)
    
    self.view.MapRoot.gameObject:SetActive(status)
    self.view.mini_mask.gameObject:SetActive(status)
    
end

function View:PlayScreenEffect(time,content,callback,status)

    utils.SGKTools.StopPlayerMove()
    utils.SGKTools.LockMapClick()
    time = time or 0.1

    utils.SGKTools.LockMapClick(true)
    self.view.Effect:SetActive(true);
    self.view.Effect.Content:SetActive(false);
    self.view.tips:SetActive(false)
    print("exbg",time)
    self.view.Effect.exbg[UI.Image]:DOFade(1,time):OnComplete(function()
        self.view.Effect.exbg[UI.Image].color = UnityEngine.Color(0,0,0,0)
        self.view.Effect.bg:SetActive(true);
        if callback then
            callback();
        end 
        if content then
            self.view.Effect.Content:SetActive(true);
            self.view.Effect.Content[UI.Text].text = content
        end
        SGK.Action.DelayTime.Create(5):OnComplete(function()
            utils.SGKTools.LockMapClick()
            self.view.Effect.Content:SetActive(false);
            self.view.Effect.bg:SetActive(false);
            self.view.Effect:SetActive(false);
            if status then
                self.view.tips.Text[UI.Text].text = status
                self.view.tips:SetActive(true)
            end
        end)
    end)
end

function View:PlayerFly( index )
    self.prefab_fly = self.prefab_fly or SGK.ResourcesManager.Load("prefabs/effect/UI/fx_ui_dati_lizi.prefab");
    self.prefab = self.prefab or SGK.ResourcesManager.Load("prefabs/effect/UI/fx_ui_dati_bao.prefab");

    local o = UnityEngine.GameObject.Instantiate(self.prefab_fly,self.view.transform); 
    o.transform.localPosition = UnityEngine.Vector3(0,0,0);            
    o.transform.localScale=Vector3.one*100
    o.layer = UnityEngine.LayerMask.NameToLayer("UI");
    for i = 0,o.transform.childCount-1 do
        o.transform:GetChild(i).gameObject.layer = UnityEngine.LayerMask.NameToLayer("UI");
    end
    local pos = self.view.MapRoot["Map"..index].gameObject.transform.position

    local tagetPos = self.view.gameObject.transform:InverseTransformPoint(pos)

    o.transform:DOLocalMove(tagetPos,1):OnComplete(function( ... )
        local _o = self.prefab and UnityEngine.GameObject.Instantiate(self.prefab, self.view.transform);
        _o.transform.localScale = Vector3.one*100
        _o.transform.localPosition = tagetPos
        _o.layer = UnityEngine.LayerMask.NameToLayer("UI");
        for i = 0,_o.transform.childCount-1 do
            _o.transform:GetChild(i).gameObject.layer = UnityEngine.LayerMask.NameToLayer("UI");
        end
    
        local _obj = _o:GetComponentInChildren(typeof(UnityEngine.ParticleSystem))
        UnityEngine.Object.Destroy(_o, _obj.main.duration)                                
        
        CS.UnityEngine.GameObject.Destroy(o)
    end)
end




-- function View:( ... )
--     -- body
-- end


function View:listEvent()
	return{

        "PLAYER_FILED_CUT",
        "PLAYSCREENEFFECT",
        "LOCAL_UPDATE_NPC",
        "MOVE_TO_SMALL_GAME",
        "LOCAL_MINIMAP_FOLLOW",
        "QUEST_INFO_CHANGE",
        "LOCAL_CLOSE_MINIMAP",
        "LOCAL_PLAY_FLY",
        "CLEAR_ALL_ROAD",
	}
end

return View