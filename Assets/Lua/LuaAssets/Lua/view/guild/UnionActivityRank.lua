local View = {};

function View:Close()
	DialogStack.Pop();
end

function View:Start(data)
	-- print("打开");
	self.view = SGK.UIReference.Setup(self.gameObject)

	self.activity_id = data.activity_id;
	self.Period = data.Period;

	self.view.view.closeBtn[UI.Button].onClick:AddListener(function ()
	    DialogStack.Pop();
	end);
	self.view.view.giftBox[CS.UGUIClickEventListener].onClick = function ()
		DialogStack.PushPrefStact("treasureRewardRank",self.activity_id);
	end
	self.localdata = data;

	module.TreasureModule.GetRank(self.activity_id,self.Period,function ( rank_data )
		if not rank_data then
			self.view.view.selfRankItem.gameObject:SetActive(false);
			self.view.view.bg_parent.gameObject:SetActive(false);
			self.view.view.default.gameObject:SetActive(true);

		else
			self.view.view.default.gameObject:SetActive(false);
			self.rank_data = rank_data;
			self:FreshScrollViewItem();

			module.TreasureModule.GetUnionRank(self.activity_id,self.Period,function ( self_rank )
				if self_rank then
					self.view.view.selfRankItem.gameObject:SetActive(true);
					self:FreshSelfItem(self_rank);
				else
					self.view.view.selfRankItem.gameObject:SetActive(false);
				end
			end);
		end
	end);

end

function View:FreshSelfItem(data)
	if data then
		self.view.view.bg_parent.gameObject:SetActive(true);
		self.view.view.selfRankItem.gameObject:SetActive(true);
		self.view.view.default.gameObject:SetActive(false);
	

		-- ERROR_LOG("======自己的公会======",sprinttb(union));
	    local temp = { union_id = data.union_id,score = ( data.rank[2] or 0 ),rank = data.rank[1] }
		self:FreshItem(self.view.view.selfRankItem,temp,data.rank[1]);
	else
		self.view.view.selfRankItem.gameObject:SetActive(false);
	end
end


function View:FreshScrollViewItem()
	self.view.view.bg_parent.gameObject:SetActive(true);
	self.view.view.default.gameObject:SetActive(false);
	self.UIDragIconScript = self.view.view.ScrollView[CS.UIMultiScroller];
	self.UIDragIconScript.RefreshIconCallback = function (obj, idx)
		obj.gameObject:SetActive(true);
		local item = SGK.UIReference.Setup(obj);

		self:FreshItem(item,self.rank_data[idx+1],idx+1);
	end;
	self.UIDragIconScript.DataCount = #self.rank_data >50 and 50 or #self.rank_data;
end
function View:FreshItem(parent,data,idx)
	if not parent or  not data or not idx then return end
	
	parent.rankPlace.Text[UI.Text].text = idx;

	
	parent.value.staticText.Text[UI.Text].text = tostring(data.score or 0);
	coroutine.resume( coroutine.create( function ( ... )
		local unionInfo = module.unionModule.Manage:GetUnion(data.union_id)
		parent.union[UI.Text].text = unionInfo.unionName
	end ) )

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
end

function View:onEvent(event, data)
	
end
function View:listEvent()
	return{
		"GET_RANK_RESULT",
		"CONTAINER_UNION_INFO_CHANGE",
	}
end

return View;