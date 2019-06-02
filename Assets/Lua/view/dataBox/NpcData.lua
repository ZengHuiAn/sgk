local npcConfig = require "config.npcConfig"
local QuestModule = require "module.QuestModule"
local DataBoxModule = require "module.DataBoxModule"
local ItemHelper = require "utils.ItemHelper"
local ParameterConf = require "config.ParameterShowInfo";
local HeroBuffModule = require "hero.HeroBuffModule"
local UserDefault = require "utils.UserDefault"
local NpcChatMoudle = require "module.NpcChatMoudle"

local User_DataBox = UserDefault.Load("User_DataBox", true);
local View = {};
local NumToText = {
    [1] = "一",
    [2] = "二",
    [3] = "三",
}
function View:Start(data)
    self.root = CS.SGK.UIReference.Setup(self.gameObject);
    self.view =  self.root.view;
    if data and data.npc_id then
        self.pos = 1;
        self.npcFriendData = {{npc_id = data.npc_id}};
    elseif data and data.pos and data.npcFriendData then
        self.pos = data.pos;
        self.npcFriendData = data.npcFriendData;
    else
        ERROR_LOG("参数错误");
        DialogStack.Pop();
        return;
    end
    self.content = self.view.middle.ScrollView.Viewport.Content;
    self:InitData();
    self:InitView();
    module.RedDotModule.PlayRedAnim(self.view.middle.BtnBg.incident.tip)
    self:initGuide()
end

function View:initGuide()
    module.guideModule.PlayByType(133,0.2)
end

function View:InitData()
    self:UpdateData();
    self.biography_UI = {};
end

