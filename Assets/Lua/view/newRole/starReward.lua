local ParameterConf = require "config.ParameterShowInfo"
local starReward = {}

function starReward:Start(data)
    self:initData(data)
    self:initUi()
end

function starReward:initData(data)
    self.heroId = data.heroId
    self.now = data.nowStar
    self.next = data.nextStar
    self.props = data.props
    self.heroManager =module.HeroModule.GetManager()
    self.hero = self.heroManager:Get(self.heroId)
end

function starReward:initUi()
    self.view = CS.SGK.UIReference.Setup(self.gameObject)
    CS.UGUIClickEventListener.Get(self.view.mask.gameObject, true).onClick = function()
        DialogStack.Pop()
    end
    CS.UGUIClickEventListener.Get(self.view.root.closeBtn.gameObject).onClick = function()
        DialogStack.Pop()
    end
    
    local _nextStar = math.floor(self.next / 6)
    local _nowStar = _nextStar - 1
    for i = 1, #self.view.root.nowStar do
        local _view = self.view.root.nowStar[i]
        _view:SetActive(_nowStar >= i)
    end
    for i = 1, #self.view.root.nextStar do
        local _view = self.view.root.nextStar[i]
        _view:SetActive(_nextStar >= i)
    end
    if _nowStar == 0 then
        self.view.root.nowStar[1]:SetActive(true)
        self.view.root.nowStar[1][UI.Image].material = SGK.QualityConfig.GetInstance().grayMaterial
        self.view.root.nowStar[1][UI.Image].color = UnityEngine.Color(1, 1, 1, 0.5) -- SGK.QualityConfig.GetInstance().grayMaterial
    end

    --self.view.root.desc[UI.Text].text = self.desc
    -- for i = 1, 6 do
    --     local item = self.view.root.desc.info["item"..i];
    --     local prop = self.props[i];
    --     if not prop then
    --         item:SetActive(false);
    --     else
    --         item:SetActive(true);
    --         item.Icon[UI.Image]:LoadSprite("propertyIcon/" .. prop.icon)
    --         item.Text[UnityEngine.UI.Text].text = prop.name;
    --         item.Value[UnityEngine.UI.Text].text = "+" .. prop.value;
    --     end
    -- end
    self:initDesc()
end

function starReward:initDesc()
    local proText = {
    [0]="baseAd",
    [1]="baseArmor",
    [2]="baseHp",
    [3]="speed",
    [4]="initEp",
    }
    local proTextName = {
    [0]="ad",
    [1]="armor",
    [2]="hpp",
    [3]="speed",
    [4]="initEp",
    }
    local _enhanceCfg = self.hero:EnhanceProperty(0,0,0)
    local enhanceCfg = self.hero:EnhanceProperty(0,0,1)
    for i = 0, 2 do
        local _view = self.view.root.desc.info["info"..(i+1)]
        _view.triangle.gameObject:SetActive(false)
        _view.name[UI.Text].text=ParameterConf.Get(proTextName[i]).name
        _view.LVUPBefore[UI.Text].text=math.floor(_enhanceCfg.props[proText[i]])
        _view.LVUPAfter[UI.Text].text=math.floor(enhanceCfg.props[proText[i]])
        _view.AddText.gameObject:SetActive(true)
        _view.AddText[UI.Text].text=string.format("<color=#ffd800>(+%d)</color>",math.floor(enhanceCfg.props[proText[i]])-math.floor(_enhanceCfg.props[proText[i]]))
        _view.triangle.gameObject:SetActive(true)
    end
end

function starReward:OnDestroy()
    local _nextStar = math.floor(self.next / 6)
    local pos = self.view.root.nextStar[_nextStar].transform.localPosition

    local localPos = self.view.root.nextStar.transform:TransformPoint(pos)
    local createPos = self.view.transform:InverseTransformPoint(localPos)
    DispatchEvent("Close_Star_up",{createPos,_nextStar})
end

return starReward
