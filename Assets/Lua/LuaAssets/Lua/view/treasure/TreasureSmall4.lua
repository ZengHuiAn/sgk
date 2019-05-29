local View = {}

function View:update()
    if not self.character then
        return;
    end
end

function View:Start(data )
    -- Minimap
    self.view = CS.SGK.UIReference.Setup(self.gameObject)
    -- GetTopic

    
    self:InitOpera();

    self.answerLength = 0
end

function View:InitOpera( ... )
    self.topic = module.TreasureMapModule.GetTopic();
    for i=1,5 do
        self.view.Topic["opt"..i]:SetActive(self.topic["opera"..i] ~= "");
        self.view.Topic["opt"..i][UI.Text].text = self.topic["opera"..i]
    end

    UI.LayoutRebuilder.ForceRebuildLayoutImmediate(self.view.Topic[UnityEngine.RectTransform])
end

function View:InitAnwser( data )

    self.answerLength = 0
    self.array = module.TreasureMapModule.GetAnswer() or {}
    for i=1,4 do
        local value  = self.array[i]

        self.view.Topic["answer"..i].bg.num[UI.Image].enabled = value    
        if value and value.value then
            self.answerLength = self.answerLength +1

            -- print(sprinttb(value))
            self.view.Topic["answer"..i].bg.num[CS.UGUISpriteSelector].index = value.value - 1 
        else
            self.answerLength = self.answerLength -1
        end
    end
    self:CheckAnswer();

end

function View:CheckAnswer(  )
    
    if self.answerLength == 4 then
        module.TreasureMapModule.ClearAnswer()
        local str = ""
        for i=1,4 do
            str = str .. self.topic["opera"..i] ..self.array[i].value
        end 
        str = " return "..str ..self.topic["opera"..5];
        -- print(str)
        local func = loadstring(str)
        print(str)
        local result = func()
        
        if tonumber(result) == 24 then

            DispatchEvent("LOCAL_TREASURE_SMALL_SUCCESS");
            -- print("你答对了")
            DialogStack.Pop();
            
        else
            self.answerLength = 0
            -- module.TreasureMapModule.ExitSmallGame();
            self.topic = module.TreasureMapModule.GetTopic(true)
            module.TreasureMapModule.FlySmallGame(true)
            DispatchEvent("LOACAL_SMALL4_RESTART")
            module.TreasureMapModule.ClearAnswer()
            self.array = {}
            self:InitOpera()
            self:InitAnwser();
        end
    end
end


function View:onEvent(event,data)
    if event == "LOCAL_TREASURE_ANSWER" then
        self:InitOpera()
        self:InitAnwser(data)
    elseif event == "MOVE_TO_SMALL_GAME" then
        self:Start()
    end
end

function View:listEvent()
	return{
        "LOCAL_TREASURE_ANSWER",
        "MOVE_TO_SMALL_GAME",
	}
end

return View