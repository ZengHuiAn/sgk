local NetworkService = require "utils.NetworkService"
local ItemHelper = require "utils.ItemHelper"
local TeamModule = require "module.TeamModule"
local Time = require "module.Time"
local SmallTeamDungeonConf = require "config.SmallTeamDungeonConf"
local View = {}
function View:Start(data)
	self.root = CS.SGK.UIReference.Setup(self.gameObject)
	self.view = self.root.view.Content

	self:InitView()

	self.view.bottom.Tip:SetActive(data and data ==1)
	self.firstInit = data and data==1
	self.statusTab = {}
	self.selectIdx = 1

	self.Data = module.TeamModule.GetPubRewardData()
	for k,v in pairs(self.Data) do
		self:updateRewardList(v)
	end
end

function View:InitView()
	self.root.view.Title[UI.Text].text = SGK.Localize:getInstance():getValue("biaoti_zhanlipin_01")
	self.view.top.tipText[UI.Text].text = SGK.Localize:getInstance():getValue("daojishi_01")

	CS.UGUIClickEventListener.Get(self.root.view.Close.gameObject).onClick = function()
		DialogStack.Pop()
	end

	CS.UGUIClickEventListener.Get(self.view.bottom.returnBtn.gameObject).onClick = function()
		DialogStack.Pop()
	end

	--16076 true 需求 false 放弃 2贪婪
	CS.UGUIClickEventListener.Get(self.view.mid.selectBtns.needBtn.gameObject).onClick = function()
		self:OnClickRollBtn(true,1)
	end

	CS.UGUIClickEventListener.Get(self.view.mid.selectBtns.unneededBtn.gameObject).onClick = function()
		self:OnClickRollBtn(2,2)
	end

	CS.UGUIClickEventListener.Get(self.view.mid.selectBtns.giveUpBtn.gameObject).onClick = function()
		self:OnClickRollBtn(false,0)
	end

	self.UIDragIconScript = self.view.top.rewardContent[CS.UIMultiScroller]
	self.UIDragIconScript.RefreshIconCallback = (function (obj,idx)
		self:refreshData(obj,idx)
	end)

	local item_x = self.UIDragIconScript.cellWidth
	self.view.top.rewardContent[CS.UnityEngine.UI.ScrollRect].onValueChanged:AddListener(function (off)
		self.view.top.rewardContent.leftArrow:SetActive(off.x>0.1)
		self.view.top.rewardContent.rightArrow:SetActive(off.x<0.9)
	end)

	CS.UGUIClickEventListener.Get(self.view.top.rewardContent.leftArrow.gameObject).onClick = function()
		local move_x = self.view.top.rewardContent.Viewport.Content.transform.localPosition.x
		self.view.top.rewardContent.Viewport.Content.transform:DOLocalMoveX(move_x+item_x,0.2)
	end

	CS.UGUIClickEventListener.Get(self.view.top.rewardContent.rightArrow.gameObject).onClick = function()
		local move_x = self.view.top.rewardContent.Viewport.Content.transform.localPosition.x
		self.view.top.rewardContent.Viewport.Content.transform:DOLocalMoveX(move_x-item_x,0.2)
	end
end

local static_status_Text ={[0]="<color=#F05025FF>放弃</color>","<color=#FFD700FF>需求</color>","<color=#00FF00FF>贪婪</color>","未知"}
local status_Color = {[0]="<color=#F05025FF>","<color=#FFD700FF>","<color=#00FF00FF>","<color=#F05025FF>","<color=#F05025FF>"}
function View:OnClickRollBtn(status,statusIdx)
	if module.TeamModule.GetTeamPveFightId() == 11701 then
		local _status = self.statusTab[self.selectIdx].status
		if  _status~= 0 and _status~=1 and _status~=2 then--没roll过
			module.GuidePubRewardAndLuckyDraw.SetSelfPubRewardRoll(status)
			self.statusTab[self.selectIdx] = self.statusTab[self.selectIdx] or {}
			self.statusTab[self.selectIdx].sn = 17101--伪造sn
			self.statusTab[self.selectIdx].status = 1
		end
	else
		if not TeamModule.GetSelfCanRollPubRewardStatus() then
			showDlgError(nil,SGK.Localize:getInstance():getValue("fuben_touzhi_4"))
			return
		end
		local _status = self.statusTab[self.selectIdx].status
		if  _status~= 0 and _status~=1 and _status~=2 then--没roll过
			self:updateBtnInteractable(false)
			local sn = NetworkService.Send(16076,{nil,self.gid,self.selectIdx,status})
			self.statusTab[self.selectIdx] = self.statusTab[self.selectIdx] or {}
			self.statusTab[self.selectIdx].sn = sn
			self.statusTab[self.selectIdx].status = statusIdx
		end
	end
