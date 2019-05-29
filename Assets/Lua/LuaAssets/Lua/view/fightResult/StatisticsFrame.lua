local View={}
function View:Start(data)
	self.view = SGK.UIReference.Setup(self.gameObject);
	
	self.UITab = {}

	CS.UGUIClickEventListener.Get(self.view.gameObject,true).onClick = function()
		CS.UnityEngine.GameObject.Destroy(self.gameObject)
	end

	CS.UGUIClickEventListener.Get(self.view.BG.Close.gameObject).onClick = function()
		CS.UnityEngine.GameObject.Destroy(self.gameObject)
	end

	CS.UGUIClickEventListener.Get(self.view.Damage.gameObject).onClick = function()
		self:InStatisticsPanel(1);
	end

	CS.UGUIClickEventListener.Get(self.view.Hurt.gameObject).onClick = function()
		self:InStatisticsPanel(2);
	end

	CS.UGUIClickEventListener.Get(self.view.Health.gameObject).onClick = function()
		self:InStatisticsPanel(3);
	end

	self.view.Damage[UI.Toggle].isOn=true

	self:updateStatisticsPanel(data)
end

local function updateCharacterIcon(icon,role)
	if icon then  
		local cfg = utils.ItemHelper.Get(utils.ItemHelper.TYPE.HERO,role.id)
		utils.IconFrameHelper.Create(icon,
		{
		customCfg =
					{
						icon = tostring(role.icon),
						level = role.level,
						role_stage = cfg.role_stage,
						star = role.grow_star,
						type=utils.ItemHelper.TYPE.HERO,
					}
		})
	end
end

local function GetRoleList(list)
	local tab = {roles ={}}
	for k,v in pairs(list) do
		local _tab = {pid = k,list = {}}
		for i=1,#v do
			_tab.list[i] = v[i]
		end
		table.insert(tab.roles,_tab)
	end
	return tab
end

function View:SortList(index)
	if index ==1 then
		self.list.totalValue = 0
		for i=1,#self.list.roles do
			self.list.roles[i].totalValue = 0
			for j=1,#self.list.roles[i].list do
				self.list.roles[i].list[j].value = self.list.roles[i].list[j].damage
				self.list.roles[i].totalValue = self.list.roles[i].totalValue + self.list.roles[i].list[j].damage
			end

			table.sort(self.list.roles[i].list,function (a,b)
				if a.value~= b.value then
					return a.value > b.value
				end
				return a.id<b.id
			end)

			self.list.totalValue = self.list.totalValue+ self.list.roles[i].totalValue
		end
		table.sort(self.list.roles,function (a,b)
			if a.totalValue ~= b.totalValue then
				return a.totalValue > b.totalValue
			end
			return a.pid<b.pid
		end)
	elseif index ==2 then
		self.list.totalValue = 0
		for i=1,#self.list.roles do
			self.list.roles[i].totalValue = 0
			for j=1,#self.list.roles[i].list do
				self.list.roles[i].list[j].value = self.list.roles[i].list[j].hurt
				self.list.roles[i].totalValue = self.list.roles[i].totalValue + self.list.roles[i].list[j].hurt
			end
			table.sort(self.list.roles[i].list,function (a,b)
				if a.value~= b.value then
					return a.value > b.value
				end
				return a.id<b.id
			end)

			self.list.totalValue = self.list.totalValue+ self.list.roles[i].totalValue
		end
		table.sort(self.list.roles,function (a,b)
			if a.totalValue ~= b.totalValue then
				return a.totalValue > b.totalValue
			end
			return a.pid<b.pid
		end)
	elseif index ==3 then
		self.list.totalValue = 0
		for i=1,#self.list.roles do
			self.list.roles[i].totalValue = 0
			for j=1,#self.list.roles[i].list do
				self.list.roles[i].list[j].value = self.list.roles[i].list[j].health
				self.list.roles[i].totalValue = self.list.roles[i].totalValue + self.list.roles[i].list[j].health
			end
			table.sort(self.list.roles[i].list,function (a,b)
				if a.value~= b.value then
					return a.value > b.value
				end
				return a.id<b.id
			end)
			self.list.totalValue = self.list.totalValue+ self.list.roles[i].totalValue
		end
		table.sort(self.list.roles,function (a,b)
			if a.totalValue ~= b.totalValue then
				return a.totalValue > b.totalValue
			end
			return a.pid<b.pid
		end)
	end
end

function View:updateStatisticsPanel(data)	
    self.list = GetRoleList(data[1])
    self.IsTeam = data[2]

    self.view.List[UI.GridLayoutGroup].cellSize = CS.UnityEngine.Vector2(620,self.IsTeam and 140 or 120)
    self.view.List[UI.GridLayoutGroup].spacing = CS.UnityEngine.Vector2(0,self.IsTeam and 15 or 7)
    
    self:InStatisticsPanel(1)
end

