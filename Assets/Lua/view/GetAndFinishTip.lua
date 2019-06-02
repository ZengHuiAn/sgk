local PlayerModule = require "module.playerModule"
local HeroModule = require "module.HeroModule"
local HeroLevelup = require "hero.HeroLevelup"
local PlayerInfoHelper = require "utils.PlayerInfoHelper"
local ItemHelper = require "utils.ItemHelper" 

local View={}
function View:Start()
	self.ItemView = SGK.UIReference.Setup(self.gameObject);
end

local will_show_Item = {}
local showLimit = 25
local showCount = 0
function View:UpdateShowItem(Type,id,count,uuid)
    self.reward_will_create = self.reward_will_create or {};
    -- 合并相同的奖励
    self.create_info = self.create_info or {};
    local key =Type* 10+id* 1000 + (uuid and uuid or 0)
    local v={Type=Type,id=id,uuid=uuid,count=count}
   
    if not self.create_info[key] then
        if showCount >= showLimit then
            table.insert(will_show_Item, v)
            return
        else
            showCount = showCount+1
            self.create_info[key] = {}
            table.insert(self.reward_will_create, v)
        end
    end
    
    self.create_info[key].count=(self.create_info[key].count or 0)+count
    if self.create_info[key].icon then
        self.create_info[key].icon.Count = self.create_info[key].count;
    end
end

