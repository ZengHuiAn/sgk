local achievementNode = {}

local AreaPoint = {
    {x = -10.75,y = -86,id = 3,duration = 0.5},
    {x = -10.75,y = 25, id = 2,duration = 0.5},
    {x = -10.75,y = 136,id = 1,duration = 0.5},
}
local duration = 1;

local QuestModule = require "module.QuestModule"
local QuestNode = {}
function QuestNode:New( quest_id )
    local o = {}

    o.quest_id = quest_id;

    setmetatable(o, {__index = function ( tb,k )
        local questCfg = QuestModule.GetCfg(o.quest_id);
        -- ERROR_LOG("=========>>>",sprinttb(questCfg));
        assert(questCfg, o.quest_id.."\t is not exits ");

        local ret = rawget(QuestNode,k);

        if not ret then
            ret = rawget(questCfg,k);
        end
        return ret;
    end})
    return o;
end

function QuestNode:AddObj( prefab,root )
    local obj = UnityEngine.GameObject.Instantiate(prefab.gameObject,root.gameObject.transform);
    return CS.SGK.UIReference.Setup(obj)
end

function achievementNode:Push( data )
    local Node = QuestNode:New(data);
    self.Queue = self.Queue or {}
    table.insert( self.Queue, Node );

    -- ERROR_LOG("入队",data);
end

function achievementNode:Start(data)
    self:initUi();

    self.queue = {};
    
    local cfg = QuestModule.GetCfg(tonumber(data.quest_id))
    -- ERROR_LOG("成就配置---------->>>",cfg.desc1);
    if cfg.type == 31 then
        self:Push(tonumber(data.quest_id));
        self.queueStatus = true;
    elseif cfg.type == 32 then
        self:updateLock(cfg);
    end

    StartCoroutine(function ( ... )
        self:Pop();
    end)
end


