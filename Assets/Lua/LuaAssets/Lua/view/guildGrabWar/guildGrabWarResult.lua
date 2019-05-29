local GuildGrabWarModule = require "module.GuildGrabWarModule"
local playerModule = require "module.playerModule"
local View = {};
function View:Start(data)
    self.view = CS.SGK.UIReference.Setup(self.gameObject);
    self.side = data and data.side;
    self.win = data and data.win;
	self:InitData();
	self:InitView();
end

function View:InitData()
    self.guildGrabWarInfo = GuildGrabWarModule.Get();
	local player_info = self.guildGrabWarInfo:GetPlayerInfo();
    self.unionMember = {};
    for k,v in pairs(player_info) do
        local side = v.is_attacker == 1 and 1 or 2;
        if side == self.side then
            local info = {};
            info.pid = v.pid;
            info.score = v.score;
            table.insert(self.unionMember, info);
        end
    end
    table.sort(self.unionMember, function ( a,b )
        if a.score ~= b.score then
            return a.score > b.score;
        end
        return a.pid < b.pid;
    end)
end

function View:InitView()
    CS.UGUIClickEventListener.Get(self.view.close.gameObject).onClick = function()
        UnityEngine.GameObject.Destroy(self.gameObject);
    end
    local index = 0;
    if self.side == 1 then
        if self.win then
            index = 0;
        else
            index = 1;
        end
    else
        if self.win then
            index = 2;
        else
            index = 3;
        end
    end
    self.view.bg[CS.UGUISpriteSelector].index = index;
    self.view.ScrollView[CS.UIMultiScroller].RefreshIconCallback = function(obj, idx)
        local view = CS.SGK.UIReference.Setup(obj);
        local info = self.unionMember[idx + 1];
        view.rank[UI.Text].text = idx + 1;
        view.bg:SetActive((idx + 1)%2 == 0)
        playerModule.Get(info.pid, function (player)
            view.name[UI.Text].text = player.name;
        end)
        playerModule.GetCombat(info.pid,function ()
            view.capacity[UI.Text].text = math.ceil(playerModule.GetFightData(info.pid).capacity)
        end)
        view.num[UI.Text].text = info.score;
        view:SetActive(true);
    end
    self.view.ScrollView[CS.UIMultiScroller].DataCount = #self.unionMember;
end

function View:listEvent()
	return {
		"",
	}
end

function View:onEvent(event, ...)
	print("onEvent", event, ...);
	if event == ""  then

	end
end

return View;