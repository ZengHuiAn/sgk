local TradeModule = require "module.TradeModule"
local ItemHelper = require "utils.ItemHelper"
local Time = require "module.Time"
local ItemModule = require "module.ItemModule"
local equipmentModule =require "module.equipmentModule"
local InscModule = require "module.InscModule"
local Property = require "utils.Property"
local ParameterConf = require "config.ParameterShowInfo"

local text_color = {};
text_color[1] = {r = 218/255, g = 38/255, b = 41/255, a = 1};
text_color[2] = {r = 0/255, g = 0/255, b = 0/255, a = 1}; --{r = 35/255, g = 255/255, b = 207/255, a = 1}
text_color[3] = {r = 27/255, g = 155/255, b = 32/255, a = 1};

local View = {};
function View:Start(data)
    self.root = CS.SGK.UIReference.Setup(self.gameObject);
    self.view = self.root.view;
    self.gid = data and data.gid or 100001;
    self.uuid = data and data.uuid or 0;
    self.order =  data and data.order;
    self.type = data and data.type or 1;
    self.canSell = data and data.canSell or false;
	self:InitData();
end

function View:InitData()
    self.overdue = false;
    self.assess_value = 0;
    self.price = 0;
    self.up_rate = 0;
    self.goods_rank = 0;
    self.pid = module.playerModule.GetSelfID();
    if self.type == 1 then --上架
        self.cfg = TradeModule.GetConfigByGid(self.gid);
    elseif self.type == 2 then --下架
        self.overdue = Time.now() > (self.order[4] + 86400)
        self.cfg = TradeModule.GetConfigById(self.order[2][1], self.order[2][2]);
    end
    if self.uuid ~= 0 then
        self.equip = equipmentModule.GetByUUID(self.uuid);
        if self.equip then
            self:InitView();
        else
            self.pid = 100000;
            equipmentModule.QueryEquipInfoFromServer(100000, self.uuid, function (equip)
                self.equip = equip;
                self:InitView();
            end);
        end
    else
        self:InitView();
    end
end

function View:InitView()
    self.gray_material = self.view.up.up[CS.UnityEngine.MeshRenderer].materials[0];
    -- print("装备信息", sprinttb(self.equip))
    local item_cfg = ItemHelper.Get(self.cfg.item_type, self.cfg.item_id, nil, self.cfg.sale_value);

    -- if self.type == 1 then
    --     self.view.title.name[UnityEngine.UI.Text].text = SGK.Localize:getInstance():getValue("biaoti_wupinshangjia_01");
    -- elseif self.type == 2 then
    --     if self.overdue then
    --         self.view.title.name[UnityEngine.UI.Text].text = SGK.Localize:getInstance():getValue("biaoti_chongxinshangjia_01");
    --     else
    --         self.view.title.name[UnityEngine.UI.Text].text = SGK.Localize:getInstance():getValue("biaoti_wupinxiajia_01");
    --     end
    -- end

    self.view.up:SetActive(self.type == 1 or self.overdue);
    self.view.down:SetActive(self.type == 2 and not self.overdue);
    if self.type == 1 or self.overdue then
        CS.UGUIClickEventListener.Get(self.view.up.up.gameObject).onClick = function (obj)
            if not self.canSell then
                showDlgError(nil, "货架已满");
                return;
            end
            if self.price > 0 then
                if self.cfg.item_type == 41 and item_cfg.count < self.cfg.sale_value then
                    showDlgError(nil, "物品数量不足");
                    return;
                end
                if ItemModule.GetItemCount(self.cfg.fee_id) < self.tax_num then
                    showDlgError(nil, "货币不足");
                    return;
                end
                if self.overdue then
                    TradeModule.Sell(self.order[2][1], self.order[2][2], self.order[2][3], self.price, self.order[2][4], self.order[1]);
                else
                    TradeModule.Sell(self.cfg.item_type, self.cfg.item_id, self.cfg.sale_value, self.price, self.uuid);
                end
            end
        end
        SetButtonStatus(false, self.view.up.up, self.gray_material);
        CS.UGUIClickEventListener.Get(self.view.up.plus.gameObject).onClick = function (obj)
            if self.price > 0 and self.up_rate < self.cfg.percent_up then
                self.up_rate = self.up_rate +  self.cfg.percent_eachtime;
                self.price = math.floor((1 + self.up_rate) * self.assess_value + 0.5);
                SetButtonStatus(self.up_rate < self.cfg.percent_up, self.view.up.plus, self.gray_material);
                SetButtonStatus(self.up_rate > self.cfg.percent_down, self.view.up.reduce, self.gray_material);
                self:UpdatePrice();
            end
        end
        CS.UGUIClickEventListener.Get(self.view.up.reduce.gameObject).onClick = function (obj)
            if self.price > 0 and self.up_rate > self.cfg.percent_down then
                self.up_rate = self.up_rate -  self.cfg.percent_eachtime;
                self.price = math.floor((1 + self.up_rate) * self.assess_value + 0.5);
                SetButtonStatus(self.up_rate < self.cfg.percent_up, self.view.up.plus, self.gray_material);
                SetButtonStatus(self.up_rate > self.cfg.percent_down, self.view.up.reduce, self.gray_material);
                self:UpdatePrice();
            end
        end
        CS.UGUIPointerEventListener.Get(self.view.up.help.gameObject).onPointerDown = function(go, pos)
            self.view.up.help.info:SetActive(true);
        end
        CS.UGUIPointerEventListener.Get(self.view.up.help.gameObject).onPointerUp = function(go, pos)
            self.view.up.help.info:SetActive(false);
        end
        CS.UGUIClickEventListener.Get(self.view.up.consult.gameObject).onClick = function (obj)
            self:ShowGoodsRank()
        end
        
        if self.overdue then
            -- self.view.up.up.gameObject.transform.localPosition = Vector3(120, -111.3, 0);
            self.view.up.up[UnityEngine.RectTransform].anchoredPosition = CS.UnityEngine.Vector2(120, -111.3);
            self.view.up.up.Text[UnityEngine.UI.Text].text = "重新上架";
            self.view.up.down:SetActive(true);
            CS.UGUIClickEventListener.Get(self.view.up.down.gameObject).onClick = function (obj)
                TradeModule.TakeBack(self.order[1]);
            end
        else
            -- self.view.up.up.gameObject.transform.localPosition = Vector3(0, -111.3, 0);
            self.view.up.up[UnityEngine.RectTransform].anchoredPosition = CS.UnityEngine.Vector2(0, -111.3);
            self.view.up.up.Text[UnityEngine.UI.Text].text = "确认上架";
            self.view.up.down:SetActive(false);
        end

        TradeModule.GetCommodityConfig(function (info)
            if info[self.cfg.item_id] then
                self.assess_value = math.floor(info[self.cfg.item_id].assess_value)
                self.price = self.assess_value;
                self.view.up.price.icon[UnityEngine.UI.Image]:LoadSprite("icon/"..info[self.cfg.item_id].cost_id.."_small");
                self.view.up.tax.icon[UnityEngine.UI.Image]:LoadSprite("icon/"..info[self.cfg.item_id].fee_id.."_small");
                self:UpdatePrice();
                SetButtonStatus(true, self.view.up.up, self.gray_material);
            end
        end)
    elseif self.type == 2 then
        self.view.down.price.num[UnityEngine.UI.Text].text = self.order[3][3];
        self.view.down.price.icon[UnityEngine.UI.Image]:LoadSprite("icon/"..self.order[3][2].."_small");
        CS.UGUIClickEventListener.Get(self.view.down.down.gameObject).onClick = function (obj)
            TradeModule.TakeBack(self.order[1]);
        end
        CS.UGUIClickEventListener.Get(self.view.down.consult.gameObject).onClick = function (obj)
            self:ShowGoodsRank()
        end
    end

    self.view.content.ScrollView[CS.UIMultiScroller].RefreshIconCallback = function ( obj, idx )
        local info = self.goods_rank[idx + 1];
        local item = CS.SGK.UIReference.Setup(obj);
        local cfg = ItemHelper.Get(info[2][1], info[2][2]);
        item.name[UnityEngine.UI.Text]:TextFormat(cfg.name);
        -- item.newItemIcon[SGK.newItemIcon]:SetInfo(cfg);
        utils.IconFrameHelper.Create(item.IconFrame,{type = info[2][1], id = info[2][2], count = 0})
        item.icon[UnityEngine.UI.Image]:LoadSprite("icon/"..info[3][2].."_small");
        item.count[UnityEngine.UI.Text].text = info[3][3];
        item:SetActive(true);
    end

    -- CS.UGUIClickEventListener.Get(self.root.mask.gameObject).onClick = function (obj)
    --     self:ShowGoodsRank()
    -- end
