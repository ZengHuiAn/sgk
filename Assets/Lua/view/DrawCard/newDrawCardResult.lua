local ActivityModule = require "module.ActivityModule"
local ItemModule = require "module.ItemModule"
local Time = require "module.Time"
local ItemHelper = require "utils.ItemHelper"
local TipCfg = require "config.TipConfig"
local View = {};

local animation = {
    [1] = {name = "chouka_ani_1_0ssr", time = 1.2},
    [2] = {name = "chouka_ani_1_ssr", time = 1.2},
    [3] = {name = "chouka_ani_10_0ssr", time = 4.2},
    [4] = {name = "chouka_ani_10_ssr", time = 4.2},
};

function View:Start(data)
    self.root = CS.SGK.UIReference.Setup(self.gameObject);
    self.view = self.root.view;
    self.activity_id = data and data.activity_id or 1;
    self.args = data and data.args;
	self:InitData();
    self:InitView();
    self:initGuide()
    if self.args then
        self:CleanCircle();
        ActivityModule.DrawCard(unpack(self.args));
    end
end

function View:InitData()
    self.updateTime = 0;
    self.allEffect = {};
    self.poolData = self:GetPoolData(self.activity_id);
end

function View:InitView()
    DialogStack.PushPref("CurrencyChat", {itemid = {90002, 90003, 90221, 90222}}, self.view.chat);

    local poolCfg = ActivityModule.GetDrawCardShowConfig(self.activity_id);
    local width = {349, 349, 365, 385};
    self.view.guarantee[UnityEngine.RectTransform].sizeDelta = CS.UnityEngine.Vector2(width[poolCfg.guarantee_stage] or 385, 39)
    self.view.guarantee.class[CS.UGUISpriteSelector].index = poolCfg.guarantee_stage - 1;
    self.view.guarantee.class[UnityEngine.UI.Image]:SetNativeSize();
    self.view.ten.off:SetActive(poolCfg.discount ~= 0);
    print("最小品质", poolCfg.show_closeup)
    self.minShowStage = poolCfg.show_closeup;--总是显示获得角色的最小品质
    if poolCfg.discount ~= 0 then
        self.view.ten.off[CS.UGUISpriteSelector].index = poolCfg.discount - 1;
    end
    self.view.circle.name[UnityEngine.UI.Text].text = SGK.Localize:getInstance():getValue("zhaomu_fazhenming_"..self.poolData.CardData.current_pool);
    self.view.circle.effect.Text[UnityEngine.UI.Text].text = SGK.Localize:getInstance():getValue("zhaomu_fazhendes_"..self.poolData.CardData.current_pool);
    self:UpdatePoolView();
    CS.UGUIClickEventListener.Get(self.view.one.gameObject).onClick = function (obj)
        self:DrawCard(self.activity_id, 0);
    end
    CS.UGUIClickEventListener.Get(self.view.ten.gameObject).onClick = function (obj)
        self:DrawCard(self.activity_id, 1);
    end
end

function View:GetPoolData(id)
    local activity_type = {1, 4, 5};
    for i,v in ipairs(activity_type) do
        local poolData = ActivityModule.GetManager(v);
        if poolData[id] then
            return poolData[id];
        end
    end
end

function View:CleanCircle()
    SetItemTipsState(false)
	for i=0,10 do
		if self.view.circle["item"..i] then
			self.view.circle["item"..i]:SetActive(false);
		end
    end
    for i,v in ipairs(self.allEffect) do
        UnityEngine.GameObject.Destroy(v);
    end
    self.allEffect = {};
    self.view.other:SetActive(false);
    self.root.mask:SetActive(true);
    self.view.point:SetActive(false);
end

