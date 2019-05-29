
local View = {}


function View:Start()
    self.view  = self.view  or CS.SGK.UIReference.Setup(self.gameObject)
    self.image = self.image or self.view[CS.UnityEngine.UI.Image];

    self.view[CS.UGUISpriteNameSelector].enabled = false;
    self.view[CS.UGUIRandomSelector].enabled = false;

    self:UpdateImage();
end

function View:UpdateImage()
    if not self.image then
        return;
    end
    
    local image, text = self:ChooseLoadingImage();
    self.image.sprite = SGK.ResourcesManager.Load(image, typeof(CS.UnityEngine.Sprite));

    text = text or {};
    self.view.LeftText1[UnityEngine.UI.Text].text = text[1] or "";
    self.view.LeftText2[UnityEngine.UI.Text].text = text[2] or "";
    self.view.RightText1[UnityEngine.UI.Text].text = text[3] or "";
    self.view.RightText2[UnityEngine.UI.Text].text = text[4] or "";
    self.view.BottomText[UnityEngine.UI.Text].text = text[5] or "";
end

function View:OnEnable()
    self:UpdateImage();
end

local textCfg = {
    {},
    -- {"左边第一行1", "左边第二行1", "右边第一行1", "右边第二行1", "底部文字1"},
    {"10号关卡", "双子悬门", "", "", "双子悬门是一座浮空城市，动力源不明，但经常会出现双子悬门即将坠毁的谣言。"},--2
    {"双子竞技场", "", "", "", "双子悬门中最重要的建筑，整个神陵世界只此一家。"},--3
    {"35号关卡", "黄金矿脉", "", "", "盛产金苹果以及各类矿石，目前被【猎金盗团】统治。"},
    {"大殿内部", "", "", "", "十字要塞被铁墓攻略并改造成坚不可摧的基地，其团长铁墓真是游戏中最强的破亿五人之一。"},
    {"12号关卡", "古墓新港", "", "", "古墓新港是一座海港城市，由【凯撒盗团】攻略并统治，发展极为迅速。"},
    {"我为何", "压抑不住泪水？", "", "", "神陵科技副总陆游七被人枪杀，其中真相究竟为何？"},
    {"爷爷所说的敌人", "究竟是谁？", "", "", "这个老人竟然是我的爷爷……"},
    {"平和而强大的力量包裹着我，", "这是爷爷留给我的最后温暖。", "", "", "爷爷将最后的力量交给了我……"},--9
    {"", "", "", "", "陆怜，我一定会把你救回来！"},
    {"", "", "", "", "陆怜被危机笼罩，我该如何拯救她？"},
    {"", "", "", "", "陆怜已经与零号关卡紧密相连，我必须守护零号关卡！"},
    {"强大的力量从陆怜体内涌出，", "与这个世界联结成整体。", "", "", "陆怜你究竟有着怎样的身世？"},
    {"银背盗团", "玉棺下属盗团之一", "", "", "银背盗团在神陵世界中的名声极差，但由于玉棺的缘故无人敢惹。"},
}


function View:ChooseLoadingImage()
    if not module.playerModule.GetSelfID() then -- 角色未登陆
        return string.format("loading/loading_0%d.jpg", math.random(1,7)), textCfg[1]
    end

