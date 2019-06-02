local View = {};
function View:Start(data)
    self.root = CS.SGK.UIReference.Setup(self.gameObject);
    self.view =  self.root.view;
	self:InitData();
	self:InitView();
	module.guideModule.PlayByType(131)
end

function View:InitData()
	self.btnInfo = {
		[2] = {dialog = "rankList/rankListFrame"},
		[3] = {dialog = "dataBox/suitsManualFrame"},
		[4] = {dialog = "dataBox/UnionOverview", red = module.RedDotModule.Type.DataBox.UnionData},
		[5] = {dialog = "dataBox/NpcRelationship", red = module.RedDotModule.Type.DataBox.NpcData},
        [8] = {dialog = "newAchievement/newAchievement",red = module.RedDotModule.Type.Achievement.Achievement},
	}
end

function View:InitView()
	for k,v in pairs(self.btnInfo) do
		CS.UGUIClickEventListener.Get(self.view["Image"..k].gameObject, true).onClick = function ( object )
			DialogStack.Push(v.dialog);
		end
		CS.UGUIClickEventListener.Get(self.view["btn"..k].gameObject).onClick = function ( object )
			DialogStack.Push(v.dialog);
		end
		if v.red then
			self.view["btn"..k].red:SetActive(module.RedDotModule.GetStatus(v.red));
			self.view["btn"..k].red.transform:DOScale(Vector3(1.2, 1.2, 1.2),0.5):SetLoops(-1,CS.DG.Tweening.LoopType.Yoyo):SetEase(CS.DG.Tweening.Ease.InQuad)
		else
			self.view["btn"..k].red:SetActive(false);
		end
	end
	local resourcesBarObj = CS.UnityEngine.GameObject.Instantiate(SGK.ResourcesManager.Load("prefabs/base/CurrencyChat.prefab"), self.view.chat.transform)
	self:UpdateBetterScreenSize(resourcesBarObj)
end

--适应超长屏UI填充
function View:UpdateBetterScreenSize(resourcesBarObj)
    if resourcesBarObj then
        local resourcesBar = CS.SGK.UIReference.Setup(resourcesBarObj)
        if resourcesBar then
            local off_top = resourcesBar.UGUIResourceBar.TopBar[UnityEngine.RectTransform].rect.height
            local off_bottom = resourcesBar.UGUIResourceBar.BottomBar[UnityEngine.RectTransform].rect.height
            local off_H = (self.view[UnityEngine.RectTransform].rect.height-self.view.bg[UnityEngine.RectTransform].rect.height)/2
            if off_top and off_bottom then
                self.view.top[UnityEngine.RectTransform]:SetSizeWithCurrentAnchors(UnityEngine.RectTransform.Axis.Vertical, off_H+ off_top)
                self.view.bottom[UnityEngine.RectTransform]:SetSizeWithCurrentAnchors(UnityEngine.RectTransform.Axis.Vertical, off_H+off_bottom )
            end
        end
    end
end

function View:deActive()
    utils.SGKTools.PlayDestroyAnim(self.gameObject)
	return true;
end

function View:listEvent()
	return {
		"",
	}
end

function View:onEvent(event, ...)
	print("onEvent", event, ...);
	if event == "CLOSE_DATABOX"  then

	end
end

return View;