function View:Update()
    if not self.reward_will_create  or  (self.reward_will_create and #self.reward_will_create == 0) then
        return;
    end

    self.reward_parent_transform =self.ItemView.Group.gameObject.transform
    self.prefab =self.ItemView.Group[1].gameObject

    local v = self.reward_will_create[1];
    table.remove(self.reward_will_create, 1);

    local key =v.Type* 10+v.id* 1000 + (v.uuid and v.uuid or 0)

    local ItemIconView = SGK.UIReference.Instantiate(self.prefab)
    ItemIconView.transform:SetParent(self.reward_parent_transform, false);

    -- utils.IconFrameHelper.Create(ItemIconView.IconFrame,{uuid=v.uuid,type=v.Type,id=v.id,count=v.count,showDetail=true,func=function (IconItem)
    --     IconItem[CS.SGK.CommonIcon].Count = "x"..self.create_info[key].count
    -- end})
    utils.IconFrameHelper.Create(ItemIconView.IconFrame,{uuid=v.uuid,type=v.Type,id=v.id,count=self.create_info[key].count,showDetail=true})


    local item = ItemHelper.Get(v.Type,v.id,nil,v.count)
    if item then
        if item.sub_type==70 or item.sub_type==72 or item.sub_type==73 or item.sub_type==74 or item.sub_type==75 or item.sub_type==76 then
            self.showSettingItem=item

            self.ItemView.Btns.SetBtn.gameObject:SetActive(true)
        else
            self.showSettingItem=nil
            self.ItemView.Btns.SetBtn.gameObject:SetActive(false)
        end
    end
    
    self.ItemView.Group.gameObject.transform.localPosition=Vector3(0,self.ItemView.view.characters.gameObject.activeSelf and 60 or 230,0)
    ItemIconView.gameObject:SetActive(true)

    self.fxTab = self.fxTab or {}
    table.insert(self.fxTab,ItemIconView)   
end

local ChangeScene=false
local _o = nil
function View:GetItemClick()
    if not self.fxTab or (self.fxTab and next(self.fxTab)==nil) then 
        self:DestroyGetAndFinishTipItem() 
        return 
    end
    
    local fx_tab = {}
    for i=1,#self.fxTab do
        self.fxTab[i].gameObject:SetActive(false)
        fx_tab[i] = self.fxTab[i]
    end
    self.fxTab = {}

    local root=UnityEngine.GameObject.FindWithTag("UGUIRoot").gameObject.transform
    local node=UnityEngine.GameObject.Find("mapSceneUI(Clone)/mapSceneUIRoot/bottom/allBtn/bag")
    local prefab_fly = SGK.ResourcesManager.Load("prefabs/effect/UI/fx_ui_dati_lizi.prefab");
    local prefab = SGK.ResourcesManager.Load("prefabs/effect/UI/fx_ui_dati_bao.prefab");

    local pushStackCount = #DialogStack.GetStack() + #DialogStack.GetPref_stact()
    if  node and pushStackCount == 0 then
        local _nodePos = SGK.GuideMask.GetNodePos(node.gameObject)
        local _targetPos = self.ItemView.transform:InverseTransformPoint(_nodePos)
        local targetPos = {_targetPos.x,_targetPos.y}
        for i=1,#fx_tab do
            if not fx_tab[i] or not node then return end
    
            SGK.Action.DelayTime.Create(0.1*i):OnComplete(function()
                if fx_tab[i] then
                    local o = prefab_fly and UnityEngine.GameObject.Instantiate(prefab_fly,root); 
                    local localPos = self.ItemView.Group.gameObject.transform:TransformPoint(fx_tab[i].gameObject.transform.localPosition)
                    local createPos = self.ItemView.transform:InverseTransformPoint(localPos)
                    o.transform.localPosition = createPos
                     
                    o.transform.localScale=Vector3.one*100
                    o.layer = UnityEngine.LayerMask.NameToLayer("UI");
                    for i = 0,o.transform.childCount-1 do
                        o.transform:GetChild(i).gameObject.layer = UnityEngine.LayerMask.NameToLayer("UI");
                    end

                    if not ChangeScene then
                        o.transform:DOLocalMove(Vector3(targetPos[1],targetPos[2],0),1):OnComplete(function( ... )
                            if node then
                                if not  _o then
                                    _o = prefab and UnityEngine.GameObject.Instantiate(prefab, node.transform);
                                    _o.transform.localScale=Vector3.one*100
                                    _o.layer = UnityEngine.LayerMask.NameToLayer("UI");
                                    for i = 0,_o.transform.childCount-1 do
                                        _o.transform:GetChild(i).gameObject.layer = UnityEngine.LayerMask.NameToLayer("UI");
                                    end
                                    if _o then
                                        local _obj = _o:GetComponentInChildren(typeof(UnityEngine.ParticleSystem))
                                        UnityEngine.Object.Destroy(_o, _obj.main.duration)
                                        SGK.Action.DelayTime.Create(_obj.main.duration):OnComplete(function()
                                           _o = nil     
                                        end)                                
                                    end
                                end
                            end
                            CS.UnityEngine.GameObject.Destroy(o)
                        end)
                    else
                        CS.UnityEngine.GameObject.Destroy(o)
                    end
                end
            end)
        end
    end

    ChangeScene=false
    if next(will_show_Item) then
        local show_Item = {}
        for i=1,#will_show_Item do
            table.insert(show_Item,will_show_Item[i])
        end
        will_show_Item = {}
        showCount = 0
        for i=1,#show_Item do
            self:UpdateShowItem(show_Item[i].Type,show_Item[i].id,show_Item[i].count,show_Item[i].uuid)
        end
    else
        self.ItemView.view.gameObject:SetActive(false)
        self.ItemView.Btns.gameObject:SetActive(false)
        SGK.Action.DelayTime.Create(0.1*#fx_tab):OnComplete(function()
            self:DestroyGetAndFinishTipItem()
        end)
    end

    if self.ItemView.Group.heroToFrameTip.activeSelf then
    	self.ItemView.Group.heroToFrameTip:SetActive(false)
    end
end

function View:SetItemClick()
    if not self.showSettingItem then return end
    if self.showSettingItem.sub_type==72 then
        DialogStack.Push("mapSceneUI/ChangeIconFrame",{2,self.showSettingItem.id})                    
    elseif self.showSettingItem.sub_type==76 then
        DialogStack.Push("mapSceneUI/newPlayerInfoFrame",{2,self.showSettingItem.sub_type,self.showSettingItem.id})
    else
        DialogStack.Push("mapSceneUI/newPlayerInfoFrame",{2,self.showSettingItem.sub_type,self.showSettingItem.id})
    end
    CS.UnityEngine.GameObject.Destroy(self.gameObject)
end

function View:DestroyGetAndFinishTipItem()
    CS.UnityEngine.GameObject.Destroy(self.gameObject)  
end

local ShowFinishQuestTextImage=false
function View:ShowGetItemTextImage()
    self.ItemView[SGK.AudioSourceVolumeController]:Play("sound/reward.mp3")
    if not ShowFinishQuestTextImage then
        self.ItemView.view.top.GetItemTextImage.gameObject:SetActive(true)         
    end
end
function View:ShowHeroToFrameTip()
    self.ItemView.Group.heroToFrameTip.gameObject:SetActive(true)  
end

function View:ShowFinishQuestTextImage()
    ShowFinishQuestTextImage=true
    self.ItemView.view.top.FinishQuestTextImage.gameObject:SetActive(true)
    self.fxTab=self.fxTab or {}
    --self.ItemView.Btns.tips.gameObject:SetActive(false)
end

function View:ShowCharacterExpChange(data)
    local oldExp=data and data[1]
    local Exp=data and data[2]
    --self.ItemView.Btns.tips.gameObject:SetActive(true)
    self.ItemView.view.characters.gameObject:SetActive(true)

    PlayerModule.Get(PlayerModule.GetSelfID(),function ( ... )
        if self.ItemView then
            local player=PlayerModule.Get(PlayerModule.GetSelfID());
            player.vip=player.vip or 0

            local slot=self.ItemView.view.characters.Slot
            slot.scaler.CharacterIcon[SGK.CharacterIcon]:SetInfo(player,true)
            local icon = slot.scaler.CharacterIcon[SGK.CharacterIcon]

            slot.Name[UI.Text].text=tostring(player.name)
            local hero= HeroModule.GetManager():Get(11000)
            local hero_level_up_config = HeroLevelup.GetExpConfig(1, hero);
            local Level_exp = hero_level_up_config[hero.level]
            local Next_hero_level_up = hero_level_up_config[hero.level+1] and hero_level_up_config[hero.level+1] or hero_level_up_config[hero.level]
                 
            local get_Exp=Exp-oldExp or 0
            local level_AddExp=Exp - Level_exp

            if level_AddExp<get_Exp then
                --升级了
                icon.level =hero.level-1
                local Last_hero_level_up=hero_level_up_config[hero.level-1] and hero_level_up_config[hero.level-1] or hero_level_up_config[hero.level]
                slot.Exp[UI.Image].fillAmount = (oldExp- Last_hero_level_up) / (Level_exp-Last_hero_level_up);
                slot.Exp[UI.Image]:DOFillAmount(1,0.5):OnComplete(function ( ... )
                    --print("特效")
                    local prefab = SGK.ResourcesManager.Load("prefabs/effect/UI/fx_icon_up.prefab");
                    local o = prefab and UnityEngine.GameObject.Instantiate(prefab,slot.scaler.gameObject.transform);
                    local _durtion=0
                    if o then
                        o.transform.localPosition =Vector3.zero;
                        o.transform.localScale = Vector3.one
                        o.transform.localRotation = Quaternion.identity;
                        local _obj = o:GetComponentInChildren(typeof(UnityEngine.ParticleSystem))
                        _obj:Play()
                        _durtion=_obj.main.duration
                        UnityEngine.Object.Destroy(o, _obj.main.duration)
                    end
                    self.ItemView.transform:DOScale(Vector3.one,0.1):OnComplete(function ( ... )
                        icon.level =hero.level
                        slot.Exp[UI.Image].fillAmount=0
                        slot.Exp[UI.Image]:DOFillAmount((hero.exp - Level_exp) / (Next_hero_level_up - Level_exp),0.5):OnComplete(function ( ... )
                            if slot.ExpValue then
                                slot.ExpValue[UI.Text].text = hero and string.format("+%s",math.ceil(get_Exp)) or "";
                            end
                        end)
                    end)                          
                end):SetDelay(1)
            else     
                icon.level =hero.level      
                slot.Exp[UnityEngine.UI.Image].fillAmount = (oldExp- Level_exp) / (Next_hero_level_up - Level_exp);
                slot.Exp[UnityEngine.UI.Image]:DOFillAmount((hero.exp - Level_exp) / (Next_hero_level_up - Level_exp),0.5):OnComplete(function ( ... )
                    slot.ExpValue[UnityEngine.UI.Text].text = hero and string.format("+%s",math.ceil(get_Exp)) or "";
                end):SetDelay(1)
            end
        end
    end)

    PlayerInfoHelper.GetPlayerAddData(0,nil,function (addData)
        if self.ItemView then
            self.ItemView.view.characters.Slot.scaler.CharacterIcon[SGK.CharacterIcon].sex = addData.Sex
            self.ItemView.view.characters.Slot.scaler.CharacterIcon[SGK.CharacterIcon].headFrame = addData.HeadFrame
        end
    end)
end

-- utils.EventManager.getInstance():addListener("SCENE_LOADED", function(event, name)
--     ChangeScene=true
-- end)

local OnCloseViewFun=nil
function View:OnClearItemTip(fun)
    OnCloseViewFun = fun
    -- PopUpTipsQueue();

end

function View:OnDisable( ... )
    if OnCloseViewFun then
       OnCloseViewFun()
       OnCloseViewFun=nil 
    end
    self.ItemView=nil
end

return View;