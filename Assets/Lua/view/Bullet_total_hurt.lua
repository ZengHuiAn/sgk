local View = {}

function View:Start()
    self.destory_time = 1.3
end

function View:Refresh()
    self.destory_time = 1.3
end

function View:Setup(id)
    self.id = id
end

function View:Update()
    if self.destory_time and self.destory_time > 0 then
        self.destory_time = self.destory_time - UnityEngine.Time.deltaTime;
        if self.destory_time <= 0 then
            self.gameObject:SetActive(false)
        end
    end
end
    
return View;