function View:DrawCard(id, combo)
    print("抽卡", id, combo)
	local data = self.poolData;
	if data then
		if combo == 0 then
			local time = math.floor(Time.now() - data.CardData.last_free_time);
			if time >= data.free_gap then
				if data.free_Item_id == 0 or ItemModule.GetItemCount(data.free_Item_id) >= data.free_Item_consume then
                    local consume = {data.consume_type, data.consume_id, 0}
                    self:CleanCircle();
					ActivityModule.DrawCard(id, 0, consume, combo, false);
					return;
				end
			end
            if data.consume_id2 ~= 0 and ItemModule.GetItemCount(data.consume_id2) >= data.price2 then
                local consume = {data.consume_type2, data.consume_id2, data.price2}
                self:CleanCircle();
                ActivityModule.DrawCard(id, 0, consume, combo, true);
                return;
            end
            if data.consume_id ~= 0 and ItemModule.GetItemCount(data.consume_id) >= data.price then
                local consume = {data.consume_type, data.consume_id, data.price}
                self:CleanCircle();
                ActivityModule.DrawCard(id, 0, consume, combo, false);
            else
                local cfg = ItemHelper.Get(data.consume_type, data.consume_id)
                showDlgError(nil, cfg.name.."不足");
            end
        else
            if data.consume_id2 ~= 0 and ItemModule.GetItemCount(data.consume_id2) >= data.combo_price2 * data.combo_count then
                local consume = {data.consume_type2, data.consume_id2, data.combo_price2 * data.combo_count}
                self:CleanCircle();
                ActivityModule.DrawCard(id, 0, consume, combo, true);
                return;
            end
			local count = ItemModule.GetItemCount(data.consume_id);
			if count >= data.combo_price * data.combo_count then
                local consume = {data.consume_type, data.consume_id, data.combo_price * data.combo_count}
                self:CleanCircle();
				ActivityModule.DrawCard(id, 0, consume, combo, false);
			else
				local cfg = ItemHelper.Get(data.consume_type, data.consume_id)
				showDlgError(nil, cfg.name.."不足");
			end
		end
	else
		ERROR_LOG("奖池不存在", id)
	end
end

--刷新奖池显示
function View:UpdatePoolView()
    local guarantee_count = self.poolData.combo_count - (self.poolData.CardData.total_count % self.poolData.combo_count) - 1;
    if guarantee_count > 0 then
        self.view.guarantee[CS.UGUISpriteSelector].index = 0;
        self.view.guarantee.count[UnityEngine.UI.Text].text = guarantee_count;
        self.view.guarantee.count:SetActive(true);
    else
        self.view.guarantee[CS.UGUISpriteSelector].index = 1;
        self.view.guarantee.count:SetActive(false);
    end
    local time = math.floor(Time.now() - self.poolData.CardData.last_free_time);
    self.view.one.icon:SetActive(time < self.poolData.free_gap);
    self.view.one.num:SetActive(time < self.poolData.free_gap);
    self.view.one.free:SetActive(time >= self.poolData.free_gap);
    if time < self.poolData.free_gap then
        if self.poolData.consume_id2 ~= 0 and ItemModule.GetItemCount(self.poolData.consume_id2) >= self.poolData.price2 then
            self.view.one.icon[UnityEngine.UI.Image]:LoadSprite("icon/"..self.poolData.consume_id2.."_small");
            self.view.one.num[UnityEngine.UI.Text].text = self.poolData.price2;
        else 
            self.view.one.icon[UnityEngine.UI.Image]:LoadSprite("icon/"..self.poolData.consume_id.."_small");
            self.view.one.num[UnityEngine.UI.Text].text = self.poolData.price;
        end
    else
        self.view.freeTime[UnityEngine.UI.Text].text = "";
    end
    if self.poolData.consume_id2 ~= 0 and ItemModule.GetItemCount(self.poolData.consume_id2) >= self.poolData.combo_count * self.poolData.combo_price2 then
        self.view.ten.icon[UnityEngine.UI.Image]:LoadSprite("icon/"..self.poolData.consume_id2.."_small");
        self.view.ten.num[UnityEngine.UI.Text].text = self.poolData.combo_count * self.poolData.combo_price2;
    else
        self.view.ten.icon[UnityEngine.UI.Image]:LoadSprite("icon/"..self.poolData.consume_id.."_small");
        self.view.ten.num[UnityEngine.UI.Text].text = self.poolData.combo_count * self.poolData.combo_price;
    end
end

function View:Update()
	if Time.now() - self.updateTime >= 1 then
		self.updateTime = Time.now();
        local time = math.floor(self.poolData.CardData.last_free_time + self.poolData.free_gap - Time.now());
        if time >= 0 then
            self.view.freeTime[UnityEngine.UI.Text]:TextFormat("{0}后免费", GetTimeFormat(time, 2))
        else
            self.view.freeTime[UnityEngine.UI.Text].text = "";
        end
	end	
