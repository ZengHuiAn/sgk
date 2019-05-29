DispatchEvent("Player_login_CHANGE",{test = "test"})
local _quest = module.QuestModule.Get(100103)
if module.playerModule.Get().honor == 9999 then
    SceneStack.EnterMap(900,nil,true);--遁入幻境
-- elseif not _quest or _quest.status == 0 then
--     SceneStack.EnterMap(29,nil,true);
else
    if module.QuestModule.Get(10004) and module.QuestModule.Get(10004).status == 1 then
        SceneStack.EnterMap(1,nil,true);
        do return end
        --0 未完成   1 完成  2  取消
        local quest_table = {
            -- {100006,29},--真陵学园 绝密影像
            -- {100081,52},--沙漠神陵 与肖斯塔娅聊聊
            -- {101051,29},--真陵学园 游戏设备
            -- {26011,10},--双子悬门 玉棺之礼
            --{100006,29},--真陵学园 绝密影像
            --{100081,1},--沙漠神陵 与肖斯塔娅聊聊
            --{101051,29},--真陵学园 游戏设备
            {26011,1},--双子悬门 玉棺之礼
        }
        for _,v in ipairs(quest_table) do
            local quest = module.QuestModule.Get(v[1])
            --print("-----------------11",quest.id,quest.status,quest.name)
            if not quest or quest.status == 0 then
                SceneStack.EnterMap(v[2],nil,true)
                return
            end
        end
        local openLevel = require "config.openLevel"
        if openLevel.GetStatus(2001) then
            --SceneStack.EnterMap(26,nil,true);--（之前是26号基地）
            SceneStack.EnterMap(1,nil,true);--开启基地后，也是回到家里
        else
            local _mapid,_x,_y,_z = module.MapModule.GetiMapid()
            if not _mapid then
                --_mapid = 10--（之前是10号双子悬门）
                _mapid = 1--特殊情况就回到家里
            end
            SceneStack.EnterMap(_mapid,nil,true);
        end
    else
        module.fightModule.SetNowSelectChapter({chapterId=1010, idx = 1, difficultyIdx = 1, chapterNum = 1})
        SceneStack.Push("newSelectMapUp")
    end
end