end

local LimitRollConsumtId = 0
function View:updateRewardList(v)
	local list,EndTime,gid,pids,RollPids,Roll= v.list,v.EndTime,v.gid,v.pids,v.RollPids,v.Roll
	self.gid = gid
	self.list = list
	EndTime = EndTime or Time.now()
	--Roll--roll 点相关信息
	--RollPids roll过的人

	local item_x = self.UIDragIconScript.cellWidth
	local totalWidth = self.view.top.rewardContent[UnityEngine.RectTransform].rect.width
	self.view.top.rewardContent.leftArrow:SetActive(false)
	self.view.top.rewardContent.rightArrow:SetActive(item_x*#self.list > totalWidth)
	
	local time = math.floor(EndTime - Time.now())>=0 and math.floor(EndTime - Time.now()) or 0
	if time > 0 then
		local _time = time<=60 and time or 60
		self.view.top.timer.bar[UI.Image].fillAmount = _time/60
		self.view.top.timer.Text[UI.Text].text = _time.."s"
	else
		self.timerOver = true
		self.view.top.timer.bar[UI.Image].fillAmount = 0
		self.view.top.timer.Text[UI.Text].text = "0s"
	end

	--物品的状态
	for i=1,#list do
		self.statusTab[list[i][4]] = self.statusTab[list[i][4]] or {}
		self.statusTab[list[i][4]].status = 3
		self.statusTab[list[i][4]].point = 0
		local containSelf = false
		--roll点相关信息
		if Roll and Roll[list[i][4]] then
			-- self.statusTab[list[i][4]].point = 0
			for j=1,#Roll[list[i][4]] do
				--中央的数字，为目前的最大骰子数，及时更新
				if Roll[list[i][4]][j].point>self.statusTab[list[i][4]].point and Roll[list[i][4]][j].status<=self.statusTab[list[i][4]].status then
					self.statusTab[list[i][4]].MaxPointStatus = Roll[list[i][4]][j].status or 3
					-- self.statusTab[list[i][4]].status = Roll[list[i][4]][j].status
					self.statusTab[list[i][4]].point = Roll[list[i][4]][j].point
					self.statusTab[list[i][4]].owner = 100000
					
					if Roll[i] then
						if #TeamModule.GetTeamInfo().members == #Roll[i] then
							self.statusTab[list[i][4]].owner = Roll[list[i][4]][j].pid
						end
					end
				end

				if Roll[list[i][4]][j].pid == module.playerModule.GetSelfID() then
					self.statusTab[self.selectIdx].status = Roll[list[i][4]][j].status
				end
			end
		end

		--玩家没有 roll点权限
		if module.TeamModule.GetTeamPveFightId() ~= 11701 and not containSelf and not TeamModule.GetSelfCanRollPubRewardStatus() and self.firstInit then
			if not self.tip then
				self.tip =true
				showDlgError(nil,SGK.Localize:getInstance():getValue("fuben_touzhi_4"))
			end

			local sn = NetworkService.Send(16076,{nil,self.gid,self.selectIdx,false})
			self.statusTab[self.selectIdx] = self.statusTab[self.selectIdx] or {}
			self.statusTab[self.selectIdx].sn = sn
			self.statusTab[self.selectIdx].status = 0
		end

		for j=1,#pids do
			if pids[j] == module.playerModule.GetSelfID() then
				if RollPids and RollPids[list[i][4]] and RollPids[list[i][4]][pids[j]] then
					--self.statusTab[list[i][4]].RollPower = true
					--已Roll过
					break
				elseif time <= 0 then
					--超时 自动放弃
					local sn = NetworkService.Send(16076,{nil,gid,list[i][4],false})
					self.view.top.tipText[UI.Text].text = "倒计时已结束"	
				else
					if i == self.selectIdx then
						self.view.mid.log.Text:SetActive(false)
					end
				end
			end
		end
	end

	self.UIDragIconScript.DataCount = #list
	self:updateViewShow()
end

function View:refreshData(Obj,Idx)
	local item=CS.SGK.UIReference.Setup(Obj);
	item:SetActive(true)
	local _tab = self.list[Idx+1]

	if _tab and next(_tab) ~= nil then
		local _type = _tab[1]
		local _id = _tab[2]
		local _count = _tab[3]
		local _idx =_tab[4]
		local uuid = _tab[5]

		local _cfg = utils.ItemHelper.Get(_type,_id)
		local owerPid = self.statusTab[_idx].owner or 100000
		
		if _cfg then
			utils.IconFrameHelper.Create(item.Icon.IconFrame,{type = _type, id = _id,uuid = uuid,otherPid =owerPid})--,count = _count,otherPid =owerPid})--,showDetail=true})
		end

		self.statusTab[_idx] = self.statusTab[_idx] or {}
		self.statusTab[_idx].status = self.statusTab[_idx].status or 3
		self.statusTab[_idx].ItemIdx = Idx

		item.status.Idx.Text[UI.Text].text = _idx
		item.status.Text[UI.Text].text = static_status_Text[self.statusTab[_idx].status]

		self.statusTab[_idx].MaxPointStatus = self.statusTab[_idx].MaxPointStatus or self.statusTab[_idx].status
		item.Icon.dotMark:SetActive(self.statusTab[_idx].MaxPointStatus~=3)
		if item.Icon.dotMark.activeSelf then
			self.statusTab[_idx].MaxPointStatus = self.statusTab[_idx].MaxPointStatus or 0
			item.Icon.dotMark.Text[UI.Text].text = string.format("%s%s</color>",status_Color[self.statusTab[_idx].MaxPointStatus],self.statusTab[_idx].point)
		end

		item.Icon[CS.UGUISpriteSelector].index = self.selectIdx == _idx and 1 or 0
		item.status.Idx[CS.UGUISpriteSelector].index = self.selectIdx == _idx and 1 or 0
		item.Icon.arrow:SetActive(self.selectIdx == _idx) 

		if self.selectIdx == _idx then
			self.view.mid.name.Text[UI.Text].text = _cfg.name
		end
		
		CS.UGUIClickEventListener.Get(item.gameObject).onClick = function()
			if self.selectIdx ~= _idx then
				local _obj = self.UIDragIconScript:GetItem(self.statusTab[self.selectIdx].ItemIdx)
				if _obj then
					local _selectItem = SGK.UIReference.Setup(_obj);
					_selectItem.Icon[CS.UGUISpriteSelector].index = 0
					_selectItem.status.Idx[CS.UGUISpriteSelector].index = 0
					_selectItem.Icon.arrow:SetActive(false) 
				end

				item.Icon[CS.UGUISpriteSelector].index = 1
				item.status.Idx[CS.UGUISpriteSelector].index = 1 
				item.Icon.arrow:SetActive(true)

				self.view.mid.name.Text[UI.Text].text = _cfg.name

				self.selectIdx = _idx  
				self:updateViewShow() 
			end

			if uuid and _type ==utils.ItemHelper.TYPE.EQUIPMENT or _type == utils.ItemHelper.TYPE.INSCRIPTION then
				module.equipmentModule.QueryEquipInfoFromServer(owerPid, uuid, function (equip)
					DialogStack.PushPrefStact("ItemDetailFrame", {type = _type, id = _id,uuid = uuid, otherPid =owerPid})
				end);
			else
				DialogStack.PushPrefStact("ItemDetailFrame", {type = _type, id = _id})
			end
		end

		CS.UGUIClickEventListener.Get(item.Icon.InfoBtn.gameObject).onClick = function()
			if self.selectIdx ~= _idx then
				local _obj = self.UIDragIconScript:GetItem(self.statusTab[self.selectIdx].ItemIdx)
				if _obj then
					local _selectItem = SGK.UIReference.Setup(_obj);
					_selectItem.Icon[CS.UGUISpriteSelector].index = 0
					_selectItem.status.Idx[CS.UGUISpriteSelector].index = 0
					_selectItem.Icon.arrow:SetActive(false) 
				end
				item.Icon[CS.UGUISpriteSelector].index = 1
				item.status.Idx[CS.UGUISpriteSelector].index = 1 
				item.Icon.arrow:SetActive(true)

				self.view.mid.name.Text[UI.Text].text = _cfg.name

				self.selectIdx = _idx  
				self:updateViewShow() 
			end		

			if uuid and _type ==utils.ItemHelper.TYPE.EQUIPMENT or _type == utils.ItemHelper.TYPE.INSCRIPTION then
				module.equipmentModule.QueryEquipInfoFromServer(owerPid, uuid, function (equip)
					DialogStack.PushPrefStact("ItemDetailFrame", {type = _type, id = _id,uuid = uuid, otherPid = owerPid})
				end);
			else
				DialogStack.PushPrefStact("ItemDetailFrame", {type = _type, id = _id})
			end
		end
	end