function View:InStatisticsPanel(index)
    self.view = SGK.UIReference.Setup(self.view.gameObject);
    for i=1,self.view.List.transform.childCount do
    	self.view.List.transform:GetChild(i-1).gameObject:SetActive(false)
    end
    
	self:SortList(index)

    local rolesCount = self.IsTeam and #self.list.roles or #self.list.roles[1].list
    for i=1,rolesCount do
		local obj = nil
    	if i <= self.view.List.transform.childCount then
    		obj = self.view.List.transform:GetChild(i-1).gameObject
    	else
    		local prefab = self.view.List[1].gameObject
            obj = CS.UnityEngine.GameObject.Instantiate(prefab,self.view.List.transform)
            obj.transform.localPosition = Vector3.zero
    	end
    	obj:SetActive(true)
    	local ItemGroup = SGK.UIReference.Setup(obj);
		ItemGroup.personal:SetActive(not self.IsTeam)
		ItemGroup.member:SetActive(not not self.IsTeam)

		local Item = nil
		if self.IsTeam then
			Item = ItemGroup.member
			self:InTeamMember(Item,i)
		else
			Item = ItemGroup.personal
			self:Inpersonal(Item,i)
		end
    end
end

function View:InTeamMember(Item,idx)
	local Cfg = self.list.roles[idx]
	local pid = self.list.roles[idx].pid
	local teamTotalValue = self.list.totalValue ~= 0 and self.list.totalValue or 100

	if module.playerModule.IsDataExist(pid) then
		Item.name[UI.Text].text = module.playerModule.IsDataExist(pid).name
	else
		module.playerModule.Get(pid,(function( ... )
			Item.name[UI.Text].text = module.playerModule.IsDataExist(pid).name
		end))
	end

	utils.PlayerInfoHelper.GetPlayerAddData(pid,99,function (addData)
		Item.sex[CS.UGUISpriteSelector].index = addData.Sex
	end)

	Item.AddBtn:SetActive(pid~= module.playerModule.GetSelfID())
	CS.UGUIClickEventListener.Get(Item.AddBtn.gameObject).onClick = function()
		utils.PlayerInfoHelper.GetPlayerAddData(pid, utils.PlayerInfoHelper.ServerAddDataType.UNIONANDTEAMSTATUS, function(addData)
			module.unionModule.AddFriend(pid)
		end)
	end

	for i=1,#Cfg.list do
		local heroCfg = utils.ItemHelper.Get(utils.ItemHelper.TYPE.HERO,Cfg.list[i].id)
		Item.List[i]:SetActive(true)
		utils.IconFrameHelper.Create(Item.List[i].IconFrame,
		{
			customCfg =
				{
					icon = tostring(Cfg.list[i].mode),
					level = Cfg.list[i].level,
					role_stage = heroCfg.role_stage,
					star = Cfg.list[i].grow_star,
					type=utils.ItemHelper.TYPE.HERO,
				}, 
			func = function (obj)
				-- obj.LowerRightText:SetActive(false)
				-- obj.Star:SetActive(false)
			end
		})

		local pesonalTotalValue = Cfg.totalValue ~= 0 and Cfg.totalValue or 100 
		Item.List[i].Value[UI.Text].text = Cfg.list[i].value
		Item.List[i].hpbg.Exp.transform.localScale = Vector3(Cfg.list[i].value /pesonalTotalValue ,1,1);
		Item.List[i].hpbg.Percent[UnityEngine.UI.Text].text = math.floor((Cfg.list[i].value/pesonalTotalValue) * 100) .. "%";
	end
	
	Item.Value:TextFormat("{0}", Cfg.totalValue)
	Item.hpbg.Exp.transform.localScale = Vector3(Cfg.totalValue / teamTotalValue,1,1);
	Item.hpbg.Percent[UnityEngine.UI.Text].text = math.floor(Cfg.totalValue / teamTotalValue * 100) .. "%";

end

function View:Inpersonal(Item,idx)
	local totalValue = self.list.roles[1].totalValue~= 0 and self.list.roles[1].totalValue or 100
	local cfg = self.list.roles[1].list[idx]
	Item.name[UI.Text].text = cfg.name;
	local heroCfg = utils.ItemHelper.Get(utils.ItemHelper.TYPE.HERO,cfg.id)
	utils.IconFrameHelper.Create(Item.IconFrame,
		{
			customCfg =
				{
					icon = tostring(cfg.mode),
					level = cfg.level,
					role_stage = heroCfg.role_stage,
					star = cfg.grow_star,
					type=utils.ItemHelper.TYPE.HERO,
				},
			func = function (obj)
				-- obj.LowerRightText:SetActive(false)
				-- obj.Star:SetActive(false)
			end
		})

	Item.Value:TextFormat("{0}", cfg.value)
	Item.hpbg.Exp.transform.localScale = Vector3(cfg.value /totalValue ,1,1);
	Item.hpbg.Percent[UnityEngine.UI.Text].text = math.floor((cfg.value/totalValue) * 100) .. "%";
end

function View:listEvent()
	return {
		""
	}
end

function View:onEvent(event)
	if event == "" then
	
	end
end

return View;