--[[    
    local quest_1 = module.QuestModule.Get(100021)
    local quest_2 = module.QuestModule.Get(100041) 
    local quest_3 = module.QuestModule.Get(101021) 
    local quest_4 = module.QuestModule.Get(101051) 
    local quest_5 = module.QuestModule.Get(101071)  
    local quest_6 = module.QuestModule.Get(102021)  
    local quest_7 = module.QuestModule.Get(102071)  
    local quest_8 = module.QuestModule.Get(102121)
    local quest_9 = module.QuestModule.Get(102131)
    
    if not quest_1 or quest_1.status ~= 1 then -- 某任务未完成
        return string.format("loading/loading_juqing_0%d.jpg", 5), textCfg[7]
    end

    if not quest_2 or quest_2.status ~= 1 then -- 某任务未完成
        return string.format("loading/loading_juqing_0%d.jpg", 5), textCfg[8]
    end

    if not quest_3 or quest_3.status ~= 1 then -- 某任务未完成
        return string.format("loading/loading_juqing_0%d.jpg", 6), textCfg[9]
    end

    if not quest_4 or quest_4.status ~= 1 then -- 某任务未完成
        return string.format("loading/loading_juqing_0%d.jpg", 1), textCfg[10]
    end

    if not quest_5 or quest_5.status ~= 1 then -- 某任务未完成
        return string.format("loading/loading_juqing_0%d.jpg", 3), textCfg[10]
    end

    if not quest_6 or quest_6.status ~= 1 then -- 某任务未完成
        return string.format("loading/loading_juqing_0%d.jpg", 2), textCfg[11]
    end

    if not quest_7 or quest_7.status ~= 1 then -- 某任务未完成
        return string.format("loading/loading_juqing_0%d.jpg", math.random(1,3)), textCfg[math.random(10, 11)]
    end

    if not quest_8 or quest_8.status ~= 1 then -- 某任务未完成
        return string.format("loading/loading_juqing_0%d.jpg", 4), textCfg[math.random(12, 13)]
    end

    if not quest_9 or quest_9.status ~= 1 then -- 某任务未完成
        return string.format("loading/loading_juqing_0%d.jpg", 9), textCfg[math.random(12, 13)]
    end

    if quest and quest.status == 1 then -- 某任务已完成
        return string.format("loading/loading_0%d.jpg", math.random(1,7)), textCfg[math.random(1, #textCfg)]
    end

    if quest_1 and quest_1.status == 0 then -- 拥有某任务但没有完成
        return string.format("loading/loading_0%d.jpg", math.random(1,7)), textCfg[math.random(1, #textCfg)]
    end

    if not quest or quest.status == 2 then -- 某任务未接
        return string.format("loading/loading_juqing_0%d.jpg", 5), textCfg[math.random(1, #textCfg)]
    end

    if not quest_3 or quest_3.status ~= 1 then -- 某任务未完成
        return string.format("loading/loading_juqing_0%d.jpg", math.random(1,3)), textCfg[math.random(1, #textCfg)]
    end

    if quest_4 and quest_4.status == 1 and not quest_5 or quest_5.status ~= 1 then -- 某任务未完成
        return string.format("loading/loading_juqing_0%d.jpg", 4), textCfg[math.random(1, #textCfg)]
    end
    ]]

    local nextSceneInfo = utils.SceneStack.GetNextSceneInfo();

    if nextSceneInfo and nextSceneInfo.scene_name == "battle" then -- 下一个场景是战斗
        return string.format("loading/loading_0%d.jpg", math.random(1,7)), textCfg[math.random(1)]
    end

    -- if nextSceneInfo and nextSceneInfo.map_id == 9 then -- 即将进入9号场景
    --     return string.format("loading/loading_juqing_%d.jpg", 14), textCfg[3]
    -- end

    -- if nextSceneInfo and nextSceneInfo.map_id == 10 then -- 即将进入10号场景
    --     return string.format("loading/loading_juqing_%d.jpg", 12), textCfg[2]
    -- end

    -- if nextSceneInfo and nextSceneInfo.map_id == 19 then -- 即将进入19号场景
    --     return string.format("loading/loading_juqing_%d.jpg", 10), textCfg[4]
    -- end

    -- if nextSceneInfo and nextSceneInfo.map_id == 37 then -- 即将进入37号场景
    --     return string.format("loading/loading_juqing_0%d.jpg", 8), textCfg[5]
    -- end

    -- if nextSceneInfo and nextSceneInfo.map_id == 30 then -- 即将进入30号场景
    --     return string.format("loading/loading_juqing_%d.jpg", 11), textCfg[6]
    -- end

    return string.format("loading/loading_0%d.jpg", math.random(1,7)), textCfg[math.random(1)]
end


return View;