function View:UpdateData()
    self.npc_id = self.npcFriendData[self.pos].npc_id;
    --print("当前npc", self.npc_id)
    self.AllRoleCfg = module.HeroModule.GetConfig();
    self.npcCfg = npcConfig.GetnpcList()[self.npc_id];
    if not self.npcCfg then
        self.npcCfg = self.AllRoleCfg[self.npc_id]
    end
    self.npcFriend = npcConfig.GetNpcFriendList()[self.npc_id];
    --print("zoezoezeo",sprinttb(self.npcCfg))
    if not self.npcFriend then
        self.view.middle:SetActive(false)
        self.view.middleTip:SetActive(true)
        self.view.middleTip.dialog.Text[UI.Text].text = SGK.Localize:getInstance():getValue("haogandu_buff_none_03")
    else
        self.view.middle:SetActive(true)
        self.view.middleTip:SetActive(false)
    end
    self.biographyCfg = DataBoxModule.GetBiographyConfig(self.npc_id);
    self.biographyDesCfg = DataBoxModule.GetBiographyDesConfig(self.biographyCfg.des_id);
    self.biography = {};
    for i=1,6 do
        if self.biographyDesCfg["clue_des"..i] ~= "" and self.biographyDesCfg["clue_des"..i] ~= "0" then
            table.insert(self.biography, {quest_id = self.biographyCfg.bigclue_quest, des = self.biographyDesCfg["clue_des"..i]})
        end
    end
    -- CS.UGUIClickEventListener.Get(self.view.middle.BtnBg.visit.gameObject).onClick = function ()
    --     if self.npcFriend then
    --         utils.SGKTools.Map_Interact(self.npcFriend.xunlu_npc_id);
    --     else
    --         showDlgError(nil,"此功能暂未开放")
    --     end
    -- end
    self.hero =module.HeroModule.GetManager():Get(self.npc_id)
    if self.hero and self.npcFriend then
        local point = module.ItemModule.GetItemCount(self.npcFriend.arguments_item_id);    
        local stageNum = module.ItemModule.GetItemCount(self.npcFriend.stage_item)
        local relation = StringSplit(self.npcFriend.qinmi_max,"|")
        self.view.middle.BtnBg.incident[UI.Image].color={r=1,g=1,b=1,a=1}
        self.view.middle.BtnBg.gift[UI.Image].color={r=1,g=1,b=1,a=1}
        self.view.middle.BtnBg.talk[UI.Image].color={r=1,g=1,b=1,a=1}
        CS.UGUIClickEventListener.Get(self.view.middle.BtnBg.incident.gameObject).onClick = function ()
            DialogStack.PushPrefStact("npcChat/npcEvent",{data=self.npcFriend,npcCfg=self.npcCfg})
            if  point >= tonumber(relation[stageNum + 2]) then
                NpcChatMoudle.SetNpcRedDotFlag(self.npc_id,module.ItemModule.GetItemCount(self.npcFriend.stage_item))
            end
            self.view.middle.BtnBg.incident.tip:SetActive(false)
        end
        CS.UGUIClickEventListener.Get(self.view.middle.BtnBg.gift.gameObject).onClick = function ()
            DialogStack.PushPref("npcBribeTaking",{id = self.npcFriend.npc_id,item_id = self.npcFriend.arguments_item_id},self.view.gameObject)
        end
        CS.UGUIClickEventListener.Get(self.view.middle.BtnBg.talk.gameObject).onClick = function ()
            if npcConfig.GetnpcTopic(self.npc_id) then
                DialogStack.PushPrefStact("npcChat/npcChat",{data=self.npcFriend,npcCfg=self.npcCfg})
            else
                showDlgError(nil,"暂未开放");
            end
        end
        if not npcConfig.GetnpcTopic(self.npc_id) then
            self.view.middle.BtnBg.talk[UI.Image].color={r=0.4,g=0.4,b=0.4,a=1}
        end
    else
        self.view.middle.BtnBg.incident[UI.Image].color={r=0.4,g=0.4,b=0.4,a=1}
        self.view.middle.BtnBg.gift[UI.Image].color={r=0.4,g=0.4,b=0.4,a=1}
        self.view.middle.BtnBg.talk[UI.Image].color={r=0.4,g=0.4,b=0.4,a=1}
        CS.UGUIClickEventListener.Get(self.view.middle.BtnBg.incident.gameObject).onClick = function ()
            showDlgError(nil, "您还未获得该英雄")
        end
        CS.UGUIClickEventListener.Get(self.view.middle.BtnBg.gift.gameObject).onClick = function ()
            showDlgError(nil, "您还未获得该英雄")
        end
        CS.UGUIClickEventListener.Get(self.view.middle.BtnBg.talk.gameObject).onClick = function ()
            showDlgError(nil, "您还未获得该英雄")
        end
    end
    if self.npcFriend and self.npcFriend.arguments_item_id ~= 0 then
        self.view.middle.BtnBg.gift.gameObject:SetActive(true)
        self.view.middle.BtnBg.talk.gameObject:SetActive(true)
        self.view.middle.BtnBg.incident.gameObject:SetActive(true)
    else
        self.view.middle.BtnBg.gift.gameObject:SetActive(false)
        self.view.middle.BtnBg.talk.gameObject:SetActive(false)
        self.view.middle.BtnBg.incident.gameObject:SetActive(false)
    end
end

function View:InitView()
    CS.UGUIClickEventListener.Get(self.root.BG.gameObject).onClick = function ( object )
        DialogStack.Pop()
    end
    CS.UGUIClickEventListener.Get(self.view.title.close.gameObject).onClick = function ( object )
        DialogStack.Pop()
    end
    CS.UGUIClickEventListener.Get(self.view.top.help.gameObject).onClick = function ( object )
        utils.SGKTools.ShowDlgHelp(SGK.Localize:getInstance():getValue("renwuzhuanji_09"), nil, self.root.dialog)
    end
    CS.UGUIClickEventListener.Get(self.view.left.gameObject).onClick = function ( object )
        if self.pos > 1 then
            self.pos = self.pos - 1;
            self:UpdateData();
            self:MoveContent(1);
            self:initFriendShipScrollView();
            self:UpdateData();
            self:UpBiography(self.BiographyIndex)
        end
    end
    CS.UGUIClickEventListener.Get(self.view.right.gameObject).onClick = function ( object )
        if self.pos < #self.npcFriendData then
            self.pos = self.pos + 1;
            self:UpdateData();
            self:MoveContent(-1);
            self:initFriendShipScrollView();
            self:UpdateData();
            self:UpBiography(self.BiographyIndex)
        end
    end
    self:initMiddleClick()
    -- CS.UGUIClickEventListener.Get(self.view.middle.itemNode.Content.FriendShipInfo.Slider.status.gameObject).onClick = function ()
    --     self.view.mask.gameObject:SetActive(true)
    --     self.view.friendShipDetail.gameObject:SetActive(true)
    -- end
    -- CS.UGUIClickEventListener.Get(self.view.mask.gameObject).onClick = function ()
    --     self.view.effectDetail.gameObject:SetActive(false)
    --     self.view.friendShipDetail.gameObject:SetActive(false)
    --     self.view.mask.gameObject:SetActive(false)
    -- end
    
    self:UpdateView();
    --self:UpdateReward();
