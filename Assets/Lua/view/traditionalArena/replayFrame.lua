local traditionalArenaModule = require "module.traditionalArenaModule"
local View = {};
function View:Start(data)
    self.root = CS.SGK.UIReference.Setup(self.gameObject);
    self.view =  self.root.view.Content;
    self.Pid = module.playerModule.GetSelfID();

	self:InitView();
end

function View:InitView()
	CS.UGUIClickEventListener.Get(self.root.view.closeBtn.gameObject).onClick = function()
		DialogStack.Pop();
	end

	CS.UGUIClickEventListener.Get(self.root.mask.gameObject).onClick = function()
		DialogStack.Pop();
	end

	self.UIDragIconScript = self.view.ScrollView.Viewport.Content[CS.ScrollViewContent];

	self:updateFightLogShow()
end


local challengeItemId = 90169
function View:updateFightLogShow()
	local fightLog = traditionalArenaModule.GetFightLog() or {}
	-- print(self.Pid)
	for i=1,#fightLog do
		local v = fightLog[i]
		-- print(sprinttb(fightLog[i]))
	end
	if fightLog then
		self.view.NoLogTip:SetActive(next(fightLog)== nil)
		if next(fightLog)~= nil then
			table.sort(fightLog,function (a,b)
				return a.fight_time > b.fight_time
			end)

			self.UIDragIconScript.RefreshIconCallback = (function (Obj,idx)
				local _Item=CS.SGK.UIReference.Setup(Obj);
				local cfg= fightLog[idx+1]
				if cfg then
					_Item.gameObject:SetActive(true)

					_Item.root.result[CS.UGUISpriteSelector].index = cfg.winner

					_Item.root.rank.Image:SetActive(cfg.change_pos~=0)
					if cfg.change_pos~=0 then
						_Item.root.rank.Text[UI.Text].text = math.abs(cfg.change_pos)
						_Item.root.rank.Image[CS.UGUISpriteSelector].index = cfg.winner
					else
						_Item.root.rank.Text[UI.Text].text = "—"
					end
					
					local passTime = self:transformShowTime(module.Time.now()-cfg.fight_time)
					_Item.root.timeData[UI.Text].text = passTime
					local opposite_pid = cfg.attacker_id == self.Pid and cfg.defender_id or cfg.attacker_id
					_Item.root.AorD[UI.Text].text = cfg.attacker_id == self.Pid and "进攻" or "防守"
					self:updatePlayerInfo(opposite_pid,_Item.root)

					local rank_Info = traditionalArenaModule.GetDefenderFightInfo(opposite_pid)
					if rank_Info then
						_Item.root.capacity.Text[UI.Text].text = rank_Info.capacity
					end

					CS.UGUIClickEventListener.Get(_Item.root.replay.gameObject).onClick = function()
						traditionalArenaModule.startFight(cfg.fight_data,{},cfg.winner)
					end	
				end
			end)
			self.UIDragIconScript.DataCount = #fightLog
		end
	end
end

function View:updatePlayerInfo(pid,item)
	if item and pid and pid ~= 0 then
		if pid <1000000 then
			local playerdata = traditionalArenaModule.GetNpcCfg(pid)
			local headIconCfg = module.ItemModule.GetShowItemCfg(playerdata.HeadFrameId)
			local _headFrame = headIconCfg and headIconCfg.effect or ""
			utils.IconFrameHelper.Create(item.IconFrame,{customCfg=
				{
					pid = pid,
					head = playerdata.icon,
					level = playerdata.level1,
					vip = playerdata.vip_lv,
					sex = playerdata.Sex,
					HeadFrame = _headFrame,
				}
			})

			item.name[UI.Text].text = playerdata.name
		else
			utils.IconFrameHelper.Create(item.IconFrame,{pid=pid})

			module.playerModule.Get(pid,function ( ... )
				local playerdata = module.playerModule.Get(pid);
				if playerdata then
					item.name[UI.Text].text = playerdata.name
				end        
			end)
		end
	end
end

function View:transformShowTime(_time)
	if math.floor(_time/(60*60*24*30))>12 then
		return math.floor(_time/(60*60*24*30*12)).."年前"
	elseif math.floor(_time/(60*60*24))>30 then
		return math.floor(_time/(60*60*24*30)).."月前"
	elseif math.floor(_time/(60*60))>24 then
		return math.floor(_time/(60*60*24)).."天前"
	elseif math.floor(_time/(60))>60 then
		return math.floor(_time/(60*60)).."小时前"
	elseif math.floor(_time)>60 then
		return math.floor(_time/60).."分钟前"
	else
		return "1分钟前"	 
	end
end

function View:deActive()
    utils.SGKTools.PlayDestroyAnim(self.gameObject)
	return true;
end

function View:listEvent()
	return {
		"TRADITIONAL_ARENA_LOG_CHANGE",
		"TRADITIONAL_RANKINFO_CHANGE",
		"PLAYER_ADDDATA_CHANGE",
	}
end

function View:onEvent(event,data)
	if event == "TRADITIONAL_ARENA_LOG_CHANGE"  then
		self:updateFightLogShow()
	elseif event == "TRADITIONAL_RANKINFO_CHANGE" then
		self.gameObject.transform:DOScale(Vector3.one,0.5):OnComplete(function()
			self.UIDragIconScript:ItemRef()
        end)
    elseif event == "PLAYER_ADDDATA_CHANGE" then
    	ERROR_LOG("=======")
	end	
end

return View;