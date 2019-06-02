local HeroModule = require "module.HeroModule"
local ItemModule = require "module.ItemModule"
local NetworkService = require "utils.NetworkService";
local HeroEvo = require "hero.HeroEvo"
local HeroWeaponStage = require "hero.HeroWeaponStage"
local ShopModule = require "module.ShopModule"
local ParameterConf = require "config.ParameterShowInfo";
local CommonConfig = require "config.CommonConfig";
local ItemHelper = require "utils.ItemHelper"
local ManorManufactureModule = require "module.ManorManufactureModule"
local IconFrameHelper = require "utils.IconFrameHelper"
local View = {};
--require "module.playerModule"
function View:Start(data)
	self.view = CS.SGK.UIReference.Setup(self.gameObject).Root
	self.viewRoot = CS.SGK.UIReference.Setup(self.gameObject)
	self.ClickItemID = 0--用户点击的物品id
	self.ClickItemindex = 0
	self.DATA = nil
	self.ItemArr = {}--插槽物品
	self.DATA = data or self.savedValues.Data--{roleID = self.savedValues.Data.heroid,ViewState = self.savedValues.ViewState}
	self.savedValues.Data = self.DATA
	self.Effect_List = {}--特效组
	-- showDlg(self.view,"这是一个提示框",function()
	-- 	print("点击了确定")
	-- end,function()
	-- 	print("点击了取消")
	-- end)
	self:refresh(self.DATA)
	DispatchEvent("RoleEquipFrame_BOSS_SHOW", {show = false})
	self.view.buyTips[UnityEngine.UI.Button].onClick:AddListener(function ()
		self.view.buyTips.gameObject:SetActive(false)
	end)
	self.viewRoot[UnityEngine.CanvasGroup]:DOFade(1,0.15)
end
function View:deActive(deActive)
	if self.viewRoot then
		local co = coroutine.running();
		self.viewRoot.Max[UnityEngine.CanvasGroup]:DOFade(0,0.1):OnComplete(function ( ... )
			self.viewRoot.Max:SetActive(false)
		end)
		self.viewRoot[UnityEngine.CanvasGroup]:DOFade(0,0.1):OnComplete(function ( ... )
			coroutine.resume(co);
			DispatchEvent("RoleEquipFrame_BOSS_SHOW", {show = true})
		end)
		coroutine.yield();
		DispatchEvent("RoleEquipBack")
		return true
	end
end