end

function View:UpRedDot(npc_id,point,stageNum,relation)
    return NpcChatMoudle.CheckNpcDataRedDot(npc_id,point,stageNum,relation)
end

function View:initMiddleClick()
    CS.UGUIClickEventListener.Get(self.view.middle.middleTab.Tab1.gameObject, true).onClick = function ()
        for i=1,4 do
            self.view.middle.middleTab["Tab"..i].Text[CS.UGUIColorSelector].index = 1
        end
        self.view.middle.middleTab.Tab1.Text[CS.UGUIColorSelector].index = 0
        self.view.middle.itemNode.Content.BiographyInfo.gameObject:SetActive(false)
        self.view.middle.itemNode.Content.FriendShipInfo.gameObject:SetActive(true)
        self:initFriendShipScrollView()
    end
    for i=1,3 do
        CS.UGUIClickEventListener.Get(self.view.middle.middleTab["Tab"..(i + 1)].gameObject, true).onClick = function ()
            for j=1,4 do
                self.view.middle.middleTab["Tab"..j].Text[CS.UGUIColorSelector].index = 1
            end
            self.view.middle.middleTab["Tab"..(i + 1)].Text[CS.UGUIColorSelector].index = 0
            self.view.middle.itemNode.Content.FriendShipInfo.gameObject:SetActive(false)
            self.view.middle.itemNode.Content.BiographyInfo.gameObject:SetActive(true)
            --self:initFriendShipScrollView()
            self.BiographyIndex = i
            self:UpBiography(i)
        end
    end
end

function View:UpBiography(i)
    local root = self.view.middle.itemNode.Content.BiographyInfo
    if not i then
        i = 1
    end
    if self.npcFriend and self:IsQuestFinish(self.biography[i].quest_id, i) then
        --print("传记完成",i,sprinttb(QuestModule.Get(self.biography[i].quest_id)))
        --print("shuliang",module.ItemModule.GetItemCount(1511049))
        local content = root.ScrollView.Viewport.Content
        root.tip:SetActive(false)
        root.ScrollView:SetActive(true)
        content.Text[UI.Text].text = self.biography[i].des
        content[UnityEngine.RectTransform].sizeDelta = CS.UnityEngine.Vector2(content[UnityEngine.RectTransform].sizeDelta.x,content.Text[UI.Text].preferredHeight+5)
        root.ScrollView[UI.ScrollRect].verticalNormalizedPosition=1
    else
        root.tip:SetActive(true)
        root.ScrollView:SetActive(false)
        if not self.npcFriend then
            root.tip.dialog.Text[UI.Text].text = "无传记"
        elseif self.biography[i].quest_id then
            local relation_desc = StringSplit(self.npcFriend.qinmi_name,"|")
            local quest_cfg = QuestModule.GetCfg(self.biography[i].quest_id, i);
            local desc = relation_desc[(quest_cfg.consume[1].value + 1)]
            root.tip.dialog.Text[UI.Text].text = "好感度达到"..desc.."开启传记"--..NumToText[i]
        end
    end
end

