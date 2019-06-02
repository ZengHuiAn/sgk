local TotalHurtPanel = {}

local wait_list = {}
local show_list = {}
local domove_x = 200
local domove_y = 60

function TotalHurtPanel:Start()
    self.view = SGK.UIReference.Setup(self.gameObject)
    for i = 1, 4, 1 do
        self["clone"..i] = SGK.UIReference.Instantiate(self.view.total_hurt.gameObject, self.view.transform)
        self["clone"..i]:SetActive(true)
        table.insert(wait_list, self["clone"..i])
    end
    self.original_localPosition = self.view.total_hurt.transform.localPosition
end

function TotalHurtPanel:Create(info)
    local item = wait_list[1]
    item.skillbg.num[UI.Text].text = info.num
    item.skillbg.skillname[UI.Text].text = info.skill_name
    item.playerbg.playername[UI.Text].text = info.player_name
    self:Add(item)
end

function TotalHurtPanel:Add(item)
    item[UnityEngine.CanvasGroup].alpha = 1

    item.transform:DOLocalMove(Vector3(self.original_localPosition.x + domove_x, self.original_localPosition.y, 0), 0.5):OnComplete(function (...)
        item.transform:DOScale(Vector3(1, 1, 1), 3):OnComplete(function (...)
            item[UnityEngine.CanvasGroup]:DOFade(0, 0.5)
        end)
    end)

    table.remove(wait_list, 1)
    table.insert(show_list, item)

    for k, v in ipairs(show_list) do
        v.transform:DOLocalMove(Vector3(self.original_localPosition.x + domove_x, self.original_localPosition.y + domove_y * (#show_list - k), 0), 0.5)
    end

    if #show_list >= 4 then
        local obj = show_list[1]
        obj.transform:DOKill()
        obj[UnityEngine.CanvasGroup]:DOKill()
        obj.transform.localPosition = self.original_localPosition
        table.remove(show_list, 1)
        table.insert(wait_list, obj)    
    end
end


return TotalHurtPanel;