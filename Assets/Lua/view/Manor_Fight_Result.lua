local ManorManufactureModule = require "module.ManorManufactureModule"
local ManorModule = require "module.ManorModule"
local HeroModule = require "module.HeroModule"
local CommonConfig = require "config.commonConfig"
local ItemHelper = require "utils.ItemHelper"


local View = {};
function View:Start(data)
	self.view = CS.SGK.UIReference.Setup(self.gameObject);
	self:InitData();
	self:InitView();
end

function View:InitData()
	self.manager = HeroModule.GetManager();
	self.work_type_config = ManorModule.GetManorWorkType();
	self.manor_property = ManorModule.GetManorProperty();
	self.fightInfo = ManorManufactureModule.GetCurFightInfo();
	local grade_cfg = ManorModule.GetManorGradeConfig();
	self.grade_rank = {};
	for i,v in ipairs(grade_cfg) do
		local data = {};
		data.score = v.down;
		data.rank = v.grade;
		self.grade_rank[i] = data;
	end
	self.fight_add_grade =0;
	local fight_add = ManorModule.GetManorFightAdd(1,self.fightInfo.property);
	local grade = 0;
	for i,v in pairs(fight_add) do
		grade = grade + (v.add_property * v.win_times);
	end
	self.fight_add_grade = grade;
end

function View:InitView()
	if self.fightInfo then
		self.view.Image:SetActive(self.fightInfo.result == 1);
		local hero = self.manager:GetByUuid(self.fightInfo.uuid);
		-- local heroCfg = ItemHelper.Get(ItemHelper.TYPE.HERO,hero.id);
		-- self.view.newCharacterIcon[SGK.newCharacterIcon]:SetInfo(heroCfg);
		utils.IconFrameHelper.Create(self.view.IconFrame,{uuid = self.fightInfo.uuid, type = 42})

		self.view.item_manor_prop.name[CS.UnityEngine.UI.Text].text = self.work_type_config[self.fightInfo.property].work_type;
		local prop_cfg = self.manor_property[hero.id][self.fightInfo.property];
		for i,v in ipairs(self.grade_rank) do
			if prop_cfg.factor >= v.score then
				self.view.item_manor_prop.rank[CS.UnityEngine.UI.Text].text = v.rank;
				break;
			end
		end
		local grade_limit = prop_cfg.init1 + prop_cfg.lv_value1 * CommonConfig.Get(6).para1 + prop_cfg.rank_value1 * CommonConfig.Get(7).para1 + prop_cfg.star_value1 * CommonConfig.Get(8).para1 + self.fight_add_grade * prop_cfg.factor;
		self.view.item_manor_prop.Slider1[CS.UnityEngine.UI.Slider].value = (self.fightInfo.value + self.fightInfo.add_property)/grade_limit;
		self.view.item_manor_prop.Slider2[CS.UnityEngine.UI.Slider].value = self.fightInfo.value/grade_limit;
		self.view.item_manor_prop.num[CS.UnityEngine.UI.Text].text = tostring(self.fightInfo.value);

		if self.fightInfo.result == 0 then
			self.view.Text[CS.UnityEngine.UI.Text].color = UnityEngine.Color.red;
			self.view.Text[CS.UnityEngine.UI.Text]:TextFormat("+{0}（未获得）",self.fightInfo.add_property);

		else
			self.view.Text[CS.UnityEngine.UI.Text]:TextFormat("+{0}",self.fightInfo.add_property);
		end
	else
		self.view:SetActive(false);
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
