

local function LoadNpc_TMP(data,vec3,is_break)
    --local tempAdd = {id = 10001,mode = 11025,mapid = "cemetery_scene",name = "测试npc10001",Position_x = 0,Position_y = 0.5,Position_z = 0}
    --print(SceneStack.GetStack()[SceneStack.Count()].name)
    --if data.map_id == SceneStack.GetStack()[SceneStack.Count()].name then
    if SceneStack.Count() > 0 and data.mapid == SceneStack.GetStack()[SceneStack.Count()].savedValues.mapId then
        if data.is_born ~= "0" and not is_break then
            if not module.NPCModule.npc_born_check(data.is_born, data.gid) then
                return nil
            end
        end
        -- ERROR_LOG("加载NPC",data.gid);
        local TipsView = nil
        if data.gid and data.gid > 0 and module.NPCModule.GetNPCALL(data.gid) then
            if vec3 then
                module.NPCModule.GetNPCALL(data.gid).transform.localPosition = vec3
            end
            module.NPCModule.GetNPCALL(data.gid):SetActive(true)
            TipsView = module.NPCModule.GetNPCALL(data.gid)
        elseif data.type == 4 and data.mode == 0 then
            local tempObj = SGK.ResourcesManager.Load("prefabs/base/npc_pos.prefab")
            local obj = CS.UnityEngine.GameObject.Instantiate(tempObj)
            TipsView = CS.SGK.UIReference.Setup(obj)
        else
            TipsView = CS.UnityEngine.GameObject.Instantiate(SGK.ResourcesManager.Load("prefabs/base/npc_pos.prefab"))
            TipsView = CS.SGK.UIReference.Setup(TipsView)
            DialogStack.PushPref("npcInfo",data,TipsView.gameObject)
        end
        TipsView[UnityEngine.BoxCollider].enabled = (data.script ~= "0")
        TipsView.name = (data.gid and data.gid > 0) and ("NPC_" .. data.gid) or ("NPC_mode_" .. data.mode)

        local function initScript(Npc_Sctipt, script)
            Npc_Sctipt.enabled = true
            Npc_Sctipt.LuaTextName = tostring(script)
            Npc_Sctipt.LuaCondition = tostring(data.is_born)
            Npc_Sctipt.values = {tostring(data.mapid),tostring(data.gid)}
        end

        local Trigger = tonumber(data.Trigger);
        if Trigger then
            local Npc_Sctipt = nil
            if Trigger == 0 then
                Npc_Sctipt = TipsView[CS.SGK.MapInteractableMenu]
            else
                Npc_Sctipt = TipsView[CS.SGK.MapColliderMenu]
            end
            initScript(Npc_Sctipt, data.script)
        else
            if data.Trigger ~= "" and data.Trigger ~= nil then
                TipsView.Trigger:SetActive(true);
                initScript(TipsView.Trigger[CS.SGK.MapColliderMenu], data.Trigger);
            end

            if data.script ~= "" and data.script ~= "0" and data.script ~= nil then
                initScript(TipsView[CS.SGK.MapInteractableMenu], data.script);
            end
        end
        
        if data.gid and data.gid > 0 then
            local NPCModule = require "module.NPCModule"
            local obj = module.NPCModule.GetNPCALL(data.gid)
            NPCModule.SetNPC(data.gid,TipsView)
            if not obj then
                DispatchEvent("NPC_OBJ_INFO_CHANGE", data.gid, TipsView);
            end
        end

        if vec3 then
            TipsView.transform.localPosition = vec3
        else
            TipsView.transform.localPosition = Vector3(data.Position_x,data.Position_y,data.Position_z)
        end
        TipsView.transform.localEulerAngles = Vector3(45,0,0)
        return TipsView
    end
    return nil
end

local loading_npc_queue = {}

local loading_end_pos = {}
local coro = nil
function ResetNPCQueue()
    loading_npc_queue = {}
    loading_end_pos = {}
    coro = nil
end

local function Change_NPC_Status( ... )
    coro = coroutine.create(function()
        while #loading_npc_queue ~= 0 do
            -- ERROR_LOG("创建NPC","=============>>>>",sprinttb(loading_npc_queue[1]));

            if not loading_npc_queue[1].type then
                local pos
                if loading_end_pos[loading_npc_queue[1].data.gid] then
                    pos = UnityEngine.Vector3(loading_end_pos[loading_npc_queue[1].data.gid][1],loading_end_pos[loading_npc_queue[1].data.gid][2],loading_end_pos[loading_npc_queue[1].data.gid][3])
                end
                LoadNpc_TMP(loading_npc_queue[1].data,pos,loading_npc_queue[1].is_break)
            elseif loading_npc_queue[1].type == 1 then
                module.NPCModule.DeleteNPC_OBJ(loading_npc_queue[1].data.gid)
            end
            table.remove(loading_npc_queue, 1)
        end

        if coro == coroutine.running() then
            coro = nil
        end
    end)

    if coro then
        coroutine.resume(coro)
    end
end

function DeleteNPC( id )

    if id then
        table.insert(loading_npc_queue, {data = {gid = id}, type = 1})
    end
    if #loading_npc_queue > 1 then
        return;
    end
    Change_NPC_Status()
end

function LoadNpcEffect(id,name,path,callback )
    
    if id then
        table.insert(loading_npc_queue, {data = {id = id ,name = name,path = path,callback = callback}, type = 2})

        if #loading_npc_queue > 1 then
            return;
        end
        Change_NPC_Status()
    end
end