end

function View:updateBtnInteractable(rolled)
	if module.TeamModule.GetTeamPveFightId() == 11701 then
		self.view.mid.selectBtns.needBtn[CS.UGUISpriteSelector].index = not rolled and 1 or 0
		self.view.mid.selectBtns.unneededBtn[CS.UGUISpriteSelector].index = not rolled and 1 or 0
		self.view.mid.selectBtns.giveUpBtn[CS.UGUISpriteSelector].index = not rolled and 1 or 0
	else
		self.view.mid.selectBtns.needBtn[CS.UGUISpriteSelector].index = (not TeamModule.GetSelfCanRollPubRewardStatus() or not rolled) and 1 or 0
		self.view.mid.selectBtns.unneededBtn[CS.UGUISpriteSelector].index = (not TeamModule.GetSelfCanRollPubRewardStatus() or not rolled) and 1 or 0
		self.view.mid.selectBtns.giveUpBtn[CS.UGUISpriteSelector].index = (not TeamModule.GetSelfCanRollPubRewardStatus() or not rolled) and 1 or 0
	end
end

function View:updateViewShow()
	local cfg = self.statusTab[self.selectIdx]
	if cfg then
		--是否roll过
		local rolled = cfg.status ==0 or cfg.status == 1 or cfg.status == 2
		self:updateBtnInteractable(not rolled)
		self:updateRollDesc()
	end
