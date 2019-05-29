local playerModule = require "module.playerModule";
local heroModule = require "module.HeroModule"
local ShopModule = require "module.ShopModule"
local ItemModule = require "module.ItemModule"
local ActivityModule = require "module.ActivityModule"
local NetworkService = require "utils.NetworkService";
local EventManager = require 'utils.EventManager';
local equipmentModule = require "module.equipmentModule"
local SmallTeamDungeonConf = require "config.SmallTeamDungeonConf"
local equipCfg = require "config.equipmentConfig"
local HeroLevelup = require "hero.HeroLevelup"
local unionModule = require "module.unionModule"
local UserDefault = require "utils.UserDefault"
local TeamModule = require "module.TeamModule"
local ManorManufactureModule = require "module.ManorManufactureModule"
local MapConfig = require "config.MapConfig"
local View = {};

local GMCommand = {}


function View:Start()
	self.view = CS.SGK.UIReference.Setup(self.gameObject)
	self.view.mask[CS.UGUIClickEventListener].onClick = function ( ... )
       DialogStack.Pop()
	end
	
	-- self.view.bg.InputField[UnityEngine.UI.InputField].text = "/gm open_dialog hunting/HuntingFrame"
	
	self.view.bg.yBtn[CS.UGUIClickEventListener].onClick = function ( ... )
        local playerModule = require "module.playerModule"
        local heroModule = require "module.HeroModule"
        local equipCfg = require "config.equipmentConfig"
        local command = self.view.bg.InputField[UnityEngine.UI.InputField].text;
        --print(command)
        if command ~= "" then
	        local tempDesc = self:lua_string_split(command," ")
	        if tempDesc[1] == "/gm" then
	        	table.remove(tempDesc,1)
		        if tempDesc[1] == "hero" then
		            if #tempDesc == 2 then
		                --添加某英雄
		                if tempDesc[2] == "all" then
		                    --添加全部英雄
		                     DATABASE.ForEach("role", function(row)
		                        local id = row[0]
		                        heroModule.GetManager():Add(id);
		                    end)
		                else
		                    heroModule.GetManager():Add(tempDesc[2]);
		                end
		            elseif #tempDesc == 3 then
		                --给英雄添加经验
		                heroModule.GetManager():AddExp(tonumber(tempDesc[2]),tonumber(tempDesc[3]))
		            else
		                print("参数错误")
		            end
		        elseif tempDesc[1] == "item" then
		            if #tempDesc == 3 then
		                if tempDesc[2] == "all" then
		                --添加全部物品
		                    DATABASE.ForEach("item", function(row)
		                        local id = row.id
		                        NetworkService.Send(29,{nil, 0,41,tonumber(id),tonumber(tempDesc[3])})
		                    end)
		                else
		                --添加某物品
		                    --print(tostring(tempDesc[2]).."<>"..tostring(tempDesc[3]))
		                    local type = 41;
		                    if (equipCfg.GetConfig(tonumber(tempDesc[2]))) then
		                        type = 43;
		                    end
		                    NetworkService.Send(29,{nil, 0,type,tonumber(tempDesc[2]),tonumber(tempDesc[3])})
		                end
		            else
		                NetworkService.Send(165,{nil})
		            end
		        elseif  tempDesc[1] == "shop" then
		            if #tempDesc == 2 then

		            else
		                SceneStack.Push('TempShop', 'view/TempShopFrame.lua',{idx = 2})
		            end
		        elseif tempDesc[1] == "mail" and #tempDesc == 3 then
		            NetworkService.Send(5009,{nil, playerModule.Get().id,1,tempDesc[2],tempDesc[3]})
		        elseif tempDesc[1] == "charge" then
		            self:Charge();
		        elseif tempDesc[1] == "story" and #tempDesc == 2 then
		        	LoadStory(tonumber(tempDesc[2]))
		        elseif tempDesc[1] == "clear" then
					showDlgError(nil,"清理本地数据")
		            UserDefault.Clear();
		        elseif tempDesc[1] == "cc" then
		            if tempDesc[2] == "accept" then
		                module.QuestModule.CityContuctAcceptQuest();
		            elseif tempDesc[2] == "cancel" then
		                module.QuestModule.CityContuctCancelQuest();
		            elseif tempDesc[2] == "submit" then
		                module.QuestModule.CityContuctSubmitQuest();
		            end
		        elseif tempDesc[1] == "quest" then
		            DialogStack.Push("quest/QuestListDialog");
		        elseif tempDesc[1] == "bounty" then
		            if tempDesc[2] == "start" then
		                module.BountyModule.Start();
		            elseif tempDesc[2] == "cancel" then
		                module.BountyModule.Cancel();
		            elseif tempDesc[2] == "fight" then
		                module.BountyModule.Fight()
		            elseif tempDesc[2] == "list" then
		                local info = module.BountyModule.Get();
		                if info.quest then
		                    print("-->", info.quest.name, info.quest.desc, info.count, info.quest.times);
		                else
		                    print("-->", nil);
		                end
		            end
		        elseif tempDesc[1] == "player" then
		            if tempDesc[2] == "mode" and tempDesc[3] then
		                module.playerModule.ChangeIcon(tonumber(tempDesc[3]));
		            end
		        elseif tempDesc[1] == "map" and #tempDesc == 2 then
					if tonumber(tempDesc[2]) == nil then
						return SceneStack.EnterMap(tempDesc[2]);
					end

		        	--直接切换地图
		        	local mapName = MapConfig.GetMapConf(tonumber(tempDesc[2]))
		        	if mapName then
		        		SceneStack.EnterMap(tonumber(tempDesc[2]));
		        	else
		        		showDlgError(nil,"地图不存在")
		        	end
				elseif tempDesc[1] == "one_time_reward" then
					if tempDesc[2] == "recv" then
						module.RewardModule.Gather(tonumber(tempDesc[3]));
					elseif tempDesc[2] == "check" then
						print(module.RewardModule.Check(tonumber(tempDesc[3])));
					else
						for i = 1, 100 do
							print(i, module.RewardModule.GetFlag(i));
						end
					end
				elseif GMCommand[tempDesc[1]] then
					assert(coroutine.resume(coroutine.create(function()
						GMCommand[tempDesc[1]](table.unpack(tempDesc));
					end)));
				elseif tempDesc[1] == "guide" then
					module.guideModule.SetGMFlag(tonumber(tempDesc[2]) == 1)
		        elseif tempDesc[1] == "addnpc" then
		        	module.NPCModule.Set_Npc_active_id(tonumber(tempDesc[2]))
		        elseif tempDesc[1] == "refshop" then
		        	module.ShopModule.GetManager(tonumber(tempDesc[2]))
		        elseif tempDesc[1] == "union" then
		        	local uninInfo = module.unionModule.Manage:GetSelfUnion()
		        	if uninInfo then
			        	if #tempDesc == 3 then
			                NetworkService.Send(3471,{nil,tonumber(tempDesc[2]),tonumber(tempDesc[3])})
			            end
			        else
			        	showDlgError(nil,"您还未加入公会")
			        end
		        else
		            showDlgError(nil,"参数错误")
		        end
	        else
	        	showDlgError(nil,"您的申请已提交")
	        end
	        --DialogStack.Pop()
	   else
	        showDlgError(nil,"内容为空")
	   end
	end
