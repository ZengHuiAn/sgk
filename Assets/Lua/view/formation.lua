
local HeroModule = require "module.HeroModule"

local View = {}

function View:Start(args)
	self.view = SGK.UIReference.Setup();

	self.listIcons = {};

	self.online = {0, 0, 0, 0, 0}

	for k, v in ipairs(HeroModule.GetManager():GetFormation()) do
		self.online[k] = v or 0;
	end

	self.select_index = 0;

	self:UpdateOnline();
	self:UpdateHeroList();

	local this = self;
	self.view.Save[CS.UGUIClickEventListener].onClick = function()
		this:SaveData();
	end

	self.view.StartBattle.gameObject:SetActive(not not (args and args.fight_id and args.fight_id ~= 0))

	self.view.StartBattle[CS.UGUIClickEventListener].onClick = function()
		this:StartBattle(args.fight_id);
	end
end

local function setIcon(slot, id)
	local hero = HeroModule.GetManager():Get(id)

	if hero then
		if slot.Add then 
			slot.Add.gameObject:SetActive(false)
		end

		slot.Icon.gameObject:SetActive(true)
		slot.Icon[UnityEngine.UI.Image]:LoadSprite(string.format("icon/%s", hero.icon));
	else
		if slot.Add then 
			slot.Add.gameObject:SetActive(true) 
		end
		slot.Icon.gameObject:SetActive(false)
	end
end

function View:UpdateOnline()
	local this = self;

	for k, v in ipairs(self.online) do
		local slot = self.view.online[k];
		print(k, slot);
		if slot then
			local toggle = slot[UnityEngine.UI.Toggle];
			slot[CS.UGUIClickEventListener].onClick = function()
				if toggle.isOn then
					this:OnlineSelected(k);
				end
			end

			if v ~= 0 then
				setIcon(slot, v)
			else
				setIcon(slot, 0)
			end
		end
	end
end

function View:OnlineSelected(idx)
	self.select_index = idx;

	local gid = self.online[idx];
	if gid then	
		local view = self.listIcons[gid];
		if view then
			view[UnityEngine.UI.Toggle].isOn = true;
		end
	end
end

function View:UpdateHeroList()
	local list = HeroModule.GetManager():GetAll()

	local order_list = {}
	for k, v in pairs(list) do
		table.insert(order_list, v.id);
	end
	table.sort(order_list)


	local prefab = self.view.list.Viewport.Content[1].gameObject;
	local transform = self.view.list.Viewport.Content.gameObject.transform;
	local this = self;

	for k, v in pairs(self.listIcons) do
		UnityEngine.GameObject.Destroy(v.gameObject);
	end
	self.listIcons = {};

	for k, v in ipairs(order_list) do
		local view = SGK.UIReference.Setup(UnityEngine.GameObject.Instantiate(prefab, transform));
		view.gameObject:SetActive(true);
		setIcon(view, v);

		self.listIcons[v] = view;

		view[CS.UGUIClickEventListener].onClick = function()
			this:onHeroSelected(v);
		end
	end
end

function View:listEvent()
	return {
		"HERO_INFO_CHANGE",
		"server_respond_32",
	}
end

function View:onEvent(event, ...)
	if event == "HERO_INFO_CHANGE" then
		self:UpdateOnline();
		self:UpdateHeroList();
	elseif event == "server_respond_32" then
		local data = select(2, ...);
		local err = data[2];

		local text = self.view.TipsText[UnityEngine.UI.Text];
		if err == 0 then
			text.text = "保存成功";
			print("上阵成功");
		else
			text.text = "保存失败(" .. err .. ")";
			print("上阵失败", err);
		end

		self.view.TipsText[UnityEngine.Animator]:SetTrigger("Slash");
	end
end

function View:onHeroSelected(id)
	if not self.online[self.select_index] then
		return;
	end

	for k, v in ipairs(self.online) do
		if v == id and k == self.select_index then
			return;
		end
	end

	for k, v in ipairs(self.online) do
		if v == id then
			self.online[k] = 0;
		end
	end

	self.online[self.select_index] = id;
	self:UpdateOnline();
end

function View:SaveData( ... )
	 HeroModule.GetManager():SetFormation(self.online);
end

function View:StartBattle(fight_id)
	SceneStack.Replace('battle', 'view/battle.lua', { fight_id = fight_id, heros = self.online } );
end

return View;
