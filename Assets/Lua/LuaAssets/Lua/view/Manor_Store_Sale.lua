local ManorManufactureModule = require "module.ManorManufactureModule"
local ItemHelper = require "utils.ItemHelper"
local ItemModule = require "module.ItemModule"
local Time = require "module.Time"

local MAX_SOLD = 10;
local View = {};
function View:Start(data)
    self.view = CS.SGK.UIReference.Setup(self.gameObject);
    self.saleView = self.view.top.ScrollView[CS.UIMultiScroller];
    self.itemView = self.view.bottom.ScrollView[CS.UIMultiScroller];
    self.dialog = self.view.dialog;
	self:InitData();
    self:InitView();
end


function View:InitData()
	self.manorProductInfo = ManorManufactureModule.Get();
    self.manorProductInfo:GetProductLineFromServer();
    self.productList = self.manorProductInfo:GetProductList(31);
    self.gathering = false;
    self.sold_count = 0;
	self.saleItem = {};
	self.goodItem = {};
	self.cur_select = 0;
end

function View:InitView()
	CS.UGUIClickEventListener.Get(self.view.title.close.gameObject).onClick = function (obj)
        DialogStack.Pop();
	end
		
	CS.UGUIClickEventListener.Get(self.dialog.pop.gameObject,true).onClick = function (obj)
		self:ClosePop();
    end
	
	self.saleView.RefreshIconCallback = function (obj,idx)
		local item = CS.SGK.UIReference.Setup(obj);
		local info = self.saleItem[idx + 1];
		if info then
			local cfg = ItemHelper.Get(info.consume[1].type, info.consume[1].id);
			-- item.item.newItemIcon[SGK.newItemIcon]:SetInfo(cfg);
			-- item.item.newItemIcon[SGK.newItemIcon].Count = info.consume[1].value;
			-- item.item.newItemIcon.mask.Icon:SetActive(true);	
			item.item.IconFrame:SetActive(true);		
			utils.IconFrameHelper.Create(item.item.IconFrame,{type = info.consume[1].type, id = info.consume[1].id, count = info.consume[1].value});
			item.item.none:SetActive(false);
			item.info.name[UnityEngine.UI.Text]:TextFormat(cfg.name);
			if info.discount and info.discount > 100 and Time.now() < info.end_time then
				item.item.up:SetActive(true);
				item.item.up.Text[UnityEngine.UI.Text].text = (info.discount - 100).."%";
				item.info.price[UnityEngine.UI.Text]:TextFormat("{0}<color=#17FFCDFF>(+{1}%)</color>",math.floor(info.reward[1].value * (info.discount / 100) * self.productLine.effect_gather), (info.discount - 100));
			else
				item.item.up:SetActive(false);
				item.info.price[UnityEngine.UI.Text].text = tostring(math.floor(info.reward[1].value * self.productLine.effect_gather));
			end
		else
			-- item.item.newItemIcon.mask.Icon:SetActive(false);
			-- item.item.newItemIcon[SGK.newItemIcon].quality = 0;
			-- item.item.newItemIcon[SGK.newItemIcon].Count = 0;
			item.item.IconFrame:SetActive(false);
			item.item.none:SetActive(true);	
			item.item.up:SetActive(false);
			item.info.price[UnityEngine.UI.Text].text = "";
			item.info.name[UnityEngine.UI.Text]:TextFormat("暂无");
		end
		if self.productLine.order_limit < MAX_SOLD and idx + 1 == self.saleView.DataCount then
			item.Button:SetActive(true);
			item.info:SetActive(false);
			item.item.lock:SetActive(true);
			CS.UGUIClickEventListener.Get(item.Button.gameObject).onClick = function (obj)
				self:IncreaseSoldCount();
			end
			-- item.item.newItemIcon[SGK.newItemIcon].quality = 0;
		else
			item.Button:SetActive(false);
			item.info:SetActive(true);
			item.item.lock:SetActive(false);
		end
		obj:SetActive(true);
	end

	self.itemView.RefreshIconCallback = function (obj,idx)
		local item = CS.SGK.UIReference.Setup(obj);
		local info = self.goodItem[idx + 1];
		-- item.newItemIcon[SGK.newItemIcon]:SetInfo(info.cfg);
		utils.IconFrameHelper.Create(item.IconFrame,{type = info.cfg.type, id = info.cfg.id});
		if info.discount and info.discount > 100 and Time.now() < info.end_time then
			item.up:SetActive(true);
			item.up.Text[UnityEngine.UI.Text].text = (info.discount - 100).."%";
		else
			item.up:SetActive(false);
		end
		item[UnityEngine.UI.Toggle].isOn = false;
		CS.UGUIClickEventListener.Get(item.gameObject,true).onClick = function (obj)
			if not item[UnityEngine.UI.Toggle].isOn then
				self.cur_select = idx;
				self.dialog.pop:SetActive(true);
				local pos = item.gameObject.transform.position;
				-- self.item_obj = UnityEngine.Object.Instantiate(item.gameObject, self.dialog.pop.layer.gameObject.transform);
				-- self.item_obj.transform.position = pos;
				-- self.item_obj:GetComponent(typeof(UnityEngine.UI.Toggle)).isOn = true;

				self.dialog.pop.button.gameObject.transform.position = pos;
				local local_pos = self.dialog.pop.button.gameObject.transform.localPosition;
				if (idx + 1)%5 == 0 then
					self.dialog.pop.button.gameObject.transform.localPosition = Vector3(local_pos.x - 120, local_pos.y - 58, local_pos.z);
				else
					self.dialog.pop.button.gameObject.transform.localPosition = Vector3(local_pos.x + 100, local_pos.y - 58, local_pos.z);
				end
				
				-- CS.UGUIClickEventListener.Get(self.item_obj).onClick = function (obj)
				-- 	self:ClosePop();
				-- end

				CS.UGUIClickEventListener.Get(self.dialog.pop.button.info.gameObject).onClick = function (obj)
					DialogStack.PushPrefStact("ItemDetailFrame", {id = info.cfg.id,type = info.cfg.type}, self.dialog.pop.content.gameObject)
				end
				CS.UGUIClickEventListener.Get(self.dialog.pop.button.sale.gameObject).onClick = function (obj)
					self:ShowSale(info);
				end
			else
				self:ClosePop();
			end
		end
		obj:SetActive(true);
	end
	self:HandleData();
	self:RefreshItemView();
	self.saleView:IsReset(false);
