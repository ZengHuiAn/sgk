local playerModule = require "module.playerModule"
local honorModule = require "module.honorModule"
local View = {}

function View:Start()
    self.view = CS.SGK.UIReference.Setup(self.gameObject)

    self.playerNode=self.view.rolesSmallNode.CharacterPrefab
    -- self:initBottom()
    -- self:upBottom()
    -- self:initQmodule()
end





function View:UpdateSpine(mode)
    local skeletonAnimation = self.playerNode.Character.Sprite[Spine.Unity.SkeletonAnimation];
    if self.mode ~= mode or not skeletonAnimation.skeleton then
        self.mode = mode

        SGK.ResourcesManager.LoadAsync(skeletonAnimation, string.format("roles_small/%s/%s_SkeletonData.asset", mode, mode), function(o)
            if o ~= nil then
                skeletonAnimation.skeletonDataAsset = o
                skeletonAnimation:Initialize(true);
                skeletonAnimation.state:SetAnimation(0, "idle1", true);

                --self.qModule.Character.Sprite[SGK.CharacterSprite]:SetDirty()
            else
                SGK.ResourcesManager.LoadAsync(skeletonAnimation, string.format("roles_small/11000/11000_SkeletonData.asset"), function(o)
                    skeletonAnimation.skeletonDataAsset = o
                    skeletonAnimation:Initialize(true);

                    skeletonAnimation.state:SetAnimation(0, "idle1", true);
                    --self.qModule.Character.Sprite[SGK.CharacterSprite]:SetDirty()
                end);
            end
        end);
    end
end

function View:UpdateFootPrint(ShowItemCfg) 
    if ShowItemCfg and ShowItemCfg.effect_type==2 then
        if self.footPrint ~= ShowItemCfg.id then
            self.footPrint = ShowItemCfg.id
            for i = 1,self.playerNode.footprint.transform.childCount do  
                UnityEngine.GameObject.Destroy(self.playerNode.footprint.transform:GetChild(i-1).gameObject)
            end
            for i = 1,self.playerNode.shadow.transform.childCount do  
                UnityEngine.GameObject.Destroy(self.playerNode.shadow.transform:GetChild(i-1).gameObject)
            end
          
            local footprint_effect = SGK.ResourcesManager.Load("prefabs/effect/UI/"..ShowItemCfg.effect..".prefab")
            if footprint_effect then
                local FootEffect = nil
                if ShowItemCfg.sub_type == 75 then
                    FootEffect = CS.UnityEngine.GameObject.Instantiate(footprint_effect,self.playerNode.footprint.transform)
                else
                    FootEffect = CS.UnityEngine.GameObject.Instantiate(footprint_effect,self.playerNode.shadow.transform)
                end
                FootEffect.layer = UnityEngine.LayerMask.NameToLayer("qPlayer");
                for i = 0,FootEffect.transform.childCount-1 do
                    FootEffect.transform:GetChild(i).gameObject.layer = UnityEngine.LayerMask.NameToLayer("qPlayer");
                end
                FootEffect.transform.localPosition = Vector3.zero
            end
        end
    else
        for i = 1,self.playerNode.footprint.transform.childCount do  
            UnityEngine.GameObject.Destroy(self.playerNode.footprint.transform:GetChild(i-1).gameObject)
        end
        for i = 1,self.playerNode.shadow.transform.childCount do  
            UnityEngine.GameObject.Destroy(self.playerNode.shadow.transform:GetChild(i-1).gameObject)
        end
        self.footPrint=nil
    end
end
function View:UpdateWidget(ShowItemCfg)
    if ShowItemCfg and ShowItemCfg.effect_type==2 then
        if self.Widget ~= ShowItemCfg.id then
            self.Widget = ShowItemCfg.id
            for i = 1,self.playerNode.Widget.transform.childCount do  
                UnityEngine.GameObject.Destroy(self.playerNode.Widget.transform:GetChild(i-1).gameObject)
            end
       
            local Widget_effect = SGK.ResourcesManager.Load("prefabs/effect/UI/"..ShowItemCfg.effect..".prefab")
            if Widget_effect then
                local WidgetEffect = CS.UnityEngine.GameObject.Instantiate(Widget_effect,self.playerNode.Widget.transform)
                WidgetEffect.layer = UnityEngine.LayerMask.NameToLayer("qPlayer");
                self:SetAllChildLayer(WidgetEffect.transform,"qPlayer")
                SGK.ParticleSystemSortingLayer.Set(WidgetEffect, 30000);
                WidgetEffect .transform.localPosition = Vector3.zero
            end
        end
    else
        for i = 1,self.playerNode.Widget.transform.childCount do  
            UnityEngine.GameObject.Destroy(self.playerNode.Widget.transform:GetChild(i-1).gameObject)
        end
        self.Widget=nil
    end
end

function View:SetAllChildLayer(_parent,_layer)
    if _parent.childCount>0 then
        for i=0,_parent.transform.childCount-1 do
            _parent.transform:GetChild(i).gameObject.layer = UnityEngine.LayerMask.NameToLayer(_layer);   
            self:SetAllChildLayer(_parent.transform:GetChild(i).gameObject.transform,_layer)
        end
    end
end

function View:OnDestroy()

end
--[[
function View:initQmodule()
    if self.qModule then
        self.qModule:AddComponent(typeof(CS.Spine.Unity.SkeletonAnimation))
        local _go = self.qModule:GetComponent(typeof(CS.Spine.Unity.SkeletonAnimation))
        local info = module.HeroModule.GetConfig(playerModule.Get().head) or {mode = 11000}
        SGK.ResourcesManager.LoadAsync(_go, "roles_small/"..info.mode.."/"..info.mode.."_SkeletonData", function(o)
            if o then
                _go.skeletonDataAsset = o
                _go:Initialize(true)
                local _sprite = self.qModule:AddComponent(typeof(SGK.CharacterSprite))
                _sprite:SetDirty()
            else
                local _mode = 11001
                SGK.ResourcesManager.LoadAsync(_go, "roles_small/".._mode.."/".._mode.."_SkeletonData", function(o)
                    _go.skeletonDataAsset = o
                    _go:Initialize(true)
                    local _sprite = self.qModule:AddComponent(typeof(SGK.CharacterSprite))
                    _sprite:SetDirty()
                end)
            end
        end)
    end
end

function View:initBottom()
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

function View:upBottom()
    local player = playerModule.Get();
    self.name.text = player.name
    if player and player.honor ~= 0 then
        self.inputText.text = honorModule.GetCfg(player.honor).name;
    end
end
--]]

function View:listEvent()
    return {
        "DESTROY_QPLAYER_NODE",

    }
end

function View:onEvent(event, ...)
    if event == "DESTROY_QPLAYER_NODE" then
        if self.gameObject then
            CS.UnityEngine.GameObject.Destroy(self.gameObject)
        end
    end
end

return View