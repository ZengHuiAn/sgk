local View={}
function View:Start()
	self.root = SGK.UIReference.Setup(self.gameObject);
	self.view = self.root.view

	CS.UGUIClickEventListener.Get(self.view.Content.Grow.gameObject).onClick = function()
        DialogStack.InsertDialog("mapSceneUI/stronger/newStrongerFrame")
		SceneStack.Pop()
	end

	self.exit_left = 10;
end

function View:SetReplayInfo(replay_fight_info)
	self.view.Content.TryAgain:SetActive(not not replay_fight_info)
	CS.UGUIClickEventListener.Get(self.view.Content.TryAgain.gameObject).onClick = function()
		local pveCfg = module.fightModule.GetConfig(nil, nil, replay_fight_info.id)
		local fightInfo = module.fightModule.GetFightInfo(replay_fight_info.id)

		if pveCfg.count_per_day <= fightInfo.today_count then
			showDlgError(nil, SGK.Localize:getInstance():getValue("fuben_cishubuzu"))
		else
			SGK.BackgroundMusicService.PlayMusic()

			if pveCfg and pveCfg.cost_item_value <= module.ItemModule.GetItemCount(90010) or not pveCfg then
				module.fightModule.StartFight(replay_fight_info.id);
			else
				showDlgError(nil, SGK.Localize:getInstance():getValue("fuben_tilibuzu"))
			end
		end
		-- DispatchEvent("battle_event_replay_fight", replay_fight_info);
	end
end

local function loadStarDesc(key, value1, value2)
    local _value1 = value1
    local _value2 = value2
    if key == 6 then    ---技能
        if value1 ~= 0 then
            _value1 = module.fightModule.GetDecCfgType(tonumber(value1))
        end
    elseif key == 7 or key == 8 then ---怪物
        if value1 ~= 0 then
            _value1 = battle_config.LoadNPC(_value1).name
        end
        if key ~= 8 then
            if value2 ~= 0 then
                _value2 = battle_config.LoadNPC(value2).name
            end
        end
    end
    return string.format(module.fightModule.GetStarDec(key) or "星星条件 " .. tostring(key)  .. " 不存在", _value1, _value2)
end

function View:updateResultShow(data)
	local starStatus = data[1]
	local starInfo = data[2]
	self:updateStarShow(starStatus,starInfo)
end

function View:updateStarShow(starStatus,starInfo)
	local Conditions = self.view.resultInfo.Stars
	Conditions:SetActive(true)

	Conditions[1].Text[UI.Text]:TextFormat("战斗胜利");
	Conditions[1].Image[CS.UGUISelector].index = starStatus[1] and 1 or 0;
	Conditions[1].bg:SetActive(false)
	Conditions[1].bgFail:SetActive(true)

	for k,v in pairs(starInfo) do
		Conditions[k+1].bg:SetActive(starStatus[k+1])
		Conditions[k+1].bgFail:SetActive(not starStatus[k+1])
		Conditions[k+1].Image[CS.UGUISelector].index = starStatus[k+1] and 1 or 0;
		Conditions[k+1].Text[UI.Text]:TextFormat("{0}", loadStarDesc(v.type, v.v1, v.v2));
		Conditions[k+1].Text[UI.Text].color = starStatus[k+1] and {r = 0, g = 0, b = 0, a = 128/255} or UnityEngine.Color.black
	end
end

return View;
