local singbar_details = {}

local Screen_width = 0
local detail_width = 0
local proofread = 25
local x_while_left = 0
local x_while_right = 0

local type_desc_list = {
    [1] = "受到普通攻击时本回合吟唱的效率减半\n受到眩晕、沉默等控制技能时会被打断吟唱",
    [2] = "受到普通攻击时不会降低吟唱的效率\n受到眩晕、沉默等控制技能时会被打断吟唱",
    [3] = "受到普通攻击时本回合吟唱的效率减半\n受到眩晕、沉默等控制技能时不会被打断吟唱",
    [4] = "受到普通攻击时不会降低吟唱的效率\n受到眩晕、沉默等控制技能时不会被打断吟唱",
}

function singbar_details:Start()
    self.view = SGK.UIReference.Setup(self.gameObject)
    self.view:SetActive(false)
    Screen_width = UnityEngine.Screen.width
    detail_width = self.view[UnityEngine.RectTransform].rect.width
    
    x_while_left = -(Screen_width/2 - detail_width/2) + proofread
    x_while_right = (Screen_width/2 - detail_width/2) - proofread
end

function singbar_details:UpdatePos(click_pos, info)
    if type(info) ~= "table" then
        return
    end

    self.view.processinfo.skillname[UnityEngine.UI.Text].text = info.name
    self.view.processinfo.process[UnityEngine.UI.Text].text = string.format( "吟唱进度：%s/%s （<color=#3bffbc>+%s</color>）", info.current, info.total, info.next)
    self.view.typeinfo.typeimage[CS.UGUISpriteSelector].index = info.type - 1
    self.view.typeinfo.desc[UnityEngine.UI.Text].text = type_desc_list[info.type]

    local algin_x = 0

    if click_pos.x < detail_width/2 + proofread then
        algin_x = x_while_left
    elseif (Screen_width - click_pos.x) < detail_width/2 + proofread then
        algin_x = x_while_right
    end

    local flag_local_y = self.view.flag.transform.localPosition.y
    if algin_x == 0 then
        self.view.transform.position = Vector3(click_pos.x, click_pos.y - flag_local_y * 2, 0)
        self.view.flag.transform.position = Vector3(click_pos.x, flag_local_y, 0)
        self.view.flag.transform.localPosition = Vector3(self.view.flag.transform.localPosition.x, flag_local_y, 0)
    else
        self.view.transform.position = Vector3(self.view.transform.position.x, click_pos.y - flag_local_y * 2, 0)
        self.view.transform.localPosition = Vector3(algin_x, self.view.transform.localPosition.y, 0)
        self.view.flag.transform.position = Vector3(click_pos.x, click_pos.y, 0)
        self.view.flag.transform.localPosition = Vector3(self.view.flag.transform.localPosition.x, flag_local_y, 0)
    end

    self.view:SetActive(true)
    self.view.transform:DOScale(Vector3.one, 0.2)
end
 
function singbar_details:PickBack()
    self.view.transform:DOScale(Vector3(1, 0.05, 1), 0.2):OnComplete(function ()
        self.view:SetActive(false)
    end)
end

return singbar_details;