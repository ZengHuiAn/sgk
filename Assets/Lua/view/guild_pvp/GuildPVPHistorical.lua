local GuildPVPGroupModule = require "guild.pvp.module.group"
local unionConfig = require "config.unionConfig"
local View = {};
function View:Start(data)
	self.view = CS.SGK.UIReference.Setup(self.gameObject)
	self.view.mask[CS.UGUIClickEventListener].onClick = function ()
		DialogStack.Pop();
	end
	self.view.close[CS.UGUIClickEventListener].onClick = function ()
		DialogStack.Pop();
	end
	self.view.title[UI.Text].text = SGK.Localize:getInstance():getValue("biaoti_shangqibangdan_01")
	self.DragIconScript = self.view.ScrollView[CS.UIMultiScroller]
	self.DragIconScript.RefreshIconCallback = (function (go,idx)
		local _view = CS.SGK.UIReference.Setup(go)
		local guild = self.listData[idx+1]
		local info = utils.Container("UNION"):Get(guild.id);
		local cfg = unionConfig.GetGuildBattleRewards(guild.order);
		if cfg then
			_view.ranking[UI.Text].text = cfg.rank_client;
			for i=1,3 do
				local item = _view.reward["item"..i];
				if cfg["reward"..i.."_id"] ~= 0 then
					print("物品", i, cfg["reward"..i.."_type"], cfg["reward"..i.."_id"], cfg["reward"..i.."_value"])
					utils.IconFrameHelper.Create(item,{type = cfg["reward"..i.."_type"], id = cfg["reward"..i.."_id"], count = cfg["reward"..i.."_value"], showDetail = true});
					item:SetActive(true);
				else
					item:SetActive(false)
				end
			end
		end
		-- ERROR_LOG(sprinttb(info))
		if info then
        	_view.name[UI.Text].text = info.unionName
        	_view.value[UI.Text].text = info.unionLevel
        end
        for i = 1,#_view.type do
    		_view.type[i]:SetActive(false)
    	end
        if guild.order <= 3 then
        	_view.type[guild.order]:SetActive(true)
        end
		go:SetActive(true)
	end)
	self.listData = GuildPVPGroupModule.GetGroundGuildList()
	table.sort(self.listData,function (a,b)
		if a.order ~= b.order then
			return a.order < b.order;
		end
		return a.id < b.id;
	end)
	print(sprinttb(self.listData))
	self.DragIconScript.DataCount = #self.listData--初始化数量
end
return View