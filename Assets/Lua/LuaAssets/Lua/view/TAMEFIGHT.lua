local guildModule = require "guild.pvp.module.group"
local View = {};
function View:Start(data)
	self.view = CS.SGK.UIReference.Setup(self.gameObject)
    self:loadlist()
    self.view.applyBtn[CS.UGUIClickEventListener].onClick = function ()
    	guildModule.Join()
    end
    guildModule.QueryHeros()--查询阵容
    self:loadHero()
end
function View:loadlist()
	local list = guildModule.GetGuildList()
	if #list > 0 then
		self.view.list[UnityEngine.UI.Text].text = "已报名公会"
		self.view.list[UnityEngine.UI.Text].color = {r = 1,g=1,b=1,a=1}
		for i = 1,#list do
			--ERROR_LOG(sprinttb(list[i]))
			self.view.list[UnityEngine.UI.Text].text = self.view.list[UnityEngine.UI.Text].text.."\n"..list[i].id
		end
	end
	local id = module.unionModule.Manage:GetUionId()
	self.view.applyBtn.Text[UnityEngine.UI.Text].text = id.."报名"
end
function View:loadHero()
	local heros = guildModule.GetHero()
	if not heros then
		return
	end
	--ERROR_LOG(sprinttb(heros))
	for i = 1,#heros do
		self.view.FightList[i][UnityEngine.UI.Text].text = heros[i]..""
	end
end
function View:listEvent()
	return {
		"GUILD_PVP_GUILD_LIST_CHANGE",
		"GUILD_PVP_HERO_CHANGE",
	}
end
function View:onEvent(event,data)
	if event == "GUILD_PVP_GUILD_LIST_CHANGE" then
		self:loadlist()
	elseif event == "GUILD_PVP_HERO_CHANGE" then
		self:loadHero()
	end
end
return View