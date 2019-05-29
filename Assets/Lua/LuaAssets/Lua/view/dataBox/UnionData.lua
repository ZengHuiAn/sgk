local npcConfig = require "config.npcConfig"
local QuestModule = require "module.QuestModule"
local DataBoxModule = require "module.DataBoxModule"
local ItemHelper = require "utils.ItemHelper"
local ParameterConf = require "config.ParameterShowInfo";
local UserDefault = require "utils.UserDefault"
local HeroBuffModule = require "hero.HeroBuffModule"
local MapConfig = require "config.MapConfig"

local User_DataBox = UserDefault.Load("User_DataBox", true);
local View = {};
function View:Start(data)
	self.root = CS.SGK.UIReference.Setup(self.gameObject);
    self.view = self.root.view;
    self.consortia_id = data and data.consortia_id or self.savedValues.consortia_id or 0;
	self:InitData();
	self:InitView();
end

function View:InitData()
    self.type = self.savedValues.type or 1;
    self.des_UI = {};
    self.icon_UI = {};
    self.consortiaConfig = DataBoxModule.GetConsortiaConfig();
    self.npcCfg = npcConfig.GetnpcList();
    local biographyCfg = DataBoxModule.GetBiographyConfig();
    self.member = {}
    for k,v in pairs(biographyCfg) do
        if v.consortia ~= 0 then
            self.member[v.consortia] = self.member[v.consortia] or {};
            table.insert(self.member[v.consortia], v);
        end
    end
end

function View:InitView()
    CS.UGUIClickEventListener.Get(self.root.BG.gameObject).onClick = function ( object )
        DialogStack.Pop()
   	end
    CS.UGUIClickEventListener.Get(self.view.title.close.gameObject).onClick = function ( object )
        DialogStack.Pop()
    end
    CS.UGUIClickEventListener.Get(self.view.info.top.help.gameObject).onClick = function ( object )
        utils.SGKTools.ShowDlgHelp(SGK.Localize:getInstance():getValue("daotuanziliao_shuoming"), nil, self.root.dialog)
    end
    for i=1,2 do
        local toggle = self.view.info.top["Toggle"..i];
        CS.UGUIClickEventListener.Get(toggle.gameObject, true).onClick = function ( object )
            self.type = i;
            self:UpdateView();
        end
    end
    CS.UGUIClickEventListener.Get(self.view.info.middle.left.gameObject).onClick = function ( object )
        if self.consortia_id > 1 then
            self.consortia_id = self.consortia_id - 1;
            self:MoveContent(1);
            self:UpdateReward();
        end
    end
    CS.UGUIClickEventListener.Get(self.view.info.middle.right.gameObject).onClick = function ( object )
        if self.consortia_id < 6 then
            self.consortia_id = self.consortia_id + 1;
            self:MoveContent(-1);
            self:UpdateReward();
        end
    end
    self:UpdateView();
    self:UpdateReward();
end

