local battleCfg = require "config.battle"
local View = {};
function View:Start(data)
    self.view = CS.SGK.UIReference.Setup(self.gameObject);
    self.role_id = data and data.role_id or 11001;
    self.bossCfg = battleCfg.LoadLimitBoss(self.role_id);
    self.updateTime = 0;
    self.closeTime = 60 + module.Time.now();
    self.endTime = data and data.endTime or -1;
	self:InitView();
end

function View:InitView()
	CS.UGUIClickEventListener.Get(self.view.BG.gameObject, true).onClick = function ( object )
        self:Close();
    end
    CS.UGUIClickEventListener.Get(self.view.info.go.gameObject).onClick = function ( object )
        DialogStack.PushPrefStact("mapSceneUI/timeBoss");
        UnityEngine.GameObject.Destroy(self.gameObject);
    end
    
    local _pos, _scale = DATABASE.GetBattlefieldCharacterTransform(tostring(self.role_id), "timeMonster")
	if _pos and _scale then
		self.view.boss.transform.localPosition = _pos + Vector3(0,0,0)
		self.view.boss.transform.localScale = _scale
    end
    self.view.boss[CS.Spine.Unity.SkeletonGraphic].skeletonDataAsset = SGK.ResourcesManager.Load("roles/"..self.role_id.."/"..self.role_id.."_SkeletonData.asset")
    self.view.boss[CS.Spine.Unity.SkeletonGraphic]:Initialize(true)
    self.view.boss[CS.Spine.Unity.SkeletonGraphic].AnimationState:SetAnimation(0, "idle", true)
    self.view.info.des[UI.Text].text = self.bossCfg.des
    self.view.talk.Text[UI.Text].text = self.bossCfg.dialogue
    self.view.talk.transform:DOScale(Vector3.one, 0.5):SetEase(CS.DG.Tweening.Ease.OutBack):SetDelay(1);
    if self.endTime > 0 then
        self.view.info.time.Text[UI.Text]:TextFormat("剩余时间 {0}", GetTimeFormat(self.endTime, 2, 2));
        self.view.info.time:SetActive(true);
    else
        self.view.info.time:SetActive(false);
    end
end

function View:Close()
    self.view[UnityEngine.CanvasGroup]:DOFade(0, 0.3):OnComplete(function ()
        DispatchEvent("BOSS_TIP_CLOSE");
        UnityEngine.GameObject.Destroy(self.gameObject);
    end)
end

function View:Update()
    if module.Time.now() - self.updateTime >= 1 then
        self.updateTime = module.Time.now();
        local time = self.closeTime - module.Time.now();
        if time > 0 then
            self.view.Text[UI.Text]:TextFormat("点击空白处关闭（{0}s）", time);
        elseif time == 0 then
            self:Close();
        end
        if self.endTime > 0 then
            self.view.info.time.Text[UI.Text]:TextFormat("剩余时间 {0}", GetTimeFormat(self.endTime, 2, 2));
            self.endTime = self.endTime - 1;
        elseif self.endTime == 0 then
            self.endTime = self.endTime - 1;
            self.view.info.time:SetActive(false);
        end
    end
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