--pri 优先级
function LoadNpc(data,vec3,is_break,pri)
    table.insert(loading_npc_queue, {data = data, vec3 = vec3 and {vec3.x,vec3.y,vec3.z}, is_break = is_break,pri = pri})

    -- ERROR_LOG("============>>>>",sprinttb(loading_npc_queue));
    local pos
    if pri then
        pos = vec3 and {vec3.x,vec3.y,vec3.z}
        loading_end_pos[data.gid] = pos
    end
    if #loading_npc_queue > 1 then
        return;
    end
    Change_NPC_Status()
end



function localNpcStatus(TipsView,id)
   DispatchEvent("localNpcStatus",{gid = id})
end

function LoadNpcDesc(id,desc,fun,type,time)
    if id then
        local NPCModule = require "module.NPCModule"
        local npc_view = NPCModule.GetNPCALL(id)

        -- ERROR_LOG("========>>>",sprinttb(npc_view))
        if npc_view and npc_view.Root then
            ShowNpcDesc_2(id,npc_view.Root.Canvas.dialogue,desc,fun,type,time)
        else
            ERROR_LOG("NPC"..id.."找不到")
        end
    else
        if not time then
            time = 2
        end
        DispatchEvent("GetplayerCharacter",id,desc,fun,type,time)
    end
end

local function utf8sub(input,size)
    local len  = string.len(input)
	local str = "";
	local cut = 1;
	local nextcut = 1;
    local left = len
    local cnt  = 0
    local _count = 0
    local arr  = {0, 0xc0, 0xe0, 0xf0, 0xf8, 0xfc}
    while left ~= 0 do
        local tmp = string.byte(input, -left)
        local i   = #arr
        while arr[i] do
            if tmp >= arr[i] then
                left = left - i
                break
            end
            i = i - 1
        end

        if i ~= 1 then
            _count = _count + i
        else
            cnt = cnt + i
		end

		if left ~= 0 then
			if (cnt + _count) >= (size * cut) then
				str = str..string.sub(input, nextcut, cnt + _count).."\n"
				nextcut = cnt + _count + 1;
				cut = cut + 1;
			end
		else
			str = str..string.sub(input, nextcut, len)
		end
    end
    return str, cut;
end

local NPCAction = nil;

function ShowNpcDesc_2(id,npc_view,desc,fun,type,time,len,color)
    --ERROR_LOG(npc_view.gameObject.name)
    len = len or 39
    npc_view:SetActive(false)
    npc_view.bg1:SetActive(type == 1)
    npc_view.bg2:SetActive(type == 2)
    npc_view.bg3:SetActive(type == 3)
    local _str,row = utf8sub(desc, len);
    time = time or row
    if color then
        _str = "<color="..color..">".._str.."</color>"
    end

    npc_view.desc[UnityEngine.UI.Text].text = _str
    npc_view:SetActive(true)
    NPCAction = NPCAction or {}
    if NPCAction[id] then
        NPCAction[id][1]:Kill();
        if NPCAction[id][2] then
            NPCAction[id][2]:Kill();
        end
        if NPCAction[id][3] then
            NPCAction[id][3]:Kill();
        end
    end
    NPCAction[id] = {}
    NPCAction[id][1] = SGK.Action.DelayTime.Create(0.1):OnComplete(function()
        npc_view[UnityEngine.RectTransform].sizeDelta = CS.UnityEngine.Vector2(npc_view.desc[UnityEngine.RectTransform].sizeDelta.x + 50, 30 + (npc_view.desc[UnityEngine.UI.Text].fontSize * row) + (row - 1) * 6)
        NPCAction[id][2] = npc_view[UnityEngine.CanvasGroup]:DOFade(1,1);
        NPCAction[id][2]:OnComplete(function( ... )
            NPCAction[id][3] = npc_view[UnityEngine.CanvasGroup]:DOFade(0,1);
            NPCAction[id][3]:OnComplete(function( ... )
                npc_view:SetActive(false)
                if fun then
                    fun()
                end
            end):SetDelay(time)
        end)
    end)
end

function ShowNpcDesc(npc_view,desc,fun,type,time,len,color)
    --ERROR_LOG(npc_view.gameObject.name)
    len = len or 39
    -- npc_view:SetActive(false)
    npc_view.bg1:SetActive(type == 1)
    npc_view.bg2:SetActive(type == 2)
    npc_view.bg3:SetActive(type == 3)
    local _str,row = utf8sub(desc, len);
    time = time or row
    if color then
        _str = "<color="..color..">".._str.."</color>"
    end

    npc_view.desc[UnityEngine.UI.Text].text = _str
    npc_view:SetActive(true)
    NPCAction = NPCAction or {}
    -- ERROR_LOG("NPCAction",sprinttb(NPCAction));
    if NPCAction[npc_view] then
        NPCAction[npc_view]:Kill();
    end

    NPCAction[npc_view] = SGK.Action.DelayTime.Create(0.1):OnComplete(function()
        npc_view[UnityEngine.RectTransform].sizeDelta = CS.UnityEngine.Vector2(npc_view.desc[UnityEngine.RectTransform].sizeDelta.x + 50, 30 + (npc_view.desc[UnityEngine.UI.Text].fontSize * row) + (row - 1) * 6)
        npc_view[UnityEngine.CanvasGroup]:DOFade(1,1):OnComplete(function( ... )
            npc_view[UnityEngine.CanvasGroup]:DOFade(0,1):OnComplete(function( ... )
                npc_view:SetActive(false)
                if fun then
                    fun()
                end
            end):SetDelay(time)
        end)
    end)
end
