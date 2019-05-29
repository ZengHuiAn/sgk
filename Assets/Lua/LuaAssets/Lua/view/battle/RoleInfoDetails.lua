local roleinfo_details = {}

local proofread = 25
local Screen_width = 0
local detail_width = 0
local x_while_left = 0
local x_while_right = 0
local animate_time = 0.15

local proofread_y = 60

function roleinfo_details:Start()
    self.view = SGK.UIReference.Setup(self.gameObject)
    Screen_width = self.view[UnityEngine.RectTransform].rect.width
    detail_width = self.view.buffdetail[UnityEngine.RectTransform].rect.width

    x_while_left = -(Screen_width/2 - detail_width/2) + proofread
    x_while_right = (Screen_width/2 - detail_width/2) - proofread
end

function roleinfo_details:UpdateBuffDetails(click_pos, info)
    if info.desc == "" then
        return
    end
    local buffdetail = self.view.buffdetail

    buffdetail.Text[UnityEngine.UI.Text].text = info.desc

    local algin_x = 0

    if click_pos.x < detail_width/2 + proofread then
        algin_x = x_while_left
    elseif (Screen_width - click_pos.x) < detail_width/2 + proofread then
        algin_x = x_while_right
    end

    local flag_local_y = buffdetail.flag.transform.localPosition.y

    if algin_x == 0 then
        buffdetail.transform.position = Vector3(click_pos.x, click_pos.y - flag_local_y * 2 + proofread_y, 0)
        buffdetail.flag.transform.position = Vector3(click_pos.x, flag_local_y + proofread_y, 0)
        buffdetail.flag.transform.localPosition = Vector3(buffdetail.flag.transform.localPosition.x, flag_local_y, 0)
    else
        buffdetail.transform.position = Vector3(buffdetail.transform.position.x, click_pos.y - flag_local_y * 2 + proofread_y, 0)
        buffdetail.transform.localPosition = Vector3(algin_x, buffdetail.transform.localPosition.y, 0)
        buffdetail.flag.transform.position = Vector3(click_pos.x, click_pos.y + proofread_y, 0)
        buffdetail.flag.transform.localPosition = Vector3(buffdetail.flag.transform.localPosition.x, flag_local_y, 0)
    end

    buffdetail.transform.localScale = Vector3(1, 0.05, 1)
    buffdetail:SetActive(true)
    buffdetail.transform:DOScale(Vector3.one, animate_time)
end

function roleinfo_details:PickBackBuffDetails()
    self.view.buffdetail:SetActive(false)
end

return roleinfo_details;
