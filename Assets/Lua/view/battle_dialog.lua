local View = {}

function View:Start()
    self.view = SGK.UIReference.Setup(self.gameObject);

    self.conversation = {};
    self.views = {}
    self.index = 0;

    SGK.Action.DelayTime.Create(0.5):OnComplete(function()
        CS.UGUIClickEventListener.Get(self.view.gameObject, true).onClick = function()
            self:Next();
        end
    end)
    
    self.view[UnityEngine.UI.Image].enabled = false;
end

function View:Add(info)
    table.insert(self.conversation, info);
    self:Next();
end

function View:SetResumeFunction(fun)
    self.ResumeFunction = fun
end

function View:Next()
    self.next_time = self.next_time or 0;
    if CS.UnityEngine.Time.realtimeSinceStartup	- self.next_time < 0.2 then
        return;
    end

    local info = self.conversation[self.index + 1];

    if not info then
        if not self.ResumeFunction then
            ERROR_LOG("________________________________SetResumeFunction ERROR")
            return
        end

        self.ResumeFunction()        
        self.view[UnityEngine.UI.Image].enabled = false;

        for k, v in pairs(self.views) do
            UnityEngine.GameObject.Destroy(v.gameObject);
        end
        self.views = {};
        self.conversation = {}
        self.index = 0;
            
        self.auto_next_time = nil;
        self.auto_next_obj = nil;
        return;
    end

    self.next_time = CS.UnityEngine.Time.realtimeSinceStartup;
    self.index = self.index + 1;
    self.view[UnityEngine.UI.Image].enabled = true;
    for k, v in pairs(self.views) do
        if k < self.index - 2 then
            UnityEngine.GameObject.Destroy(v.gameObject);
            self.views[k] = nil;
        else
            v.transform:DOLocalMoveY(180, 0.3):SetRelative(true);
            v.ClickFlag:SetActive(false);
        end
    end

    local view = SGK.UIReference.Instantiate( (info.side == 1) and self.view.Left.gameObject or self.view.Right.gameObject);
    
    
    view:SetActive(true);
    view.transform:SetParent(self.view.transform, false);
    view.transform:DOAnchorPosX( (info.side == 1) and 765 or -765, 0.3):SetRelative(true):SetDelay(0.1);--:From():SetRelative(true):SetDelay(0.1);
    
    view.BG[CS.UGUISpriteSelector].index = info.bg or 0;
    view.BG[UnityEngine.UI.Image]:SetNativeSize();
    view.NameLabel[UnityEngine.UI.Text].text = info.name;

    local icon = utils.IconFrameHelper.Create(view.IconFrame, {customCfg = {
        level = 0,
        star = 0,
        quality = info.quality or 0,
        icon = info.icon
    }, type = 42,func = function (iconItem)
        -- iconItem.Frame:SetActive(false)
    end})
    
    icon:GetComponent(typeof(SGK.CommonIcon))._FrameImage.enabled = false;

    view.MessageLabel[UnityEngine.UI.Text].text = info.message;

    self.views[self.index] = view;

    if self.views[self.index - 1] then
        self.views[self.index - 1].IsRead = true 
    end

    local battle = CS.SGK.UIReference.Setup(UnityEngine.GameObject.FindWithTag("battle_root"))

    if info.sound and type(info.sound) == "string" then
        battle[SGK.LuaBehaviour]:Call("PlaySound", info.sound);
    end
    
    self.auto_next_time = info.duration or 4;
    self.auto_next_obj = view;
    -- self:Auto_Next(view, info.sound and type(info.sound) == "string" and )
end

function View:Update()
    if self.auto_next_time and self.auto_next_time > 0 then
        self.auto_next_time = self.auto_next_time - UnityEngine.Time.deltaTime;
        if self.auto_next_time <= 0 then
            if self.auto_next_obj and not self.auto_next_obj.IsRead then
                self:Next();
            end
        end
    end
end

--[[
function View:Auto_Next(obj, delay)
    SGK.Action.DelayTime.Create(delay):OnComplete(function() 
        if obj and not obj.IsRead then
            self:Next()
        end
    end)    
end
--]]
    
return View;