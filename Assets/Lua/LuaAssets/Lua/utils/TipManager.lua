local GetItemTipsState = true
local ShowActorLvUpState=true
local ShowActorExpChangestate=true

local saved_item_tips = {}
local saved_actorLv_data = {}
local saved_actorExp_data = {}
local saved_quest_data = {}
function SetTipsState(state,DontIgnore)
    GetItemTipsState = state
    ShowActorLvUpState = state
    ShowActorExpChangestate= state

    if state then
        -- if DontIgnore then
        --     if next(saved_item_tips)~=nil then
        --         for _, v in ipairs(saved_item_tips) do
        --             GetItemTips(v[1], v[2], v[3]);
        --         end 
        --     end
        -- end
    --     if next(saved_actorLv_data)~=nil then
    --         GetActorLvUpData(saved_actorLv_data[1][1],saved_actorLv_data[#saved_actorLv_data][2],saved_actorLv_data[1][3],saved_actorLv_data[#saved_actorLv_data][4]) 
    --     end
    --     saved_actorLv_data={}  
    end
end

local not_show_tips_scene = {
    ['battle'] = true,
}

--获取 获取道具提示状态
function GetGetItemTipsState()
    return GetItemTipsState
end

function SetItemTipsState(state)
    --ERROR_LOG("设置SetITemTipsState",state,#saved_item_tips)
    GetItemTipsState = state
    if not not_show_tips_scene[utils.SceneStack.CurrentSceneName()] then
        saved_item_tips = {}--改变状态后,清空itemTab
    end
end

function SetLvUpTipsState(State)
    ShowActorLvUpState = State
end

--flag 特殊标记是 hero 不显示获得动画
local rewards_filter_tab = {}--过滤的获取
function GetItemTips(id,count,type,uuid,flag)
    -- ERROR_LOG(id,count,type,uuid,flag,"GetItemTipsState",GetItemTipsState)
    if not GetItemTipsState then
        table.insert(saved_item_tips, {id,count,type,uuid,flag});
        return
    end 
    -- ERROR_LOG("rewards_filter_tab",sprinttb(rewards_filter_tab))
    if next(rewards_filter_tab) then
        if rewards_filter_tab[type] and rewards_filter_tab[type][id] and rewards_filter_tab[type][id] == count then
            rewards_filter_tab[type][id] = nil
            return
        end
    end

    if type == utils.ItemHelper.TYPE.HERO then
        local herolist = module.ActivityModule.GetSortHeroList()
        local hero_exist = false
        for i = 1,#herolist do
            --ERROR_LOG(id..">"..herolist[i].id)
            if herolist[i].id == id then
                hero_exist = true
                break
            end
        end

        if hero_exist then
            id = id + 10000
            count = 10
           -- type = ItemHelper.TYPE.ITEM
           --类型用来标记是英雄转变的碎片在显示的时候改变type为Item          
        else
            if not flag then
                PopUpTipsQueue(4,id)--获得英雄
                -- utils.utils.SGKTools.HeroShow(id)
            end
        end
    end 

    if type == utils.ItemHelper.TYPE.HERO_ITEM then
        return;
    elseif type == utils.ItemHelper.TYPE.EQUIPMENT or type == utils.ItemHelper.TYPE.INSCRIPTION or type == utils.ItemHelper.TYPE.HERO then
        PopUpTipsQueue(1,{id,count,type,uuid,flag})
        -- DispatchEvent("GetItemTips",{id,count,type,uuid,flag})
    else
        local itemconf = module.ItemModule.GetConfig(id)
        if not itemconf then
            --ERROR_LOG("道具id->"..id.."在item表中不存在。")
            return
        elseif itemconf and itemconf.is_show == 0 then
            if itemconf.type==111 then--称号进度凭证
               PopUpTipsQueue(5,{id})
            elseif itemconf.type==166 then--学会图纸
                PopUpTipsQueue(9,{id})
            end
            return
        end
        --DispatchEvent("GetItemTips",{id,count,type,uuid})
        PopUpTipsQueue(1,{id,count,type,uuid,flag})
    end
end

function GetActorLvUpData(oldLv,lv,oldExp,Exp)
    if not_show_tips_scene[utils.SceneStack.CurrentSceneName()] then
    	--战斗界面升级不再提示
        -- table.insert(saved_actorLv_data,{oldLv,lv,oldExp,Exp})
        return;
    end

    -- if not ShowActorLvUpState then
    --     table.insert(saved_actorLv_data,{oldLv,lv,oldExp,Exp})
    --     return
    -- end
    --升级时提示经验变化
    PopUpTipsQueue(1,{11000,oldExp,Exp})
    ShowLvUpTips()
    saved_actorLv_data = {} 
end

function GetActorExpChangeData(oldExp,Exp) 
    if not_show_tips_scene[utils.SceneStack.CurrentSceneName()] then
        table.insert(saved_actorExp_data,{oldExp,Exp})
        return;
    end

    if not ShowActorExpChangestate then
        table.insert(saved_actorExp_data,{oldExp,Exp})
        return
    end

    -- if next(rewards_filter_tab) then
    --     if rewards_filter_tab[90] and rewards_filter_tab[90][90000] and rewards_filter_tab[90][90000] == Exp-oldExp then
    --         rewards_filter_tab[90][90000] = nil
    --         return
    --     end
    -- end

    --PopUpTipsQueue(1,{11000,oldExp,Exp})
    saved_actorExp_data = {}
end

function ShowLvUpTips()
    utils.NetworkService.Send(18046, {nil,{7,module.playerModule.Get().id}})--向地图中其他人发送刷新玩家战斗信息
end

function SetItemTipsStateAndShowTips(state)--商店显示GetItemTip等动画播完
    GetItemTipsState = state
    if not not_show_tips_scene[utils.SceneStack.CurrentSceneName()] then
        if state then
            for _, v in ipairs(saved_item_tips) do
                GetItemTips(v[1], v[2], v[3],v[4],v[5]);
            end 
            DispatchEvent("LOCLA_QUICKTOSUE_CHANE")
            DispatchEvent("LOCLA_MAPSCENE_SHOW_QUICKTOHERO")
        end
        saved_item_tips = {} 
    end    
end

utils.EventManager.getInstance():addListener("SCENE_LOADED", function(event, name)
    if not_show_tips_scene[name] then
        GetItemTipsState = false
        return;
    end

    if not GetItemTipsState then--切换场景后 如果不是战斗 就自动强制转换 tip状态为 true
        GetItemTipsState = true
    end 

    if next(saved_item_tips) ~= nil then
        if next(rewards_filter_tab) ~= nil then
            for _, v in ipairs(saved_item_tips) do--id,count,type
                local type,id,count,uuid,flag=v[3],v[1],v[2],v[4],v[5]

                if uuid and type== utils.ItemHelper.TYPE.EQUIPMENT or type== utils.ItemHelper.TYPE.INSCRIPTION then
                    if not rewards_filter_tab[type] or not rewards_filter_tab[type][uuid] then
                        GetItemTips(id,count,type,uuid,flag);
                    end
                else
                    if rewards_filter_tab[type] and rewards_filter_tab[type][id] then
                        local _count=count-rewards_filter_tab[type][id]
                        if _count>0 then
                           GetItemTips(id,_count,type,uuid,flag); 
                        end
                    else
                        GetItemTips(id,count,type,uuid,flag);
                    end
                end
            end
        else
            for _, v in ipairs(saved_item_tips) do
                GetItemTips(v[1], v[2], v[3],v[4],v[5]);
            end
        end 
    end

  --   if next(saved_actorLv_data)~=nil then
		-- GetActorLvUpData(saved_actorLv_data[1][1],saved_actorLv_data[#saved_actorLv_data][2],saved_actorLv_data[1][3],saved_actorLv_data[#saved_actorLv_data][4]) 
  --   end
    if next(saved_quest_data)~=nil then
        -- DispatchEvent("GetItemTips",{})
    end

    saved_item_tips = {}
    saved_actorLv_data={}
    saved_actorExp_data={}
    saved_quest_data = {}
    rewards_filter_tab = {}
end)

utils.EventManager.getInstance():addListener("ADD_FILTER_REWARDS", function(event,data)
    -- ERROR_LOG("ADD_FILTER_REWARDS",data)
    if data and next(data) then
        rewards_filter_tab = {}
        for k,v in pairs(data) do
            local type,id,count,uuid=v[1],v[2],v[3],v[4]
            if type == 44 then
                coroutine.resume(coroutine.create(function()
                    local data = utils.NetworkService.SyncRequest(428, {nil, id})
                    if data and data[3] and next(data[3]) then
                        for i=1,#data[3] do
                            local _type,_id,_count,uuid = data[3][i][1],data[3][i][2],data[3][i][3],data[3][i][4]
                            if _type== utils.ItemHelper.TYPE.EQUIPMENT or _type== utils.ItemHelper.TYPE.INSCRIPTION then
                                if uuid then
                                    rewards_filter_tab[type]=rewards_filter_tab[type] or {}
                                    rewards_filter_tab[type][uuid] = 1
                                else
                                    rewards_filter_tab[type]=rewards_filter_tab[type] or {}
                                    rewards_filter_tab[type][id]=rewards_filter_tab[type][id] and rewards_filter_tab[type][id]+count or count 
                                end
                            else
                                rewards_filter_tab[_type]=rewards_filter_tab[_type] or {}
                                rewards_filter_tab[_type][_id]=rewards_filter_tab[_type][_id] and rewards_filter_tab[_type][_id]+_count or _count 
                            end
                        end
                    end
                end))
            elseif type== utils.ItemHelper.TYPE.EQUIPMENT or type== utils.ItemHelper.TYPE.INSCRIPTION then
                if uuid then
                    rewards_filter_tab[type]=rewards_filter_tab[type] or {}
                    rewards_filter_tab[type][uuid] = 1
                else
                    rewards_filter_tab[type]=rewards_filter_tab[type] or {}
                    rewards_filter_tab[type][id]=rewards_filter_tab[type][id] and rewards_filter_tab[type][id]+count or count 
                end
            else    
                rewards_filter_tab[type]=rewards_filter_tab[type] or {}
                rewards_filter_tab[type][id]=rewards_filter_tab[type][id] and rewards_filter_tab[type][id]+count or count
            end
        end
    end
end)

--结算界面 奖励物品的变化
local doubleAwardItemTab={}
utils.EventManager.getInstance():addListener("server_notify_16040", function (event, cmd, data)
    -- if data[1]==1 then
    --     local totalShowInfo=utils.PlayerInfoHelper.GetTotalShow()
    --     for k,v in pairs(totalShowInfo) do
    --         if v.double_id~=0 then
    --             doubleAwardItemTab[v.double_id]=module.ItemModule.GetItemCount(v.double_id) or 0
    --         end
    --     end
    -- end
end);

function GetRawardItemChange()
    local _changed=false
    for k,v in pairs(doubleAwardItemTab) do
        local _count=module.ItemModule.GetItemCount(k) or 0
        if v~=_count then
            _changed=true
            break
        end
    end
    return _changed
end

local _PopUpQueueData = {}
local _PopUpQueueType = 0
local _PopUpQueueData_now = nil
local _PopUpQueuelock = false
function ClearTipsQueue()
    _PopUpQueueType = 0
    _PopUpQueueData_now = nil
    _PopUpQueuelock = false
    _PopUpQueueData = {}
end


function PopUpTipsQueue(_type,data)
    if _type and data then
        _PopUpQueueData[#_PopUpQueueData + 1] = {_type,data}
    else
        _PopUpQueuelock = false
    end
    -- ERROR_LOG(sprinttb(_PopUpQueueData))
    -- ERROR_LOG(#_PopUpQueueData,_PopUpQueueType)
    if (#_PopUpQueueData > 0 and _PopUpQueuelock == false) then
        _PopUpQueueType = _PopUpQueueData[1][1]
        _PopUpQueueData_now = _PopUpQueueData[1]
        table.remove(_PopUpQueueData,1)
        _PopUpQueuelock = true
        if _PopUpQueueType == 1 then--获得物品
            DispatchEvent("GetItemTips",_PopUpQueueData_now[2],function ( ... )
                PopUpTipsQueue()
            end,_PopUpQueueData_now[2] and _PopUpQueueData_now[2][5])

            local count = #_PopUpQueueData
            for i = 1,count do
                if _PopUpQueueData[i][1] == 1 then
                    local temp = _PopUpQueueData[i]
                    table.remove(_PopUpQueueData,i)
                    PopUpTipsQueue(temp[1],temp[2])
                    break
                end
            end
        elseif _PopUpQueueType == 2 then--完成任务
            DispatchEvent("QUEST_FINISH",function ( ... )
                PopUpTipsQueue()
            end);
        -- elseif _PopUpQueueType == 3 then--主角升级
        --     utils.SGKTools.loadEffect("UI/fx_map_lv_up",nil,{fun = function ( ... )      
        --     end,time = 1.5})
        --     PopUpTipsQueue()
        elseif _PopUpQueueType == 4 then--获得英雄
            utils.SGKTools.HeroShow(_PopUpQueueData_now[2],function ( ... )
                PopUpTipsQueue()
            end)
        elseif _PopUpQueueType == 5 then--获得称号
            -- utils.SGKTools.ShowTitleInfoChangeTip(_PopUpQueueData_now[2][1],function ( ... )
            --     PopUpTipsQueue()
            -- end);
        elseif _PopUpQueueType == 6 then--章节结束
            utils.SGKTools.StoryEndEffectCallBack(_PopUpQueueData_now[2],function ( ... )
                PopUpTipsQueue()
            end)
        elseif _PopUpQueueType == 7 then--排行榜超越通知结束
            utils.SGKTools.RankListChangeTipShow(_PopUpQueueData_now[2],function ( ... )
                PopUpTipsQueue()
            end)
        elseif _PopUpQueueType == 8 then--成就
            if _PopUpQueueData and #_PopUpQueueData >1 then
                table.sort( _PopUpQueueData, function ( a,b )
                    local a_type = module.QuestModule.GetCfg(a[2].quest_id).cfg.raw.type;
                    local b_type = module.QuestModule.GetCfg(a[2].quest_id).cfg.raw.type;
                    return tonumber(a_type) <tonumber(b_type)
                end )
            end
            --盗团可能会因为完成奖励导致盗团弹不出来
            if not DialogStack.GetPref_list("mapSceneUI/achievementNode") then
                local _root = UnityEngine.GameObject.FindWithTag("UITopRoot") or UnityEngine.GameObject.FindWithTag("UGUIGuideRoot") or UnityEngine.GameObject.FindWithTag("UGUIRootTop") or UnityEngine.GameObject.FindWithTag("UGUIRoot")
                if _root then
                    local _obj = CS.SGK.UIReference.Setup(_root)
                    if _obj.UIMessageRoot then
                        _root= _obj.UIMessageRoot.gameObject
                    end
                    DialogStack.PushPref("mapSceneUI/achievementNode", _PopUpQueueData_now[2],_root)
                end             
            else
                DispatchEvent("LOCAL_SELF_ACHIEVEMENT_CHANGE",_PopUpQueueData_now[2]);
            end      
        elseif  _PopUpQueueType == 9 then--学会图纸
            utils.SGKTools.LearnedDrawingTipShow(_PopUpQueueData_now[2],function ( ... )
                PopUpTipsQueue()
            end)
        elseif  _PopUpQueueType == 10 then--获得Buff
            utils.SGKTools.GetBuffTipShow(_PopUpQueueData_now[2],function ( ... )
                PopUpTipsQueue()
            end)
        else--处理部分因 pop类型不存在导致的错误
            -- ERROR_LOG(_PopUpQueueType,"_PopUpQueueType")
            PopUpTipsQueue()
        end
    elseif #_PopUpQueueData > 0 and _PopUpQueueType == 1 and _PopUpQueueType == _PopUpQueueData[#_PopUpQueueData][1] then
        DispatchEvent("GetItemTips",_PopUpQueueData[#_PopUpQueueData][2],function ( ... )
            PopUpTipsQueue()
        end,_PopUpQueueData[#_PopUpQueueData][2] and _PopUpQueueData[#_PopUpQueueData][2][5])

        table.remove(_PopUpQueueData,#_PopUpQueueData)
        local count = #_PopUpQueueData
        for i = 1,count do
            if _PopUpQueueData[i][1] == 1 then
                local temp = _PopUpQueueData[i]
                table.remove(_PopUpQueueData,i)
                PopUpTipsQueue(temp[1],temp[2])
                break
            end
        end
    elseif #_PopUpQueueData > 0 and _PopUpQueueData[#_PopUpQueueData][1] == 4 then
        local idx = nil
        if _PopUpQueueData_now[2] == _PopUpQueueData[#_PopUpQueueData][2] then
            idx = #_PopUpQueueData
        else
            for i = 1 ,#_PopUpQueueData - 1 do
                if _PopUpQueueData[i][2] == _PopUpQueueData[#_PopUpQueueData][2] then
                    idx = #_PopUpQueueData
                end
            end
        end
        if idx then
            table.remove(_PopUpQueueData,idx)
        end
    end
end

local operation_queue = {}
local opt_index = 0;
local show_get_item_tab = {}
local function OperationQueueCall()
    if operation_queue[1] then
        local info = operation_queue[1];
        -- print('OperationQueueCall', info.idx);
        local suc, info = pcall(table.unpack(info.args))
        if not suc then
            ERROR_LOG(info)
        end
    end
end

function OperationQueuePush(func, ...)
    --ERROR_LOG(select("#",...),#show_get_item_tab ,...)

    opt_index = opt_index + 1;
    table.insert(operation_queue, {showtype =1,idx = opt_index, args = table.pack(func, ...)});

    --ERROR_LOG('OperationQueuePush' , opt_index, #operation_queue, #show_get_item_tab,debug.traceback(), sprinttb(operation_queue))
    if #operation_queue == 1 then
        OperationQueueCall();
    end
end

function OperationQueueNext()
    --ERROR_LOG('OperationQueueNext', operation_queue[1] and operation_queue[1].idx or '-', #operation_queue, debug.traceback())
    table.remove(operation_queue, 1);
    OperationQueueCall();
end
