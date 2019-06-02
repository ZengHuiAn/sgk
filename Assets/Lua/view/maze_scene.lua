local View = {}

local mazeModule = require "module.mazeModule"
local mazeConfig = require "config.mazeConfig"


function View:OpenMazeTips()
	local tempObj = SGK.ResourcesManager.Load("prefabs/base/mazeTips.prefab")
	local NGUIRoot = UnityEngine.GameObject.FindWithTag("UGUIRoot")
	local obj = nil;
	if NGUIRoot then
		obj = CS.UnityEngine.GameObject.Instantiate(tempObj, NGUIRoot.gameObject.transform)
	end
	if obj then
		SGK.LuaBehaviour.Append(obj, "view/mazeTips.lua")
	end
end

function View:Start()
	mazeModule.SetNotify();

	if not mazeModule.GetOpen() then
		SceneStack.EnterMap(13,{pos = {-3.43,-0.02,9.82}});
		return
	end
	DispatchEvent("MAP_UI_HideGuideLayerObj");
	-- print("===============");
	--有队伍
	self.root = UnityEngine.GameObject.Find("maze");
	self.data = {};
	self.maxRow =10;
	self.maxColumns = 10;
	self.source1 = SGK.ResourcesManager.Load("prefabs/common/maze_cube1.prefab");
	self.source2 = SGK.ResourcesManager.Load("prefabs/common/maze_cube2.prefab");
	self.source3 = SGK.ResourcesManager.Load("prefabs/common/maze_cube3.prefab");
	self:Check_Battle_Boss();

	self.prefabs = {self.source1,self.source2,self.source3};
	for row=1,self.maxRow do
		self.data[row] = {}
		local root = UnityEngine.GameObject("root"..(row-1));
		local rootItem = root.transform;
		rootItem.parent = self.root.transform;
		for Columns=1,self.maxColumns do
			local data = self:CreateBox(row,Columns,rootItem);
			self:SetObjStatus(data,true);
			self.data[row][Columns] = {};
			self.data[row][Columns].data = data;

			--设置id
			local inter = data:GetComponent(typeof(SGK.MapInteractableMenu));
			local id = self:SetValue(row,Columns);
			inter.values[0] = id;

			self.data[row][Columns].flag = true;

			self.data[row][Columns]["id"] = id;


			self.data[row][Columns].RefreshId = function(_id)
				self.data[row][Columns]["id"] = _id;
				inter.values[0] = _id;
			end
		end
	end

	self.root.gameObject.transform.localRotation = UnityEngine.Quaternion.AngleAxis(45, Vector3.up);

	mazeModule.SetData(self.data);

	local _,data,npcs = mazeModule.Get();
	-- ERROR_LOG("------------------------>>>>",sprinttb(data));
	--关掉已经交互过的东西
	if data then
		for k,v in pairs(data) do
			if v == 1 then
				mazeModule.ChangeIDStatus(k);
			end
		end
	end
	local this_flag = nil;
	if npcs then
		for k,v in pairs(npcs) do
			if k ~= 1 then
				local pos = mazeModule.GetCubePos(v.value[1]);

				local obj = mazeModule.LoadNPC(v.id,pos,v.value[1],v.uuid,true);
				-- ERROR_LOG("有npc已死亡",sprinttb(v));
				if v.dead == 1 then

					if v.id == 1601106 then
						this_flag = true;
					end

					mazeModule.DeadNpc(v.uuid,v.value[1],v.id);
				end
			end
		end
	end
	mazeModule.Interact(1,56,1);

	mazeModule.ChangeIDStatus(56);
	self:OpenMazeTips();

	local boss = mazeModule.GetBoss();
	--如果boss死亡

	self:Check();
end

function View:Check(  )
	if not mazeModule.GetOpen() then
		-- ERROR_LOG("活动未开");
		return;
	end

	local boss = mazeModule.GetBoss();
	-- ERROR_LOG("Boss--->>",boss);
	--如果boss没有死亡
	if (not boss or boss ~= 1) and boss ~= -1 then
		if not boss then
			-- ERROR_LOG("Boss没有出现");
			return
		end

		local all_config = mazeConfig.GetTypeInfo(2);
		local all_dead = 0;
		for k,v in pairs(all_config) do
			
			if mazeModule.GetNpcIsKill(v.id) == 1 then
				all_dead = all_dead + 1;	
			end
		end
		-- ERROR_LOG("==============>>>",all_dead)
		if all_dead == #all_config then
			if not mazeModule.GetIsAllKill() then

				utils.SGKTools.LockMapClick(true)
				-- ERROR_LOG(sprinttb(mazeModule.GetNPCObj(1601106) or {}));
				utils.SGKTools.MapCameraMoveToTarget(mazeModule.GetNPCObj(1601106).gameObject.transform)
				
				local eff_dun = mazeModule.GetNPCObj(1601106).gameObject.transform:Find("xf_dun_run(Clone)")
				
				SGK.Action.DelayTime.Create(3):OnComplete(function()
					
					-- 是时候击败西风!
					local eff_boom = mazeModule.LoadEffect("xf_dun_boom",2);
					
					eff_boom.gameObject.transform.parent = eff_dun.gameObject.transform.parent;
					eff_boom.gameObject.transform.localPosition = Vector3.zero;
					eff_dun.gameObject:SetActive(false);
					-- UnityEngine.Object.Destroy(eff_dun.gameObject);
					mazeModule.SetIsAllKill()
					showDlgError(nil, "是时候击败西风!")
					
					
					SGK.Action.DelayTime.Create(1):OnComplete(function()
						utils.SGKTools.MapCameraMoveTo();
						utils.SGKTools.LockMapClick()
						
					end)
				end)

			else
				local eff_dun = mazeModule.GetNPCObj(1601106).gameObject.transform:Find("xf_dun_run(Clone)")

				eff_dun.gameObject:SetActive(false);
			end
		end
	elseif boss and boss == 1 then
		mazeModule.SetStatus();
		DialogStack.PushPrefStact("mazeSuccess");
	end
