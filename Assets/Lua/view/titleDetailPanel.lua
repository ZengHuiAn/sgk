local talentModule = require "module.TalentModule"
local HeroModule = require "module.HeroModule"
local View = {}

function View:Start(data)
	self.view=CS.SGK.UIReference.Setup(self.gameObject);
	self:Init(data);
end

function View:Init(data)
	self.roleID=data and data.Id or 11000
	self.titleData=data and data.title or {}
	self.talentType=data and data.talentType or 4
	self.PageUI={}
	self.CurrIdx=0;

	self:InitView()
	CS.UGUIClickEventListener.Get(self.view.gameObject).onClick = function (obj)
		CS.UnityEngine.GameObject.Destroy(self.view.gameObject) 
	end
end

function View:InitView()
	self.hero = HeroModule.GetManager():Get(self.roleID);
	self.talentId   = self.talentType==4 and self.hero.roletalent_id1 or self.hero.roletalent_id2
	self.typePoint = talentModule.CalcTalentGroupPoint(self.titleData, self.talentId);

	self.config     = talentModule.GetTalentConfig(self.talentId);


	self.sizeX=self.view[UnityEngine.RectTransform].sizeDelta.x
	self.view.root.Viewport.Content[UnityEngine.RectTransform].sizeDelta=CS.UnityEngine.Vector2(self.sizeX*#self.typePoint,0)
	for i=1,#self.typePoint do
		local _obj
		if self.PageUI[i] then
			_obj=self.PageUI[i]
		else
			_obj=UnityEngine.Object.Instantiate(self.talentType==4 and self.view.detailPanel.gameObject or self.view.detailPanel_Product.gameObject)
			self.PageUI[i]=_obj
			_obj.transform:SetParent(self.view.root.Viewport.Content.gameObject.transform,false)
			_obj.name=tostring(i)
		end
		_obj.gameObject:SetActive(true)
		local _page=CS.SGK.UIReference.Setup(_obj.transform)
		self:RefPage(_page,i-1)
	end

	self.view.root[CS.UIPageView].enabled =true
	self.UIPageViewScript=self.view.root[CS.UIPageView]
	self.UIPageViewScript.dataCount=#self.typePoint
	self.UIPageViewScript.OnPageChanged =(function (index)
     	self.CurrIdx=index
   	end)

	-- SGK.Action.DelayTime.Create(0.2):OnComplete(function()
	-- 	for i=1,#self.typePoint do
	-- 		if self.typePoint[i]~=0 then
	-- 			self.CurrIdx=i-1
	-- 			self.UIPageViewScript:pageTo(self.CurrIdx)
	-- 			break
	-- 		end
	-- 	end
	-- end)
end

function View:RefPage(page,Idx)
	local length=#self.config/#self.typePoint
	local _tab={}
	for i=1,length do
		local cfg=self.config[Idx*length+i]
		page.aliveItem[i].Item.Icon[UI.Image]:LoadSprite("icon/".."ch_"..string.format("%02d",cfg.icon_id))
		page.aliveItem[i].Item.name[UI.Text].text=cfg.name

		local isperc = false
		if string.find(cfg.desc, "%%%%") ~= nil then
			isperc = true;
		end

		local _value={}

		for j=1,4 do
			if self.titleData[Idx*length+i]~=0 then
				table.insert(_value,tostring(isperc and (cfg["init_value"..j]+cfg["incr_value"..j]*(self.titleData[Idx*length+i]-1))/100 or (cfg["init_value"..j]+cfg["incr_value"..j]*(self.titleData[Idx*length+i]-1))))
			else
				table.insert(_value,tostring(isperc and (cfg["init_value"..j]+cfg["incr_value"..j]*(self.titleData[Idx*length+i]))/100 or (cfg["init_value"..j]+cfg["incr_value"..j]*(self.titleData[Idx*length+i]))))
			end
		end
	
		page.aliveItem[i].Item.desc[UI.Text].text=cfg.incr_value1==0 and  cfg.desc or string.format(cfg.desc,_value[1],_value[2],_value[3],_value[4])
		page.aliveItem[i].Item.choose.gameObject:SetActive(self.titleData[Idx*length+i]~=0)

		if self.titleData[Idx*length+i]~=0 then
			table.insert(_tab,i)
		end
	end

	page.leftBtn.gameObject:SetActive(Idx~=0)
	page.rightBtn.gameObject:SetActive(Idx+1~=#self.config/length)

	local id=1;
	for i=#self.titleData,1,-1 do
		if self.titleData[i]~=0 then
			id=i
			break
		end
	end

	if page.leftBtn.gameObject.activeSelf then--左侧按钮
		local cfg=self.typePoint[Idx]~=0 and self.config[id] or self.config[(Idx-1)*length+1]
		page.leftBtn.titleItem[SGK.TitleItem]:SetInfo(cfg)
	end
	if page.rightBtn.gameObject.activeSelf then--右侧按钮 第一页 第二页显示
		local cfg=self.typePoint[Idx+2]~=0 and self.config[id] or self.config[(Idx+1)*length+1]
		page.rightBtn.titleItem[SGK.TitleItem]:SetInfo(cfg)
	end

	CS.UGUIClickEventListener.Get(page.leftBtn.gameObject).onClick = function (obj)
		if self.CurrIdx >0 then
			self.CurrIdx=self.CurrIdx-1;
			self.UIPageViewScript:pageTo(self.CurrIdx)
		end
	end
	
	CS.UGUIClickEventListener.Get(page.rightBtn.gameObject).onClick = function (obj)
		if  self.CurrIdx<length then
			self.CurrIdx=self.CurrIdx+1
			self.UIPageViewScript:pageTo(self.CurrIdx)
		end
	end

	for i=1,12 do
		if page.aliveLine[i] then
			page.aliveLine[i].gameObject:SetActive(false)
		end
	end

	if self.talentType==4 then
		if self.typePoint[Idx+1]~=0 then
			if next(_tab)~=nil then
				if _tab[2] then -- 2   3
				 	page.aliveLine[ _tab[2]-1].gameObject:SetActive(true)
				end
				if _tab[3] then-- 4  5    5  6
					page.aliveLine[ _tab[2]== 2 and _tab[3]-1  or _tab[3]].gameObject:SetActive(true)
				end
				if _tab[4] then --7    8     89    9 10
					page.aliveLine[ (_tab[3]== 4 and _tab[4] ) or (_tab[3]==5 and _tab[4]+1 ) or  (_tab[3]==6 and  _tab[4]+2 )].gameObject:SetActive(true)
				end
			end
		end
	else
		if next(_tab)~=nil then
			for i=1,#_tab do
				if page.aliveLine[_tab[i]-1] then
					page.aliveLine[_tab[i]-1].gameObject:SetActive(true)
				end
			end
		end
	end
end
return View;
