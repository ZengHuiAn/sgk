local ManorModule = require "module.ManorModule"
local ManorManufactureModule = require "module.ManorManufactureModule"
local View = {};
function View:Start(data)
	self.view = CS.SGK.UIReference.Setup(self.gameObject);
	self:InitData(data);
	self:InitView();
end

function View:InitData(data)
    self.line = data and data.line or 11;
    self.level = data and data.level or 1;
    self.levelup_cfg = ManorModule.GetManorLevelUpConfig(self.line);
    self.manorProductInfo = ManorManufactureModule.Get();
    self.productList = self.manorProductInfo:GetProductList(self.line);
end

function View:InitView()
	CS.UGUIClickEventListener.Get(self.view.BG.gameObject).onClick = function ( object )
        DialogStack.Pop()
   	end
    CS.UGUIClickEventListener.Get(self.view.title.close.gameObject).onClick = function ( object )
  	    DialogStack.Pop()
    end
    local manor_info = ManorModule.LoadManorInfo(self.line, 2);
    self.view.title.name[CS.UnityEngine.UI.Text]:TextFormat("<size=44>{0}</size>{1}{2}级",string.sub(manor_info.des_name,1,3), string.sub(manor_info.des_name,4), self.level);
    local cur_pool, next_pool = 0, 0;
    for k,v in pairs(self.productList) do
        if v.level_limit == self.level then
            cur_pool = v.product_pool1;
        end
        if v.level_limit == self.level + 1 then
            next_pool = v.product_pool1;
        end
    end 
    local pool1 = ManorModule.GetManufacturePool(cur_pool);
    local pool2 = ManorModule.GetManufacturePool(next_pool);
    for i=1,2 do
        if pool1[i] then
            self.view.order.before["icon"..i]:SetActive(true);
            utils.IconFrameHelper.Create(self.view.order.before["icon"..i],{type = pool1[i].item_type, id = pool1[i].item_id, count = pool1[i].item_value, showDetail = true})
        else
            self.view.order.before["icon"..i]:SetActive(false);
        end
        if pool2[i] then
            self.view.order.after["icon"..i]:SetActive(true);
            utils.IconFrameHelper.Create(self.view.order.after["icon"..i],{type = pool2[i].item_type, id = pool2[i].item_id, count = pool2[i].item_value, showDetail = true})
        else
            self.view.order.after["icon"..i]:SetActive(false);
        end
    end
    local levelup_cfg = self.levelup_cfg[self.level + 1];
    local canLevelUp1,canLevelUp2 = true, true;
    for i=1,2 do
        if levelup_cfg["condition_item_id"..i] ~= 0 then
            local count = module.ItemModule.GetItemCount(levelup_cfg["condition_item_id"..i]);
            local condition = levelup_cfg["condition_item_value"..i];
            if count >= condition then
                self.view.need.condition["des"..i][UI.Text]:TextFormat("{0}(<color=#008846FF>{1}/{2}</color>)", levelup_cfg["condition_text"..i], count, condition)
                self.view.need.condition["des"..i].check1:SetActive(true);
                self.view.need.condition["des"..i].check2:SetActive(false);
            else
                canLevelUp1 = false;
                self.view.need.condition["des"..i][UI.Text]:TextFormat("{0}(<color=red>{1}/{2}</color>)", levelup_cfg["condition_text"..i], count, condition)
                self.view.need.condition["des"..i].check1:SetActive(false)
                self.view.need.condition["des"..i].check2:SetActive(true);;
            end
            self.view.need.condition["des"..i]:SetActive(true);
        else
            self.view.need.condition["des"..i]:SetActive(false);
        end
    end
    for i=1,3 do
        if levelup_cfg["consume_item_id"..i] ~= 0 then
            local count = module.ItemModule.GetItemCount(levelup_cfg["consume_item_id"..i]);
            local condition = levelup_cfg["consume_item_value"..i];
            utils.IconFrameHelper.Create(self.view.need.cost["item"..i].IconFrame, {type = 41, id = levelup_cfg["consume_item_id"..i], count = 0, showDetail = true})
            if count >= condition then
                self.view.need.cost["item"..i].Text[UI.Text]:TextFormat("{0}/{1}", count, condition);
            else
                canLevelUp2 = false;
                self.view.need.cost["item"..i].Text[UI.Text]:TextFormat("<color=red>{0}</color>/{1}", count, condition);
            end
            self.view.need.cost["item"..i]:SetActive(true);
        else
            self.view.need.cost["item"..i]:SetActive(false);
        end
    end
    self.view.up.Text[UI.Text]:TextFormat("升为{0}级", self.level + 1);
    CS.UGUIClickEventListener.Get(self.view.up.gameObject).onClick = function ( object )
        if canLevelUp1 and canLevelUp2 then
            self.manorProductInfo:UpgradeLine(self.line, self.level + 1)
        elseif not canLevelUp1 then
            showDlgError(nil, "未满足条件");
        elseif not canLevelUp2 then
            showDlgError(nil, "缺少升级所需资源");
        end
    end
end

function View:deActive()
    utils.SGKTools.PlayDestroyAnim(self.gameObject)
	return true;
end

function View:listEvent()
	return {
		"MANOR_LEVELUP_SUCCESS",
	}
end

function View:onEvent(event, ...)
	print("onEvent", event, ...);
	if event == "MANOR_LEVELUP_SUCCESS"  then
        DialogStack.Pop()
	end
end

return View;