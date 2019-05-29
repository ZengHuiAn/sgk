local unionScene = {}

function unionScene:Start()
    self:initData()
    self:initUi()
    self:upRedDot()
end

function unionScene:initData()
    self.redDotTab = {
        ["exploreTextLab"] = {red = module.RedDotModule.Type.Union.Explore},
        ["signinTextLab"] = {red = module.RedDotModule.Type.Union.Info, red1 = module.RedDotModule.Type.Union.Join},
        ["joinTextLab"] = {red = module.RedDotModule.Type.Union.Join},
        ["wishTextLab"] = {red = module.RedDotModule.Type.Union.Wish},
    }
end

function unionScene:upRedDot()
    for k,v in pairs(self.redDotTab) do
        if self.view[k] and self.view[k].fx_juntuan_tishi then
            if v.red1 then
                self.view[k].fx_juntuan_tishi:SetActive(module.RedDotModule.GetStatus(v.red) or module.RedDotModule.GetStatus(v.red1))
            else
                self.view[k].fx_juntuan_tishi:SetActive(module.RedDotModule.GetStatus(v.red))
            end
        end
    end
end

function unionScene:initUi()
    self.view = CS.SGK.UIReference.Setup(self.gameObject)
    CS.ModelClickEventListener.Get(self.view.exploreTextLab.gameObject).onClick = function(go, pos)
        utils.MapHelper.OpUnionExplore()
    end
    CS.ModelClickEventListener.Get(self.view.unionListTextLab.gameObject).onClick = function(go, pos)
        utils.MapHelper.OpUnionList()
    end
    CS.ModelClickEventListener.Get(self.view.signinTextLab.gameObject).onClick = function(go, pos)
        utils.MapHelper.OpUnionInfo()
    end
    CS.ModelClickEventListener.Get(self.view.joinTextLab.gameObject).onClick = function(go, pos)
        utils.MapHelper.OpUnionJoin()
    end
    CS.ModelClickEventListener.Get(self.view.memberTextLab.gameObject).onClick = function(go, pos)
        utils.MapHelper.OpUnionMember()
    end
    CS.ModelClickEventListener.Get(self.view.wishTextLab.gameObject).onClick = function(go, pos)
        utils.MapHelper.OpUnionWish()
    end
    CS.ModelClickEventListener.Get(self.view.shopTextLab.gameObject).onClick = function(go, pos)
        utils.MapHelper.OpUnionShop()
    end
end

function unionScene:listEvent()
    return {
        "LOCAL_UNION_LEAVEUNION",
        "LOCAL_REDDOT_UNION_CHANE",
    }
end

function unionScene:onEvent(event, data)
    if event == "LOCAL_UNION_LEAVEUNION" then
        SceneStack.EnterMap(10)
    elseif event == "LOCAL_REDDOT_UNION_CHANE" then
        self:upRedDot()
    end
end

return unionScene
