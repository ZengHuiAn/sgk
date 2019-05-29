local NetworkService = require "utils.NetworkService";
local ActivityModule = require "module.ActivityModule"
local ItemModule = require "module.ItemModule"
local ItemHelper = require "utils.ItemHelper"
local lucky_draw = require "config.lucky_draw"
local UserDefault = require "utils.UserDefault"
local Time = require "module.Time"

local View = {};
function View:Start(data)
	self.view = CS.SGK.UIReference.Setup(self.gameObject)
	self.Data = data and data or self.Data
	self.ItemArr = self.ItemArr and self.ItemArr or {}
	self.ClickID = 0
	self.HeroArr = {}--抽出的英雄数组
	self.DrawCardSum = UserDefault.Load("DrawCardSum",true)
	self.DrawCount = self.Data.modeid == 0 and 20 or 2

	local inversion = true
	local ActivityData = ActivityModule.GetManager(1)
	local id = self.Data.typeid
	local time =  math.floor(os.time()  - ActivityData[id].CardData.last_free_time)
	local temp = {ActivityData[id].consume_type,ActivityData[id].consume_id}--{type id value}
	--if self.Data.IsFree[self.Data.typeid] then
	if time >= ActivityData[id].free_gap then
	--是否免费
		temp[3] = self.Data.modeid == 1 and ActivityData[id].combo_price or 0
	else
		temp[3] = self.Data.modeid == 0 and ActivityData[id].price or ActivityData[id].combo_price
	end
	for i = 1,10 do
		if not self.ItemArr[i] then
			local obj = CS.UnityEngine.GameObject.Instantiate(self.view.ItemPanel.item.gameObject,self.view.ItemPanel.Grid1.gameObject.transform)
			self.ItemArr[i] = CS.SGK.UIReference.Setup(obj)
		end
		if self.Data.modeid == 0 then
			--单抽
			self.ItemArr[i].icon[CS.UITexture].mainTexture = CS.SGK.ResourcesManager.Load("icon/10000.png")
			self.ItemArr[i].name[CS.UILabel].text = "???"
			self.ItemArr[i].border[CS.UISprite].spriteName = "daoju_1"
			self.ItemArr[i].icon[CS.UIEventListener].onClick = (function()
				if ActivityData[id] and inversion then
					inversion = false
				
					ActivityModule.DrawCard(ActivityData[id].id,ActivityData[id].pool_type,temp,self.Data.modeid)
					self.ClickID = i
				end
			end)
		else
			self.ItemArr[i].gameObject.transform.parent = self.view.ItemPanel.Grid1.gameObject.transform
		end
		self.ItemArr[i].gameObject:SetActive(self.Data.modeid == 0)
	end
	self.view.ItemPanel.Grid1[CS.UIGrid]:Reposition()
	if self.Data.modeid == 1 then
	--多抽
		if ActivityData[id] then
			ActivityModule.DrawCard(ActivityData[id].id,ActivityData[id].pool_type,temp,self.Data.modeid)
		end
	end
	self.view.Hero.mask[CS.UIEventListener].onClick = (function ( ... )
		-- if #self.HeroArr > 0 then
		-- 	self:HeroLoad()
		-- else
		-- 	self.view.ItemPanel.gameObject:SetActive(true)
		-- 	self.view.Hero.gameObject:SetActive(false)
		-- 	DispatchEvent("Main_bg_IsActive")
		-- end
	end)
	self.view.BtnPanel.continueBtn[CS.UIEventListener].onClick = (function ( ... )
		local ExpendData = self:Expend(self.Data.typeid,self.Data.modeid)
		if ItemModule.GetItemCount(ExpendData.id) >= ExpendData.price then
			if self.DrawCardSum[self.Data.typeid][self.Data.modeid + 1] < self.DrawCount then
				self:Start(data)
			else
				showDlgError(nil,"已达当天最大抽取次数.")
			end
		else
			showDlgError(nil,ExpendData.cfg.name.."不足.")
		end
	end)
	self:CostRef()
	DispatchEvent("CloseBackChatBtn",{true,false})
	self.view.BtnPanel.continueBtn.gameObject:SetActive(false)
	--self:RandomPadding()
end

