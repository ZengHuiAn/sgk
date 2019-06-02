local ManorManufactureModule = require "module.ManorManufactureModule"
local ItemModule = require "module.ItemModule"
local Time = require "module.Time"
local ItemHelper = require "utils.ItemHelper"
local heroModule = require "module.HeroModule"
local ManorModule = require "module.ManorModule"
local TipConfig = require "config.TipConfig"
local View = {};

function View:Start(data)
	self.root = CS.SGK.UIReference.Setup(self.gameObject)
	self.view = self.root.view;
	self.tabelview = self.view.bottom.ScrollView[CS.UIMultiScroller];
	self.material = self.view.top.content;
	self.dialog = self.root.dialog;
	self.btn_start = self.view.bottom.complete;
	self.line = data and data.line or self.savedValues.productline or 1;
	self.init_item = data and data.product_id or 0;
	self.curdoing = 0;
	self:InitData();
	if data and data.callback then
        data.callback();
    end
end

function View:InitData()
	--ManorManufactureModule.SetInManorScene(true);
	self.manager = heroModule.GetManager();
	self.manorInfo = ManorManufactureModule.Get();
	self.manorInfo:CheckWorkerProperty();
	self.manorConfig = ManorModule.LoadManorInfo(self.line, 2);
	self.manorLineConfig = ManorModule.GetManorLineConfig();
	self.manorInfo:GetProductLineFromServer();
    self.noWorker = false;
	self.canWork = true;
	self:InitView();
	self:SwitchProductLine(self.line);
end

function View:GetConfig(data)
	local cfg = ItemHelper.Get(data.type,data.id);
	assert(cfg,"item not find "..data.id);
	return cfg;
end

function View:OnDestroy()
	self.savedValues.productline = self.line;
end

function View:HandleData(productlist,onlyRecommend)
	
	self.productlist = {};
	self.productstate = {}; --0 材料条件不满足 1 满足制作条件 -1 图纸已经制作过
	self.productstate[0] = {};
	self.productstate[0].state = 0;
	self.productIDtoGid = {};
	self.productIDtoGid[0] = 0;
	self.dependIDtoGid = {};

	-- setmetatable(self.productIDtoGid, {__newindex = function ( t,k,v )
	-- 	print("~~~~产物重复~~~~",k,v);
	-- end})

	self.productIDtoGid, self.dependIDtoGid = ManorManufactureModule.GetProductAndDependIndex();
	for j,v in pairs(productlist) do
		if v.type ~= 2 or ItemModule.GetItemCount(v.reward[1].id) == 0 then
			-- if self.productlist[v.show_type] == nil then
			-- 	self.productlist[v.show_type] = {};
			-- end
            -- table.insert(self.productlist[v.show_type], v);
            if self.productlist[101] == nil then
				self.productlist[101] = {};
            end
            
            table.insert(self.productlist[101], v);

			if self.productlist[100] == nil then
				self.productlist[100] = {};
			end

			local count = self:GetMaterialFulfilCount(v.consume);
			if self.productstate[v.gid] == nil then
				self.productstate[v.gid] ={};
			end
			if self.productline and self.productline.orders[v.gid] then
				self.productstate[v.gid].state = 2;
				table.insert(self.productlist[100], v);
			elseif count == #(v.consume) then
				if v.type ~= 2 then
					if v.depend_item and ItemModule.GetItemCount(v.depend_item) > 0 or v.depend_item == 0 then
						self.productstate[v.gid].state = 1;
						table.insert(self.productlist[100], v);
					else
						self.productstate[v.gid].state = 0;
					end
				elseif ItemModule.GetItemCount(v.reward[1].id) == 0 then
					table.insert(self.productlist[100], v);
					self.productstate[v.gid].state = 1;
				else
					self.productstate[v.gid].state = -1;
				end
			else
				self.productstate[v.gid].state = 0;
			end
			self.productstate[v.gid].consume_count = count;
		elseif  v.type == 2 and ItemModule.GetItemCount(v.reward[1].id) > 0 then
			print(v.gid,v.reward[1].id, "已经研究")
		else
			print(v.gid,v.reward[1].id, "排除")
		end
	end
	print("self.productstate",sprinttb(self.productstate))
end

