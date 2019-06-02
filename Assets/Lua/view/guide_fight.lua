-- 9999901	陆水银
-- 9999902	华羚
-- 9999903	双子星
-- 9999904	西风
-- 9999905	钛小锋
-- 9999906	石心子
-- 9999907	洛根
-- 9999908	马仕达
-- 9999909	蓝琪儿
-- 9999910	蓝田玉
--self.view.transform:DOScale(Vector3(1, 1, 1), 1):OnComplete(function()
-- 陆水银	这就是零号关卡的入口处，我们必须守住这里！
-- 华羚	我们真的可以守住零号关卡吗？
-- 钛小峰	当然！没有人可以阻挡我的道路！
-- 西风	西风讨厌等待。
-- 石心子	抱歉各位，让你们久等了！
-- 陆水银	石心子，玉棺就派了你过来吗？
-- 石心子	烦人的小老鼠，让我送你和其他守墓人团聚吧！
-- 陆水银	你们今天注定失败！

local MapConfig = require "config.MapConfig"
local UserDefault = require "utils.UserDefault"

local guide_fight = {}

function guide_fight:colseUI()
    local _mapScene = UnityEngine.GameObject.Find("mapSceneUI(Clone)")
    if _mapScene then
        _mapScene:SetActive(false)
    end
    local _player = UnityEngine.GameObject.Find("CharacterPrefab(Clone)")
    if _player then
        _player:SetActive(false)
    end
    local _eventSystem = UnityEngine.GameObject.Find("MapSceneController/EventSystem")
    if _eventSystem then
        _eventSystem:SetActive(false)
    end
end

function guide_fight:Npc_showDialog(id, desc, delay, duration, type)
    self.view.transform:DOScale(Vector3(1, 1, 1), delay):OnComplete(function() LoadNpcDesc(id, desc, nil, type, duration)  end)
end

function guide_fight:Npc_move(obj, Vector, delay, is_shunyi)
    local x,y,z = Vector.x,Vector.y,Vector.z
    self.view.transform:DOScale(Vector3(1, 1, 1), delay):OnComplete(function() obj[SGK.MapPlayer]:MoveTo(Vector3(x,y,z),is_shunyi) end)
end

function guide_fight:Npc_changeDirection(obj, direction, delay)
    self.view.transform:DOScale(Vector3(1, 1, 1), delay):OnComplete(function() 
        obj[SGK.MapPlayer]:SetDirection(direction) 
    end)
end

function guide_fight:Load_Camera(obj, delay)
    self.view.transform:DOScale(Vector3(1, 1, 1), delay):OnComplete(function() obj:SetActive(true) end)
end


function guide_fight:Play_Animation(obj, animation1, delay, animation2, duration)
    self.view.transform:DOScale(Vector3(1, 1, 1), delay):OnComplete(function()
        obj.Root.spine:GetComponent(typeof(CS.Spine.Unity.SkeletonAnimation)).AnimationName = animation1
        if not animation2 then
            return
        end
        self.view.transform:DOScale(Vector3(1, 1, 1), duration):OnComplete(function()
            obj.Root.spine:GetComponent(typeof(CS.Spine.Unity.SkeletonAnimation)).AnimationName = animation2            
        end)
    end)
end

function guide_fight:Load_OP(effect, duration ,delay)
    local duration = duration or 5
    local cj = SGK.ResourcesManager.Load("prefabs/effect/"..effect .. ".prefab")

    if delay then
        self.view.transform:DOScale(Vector3(1, 1, 1), delay):OnComplete(function()
            local _cj = CS.UnityEngine.GameObject.Instantiate(cj)
            UnityEngine.GameObject.Destroy(_cj.gameObject,duration)
        end)
    else
        local _cj = CS.UnityEngine.GameObject.Instantiate(cj)
        UnityEngine.GameObject.Destroy(_cj.gameObject,duration)
    end
end

function guide_fight:Load_Effect(Vector, delay)
    local effect = SGK.ResourcesManager.Load("prefabs/effect/fx_xiayazhixin.prefab")
    local _effect = CS.UnityEngine.GameObject.Instantiate(effect)
    _effect.gameObject.transform.localPosition = Vector

    self.view.transform:DOScale(Vector3(1, 1, 1), delay):OnComplete(function()
        _effect.gameObject:SetActive(true)
        UnityEngine.GameObject.Destroy(_effect.gameObject,8)
    end)
end

function guide_fight:PlaySound(sound, delay, type) 
    if self.audioSource_1 == nil then
        self.audioSource_1 = self.view.Canvas[SGK.AudioSourceVolumeController]
    end
  
    if self.audioSource_2 == nil then
        self.audioSource_2 = self.view.Canvas.Image[SGK.AudioSourceVolumeController]
    end
    if type == 2 then
        self.view.transform:DOScale(Vector3(1, 1, 1), delay):OnComplete(function() self.audioSource_2:Play("sound/" .. sound) end)
    else
        self.view.transform:DOScale(Vector3(1, 1, 1), delay):OnComplete(function() self.audioSource_1:Play("sound/" .. sound) end)
    end
end


function guide_fight:GetObj()
    self.npc1 = module.NPCModule.GetNPCALL(9999901)
    self.npc2 = module.NPCModule.GetNPCALL(9999902)
    self.npc3 = module.NPCModule.GetNPCALL(9999903)
    self.npc4 = module.NPCModule.GetNPCALL(9999904)
    self.npc5 = module.NPCModule.GetNPCALL(9999905)
    self.npc6 = module.NPCModule.GetNPCALL(9999906)
    self.npc7 = module.NPCModule.GetNPCALL(9999907)
    self.npc8 = module.NPCModule.GetNPCALL(9999908)
    self.npc9 = module.NPCModule.GetNPCALL(9999909)
    self.npc10 = module.NPCModule.GetNPCALL(9999910)
end

function guide_fight:Start(data)
    self.view = CS.SGK.UIReference.Setup(self.gameObject)

    local guideFight = UserDefault.Load("guide_fight")
    -- self.view.Canvas.Button:SetActive(guideFight and guideFight.first)
    self.view.Canvas.Button:SetActive(true)

    self.view.Canvas.Button[CS.UGUIClickEventListener].onClick = function()
        showDlg(nil, "是否跳过序章剧情", function()
            StartScene('create_character', 'view/create_character.lua')
        end, function()
        end)
    end

    if data and data.fight then
        self.view.MainCamera_op_3:SetActive(true)
        self.view.MainCamera_op_1:SetActive(false)
        self:After_Fight()
    else
        self.view.MainCamera_op_1:SetActive(false)
        self:Load_OP("op_cj", 7.2)
        self:PlaySound("xinshou_leidian",0.1,2)
        self.view.transform:DOScale(Vector3(1, 1, 1), 7.1):OnComplete(function() self:Before_Fight() end)
    end
end

function guide_fight:Before_Fight()
    self.view.MainCamera_op_1:SetActive(true)

    self:colseUI()
    self:GetObj()
    
    self:Npc_move(self.npc1,Vector3(3.72, 0, 7.885),1)--下楼梯（主角）
    self:PlaySound("xinshou_jiaobu1",1,2)--脚步声

    --self:Npc_showDialog(9999905,"(ˉ▽￣～) 切~~", 2, 1 ,1)--钛小锋聊天

    -- self:Play_Animation(self.npc5, "jump2", 1)

    --[[
    self:PlaySound("lushuiyin_0001",3)
    self:PlaySound("lushuiyin_0001",6.5)
    self:PlaySound("lushuiyin_0002",11)
    self:PlaySound("hualing_0001",14)
    self:PlaySound("taixiaofeng_0002",19)
    self:PlaySound("xifeng_0001",24)
    self:PlaySound("shixinzi_0001",27)
    self:PlaySound("shixinzi_0002",33) 
    self:PlaySound("lushuiyin_0003",41)
    self:PlaySound("lushuiyin_0004",43) 
    ]]

--(id, desc, delay, duration, type)

    self:Npc_showDialog(9999902,"!!", 3, 1 ,1)--华羚聊天
    self:Npc_showDialog(9999903,"??", 4, 1 ,3)
    self:Npc_showDialog(9999901,"这里是零号关卡的最后一道防线！", 6.5, 1 ,1)--召集队友
    self:PlaySound("lushuiyin_0001",6.5)
    self:Npc_showDialog(9999902,"!!!",7,1,2)--惊讶
    self:Npc_showDialog(9999903,"!!!",7,1,2)
    self:Npc_showDialog(9999904,"!!!",7,1,2)
    self:Npc_showDialog(9999905,"!!!",7,1,2)

    self:Npc_move(self.npc2,Vector3(2.32, 1.4, 8.89),7)--移动水银位置
    self:PlaySound("xinshou_jiaobu2",7,2)--脚步声
    self:Npc_move(self.npc3,Vector3(4.5, 1.4, 8.34),7)
    self:Npc_move(self.npc4,Vector3(3.409, 1.8, 8.9),7)
    self:Npc_move(self.npc5,Vector3(4.1, 1.8, 8.9),7)

    self:Npc_changeDirection(self.npc1, 4, 6)--说话转面向（主角）
    self:Npc_changeDirection(self.npc2, 6, 9.5)

    self:Npc_showDialog(9999901,"按照计划，我们必须要拖住玉棺！", 10.5, 1 ,1)
    self:PlaySound("lushuiyin_0002",10.5)
    self:Npc_showDialog(9999902,"哼！这种事可难不倒本小姐！",14,1,2 )
    self:PlaySound("hualing_0001",14)
    --self:Play_Animation(self.npc5, "jump2", 18, "idle1", 1)
    self:Npc_showDialog(9999905,"...",17,0.3,1)
    self:Npc_showDialog(9999904,"西风讨厌等待。",18,1,1)
    self:PlaySound("xifeng_0001",18)

    self:Npc_move(self.npc6,Vector3(3.7, 0, 6.76),19)--出场（玉棺）
    self:PlaySound("xinshou_jiaobu3",19,2)--脚步声
    self:PlaySound("xinshou_jiaobu3_bgm",19,2)--预示敌人出场的危险背景音
    self:Npc_move(self.npc7,Vector3(3, 0, 5.76),19)
    self:Npc_move(self.npc8,Vector3(4.5, 0, 5.76),19)
    self:Npc_move(self.npc9,Vector3(2, 0, 5.36),19.5)
    self:Npc_move(self.npc10,Vector3(5.5, 0, 5.36),19.5)

    self:Npc_showDialog(9999901,"!!!",21.5,1,2)
    self:Npc_showDialog(9999902,"!!!",21.5,1,2)
    self:Npc_showDialog(9999903,"!!!",21.5,1,2)
    self:Npc_showDialog(9999904,"!!!",21.5,1,2)
    self:Npc_showDialog(9999905,"!!!",21.5,1,2)

    self:Npc_changeDirection(self.npc1, 0, 22)--玉棺来袭转面向（主角）
    self:Npc_changeDirection(self.npc2, 0, 22)
    self:Npc_changeDirection(self.npc3, 0, 22)

    self:Npc_showDialog(9999906,"喂！我说……你们可以放弃抵抗吗？",21,2,2)
    self:PlaySound("shixinzi_0001",21)
    self:Npc_showDialog(9999901,"...",24,1,1)
    self:Npc_showDialog(9999902,"...",24,1,1)
    self:Npc_showDialog(9999903,"...",24,1,1)
    self:Npc_showDialog(9999904,"...",24,1,1)
    self:Npc_showDialog(9999905,"...",24,1,1)   
    self:Npc_showDialog(9999906,"真可惜，你们错过了唯一一次逃跑机会！",25.5,5,1)
    self:PlaySound("shixinzi_0002",25)
    self:Npc_showDialog(9999901,"逃跑？",32,1,1)
    self:PlaySound("lushuiyin_0003",32)
    self:Npc_showDialog(9999901,"根本没有必要！",33,1,1) 
    --self:PlaySound("lushuiyin_0004",33)
 
    --self:Npc_showDialog(9999906,"烦人的小老鼠，让我送你和其他守墓人团聚吧！",30,2,2)

    self:Load_Camera(self.view.MainCamera_op_2, 35.2)     --摄像机2

	self:Npc_move(self.npc1,Vector3(3.71, 0.4, 7.14),35)--移动进入战斗（主角）
    self:Npc_move(self.npc6,Vector3(3.75, 0.7, 7.5),35)--移动进入战斗（玉棺）
    self:Npc_move(self.npc7,Vector3(3, 0, 6.7),35)
    self:Npc_move(self.npc8,Vector3(4.5, 0, 6.7),35)
    self:Npc_move(self.npc9,Vector3(2, 0, 6.3),35)
    self:Npc_move(self.npc10,Vector3(5.5, 0.7, 6.3),35)
    self:PlaySound("xinshou_zhandou_qian",35,2)--即将开战的拔剑背景音
    self.view.transform:DOScale(Vector3(1, 1, 1), 35.3):OnComplete(function()
        -- module.fightModule.StartFight(11010100, false, function()
        --     SceneStack.ClearBattleToggleScene()
        --     SceneStack.EnterMap(999)
        -- end)
        local _data = SGK.ResourcesManager.Load("guide_fight.txt", typeof(CS.UnityEngine.TextAsset))
        local fight_data = _data.bytes
        SceneStack.Push('battle', 'view/battle.lua', {
            fight_id = 11010100,
            fight_data = fight_data,
            force_play_as_attacker = true,
            guideFight = true,
            callback = function(win, heros, fightid, starInfo, input_record)
		end})
    end)
end


function guide_fight:After_Fight()
    self:colseUI()
    self:GetObj()

    local guideFight = UserDefault.Load("guide_fight")
    guideFight.first = true
    UserDefault.Save()

    self:Npc_move(self.npc1,Vector3(3.7, 0, 4.854),0,true)--战斗结束NPC站位
    self:Npc_move(self.npc2,Vector3(3.2, 0, 5.3),0,true)
    self:Npc_move(self.npc3,Vector3(4.199, 0, 5.54),0,true)
    self:Npc_move(self.npc4,Vector3(3.38, 0, 6.09),0,true)
    self:Npc_move(self.npc5,Vector3(4.17, 0, 6.57),0,true)
    self:Npc_move(self.npc6,Vector3(3.7, 0, 3.617),0,true)
    self:Npc_move(self.npc7,Vector3(2.32, 0, 6.58),0,true)
    self:Npc_move(self.npc8,Vector3(5.37, 0, 6.71),0,true)
    self:Npc_move(self.npc10,Vector3(2.238, 0, 4.36),0,true)
    self:Npc_move(self.npc9,Vector3(5.38, 0, 4.9),0,true)

    self:Npc_changeDirection(self.npc1, 0, 0.5)--主角面向
    self:Npc_changeDirection(self.npc2, 1, 0.5)
    self:Npc_changeDirection(self.npc3, 7, 0.5)
    self:Npc_changeDirection(self.npc4, 3, 0.5)
    self:Npc_changeDirection(self.npc5, 6, 0.5)

    self:Npc_changeDirection(self.npc6, 4, 0.5)--玉棺面向
    self:Npc_changeDirection(self.npc7, 7, 0.5)
    self:Npc_changeDirection(self.npc8, 2, 0.5)
    self:Npc_changeDirection(self.npc10, 5, 0.5)
    self:Npc_changeDirection(self.npc9, 2, 0.5)

    self:Npc_showDialog(9999906,"没想到你竟然可以把我逼到这种地步。", 2, 3 ,1)
    --self:PlaySound("lanqier_0003",2)
    self:Npc_showDialog(9999906,"接下来就请你见识一下玉棺真正的实力吧！", 6, 3 ,1)
	--self:Npc_showDialog(9999901,"...",6,1,2)
    --self:Npc_showDialog(9999902,"...",6,1,2)
    --self:Npc_showDialog(9999903,"...",6,1,2)
    --self:Npc_showDialog(9999904,"...",6,1,2)
    --self:Npc_showDialog(9999905,"...",6,1,2)
    --self:Npc_showDialog(9999902,"水银……我会和你并肩作战的！",7,1,1 )
    --self:PlaySound("hualing_0003",7)
    --self:Npc_showDialog(9999903,"我可是你的向导，今后还要好好调教你呢！",10.5,1,1)
    --self:PlaySound("shuangzixing_0003",10.5)
    --self:Npc_showDialog(9999904,"o(▼皿▼メ;)o",13,1,1)
    --self:Npc_showDialog(9999905,"……",13,1,1)
	--self:Npc_showDialog(9999901,"大家……",14.5,1,2)
    --self:PlaySound("lushuiyin_0008",14.5)
	--self:Npc_showDialog(9999906,"那你们就一起死吧！",15.5,1,2)
    --self:PlaySound("shixinzi_0005",15.5)

    --self:Npc_move(self.npc9,Vector3(3.87, 0, 4.89),1)--蓝琪儿上前一步

    self:Load_Effect(Vector3(3.72, 2.44, 4), 10)--石心子特效

	self:Load_Camera(self.view.MainCamera_op_4, 12.5)     --摄像机4

    self:Load_OP("op_cj2", 4, 13)

    self.view.transform:DOScale(Vector3(1, 1, 1),14):OnComplete(function()
        StartScene('create_character', 'view/create_character.lua');
    end)
end

return guide_fight