function View:initFriendShipScrollView()
    if self.npcFriend and self.npcFriend.arguments_item_id ~= 0 then
        self.view.middle.itemNode.Content.FriendShipInfo.Slider.gameObject:SetActive(true)
        local point = module.ItemModule.GetItemCount(self.npcFriend.arguments_item_id);
        local stageNum = module.ItemModule.GetItemCount(self.npcFriend.stage_item)
        local relation = StringSplit(self.npcFriend.qinmi_max,"|")
        local relation_desc = StringSplit(self.npcFriend.qinmi_name,"|")
        local buffid =StringSplit(self.npcFriend.quest_buff,"|")
        local quest_List =StringSplit(self.npcFriend.quest_up,"|")
        local redDotFlag = self:UpRedDot(self.npc_id,point,stageNum,relation)
        self.view.middle.BtnBg.incident.tip:SetActive(redDotFlag)
        --print("zoe npc事件红点",redDotFlag,self.npc_id,point,stageNum,sprinttb(relation))
        self.rewardFlag = true
        self.view.middle.itemNode.Content.FriendShipInfo.ScrollView[CS.UIMultiScroller].RefreshIconCallback = (function (go,idx)
            local obj = CS.SGK.UIReference.Setup(go)
            obj.name.Text[UI.Text].text = relation_desc[idx + 2]
            obj.name.need[UI.Text].text = relation[idx + 2].."+"
            if tonumber(buffid[idx + 2]) ~= 0 then
                obj.reward[UI.Text].text = QuestModule.GetCfg(tonumber(buffid[idx + 2])).raw.name
            else
                obj.reward[UI.Text].text = ""
            end
            if self:IsQuestFinish(tonumber(quest_List[idx + 2])) then
                obj.name.need[CS.UGUIColorSelector].index = 1
                obj.reward[CS.UGUIColorSelector].index = 1
            else
                obj.name.need[CS.UGUIColorSelector].index = 0
                obj.reward[CS.UGUIColorSelector].index = 0
            end
            self:UpdateReward(go,idx)
            obj.gameObject:SetActive(true)
        end)
        self.view.middle.itemNode.Content.FriendShipInfo.ScrollView[CS.UIMultiScroller].DataCount = #relation - 1
        self.view.middle.itemNode.Content.FriendShipInfo.Slider.status[CS.UGUISpriteSelector].index = stageNum
        
        if stageNum+1 < #relation then
            self.view.middle.itemNode.Content.FriendShipInfo.Slider[UnityEngine.UI.Slider].maxValue = tonumber(relation[stageNum + 2]);
            self.view.middle.itemNode.Content.FriendShipInfo.Slider[UnityEngine.UI.Slider].value = point;
            self.view.middle.itemNode.Content.FriendShipInfo.Slider.num[UnityEngine.UI.Text]:TextFormat("{0}/{1}", point, tonumber(relation[stageNum + 2]));
            if point < tonumber(relation[stageNum + 2]) then
                self.view.middle.itemNode.Content.FriendShipInfo.Slider.tip.gameObject:SetActive(false)
            else
                self.view.middle.itemNode.Content.FriendShipInfo.Slider.tip.gameObject:SetActive(true)
                CS.UGUIClickEventListener.Get(self.view.middle.itemNode.Content.FriendShipInfo.Slider.tip.gameObject).onClick = function ()
                    showDlgError(nil,SGK.Localize:getInstance():getValue("haogandu_tips_03"))
                end
            end
        else
            self.view.middle.itemNode.Content.FriendShipInfo.Slider.tip.gameObject:SetActive(true)
            CS.UGUIClickEventListener.Get(self.view.middle.itemNode.Content.FriendShipInfo.Slider.tip.gameObject).onClick = function ()
                showDlgError(nil,"好感度已满")
            end
            self.view.middle.itemNode.Content.FriendShipInfo.Slider[UnityEngine.UI.Slider].maxValue = 1;
            self.view.middle.itemNode.Content.FriendShipInfo.Slider[UnityEngine.UI.Slider].value = 1;
            self.view.middle.itemNode.Content.FriendShipInfo.Slider.num[UnityEngine.UI.Text].text="max"
        end
    else
        self.view.middle.itemNode.Content.FriendShipInfo.Slider.gameObject:SetActive(false)
    end    
end