function View:SortList()
	--排序
	for k,v in pairs(self.productlist) do
		table.sort(v,function (a,b)
			if (self.productstate[a.gid].count or 0) ~= (self.productstate[b.gid].count or 0) then
				return (self.productstate[a.gid].count or 0) > (self.productstate[b.gid].count or 0) ;
			end
			if (self.productstate[a.gid].left_count or 0) ~= (self.productstate[b.gid].left_count or 0) then
				return (self.productstate[a.gid].left_count or 0) > (self.productstate[b.gid].left_count or 0) ;
			end

			if self.productstate[a.gid].state ~= self.productstate[b.gid].state then
				return self.productstate[a.gid].state > self.productstate[b.gid].state;
			end
			
			-- if a.material_type ~= b.material_type then
			-- 	if a.material_type == self.manorLineConfig[self.line].cfg.material_type then
			-- 		return true;
			-- 	end
			-- 	if b.material_type == self.manorLineConfig[self.line].cfg.material_type then
			-- 		return false;
			-- 	end
			-- end

			if self:GetConfig(a.reward[1]).quality ~= self:GetConfig(b.reward[1]).quality  then
				return self:GetConfig(a.reward[1]).quality > self:GetConfig(b.reward[1]).quality
			end

			if self.productstate[a.gid].consume_count ~= self.productstate[b.gid].consume_count then
				return self.productstate[a.gid].consume_count > self.productstate[b.gid].consume_count
			end

			return a.gid < b.gid
		end)
	end
end

function View:InitView()
	self.tabelview.RefreshIconCallback = function ( obj, idx )
		self:updateProductItem(obj, idx);
	end
	
	CS.UGUIClickEventListener.Get(self.btn_start.gameObject).onClick = function ( object )
		if not self.canWork then
			return;
		end
		if self.noWorker then
			showDlgError(nil, "没有工作人员");
			return;
		end
		if self.productstate[self.curSelect].left_count ~= nil and self.productstate[self.curSelect].left_count > 0 then
			print("加速")
			-- SetButtonStatus(true, self.btn_start);
			self:ShowCompleteDialog();
		elseif self.productstate[self.curSelect].count ~= nil and self.productstate[self.curSelect].count > 0 then
			print("收获")
			SetButtonStatus(false, self.btn_start);
			self.btn_start.gather.bg[CS.UnityEngine.UI.Image].material = self.btn_start[CS.UnityEngine.MeshRenderer].materials[0];
			self.manorInfo:Gather(self.line);
		elseif self.productstate[self.curSelect].state == 1 then
			for k,v in pairs(self.productline.orders) do
				if v and v.gather_count > 0 then
					local productInfo = self.LineInfo[v.gid];
					local productCfg = self:GetConfig(productInfo.reward[1]);
					if self.line == 1 then
						self.dialog.tip.Text[CS.UnityEngine.UI.Text]:TextFormat("{0}已研究完成，是否收取？", productCfg.name);
					else
						self.dialog.tip.Text[CS.UnityEngine.UI.Text]:TextFormat("{0}已制作完成，是否收取？", productCfg.name);
					end
					
					CS.UGUIClickEventListener.Get(self.dialog.tip.confirm.gameObject).onClick = function ( object )
						self.manorInfo:Gather(self.line);
						self.manorInfo:StartProduce(self.line,self.curSelect);
						self.dialog.tip.gameObject:SetActive(false)
                    end
                    self.dialog.tip.icon:SetActive(false);
					self.dialog.tip.gameObject:SetActive(true);
					return;
				end
			end
			print("制作")
			self.manorInfo:StartProduce(self.line,self.curSelect);
		else
			showDlgError(nil, "材料不足");
		end
	end


    CS.UGUIClickEventListener.Get(self.view.title.close.gameObject).onClick = function ( object )
		DialogStack.Pop();
	end
	CS.UGUIClickEventListener.Get(self.root.BG.gameObject, true).onClick = function (obj)
        DialogStack.Pop();
	end
	CS.UGUIClickEventListener.Get(self.view.top.help.gameObject).onClick = function ( object )
		utils.SGKTools.ShowDlgHelp(TipConfig.GetAssistDescConfig(55002 + self.line).info, nil, self.dialog)
	end
	CS.UGUIClickEventListener.Get(self.material.product.item.gameObject).onClick = function ( object )
		if self.curdoing ~= 0 and self.curSelect == self.curdoing then
			print("取消")
			self:ShowCancelOrder(self.curdoing);
		end
	end
	
	-- CS.UGUIClickEventListener.Get(self.view.left.gameObject).onClick = function ( object )
	-- 	if not self.view.left[CS.UnityEngine.UI.Button].interactable then
	-- 		return;
	-- 	end
	-- 	self:SwitchProductLine(self.line - 1);
	-- end

	-- CS.UGUIClickEventListener.Get(self.view.right.gameObject).onClick = function ( object )
	-- 	if not self.view.right[CS.UnityEngine.UI.Button].interactable then
	-- 		return;
	-- 	end
	-- 	self:SwitchProductLine(self.line + 1);
	-- end


