local View = {}

local textureSize = 10
local texture2D = nil
local offest = nil

local materail = nil
function View:Start( data )

    self.view = CS.SGK.UIReference.Setup(self.gameObject)
    texture2D = UnityEngine.Texture2D(textureSize*textureSize,textureSize*textureSize,UnityEngine.TextureFormat.ARGB32, false);

    materail = self.view[UnityEngine.MeshRenderer].material;

    materail:SetTexture("_MainTex", texture2D);
    self.MapSceneController = UnityEngine.GameObject.FindObjectOfType(typeof(SGK.MapSceneController));
    self.pid = module.playerModule.Get().id
    local character = self.MapSceneController:Get(self.pid) 
    self.target = character;

    offest = textureSize * textureSize / 2;
end

function View:Update( ... )
    

    if self.target then
        
    end
end

function View:GetPlayerPos( ... )
    if self.target then
        local pos = self.target.transform.position;
        return {x = pos.x + offest,y = pos.z} ;
    end
end

return View;