function View:UpdateView()
    self.view.info.middle.ScrollView1:SetActive(self.type == 1);
    self.view.info.middle.ScrollView2:SetActive(self.type == 2);
    self.view.info.middle.left:SetActive(self.consortia_id > 1);
    self.view.info.middle.right:SetActive(self.consortia_id < 6);
    local cfg = self.consortiaConfig[self.consortia_id];
    self.view.title.name[UnityEngine.UI.Text].text = SGK.Localize:getInstance():getValue("daotuanziliao_0"..cfg.des_id)
    local des_cfg = DataBoxModule.GetConsortiaDesConfig(cfg.des_id);
    self.view.info.top["Toggle"..self.type][UnityEngine.UI.Toggle].isOn = true;
    if self.type == 1 then
        local content =  self.view.info.middle.ScrollView1.Viewport.Content;
        for i=1,6 do
            local item = nil;
            if self.des_UI[i] == nil then
                local obj = UnityEngine.Object.Instantiate(content.clue.gameObject, content.gameObject.transform);
                item = CS.SGK.UIReference.Setup(obj);     
                self.des_UI[i] = item;
            else
                item = self.des_UI[i];
            end
            if cfg["bigclue_quest"..i] ~= 0 then
                if self:IsQuestFinish(cfg["bigclue_quest"..i]) then
                    item.Image:SetActive(true);
                    item.Text:SetActive(false);
                    item.content:SetActive(true);
                    item.content[UnityEngine.UI.Text].text = des_cfg["clue_des"..i];
                    if User_DataBox.data[cfg["bigclue_quest"..i]] ~= 1 then
                        item.new:SetActive(true);
                        User_DataBox.data[cfg["bigclue_quest"..i]] = 1;
                    else
                        item.new:SetActive(false);
                    end
                else
                    item.Image:SetActive(false);
                    item.Text:SetActive(true);
                    item.content:SetActive(false);
                    item.new:SetActive(false);
                    item.Text[UnityEngine.UI.Text].text = des_cfg["depend_des"..i];
                    local quest = QuestModule.Get(cfg["bigclue_quest"..i]);
                    if quest then
                        CS.UGUIClickEventListener.Get(item.gameObject).onClick = function ( object )
                            local map_cfg = MapConfig.GetMapConf(quest.relation_value)
                            if map_cfg then
                                showDlg(nil,"是否前往"..map_cfg.map_name.."？",function()
                                    QuestModule.StartQuestGuideScript(quest);
                                end,function ( ... )
                                end)
                            end
                        end
                    end
                end
                item:SetActive(true);
            else
                item:SetActive(false);
            end
        end
    elseif self.type == 2 then
        local content =  self.view.info.middle.ScrollView2.Viewport.Content;
        local member = self.member[self.consortia_id] or {};
        for i,v in ipairs(self.icon_UI) do
            v:SetActive(false);
        end
        for i,v in ipairs(member) do
            local item = nil;
            if self.icon_UI[i] == nil then
                local obj = UnityEngine.Object.Instantiate(content.icon.gameObject, content.gameObject.transform);
                item = CS.SGK.UIReference.Setup(obj);     
                self.icon_UI[i] = item;
            else
                item = self.icon_UI[i];
            end
            CS.UGUIClickEventListener.Get(item.gameObject).onClick = function ( object )
                self.savedValues.consortia_id = self.consortia_id;
                self.savedValues.type = self.type;
                DialogStack.PushPrefStact("dataBox/NpcData", {npc_id = v.npc_id});
            end
            local npcCfg = self.npcCfg[v.npc_id];
            item[CS.UnityEngine.UI.Image]:LoadSprite("icon/"..npcCfg.mode);
            item.Text[UnityEngine.UI.Text].text = npcCfg.name;

            local hero = module.HeroModule.GetManager():Get(v.npc_id);
            if hero then
                item[CS.UnityEngine.UI.Image].material = nil;
                item[CS.UGUIClickEventListener].interactable = true;
            else
                item[CS.UGUIClickEventListener].interactable = false;
            end
            item:SetActive(true);
        end
    end
end

