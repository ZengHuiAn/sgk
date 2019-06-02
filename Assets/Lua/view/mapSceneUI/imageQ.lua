local playerModule = require "module.playerModule"
local honorModule = require "module.honorModule"
local imageQ = {}

function imageQ:Start()
    self:initData()
    self:initUi()
end

function imageQ:initData()

end

function imageQ:initUi()
    self.view = CS.SGK.UIReference.Setup(self.gameObject)
    self.qPlayerNode = CS.UnityEngine.GameObject.Find("qPlayerNode")
    if not self.qPlayerNode then
        local prefab = SGK.ResourcesManager.Load("prefabs/mapSceneUI/qPlayerNode.prefab")
        self.qPlayerNode = CS.UnityEngine.GameObject.Instantiate(prefab)
        local _view = CS.SGK.UIReference.Setup(self.qPlayerNode)
        self.qModule = _view.rolesSmallNode
    end
    self:initBottom()
    self:upBottom()
    self:initQmodule()
end

function imageQ:OnDestroy()
    if self.qPlayerNode then
        UnityEngine.GameObject.Destroy(self.qPlayerNode.gameObject)
    end
end

function imageQ:initQmodule()
    if self.qModule then
        self.qModule:AddComponent(typeof(CS.Spine.Unity.SkeletonAnimation))
        local _go = self.qModule:GetComponent(typeof(CS.Spine.Unity.SkeletonAnimation))
        local info = module.HeroModule.GetConfig(playerModule.Get().head) or {mode = 11000}
        SGK.ResourcesManager.LoadAsync(_go, "roles_small/"..info.mode.."/"..info.mode.."_SkeletonData.asset", function(o)
            if o then
                _go.skeletonDataAsset = o
                _go:Initialize(true)
                local _sprite = self.qModule:AddComponent(typeof(SGK.CharacterSprite))
                _sprite:SetDirty()
            else
                local _mode = 11001
                SGK.ResourcesManager.LoadAsync(_go, "roles_small/".._mode.."/".._mode.."_SkeletonData.asset", function(o)
                    _go.skeletonDataAsset = o
                    _go:Initialize(true)
                    local _sprite = self.qModule:AddComponent(typeof(SGK.CharacterSprite))
                    _sprite:SetDirty()
                end)
            end
        end)
    end
end

function imageQ:initBottom()
    self.name = self.view.imageQRoot.bottom.name[UI.Text]
    self.inputText = self.view.imageQRoot.bottom.InputField[UI.InputField]
    local player = playerModule.Get();
    if player and player.honor ~= 0 then
        self.inputText.text = honorModule.GetCfg(player.honor).name;
    end
    
    CS.UGUIClickEventListener.Get(self.view.imageQRoot.bottom.changeBtn.gameObject).onClick = function()
        DialogStack.PushPrefStact("mapSceneUI/item/honor", nil, UnityEngine.GameObject.FindWithTag("UGUIRootTop"))
    end
end

function imageQ:upBottom()
    local player = playerModule.Get();
    self.name.text = player.name
    if player and player.honor ~= 0 then
        self.inputText.text = honorModule.GetCfg(player.honor).name;
    end
end

function imageQ:listEvent()
    return {
        "PLAYER_INFO_CHANGE",
        "ITEM_INFO_CHANGE",
    }
end

function imageQ:onEvent(event, ...)
    if event == "PLAYER_INFO_CHANGE" then
        self:upBottom()
    end
end

return imageQ