local View = {};

local type = nil

function View:Start(data)
	self.view = SGK.UIReference.Setup(self.gameObject)
	type = data and data.type or type; 
	if not type then
		self.current = module.TreasureModule.GetLocalRank() or 999;
	else
		local value = module.guildBarbecueModule.GetSelfRank();
		-- ERROR_LOG(sprinttb(value))
		self.current =value.rank[1] or 999;
	end
	
	self.reward = module.TreasureModule.GetReward(type and 2 or nil);
	-- ERROR_LOG(self.current);
	-- ERROR_LOG(sprinttb(self.reward));
	local reward = self:FreshData();
	-- ERROR_LOG(reward);
	-- ERROR_LOG(sprinttb(reward));
	self:FreshItem(reward and reward.reward or {} );
	self:FreshTitle();

	self.view.bg.view.bg.btn.rank[CS.UGUIClickEventListener].onClick = function ()
		if not type then
			module.TreasureModule.GetRank();
			module.TreasureModule.GetUnionRank();
		else
			module.guildBarbecueModule.GetRank();
			module.guildBarbecueModule.GetScore();
		end
	end
	self.view.bg.view.bg.btn.exit[CS.UGUIClickEventListener].onClick = function ()
		SceneStack.EnterMap(10);
	end
	-- exit
end

-- 本次活动公会排名 1


function View:FreshTitle()
	self.view.bg.view.bg.desc.desc.Text[UI.Text].text = "本次活动公会排名 "..self.current
end
function View:FreshItem(data)
	local parent = self.view.bg.view.bg.scroll.content;

	for i=1,3 do

		if data[i] then
			local cfg = utils.ItemHelper.Get(data[i].type,data[i].id);

			if cfg then
				utils.IconFrameHelper.Create(parent["item"..i], {customCfg = cfg,showName=true,showDetail = true,func = function ( obj)
					-- obj.gameObject.transform.localScale = UnityEngine.Vector3(0.6,0.6,0.6);
					obj.gameObject.transform.localScale = UnityEngine.Vector3(0.8,0.8,0.8);
				end})
			else
				parent.gameObject:SeActive(false);
			end
		else
			parent.gameObject:SeActive(false);
		end
	end
end
function View:FreshData()
	local up = nil;
	for i=1,#self.reward do

		if up then
			for j=up,self.reward[i].rank_range do
				if self.current == j then
					return self.reward[i];
				end
			end
		else
			if self.current == i then
				return self.reward[i];
			end
		end
		up = self.reward[i].rank_range;
	end
end

function View:onEvent(event, data)
	-- ERROR_LOG(event);
	if event == "GET_RANK_RESULT" then
		if not module.TreasureModule.GetOpen_Rank()  then
			if not type then
				module.TreasureModule.SetOpen_Rank(true)
				DialogStack.Push("treasureRank",data);
			else
				DialogStack.Push("guild/guildBarbecueRank",data);
			end
			
		end
	end
end
function View:listEvent()
	return{
	"GET_RANK_RESULT",
	}
end


return View;