function View:UpdateReward()
    local consortia_id = self.consortia_id == 0 and 1 or self.consortia_id;
    for i=1,3 do
        local cfg = self.consortiaConfig[self.consortia_id];
        if cfg == nil then
            ERROR_LOG("consortiaConfig not exist ", self.consortia_id)
            return;
        end
        local quest_id = cfg.reward_quest;
        if quest_id ~= 0 then
            if (not self:IsQuestFinish(quest_id, i)) or i == 3 then
                self.view.info.bottom.Text[UnityEngine.UI.Text].text = SGK.Localize:getInstance():getValue("daotuanziliaojiangli_0"..i);
                local quest_cfg = QuestModule.GetCfg(quest_id, i);
                if quest_cfg and quest_cfg.consume[1] then
                    local count = module.ItemModule.GetItemCount(quest_cfg.consume[1].id);
                    if count >= quest_cfg.consume[1].value then
                        self.view.info.bottom.num[UnityEngine.UI.Text]:TextFormat("{0}/{1}", count, quest_cfg.consume[1].value);
                    else
                        self.view.info.bottom.num[UnityEngine.UI.Text]:TextFormat("<color=#FF0000FF>{0}</color>/{1}", count, quest_cfg.consume[1].value);
                    end
                    if quest_cfg.reward[1].type == 93 then
                        local buffCfg = HeroBuffModule.GetBuffConfig(quest_cfg.reward[1].id)
                        self.view.info.bottom.icon:SetActive(true);
                        self.view.info.bottom.IconFrame:SetActive(false);
                        if buffCfg.hero_id ~= 0 then
                            self.view.info.bottom.icon[UnityEngine.UI.Image]:LoadSprite("icon/"..buffCfg.hero_id);
                        end
                        self.view.info.bottom.name[UnityEngine.UI.Text]:TextFormat("{0}<color=#8A4CC7FF>+{1}</color>", ParameterConf.Get(buffCfg.type).name, quest_cfg.reward[1].value * buffCfg.value);
                    else
                        self.view.info.bottom.icon:SetActive(false);
                        self.view.info.bottom.IconFrame:SetActive(true);
                        local itemCfg = ItemHelper.Get(quest_cfg.reward[1].type, quest_cfg.reward[1].id);
                        self.view.info.bottom.name[UnityEngine.UI.Text].text = itemCfg and itemCfg.name or "";
                        utils.IconFrameHelper.Create(self.view.info.bottom.IconFrame,{type = quest_cfg.reward[1].type, id = quest_cfg.reward[1].id, count = quest_cfg.reward[1].value})
                    end
                    self.view.info.bottom.fx_item_get:SetActive(QuestModule.CanSubmit(quest_id));
                    CS.UGUIClickEventListener.Get(self.view.info.bottom.IconFrame.gameObject).onClick = function ( object )
                        if self:IsQuestFinish(quest_id, i) then
                            showDlgError(nil, "奖励已领取")
                        elseif QuestModule.CanSubmit(quest_id) then
                            QuestModule.Submit(quest_id);
                        else
                            showDlgError(nil, "解锁线索数量不足");
                        end
                    end
                end
                self.view.info.bottom.get:SetActive(i == 3 and self:IsQuestFinish(quest_id, i));
                break;
            end
        end
    end
end

function View:MoveContent(direction)
    local content = nil;
    if self.view.info.middle.ScrollView1.activeSelf then
        content = self.view.info.middle.ScrollView1.Viewport.Content
    elseif self.view.info.middle.ScrollView2.activeSelf then
        content = self.view.info.middle.ScrollView2.Viewport.Content
    end
    content.transform:DOLocalMove(Vector3(650 * direction, 0, 0), 0.15):SetRelative(true):SetEase(CS.DG.Tweening.Ease.InQuad):OnComplete(function ()
        content[UnityEngine.RectTransform].anchoredPosition = UnityEngine.Vector2(650 * -direction,0);
        -- content.transform.localPosition 
        self:UpdateView();
        content.transform:DOLocalMove(Vector3(650 * direction, 0, 0), 0.15):SetRelative(true):SetEase(CS.DG.Tweening.Ease.OutQuad);
    end)
end

function View:GetQuestCondition(quest_id)
    local quest = QuestModule.GetCfg(quest_id);
    for i=1,2 do
        if quest.condition[i].type == 56 then
            local _quest = QuestModule.GetCfg(quest.condition[i].id);
            if _quest then
                local _type = "";
                if _quest.type == 10 then
                    _type = "主线-";
                elseif _quest.type == 11 then
                    _type = "支线-";
                elseif _quest.type == 12 then
                    _type = "庄园流言-";
                end
                return "完成<color=#FF0000FF>".._type.._quest.name.."</color>后解锁"
            end
        end
    end
    return ""
end

function View:IsQuestFinish(quest_id, stage)
    stage = stage or 1;
    if quest_id == 0 then
        return true;
    end
    local quest = QuestModule.Get(quest_id);
    if quest then
        -- print("任务状态", quest_id, quest.name, "阶段"..quest.stageFlag, quest.stage, QuestModule.CanSubmit(quest_id), sprinttb(quest.consume))
        if quest.status == 1 then
            return true;
        elseif quest.stageFlag > stage then
            return true;
        else
            -- print("任务未完成", quest_id, QuestModule.CanSubmit(quest_id))
        end
    else
        print("任务不存在", quest_id)
    end
    return false;
end

function View:listEvent()
	return {
		"QUEST_INFO_CHANGE",
	}
end

function View:onEvent(event, ...)
	print("onEvent", event, ...);
	if event == "QUEST_INFO_CHANGE"  then
        self:UpdateReward();
	end
end

return View;