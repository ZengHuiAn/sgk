local TeamModule = require "module.TeamModule"
local playerModule = require "module.playerModule"
local ActivityModule = require "module.ActivityModule"
local UserDefault = require "utils.UserDefault"
local ItemModule = require "module.ItemModule"
local NetworkService = require "utils.NetworkService";
local TipCfg = require "config.TipConfig"
local Time = require "module.Time"
local ItemHelper = require "utils.ItemHelper"
local IconFrameHelper = require "utils.IconFrameHelper"
local DrawCard_data = UserDefault.Load("DrawCard_data",true);
local View = {}
function View:Start(data)
	self.view = CS.SGK.UIReference.Setup(self.gameObject)
	self.Data = data
	local ActivityData = ActivityModule.GetManager(1)
	local DrawCount = ActivityData[2].CardData.current_pool_draw_count > 0 and ActivityData[2].CardData.current_pool_draw_count or 1
	for i = 1,#self.view.fz do
		if DrawCard_data and DrawCard_data.list and DrawCard_data.list[i] and DrawCard_data.Rom == ActivityData[2].CardData.current_pool then
			--self.view.fz[i]:SetActive(false)
			local integral = data and data.integral or false
			self:OpenBoxEffect(self:GetItemType(DrawCard_data.list[i]),i,function ( ... )
				if integral then
					SetItemTipsState(true)
					local temp = DrawCard_data.list[i]
					for j = 1 ,#temp do
						GetItemTips(temp[j][2],temp[j][3],temp[j][1])
					end
					DispatchEvent("integral_info_change",{x=self.view.fz[i].transform.position.x,y=self.view.fz[i].transform.position.y,z=self.view.fz[i].transform.position.z})
				end
			end,integral)
		else
			if DrawCard_data.Rom == ActivityData[2].CardData.current_pool then
				self.view.fz[i]:SetActive(true)
			else
				self.view.fz[i]:SetActive(i > DrawCount)
			end
			SGK.ResourcesManager.LoadAsync(self.view[SGK.UIReference],"prefabs/effect/UI/chouka_rock_"..math.random(1,3) .. ".prefab",function (o)
				GetUIParent(o,self.view.fz[i].transform)
			end)
			SGK.ResourcesManager.LoadAsync(self.view[SGK.UIReference],"prefabs/effect/UI/fx_box_start.prefab",function (o)
				GetUIParent(o,self.view.fz[i].transform)
			end)
		end
		self.view.fz[i][CS.UGUIClickEventListener].onClick = function ( ... )
			local price = ActivityData[2].price
			local item = ItemHelper.Get(ItemHelper.TYPE.ITEM, ActivityData[2].consume_id);
			showDlg(nil,"是否消耗<color=#55FDFEFF>"..price..item.name.."</color>打开",function()
				print("点击了确定",i)
				ActivityModule.StartDraw(2,i)
			 end,function()
			 	print("点击了取消")
			end)
		end
	end
