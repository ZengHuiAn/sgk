local defensiveModule = require "module.DefensiveFortressModule"
local playerModule = require "module.playerModule";
local View = {};

function View:Start()
	self.root=CS.SGK.UIReference.Setup(self.gameObject)
	self.view=self.root.view
	self.TeamPlayerUI={}
	CS.UGUIClickEventListener.Get(self.root.mask.gameObject,true).onClick = function (obj)
		self.view.gameObject.transform:DOLocalMove(Vector3(-695,90,0), 0.5):OnComplete(function ( ... )
			self.gameObject:SetActive(false)
		end)
	end
end
function View:InitData(data)
	local teamInfo =data and data.teamInfo
	self.PlayerCfg=data and data.PlayerCfg

	table.sort(teamInfo.members, function(a,b)
			return a.pid==teamInfo.leader.pid
		end)

	for i,v in ipairs(teamInfo.members) do
		local k=v.pid
		local item=nil
		item,self.TeamPlayerUI=defensiveModule.CopyUI(self.TeamPlayerUI,self.view.ScrollView.Viewport.Content,self.view.ScrollView.Item,k)
		local player=self.PlayerCfg[v.pid];
		item.CharacterIcon[SGK.CharacterIcon]:SetInfo(player,true)
		item.name[UI.Text].text=v.name
		item.tip.gameObject:SetActive(k==teamInfo.leader.pid)
	end
	self:RefTeamResourcesNum()
end

function View:RefTeamResourcesNum()
	local ResourcesNum=defensiveModule.GetPlayerColNum()
	for k,v in pairs(ResourcesNum) do
		local item=CS.SGK.UIReference.Setup(self.TeamPlayerUI[k])
		item.desc[UI.Text]:TextFormat("已搜集资源:{0}",v.ColNum)
	end
end

function View:listEvent()
	return {
		"RESOURCES_NUM_CHANGE",
	}
end

function View:onEvent(event,data)
	if event == "RESOURCES_NUM_CHANGE" then
		self:RefTeamResourcesNum()
	end
end

 
return View;