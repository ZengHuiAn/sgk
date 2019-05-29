

local View = {}



function View:Start()
    self.view = SGK.UIReference.Setup(self.gameObject);

    self.questItem = {}

    self:UpdateQuestList()
    self:UpdateCityContructInfo()
end

local function UpdateImage(view, item, showHave)
    if not view then
        return;
    end

    if item.type == 0 then
        view:SetActive(false);
        return;
    end

    local info = utils.ItemHelper.Get(item.type, item.id, item.value)
    view[UnityEngine.UI.Image]:LoadSprite("icon/" .. info.icon);

    view.Count[UnityEngine.UI.Text].text = showHave and string.format("%d/%d", info.count, item.value) or string.format("%d", item.value)
end

function View:UpdateQuestList()
    local prefab = self.view.ScrollView.Viewport.Content[1].gameObject;
    local parent = self.view.ScrollView.Viewport.Content.gameObject.transform;

    local quests = module.QuestModule.GetList()
    for uuid, view in pairs(self.questItem) do
        if not quests[uuid] or quests[uuid].status ~= 0 then
            self.questItem[uuid] = nil;
            UnityEngine.GameObject.Destroy(view.gameObject);
        end
    end

    local info = module.QuestModule.CityContuctInfo();
    local richReward = (info.today_count <= 20);

    for _, v in pairs(quests) do
        if v.type == 1 and v.status == 0 then
            local view = self.questItem[v.uuid]
            if not view then
                view = SGK.UIReference.Setup(UnityEngine.GameObject.Instantiate(prefab, parent));
                view:SetActive(true);
                self.questItem[v.uuid] = view;
            end

            view.Title[UnityEngine.UI.Text].text = v.name .. "(" .. v.status .. ")";
            view.Desc[UnityEngine.UI.Text].text = v.desc;

            local consumes = {
                {type = v.consume_type1, id = v.consume_id1, value = v.consume_value1},
                {type = v.consume_type2, id = v.consume_id2, value = v.consume_value2},
            }

            local rewards = {
                {type = v.reward_type1, id = v.reward_id1, value = richReward and v.reward_richvalue1 or v.reward_value1},
                {type = v.reward_type2, id = v.reward_id2, value = richReward and v.reward_richvalue2 or v.reward_value2},
                {type = v.reward_type3, id = v.reward_id3, value = richReward and v.reward_richvalue3 or v.reward_value3},
            }

            for k, consume in ipairs(consumes) do
                UpdateImage(view.Consumes[k], consume, true)
            end

            for k, reward in ipairs(rewards) do
                UpdateImage(view.Rewards[k], reward, false)
            end
        end
    end
end


function View:UpdateCityContructInfo()
    local info = module.QuestModule.CityContuctInfo();
    self.view.CCInfo:TextFormat("进度 {0}/10, 已完成数量 {1}", info.round_index, info.today_count);
end

function View:listEvent()
    return {
        "QUEST_INFO_CHANGE",
        "CITY_CONTRUCT_INFO_CHANGE",
    }
end

function View:onEvent(event, ...)
    if event == "QUEST_INFO_CHANGE" then
        self:UpdateQuestList();
    elseif event == "CITY_CONTRUCT_INFO_CHANGE" then
        self:UpdateCityContructInfo();
    end
end



return View;