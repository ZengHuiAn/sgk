local battleInstructionsConfig = require "config.battleInstructionsConfig"


local View= {}

function View:Start(data)
    self.id = data and data.id or 1;
    self.func = data and data.func;
    self.view = CS.SGK.UIReference.Setup(self.gameObject)
    self.Instructions = battleInstructionsConfig.getConfig(self.id)
    self.view.root.button.previousBtn:SetActive(false)
    self.InstructionsList = {}
    if self.Instructions then
        --self.InstructionsList.insert(self.Instructions)
        table.insert(self.InstructionsList,self.Instructions)
    end

    local des = data and data.des or ""
    if des ~= "" and des ~= "0" then
        self.view.root.guide.info[UI.Text].text = des;
        self.view.root.guide.transform.localScale = Vector3(1, 0, 1);
        self.view.root.guide.transform:DOScale(Vector3.one, 0.2):SetEase(CS.DG.Tweening.Ease.OutBack):SetDelay(0.1);
        self.view.root.guide:SetActive(true);
    end
    self:initUi()
end
function View:initUi()
   -- ERROR_LOG("ding=============>>>1",sprinttb(battleInstructionsConfig.getConfig()))
   -- ERROR_LOG("ding=============>>>1",sprinttb(battleInstructionsConfig.getConfig(self.id)))
    if  self.Instructions then
       self.view.root.bg.label.Text[UI.Text].text=self.Instructions.name
       self.view.root.describe.Image[UI.Image]:LoadSprite("icon/battleInstructions/" .. self.Instructions.picture)
       if self.Instructions.next_id ==0 then
          self.view.root.button.NextBtn:SetActive(false)
          self.view.root.button.closeBtn:SetActive(true)
       end
    else
        return
    end
    self:botButton()
end
function View:botButton()
    CS.UGUIClickEventListener.Get(self.view.root.button.NextBtn.btn.gameObject).onClick=function()
        if self.Instructions then
            if self.Instructions.next_id ~=0 then
                self.Instructions=battleInstructionsConfig.getConfig(self.Instructions.next_id)
                self:initUi() 
                self.view.root.button.previousBtn:SetActive(true)
                local isHave = false
                for i,v in ipairs(self.InstructionsList) do
                    --ERROR_LOG("ding========tab",sprinttb(v))
                    if v == self.Instructions then
                        isHave=true
                    end
                end
                if isHave ~= true then
                    table.insert(self.InstructionsList,self.Instructions)
                end
            end
        end
    end
    CS.UGUIClickEventListener.Get(self.view.root.button.previousBtn.btn.gameObject).onClick=function ()
        for i,v in ipairs(self.InstructionsList) do
            if v== self.Instructions then
                self.index = i-1
            end
        end
        if self.index ~=0  then
            self.Instructions=self.InstructionsList[self.index]  
        end
        if self.index-1==0 then
            self.view.root.button.previousBtn:SetActive(false)
        end
        self.view.root.button.closeBtn:SetActive(false)
        self.view.root.button.NextBtn:SetActive(true )
        self:initUi()
    end
    CS.UGUIClickEventListener.Get(self.view.root.button.closeBtn.btn.gameObject).onClick=function ()
        if self.func then
            self.func();
        end
        CS.UnityEngine.GameObject.Destroy(self.gameObject)
    end
    
end

return View;