end

function View:ShowResult(result)
    print("result", sprinttb(result))
    local showReward = function ()
        self.view.point.Text[UnityEngine.UI.Text].text = "+"..result.point;
        self.view.point:SetActive(true);
        SGK.Action.DelayTime.Create(0.2):OnComplete(function()
            SetItemTipsState(true)
            for i,v in ipairs(result.other) do
                GetItemTips(v.id, v.value, v.type)
            end
            for i,v in ipairs(result.normal) do
                if v.type ~= ItemHelper.TYPE.HERO then
                    GetItemTips(v.id, v.value, v.type);
                else
                    GetItemTips(v.id, v.value, v.type,nil,true);
                end
            end
        end)
        SGK.Action.DelayTime.Create(0.3):OnComplete(function()
            self.root.mask:SetActive(false);
        end)
    end
    self.co = coroutine.create(function ()
        self.root.mask2:SetActive(true);
        self.effect:SetActive(false);
        for i,v in ipairs(result.normal) do
            if self.view.circle["item"..i] then
                if #result.normal == 1 then
                    self:PlayEffect(self.view.circle.item0, v);
                else
                    self:PlayEffect(self.view.circle["item"..i], v);
                end
                -- Sleep(0.1);
                if v.type == ItemHelper.TYPE.HERO then
                    local heroCfg = module.HeroModule.GetConfig(v.id);
                    if heroCfg.role_stage >= self.minShowStage then
                        utils.SGKTools.HeroShow(v.id,nil,nil,nil,self:CheckHero(v.id), heroCfg.sound)
                        coroutine.yield();
                    else
                        -- if not self:CheckHero(v.id) then
                        -- end
                        utils.SGKTools.HeroShow(v.id,nil,nil,nil,self:CheckHero(v.id), heroCfg.sound);
                        coroutine.yield();
                    end
                end
            end
        end
        showReward();
        -- self.root.effect:SetActive(false);
        self.root.mask2:SetActive(false);
        self.effect.transform:Find("chouka_ani"):GetComponent(typeof(UnityEngine.Animator)):Rebind();
    end);

    local ani_data = {};
    if #result.normal == 1 then
        if result.ssr == 0 then
            ani_data = animation[1];
        else
            ani_data = animation[2];
        end 
    else
        if result.ssr == 0 then
            ani_data = animation[3];
        else
            ani_data = animation[4];
        end 
    end

    print("ani_data", sprinttb(ani_data))
    -- self.root.effect:SetActive(true);

    if self.effect then
        self.effect:SetActive(true);
        self.effect.transform:Find("chouka_ani"):GetComponent(typeof(UnityEngine.Animator)):Play(ani_data.name);
        SGK.Action.DelayTime.Create(ani_data.time):OnComplete(function()
            coroutine.resume(self.co);
        end)
    else
        SGK.ResourcesManager.LoadAsync(self.view[SGK.UIReference],"prefabs/effect/fx_chouka_1.prefab",function (obj)
            self.effect = CS.UnityEngine.GameObject.Instantiate(obj)
            -- self.effect = GetUIParent(obj, self.view.transform)
            self.effect.transform:Find("chouka_ani"):GetComponent(typeof(UnityEngine.Animator)):Play(ani_data.name);
            SGK.Action.DelayTime.Create(ani_data.time):OnComplete(function()
                coroutine.resume(self.co);
            end)
        end)
    end
end

function View:CheckHero(id)
    local herolist = ActivityModule.GetSortHeroList()
    local hero_exist = false
    for i = 1,#herolist do
        if herolist[i].id == id then
            hero_exist = true
            break
        end
    end
    return hero_exist;
end

function View:GetClass(info)    --区分物品档次
    if info.type == ItemHelper.TYPE.HERO then
        return 0;
    end
    if math.floor(info.id / 10000) == 2 then
        return 1;
    end
    return 2;
end

