local defensiveModule = require "module.DefensiveFortressModule"
local ItemHelper = require "utils.ItemHelper"
local Time = require "module.Time";
local View = {};

function View:Start(data)
	self.root=CS.SGK.UIReference.Setup(self.gameObject)
	self.view=self.root.view.Content

	self.Rewards=data and data.Rewards
	self.Result=data and data.status

	self.RewardCD =false
	self.clearCDTime=Time.now()
	self.exitTime=5
	self:InitUI()
end

function View:InitUI()
	print(sprinttb(self.Rewards))
	self.teamInfo = module.TeamModule.GetTeamInfo() or module.playerModule.GetSelfID()
	

	self.root.view[CS.UGUISpriteSelector].index = self.Result ==1 and 0 or 1
	self.RewardCD=true
	self.view.rewardPanel.defeatedTip:SetActive(self.Result ~=1)
	self.view.rewardPanel.RewardsBg:SetActive(self.Rewards and next(self.Rewards)~=nil)
	if self.Rewards and next(self.Rewards)~=nil then
		for i=1,#self.Rewards do
			if self.Rewards[i][1]==41 then
				local cfg=ItemHelper.Get(self.Rewards[i][1],self.Rewards[i][2])
				if cfg then
					local _obj=UnityEngine.Object.Instantiate(self.view.rewardPanel.Rewards.IconFrame.gameObject.transform,self.view.rewardPanel.Rewards.gameObject.transform)
					local itemIcon=CS.SGK.UIReference.Setup(_obj.transform)
					_obj.gameObject:SetActive(true)
					utils.IconFrameHelper.Create(itemIcon,{type = self.Rewards[i][1], id=self.Rewards[i][2],count=self.Rewards[i][3]})
					--itemIcon.newItemIcon[SGK.newItemIcon]:SetInfo(cfg,false,tonumber(self.Rewards[i][3]))
					
					--itemIcon[SGK.newItemIcon].showDetail = true
					CS.UGUIClickEventListener.Get(_obj.gameObject).onClick = function (obj) 
						DialogStack.PushPrefStact("ItemDetailFrame",{id =self.Rewards[i][2],type =self.Rewards[i][1],count=self.Rewards[i][3]},UnityEngine.GameObject.FindWithTag("UITopRoot").gameObject)
						--self.RewardCD=false
						self.view.rewardPanel.tip.gameObject:SetActive(false)
					end
				end
			end
		end
	end	
	if self.Result ==1 then
		SGK.ResourcesManager.LoadAsync("sound/victory 5.mp3",typeof(UnityEngine.AudioClip),function (Audio)
			self.root.view[UnityEngine.AudioSource].clip = Audio
			self.root.view[UnityEngine.AudioSource]:Play()
		end)
	end
	self.view.rewardPanel.GetBtn.Text[UI.Text].text = "领取奖励"--self.Result ==1 and -- or "退出"
	CS.UGUIClickEventListener.Get(self.view.rewardPanel.GetBtn.gameObject).onClick = function (obj) 
		defensiveModule.QueryGetRewards()
		if self.teamInfo.leader.pid == module.playerModule.GetSelfID() then
			defensiveModule.BackToEntranceNpc()
		else
			CS.UnityEngine.GameObject.Destroy(self.gameObject)
		end
	end	
	CS.UGUIClickEventListener.Get(self.root.mask.gameObject).onClick = function (obj) 
		defensiveModule.QueryGetRewards()
		if self.teamInfo.leader.pid == module.playerModule.GetSelfID() then
			defensiveModule.BackToEntranceNpc()
		else
			CS.UnityEngine.GameObject.Destroy(self.gameObject)
		end
	end
end
	
function View:Update()
	if self.RewardCD then
		local time=self.clearCDTime+self.exitTime-Time.now()
		if time>=0 then
			if self.teamInfo.leader.pid == module.playerModule.GetSelfID() then
				self.view.rewardPanel.tip[UI.Text].text = string.format("%ds后自动领取并退出",time)
				--self.view.rewardPanel.tip[UI.Text].text=self.Result ==1  and string.format("%ds后自动领取并退出",time) or string.format("%ds后自动退出",time)
			else
				self.view.rewardPanel.tip[UI.Text].text = string.format("%ds后自动领取",time)
			end
		else
			self.RewardCD =false	
			if self.teamInfo.leader.pid == module.playerModule.GetSelfID() then
				defensiveModule.BackToEntranceNpc();
			else
				CS.UnityEngine.GameObject.Destroy(self.gameObject)
			end
		end 
	end
end

return View;