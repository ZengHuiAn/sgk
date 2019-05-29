local npcConfig = require "config.npcConfig"
local QuestModule = require "module.QuestModule"
local DataBoxModule = require "module.DataBoxModule"
local ItemHelper = require "utils.ItemHelper"
local ParameterConf = require "config.ParameterShowInfo";
local UserDefault = require "utils.UserDefault"

local User_DataBox = UserDefault.Load("User_DataBox", true);
local View = {};
function View:Start(data)
	self.root = CS.SGK.UIReference.Setup(self.gameObject);
    self.view = self.root.view;
	self:InitData();
	self:InitView();
end

function View:InitData()
    self.consortia_id = self.savedValues.consortia_id or 0;
    self.consortiaConfig = DataBoxModule.GetConsortiaConfig();
end

function View:InitView()
    DialogStack.PushPref("CurrencyChat", nil, self.root.dialog);
    for i=1,6 do
        local view = self.view.all["union"..i];
        local cfg = self.consortiaConfig[i];
        if cfg then
            view.Image[CS.UGUISpriteSelector].index = cfg.des_id - 1;
            local quest_count, finish_count = 0,0;
            for j=1,6 do
                if cfg["bigclue_quest"..j] ~= 0 then
                    quest_count = quest_count + 1;
                    if self:IsQuestFinish(cfg["bigclue_quest"..j]) then
                        finish_count = finish_count + 1;
                    end
                end
            end
            view.Slider[UnityEngine.UI.Slider].value = finish_count / quest_count;
            view.Slider.num[UnityEngine.UI.Text].text = math.ceil(finish_count / quest_count * 100).."%";
            CS.UGUIClickEventListener.Get(view.Image.gameObject).onClick = function ( object )
                self.consortia_id = i;
                -- view.new:SetActive(module.RedDotModule.CheckModlue:checkUnionData(i, true));
                DialogStack.PushPrefStact("dataBox/UnionData", {consortia_id = self.consortia_id});
            end
        else
            view.Slider:SetActive(false);
            view.Image:SetActive(false);
        end
    end
    self:CheckRedPoint();
end

function View:CheckRedPoint()
    for i=1,6 do
        local view = self.view.all["union"..i];
        if module.RedDotModule.CheckModlue:checkUnionData(i) then
            view.new:SetActive(true);
            view.new[CS.DG.Tweening.DOTweenAnimation]:DOPlay();
        else
            view.new:SetActive(false)
        end
    end
end

function View:IsQuestFinish(quest_id)
    local quest = QuestModule.Get(quest_id);
    if quest then
        if quest.status == 1 then
            return true;
        else
            print("任务未完成", quest_id, QuestModule.CanSubmit(quest_id))
        end
    else
        print("任务不存在", quest_id)
    end
    return false;
end

function View:listEvent()
	return {
        "QUEST_INFO_CHANGE",
        "PrefStact_POP",
	}
end

function View:onEvent(event, ...)
	print("onEvent", event, ...);
	if event == "QUEST_INFO_CHANGE" or event == "PrefStact_POP" then
        self:CheckRedPoint();
	end
end

return View;