end

function View:HandleData()
	self.productLine = self.manorProductInfo:GetLine(31);
	if self.productLine == nil then
		print("生产线为空")
		return;
	end
	self.productLine.sortOrder = {};
	local sortOrder = {};
	for k,v in pairs(self.productLine.orders) do
		if v.left_count ~= 0 then
			table.insert(sortOrder,v);
		end
	end
	table.sort(sortOrder,function ( a,b )
		if a.order ~= b.order then
			return a.order < b.order;
		end
		return a.gid < b.gid;
	end)
	self.productLine.sortOrder = sortOrder;
	print("生产线信息", sprinttb(self.productLine))

	local nextTime = 0;
	for k,v in ipairs(self.productLine.sortOrder) do
		local productinfo = self.productList[v.gid]
		if productinfo then
			if k == 1 then
				nextTime = nextTime + (v.left_count - 1) * productinfo.time.max;
			else
				nextTime = nextTime + v.left_count * productinfo.time.max;
			end
		end
	end
	self.alltime = nextTime;
	--self.alltime = math.ceil(nextTime * self.productLine.effect_time);

	local needGather = false;
	for k,v in pairs(self.productLine.orders) do
		if v.gather_count > 0 then
			needGather = true;
			break;
		end
	end
	if needGather then
		print("自动收获")
		self.manorProductInfo:Gather(31);
		return;
	end    
	self:RefreshSaleView();
end

