local View = {};

function View:Close()
	DialogStack.Pop();
end

function View:Start(data)
	-- print("打开");
	self.view = SGK.UIReference.Setup(self.gameObject)
	self.view.view.closeBtn[UI.Button].onClick:AddListener(function ()
	    DialogStack.Pop();
		module.TreasureModule.SetOpen_Rank(nil)
	end);
	self.view.view.giftBox[CS.UGUIClickEventListener].onClick = function ()
		module.TreasureModule.SetOpen_Rank(nil)
		DialogStack.Replace("treasureRewardRank");
	end
	self.localdata = data;
	if  (not data  or #data == 0) then
		-- print("关闭");
		self.view.view.selfRankItem.gameObject:SetActive(false);
		self.view.view.bg_parent.gameObject:SetActive(false);
		self.view.view.default.gameObject:SetActive(true);
		return;
	end
	self.view.view.default.gameObject:SetActive(false);
	-- ERROR_LOG(sprinttb(data));
	self:Init(data);

	-- ERROR_LOG(sprinttb(self.tempdata));
	self.data = data;


	self.self_data = module.TreasureModule.GetSelfRank();

	-- print("查询自己的数据",sprinttb(self.self_data));
	self:FreshSelfItem();
	self:FreshScrollViewItem();
end

function View:FreshSelfItem()
	
	-- ERROR_LOG("======自己的事件======",sprinttb(self.self_data));

	if self.self_data and self.self_data.rank then
		-- ERROR_LOG("======自己的数据======",sprinttb(self.self_data));

		self.view.view.bg_parent.gameObject:SetActive(true);
		self.view.view.selfRankItem.gameObject:SetActive(true);
		self.view.view.default.gameObject:SetActive(false);
		local union = module.unionModule.Manage:GetUnion(self.self_data.union_id)
		-- ERROR_LOG("======自己的公会======",sprinttb(union));
	    local temp = { unionId = self.self_data.union_id,guild = union.unionName,score = ( self.self_data.rank[2] or 0 ),rank = self.self_data.rank}
		self:FreshItem(self.view.view.selfRankItem,temp,self.self_data.rank[1]);
	else
		self.view.view.selfRankItem.gameObject:SetActive(false);
	end
end


function View:FreshScrollViewItem()

	if self.tempdata then
		-- ERROR_LOG("滑动条",sprinttb(self.tempdata));
		self.view.view.bg_parent.gameObject:SetActive(true);
		self.view.view.default.gameObject:SetActive(false);
		self.UIDragIconScript = self.view.view.ScrollView[CS.UIMultiScroller];
		self.UIDragIconScript.RefreshIconCallback = function (obj, idx)
			obj.gameObject:SetActive(true);
		    local item = SGK.UIReference.Setup(obj);

		    self:FreshItem(item,self.tempdata[idx+1],idx+1);
		end;
		self.UIDragIconScript.DataCount = #self.tempdata >50 and 50 or #self.tempdata;
	end
end
function View:FreshItem(parent,data,idx)
	if not parent or  not data or not idx then return end
	parent.rankPlace.Text[UI.Text].text = idx;

	parent.value.staticText.Text[UI.Text].text = tostring(data.score or 0);
	parent.union[UI.Text].text = data.guild

    if tonumber(idx) < 4 then
    	parent.rankPlace.Text.gameObject:SetActive(false);
        parent.rankPlace.Image.gameObject:SetActive(true);
       	parent.rankPlace.Image[CS.UGUISpriteSelector].index = idx-1 or 0;
    end
end

function View:Init(value)
	-- ERROR_LOG(value);
	self.tempdata = nil;
	for k,v in pairs(value) do
	    self.tempdata = self.tempdata or {};
	    local union = module.unionModule.Manage:GetUnion(v.union_id)
	    -- print("公会======",union);
		if union then
		    local temp = { unionId = v.union_id,guild = union.unionName,score = v.score,rank = v.rank}
		    table.insert(self.tempdata, temp);
		end
	end
	-- ERROR_LOG(sprinttb(self.tempdata));
	table.sort( self.tempdata, function (a,b)
		return a.rank <b.rank;
	end )
	-- ERROR_LOG(sprinttb(self.tempdata));
end

function View:OnDestory()
	module.TreasureModule.SetOpen_Rank(nil)
end

function View:onEvent(event, data)
	-- ERROR_LOG(event,"事件");
	if event == "CONTAINER_UNION_INFO_CHANGE" then
		-- print("查询到公会");
		self:Init(self.localdata);
		self:FreshScrollViewItem();
	elseif event == "GET_RANK_SELF_RESULT" then
		-- print("查询数据");

		if data then
			-- print("查询到自己的");
			self.self_data = data
			self:FreshSelfItem();
		else
			self.view.view.selfRankItem.gameObject:SetActive(false);
		end
	elseif event == "GET_RANK_RESULT" then
		self:Init(data);
		self:FreshScrollViewItem();
	end
end
function View:listEvent()
	return{
		"GET_RANK_SELF_RESULT",
		"GET_RANK_RESULT",
		"CONTAINER_UNION_INFO_CHANGE",
	}
end

return View;