end

function View:ShowGoodsRank()
    if self.view.content.activeSelf then
        self.view.content:SetActive(false);
        -- self.view.mask:SetActive(false);
        self.view.content.none:SetActive(false);
    else
        self.view.content:SetActive(true);
        -- self.view.mask:SetActive(true);
        TradeModule.QueryOrdersRank(self.cfg.gid, function (ranklist)
            self.goods_rank = ranklist;
            self.view.content.ScrollView[CS.UIMultiScroller].DataCount = #ranklist;
            self.view.content.none:SetActive(#ranklist == 0);
        end)
    end
end

function View:UpdatePrice()
    if self.up_rate > 0 then
        self.view.up.tip[UnityEngine.UI.Text]:TextFormat("推荐价格 +{0}%", math.floor(self.up_rate * 100));
        self.view.up.tip[UnityEngine.UI.Text].color = text_color[3];
    elseif self.up_rate < 0 then
        self.view.up.tip[UnityEngine.UI.Text]:TextFormat("推荐价格 {0}%", math.ceil(self.up_rate * 100));
        self.view.up.tip[UnityEngine.UI.Text].color = text_color[1];
    else
        self.view.up.tip[UnityEngine.UI.Text]:TextFormat("推荐价格");
        self.view.up.tip[UnityEngine.UI.Text].color = text_color[2];
    end
    self.view.up.price.num[UnityEngine.UI.Text].text = self.price;
    local tax_num = math.floor(self.price * self.cfg.fee_rate / 100);
    if tax_num > 10000 then
        tax_num = 10000;
    elseif tax_num < 100 then
        tax_num = 100;
    end
    self.tax_num = tax_num;
    self.view.up.tax.num[UnityEngine.UI.Text].text = tostring(tax_num);
end

function View:deActive()
	utils.SGKTools.PlayDestroyAnim(self.gameObject)
	return true;
end

function View:listEvent()
	return {
        "TRADE_TAKEBACK_SUCCESS",
        "TRADE_SELL_SUCCESS",
        "TRADE_TAKEBACK_FAILD"
	}
end

function View:onEvent(event, ...)
	print("onEvent", event, ...);
	if event == "TRADE_TAKEBACK_SUCCESS" or event == "TRADE_TAKEBACK_FAILD" or event == "TRADE_SELL_SUCCESS" then
        DialogStack.Pop();
	end
end

return View;