function View:ClosePop()
	self.dialog.pop:SetActive(false);
	local obj = self.itemView:GetItem(self.cur_select);
	obj:GetComponent(typeof(UnityEngine.UI.Toggle)).isOn = false;
	if self.item_obj then
		UnityEngine.GameObject.Destroy(self.item_obj);
		self.item_obj = nil;
	end
	--obj:GetComponent(typeof(UnityEngine.Canvas)).sortingOrder = 1;
end

function View:IncreaseSoldCount()
	CS.UGUIClickEventListener.Get(self.dialog.tip.confirm.gameObject).onClick = function (obj)
		if self.productLine.order_limit >= MAX_SOLD then
			showDlgError(nil, "您的货架已达数量上限（"..MAX_SOLD.."个），无法购买更多货架了");
			return;
		end
		if ItemModule.GetItemCount(90006) < 50 then
			showDlgError(nil, "钻石不足");
			return;
		end
		self.manorProductInfo:UpgradeOrderLimit(31);
		self.dialog.tip:SetActive(false);
	end
	CS.UGUIClickEventListener.Get(self.dialog.tip.cancel.gameObject).onClick = function (obj)
		self.dialog.tip:SetActive(false);
	end
	self.dialog.tip:SetActive(true);
end

function View:ShowSale(info)
	-- self.dialog.sale.item_sale.item.newItemIcon[SGK.newItemIcon]:SetInfo(info.cfg);
	utils.IconFrameHelper.Create(self.dialog.sale.item_sale.item.IconFrame,{type = info.cfg.type, id = info.cfg.id});
	self.dialog.sale.item_sale.info.name[UnityEngine.UI.Text]:TextFormat(info.cfg.name);
	if info.discount and info.discount > 100 and Time.now() < info.end_time then
		self.dialog.sale.item_sale.item.up:SetActive(true);
		self.dialog.sale.item_sale.item.up.Text[UnityEngine.UI.Text].text = (info.discount - 100).."%";
		self.dialog.sale.item_sale.info.price[UnityEngine.UI.Text]:TextFormat("{0}<color=#17FFCDFF>(+{1}%)</color>",math.floor(info.reward[1].value * info.discount / 100), (info.discount - 100));
	else
		self.dialog.sale.item_sale.item.up:SetActive(false);
		self.dialog.sale.item_sale.info.price[UnityEngine.UI.Text].text = tostring(info.reward[1].value);
	end
	local count = 1;
	CS.UGUIClickEventListener.Get(self.dialog.sale.reduce.gameObject).onClick = function (obj)
		if count > 1 then
			count = count - 1;
			self.dialog.sale.count[UnityEngine.UI.Text].text = tostring(count * info.consume[1].value);
		end
	end
	CS.UGUIClickEventListener.Get(self.dialog.sale.plus.gameObject).onClick = function (obj)
		if info.cfg.count >= ((count + 1) * info.consume[1].value) then
			if self.sold_count + count + 1 <= self.productLine.order_limit then
				count = count + 1;
				self.dialog.sale.count[UnityEngine.UI.Text].text = tostring(count * info.consume[1].value);
			else
				showDlgError(self.dialog.sale,"货架已满, 请等待物品售出");
			end
		end
	end
	CS.UGUIClickEventListener.Get(self.dialog.sale.max.gameObject).onClick = function (obj)
		if info.cfg.count >= ((self.productLine.order_limit - self.sold_count) * info.consume[1].value) then
			count = self.productLine.order_limit - self.sold_count;
		elseif info.cfg.count >= info.consume[1].value then
			count = math.floor(info.cfg.count / info.consume[1].value); 
		end
		self.dialog.sale.count[UnityEngine.UI.Text].text = tostring(count * info.consume[1].value);
	end

	CS.UGUIClickEventListener.Get(self.dialog.sale.Button.gameObject).onClick = function (obj)
		if info.cfg.count < (count * info.consume[1].value) then
			showDlgError(nil, "物品数量不足")
			self.dialog.sale:SetActive(false);
			self:ClosePop();
			return;
		end
		if self.sold_count + count > self.productLine.order_limit then
			showDlgError(self.dialog.sale,"货架已满, 请等待物品售出");
			return;
		end
		if count > 0 then
			self.manorProductInfo:StartProduce(31,info.gid,count);
		end
	end
	self.dialog.sale.count[UnityEngine.UI.Text].text = tostring(count * info.consume[1].value);
	self.dialog.sale:SetActive(true);