function View:RandomPadding(idx,type)
	--print(idx.."<>"..type)
	local lucky_drawConf = lucky_draw.GetConf(idx,type)
	local lucky_drawConf_weight = lucky_draw.GetMaxWeight(idx,type)
	local random = math.random(1,lucky_drawConf_weight)
	local WeightSum = 0
	--print(lucky_drawConf_weight)
	for i = 1,#lucky_drawConf do
		WeightSum = WeightSum + lucky_drawConf[i].weight
		if random <= WeightSum then
			--print(lucky_drawConf[i].gid)
			return lucky_drawConf[i]
		end
	end
end

function View:HeroLoad()
	if #self.HeroArr > 0 then
		self.view.ItemPanel.gameObject:SetActive(false)
		self.view.Hero.gameObject:SetActive(true)
		local heroid = self.HeroArr[1]
		if self.Herogameobj then
			CS.UnityEngine.GameObject.Destroy(self.Herogameobj)
		end
		self.Herogameobj = UnityEngine.GameObject("Hero"..heroid);
		
		local com = self.Herogameobj:AddComponent(typeof(CS.Spine.Unity.SkeletonAnimation));
		com.skeletonDataAsset = SGK.ResourcesManager.Load("roles/"..heroid.."/"..heroid.."_SkeletonData.asset");
		com:Initialize(true);
		if com.state then
			com.state:SetAnimation(0,"idle",true);
			self.Herogameobj.transform.parent = self.view.Hero.gameObject.transform;
			self.Herogameobj.transform.localScale = Vector3(65,65,1)
			self.Herogameobj.transform.localPosition = Vector3(0,-325,0)
			self.Herogameobj.layer = 10
		end
		table.remove(self.HeroArr,1)
		self.view.gameObject.transform:DOMove(Vector3.zero,1):OnComplete(function( ... )
			if #self.HeroArr > 0 then
				self:HeroLoad()
			else
				self.view.ItemPanel.gameObject:SetActive(true)
				self.view.Hero.gameObject:SetActive(false)
				self.view.BtnPanel.continueBtn.gameObject:SetActive(true)
				DispatchEvent("Main_bg_IsActive")
			end
		end):SetDelay(0.5)
	end
end

function View:listEvent()
	return {
		"ITEM_INFO_CHANGE",
		"DrawCard_Succeed"
	}
end

