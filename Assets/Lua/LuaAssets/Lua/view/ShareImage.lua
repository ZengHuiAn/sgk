local ShareImage = {} 

function ShareImage:Start()
end
function ShareImage:Create(data)
    self.view=SGK.UIReference.Setup(self.gameObject)
    if data then
       self.path=data.path
    else
        return
    end
   -- ERROR_LOG("path===>>",self.path)
    self:Load()
end
function ShareImage:Load()
    if not self.path then
       return
    end
    StartCoroutine(function()
        local www = UnityEngine.WWW("file://" .. self.path)
        Yield(www)
        if not www.texture then
            local theMR = www.texture
            local sprite = UnityEngine.Sprite.Create(theMR,UnityEngine.Rect(0,0,theMR.width,theMR.height),UnityEngine.Vector2(0.5,0.5))
            self.view[UI.Image].sprite=sprite
        else
            showDlgError(nil, "error")
            -- local fileStream = CS.System.IO.FileStream(self.path,CS.System.IO.FileMode.Open,CS.System.IO.FileAccess.Read)
            -- --fileStream.Seek(0,CS.System.IO.SeekOrigin.Begin)
            -- ERROR_LOG("1====>>",fileStream.Length)
            -- local bytes=CS.System.IO.byte[fileStream.Length]
            -- ERROR_LOG("2====>>",sprinttb(bytes))
            -- fileStream.Read(bytes,1,fileStream.Length)
            -- print("3")
            -- fileStream.Close()
            -- print("4")
            -- fileStream.Dispose()
            -- print("6")
            -- fileStream=nil
            -- local width = 300
            -- local height = 372
            -- local texture = UnityEngine.Texture2D(width,height)
            -- texture.LoadImage(bytes)
            -- local sprite = Sprite.Create(texture, UnityEngine.Rect(0, 0, texture.width, texture.height), UnityEngine.Vector2(0.5, 0.5))
            -- self.view[UI.Image].sprite=sprite
        end
    end)
    
end

    


return ShareImage