function achievementNode:PopAll(index,func)
    -- ERROR_LOG(#self.queue,index);
    if (self.queue and #self.queue ~=0) or self.lock then
        for k,v in pairs(self.queue) do
            self.queue[k][UnityEngine.RectTransform]:DOLocalMoveX(999,1):OnComplete(function ( ... )
                UnityEngine.Object.Destroy(self.queue[k].gameObject,1);
            end);
        end
        self.root2.content1[UnityEngine.RectTransform]:DOLocalMoveX(999,1):OnComplete(function ( ... )
            if func then
               func();
            end 
        end);

    else

        if func then
           func();
        end    
    end
end

function achievementNode:Pop( ... )
    self.Queue = self.Queue or {}
    if #self.Queue == 0 then
        self.queueStatus = nil
        if self.lockCfg then
            self:updateLock(self.lockCfg)
        end
        -- ERROR_LOG(self.lock and 3 or 1);
        
        if self.action then
            self.action:Kill();
        end
        self.action = SGK.Action.DelayTime.Create((self.lock and 4 or 3)):OnComplete(function ( ... )
            
            if not self.queueStatus then
                StartCoroutine(function ( ... )
                    self:PopAll(1,function ( ... )
                        DialogStack.Destroy("mapSceneUI/achievementNode");
                    end);
                end)
                
            end
        end)
        return;
    end
    
    self.achieve = true;
    
    local id = self.Queue[1];
    table.remove( self.Queue, 1);

    -- ERROR_LOG(id,"出队");
    self:DONext();
    self:AddItem(id)
    
    PopUpTipsQueue()
    self:Pop();

end

function achievementNode:initUi()
    self.view = CS.SGK.UIReference.Setup(self.gameObject)

    self.root1 = self.view.root.Area.Area1;
    self.prefab = self.view.root.Area.Area1.content1;
    self.root2 = self.view.root.Area.Area2;
end

function achievementNode:updateLock( config )
    self.root2.content1:SetActive(false);
    self.lock = true
    self.root2.content1.info[UI.Text].text = config.desc1
    self.root2.content1:SetActive(true);
    PopUpTipsQueue()
    
    CS.UGUIClickEventListener.Get(self.root2.content1.watch.gameObject).onClick = function()
        module.QuestModule.StartQuestGuideScript(QuestModule.Get(tonumber(config.id)),true)
        self.root2.content1:SetActive(false);

        if not self.achieve then
            if self.action then
                self.action:Kill();
            end

            DialogStack.Destroy("mapSceneUI/achievementNode");
        end
    end
end

function achievementNode:AddItem( data )
    -- ERROR_LOG(sprinttb(data));
    local obj = UnityEngine.GameObject.Instantiate(self.prefab.gameObject,self.root1.gameObject.transform);
    local _view = CS.SGK.UIReference.Setup(obj);
    _view[UnityEngine.RectTransform].anchoredPosition = UnityEngine.Vector2(AreaPoint[1].x,AreaPoint[1].y);
    local Config = QuestModule.GetCfg(tonumber(data.quest_id))
    _view.info[UI.Text].text = Config.cfg.raw.desc1;

    _view.name[UI.Text].text = Config.cfg.raw.name;
    self.queue = self.queue or {};
    table.insert( self.queue, _view );
    _view:SetActive(true);

    -- _view[UnityEngine.Animator].enabled = true
end

function achievementNode:DONext()
    local obj = self.queue[1];
    if obj and #self.queue == 3 then
        table.remove( self.queue, 1);
        UnityEngine.Object.Destroy(obj.gameObject,1);
        WaitForSeconds(duration);
    end 
    if #self.queue == 1 then
        local info = self.queue[1];
        if info then
            info[UnityEngine.RectTransform]:DOLocalMoveY(AreaPoint[2].y,AreaPoint[2].duration);
            -- WaitForSeconds(duration);
            -- PopUpTipsQueue();
        end
        return;
    end

    for i=1,2 do
        local info = self.queue[i];
        if info then
            -- ERROR_LOG( string.format( "do next %d",4-i));
            info[UnityEngine.RectTransform]:DOLocalMoveY(AreaPoint[4-i].y,AreaPoint[4-i].duration);
            -- PopUpTipsQueue();
        end
    end
    WaitForSeconds(duration);
end

function achievementNode:DONext_Pro()
    -- ERROR_LOG();
    local obj = self.queue[1];
    if obj and #self.queue == 3 then
        table.remove( self.queue, 1);
        UnityEngine.Object.Destroy(obj.gameObject);
        WaitForSeconds(duration);
    end 
    if #self.queue == 1 then
        local info = self.queue[1];
        if info then
            info[UnityEngine.RectTransform]:DOLocalMoveY(AreaPoint[2].y,AreaPoint[2].duration);
            WaitForSeconds(duration);
        end
        return;
    end

    for i=1,2 do
        local info = self.queue[i];
        if info then
            -- ERROR_LOG( string.format( "do next %d",4-i));
            info[UnityEngine.RectTransform]:DOLocalMoveY(AreaPoint[4-i].y,AreaPoint[4-i].duration);
            WaitForSeconds(duration);
        end
    end
end


function achievementNode:OnDestroy()
    PopUpTipsQueue()
end


function achievementNode:listEvent()
    return {
        "LOCAL_SELF_ACHIEVEMENT_CHANGE",
        "LOCAL_ACHIEVEMENT_CHANGE",
    }
end

function achievementNode:onEvent( event,data )
    if event == "LOCAL_SELF_ACHIEVEMENT_CHANGE" then
        if data then
            local cfg = QuestModule.GetCfg(tonumber(data.quest_id))
            -- ERROR_LOG(sprinttb(cfg));
            if self.action then
                self.action:Kill();
            end

            if cfg.cfg.type == 31 then
                self:Push(tonumber(data.quest_id));
                
                if not self.queueStatus then
                    self.queueStatus = true
                    StartCoroutine(function ( ... )
                        self:Pop();
                    end)
                end
            elseif cfg.cfg.type == 32 then
                --解锁成就配置
                self.lockCfg = cfg;
                if not self.queueStatus then
                    StartCoroutine(function ( ... )
                        self:Pop();
                    end)
                end
            end
            

            -- ERROR_LOG("队列---------->>>>",self.queueStatus,sprinttb(self.Queue));
        end
    else
        PopUpTipsQueue()
    end
end

return achievementNode
