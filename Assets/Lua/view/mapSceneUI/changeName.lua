local playerModule = require "module.playerModule"
local PlayerInfoHelper = require "utils.PlayerInfoHelper"
local ItemModule=require"module.ItemModule"
local TipCfg = require "config.TipConfig"
local changeName = {}

function changeName:Start(data)
    local idx=data and data.idx or 1
    local info=data and data.info or ""

    self.view = CS.SGK.UIReference.Setup(self.gameObject)
    -- self.placeholder = self.view.changeNameRoot.Content.InputField.Placeholder[UI.Text]
    -- --self.placeholder.text = playerModule.Get().name
    self:initBtn(idx,info)
end

function changeName:initBtn(idx,info)
    
    
    self.view.changeNameRoot.nameContent:SetActive(idx == 1)
    self.view.changeNameRoot.infoContent:SetActive(idx ~= 1)
    self.view.changeNameRoot.Tip.gameObject:SetActive(idx==1)


    if idx == 1 then
        self.inputText = self.view.changeNameRoot.nameContent.InputField[UI.InputField]
        self.view.changeNameRoot.Title[UI.Text].text = SGK.Localize:getInstance():getValue("biaoti_jueseming_01")
        self.view.changeNameRoot.nameContent.InputField[UI.InputField].characterLimit = 10
        self.view.changeNameRoot.nameContent.InputField[UI.InputField].text = playerModule.Get().name
        self.view.changeNameRoot.nameContent.InputField.Placeholder[UI.Text].text = "请输入角色名称"

        local _consume=utils.ItemHelper.Get(utils.ItemHelper.TYPE.ITEM,90006)
        self.view.changeNameRoot.Tip[UI.Text].text="改名消耗"
        self.view.changeNameRoot.Tip.Image[UI.Image]:LoadSprite("icon/".._consume.icon.."_small")
        self.view.changeNameRoot.Tip.Image.Text[UI.Text].text=tostring(100)


    else
        self.inputText = self.view.changeNameRoot.infoContent.InputField[UI.InputField]
        self.view.changeNameRoot.Title[UI.Text].text = SGK.Localize:getInstance():getValue("biaoti_gexingqianming_01")
        self.view.changeNameRoot.infoContent.InputField[UI.InputField].characterLimit = 80
        self.view.changeNameRoot.infoContent.InputField[UI.InputField].text = info
        self.view.changeNameRoot.infoContent.InputField.Placeholder[UI.Text].text = "输入新个性签名"

    end

    CS.UGUIClickEventListener.Get(self.view.changeNameRoot.Close.gameObject).onClick = function()
        if idx==1 then
            DialogStack.Pop()
        else
            if self.inputText.text ~= info then
                showDlg(self.view,TipCfg.GetAssistDescConfig(62003).info,
                    function ()
                        DialogStack.Pop()
                    end,
                    function ()

                    end,
                "退出","取消")
            else
                DialogStack.Pop()
            end
        end
    end
    
    CS.UGUIClickEventListener.Get(self.view.changeNameRoot.saveBtn.gameObject).onClick = function()
        if self.inputText.text == "" then
            showDlgError(nil, tostring(idx==1 and "请输入需要修改的用户名" or "请输入需要修改的个性签名"))
        else
            if self.inputText.text == playerModule.Get().name then
                showDlgError(nil, "已保存")
                DialogStack.Pop()
                return
            end
            local name,hit = WordFilter.check(self.inputText.text)
            if idx==1 then
                if hit then
                    showDlgError(nil,"无法使用这个用户名")
                elseif GetUtf8Len(self.inputText.text) < 4 or GetUtf8Len(self.inputText.text) > 12 then
                    showDlgError(nil, "请输入2~6个汉字或4~12个字母、数字")
                else
                    local _consume=utils.ItemHelper.Get(utils.ItemHelper.TYPE.ITEM,90006)
                    showDlg(nil, string.format("修改需要花费100%s,是否确认修改?",_consume.name), function()
                        if ItemModule.GetItemCount(_consume.id) >= 100 then
                           playerModule.ChangeName(self.inputText.text)
                        else
                            showDlgError(nil, string.format("%s不足",_consume.name))
                        end
                        end, function() end)
                end
            else
                if hit then
                    showDlgError(nil,"无法使用这个个性签名")
                elseif GetUtf8Len(self.inputText.text) > 80 then
                    showDlgError(nil,TipCfg.GetAssistDescConfig(62002).info)
                else
                    PlayerInfoHelper.ChangeDesc(self.inputText.text)
                    DialogStack.Pop()
                end
            end
        end
    end

    CS.UGUIClickEventListener.Get(self.view.mask.gameObject).onClick = function()
        if idx==1 then
            DialogStack.Pop()
        else
            if self.inputText.text ~= info then
                showDlg(self.view,TipCfg.GetAssistDescConfig(62003).info,
                    function ()
                        DialogStack.Pop()
                    end,
                    function ()

                    end,
                "退出","取消")
            else
                DialogStack.Pop()
            end
        end
    end
end

function changeName:listEvent()
    return {
        "LOCAL_PLAYERMODULE_NAMEORICON_CHANGE_OK",
        "LOCAL_PLAYERMODULE_NAMEORICON_CHANGE_ERROR",
    }
end

function changeName:onEvent(event, ...)
    if event == "LOCAL_PLAYERMODULE_NAMEORICON_CHANGE_OK" then
        showDlgError(nil, "修改成功")
        DialogStack.Pop()
    elseif event == "LOCAL_PLAYERMODULE_NAMEORICON_CHANGE_ERROR" then
        showDlgError(nil, "用户名已存在")
    end
end

return changeName
