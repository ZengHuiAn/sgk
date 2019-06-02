local DataBoxModule = require "module.DataBoxModule"
local QuestModule = require "module.QuestModule"
local ItemHelper = require "utils.ItemHelper"
local View = {};
function View:Start(data)
    self.root = CS.SGK.UIReference.Setup(self.gameObject);
    self.view = self.root.view;
    self.dialog = self.root.dialog;
    self.content = self.view.left.ScrollView.Viewport.Content;
    self.cur_chatper = 1;
    self.cur_stage = 1;
	self:InitData();
	self:InitView();
end

function View:InitData()
    self.chatper_UI = {};
    self.stage_UI = {};
    self.item_UI = {};
    self.memoryData = {};
    self.stageConfig = DataBoxModule.GetStageConfig();
    for chatper_id,v in ipairs(self.stageConfig) do
        local chatperData = {};
        chatperData.quest_count = 0;
        chatperData.finish_count = 0;
        chatperData.stageData = {}
        for stage_id,j in ipairs(v) do
            local stageData = {};
            stageData.quest_count = 0;
            stageData.finish_count = 0;
            stageData.reward = {};
            local quests = QuestModule.GetQuestConfigByMemory(chatper_id, stage_id);
            for _,k in ipairs(quests) do
                local quest = QuestModule.Get(k.id);
                local finish = false;
                if quest and quest.status == 1 then
                    stageData.finish_count =  stageData.finish_count + 1;
                    finish = true;
                end
                for _,item in ipairs(k.reward) do
                    if item.id ~= 90000 and item.id ~= 90002 and item.id ~= 199999 then
                        table.insert(stageData.reward, {type = item.type, id = item.id, value = item.value, get = finish})
                    end
                end
                stageData.quest_count =  stageData.quest_count + 1;
            end
            chatperData.quest_count = stageData.quest_count + chatperData.quest_count;
            chatperData.finish_count = stageData.finish_count + chatperData.finish_count;
            chatperData.stageData[stage_id] = stageData;
        end
        self.memoryData[chatper_id] = chatperData;
    end
end

function View:InitView()
	for chatper_id,v in ipairs(self.memoryData) do
        local obj = UnityEngine.Object.Instantiate(self.content.chapter.gameObject, self.content.gameObject.transform);
        local chatper_view  = CS.SGK.UIReference.Setup(obj);
        local chatper_cfg = DataBoxModule.GetChapterConfig(chatper_id);
        chatper_view.Toggle.Label[UnityEngine.UI.Text].text = chatper_cfg.chapter_des;
        chatper_view.Toggle.Slider[UnityEngine.UI.Slider].value = v.finish_count/v.quest_count;
        chatper_view.Toggle.num[UnityEngine.UI.Text].text = math.floor(v.finish_count/v.quest_count*100).."%";
        if chatper_cfg.depend_item_id ~= 0 and module.ItemModule.GetItemCount(chatper_cfg.depend_item_id) == 0 then
            chatper_view.Toggle[CS.UnityEngine.UI.Toggle].interactable = false;
        else
            chatper_view.Toggle[CS.UnityEngine.UI.Toggle].interactable = true;
        end
        chatper_view.Toggle[CS.UnityEngine.UI.Toggle].onValueChanged:AddListener(function ( value )
            if value then
                chatper_view.Toggle.arrow.transform:DOLocalRotate(Vector3(0,0,-90),0.25);
                if self.stage_UI[chatper_id] == nil then
                    self.stage_UI[chatper_id] = {};
                    for stage_id,k in ipairs(v.stageData) do
                        local stage_cfg = DataBoxModule.GetStageConfig(chatper_id, stage_id);
                        local obj2 = UnityEngine.Object.Instantiate(chatper_view.titles.title.gameObject, chatper_view.titles.gameObject.transform);
                        local stage_view = CS.SGK.UIReference.Setup(obj2);
                        stage_view.name[UnityEngine.UI.Text].text = stage_cfg.stage_des;
                        stage_view.num[UnityEngine.UI.Text]:TextFormat("({0}/{1})", k.finish_count, k.quest_count);
                        stage_view:SetActive(true);
                        CS.UGUIClickEventListener.Get(stage_view.gameObject).onClick = function (obj)        
                            self:SelectStage(chatper_id, stage_id)
                        end
                        self.stage_UI[chatper_id][stage_id] = stage_view;
                    end
                end
                chatper_view.titles:SetActive(true);
            else
                chatper_view.Toggle.arrow.transform:DOLocalRotate(Vector3(0,0,-180),0.25);
                chatper_view.titles:SetActive(false);
            end
        end)

        if self.cur_chatper == chatper_id then
            chatper_view.Toggle[CS.UnityEngine.UI.Toggle].isOn = true;
        end
        chatper_view:SetActive(true);
        self.chatper_UI[chatper_id] = chatper_view;;
    end
    CS.UGUIClickEventListener.Get(self.view.title.close.gameObject).onClick = function (obj)        
        DialogStack.Pop();
    end
    CS.UGUIClickEventListener.Get(self.root.BG.gameObject, true).onClick = function (obj)        
        DialogStack.Pop();
    end
    CS.UGUIClickEventListener.Get(self.dialog.reward.confirm.gameObject, true).onClick = function (obj)   
        if self.memoryData[self.cur_chatper].quest_count == self.memoryData[self.cur_chatper].finish_count then
            
        else
            showDlgError(nil, "完成本章节所有任务后才能领取")
        end
    end
    self:SelectStage(self.cur_chatper, self.cur_stage)