end

function View:OnDestroy( ... )
	if self.Data then
		DispatchEvent("LOCAL_ROLL_FINISHED",self.Data)
	end
end

local showReturnBtnDelay = 5
function View:Update()
	if self.gid and self.selectIdx then
		local time = math.floor(self.Data[self.gid].EndTime - Time.now())
		if not self.timerOver then
			if time >= 0 then
				self.view.top.timer.Text[UI.Text].text = time.."s"
				self.view.top.timer.bar[UI.Image].fillAmount = time/60		
			else
				--当时间到了，更新日志（所有 没roll的 物品和没Roll的人看做是放弃） 
				for i=1,#self.list do	
					for j = 1,#self.Data[self.gid].pids do
						TeamModule.SetPubRewardList({self.gid,self.Data[self.gid].pids[j],i,0,0})
					end
				end
				self.view.top.tipText[UI.Text].text = "倒计时已结束"	
				self.view.top.timer.Text[UI.Text].text = "0s"
				self.view.top.timer.bar[UI.Image].fillAmount = 0

				self:updateBtnInteractable(false)
				self.timerOver = true
			end
		end
	end

	if self.view.bottom.Tip.activeSelf then
		showReturnBtnDelay = showReturnBtnDelay-UnityEngine.Time.deltaTime
		if showReturnBtnDelay>= 0 then
			self.view.bottom.Tip[UI.Text].text=string.format("%s秒后可返回",math.ceil(showReturnBtnDelay))
		else
			self.view.bottom.Tip:SetActive(false)
			self.view.bottom.returnBtn:SetActive(true)
		end
	end
end

