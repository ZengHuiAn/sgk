

local shareFrame = {}

function shareFrame:Start(data)
    --ERROR_LOG("ding======分享Start",sprinttb(data))
    if data then
        self._data=data  
    else
        showDlgError(nil, "error")
        return
    end
    self:initUi()
end
function shareFrame:initUi()
    self.view = CS.SGK.UIReference.Setup(self.gameObject)
    self:loadSpirit()
    CS.UGUIClickEventListener.Get(self.view.root.bg.gameObject).onClick=function()
        DialogStack.Pop()
    end
    CS.UGUIClickEventListener.Get(self.view.root.Btn.gameObject).onClick=function()
        DispatchEvent("SCREEN_SHOT", {name = self._data.name, path=UnityEngine.Application.persistentDataPath.."/".."ScreenShots"..".png"})
    end
end
function shareFrame:loadSpirit()
    --utils.IconFrameHelper.Create(self.view.root.bg,{path=self._data.path})
    self.view:SetActive(false)
    StartCoroutine(function()
        WaitForEndOfFrame()
        local tex = UnityEngine.ScreenCapture.CaptureScreenshotAsTexture()
       -- ERROR_LOG("tex====>>",tex)
        --self.view.root.bg[UI.RawImage].material.mainTexture=tex
        local sprite = UnityEngine.Sprite.Create(tex,UnityEngine.Rect(0,0,tex.width,tex.height),UnityEngine.Vector2(0.5,0.5))
       -- ERROR_LOG("tex1====>>",sprite)
        self.view.root.bg[UI.Image].sprite=sprite
        self.view:SetActive(true)
        if self.view.gameObject.activeInHierarchy then
            --ERROR_LOG("截屏成功")
            local fillName = "ScreenShots"
	        local fill=""
            StartCoroutine(function ()
              WaitForEndOfFrame();
              fill =UnityEngine.Application.persistentDataPath.."/"..fillName..".png";
              UnityEngine.ScreenCapture.CaptureScreenshot(fill);
            end)
        end
    end)
end


-- function shareFrame:listEvent()
--     return {
--         "SCREEN_SHOT",
--     }
-- end
-- function shareFrame:onEvent(event, data)
--     if event=="SCREEN_SHOT" then
--         ERROR_LOG("数据====>>>>>",sprinttb(data))
--     end
-- end

return shareFrame