end
function View:OpenBoxEffect(data,idx,fun,isEct)
	if idx then
		local Type,Heroid,id,count = data[1],data[2],data[3],data[4]
		if Heroid then
			--ERROR_LOG("hero ->",idx,id)
			self:showHero(Heroid,idx,Type)
			if isEct then
				SGK.ResourcesManager.LoadAsync(self.view[SGK.UIReference],"prefabs/effect/UI/fx_box_kai_ren.prefab",function (temp)
					local effect = GetUIParent(temp,self.view.transform)
					effect.transform.position = self.view.fz[idx].transform.position
				end)
			end
		else
			--ERROR_LOG("item ->"..idx.." "..id)
			local ItemIconView = IconFrameHelper.Item({id = id,count = count},self.view, {showDetail = true})
			ItemIconView.transform.position = self.view.fz[idx].gameObject.transform.position
			ItemIconView.transform.localScale = Vector3(0.8,0.8,1)
			--local ItemIconView = SGK.UIReference.Setup(ItemClone)
	        --ItemIconView[SGK.newItemIcon]:SetInfo(ItemHelper.Get(utils.ItemHelper.TYPE.ITEM,id,nil,count))
	        --ItemIconView[SGK.newItemIcon].showDetail = true
	        if Type == 2 then
	        	SGK.ResourcesManager.LoadAsync(self.view[SGK.UIReference],"prefabs/effect/UI/fx_box_gold_run.prefab",function (temp)
	        		GetUIParent(temp,ItemIconView.transform)
	        	end)
			end
			if isEct then
				if Type == 1 then
					SGK.ResourcesManager.LoadAsync(self.view[SGK.UIReference],"prefabs/effect/UI/fx_box_kai_blue.prefab",function (temp)
						GetUIParent(temp,ItemIconView.transform)
					end)
				else
					SGK.ResourcesManager.LoadAsync(self.view[SGK.UIReference],"prefabs/effect/UI/fx_box_kai_gold.prefab",function (temp)
						GetUIParent(temp,ItemIconView.transform)
					end)
				end
			end
		end
		--effect.transform:DOScale(Vector3(1,1,1),0.5):OnComplete(function ( ... )
		self.view.fz[idx]:SetActive(false)
		SGK.Action.DelayTime.Create(0.6):OnComplete(function()--0.6秒后结算
			SetItemTipsState(true)
			if fun then
				fun()
			end	
		end)
	end
end
function View:showHero(id,idx,Type)
	local cfg = module.HeroModule.GetInfoConfig()
	if cfg[id] then
		--obj = CS.UnityEngine.GameObject.Instantiate(SGK.ResourcesManager.Load("prefabs/newCharacterIcon"),self.view.transform)
		SGK.ResourcesManager.LoadAsync("prefabs/base/npcUI.prefab",function (prefab)
			local obj = CS.UnityEngine.GameObject.Instantiate(prefab,self.view.transform)
			local HeroView = SGK.UIReference.Setup(obj)
			HeroView.transform.position = self.view.fz[idx].transform.position
			--PLayerIcon.transform.localScale = Vector3(0.8,0.8,0.8)
			--PLayerIcon[SGK.newCharacterIcon]:SetInfo({head = id,level = 0,name = "",vip=0},true)
	    	local animation = HeroView.spine[CS.Spine.Unity.SkeletonGraphic];
	    	animation:UpdateSkeletonAnimation("roles_small/"..cfg[id].mode_id.."/"..cfg[id].mode_id.."_SkeletonData")
			--animation.startingAnimation = actionName
			animation.startingLoop = true
	    	animation:Initialize(true);
	    	HeroView.Label.name:TextFormat(cfg[id].name)
			obj:SetActive(true)
			self:ShowNpcDesc(HeroView.Label,cfg[id].talk, math.random(1,3))
			HeroView[CS.UGUIClickEventListener].onClick = function ( ... )
				utils.SGKTools.HeroShow(id)
			end
			if Type == 2 then
				SGK.ResourcesManager.LoadAsync(self.view[SGK.UIReference],"prefabs/effect/UI/fx_box_gold_run.prefab",function (temp)
					GetUIParent(temp,HeroView.transform)
				end)
			end
		end)
	else
		ERROR_LOG(nil,"配置表role_info中"..id.."不存在")
	end
end
function View:onEvent(event, data)
	if event == "DrawCard_Succeed" then
		local idx = ActivityModule.GetDrawIndex()
		if idx > 0 then
			if not DrawCard_data or not DrawCard_data.list then
				DrawCard_data.list = {}
			end
			DrawCard_data.list[idx] = data
			self:OpenBoxEffect(self:GetItemType(data),idx,function ( ... )
				--ERROR_LOG("DrawCard_Succeed")
				for i = 1 ,#data do
					--local ItemHelper = require "utils.ItemHelper"
					GetItemTips(data[i][2],data[i][3],data[i][1])
				end
				local ActivityData = ActivityModule.GetManager(1)
				if ActivityData[2].CardData.current_pool_draw_count == ActivityData[2].CardData.current_pool_draw_Max and self.DrawAllView then
					self.DrawAllView.allBtn:SetActive(false)
					self.DrawAllView.RefBtn:SetActive(false)
				end
				DispatchEvent("integral_info_change",{x=self.view.fz[idx].transform.position.x,y=self.view.fz[idx].transform.position.y,z=self.view.fz[idx].transform.position.z})
			end,true)
		end
	elseif event == "sweepstake_change_pool" then
		DialogStack.Destroy("DrawAllFrame")
		UnityEngine.GameObject.Destroy(self.gameObject)
	end
end
function View:listEvent()
    return {
    "StartDraw",
    "DrawClickBox",
    "DrawCard_Succeed",
    "Activity_INFO_CHANGE",
    "sweepstake_change_pool",
    "sweepstake_callback",
    "DrawCard_callback",
    "LOCAL_GUIDE_CHANE",
}
end
function View:GetItemType(data)
	--ERROR_LOG(sprinttb(data))
	local TYPE = 0
	local hero = nil
	local id = #data == 3 and data[3][2] or data[1][2]
	local count = #data == 3 and data[3][3] or data[1][3]
	for i = 1,#data do
		if data[i][4] and data[i][4] > TYPE then
			TYPE = data[i][4]
		end
		if data[i][1] == ItemHelper.TYPE.HERO then
			hero = data[i][2]
		end
	end
	return {TYPE,hero,id,count}
end
function View:ShowNpcDesc(npc_view,desc,type, fun)
	npc_view.dialogue.bg1:SetActive(type == 1)
	npc_view.dialogue.bg2:SetActive(type == 2)
    npc_view.dialogue.bg3:SetActive(type == 3)
    npc_view.dialogue.desc[UnityEngine.UI.Text].text = desc

    if npc_view.qipao and npc_view.qipao.activeSelf then
        npc_view.qipao[UnityEngine.CanvasGroup]:DOFade(0,0.5):OnComplete(function()
            npc_view.dialogue[UnityEngine.CanvasGroup]:DOFade(1,1):OnComplete(function()
                npc_view.dialogue[UnityEngine.CanvasGroup]:DOFade(0,1):OnComplete(function()
                    npc_view.dialogue.desc[UnityEngine.UI.Text].text = "";
                    if fun then
                        fun()
                    end
                    npc_view.qipao[UnityEngine.CanvasGroup]:DOFade(1,0.5);
                end):SetDelay(1)
            end)        
        end)
    else
    	npc_view.dialogue[UnityEngine.CanvasGroup]:DOPause()
        npc_view.dialogue[UnityEngine.CanvasGroup]:DOFade(1,1):OnComplete(function()
            npc_view.dialogue[UnityEngine.CanvasGroup]:DOFade(0,1):OnComplete(function()
                npc_view.dialogue.desc[UnityEngine.UI.Text].text = "";
                if fun then
                    fun()
                end
            end):SetDelay(1)
        end)
    end
end
return View