function View:updateRollDesc()
	local PubRewardData = TeamModule.GetPubRewardData()
	local _pubRewardData = PubRewardData[self.gid]
	if _pubRewardData and _pubRewardData.desc then
		self.view.mid.log.Text:SetActive(true)
		if _pubRewardData.desc[self.selectIdx] then
			local MaxPoint = 0
			local MaxPointStatus = 3
			--道具 优先级最高点 显示
			for i=1,#_pubRewardData.Roll[self.selectIdx] do
				if _pubRewardData.Roll[self.selectIdx][i].status == 1 or _pubRewardData.Roll[self.selectIdx][i].status ==2 then
					--优先级高的 优先
					if MaxPointStatus~=0 and _pubRewardData.Roll[self.selectIdx][i].status < MaxPointStatus  or MaxPointStatus == 0 then
						MaxPoint = _pubRewardData.Roll[self.selectIdx][i].point
						MaxPointStatus = _pubRewardData.Roll[self.selectIdx][i].status
						self.statusTab[self.selectIdx].point = MaxPoint
					elseif _pubRewardData.Roll[self.selectIdx][i].status == MaxPointStatus then
						--同优先级 取点大的
						if _pubRewardData.Roll[self.selectIdx][i].point > MaxPoint then
							MaxPoint = _pubRewardData.Roll[self.selectIdx][i].point
							MaxPointStatus = _pubRewardData.Roll[self.selectIdx][i].status
							self.statusTab[self.selectIdx].point = MaxPoint
						end
					end
				else
					if MaxPointStatus == 3 or MaxPointStatus == 4 then
						MaxPointStatus = 0
					end
				end
			end
			if MaxPointStatus ~= 0 then
				local _obj = self.UIDragIconScript:GetItem(self.statusTab[self.selectIdx].ItemIdx)
				if _obj then
					local item = SGK.UIReference.Setup(_obj);
					item.Icon.dotMark:SetActive(true)
					item.Icon.dotMark.Text[UI.Text].text = string.format("%s%s</color>",status_Color[MaxPointStatus],MaxPoint)
				end
			end
			--MaxPoint--desc 优先级最高点高亮显示 
			local desc = ""
			for i = 1,#_pubRewardData.desc[self.selectIdx] do
				if MaxPoint == _pubRewardData.Roll[self.selectIdx][i].point and MaxPointStatus == _pubRewardData.Roll[self.selectIdx][i].status then
					desc = desc.."<color=#F05025FF>".._pubRewardData.desc[self.selectIdx][i].."</color>\n"
				else
					desc = desc.._pubRewardData.desc[self.selectIdx][i].."\n"
				end
			end
			--所有人都ROll过
			if #_pubRewardData.Roll[self.selectIdx] == #_pubRewardData.pids+#_pubRewardData.offRollPids then
				if MaxPointStatus ~= 0 then
					for i=1,#_pubRewardData.Roll[self.selectIdx] do
						if MaxPoint == _pubRewardData.Roll[self.selectIdx][i].point and MaxPointStatus == _pubRewardData.Roll[self.selectIdx][i].status then
							local _pid = _pubRewardData.Roll[self.selectIdx][i].pid
							local cfg = ItemHelper.Get(_pubRewardData.list[self.selectIdx][1],_pubRewardData.list[self.selectIdx][2])
							
							local _name = ""
							if _pid>0 then
								_name = module.playerModule.IsDataExist(_pid).name
							else
								local guideResultModule = require "module.GuidePubRewardAndLuckyDraw"
								local AIData = guideResultModule.GetLocalPubRewardAIData(_pid)
								if AIData then
									_name = AIData.name
								end
							end
							local getLog = _name.."  获得 <color="..utils.ItemHelper.QualityTextColor(cfg.quality)..">"..cfg.name.."</color>x".._pubRewardData.list[self.selectIdx][3]
							self.statusTab[self.selectIdx].owner = _pid
							desc = desc ..getLog
						end
					end
				else
					local cfg = ItemHelper.Get(_pubRewardData.list[self.selectIdx][1],_pubRewardData.list[self.selectIdx][2])
					local getLog = "<color="..utils.ItemHelper.QualityTextColor(cfg.quality)..">"..cfg.name.."</color>x".._pubRewardData.list[self.selectIdx][3].."已流拍"
					desc = desc ..getLog 
				end
			end
		
			self.view.mid.log.Text[UI.Text].text = desc
		else
			self.view.mid.log.Text[UI.Text].text = ""
		end
	end
end

function View:onEvent(event, data) 
	if event == "TEAM_ROLL_GAME_ROLL_REQUEST" then
		ERROR_LOG(self.statusTab[self.selectIdx].sn ,data.sn)
		--ERROR_LOG(self.statusTab[self.selectIdx].sn, data.sn,self.statusTab[self.selectIdx].status ,static_status_Text[self.statusTab[self.selectIdx].status])
		if self.statusTab[self.selectIdx] and self.statusTab[self.selectIdx].sn == data.sn  then
			local _obj = self.UIDragIconScript:GetItem(self.statusTab[self.selectIdx].ItemIdx)
			if _obj then
				local item = SGK.UIReference.Setup(_obj);
				item.status.Text[UI.Text].text = static_status_Text[self.statusTab[self.selectIdx].status]
			end
		end

		local cfg = self.statusTab[self.selectIdx]
		if cfg then
			--是否roll过
			local rolled = cfg.status ==0 or cfg.status == 1 or cfg.status == 2
			self:updateBtnInteractable(not rolled)
		end
	elseif event == "TEAM_ROLL_Notify" then
		if self.view then
			self:updateRollDesc()
		end
	end
end
function View:listEvent()
    return {
    	"TEAM_ROLL_GAME_ROLL_REQUEST",
    	"TEAM_ROLL_Notify",	
    }
end
return View