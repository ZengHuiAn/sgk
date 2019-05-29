local View = {}
local mazeConfig = require "config.mazeConfig"
local battle = require "config.battle"
function View:Start(data)
	-- ERROR_LOG("战斗数据",sprinttb(data))
	if not data then return end
	local desc = data.data.desc;
	local title = data.data.title;

	local callback = data.callback;

	local battleid = data.data.battleid;

	self.view = SGK.UIReference.Setup(self.gameObject);

	self.view.bg.title.Text[UI.Text].text = title;
	
	self.view.bg.desc.Text[UI.Text].text = desc;
	self.flag = data.data.flag;
	-- ERROR_LOG("怪物描述",self.flag);

	if self.flag then
		self.view.bg.TipBtn.gameObject:SetActive(true);
		self.view.bg.TipBtn.tips.Text[UI.Text].text = tostring(self.flag);
	else
		self.view.bg.TipBtn.gameObject:SetActive(false);
	end
	CS.UGUIClickEventListener.Get(self.view.bg.exit.gameObject,true).onClick = function (obj)
		DialogStack.Pop()
	end

	CS.UGUIClickEventListener.Get(self.view.bg.closeBtn.gameObject,true).onClick = function (obj)
		DialogStack.Pop()
	end
	-- FormationDialog
	self.view.back[UI.Button].onClick:AddListener(function ( ... )
		DialogStack.Pop()
	end);
	CS.UGUIClickEventListener.Get(self.view.bg.fog.gameObject,true).onClick = function (obj)
		DialogStack.PushPrefStact("FormationDialog")
	end

	CS.UGUIClickEventListener.Get(self.view.bg.startBattle.gameObject,true).onClick = function (obj)
		if callback then
			callback();
		end
	end

	self.UIDragIconScript = self.view.bg.scroll.ScrollView[CS.UIMultiScroller];
	local fights = mazeConfig.GetTeamPveMonsterList(battleid);
	-- ERROR_LOG("战斗配置数据",sprinttb(fights))

	local cfg_data = {};
	
	local index = 0;
	for k,v in pairs(fights) do
		if v then
			index = index + 1;
			for _k,_v in pairs(v) do
				cfg_data[index] = cfg_data[index] or {};
				table.insert(cfg_data[index],_v );
			end
			
		end
	end

	-- ERROR_LOG("战斗配置数据",sprinttb(cfg_data))

	local playinfo = module.playerModule.Get();
	local count = #cfg_data;
	self.UIDragIconScript.DataCount = count;
	if count > 0 then
	    self.UIDragIconScript.RefreshIconCallback = function (obj, idx)
	    	obj.gameObject:SetActive(true);
	    	local item_data = cfg_data[idx+1];
	    	local item = SGK.UIReference.Setup(obj);
	    	local npcinfo = battle.LoadNPC(item_data[1].role_id);
	    	item.root[UI.Image]:LoadSprite("icon/" .. npcinfo.icon)

	    	-- ERROR_LOG("战斗数据怪物---->>",sprinttb(item_data[1]));
	    	item.root.Text[UI.Text].text = "x"..#item_data;
	    	-- ERROR_LOG("类型---->>",type(item_data[1].role_lev));
	    	if item_data[1].role_lev == 0 then
	    		item.root.lev[UI.Text].text = "^."..playinfo.level;
    		else
    			item.root.lev[UI.Text].text = "^."..item_data[1].role_lev;
	    	end
	    	-- print(sprinttb(npcinfo))
	    	item.root.name[UI.Text].text = npcinfo.name;

		end
	end

end






return View;