function View:ShowItem(data)
	local i = self.ClickID
	--local itemID = data[1]
	--table.remove(data,1)
	--print(sprinttb(data))
	--print(self.Data.typeid..">"..self.Data.modeid)
	--print(self.DrawCardSum[self.Data.typeid][self.Data.modeid+1])
	self.DrawCardSum[self.Data.typeid][self.Data.modeid + 1] = self.DrawCardSum[self.Data.typeid][self.Data.modeid+1] + 1
	self.DrawCardSum[3] = Time.now();
	local IitemObjCount = 0
	
	for j = 1,10 do
		if #data == 1 then
			--local random = math.random(1,ItemXls.row -1)
			--local id = tonumber(ItemXls[random][0])
			local ActivityData = ActivityModule.GetManager(1)
			local drawType = 1--普通
			if ActivityData[self.Data.typeid].CardData.total_count == ActivityData[self.Data.typeid].guarantee_count then
				--保底抽取
				drawType = 3
			elseif ActivityData[self.Data.typeid].CardData.has_used_gold == 0 then
				--首抽
				drawType = 2
			end
			local RamItem = self:RandomPadding(self.Data.typeid,drawType)
			--local cfg = ItemModule.GetConfig(data[1][2]) or { icon = "10000", name = data[1][2].."", info = "",quality = 0};
			--print(data[1][1]..">>"..data[1][2])
			local cfg = ItemHelper.Get(data[1][1],data[1][2])
			if j == i then
				self.HeroArr[#self.HeroArr+1] = cfg.icon
			end
			cfg = j == i and cfg or ItemHelper.Get(RamItem.reward_item_type,RamItem.reward_item_id)--ItemModule.GetConfig(id)
			local idx = j
			local time = j==i and 0 or 0.5
			local desc = cfg.name
			local iconid = cfg.icon
			self.ItemArr[idx].gameObject.transform:DOLocalRotate(Vector3(0,90,0),0.25):SetDelay(time):OnComplete(function( ... )
				self.ItemArr[idx].border[CS.UISprite].spriteName = "daoju_"..(cfg.quality+1)
				self.ItemArr[idx].name[CS.UILabel].text = desc
				self.ItemArr[idx].icon[CS.UITexture].mainTexture = CS.SGK.ResourcesManager.Load("icon/".. iconid..".png")
				self.ItemArr[idx].gameObject.transform:DOLocalRotate(Vector3(0,0,0),0.25):OnComplete(function( ... )
					if j == i then
						showDlgError(self.view,"获得"..cfg.name.." X "..data[1][3],Vector3(0,-330,0),nil,10)
						self.view.BtnPanel.continueBtn.gameObject:SetActive(true)
						self:examine()
					end
				end)
			end)
			self.ItemArr[idx].gameObject:SetActive(true)
		else
			if #data >= j then
				--local cfg = ItemModule.GetConfig(data[j][2]) or { icon = "88005", name = data[j][2].."", info = "",type = 0};
				local cfg = ItemHelper.Get(data[j][1],data[j][2])
				if cfg.type == ItemHelper.TYPE.HERO then
					--print(cfg.id..">>"..cfg.type)
					self.ItemArr[j].gameObject.transform.parent = self.view.ItemPanel.HeroGrid.gameObject.transform
					self.HeroArr[#self.HeroArr+1] = cfg.icon
				else
					IitemObjCount = IitemObjCount + 1
					if IitemObjCount > 5 then
						self.ItemArr[j].gameObject.transform.parent = self.view.ItemPanel.Grid2.gameObject.transform
					end
				end
				self.ItemArr[j].name[CS.UILabel].text = cfg.name
				self.ItemArr[j].icon[CS.UITexture].mainTexture = CS.SGK.ResourcesManager.Load("icon/".. cfg.icon..".png")
				--local localPos = self.ItemArr[j].gameObject.transform.localPosition
				self.ItemArr[j].gameObject.transform:DOScale(Vector3(1,1,1),(j-1)*0.1):OnComplete(function( ... )
					showDlgError(self.view,"获得"..cfg.name.." X "..data[1][3],Vector3(0,-330+(j*80),0),j,10)
				end)
			end
			self.ItemArr[j].gameObject:SetActive(#data >= j)
		end
	end
	self.view.ItemPanel.HeroGrid[CS.UIGrid]:Reposition()
	self.view.ItemPanel.Grid1[CS.UIGrid]:Reposition()
	self.view.ItemPanel.Grid2[CS.UIGrid]:Reposition()
	if #data ~= 1 then--不是十连
		self:examine()
	end
end

function View:examine()
	if #self.HeroArr > 0 then
		DispatchEvent("Main_bg_IsActive")
		if self.view.Hero.Rolebg.gameObject.transform.childCount == 0 then
			CS.UnityEngine.GameObject.Instantiate(SGK.ResourcesManager.Load("prefabs/effect/UI/role_bg.prefab"),self.view.Hero.Rolebg.gameObject.transform)
		end
	else
		self.view.BtnPanel.continueBtn.gameObject:SetActive(self.Data.modeid == 1)
	end
	self:HeroLoad()
end

function View:CostRef()
	--消费刷新
	local ExpendData = self:Expend(self.Data.typeid,self.Data.modeid)
	self.view.BtnPanel.continueBtn.cost[CS.UILabel].text = ExpendData.price..""
	self.view.BtnPanel.continueBtn.icon[CS.UITexture].mainTexture = SGK.ResourcesManager.Load("icon/"..ExpendData.cfg.icon .. ".png")
	--self.view.BtnPanel.continueBtn.gameObject:SetActive(self.Data.modeid == 1)
end

function View:Expend(typeid,modeid)
	local ActivityData = ActivityModule.GetManager(1)
	local Tid = ActivityData[typeid] and ActivityData[typeid].consume_id or 0
	local Tcfg = ItemModule.GetConfig(Tid) or { icon = "", name = "nil", info = ""};
	local Tprice = ActivityData[typeid] and (modeid == 0 and ActivityData[typeid].price or ActivityData[typeid].combo_price * ActivityData[typeid].combo_count) or 0
	return {id = Tid, cfg = Tcfg , price = Tprice}
end

function View:onEvent(event,data)
	if event == "ITEM_INFO_CHANGE" then

	elseif event == "DrawCard_Succeed" then
		--print(sprinttb(data))
		local list = {}
		for i = 1 ,#data do
			if data[i][2] == 90401 or data[i][2] == 90403 then
			
			else
				list[#list+1] = data[i]
			end
		end
		self:ShowItem(list)
	end
end

return View
