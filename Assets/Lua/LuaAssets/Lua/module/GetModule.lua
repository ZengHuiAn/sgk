return{
----------------------module-----------------------------------
	Time = require "module.Time",
	playerModule = require "module.playerModule",
	TeamModule = require "module.TeamModule",
	EncounterFightModule = require "module.EncounterFightModule",
	playerModule = require "module.playerModule",
	NPCModule = require "module.NPCModule",
	honorModule = require "module.honorModule",
	Time = require "module.Time",
	ItemModule = require "module.ItemModule",
	EquipmentModule = require "module.equipmentModule",
	PlayerInfoModule = require "module.PlayerInfoModule",
	NpcContactModule = require "module.NpcContactModule",
----------------------NewModule-----------------------------------------
	MapPlayerModule = require "module.ModuleProxy.MapPlayerProxy",
------------------------utils-------------------------------
	NetworkService = require "utils.NetworkService",
	Thread = require "utils.Thread",
	PlayerInfoHelper = require "utils.PlayerInfoHelper",
	EventManager = require 'utils.EventManager',
	ItemHelper = require "utils.ItemHelper",
-----------------------config--------------------------------
	HeroEvo = require "hero.HeroEvo",
	MapConfig = require "config.MapConfig",
	UnionConfig = require "config.unionConfig",
	EquipmentConfig = require "config.equipmentConfig"
}