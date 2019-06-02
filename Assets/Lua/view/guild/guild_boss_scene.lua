local worldBossModule = require "module.worldBossModule"
local Time = require "module.Time"
local UnionConfig = require "config.UnionConfig"
local View = {}


local npc_list = {
	2251200,
	2251201,
	2251202,
	2251203,
	2251204,
	2251205,
}

function View:Start(data)

	
	worldBossModule.QueryUnionInfo()
	worldBossModule.QueryUnionReplay();
	worldBossModule.QueryUnionRank();
    local _cfg = UnionConfig.GetActivity(5)
    -- self:RemoveAll()
	self:FreshNpc();
end

function View:RemoveAll( ... )
	for k,v in pairs(npc_list) do
		local npc_obj = module.NPCModule.GetNPCALL(v);

		if npc_obj then
			module.NPCModule.deleteNPC(v)
		end
	end
end

function View:Update( ... )
    if self.m_endTime then
        local time = self.m_endTime - Time.now();

        if time >=0 then
            
        else
            self.m_endTime = nil
            self:RemoveAll()

            module.worldBossModule.QueryUnionInfo()
            module.worldBossModule.QueryUnionReplay()
        end
    end
end


function View:FreshNpc( ... )
    local _union = worldBossModule.GetBossInfo(2)

    -- ERROR_LOG("=======>>>NPC信息",sprinttb(_union))
    if _union then

    	local boss_id = _union.id;
    	local all_hp = _union.allHp
    	local hp = _union.hp;
		local npc_obj = module.NPCModule.GetNPCALL(boss_id);
		if hp ==nil then
			hp=0
		end
    	if math.floor(hp) == 0 or not _union.id  then
    		-- ERROR_LOG("删除NPC"..boss_id);

    			if _union.id and math.floor(hp) == 0  then
    				SGK.Action.DelayTime.Create(3):OnComplete(function()
    					module.NPCModule.deleteNPC(boss_id);
					end)
    			else
    				module.NPCModule.deleteNPC(boss_id);
    			end
    		
    		return;
    	else
    		AssociatedLuaScript("guide/".."guildBossBorn"..".lua",boss_id)
    		if not npc_obj then
				module.NPCModule.LoadNpcOBJ(boss_id);
				-- module.NPCModule.Ref_NPC_LuaCondition()
    		end
    		-- ERROR_LOG("加载NPC"..boss_id);
    	end
    	self.m_endTime = _union.duration + _union.beginTime
    end
end


function View:listEvent( ... )
	return {
	"LOCAL_WORLDBOSS_ATTACK_INFO",
	"LOCAL_WORLDBOSS_INFO_CHANGE",
	"UNION_BOSS_END",
}
end
function View:onEvent( event ,data  )
	ERROR_LOG(event,"======================>>>>")
	if event == "LOCAL_WORLDBOSS_ATTACK_INFO" or "LOCAL_WORLDBOSS_INFO_CHANGE" then
		if data == 2 then
			self:FreshNpc();
		end
		
	elseif event == "UNION_BOSS_END" then
		if data.type == 2 then
			self:FreshNpc();
		end
	elseif event =="NPC_OBJ_INFO_CHANGE" or event == "npc_init_succeed" then

		ERROR_LOG("NPC_OBJ_INFO_CHANGE ===============>>>");
		module.NPCModule.Ref_NPC_LuaCondition()

	end
end

return View;