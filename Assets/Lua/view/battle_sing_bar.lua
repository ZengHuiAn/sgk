local Sing_bar = {}

local x = 0
local total_lenght = 0
local animate_time = 0.2

local proofread_list = {
    [1] = {total_lenght = 185 , x = -0.75 },
    [2] = {total_lenght = 83 , x = -1.125 },
}

function Sing_bar:CleanObjs()
    for i = 1,  self.total_count, 1 do
        UnityEngine.GameObject.Destroy(self["bar_"..i].gameObject)
        self["bar_"..i] = nil
    end
    self.total_count = 0
end

function Sing_bar:CleanSingBar()
    if self.current_count ~= self.total_count then
        self.Tween:DORestart(true)
    end
    self.view.total.transform:DOScale(Vector3(1,1,1), 0.6):OnComplete(function()
        self.gameObject:SetActive(false)
        self:CleanObjs()
    end)
end

function Sing_bar:Start()
    if self.gameObject.tag == "big_skill" then
        x = proofread_list[1].x
        total_lenght = proofread_list[1].total_lenght
    else
        x = proofread_list[2].x
        total_lenght = proofread_list[2].total_lenght
    end
    self.view = SGK.UIReference.Setup(self.gameObject)
    self.Tween = self.view[CS.DG.Tweening.DOTweenAnimation]
    self.bar = self.view.total.bars.bar
end

function Sing_bar:CreateSingBar(type, total, current, certainly_increase, beat_back)
    self.current_count = 0
    self.bar_width = (total_lenght / total) - x
    self.sing_type = type
    self.total_count = total
    self.view.type.text[CS.UGUISpriteSelector].index = self.sing_type - 1

    self.view.total.bars[UI.GridLayoutGroup].cellSize = CS.UnityEngine.Vector2(self.bar_width, 5)

    self.bar.barvalue_1[UnityEngine.RectTransform].sizeDelta = CS.UnityEngine.Vector2(self.bar_width, 5)
    self.bar.barvalue_2[UnityEngine.RectTransform].sizeDelta = CS.UnityEngine.Vector2(self.bar_width, 5)
    self.bar.barvalue_2[CS.UGUISpriteSelector].index = self.sing_type - 1
    for i = 1, total, 1 do
        self["bar_"..i] = SGK.UIReference.Instantiate(self.bar.gameObject, self.view.total.bars.transform)
        self["bar_"..i]:SetActive(true)
        self["bar_"..i].Status = "Null"
        self["bar_"..i].dotween = self["bar_"..i].barvalue_1[CS.DG.Tweening.DOTweenAnimation]
    end

    self:SetSingBar(current, certainly_increase, beat_back)
end

function Sing_bar:SetSingBar(current, certainly_increase, beat_back)
    if self.current_count > current then
        print("=========@@@@!!!!!!!!!!!!!!!! 蓄力条不予许倒退")
        return
    end

    self.current_count = math.min(current, self.total_count)

    for i = 1, self.total_count, 1 do
        local obj = self["bar_" .. i]
        if i <= current then
            obj.To_Status = "Current"
        elseif i > current and i <= (current + certainly_increase) then
            obj.To_Status = "Certainly_Increase"
        elseif i > (current + certainly_increase) and i <= (current + certainly_increase + beat_back) then
            obj.To_Status = "Beat_Back"
        else
            obj.To_Status = "Null"
        end
    end
    self:SetSingBarStatus(self.total_count)
end

local _total = 0 
local _index = 0

function Sing_bar:SetSingBarStatus(total_count)
    if total_count then
        _total = total_count
        _index = 0
    end

    if _index == _total then
        for i = 1, self.total_count, 1 do
            local obj = self["bar_" .. i]
            obj.Status = obj.To_Status
        end    
        return
    end
    _index = _index + 1

    local obj = self["bar_" .. _index]

    if obj.To_Status ~= obj.Status then
        if obj.To_Status == "Current" then
            obj.barvalue_2.transform:DOScale(Vector3(1, 1, 1), animate_time):OnComplete(function()
                obj.barvalue_1:SetActive(false)
                self:SetSingBarStatus()
            end)
            return
        end

        if obj.To_Status == "Certainly_Increase" then
            obj.dotween:DORewind()
            obj.dotween:DOPause()
            obj.barvalue_1.transform:DOScale(Vector3(1, 1, 1), animate_time):OnComplete(function()
                self:SetSingBarStatus()
            end)
            return
        end

        if obj.To_Status == "Beat_Back" and obj.Status == "Null" then
            obj.barvalue_1.transform:DOScale(Vector3(1, 1, 1), animate_time):OnComplete(function()
                obj.dotween:DORestart(true)
                self:SetSingBarStatus()
            end)
            return
        end

        if obj.To_Status == "Null" and obj.Status == "Beat_Back" then
            obj.dotween:DORewind()
            obj.dotween:DOPause()
            self.Tween:DORestart(true)
            obj.barvalue_1.transform:DOScale(Vector3(0, 1, 1), animate_time * 2):OnComplete(function()
                self:SetSingBarStatus()
            end)
            return
        end        
    end

    self:SetSingBarStatus()
end
    
return Sing_bar