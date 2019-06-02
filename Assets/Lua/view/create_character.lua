local PlayerModule = require "module.playerModule";
local NetworkService = require "utils.NetworkService";
local NameCfg = require "config.nameConfig"
local TipCfg = require "config.TipConfig"
local UserDefault = require "utils.UserDefault";
require "WordFilter"

local View = {};

function View:Start()
    if not PlayerModule.Get() then
        LoadStory(10100101,function ()
            NetworkService.Send(7, {nil, "<SGK>"..PlayerModule.GetSelfID().."</SGK>", 11000})
        end)
        DispatchEvent("START_CREATE_STORY")
    end
end

function View:listEvent()
    return {
        "server_respond_8",
        "KEYDOWN_ESCAPE",
    }
end
function View:onEvent(event, ...)
    if event == "server_respond_8" then
        local data = select(2, ...)
        local result = data[2];
        print("result",result)
        if result == 0 then
            module.HeroModule.GetManager():GetAll(true)
            SceneStack.ClearBattleToggleScene()
            module.QuestModule.QueryQuestList(true)

            module.fightModule.SetNowSelectChapter({chapterId=1010, idx = 1, difficultyIdx = 1, chapterNum = 1})
            --SceneStack.Push("newSelectMapUp")
            DispatchEvent("NEW_PALYER_STORY_OVER")
        elseif result == 52 then
            self.clickFlag = true
            self.view.createCharacterView.createCharacterRoot.right.enterGame[UI.Image].material = nil
            showDlgError(nil, "角色名称已经被使用")
        elseif result == 281 then
            self.clickFlag = true
            self.view.createCharacterView.createCharacterRoot.right.enterGame[UI.Image].material = nil
            showDlgError(nil, "无法使用该角色名称")
        else
            self.clickFlag = true
            self.view.createCharacterView.createCharacterRoot.right.enterGame[UI.Image].material = nil
            showDlgError(nil, "创建角色失败")
        end
    elseif event == "KEYDOWN_ESCAPE" then
        DialogStack.Pop()
    end
end

return View;
