local PVPArenaModule = require "module.PVPArenaModule"
local playerModule = require "module.playerModule"

local View = {};
function View:Start(data)
    self.view = CS.SGK.UIReference.Setup(self.gameObject);
    local change = PVPArenaModule.GetWealthChange();
    self:ShowWealthChange(change[1], change[2], change[3])
end

function View:ShowWealthChange(old,new, result)
    
    local delta = new - old;
    if delta > 0 then
        self.view.num[UnityEngine.UI.Text]:TextFormat("{0} <color=#00E8B4FF>+{1}</color>",old,delta);
    elseif delta < 0 then
        self.view.num[UnityEngine.UI.Text]:TextFormat("{0} <color=#FF0000FF>{1}</color>",old,delta);
    else
        return;
    end
    
    self.view.Image:SetActive(delta > 0);
    local player = playerModule.Get();
	-- local head = player.head ~= 0 and player.head or 11000;
	-- self.view.newCharacterIcon.mask.Icon[UnityEngine.UI.Image]:LoadSprite("icon/"..head)
    -- self.view.newCharacterIcon.Level[UnityEngine.UI.Text].text = "Lv "..player.level;
    utils.IconFrameHelper.Create(self.view.IconFrame, {pid = player.id});

    if result == 1 then
        self.view.tip[UnityEngine.UI.Text]:TextFormat("恭喜！输出更胜一筹！")
    -- elseif result == 2 then
    --     self.view.tip[UnityEngine.UI.Text]:TextFormat("可惜，还是差了一点，下次努力吧！")
    else
        self.view.tip[UnityEngine.UI.Text]:TextFormat("")
    end
	self.gameObject:SetActive(true);
end

function View:listEvent()
	return {
        "ARENA_WEALTH_CHANGE",
        "ARENA_FIGHT_RESULT"
	}
end

function View:onEvent(event, ...)
    if event == "ARENA_WEALTH_CHANGE"  then
        self:ShowWealthChange(...);
    elseif event == "ARENA_FIGHT_RESULT" then
        self:ShowResult(...);
	end
end

return View;