end
function View:lua_string_split(str, split_char)
    local sub_str_tab = {};
    while (true) do
        local pos = string.find(str, split_char);
        if (not pos) then
            sub_str_tab[#sub_str_tab + 1] = str;
            break;
        end
        local sub_str = string.sub(str, 1, pos - 1);
        sub_str_tab[#sub_str_tab + 1] = sub_str;
        str = string.sub(str, pos + 1, #str);
    end

    return sub_str_tab;
end


function GMCommand.reward(_, type, id, value, hid)
	type  = tonumber(type or 0)
	id    = tonumber(id or 0)
	value = tonumber(value or 0)
	hid   = tonumber(hid or 0)

	if type == nil or id == nil or value == nil then
		return;
	end


	if type == 0 or id == 0 or value == 0 then
		return;
	end

	local uuid;
	if hid then
		local hero = module.HeroModule.GetManager():Get(hid);
		uuid = hero and hero.uuid;
	end

	NetworkService.Send(29,{nil,0,type,id,value,uuid})
end

local canvas = nil;
function GMCommand.fps()
	print(UnityEngine.GameObject.FindObjectOfType(typeof(SGK.PatchManager)));
	canvas = canvas or UnityEngine.GameObject.FindObjectOfType(typeof(SGK.PatchManager)).FPSCanvas;
	canvas:SetActive(not canvas.activeSelf);
end

function GMCommand.reload()
	SceneService:Reload();
end

function GMCommand.arena_gold_finger(_, value)
	NetworkService.Send(591, {nil, tonumber(value)})
end

function GMCommand.pve(_, id)
	module.fightModule.StartFight(tonumber(id))
end

function GMCommand.pvp(_, id)
	NetworkService.Send(16007, {nil, tonumber(id)})
end

function GMCommand.finish_quest(_, id)
	utils.NetworkService.Send(205, {nil, tonumber(id)});
end

function GMCommand.notify(_, n, str)
	local NotificationCenter = require "utils.NotificationCenter"
	print("notify", n, str);
	NotificationCenter.AddNotification(tonumber(n), str);
end

function GMCommand.guide_team_fight()
	local EncounterFightModule = require "module.EncounterFightModule"
	EncounterFightModule.StartGuideTeamFight();
end

function GMCommand.open_dialog(_, name)
	DialogStack.Push(name);
end


return View