end


function View:SelectStage(chatper_id, stage_id)
    print("选择", chatper_id, stage_id)
    self.cur_chatper = chatper_id;
    self.cur_stage = stage_id;
    local chatper_cfg = DataBoxModule.GetChapterConfig(chatper_id);
    local stage_cfg = DataBoxModule.GetStageConfig(chatper_id, stage_id);
    local view = self.view.right;
    view.top.Text[UnityEngine.UI.Text].text = chatper_cfg.chapter_des;
    view.des.Image.Text[UnityEngine.UI.Text].text = stage_cfg.stage_des;
    view.des.Text[UnityEngine.UI.Text].text = stage_cfg.backdrop_des;
    if stage_cfg.consume_id ~= 0 then
        view.go.icon[UnityEngine.UI.Image]:LoadSprite("icon/"..stage_cfg.consume_id.."_small")
        view.go.count[UnityEngine.UI.Text].text = "x"..stage_cfg.consume_value;
    end
    for i,v in ipairs(self.item_UI) do
        v:SetActive(false);
    end
    for i,v in ipairs(self.memoryData[chatper_id].stageData[stage_id].reward) do
        local item = nil;
        if self.item_UI[i] then
            item = self.item_UI[i]
        else
            local obj = UnityEngine.Object.Instantiate(view.reward.items.item.gameObject, view.reward.items.gameObject.transform);
            item = CS.SGK.UIReference.Setup(obj);
            self.item_UI[i] = item;
        end
        utils.IconFrameHelper.Create(item.IconFrame,{type = v.type, id = v.id, count = v.value, showDetail = true})
        item.select:SetActive(v.get);
        item:SetActive(true);
    end
    CS.UGUIClickEventListener.Get(view.top.Image.gameObject).onClick = function (obj)        
        self:ShowChapterReward(chatper_cfg);
    end
    CS.UGUIClickEventListener.Get(view.go.gameObject).onClick = function (obj)        
        self:StartReview(stage_cfg)
    end

end

function View:ShowChapterReward(chatper_cfg)
    for i=1,5 do
        if chatper_cfg["reward_id"..i] ~= 0 then
            local cfg = ItemHelper.Get(chatper_cfg["reward_type"..i], chatper_cfg["reward_id"..i]);
            self.dialog.reward.items["item"..i].Text[UnityEngine.UI.Text].text = cfg.name;
            utils.IconFrameHelper.Create(self.dialog.reward.items["item"..i].IconFrame,{type = chatper_cfg["reward_type"..i], id = chatper_cfg["reward_id"..i], count = chatper_cfg["reward_value"..i], showDetail = true})
            self.dialog.reward.items["item"..i]:SetActive(true);
        else
            self.dialog.reward.items["item"..i]:SetActive(false);
        end
    end
    self.dialog.reward:SetActive(true);
end

function View:StartReview(stage_cfg)
    print("开始回忆", stage_cfg.quest_id);
    if module.ItemModule.GetItemCount(stage_cfg.consume_id) < stage_cfg.consume_value then
        showDlgError(nil, "物品不足")
        return;
    end
end

function View:listEvent()
	return {
		"",
	}
end

function View:onEvent(event, ...)
	print("onEvent", event, ...);
	if event == ""  then

	end
end

return View;