function View:PlayEffect(item, info)
    if info.type == ItemHelper.TYPE.HERO and self:CheckHero(info.id) then
        local _cfg = ItemModule.GetConfig(info.id + 10000);
        utils.IconFrameHelper.Create(item.IconFrame,{type = 41, id = info.id + 10000, count = _cfg.compose_num, showDetail = true})
    else
        utils.IconFrameHelper.Create(item.IconFrame,{type = info.type, id = info.id, count = info.value, showDetail = true})
    end
    local class = info.quality;
    if class >= 4 then
        SGK.ResourcesManager.LoadAsync(self.view[SGK.UIReference],"prefabs/effect/UI/fx_box_kai_blue.prefab",function (obj)
            local effect = GetUIParent(obj, item.transform)
            table.insert(self.allEffect, effect);
            effect.transform.localPosition = Vector3.zero;
        end)
    else
        SGK.ResourcesManager.LoadAsync(self.view[SGK.UIReference],"prefabs/effect/UI/fx_box_start.prefab",function (obj)
            local effect = GetUIParent(obj, item.transform)
            table.insert(self.allEffect, effect);
            effect.transform.localPosition = Vector3.zero;
        end)
    end
    if class == 2 then
        SGK.ResourcesManager.LoadAsync(self.view[SGK.UIReference],"prefabs/effect/UI/fx_box_zi_run.prefab",function (obj)
            local effect = GetUIParent(obj, item.transform)
            table.insert(self.allEffect, effect);
            effect.transform.localPosition = Vector3.zero;
        end)
    elseif class == 4 then
        SGK.ResourcesManager.LoadAsync(self.view[SGK.UIReference],"prefabs/effect/UI/fx_box_gold_run.prefab",function (obj)
            local effect = GetUIParent(obj, item.transform)
            table.insert(self.allEffect, effect);
            effect.transform.localPosition = Vector3.zero;
        end)
    end
    item:SetActive(true);
end

function View:initGuide()
    module.guideModule.PlayByType(117,0.2)
end

function View:OnDestroy()
    CS.UnityEngine.GameObject.Destroy(self.effect)
	SetItemTipsState(true)
end

function View:deActive()
    utils.SGKTools.PlayDestroyAnim(self.gameObject)
	return true;
end

function View:listEvent()
	return {
        "Activity_INFO_CHANGE",
        "DrawCard_Succeed",
        "DrawCard_Failed",
        "Continue_Show_DrawCard",
        "LOCAL_SOTRY_DIALOG_CLOSE",
        "LOCAL_GUIDE_CHANE",
	}
end

function View:onEvent(event, ...)
    print("onEvent", event, ...);
    local data = ...;
    if event == "Activity_INFO_CHANGE" then
        self.poolData = self:GetPoolData(self.activity_id);
        self:UpdatePoolView();
    elseif event == "DrawCard_Succeed" then
        print("物品", sprinttb(data))
        local poolCfg = ActivityModule.GetDrawCardShowConfig(self.activity_id);
        local result = {};
        result.normal = {};
        result.other = {};
        result.point = 0;
        result.ssr = 0;
        for i,v in ipairs(data) do
            local info = {type = v[1], id = v[2], value = v[3], quality = v[4]}
            if info.id == poolCfg.gift_id then
                table.insert(result.other, info);
            elseif info.id == 90036 then
                result.point = result.point + info.value;
            else
                table.insert(result.normal, info);
            end
            if v[1] == 42 then
                local heroCfg = module.HeroModule.GetConfig(v[2]);
                if heroCfg and heroCfg.role_stage >= 4 then
                    result.ssr = result.ssr + 1;
                end
            end
        end
        local all = {};
        for i,v in ipairs(result.other) do
            all[v.id] = all[v.id] or 0;
            all[v.id] = all[v.id] + v.value;
        end
        for k,v in pairs(all) do
            self.view.other:SetActive(true);
            utils.IconFrameHelper.Create(self.view.other.IconFrame,{type = 41, id = k, count = v, showDetail = true})
        end
        self:ShowResult(result)
    elseif event == "DrawCard_Failed" then
        showDlgError(nil, "抽卡失败"..data);
        if self.root.mask.activeSelf then
            self.root.mask:SetActive(false);
        end
    elseif event == "Continue_Show_DrawCard" or event == "LOCAL_SOTRY_DIALOG_CLOSE" then
        if self.co and coroutine.status(self.co) == "suspended" then
            coroutine.resume(self.co);
        end
    elseif event == "LOCAL_GUIDE_CHANE" then
        self:initGuide()
	end
end

return View;