end


function View:RandomPrefabs()

	local index = mazeModule.RandomMaze(3);
	local obj = self.prefabs[index];
	return obj,index;
end


function View:SetObjStatus(data,status)
	if not status then

		if data.activeInHierarchy then
			data:SetActive(status);
		end
	else
		if not data.activeInHierarchy then
			data:SetActive(status);
		end
	end
end


function View:CreateBox(row,Columns,root)

	local prefab,index = self:RandomPrefabs()
	local obj = UnityEngine.GameObject.Instantiate(prefab);
	obj.transform.parent = root;
	obj.name = index;
	local scale = obj.transform.localScale;

	obj.transform.localPosition = self:SetBoxPos(scale.x,scale.z,(row-1),(Columns-1));


	return obj;
end

function View:SetBoxPos(x,z,row,Columns)
	local thisRow = row-self.maxRow/2;

	local thisCol = Columns-self.maxColumns/2

	local pos = UnityEngine.Vector3(((thisRow * x) or 0),0.3,((thisCol or 0) * z));
	return pos;
end


function View:SetValue(row,Columns)
	return (row-1)*10+Columns;
end

function View:OnDestroy()
	-- ERROR_LOG("离开场景");	
	mazeModule.SetNotify(true);
end


function View:listEvent()
    return {
    	"TEAM_ACTIVITY_FINISHED",--活动结束  参数activity_id活动id
    	"TEAM_ACTIVITY_PLAYER_CHANGE",--活动的玩家信息改变 参数pid
    	"TEAM_ACTIVITY_NPC_CHANGE",   --活动场景中的npc信息改变 参数uuid
		"kICKTEAMSUCCESS",
		"TEAM_MAZE_ACTIVITY_START",
    };
end

local Lords = {
		1601100,
		1601101,
		1601102,
		1601103,
		1601104,
		1601105,

}

function View:Check_Battle_Boss( ... )
	-- GetNpcIsKill
	-- for k,v in pairs(Lords) do

	-- 	-- print("是否死亡",sprinttb(mazeModule.GetNpcIsKill(v)))
	-- end

end

function View:onEvent(event, ...)
	if event == "kICKTEAMSUCCESS" then
		SceneStack.EnterMap(13,{pos = {-3.43,-0.02,9.82}});
	end

    -- ERROR_LOG(event)
    if event == "TEAM_ACTIVITY_FINISHED" then
        local activity_id = select(1, ...)
        if activity_id == 1 then
        	-- print("活动结束------->>>>");
        end
        SceneStack.EnterMap(13,{pos = {-3.43,-0.02,9.82}});
    end

    if event == "TEAM_ACTIVITY_PLAYER_CHANGE" then
        local pid = select(1, ...)
    	-- print("玩家信息改变------->>>>",pid);
    end
    if event == "TEAM_ACTIVITY_NPC_CHANGE" then
        local uuid = select(1, ...)
    	-- print("NPC信息改变------->>>>",uuid);
		local _,data,npcs = mazeModule.Get();
		-- ERROR_LOG("新数据",sprinttb(data))
		-- ERROR_LOG("npc新数据",sprinttb(npcs))
		--与1号npc交互结果
		if uuid == 1 then
			for k,v in pairs(data) do
				if v == 1 then
					mazeModule.ChangeIDStatus(k,true);
				end
			end
		else
			if not npcs then
				return;
			end
			local value = npcs[uuid].value;

			if value then
				--获取到开启的位置
				local pos = mazeModule.GetCubePos(value[1]);
				local npcid = npcs[uuid].id;
				-- ERROR_LOG("uuid   " ,uuid );
				mazeModule.LoadNPC(npcid,pos,value[1],uuid);
				if npcs[uuid].dead == 1 then
					-- ERROR_LOG("第"..value[1].."的怪物死亡");
					mazeModule.DeadNpc(uuid,value[1],npcid);
				end
			end
		end
	end
	
	if event == "TEAM_MAZE_ACTIVITY_START" then

		-- ERROR_LOG("TEAM_MAZE_ACTIVITY_START");
		self:Check();
	end
end


return View;