function View:UpdateView()
    self.view.left:SetActive(self.pos > 1);
    self.view.right:SetActive(self.pos < #self.npcFriendData);
    self.view.top.title[UnityEngine.UI.Text].text = self.biographyDesCfg.honor;
    self.view.top.name[UnityEngine.UI.Text].text = self.npcCfg.name;
    if self.npcCfg then
        if self.npcCfg.icon then
            self.view.top.icon.transform.localScale=UnityEngine.Vector3(0.95,0.95,1)
            utils.IconFrameHelper.Create(self.view.top.icon,{type = ItemHelper.TYPE.HERO,id = self.npc_id,customCfg={level = 0},showDetail = false})
            --self.view.top.icon[UI.Image]:LoadSprite("icon/"..self.npcCfg.icon);
            -- local icon = utils.IconFrameHelper.Hero({icon = self.npcCfg.icon},self.view.top.icon)
            -- if icon and icon.Frame then
            --     icon.Frame:SetActive(false)
            -- end
        end
    end
    -- local animation = self.view.top.role.spine[CS.Spine.Unity.SkeletonGraphic];
    -- animation.skeletonDataAsset = SGK.ResourcesManager.Load("roles_small/"..self.npcCfg.mode.."/"..self.npcCfg.mode.."_SkeletonData") or SGK.ResourcesManager.Load("roles_small/11000/11000_SkeletonData");
    -- animation.startingAnimation = "idle1";
    -- animation.startingLoop = true;
    -- animation:Initialize(true);
    
    for i=1,5 do
        local quest_id = self.biographyCfg["clue_quest"..i];
        if self:IsQuestFinish(quest_id) then
            self.view.top.info["info"..i].Text[UnityEngine.UI.Text]:TextFormat("{0}{1}", SGK.Localize:getInstance():getValue("renwuzhuanji_0"..i), self.biographyDesCfg["des"..i])
        else
            self.view.top.info["info"..i].Text[UnityEngine.UI.Text]:TextFormat("{0}{1}", SGK.Localize:getInstance():getValue("renwuzhuanji_0"..i), SGK.Localize:getInstance():getValue("renwuzhuanji_10"))
        end
    end
    for i,v in ipairs(self.biography_UI) do
        v:SetActive(false);
    end
    self:initFriendShipScrollView()
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
    for _, consume in ipairs(quest.consume) do
        if consume.type == 41 then
            if consume.id == self.npcFriend.arguments_item_id then
                local relation = StringSplit(self.npcFriend.qinmi_max,"|")
                local relation_desc = StringSplit(self.npcFriend.qinmi_name,"|")
                local relation_index = #relation;
                for i,v in ipairs(relation) do
                    if consume.value < tonumber(v) then
                        relation_index = i - 1;
                        break;
                    end
                end
                return "需要好感度达到<color=#FF0000FF>"..relation_desc[relation_index].."</color>";
            else
                local cfg = ItemHelper.Get(consume.type, consume.id);
                return "需要<color=#FF0000FF>"..cfg.name.."</color>"..consume.value.."个";
            end
        end
    end
end

local rewardIdxCfg = {
    [1] = 0,
    [2] = 2,
    [3] = 4,
}

function View:UpdateReward(go,idx)
    --print("zoe npcData报错查看npcid",self.npc_id)
    local root = CS.SGK.UIReference.Setup(go);
    local view = root
    local quest_id = nil
    for k,v in pairs(rewardIdxCfg) do
        if idx == v then
            quest_id = self.biographyCfg["reward_quest"];
            idx = k
        end
    end
    if quest_id then
        local quest_cfg = QuestModule.GetCfg(quest_id,idx);
        --print("奖励",quest_id,sprinttb(quest_cfg))
        if quest_cfg then
            local desc = root.reward[UI.Text].text
            root.reward[UI.Text].text = desc.."\n解锁传记"..NumToText[quest_cfg.consume[1].value]
            view.btn.gameObject:SetActive(true)
            view.get.gameObject:SetActive(false)
            if self:IsQuestFinish(quest_id,idx) then
                view.btn.gameObject:SetActive(false)
                view.get.gameObject:SetActive(true)
            elseif QuestModule.CanSubmit(quest_id) and self.rewardFlag then
                view.btn[CS.UGUISpriteSelector].index = 0
                view.btn.Text[UI.Text].text = "领取"
                CS.UGUIClickEventListener.Get(view.btn.gameObject).onClick = function ()
                    QuestModule.Finish(quest_id)
                end
                self.rewardFlag = false
            else
                view.btn[CS.UGUISpriteSelector].index = 1
                view.btn.Text[UI.Text].text = "未达成"
                CS.UGUIClickEventListener.Get(view.btn.gameObject).onClick = function ()
                    showDlgError(nil, "好感度不足，请继续努力！");
                end
            end
            if quest_cfg.reward[1].type == 93 then
                if quest_cfg.reward[1].id ~= 0 then
                    local buffCfg = HeroBuffModule.GetBuffConfig(quest_cfg.reward[1].id)
                    view.icon:SetActive(true);
                    view.IconFrame:SetActive(false);
                    if buffCfg.hero_id ~= 0 then
                        view.icon[UnityEngine.UI.Image]:LoadSprite("icon/"..buffCfg.hero_id);
                    end
                else
                    view.icon:SetActive(false);
                    view.IconFrame:SetActive(false);
                    view.btn.gameObject:SetActive(false)
                    local stageNum = module.ItemModule.GetItemCount(self.npcFriend.stage_item)
                    if stageNum > idx then
                        view.get.gameObject:SetActive(true)
                    else
                        view.get.gameObject:SetActive(false)
                    end
                end
            else
                view.icon:SetActive(false);
                view.IconFrame:SetActive(true);
                local itemCfg = ItemHelper.Get(quest_cfg.reward[1].type, quest_cfg.reward[1].id);
                utils.IconFrameHelper.Create(view.IconFrame,{type = quest_cfg.reward[1].type, id = quest_cfg.reward[1].id, count = quest_cfg.reward[1].value})
                view.IconFrame.transform.localScale = UnityEngine.Vector3(64/130,64/130,0) 
            end
        end
    else
        --print(idx)
        view.icon:SetActive(false);
        view.IconFrame:SetActive(false);
        view.btn.gameObject:SetActive(false)
        local stageNum = module.ItemModule.GetItemCount(self.npcFriend.stage_item)
        if stageNum > idx then
            view.get.gameObject:SetActive(true)
        else
            view.get.gameObject:SetActive(false)
        end
    end
end

function View:MoveContent(direction)
    local content = self.view.middle--.ScrollView.Viewport.Content;
    local _content = self.view.middleTip
        self:UpdateView();
    content.transform:DOLocalMove(Vector3(650 * direction, 0, 0), 0.15):SetRelative(true):SetEase(CS.DG.Tweening.Ease.InQuad):OnComplete(function ()
        content[UnityEngine.RectTransform].anchoredPosition = UnityEngine.Vector2(650 * -direction,-205);
        content.transform:DOLocalMove(Vector3(650 * direction, 0, 0), 0.15):SetRelative(true):SetEase(CS.DG.Tweening.Ease.OutQuad);
    end)
    _content.transform:DOLocalMove(Vector3(650 * direction, 0, 0), 0.15):SetRelative(true):SetEase(CS.DG.Tweening.Ease.InQuad):OnComplete(function ()
        _content[UnityEngine.RectTransform].anchoredPosition = UnityEngine.Vector2(650 * -direction,-205);
        _content.transform:DOLocalMove(Vector3(650 * direction, 0, 0), 0.15):SetRelative(true):SetEase(CS.DG.Tweening.Ease.OutQuad);
    end)
end

function View:IsQuestFinish(quest_id, stage)
    stage = stage or 1;
    if quest_id == 0 then
        return true;
    end
    local quest = QuestModule.Get(quest_id);
    if quest then
        if quest.status == 1 then
            return true;
        elseif quest.stageFlag > stage then
            return true;
        end
    else
        print("任务不存在", quest_id)
    end
    return false;
end

function View:OnDestroy()

end

function View:listEvent()
	return {
		"QUEST_INFO_CHANGE",
        "SHOP_BUY_SUCCEED",
        "LOCAL_GUIDE_CHANE",
	}
end

function View:onEvent(event, ...)
	--print("NpcData onEvent", event, ...);
	if event == "QUEST_INFO_CHANGE"  then
        self:initFriendShipScrollView();
        self:UpdateView();
        self:UpdateData()
    elseif event == "SHOP_BUY_SUCCEED" then
        self:UpdateView();
        self:initFriendShipScrollView();
        self:UpdateData()
    elseif event == "LOCAL_GUIDE_CHANE" then
        self:initGuide()
	end
end

return View;
