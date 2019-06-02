local Time=require "module.Time"
local noticeFrame = {}

function noticeFrame:Start()
	self.Root =CS.SGK.UIReference.Setup(self.gameObject)
	self.view=self.Root.view

	self.view.gameObject:GetComponent(typeof(UnityEngine.RectTransform)):DOSizeDelta(CS.UnityEngine.Vector2(745,1114),0.5):OnComplete(function ( ... )
		self.view.content[UnityEngine.CanvasGroup]:DOFade(1,0.5)
		self:initUi()
	end)
end

function noticeFrame:deActive(deActive)
	if self.view then
		local co = coroutine.running();
		self.view.content[UnityEngine.CanvasGroup]:DOFade(0,0.3):OnComplete(function ( ... )
			self.view.gameObject:GetComponent(typeof(UnityEngine.RectTransform)):DOSizeDelta(CS.UnityEngine.Vector2(0,0),0.5):OnComplete(function ( ... )
				coroutine.resume(co);
			end)
		end)
		coroutine.yield();
		return true
	end
end
function noticeFrame:initUi()
	self.view[SGK.NoticeWebView].enabled=true

	CS.UGUIClickEventListener.Get(self.Root.mask.gameObject).onClick = function (obj) 
		CS.UnityEngine.GameObject.Destroy(self.Root.gameObject)
	end
	CS.UGUIClickEventListener.Get(self.view.content.Button.gameObject).onClick = function (obj) 
		CS.UnityEngine.GameObject.Destroy(self.Root.gameObject)
	end

	self.view.content.Tip.gameObject.transform:DORotate(Vector3(0,180,0),1):SetLoops(-1,CS.DG.Tweening.LoopType.Yoyo):SetEase(CS.DG.Tweening.Ease.InQuad)
end



return noticeFrame