end
--获取材料满足数量
function View:GetMaterialFulfilCount(consume)
	local count = 0;
	for _,k in ipairs(consume) do
		if ItemModule.GetItemCount(k.id) >= k.value then
			count = count + 1;
		end
	end
	return count;
end

function View:ShowCancelOrder(gid)
	local LineInfo = self.manorInfo:GetProductList(self.line);
	local productInfo = LineInfo[gid];
	if productInfo then
		for i=1,4 do
			local item = self.dialog.cancel.item["item"..i];
			if productInfo.consume[i] then
				item:SetActive(true);
				utils.IconFrameHelper.Create(item,{type = productInfo.consume[i].type, id = productInfo.consume[i].id, count = math.floor(productInfo.consume[i].value * 0.8)});
			else
				item:SetActive(false);
			end
		end
		CS.UGUIClickEventListener.Get(self.dialog.cancel.confirm.gameObject).onClick = function (obj)
			if self.curdoing ~= 0 then
				self.manorInfo:CancelOrder(self.line, self.curdoing, 1);
			else
				showDlgError("制作已完成")
			end
			self.dialog.cancel:SetActive(false);
		end
		self.dialog.cancel:SetActive(true);
	end
end

function View:ShowCompleteDialog()
	self.dialog.tip.Text[CS.UnityEngine.UI.Text]:TextFormat("立刻完成该物品制作，需要消耗               是否继续？");
	CS.UGUIClickEventListener.Get(self.dialog.tip.confirm.gameObject).onClick = function (obj)
		if self.productstate[self.curSelect].left_count ~= nil and self.productstate[self.curSelect].left_count > 0 then
			local time = self.productline.next_gather_time - Time.now();
			local count = math.ceil(time/60);
			if ItemModule.GetItemCount(90006) >= count then
				self.manorInfo:Speedup(self.line,100);
			else
				showDlgError(nil, "钻石不足");
			end
			
		else
			print("制作")
			self.manorInfo:StartProduce(self.line,self.curSelect);
		end
		self.dialog.tip.gameObject:SetActive(false);
	end
	self.dialog.tip:SetActive(true)
end