end

function View:RefreshSaleView()
	self.saleItem = {};
    local sold_count = 0;
	for _,v in ipairs(self.productLine.sortOrder) do
		local productInfo = self.productList[v.gid];
		--price = price + math.floor(prpductInfo.reward[1].value * (productInfo.discount or 100)/100 * v.left_count);
		if v.left_count > 0 then
			sold_count = sold_count + v.left_count;
			for i=1,v.left_count do
				table.insert(self.saleItem, productInfo);
			end
		end
	end 
	self.view.top.Text:SetActive(false);
    self.sold_count = sold_count;
    self.view.top.title.count[UnityEngine.UI.Text].text = sold_count.."/"..self.productLine.order_limit..(self.productLine.order_limit == MAX_SOLD and "(最大)" or "");
	self.saleView.DataCount = self.productLine.order_limit >= MAX_SOLD and self.productLine.order_limit or (self.productLine.order_limit + 1);
end

function View:RefreshItemView()
	self.goodItem = {};
	local list = {};
	for k,v in pairs(self.productList) do
		local info = v;
		info.cfg = ItemHelper.Get(ItemHelper.TYPE.ITEM, v.consume[1].id)
		if info.cfg and info.cfg.count > 0 then
			table.insert(list,info);
		end
	end
	table.sort(list,function ( a,b )
		if a.cfg.quality ~= b.cfg.quality then
			return a.cfg.quality > b.cfg.quality;
		end
		if a.reward[1].value ~= b.reward[1].value then
			return a.reward[1].value > b.reward[1].value
		end
		return a.gid < b.gid;
	end)
	self.goodItem = list;
	self.view.bottom.Text:SetActive(#self.goodItem == 0);
	self.itemView.DataCount = #self.goodItem;
end

function View:Update()
	if self.productLine and self.productLine.next_gather_time and self.productLine.next_gather_time ~= 0  then
		local time = self.productLine.next_gather_time - Time.now();
		--print("time",self.productLine.next_gather_time, Time.now(),time)
		if time == 0 and not self.gathering then
			self.gathering = true;
			self.manorProductInfo:GetProductLineFromServer();
		elseif time < 0 then
			return;
		end
	end
end

function View:deActive()
	for i=#self.dialog,1,-1 do
		if self.dialog[i].active then
			self.dialog[i]:SetActive(false);
			return false;
		end
	end
	--ManorManufactureModule.SetInManorScene(false);
	return true;
end

function View:listEvent()
	return {
		"MANOR_MANUFACTURE_PRODUCT_LINE_CHANGE",
		"MANOR_MANUFACTURE_GATHER_SUCCESS",
		"MANOR_POPULAR_EVENT",
		"MANOR_INCREASE_LINE_ORDER_LIMIT",
		"MANOR_STORE_STALL_SUCCESS",
		"MANOR_STORE_STALL_FAILED",
	}
end

function View:onEvent(event, ...)
	print("onEvent", event, ...);
    if event == "MANOR_MANUFACTURE_PRODUCT_LINE_CHANGE"  then
        self:HandleData();
    elseif event == "MANOR_MANUFACTURE_GATHER_SUCCESS" then
		self.gathering = false;
	elseif event == "MANOR_POPULAR_EVENT" then
		self.productList = self.manorProductInfo:GetProductList(31);
		self:RefreshSaleView();
	elseif event == "MANOR_INCREASE_LINE_ORDER_LIMIT" then
		showDlgError(self.dialog,"货架扩充成功");
	elseif event == "MANOR_STORE_STALL_SUCCESS" then
		self:ClosePop();
		self:RefreshItemView();
		self.dialog.sale:SetActive(false);
	elseif event == "MANOR_STORE_STALL_FAILED" then
		showDlgError(self.dialog, "上架失败");
	end
end

return View;