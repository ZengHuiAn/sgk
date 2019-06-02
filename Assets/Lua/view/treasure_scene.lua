local View = {}
local mazeConfig = require "config.mazeConfig"


local CameraSize = 5

local Player_Size = {1,1.75,1}


function View:Start()
    self.view = CS.SGK.UIReference.Setup(self.gameObject)
	 self.view = CS.SGK.UIReference.Setup(self.gameObject)
	UnityEngine.Camera.main.orthographic = false
	UnityEngine.Camera.main.fieldOfView = 30
	UnityEngine.Camera.main.gameObject.transform.localRotation = UnityEngine.Quaternion.Euler(60,0,0);
end

function View:Random( ... )

	local type = {8,9,10,100,31}
	self.list = {}

	for i=1,#type do
		local list= mazeConfig.GetTypeInfo(type[i]);

		if list then
			for k,v in pairs(list) do
				table.insert( self.list, v.id )
			end
		end
	end

	local temp_List = {}

	for i=1,#self.reward_pos_list do
		table.insert( temp_List, math.random( 1,#temp_List == 0 and 1 or #temp_List ), self.reward_pos_list[i] )
	end


	-- small_gold_position
	-- ERROR_LOG(sprinttb(self.list),"==========>>>");
	local index = 1;
	local temp_index = 1;
	while index ~= (#self.list+1) do
		local ret = math.random(1,#self.posList);
   

		local pos = self.posList[ret]

		table.remove( self.posList, ret )

		local npcid = self.list[index]
		-- ERROR_LOG(npcid);
		local info = mazeConfig.GetInfo(npcid);
		if info and info.type == 31 then
			pos = self.reward_pos_list[temp_index];
			temp_index = temp_index +1
		end
		local obj = module.TreasureMapModule.Load(1,info,pos);
		-- ERROR_LOG("-------->>>",obj);
		
		index = index +1
	end
	for k,v in pairs(self.list) do
		self:FreshNpc(v,true);
	end
end

function View:FreshSmallNpc( id ,first)

	local info = mazeConfig.GetInfo(id);

	-- print("小地图任务刷新任务信息",id)
	if not info then
		return;
	end
	local flag = true

	local small_status = module.TreasureMapModule.GetGameStatus()
	-- ERROR_LOG("状态========>>>",small_status);
	if info.fight_id and info.fight_id ~= 0  then
		if module.QuestModule.CanAccept(info.fight_id) then
			if small_status and small_status+40 == info.type then
				flag = true
			else
				flag = false	
			end
			
		else
			flag = false
		end	
	else
		ERROR_LOG("=====>>>",id);
	end

	module.TreasureMapModule.SetNPCStatus(id,flag);

end


function View:FreshNpc( id ,first)

	local info = mazeConfig.GetInfo(id);

	-- print("刷新任务信息",id)
	if not info or info.type == 41 or info.type == 42 or info.type == 43 or info.type == 44 then
		return;
	end
	local flag = true
	if info.fight_id and info.fight_id ~= 0  then
		if not module.QuestModule.Get(info.fight_id) or module.QuestModule.Get(info.fight_id).status ~= 1 then


			flag = true
			if info.type == 100 then
				local quest_list = mazeConfig.GetTypeInfo(10);

				local status = true;
				for k,v in pairs(quest_list) do
					if not module.QuestModule.Get(v.fight_id) or module.QuestModule.Get(v.fight_id).status ~= 1 then
						-- print("NPCb不满足条件",v.id)
						status = false;
						break;
					else
						-- print("NPCb满足条件",v.id)
					end	
				end
				flag = status
				-- ERROR_LOG("最终任务是否完成",flag);
			end
			-- print(" NPC任务未完成 ",info.id)

		else
			-- print(" NPC任务完成 ",info.id)
			if info.type == 10 then
				if first then
				else
					showDlgError(nil,SGK.Localize:getInstance():getValue("migong_suipian1"))
					DispatchEvent("LOCAL_PLAY_FLY",2);
				end
			end
			flag = false
		end	
	end
	module.TreasureMapModule.SetNPCStatus(id,flag);
	DispatchEvent("LOCAL_UPDATE_NPC",{id = id,status = not flag});
end

function View:listEvent()
	return{
		"MAP_SCENE_READY",
		"MOVE_TO_SMALL_GAME",
		"SCENE_READY_LOCAL",
		"PLAYER_SPEED_OFFEST",
		"QUEST_INFO_CHANGE",
		"CLEAR_ALL_ROAD",
		"AFTER_ITEM_INFO_CHANGE",
	}
end

function View:ClearAllRoad( ... )
	self.small_road  = CS.SGK.UIReference.Setup(UnityEngine.GameObject.Find("mig_1_small"))
	-- ERROR_LOG(#self.small_road,"==============",sprinttb(self.small_road));
	for i=1,#self.small_road.road do
		local road = self.small_road.road[i];
		-- ERROR_LOG("ROAD",road);
		if road then
            road[UnityEngine.AI.NavMeshObstacle].enabled = true
            road.triggle[CS.SGK.MapColliderMenu].LuaTextName = "";
			road.mig_box:SetActive(false);
		else
			ERROR_LOG(i.."this road is nil");
		end
	end
end


local function SetUpMinMapIcon( name,parent )
    local obj = UnityEngine.GameObject.Instantiate(SGK.ResourcesManager.Load("prefabs/treasure/"..name .. ".prefab"),parent);
    obj.transform.localRotation = UnityEngine.Quaternion.Euler(-90,180,0);
    return CS.SGK.UIReference.Setup(obj);
end
local function SetMapPlayerView( character )
    character[UnityEngine.Transform].localScale = UnityEngine.Vector3(Player_Size[1],Player_Size[2],Player_Size[3])
    character.Character[CS.FollowCamera].enabled = false
    character.Character.gameObject.transform.localRotation= UnityEngine.Quaternion.identity;

end



function View:onEvent(event,data)
	-- ERROR_LOG(event);
	if event == "MAP_SCENE_READY"then
		local id = module.playerModule.Get().id;
		local character = self.view.MapSceneController[CS.SGK.MapSceneController]:Get(id) 
        self.character = character
        self.player_view = CS.SGK.UIReference.Setup(self.character)
		SetMapPlayerView(self.player_view);
		self.player_view.Character.shadow[UnityEngine.SpriteRenderer].color = UnityEngine.Color(0,0,0,0.5)
        -- player_view.Character.Sprite.gameObject.transform.localRotation = UnityEngine.Quaternion.Euler(-45,0,0);
		-- self.miniMapCamera[CS.SGK.MiniMapFollowPlayer].m_playerObj = character.gameObject

		-- local player_icon = SetUpMinMapIcon("MinMapIcon",player_view.Character.gameObject.transform);
		self.small_npc_pos = CS.SGK.UIReference.Setup(UnityEngine.GameObject.Find("small_position"))
		DialogStack.PushPref("treasure/FogCamera",nil, UnityEngine.GameObject.Find("bottomUIRoot"))
		
	elseif event == "SCENE_READY_LOCAL" then
		self:RandomNPC();
		-- local MinimapObject = self.character.gameObject:GetComponent(typeof(CS.MinimapObject));
		-- if MinimapObject == nil then
		-- 	MinimapObject = self.character.gameObject:AddComponent(typeof(CS.MinimapObject))
		-- end
		-- local config = CS.MinimapObject.Config();
		-- config.icon = SGK.ResourcesManager.Load("icon/zuan_1");
		-- config.color = UnityEngine.Color.white
		-- MinimapObject.Config =config;
	elseif event =="MOVE_TO_SMALL_GAME" then

		if DialogStack.GetPref_list("treasure/TreasureSmall4") then
			DialogStack.Pop()
		end

		
		if not self.smallGame then
			self.smallGame = UnityEngine.GameObject.Instantiate(SGK.ResourcesManager.Load("prefabs/treasure/SmallGame.prefab"));
		else
			local behavior = self.smallGame.gameObject:GetComponent(typeof(CS.SGK.LuaBehaviour));
			if behavior then
				module.TreasureMapModule.ClearGame1ObsStatus()
				UnityEngine.Object.Destroy(behavior)
			end

			if not data then
				module.TreasureMapModule.ResetSmallGame()
				return
			end
		end
		


		module.TreasureMapModule.ResetSmallGame()

		if data then
			SGK.LuaBehaviour.Append(self.smallGame.gameObject, "view/treasure/smallGame"..data..".lua");
		end

		if data then
			self:RandSmallNpcPos(data)
		end

		-- ERROR_LOG("小游戏",data);
	elseif event == "PLAYER_SPEED_OFFEST"  then
		if data == 0 then --恢复速度
			utils.SGKTools.SetMAPNPCSpeed(self.player_view,2)
		elseif data == 1 then --提速
			utils.SGKTools.SetMAPNPCSpeed(self.player_view,nil,nil,1.5)
		else --减速
			utils.SGKTools.SetMAPNPCSpeed(self.player_view,nil,nil,0.4)
		end
	elseif event == "QUEST_INFO_CHANGE" then
		if data and data.npc_id then

			if  tonumber(data.npc_id) == 0 then
				return
			end
			local info = mazeConfig.GetInfo(data.npc_id)
			if info.type >40 then
				
				self:FreshSmallNpc(tonumber(data.npc_id));
				return
			end
			if info.type == 10 then
				local list= mazeConfig.GetTypeInfo(100);
				self:FreshNpc(list[1].id);
			end
			self:FreshNpc(tonumber(data.npc_id));
		end
	elseif event == "CLEAR_ALL_ROAD" then

		self:ClearAllRoad();
	elseif event == "AFTER_ITEM_INFO_CHANGE" then
		self:PlayerHeadEffect(data);
	end
end


function View:PlayerHeadEffect( data )
	-- ERROR_LOG(sprinttb(data));
	if data then
		local flag = nil
		for i=1,#data do
			if data[i][1] == 110000 then
				flag = true
				break
			end
		end

		local tmp = {
			[90002] = "yinbi01_tou",
			[90003] = "jinbi01_tou",
		}

		if flag then
			for i=1,#data do
				if data[i][1] ~= 110000 then
					if tmp[data[i][1]] then
						
						utils.SGKTools.loadTwoEffect(tmp[data[i][1]],nil,{time = 2,count = data[i][2]})
						break;
					else
						local config = module.ItemModule.GetConfig(data[i][1]);

						if config.type == 56 then
							utils.SGKTools.loadTwoEffect("shuijing_tou",nil,{time = 2,count = ""})
							break;
						end
					end
				end
			end
		end
	end
end

--随机NPC
function View:RandomNPC( ... )
	local position = UnityEngine.GameObject.Find("position")
	local pos = CS.SGK.UIReference.Setup(position)
	local reward_position = CS.SGK.UIReference.Setup(UnityEngine.GameObject.Find("small_gold_position"))
	self.posList = {}
	for i=1,#pos do
		table.insert( self.posList,{pos[i].gameObject.transform.position.x,pos[i].gameObject.transform.position.y,pos[i].gameObject.transform.position.z}  );
	end


	self.reward_pos_list = {}

	for i=1,#reward_position do
		table.insert( self.reward_pos_list,{reward_position[i].gameObject.transform.position.x,reward_position[i].gameObject.transform.position.y,reward_position[i].gameObject.transform.position.z}  );
	end


	math.randomseed(module.Time.now()/3600/24);
	self:Random();
end

function View:RandSmallNpcPos( data )
	local type_npc_list = mazeConfig.GetTypeInfo(data+40)
	local list = self:RANDOM_List(#type_npc_list,#self.small_npc_pos);
	-- ERROR_LOG("==============>>>",sprinttb(list));

	for i=1,#list do
		-- type_npc_list
		local item = self.small_npc_pos[list[i]].gameObject.transform.position
		local pos = {item.x,item.y,item.z}

		module.TreasureMapModule.Load(1,type_npc_list[i],pos);
		self:FreshSmallNpc(type_npc_list[i].id,true)
	end
end

function View:PlayAnimation( ... )
	local playerView =CS.SGK.UIReference.Setup(self.character)
end

--随机到数组长度  max   随机点的长度 count
function View:RANDOM_List( max ,count)

	-- ERROR_LOG(max,count);
	if max>count or not max or not count then
		
		-- ERROR_LOG("max > count ");
		return;
	end


	local randomList = {}

	local pos_list = {}

	for i=1,count do
		table.insert( pos_list, i )
	end
	-- ERROR_LOG(sprinttb(pos_list),#pos_list);
	for i=1,max do
		math.randomseed(module.Time.now())
		local index = math.random(1,#pos_list  )

		local value = pos_list[index]
		table.remove( pos_list, index )
		table.insert( randomList, i,value )
	end
	return randomList;
end



return View;
