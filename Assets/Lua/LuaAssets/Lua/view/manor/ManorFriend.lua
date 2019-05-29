local FriendModule = require 'module.FriendModule'
local ManorModule = require 'module.ManorModule'
local openLevel = require "config.openLevel"

local View = {};
function View:Start(data)
	self.root = CS.SGK.UIReference.Setup(self.gameObject);
    self.view = self.root.view;
	self:InitData();
	self:InitView();
end

function View:InitData()
    self.list = {};
    local list = FriendModule.GetManager();
    for i,v in ipairs(list) do
        if v.level >= openLevel.GetCfg(2001).open_lev then
            table.insert(self.list, v);
        end
    end
    table.sort(self.list, function (a,b)
        if a.online ~= b.online then
            return a.online > b.online;
        end
        if a.care ~= b.care then
            return a.care > b.care
        end
        return a.pid < b.pid
    end)
end

function View:InitView()
	CS.UGUIClickEventListener.Get(self.root.BG.gameObject).onClick = function ( object )
        DialogStack.Pop()
   	end
    CS.UGUIClickEventListener.Get(self.view.title.close.gameObject).onClick = function ( object )
  	    DialogStack.Pop()
    end
    CS.UGUIClickEventListener.Get(self.view.ScrollView.tip.add.gameObject).onClick = function ( object )
        DialogStack.Push("FriendSystemList", {idx = 4})
    end
    self.view.top.steal.Text[UnityEngine.UI.Text]:TextFormat("事件 {0}/10", module.ItemModule.GetItemCount(1401));
    self.view.top.news.Text[UnityEngine.UI.Text]:TextFormat("新闻 {0}/10", module.ItemModule.GetItemCount(1405));
    self.view.ScrollView[CS.UIMultiScroller].RefreshIconCallback = function (obj, idx)
        local item = CS.SGK.UIReference.Setup(obj);
        local friend = self.list[idx + 1];
        utils.IconFrameHelper.Create(item.IconFrame, {pid = friend.pid});
        item.name[UI.Text].text = friend.name;
        item.online[CS.UGUISpriteSelector].index = friend.online;
        coroutine.resume(coroutine.create(function ()
            local news,steal,quest,event = ManorModule.GetOtherManorStatus(friend.pid);
            item.news[CS.UGUIColorSelector].index = news;
            item.steal[CS.UGUIColorSelector].index = (steal + event) > 0 and 1 or 0;
            item.quest[CS.UGUIColorSelector].index = quest;
            print("测试", friend.name, news,steal,quest,event)
        end))
        CS.UGUIClickEventListener.Get(item.gameObject).onClick = function ( object )
            SceneStack.EnterMap(26, {mapid = 26, room = friend.pid})
        end
        item:SetActive(true);
    end
    self:UpdateView();
end

function View:UpdateView()
    self.view.ScrollView[CS.UIMultiScroller].DataCount = #self.list;
    self.view.top.Text[UI.Text]:TextFormat("好友  {0}/50", #self.list)
    self.view.ScrollView.tip:SetActive(#self.list < 3);
end

function View:deActive()
    utils.SGKTools.PlayDestroyAnim(self.gameObject)
	return true;
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