function View:SwitchProductLine(line)
	if line < 1 or line > 4 then
		return;
	end

	self.LineInfo = self.manorInfo:GetProductList(line);
	print("self.LineInfo",sprinttb(self.LineInfo))
	if self.LineInfo == nil  then
		showDlgError(nil,"生产线数据未找到")
		return;
	end

	-- self.view.left[CS.UnityEngine.UI.Button].interactable = not (line == 1);
	-- self.view.right[CS.UnityEngine.UI.Button].interactable = not (line == 4);

	self.line = line;
	self.isRefresh = true;
	self.curSelect = 0;
	self.curIndex = 1;
	self.quality = 101;
	self.productline = self.manorInfo:GetLine(line)
	self:HandleData(self.LineInfo)
	print("self.productline", sprinttb(self.productline));
	print("self.productlist", sprinttb(self.productlist));

	for k,v in pairs(self.productline.orders) do
		self.productstate[k].count = v.gather_count;
		self.productstate[k].left_count = v.left_count;
    end
    
	self:SortList();
	self.view.title.name[CS.UnityEngine.UI.Text].text = SGK.Localize:getInstance():getValue(self.manorConfig.title);
	self.view.top.effect.Text[CS.UnityEngine.UI.Text]:TextFormat("<color=#FFD731FF>研究时间缩短为：{0}%</color>", math.floor(self.productline.effect_time * 100)); 

	--自动选择应该选中的产品
	if self.init_item ~= 0 then
        for i,j in ipairs(self.productlist[self.quality]) do
            if j.reward[1].id == self.init_item then
                self.init_item = 0;                    
                self:selectItem(i,false,true);
                self:refreshTableView(self.quality,true);
                print("移动到", i)
                --self.view.product.ScrollView.Viewport.Content.gameObject.transform:DOLocalMove(Vector3(0, math.min((i - 1) * 120, math.max(#self.productlist[k] * 120 - 371.8, 0)),0), 0.2):Play()
                return;
            end
        end
	end

	self:selectItem(1,false,true);
	self:refreshTableView(self.quality,true);
	
end

function View:refreshTableView(quality,check,index)	
	if self.line == 1 and check and self.productlist[quality] ~= nil then
		local remove = {};
		for i,v in ipairs(self.productlist[quality]) do
			if ItemModule.GetItemCount(v.reward[1].id) > 0 and v.type == 2 then
				table.insert(remove,i);
			end
		end

		for i,v in ipairs(remove) do
			table.remove(self.productlist[quality],v - (i - 1))
		end
	end

	local productlist = self.productlist[quality];
	print("产品列表",index, quality, sprinttb(productlist))

	if productlist == nil or #productlist == 0 then
		print("产品列表为空")
		self.tabelview.DataCount = 0;
		self.view.product.Text:SetActive(true);
        if self.line == 1 then
            self.view.bottom.Text[UnityEngine.UI.Text]:TextFormat("图纸已研究完毕",str);
        else
            self.view.bottom.Text[UnityEngine.UI.Text]:TextFormat("暂无可制作的物品",str);
        end
	else
		self.view.bottom.Text:SetActive(false);		
		if check ~= nil and check then
			if self.tabelview.DataCount ~= #productlist then
				self.tabelview.DataCount = #productlist;
			end
			for i,v in ipairs(productlist) do
				self.productstate[v.gid].consume_count = self:GetMaterialFulfilCount(v.consume);
				if self.productstate[v.gid].consume_count == #(v.consume)  and (ItemModule.GetItemCount(v.depend_item) > 0 or v.depend_item == 0) then
					self.productstate[v.gid].state = 1;
				else
					self.productstate[v.gid].state = 0;
				end
			end
		end
	end


	if index and index > 0 then
		local obj = self.tabelview:GetItem(index - 1);
		if obj then
			self:updateProductItem(obj, index - 1);
		end
	else
		self.tabelview:ItemRef();
	end
end

function View:updateProductItem(obj, idx)
    local productInfo = self.productlist[self.quality][idx + 1];
    local productCfg = self:GetConfig(productInfo.reward[1]);
    local item = CS.SGK.UIReference.Setup(obj);
    item[CS.UnityEngine.UI.Toggle].isOn = (self.curIndex == idx + 1);	
    -- item.check:SetActive(self.curIndex == idx + 1);
    -- item[CS.UnityEngine.UI.Toggle].group = self.view.product.ScrollView[CS.UnityEngine.UI.ToggleGroup];    

    -- item.newItemIcon[SGK.newItemIcon]:SetInfo(productCfg)
    -- item.newItemIcon[SGK.newItemIcon].Count = productInfo.reward[1].value;
	local count = productInfo.reward[1].value;
    if productInfo.discount and Time.now() < productInfo.end_time then
        item.up:SetActive(true);
        item.up.Text[CS.UnityEngine.UI.Text].text = (productInfo.discount - 100).."%";
		-- item.newItemIcon[SGK.newItemIcon].Count = math.floor(productInfo.reward[1].value * productInfo.discount / 100);
		count = math.floor(productInfo.reward[1].value * productInfo.discount / 100)
    else
        item.up:SetActive(false);
	end
	
	utils.IconFrameHelper.Create(item.IconFrame,{type = productCfg.type, id = productCfg.id, count = count});
	
    if self.curdoing ~= 0 and self.curdoing == productInfo.gid then
        item.doing:SetActive(true);
    else
        item.doing:SetActive(false);        
    end
    if self.productstate[productInfo.gid].count ~= nil and self.productstate[productInfo.gid].count ~= 0 then
        item.gather:SetActive(true);
    else
        item.gather:SetActive(false);
    end

    CS.UGUIClickEventListener.Get(item.gameObject, true).onClick = function ( obj )	
        print("拥有",  ItemModule.GetItemCount(productCfg.id))
        self:selectItem(idx + 1);
    end
    -- item[CS.UnityEngine.UI.Toggle].onValueChanged:AddListener(function ( value )
    --     item.checkt:SetActive(value);
    -- end)
    obj:SetActive(true);
end

function View:GetTime(time,format)
	local time_str = "";
	if format == 1 then		
		if time < 60 then
			time_str = time.."秒";
		elseif time < 3600 then
			time_str = math.floor(time/60).."分"..math.floor(time%60).."秒";
		else --if productInfo.time.max < 86400  then
			time_str = math.floor(time/3600).."小时"..math.floor((time%3600)/60).."分";
		end
	elseif format == 2 then
		local hour,sec = 0;
		local min = 0;
		if time < 60 then
			sec = time;
		elseif time < 3600 then
			min = math.floor(time/60);
			sec = math.floor(time%60);
		else --if productInfo.time.max < 86400  then
			hour = math.floor(time/3600);
			min = math.floor((time%3600)/60);
			sec =  math.floor(time%60);
		end
		time_str = string.format("%02d"..":".."%02d"..":".."%02d",hour,min,sec);
	end
	return time_str;
end

-- function View:updateProduct()
-- 	for k,v in pairs(self.productline.orders) do
-- 		if v.left_count > 0 then
-- 			local cfg = self:GetConfig(self.manorInfo:GetProductList(self.line)[v.gid].reward[1]);
-- 			self.material.product.Image[CS.UnityEngine.UI.Image].color = ItemHelper.QualityColor(cfg.quality);
-- 			self.material.product.icon.gameObject:SetActive(true);
-- 			self.material.product.icon[CS.UnityEngine.UI.Image]:LoadSprite("icon/"..cfg.icon);
-- 			return;
-- 		end
-- 	end
-- 	local _,color = UnityEngine.ColorUtility.TryParseHtmlString('#AEAEAEFF');
-- 	self.material.product.icon.gameObject:SetActive(false);
-- 	self.material.product.Image[CS.UnityEngine.UI.Image].color = color;
-- end

function View:selectItem(index, cost,init)
	self.curIndex = index;
	--print("self.productlist", sprinttb(self.productlist))
	if self.productlist[self.quality] == nil or self.productlist[self.quality][index] == nil then
        self.material:SetActive(false);
        self.view.top.Text:SetActive(true);
		return;
	else
        self.material:SetActive(true);
        self.view.top.Text:SetActive(false);        
	end
    
	local productInfo = self.productlist[self.quality][index];
	self.view.bottom.info.need[CS.UnityEngine.UI.Text].color =  {r = 0, g = 219/255, b = 196/255, a = 1};

	if productInfo.depend_item ~= 0 then
		self.view.bottom.info.need[CS.UnityEngine.UI.Text]:TextFormat("需要：{0}",ItemModule.GetConfig(productInfo.depend_item).name);
		if ItemModule.GetItemCount(productInfo.depend_item) <= 0 then
			self.view.bottom.info.need[CS.UnityEngine.UI.Text].color = CS.UnityEngine.Color.red;
			self.view.bottom.need.Text[UnityEngine.UI.Text].text = "<color=#FF2728FF>0</color>/1";
		else
			self.view.bottom.need.Text[UnityEngine.UI.Text].text = "1/1";
		end
		self.view.bottom.need:SetActive(true);
		utils.IconFrameHelper.Create(self.view.bottom.need.IconFrame,{type = 41, id = productInfo.depend_item, count = 1, showDetail = true});
		self.view.bottom.complete.transform.localPosition = Vector3(-140, -138, 0);
	else
		self.view.bottom.need:SetActive(false);
		self.view.bottom.info.need[CS.UnityEngine.UI.Text]:TextFormat("需要：无");
		self.view.bottom.complete.transform.localPosition = Vector3(-180, -138, 0);
	end

	local productCfg = self:GetConfig(productInfo.reward[1]);
    self.view.bottom.info.title.Text[CS.UnityEngine.UI.Text]:TextFormat(productCfg.name);

	self.curSelect = productInfo.gid;
	print("productInfo",sprinttb(productInfo));
	print("productstate", sprinttb(self.productstate[self.curSelect]));

	local materials = self.material;
	--local _,color = UnityEngine.ColorUtility.TryParseHtmlString('#AEAEAEFF');
	local count = 0;
	for i=1,4 do
		if productInfo.consume[i] ~= nil then
			local materialCfg = self:GetConfig(productInfo.consume[i]);
			-- materials["item"..i].newItemIcon[SGK.newItemIcon]:SetInfo(materialCfg);
			-- materials["item"..i].newItemIcon[SGK.newItemIcon].Count = productInfo.consume[i].value;
			utils.IconFrameHelper.Create(materials["item"..i].IconFrame,{type = materialCfg.type, id = materialCfg.id, count = productInfo.consume[i].value, showDetail = true});

			if ItemModule.GetItemCount(materialCfg.id) < productInfo.consume[i].value then
				materials["item"..i].Text[CS.UnityEngine.UI.Text]:TextFormat("<color=#FF2728FF>{0}</color>/{1}",ItemModule.GetItemCount(materialCfg.id), productInfo.consume[i].value);
            else
				materials["item"..i].Text[CS.UnityEngine.UI.Text]:TextFormat("{0}/{1}",ItemModule.GetItemCount(materialCfg.id), productInfo.consume[i].value);
			end

			-- materials["item"..i].cost[CS.UnityEngine.UI.Image]:LoadSprite("icon/"..materialCfg.icon);
			-- materials["item"..i].cost.Text[CS.UnityEngine.UI.Text].text = "- "..productInfo.consume[i].value;
			-- if cost and self.curdoing ~= 0 and self.curSelect == self.curdoing then
			-- 	materials["item"..i].cost:SetActive(true)
			-- 	materials["item"..i].cost.transform:DOLocalMove(Vector3(0,70,0),1.2);
			-- 	materials["item"..i].cost.Text[CS.UnityEngine.UI.Text]:DOFade(0,1.2):SetEase(CS.DG.Tweening.Ease.InQuart);
			-- 	materials["item"..i].cost[CS.UnityEngine.UI.Image]:DOFade(0,1.2):SetEase(CS.DG.Tweening.Ease.InQuart):OnComplete(function ()
			-- 		materials["item"..i].cost:SetActive(false);
			-- 		materials["item"..i].cost.transform.localPosition = Vector3(0,0,0);
			-- 		materials["item"..i].cost[CS.UnityEngine.UI.Image]:DOFade(1,0.1);
			-- 		materials["item"..i].cost.Text[CS.UnityEngine.UI.Text]:DOFade(1,0.1);
			-- 	end);
			-- end

			count = count + 1;
			-- CS.UGUIClickEventListener.Get(materials["item"..i].newItemIcon.gameObject).onClick = function (obj)
			-- 	DialogStack.PushPrefStact("ItemDetailFrame", {id = materialCfg.id,type = materialCfg.type, InItemBag = 2},self.view.gameObject)
			-- end
            materials["item"..i]:SetActive(true);
        else
            materials["item"..i]:SetActive(false);
		end
	end

	self.view.bottom.info.des.Text[CS.UnityEngine.UI.Text].text = productCfg.info;
	if self.line ~= 1 then
		self.view.bottom.info.des.time[CS.UnityEngine.UI.Text]:TextFormat("制作时间：");
	else
		self.view.bottom.info.des.time[CS.UnityEngine.UI.Text]:TextFormat("研究时间：");
	end

	utils.IconFrameHelper.Create(self.material.product.item.IconFrame,{type = productCfg.type, id = productCfg.id, count = math.floor(productInfo.reward[1].value * productInfo.discount / 100)});
	if self.curdoing ~= 0 and self.curSelect == self.curdoing then
		self:updateProductSlider();
		self.material.product.item.info:SetActive(true);
		self.material.product.Text:SetActive(true);
		self.material.product.item[CS.UGUIClickEventListener].interactable = true;
	else
		self.material.product.item.info:SetActive(false);
		self.material.product.Text:SetActive(false);
		self.view.bottom.info.des.time.num[CS.UnityEngine.UI.Text].text = self:GetTime(math.ceil(productInfo.time.max * self.productline.effect_time),2);        
		self.material.product.item[CS.UGUIClickEventListener].interactable = false;
	end
	self:updateButtonState(productInfo.gid,productInfo.type);
end

function View:updateProductSlider()
	self.material.product.item.info.mask.Slider[CS.UnityEngine.UI.Slider]:DOPause();
	local time = self.productline.next_gather_time - Time.now();
	self.material.product.item.info.mask.Slider[CS.UnityEngine.UI.Slider].value = 1 - time/(self.productline.next_gather_time - self.productline.order_start_time);
	self.material.product.item.info.mask.Slider[CS.UnityEngine.UI.Slider]:DOValue(1,time):SetEase(CS.DG.Tweening.Ease.Linear):OnComplete(function ( ... )
		self.material.product.item.info:SetActive(false);
		self.material.product.Text:SetActive(false);
	end)
end

function View:updateButtonState(gid,type)
	local curSelect = gid or self.curSelect;

	if self.line == 1 then
		self.btn_start.start.Text[CS.UnityEngine.UI.Text]:TextFormat("开始研究");
	else
		self.btn_start.start.Text[CS.UnityEngine.UI.Text]:TextFormat("开始制作");
    end

	local start_active = true;
	local gather_active = false;
	local fast_active = false;
	local interactable = true;
   
	--制作
	if self.productstate[curSelect].state == 1 then
		interactable = true;
	else
		interactable = false;
	end
	--收获,加速,工作中
	if self.productstate[curSelect].count and self.productstate[curSelect].count > 0 then
		self.btn_start.gather.Text[CS.UnityEngine.UI.Text]:TextFormat("收获");	
		gather_active = true;
		start_active = false;
		interactable = true;	
	elseif self.productstate[curSelect].left_count ~= nil and self.productstate[curSelect].left_count > 0 then
		start_active = false;
		fast_active = true
		interactable = true;
	elseif self.productline.next_gather_time > Time.now() then
		if self.line == 1 then
			self.btn_start.gather.Text[CS.UnityEngine.UI.Text]:TextFormat("研究中");
		else
			self.btn_start.gather.Text[CS.UnityEngine.UI.Text]:TextFormat("制作中");
		end
		interactable = false;
	end
	if gather_active and not interactable then
		self.btn_start.gather.bg[UnityEngine.UI.Image].material = self.btn_start[CS.UnityEngine.MeshRenderer].materials[0];
	else
		self.btn_start.gather.bg[UnityEngine.UI.Image].material = nil;
	end
	if fast_active and not interactable then
		self.btn_start.fast.bg[UnityEngine.UI.Image].material = self.btn_start[CS.UnityEngine.MeshRenderer].materials[0];
	else
		self.btn_start.fast.bg[UnityEngine.UI.Image].material = nil;
	end
	if start_active and not interactable then
		self.btn_start.start.bg[UnityEngine.UI.Image].material = self.btn_start[CS.UnityEngine.MeshRenderer].materials[0];
	else
		self.btn_start.start.bg[UnityEngine.UI.Image].material = nil;
	end
	self.btn_start.gather:SetActive(gather_active);
	self.btn_start.fast:SetActive(fast_active);
	self.btn_start.start:SetActive(start_active);
	self.btn_start[CS.UGUIClickEventListener].interactable = interactable;
	self.canWork = interactable;
end

function View:playEffect(effectName, node, position, loop, sortOrder, func)
    SGK.ResourcesManager.LoadAsync(self.view[SGK.UIReference], "prefabs/effect/UI/".. effectName..".prefab", function(prefab)
        local o = prefab and UnityEngine.GameObject.Instantiate(prefab, node.transform)
        if o then
            local transform = o.transform;
            transform.localPosition = position or Vector3.zero;
            --transform.localRotation = Quaternion.identity
            SGK.ParticleSystemSortingLayer.Set(o, sortOrder or 1)
            if not loop then
                local _obj = o:GetComponentInChildren(typeof(UnityEngine.ParticleSystem))
                UnityEngine.Object.Destroy(o, _obj.main.duration)
            end
            if func then
                func(o)
            end
        end
    end)
end

function View:listEvent()	
	return {
		"MANOR_MANUFACTURE_PRODUCT_LINE_CHANGE",
		"ITEM_INFO_CHANGE",
		"MANOR_MANUFACTURE_GATHER_SUCCESS",
		"MANOR_MANUFACTURE_SPEEDUP_FAILED",
		"MANOR_WORKSTATION_SWITCH",
		"MANOR_POPULAR_EVENT",
		"MANOR_MANUFACTURE_SPEEDUP_SUCCESS"
	}
end

function View:Update()
	if self.productline and self.productline.next_gather_time ~= 0 and self.isRefresh then
		local time = self.productline.next_gather_time - Time.now();
		if time == 0 then
			self.isRefresh = false;
			--print("请求服务器")
			self.manorInfo:GetProductLineFromServer();
			if self.dialog.tip.gameObject.activeSelf then
				self.dialog.tip.gameObject:SetActive(false)
			end
		elseif time < 0 then
			return;
		end
		self.dialog.tip.icon.count[CS.UnityEngine.UI.Text].text = tostring(math.ceil(time/60));

		if self.curdoing ~= 0 and self.curSelect == self.curdoing then
            self.view.bottom.info.des.time.num[CS.UnityEngine.UI.Text].text = self:GetTime(time,2);
            self.btn_start.fast.count[CS.UnityEngine.UI.Text].text = tostring(math.ceil(time/60));
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
	utils.SGKTools.PlayDestroyAnim(self.gameObject)
	return true;
end

function View:onEvent(event, ...)
	print("onEvent", event, ...);
	local data = ...;
	if event == "MANOR_MANUFACTURE_PRODUCT_LINE_CHANGE" then
		self.isRefresh = true;
		self.productline = self.manorInfo:GetLine(self.line);
		self.curdoing = 0;
		local canGather = 0;
		for k,v in pairs(self.productline.orders) do
			if v and v.left_count > 0 then
				self.curdoing = v.gid;
			end
			if v and v.gather_count > 0 then
				canGather = v.gid;
			end
		end
		--print("生产线信息",sprinttb(self.productline));
		for k,v in pairs(self.productstate) do
			if self.productline.orders[k] ~= nil then
				v.count = self.productline.orders[k].gather_count;
				v.left_count = self.productline.orders[k].left_count;
			else
				v.count = 0;
				v.left_count = 0;
			end
		end
		--print("生产线状态",sprinttb(self.productstate));
		--self:SortList();

		if data and data.type == 1 then --开始生产返回
			print("开始生产返回")
			DialogStack.Pop();
			-- self:selectItem(self.curIndex, true);
			-- self:refreshTableView(self.quality,true, self.curIndex);
		else
			self:refreshTableView(self.quality,true);
			self:selectItem(self.curIndex,false,true);			
		end
		
		self:updateButtonState()
        self.view.top.effect.Text[CS.UnityEngine.UI.Text]:TextFormat("<color=#FFD731FF>研究时间缩短为：{0}%</color>", math.floor(self.productline.effect_time * 100)); 
		print("productline",sprinttb(self.productline))
	elseif event == "ITEM_INFO_CHANGE" then
		self:selectItem(self.curIndex);
	elseif event == "MANOR_MANUFACTURE_GATHER_SUCCESS" then
		SetButtonStatus(true, self.btn_start);
		self.btn_start.gather.bg[CS.UnityEngine.UI.Image].material = nil;
		-- showDlgError(nil, "收获成功");
	elseif event == "MANOR_MANUFACTURE_SPEEDUP_FAILED" then
		showDlgError(nil, "加速失败");
		SetButtonStatus(true, self.btn_start);
		self.btn_start.fast.bg[CS.UnityEngine.UI.Image].material = nil;
	elseif event == "MANOR_MANUFACTURE_SPEEDUP_SUCCESS" then
		SetButtonStatus(true, self.btn_start);
		self.btn_start.fast.bg[CS.UnityEngine.UI.Image].material = nil;
	elseif event == "MANOR_WORKSTATION_SWITCH" then
		self.init_item = data.product_id;
		self:SwitchProductLine(data.line);
		self:selectItem(self.curIndex);
	elseif event == "MANOR_POPULAR_EVENT" then
		local LineInfo = self.manorInfo:GetProductList(self.line);
		self:HandleData(LineInfo);
		for i,v in ipairs(self.productlist[self.quality]) do
			if v.gid == data.gid then
				self:refreshTableView(self.quality,false, i);
				break;
			end
		end
	end
end



return View