function View:refresh(data)
	if data == nil then
		return
	end
	local WeaponID = nil

	local role = module.HeroModule.GetConfig(data.roleID);
	if role then
		WeaponID = role.weapon;
	end
	for i = 1, #self.Effect_List do
		UnityEngine.GameObject.Destroy(self.Effect_List[i].gameObject)
	end
	local manager = HeroModule.GetManager();
	local hero = manager:Get(data.roleID);
	--local ParameterConf =HeroModule.GetPeropertyParameterConfig()
	local heroLevel = 0
	local Hero_weapon_Stage = self.DATA.ViewState and hero.stage or hero.weapon_stage
	local Hero_weapon_Slot = self.DATA.ViewState and hero.stage_slot or hero.weapon_stage_slot
	local NowStageHeroConf = hero and (self.DATA.ViewState and HeroEvo.GetConfig(data.roleID)[hero.stage] or HeroWeaponStage.GetConfig(WeaponID)[hero.weapon_stage]) or nil
	local NextStageHeroConf = nil
	local stagecolor = {{r=245/255,g=245/255,b=245/255,a=1},{r=99/255,g=238/255,b=155/255,a=1},{r=95/255,g=208/255,b=1,a=1},{r=184/255,g=82/255,b=1,a=1},{r=1,g=181/255,b=86/255,a=1},{r=254/255,g=17/255,b=106/255,a=1}}
	local bgcolor = {{r=182/255,g=182/255,b=182/255,a=1},{r=39/255,g=249/255,b=220/255,a=1},{r=87/255,g=216/255,b=1,a=1},{r=179/255,g=128/255,b=1,a=1},{r=1,g=184/255,b=32/255,a=1},{r=254/255,g=17/255,b=106/255,a=1}}
	local StageColorEff = {"fx_tupo_bight_green","fx_tupo_bight_blue","fx_tupo_bight_zi","fx_tupo_bight_gold","fx_tupo_bight_red"}
	if hero then
		if self.DATA.ViewState then
			NextStageHeroConf = HeroEvo.GetConfig(data.roleID)[hero.stage+1]
		else
			NextStageHeroConf = HeroWeaponStage.GetConfig(WeaponID)[hero.weapon_stage+1]
		end

		if NextStageHeroConf then
			self.view:SetActive(true)
			self.viewRoot.Max:SetActive(false)
			local cfg = CommonConfig.Get(100 + Hero_weapon_Stage + 1);
            local heroLevel = cfg and cfg.para2 or 0;

			--self.view.Bar.Scrollbar[UnityEngine.UI.Scrollbar].size = 0
			local Nowtemp = 0
			for i =1 ,20/4 do
				if Hero_weapon_Stage >= i*4 then
					Nowtemp = i*4
				end
			end
			for i = 1 ,#self.viewRoot.bg do
				self.viewRoot.bg[i]:SetActive(false)
			end
			if self.viewRoot.bg[NowStageHeroConf.quality].transform.childCount > 0 then
				UnityEngine.GameObject.Destroy(self.viewRoot.bg[NowStageHeroConf.quality].transform:GetChild(0).gameObject)
			end
			local tree_stage = GetUIParent(SGK.ResourcesManager.Load("prefabs/effect/UI/tree_stage"..NowStageHeroConf.quality .. ".prefab"),self.viewRoot.bg[NowStageHeroConf.quality])
			for i = 1 ,#self.view.Stage do
				stagecolor[NowStageHeroConf.quality + 1].a = i <= (Hero_weapon_Stage - Nowtemp) and 1 or 0.3
				self.view.Stage[i][UnityEngine.UI.Image].color = stagecolor[NowStageHeroConf.quality + 1]
				tree_stage.transform:GetChild(i-1).gameObject:SetActive(false)
			end
			if (Hero_weapon_Stage - Nowtemp) > 0 then
				tree_stage.transform:GetChild((Hero_weapon_Stage - Nowtemp)-1).gameObject:SetActive(true)
			end
			self.Effect_List[#self.Effect_List+1] = tree_stage
			local Nexttemp = 0
			for i =1 ,20/4 do
				if Hero_weapon_Stage+1 >= i*4 then
					Nexttemp = i*4
				end
			end
			for i = 1 ,#self.view.NextStage do
				stagecolor[NextStageHeroConf.quality + 1].a = i <= (Hero_weapon_Stage+1 - Nexttemp) and 1 or 0.3
				self.view.NextStage[i][UnityEngine.UI.Image].color = stagecolor[NextStageHeroConf.quality + 1]
			end
			self.viewRoot.bg[NowStageHeroConf.quality]:SetActive(true)
			local stage_slot_Sum = 0
			local install_ID = {}
			if (self.DATA.ViewState and hero.level < heroLevel) or (self.DATA.ViewState == false and hero.weapon_level < heroLevel) then
				self.view.DegreeBtn.breakThrough[CS.UGUIClickEventListener].interactable = false
				self.view.DegreeBtn.breakThrough.Text[UnityEngine.UI.Text].text = "LV "..heroLevel--.."可突破"
			else
				self.view.DegreeBtn.breakThrough[CS.UGUIClickEventListener].interactable = true
				self.view.DegreeBtn.breakThrough.Text[UnityEngine.UI.Text].text = "突破"
			end
			for i = 1,6 do
				self.ItemArr[i] = self.view.Grid[i]
				local texName = 0
				local TempDesc = "" 
				local tempValue = ""
				if i == 1 then
					texName = NowStageHeroConf.cost1_id
					TempDesc = ParameterConf.Get(NowStageHeroConf.effect1_type).name
					tempValue = "+"..NowStageHeroConf.effect1_value
				elseif i == 2 then
					texName = NowStageHeroConf.cost2_id
					TempDesc = ParameterConf.Get(NowStageHeroConf.effect2_type).name
					tempValue = "+"..NowStageHeroConf.effect2_value
				elseif i == 3 then
					texName = NowStageHeroConf.cost3_id
					TempDesc = ParameterConf.Get(NowStageHeroConf.effect3_type).name
					tempValue = "+"..NowStageHeroConf.effect3_value
				elseif i == 4 then
					texName = NowStageHeroConf.cost4_id
					TempDesc = ParameterConf.Get(NowStageHeroConf.effect4_type).name
					tempValue = "+"..NowStageHeroConf.effect4_value
				elseif i == 5 then
					texName = NowStageHeroConf.cost5_id
					TempDesc = ParameterConf.Get(NowStageHeroConf.effect5_type).name
					tempValue = "+"..NowStageHeroConf.effect5_value
				elseif i == 6 then
					texName = NowStageHeroConf.cost6_id
					TempDesc = ParameterConf.Get(NowStageHeroConf.effect6_type).name
					tempValue = "+"..NowStageHeroConf.effect6_value
				end
				--print("stage up", i, texName)
				local cfg = ItemModule.GetConfig(texName) or { icon = "", name = "", info = ""};
				if texName ~= 0 then
					self.ItemArr[i].icon[UnityEngine.UI.Image]:LoadSprite("icon/" .. cfg.icon)
				end
				local ItemStateDesc = ""
				local ItemCount = ItemModule.GetItemCount(texName)
				self.ItemArr[i].state[UnityEngine.UI.Text].text = ""
				self.ItemArr[i].value[UnityEngine.UI.Text].text = ""
				local ItemCount_color = ItemCount < 1 and "<color=#FF0000FF>" or "<color=#FFFFFFFF>"
				self.ItemArr[i].describe[UnityEngine.UI.Text].text = ItemCount_color..ItemCount.."</color>/1"
				self.ItemArr[i].bright[UnityEngine.UI.Image].color = ItemHelper.QualityColor(NowStageHeroConf.quality,(Hero_weapon_Slot[i] == 1 and 0.5 or 1))--{r=1,g=1,b=1,a=0.5}
				self.ItemArr[i].dark:SetActive(Hero_weapon_Slot[i] == 1)
				--print(texName..">>"..ItemCount)
				self.ItemArr[i][UnityEngine.UI.Image].sprite = self.view.Grid.itemObj[UnityEngine.UI.Image].sprite
				local item = ItemHelper.Get(ItemHelper.TYPE.ITEM,texName)
				
				if Hero_weapon_Slot[i] == 1 then
					self.ItemArr[i].describe[UnityEngine.UI.Text].text = TempDesc.."\n"..tempValue
					--ItemStateDesc = "已装备"
					stage_slot_Sum = stage_slot_Sum + 1
					self.Effect_List[#self.Effect_List+1] = GetUIParent(SGK.ResourcesManager.Load("prefabs/upStar/"..StageColorEff[NowStageHeroConf.quality] .. ".prefab"),self.ItemArr[i])
				elseif ItemCount > 0 then
					ItemStateDesc = "可装备"
					install_ID[#install_ID+1] = i
					--self.view.DegreeBtn.breakThrough.Text[UnityEngine.UI.Text].text = "一键激活"
					self.ItemArr[i].state:TextFormat("点击激活");
					self.Effect_List[#self.Effect_List+1] = GetUIParent(SGK.ResourcesManager.Load("prefabs/upStar/fx_tupo_jihuo.prefab"),self.ItemArr[i])
				elseif ManorManufactureModule.CheckProduct(texName) == 0 then
					ItemStateDesc = "可生产"
				else
					ItemStateDesc = "未拥有"
				end
				self.ItemArr[i].mask:SetActive(false)
				self.ItemArr[i].icon[CS.UGUIClickEventListener].onClick = (function ()
					--if Hero_weapon_Slot[i] then
					if Hero_weapon_Slot[i] == 1 then
						--已安装
						DialogStack.PushPrefStact("ItemDetailFrame", {id = item.id,type = item.type,InItemBag=2},UnityEngine.GameObject.FindWithTag("UGUIRoot").gameObject.transform)
					else
						if ItemStateDesc == "可装备" then
							--showDlgError(nil,"已拥有")
							DialogStack.PushPrefStact("ItemDetailFrame", {id = item.id,type = item.type,InItemBag=3,BtnDesc = "激活"},UnityEngine.GameObject.FindWithTag("UGUIRoot").gameObject.transform)
						else
							--showDlgError(nil,"未拥有")
							DialogStack.PushPrefStact("ItemDetailFrame", {id = item.id,type = item.type,InItemBag=2},UnityEngine.GameObject.FindWithTag("UGUIRoot").gameObject.transform)
						end
					end
				 	self.ClickItemID = texName
				 	self.ClickItemindex = i
				end)
			end
			self.view.DegreeBtn.gameObject:SetActive(true)--stage_slot_Sum == 6 and hero.level >= heroLevel)

			local value = ""
			local desc = ""
			local D_A = ""
			if self.DATA.ViewState then--and NextStageHeroConf.effect0_value3 ~= 0 and ParameterConf.Get(NextStageHeroConf.effect0_type3).notshow == 0 then
				value = value..(NextStageHeroConf.effect0_value1 ~= 0 and "+"..NextStageHeroConf.effect0_value1.."\n" or "")
				value = value..(NextStageHeroConf.effect0_value2 ~= 0 and "+"..NextStageHeroConf.effect0_value2.."\n" or "")
				value = value..(NextStageHeroConf.effect0_value3 ~= 0 and "+"..NextStageHeroConf.effect0_value3.."" or "")

				desc = desc..(NextStageHeroConf.effect0_value1 ~= 0 and ParameterConf.Get(NextStageHeroConf.effect0_type1).name.."\n" or "")
				desc = desc..(NextStageHeroConf.effect0_value2 ~= 0 and ParameterConf.Get(NextStageHeroConf.effect0_type2).name.."\n" or "")
				desc = desc..(NextStageHeroConf.effect0_value3 ~= 0 and ParameterConf.Get(NextStageHeroConf.effect0_type3).name.."" or "")

				D_A = (NextStageHeroConf.effect0_value1 ~= 0 and ParameterConf.Get(NextStageHeroConf.effect0_type1).name or "")..(NextStageHeroConf.effect0_value1 ~= 0 and "<color=#F3C702FF>+"..NextStageHeroConf.effect0_value1.."</color>" or "")
				D_A = D_A.."  "..(NextStageHeroConf.effect0_value2 ~= 0 and ParameterConf.Get(NextStageHeroConf.effect0_type2).name or "")..(NextStageHeroConf.effect0_value2 ~= 0 and "<color=#F3C702FF>+"..NextStageHeroConf.effect0_value2.."</color>" or "")
				D_A = D_A.."  "..(NextStageHeroConf.effect0_value3 ~= 0 and ParameterConf.Get(NextStageHeroConf.effect0_type3).name or "")..(NextStageHeroConf.effect0_value3 ~= 0 and "<color=#F3C702FF>+"..NextStageHeroConf.effect0_value3.."</color>" or "")
			else
				self.view.ScrollView.Viewport.Content.DescValue[UnityEngine.UI.Text].text = NowStageHeroConf.desc
			end
			self.view.describe[UnityEngine.UI.Text].text = D_A
			self.view.value[UnityEngine.UI.Text].text = ""
			
			local cfg = ItemModule.GetConfig(NextStageHeroConf.cost0_id1) or { icon = "", name = "", info = ""};

			--self.view.materialLeft.Label[UnityEngine.UI.Text].text = NextStageHeroConf.cost0_id1 == 0 and "" or cfg.name
			local count1color = ItemModule.GetItemCount(NextStageHeroConf.cost0_id1) < NextStageHeroConf.cost0_value1 and "<color=#FF0000FF>" or "<color=#FFFFFFFF>"
			local ItemCount_1 = ItemModule.GetItemCount(NextStageHeroConf.cost0_id1)
			self.view.DegreeBtn.count1[UnityEngine.UI.Text].text = NextStageHeroConf.cost0_value1 == 0 and 0 or count1color..utils.SGKTools.FormattingNumber(ItemCount_1).."</color>/"..utils.SGKTools.FormattingNumber(NextStageHeroConf.cost0_value1)
			if NextStageHeroConf.cost0_id1 ~= 0 then
				local ItemIconView = nil
				if self.view.DegreeBtn.icon1Btn.transform.childCount == 0 then
					ItemIconView = IconFrameHelper.Item({id = cfg.id,count = NextStageHeroConf.cost0_value1},self.view.DegreeBtn.icon1Btn, {showDetail = true})
				else
					local ItemClone = self.view.DegreeBtn.icon1Btn.transform:GetChild(0)
					ItemClone.gameObject:SetActive(true)
					ItemIconView = SGK.UIReference.Setup(ItemClone)
					IconFrameHelper.UpdateItem({id = cfg.id, count = NextStageHeroConf.cost0_value1},ItemIconView, {showDetail = true})
				end
    			--ItemIconView[SGK.newItemIcon].pos=2
				--self.view.DegreeBtn.icon1[UnityEngine.UI.Image]:LoadSprite("icon/".. cfg.icon)
				-- self.view.DegreeBtn.icon1Btn[CS.UGUIClickEventListener].onClick = function ( ... )
				-- 	local icon1item = ItemHelper.Get(ItemHelper.TYPE.ITEM,cfg.id)
				-- 	DialogStack.PushPref("ItemDetailFrame", {id = icon1item.id,type = icon1item.type,InItemBag=2},UnityEngine.GameObject.FindWithTag("NGUIRoot").gameObject.transform)
				-- end
			end

			local cfg = ItemModule.GetConfig(NextStageHeroConf.cost0_id2) or { icon = "", name = "", info = ""};
			--self.view.materialRight.Label[UnityEngine.UI.Text].text = NextStageHeroConf.cost0_id2 == 0 and "" or cfg.name
			local count2color = ItemModule.GetItemCount(NextStageHeroConf.cost0_id2) < NextStageHeroConf.cost0_value2 and "<color=#FF0000FF>" or "<color=#FFFFFFFF>"
			local ItemCount_2 = ItemModule.GetItemCount(NextStageHeroConf.cost0_id2)
			self.view.DegreeBtn.count2[UnityEngine.UI.Text].text = NextStageHeroConf.cost0_value1 == 0 and 0 or count2color..utils.SGKTools.FormattingNumber(ItemCount_2).."</color>/"..utils.SGKTools.FormattingNumber(NextStageHeroConf.cost0_value2)
			if NextStageHeroConf.cost0_id2 ~= 0 then
				local ItemIconView = nil
				if self.view.DegreeBtn.icon2Btn.transform.childCount == 0 then
					ItemIconView = IconFrameHelper.Item({id = cfg.id,count = NextStageHeroConf.cost0_value2},self.view.DegreeBtn.icon2Btn, {showDetail = true})
				else
					local ItemClone = self.view.DegreeBtn.icon2Btn.transform:GetChild(0)
					ItemClone.gameObject:SetActive(true)
					ItemIconView = SGK.UIReference.Setup(ItemClone)
					IconFrameHelper.UpdateItem({id = cfg.id,count = NextStageHeroConf.cost0_value2},ItemIconView, {showDetail = true})
				end
    			--ItemIconView[SGK.newItemIcon].pos=2
				--self.view.DegreeBtn.icon2[UnityEngine.UI.Image]:LoadSprite("icon/".. cfg.icon)
				-- self.view.DegreeBtn.icon2Btn[CS.UGUIClickEventListener].onClick = function ( ... )
				-- 	local icon2item = ItemHelper.Get(ItemHelper.TYPE.ITEM,cfg.id)
				-- 	DialogStack.PushPref("ItemDetailFrame", {id = icon2item.id,type = icon2item.type,InItemBag=2},UnityEngine.GameObject.FindWithTag("NGUIRoot").gameObject.transform)
				-- end
			end
			self.view.describe:SetActive(#install_ID == 0)
			self.view.RapidActivationBtn:SetActive(#install_ID > 0)
			self.view.desc:SetActive(#install_ID > 0)
			-- if #install_ID > 0 then
			-- 	self.view.DegreeBtn.breakThrough[CS.UGUIClickEventListener].interactable = false
			-- else
			-- 	self.view.DegreeBtn.breakThrough[CS.UGUIClickEventListener].interactable = true
			-- end
			self.view.RapidActivationBtn[CS.UGUIClickEventListener].onClick = (function ()
				if #install_ID > 0 then
					for i = 1,#install_ID do
						local tupo = GetUIParent(SGK.ResourcesManager.Load("prefabs/upStar/fx_tupo_up.prefab"),self.ItemArr[install_ID[i]].icon)
						SGK.Action.DelayTime.Create(2):OnComplete(function()
							CS.UnityEngine.GameObject.Destroy(tupo.gameObject)
						end)
						-- if self.ItemArr[i].transform.childCount > 8 then
						-- 	CS.UnityEngine.GameObject.Destroy(self.ItemArr[i].transform:GetChild(8).gameObject)
						-- end
						NetworkService.Send(17,{nil, data.roleID,install_ID[i],(self.DATA.ViewState and 0 or 1)});--插槽安装0角色1武器进阶
					end
				end
			end)
			self.view.DegreeBtn.breakThrough[CS.UGUIClickEventListener].onClick = (function ()
				if self.view.DegreeBtn.breakThrough[CS.UGUIClickEventListener].interactable then
					showDlg(nil,"是否进阶",function()
					 	--print("点击了确定")
					 	local tempNum = 0
					 	for i = 1,6 do
					 		if Hero_weapon_Slot[i] == 1 then
					 			tempNum = tempNum + 1
					 		else
					 			print(i)
					 			break
					 		end
					 	end
					 	local LeftItemCount = ItemModule.GetItemCount(NextStageHeroConf.cost0_id1)
					 	local RightItemCount = ItemModule.GetItemCount(NextStageHeroConf.cost0_id2)
					 	if tempNum ~= 6 then
					 		showDlg(nil,"插槽"..(tempNum+1).."未安装！",function()end)
					 	elseif (self.DATA.ViewState and hero.level < heroLevel) or (self.DATA.ViewState == false and hero.weapon_level < heroLevel) then
					 		local _desc = self.DATA.ViewState and "英雄" or "盗具"
	 				 		showDlg(nil,_desc.."等级Lv"..heroLevel.."可进阶",function()end)
					 	elseif NextStageHeroConf.cost0_id1 ~= 0 and LeftItemCount < NextStageHeroConf.cost0_value1 then
					 		local cfg = ItemModule.GetConfig(NextStageHeroConf.cost0_id1) or { icon = "", name = "", info = ""};
					 		showDlg(nil,cfg.name.."不足",function()end)
					 	elseif NextStageHeroConf.cost0_id2 ~= 0 and RightItemCount < NextStageHeroConf.cost0_value2 then
					 		local cfg = ItemModule.GetConfig(NextStageHeroConf.cost0_id2) or { icon = "", name = "", info = ""};
					 		showDlg(nil,cfg.name.."不足",function()end)
					 	else
					 		manager:AddRoleStage(data.roleID,(self.DATA.ViewState and 0 or 1))--0角色1武器进阶
					 		local shu_up = GetUIParent(SGK.ResourcesManager.Load("prefabs/upStar/fx_shu"..NowStageHeroConf.quality.."_up.prefab"),self.view)
					 		local lock = GetUIParent(SGK.ResourcesManager.Load("prefabs/base/LockFrame.prefab"))
					 		SGK.Action.DelayTime.Create(3):OnComplete(function()
					 			UnityEngine.GameObject.Destroy(lock.gameObject)
					 			UnityEngine.GameObject.Destroy(shu_up.gameObject)
					 		end)
					 	end
					 end,function()
					 	print("点击了取消")
					end)
				end
			end)
		else
			--max满阶级
			self.view:SetActive(false)
			self.viewRoot.Max:SetActive(true)
			self.viewRoot.Max[UnityEngine.CanvasGroup]:DOFade(1,0.15):SetDelay(0.2)
			local Nowtemp = 0
			for i =1 ,20/4 do
				if Hero_weapon_Stage >= i*4 then
					Nowtemp = i*4
				end
			end
			for i = 1 ,#self.viewRoot.Max.Stage do
				stagecolor[NowStageHeroConf.quality + 1].a = i <= (Hero_weapon_Stage - Nowtemp) and 1 or 0.5
				self.viewRoot.Max.Stage[i][UnityEngine.UI.Image].color = stagecolor[NowStageHeroConf.quality + 1]
			end
			for i = 0,self.viewRoot.bg[NowStageHeroConf.quality].transform.childCount-1 do
				--if self.viewRoot.bg[NowStageHeroConf.quality].transform.childCount > 0 then
				UnityEngine.GameObject.Destroy(self.viewRoot.bg[NowStageHeroConf.quality].transform:GetChild(i).gameObject)
				--end
			end
			for i = 1 ,#self.viewRoot.bg do
				self.viewRoot.bg[i]:SetActive(false)
			end
			self.viewRoot.bg[NowStageHeroConf.quality]:SetActive(true)
			local MAXtree = GetUIParent(SGK.ResourcesManager.Load("prefabs/effect/UI/tree_stage"..NowStageHeroConf.quality) .. ".prefab",self.viewRoot.bg[NowStageHeroConf.quality])
			MAXtree.transform:GetChild(MAXtree.transform.childCount -1).gameObject:SetActive(true)
			self.Effect_List[#self.Effect_List+1] = MAXtree
			self.viewRoot.Max.title[UnityEngine.UI.Text].text = self.DATA.ViewState and "角色已经满阶" or "盗具已经满阶"
			local CaclProperty = self.DATA.ViewState and HeroEvo.CaclProperty(hero) or HeroWeaponStage.CaclProperty(hero)
			self.viewRoot.Max.describe1[UnityEngine.UI.Text].text = ""
			self.viewRoot.Max.describe2[UnityEngine.UI.Text].text = ""
			self.viewRoot.Max.ScrollView.Viewport.Content.describe3[UnityEngine.UI.Text].text = ""
			if self.DATA.ViewState then
				local idx = 0
				for k,v in pairs(CaclProperty) do
					if k ~= 0  then
						if ParameterConf.Get(k) then
							idx = idx + 1
							if idx%2 ~= 0 then
								self.viewRoot.Max.describe1[UnityEngine.UI.Text].text = self.viewRoot.Max.describe1[UnityEngine.UI.Text].text..ParameterConf.Get(k).name.."<color=#F7C703FF>+"..v.."</color>\n"
							else
								self.viewRoot.Max.describe2[UnityEngine.UI.Text].text = self.viewRoot.Max.describe2[UnityEngine.UI.Text].text..ParameterConf.Get(k).name.."<color=#F7C703FF>+"..v.."</color>\n"
							end
						else
							showDlgError(nil,"属性"..k.."在ParameterConf中查找不到。")
						end
					end
				end
			else
				self.viewRoot.Max.ScrollView.Viewport.Content.describe3[UnityEngine.UI.Text].text = NowStageHeroConf.desc
			end
		end
	end
end


function View:ScreenToNguiPos(screenPos)	
    local nguiPos = UVector3.ctor(0,0,0)    
    nguiPos.x = screenPos.x * (768 / UnityEngine.Screen.width) - 384;
    nguiPos.y = screenPos.y * (1136 / UnityEngine.Screen.height) - 568;            
    return nguiPos;
end

function View:listEvent()
	return {
		"ITEM_INFO_CHANGE",
		"HERO_INFO_CHANGE",
		"Equip_Hero_Index_Change",
		"HERO_Stage_Succeed",
		"HERO_Stage_Equip_CHANGE",
		"Add_Degree_Succed",
	}
end

function View:onEvent(event,data)
	print(event)
	if event == "ITEM_INFO_CHANGE" then
		--新道具推送
		-- if self.view.buyTips.gameObject.activeSelf then
		-- 	self.view.buyTips.Count:TextFormat("拥有{0}件", ItemModule.GetItemCount(self.ClickItemID));
		-- end
		-- self:refresh(self.DATA)
	elseif event == "HERO_Stage_Equip_CHANGE" then
		if self.ClickItemindex ~= 0 then
			self.ItemArr[self.ClickItemindex].mask.gameObject:SetActive(true)
			self.ItemArr[self.ClickItemindex].mask.gameObject.transform:DOScale(Vector3(1.1,1.1,1.1),0.5)
			self.ItemArr[self.ClickItemindex].mask[UnityEngine.UI.Image]:DOFade(0,0.5)
			self.view.buyTips.gameObject:SetActive(false)
			self.ClickItemindex = 0
		end
	elseif event == "HERO_INFO_CHANGE" then
		--角色信息推送刷新
		self:refresh(self.DATA)
	elseif event == "Equip_Hero_Index_Change" then
		self.DATA.roleID = data.heroid
		self:refresh(self.DATA)
	elseif event == "HERO_Stage_Succeed" then
		
	elseif event == "Add_Degree_Succed" then
		if self.ItemArr[self.ClickItemindex].icon.transform.childCount == 0 then
			GetUIParent(SGK.ResourcesManager.Load("prefabs/upStar/fx_tupo_up.prefab"),self.ItemArr[self.ClickItemindex].icon)
		else
			self.ItemArr[self.ClickItemindex].icon.transform:GetChild(0).gameObject:SetActive(false)
			self.ItemArr[self.ClickItemindex].icon.transform:GetChild(0).gameObject:SetActive(true)
		end
		for i = 1, #self.Effect_List do
			UnityEngine.GameObject.Destroy(self.Effect_List[i].gameObject)
		end
		NetworkService.Send(17,{nil, self.DATA.roleID,self.ClickItemindex,(self.DATA.ViewState and 0 or 1)});--插槽安装0角色1武器进阶
	end
end

function View:ItemConfig(data,i)
	local tempConf = {
		id = data[i][0],
		name = data[i][1],
		icon = data[i][4]
	}
	return tempConf
end

return View;