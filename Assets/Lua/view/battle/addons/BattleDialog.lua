local dialog_view = nil
local dialog_cfg = nil

local function AddDialog(dialog_id)
    if not dialog_view then
        dialog_view = SGK.UIReference.Instantiate(SGK.ResourcesManager.Load("prefabs/battlefield/BattleDialog.prefab"));
        dialog_view.transform:SetParent(root.view.battle.Canvas.ConversationRoot.transform, false);
        dialog_view[SGK.LuaBehaviour]:Call("SetResumeFunction", function ()
            EventNeedPause_Resume()
        end)
    end 

    if not dialog_cfg then
        dialog_cfg = {}
        DATABASE.ForEach("fight_story", function(data)
            dialog_cfg[data.id] = data
        end)
    end

    local cfg = dialog_cfg[dialog_id]
    if not cfg then
        return
    end

    local info = {
        bg = cfg.bg or 1,
        name = cfg.name,
        icon = tonumber(cfg.icon),
        side =  cfg.side;
        message = cfg.dialog;
        sound = cfg.sound;
    }

    dialog_view[SGK.LuaBehaviour]:Call("Add", info);

    if cfg.next_id and cfg.next_id ~= 0 then
        AddDialog(cfg.next_id)
    else
        EventNeedPause_Yield()
    end
end

function EVENT.RAW_BATTLE_EVENT(_, event, ...)
    if event == "ADD_BATTLE_DIALOG" then
        if root.args.remote_server or root.speedUp then return end
        local info = ...
        AddEventNeedPause(function()
            AddDialog(info.dialog_id)
        end, 20)
    end
end
