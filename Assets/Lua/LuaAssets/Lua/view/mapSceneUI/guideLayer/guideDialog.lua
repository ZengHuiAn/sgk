local guideDialog = {}

function guideDialog:Start(data)
    --self:initData(data)
    self.data = data
    self:initUi(data)
end

function guideDialog:initData(data)
    self.questId = data.questId
end

function guideDialog:initUi(data)
    self.view = CS.SGK.UIReference.Setup(self.gameObject)
    --self.quest = module.QuestModule.Get(self.questId)
    -- if self.quest then
    self.view.root.desc[UI.Text].text = data.desc
    --self.view.root.icon[UI.Image]:LoadSprite("guideLayer/"..data.icon)
    self.view.root.icon[UI.Image]:LoadSprite("guideLayer/"..data.icon, function()
        self.view.root.icon[UI.Image]:SetNativeSize()
    end)
    if utils.SGKTools.GetTeamState() and not utils.SGKTools.isTeamLeader() then
        module.TeamModule.TEAM_AFK_REQUEST()
        showDlgError(nil,SGK.Localize:getInstance():getValue("xinshouyindao01"))
    end
    utils.EventManager.getInstance():dispatch("GUIDE_DIALOG_START")
    if UnityEngine.SceneManagement.SceneManager.GetActiveScene().name == "newSelectMapUp" then
        module.quickToUseModule.Clear()
    end
    -- if CS.UnityEngine.GameObject.Find("quickToHeroNode") then 
    --     local obj = CS.UnityEngine.GameObject.Find("quickToHeroNode")
    --     if obj.transform.childCount > 0 then
    --         CS.UnityEngine.GameObject.Destroy(obj.transform:GetChild(0).gameObject)
    --         module.EquipHelp.RemoveQuick()
    --     end
    -- end
    -- if CS.UnityEngine.GameObject.Find("quickToUseNode") then 
    --     local obj = CS.UnityEngine.GameObject.Find("quickToUseNode")
    --     if obj.transform.childCount > 0 then
    --         for k,v in pairs(module.quickToUseModule.Get()) do
    --             if module.quickToUseModule.RemoveItem(v.gid, {colseAll = true}) <= 0 then
    --                 UnityEngine.GameObject.Destroy(obj.transform:GetChild(0).gameObject)
    --             end
    --         end
    --     end
    -- end
    -- end
    -- CS.UGUIClickEventListener.Get(self.view.mask.gameObject).onClick = function()
    --     DialogStack.Pop()
    -- end
    CS.UGUIClickEventListener.Get(self.view.root.Btn.gameObject).onClick = function()
        utils.EventManager.getInstance():dispatch("GUIDE_DIALOG_START")
        print("引导框查看状态",UnityEngine.SceneManagement.SceneManager.GetActiveScene().name,utils.SGKTools.Athome())
        if UnityEngine.SceneManagement.SceneManager.GetActiveScene().name == "newSelectMapUp" then
            module.guideModule.SetGuideDialogId(data.id)
            module.quickToUseModule.Clear()
            DialogStack.CleanAllStack()
            SceneStack.EnterMap(1,nil,true)
        elseif not utils.SGKTools.Athome() then
            module.guideModule.SetGuideDialogId(data.id)
            DialogStack.CleanAllStack()
            SceneStack.EnterMap(1,nil,true)
        else
            DialogStack.CleanAllStack()
            --print("zoe 发送发送GUIDE_DIALOG_CLOUSE")
            utils.EventManager.getInstance():dispatch("GUIDE_DIALOG_CLOUSE",{id = data.id})
        end
        CS.UnityEngine.GameObject.Destroy(self.view.gameObject)
    end
end

function guideDialog:onEvent(event,data)
    if event == "KEYDOWN_ESCAPE_ONLY" then
        CS.UnityEngine.GameObject.Destroy(self.view.gameObject)
    end
end

function guideDialog:listEvent()
    return {
        "KEYDOWN_ESCAPE_ONLY",
    }
end
return guideDialog
