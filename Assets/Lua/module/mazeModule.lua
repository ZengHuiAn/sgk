local data = nil
local socket = require "socket";
local TeamActivityModule = require "module.TeamActivityModule"
local mazeConfig = require "config.mazeConfig"
local EventManager=require 'utils.EventManager';
local Time = require "module.Time"

--格子的信息表
local data_maze = nil
--npc的数据
local npc_data = nil
--npc的模型数据
local npc_count = nil
local npc_obj = nil ;
--npc数量
local count = 0
local mazeCount = 0
local deadBoss = nil
local callback = nil
local flag = nil;
local startTime = nil;
local endTime = nil
--npc是否被交互或战斗过
local npc_inter = nil

local bossStatus = nil
local function Init()
	data_maze = nil;
	npc_data = nil
	deadBoss = nil
	callback = nil;
end
--初始化格子信息
local function setData(info)
	data = {} 
	npc_obj = nil
	data = info;
	npc_count = nil
	mazeCount = 100;
	count = 0;
	if flag then
		Init();
		flag = nil;
	end
end

local function getData()
	return data or {};
end

local function getDataByID(id)
	local shi;
	if id % 10 == 0 then
		shi = (math.modf( (id / 10) )or 0);
	else
		shi = (math.modf( (id / 10) )or 0)+1;
	end

	local ge = id % 10 ;
	if ge == 0 then 
		ge = 10;
	end

	if shi<=0 or shi>10 or ge<=0 or ge>10 then
		return;
	end
	if data[shi][ge] then
		return data[shi][ge];
	end
end

--根据id获取位置 外部使用 module.mazeModule.GetPosByID(id);
local function getCubePos(id)
	local _data = getDataByID(id);
	if _data then
		local pos = _data.data.transform.position;

		if not pos then
			pos = UnityEngine.Vector3.zero;
		end
		return pos;
	else
		-- print("不存在该数据");
	end 
end 

local function LoadEffect(effectname,time)
	local eff = SGK.ResourcesManager.Load("prefabs/effect/"..effectname..".prefab");
	-- ERROR_LOG(eff);
	if eff then

		local effect = UnityEngine.GameObject.Instantiate(eff);
		if time then
			SGK.Action.DelayTime.Create(time):OnComplete(function()
				if utils.SGKTools.GameObject_null(effect) ~= true then
					UnityEngine.GameObject.Destroy(effect)
				end
			end)
			--todo
		end
		return effect;
	else
		ERROR_LOG(effectname.." is not find");
	end
end

local function getCubeS(data)
	if data then
		if data.data.activeInHierarchy == false then
			return nil;
		end
	end
	return true;
end

local function getCubeStatus(id)
	local data = getDataByID(id);

	--检查上下左右有没有被消除
	local right = getDataByID(id+1);
	local left = getDataByID(id-1);

	local up = getDataByID(id+10);
	local down = getDataByID(id - 10 );

	if getCubeS(right) and  getCubeS(left) and getCubeS(up) and getCubeS(down) then
		return false;
	end

	return true;
end


--刷掉物体 外部使用 module.mazeModule.ChangeIDStatus(id);
local function changeIDStatus(id,_status)
	local _data = getDataByID(id);
	-- ERROR_LOG(id,"   ",sprinttb(data));
	if _data and _data.data.gameObject.activeInHierarchy then
		if _status then
			local eff = LoadEffect("UI/fx_maze_boom",2);
			if eff then
				-- ERROR_LOG("播放特效");
				eff.gameObject.transform.position = getCubePos(id);
				SGK.Action.DelayTime.Create(1):OnComplete(function()
		            UnityEngine.Object.Destroy(eff)
		        end)
			end
		end
		_data.data.gameObject:SetActive(false);
		mazeCount = mazeCount -1;

		DispatchEvent("MAZECUBECHANGE",mazeCount);

	end
end

local function changeIDClick( id ,time)
	local _data = getDataByID(id);

	if _data and _data.data.gameObject.activeInHierarchy then


		local eff = LoadEffect("UI/maze_cube_standby".._data.data.gameObject.name,time);
		eff.gameObject.transform.parent = _data.data.gameObject.transform;
		eff.gameObject.transform.localPosition = Vector3.zero
		eff.gameObject.transform.localRotation  = UnityEngine.Quaternion.identity

	end

end

--获取格子存储的id
local function getNPCID(cubeid)
	local _data =getDataByID(cubeid);
	return _data;
end

local npc_uuid = nil
local function randomMaze(count)

	math.randomseed(tostring(socket.gettime()):reverse():sub(1, 6)) 
	local index = math.random(1,count);
	return index;
end

--根据获取到的格子信息 来改变格子的状态
local function ChangeMazeData(data1,data2,data3,data4,data5)
	-- ERROR_LOG("----------",data1,data2,data3,data4,data5);
	if not data_maze then
		data_maze = {};
	end
	local count = 0;
	local changeData = {}
	if data1 then
		local d1_20 = BIT(data1);
		for i,v in ipairs(d1_20) do
			if data_maze[i] ~= v then
				data_maze[i] = v ;
			end
			if v == 1 then
				count = count + 1;
			end
		end
	end
	if data2 then
		local d21_40 = BIT(data2);
		for i,v in ipairs(d21_40) do
			if data_maze[i+20] ~= v then
				data_maze[i+20] =v;
			end
			if v == 1 then
				count = count + 1;
			end
		end
	end


	if data3 then
		local d41_60 = BIT(data3);
		for i,v in ipairs(d41_60) do

			if data_maze[i+40] ~= v then
				data_maze[i+40] =v;
			end
			if v == 1 then
				count = count + 1;
			end
		end
	end
	if data4 then
		local d61_80 = BIT(data4);
		for i,v in ipairs(d61_80) do

			if data_maze[i+60] ~= v then
				data_maze[i+60] =v;
			end
			if v == 1 then
				count = count + 1;
			end
		end
	end
	if data5 then
		local d81_100 = BIT(data5);
		for i,v in ipairs(d81_100) do
			if data_maze[i+80] ~= v then
				data_maze[i+80] =v;
			end
			if v == 1 then
				count = count + 1;
			end
		end
	end
	return count
end


local function UpdateDoneNpc(this_data)
	
	-- ERROR_LOG("更新数据--------------------=============",sprinttb(this_data));
	npc_inter = npc_inter or {};

	npc_inter[this_data["uuid"]] = npc_inter[this_data["uuid"]] or {};

	npc_inter[this_data["uuid"]].event = npc_inter[this_data["uuid"]].event or {};

	if not npc_inter[this_data["uuid"]].event[this_data.value[2]+1] then
		--修改成功
		npc_inter[this_data["uuid"]].event[this_data.value[2]+1] = npc_inter[this_data["uuid"]].event[this_data.value[2]+1] or {};
		npc_inter[this_data["uuid"]].event[this_data.value[2]+1].time = Time.now();

		npc_inter[this_data["uuid"]].event[this_data.value[2]+1].status = this_data.value[2];
		npc_inter[this_data["uuid"]].event[this_data.value[2]+1].gid = this_data.value[1];
		npc_inter[this_data["uuid"]].event[this_data.value[2]+1].id = this_data.id;

		-- ERROR_LOG("修改成功---->>>",npc_inter[this_data["uuid"]]);
		return npc_inter[this_data["uuid"]].event[this_data.value[2]+1];
	end
	

end

--存储npc数据

local function UpdateInterNpc(npcs)

	if not npcs then return end;
	-- ERROR_LOG(sprinttb(npcs));
	npc_inter =npc_inter or{}; 
	for k,v in pairs(npcs) do
		if k ~= 1 then
			npc_inter[v.uuid] = npc_inter[v.uuid] or {};

			npc_inter[v.uuid].event = npc_inter[v.uuid].event or {};

			if not npc_inter[v.uuid].event[v.value[2]+1] then
				npc_inter[v.uuid].event[v.value[2]+1] = npc_inter[v.uuid].event[v.value[2]+1] or {};

				npc_inter[v.uuid].event[v.value[2]+1].time = Time.now();
				npc_inter[v.uuid].event[v.value[2]+1].status = v.value[2];
				npc_inter[v.uuid].event[v.value[2]+1].gid = v.value[1];
				npc_inter[v.uuid].event[v.value[2]+1].id = v.id;

			end

			if v.dead == 1 then
				UpdateDoneNpc({["uuid"] = v.uuid , ["value"] = { v.value[1] , 1}, ["id"] = v.id});
			end
		end
	end
end

local time_open = nil

local function setTime(this_status)
	time_open = this_status;
end

local enemybuff = nil;
local selfbuff = nil

local function getBuff( ... )
	return selfbuff,enemybuff;
end 

local function Get(flag)
	local _data,isloading = TeamActivityModule.Get(1);
	-- ERROR_LOG("==============================",sprinttb(_data),isloading);
	local count = nil

	if _data and not isloading then
		startTime = _data.startTime;
		endTime = _data.endTime;
		if not time_open then
			DispatchEvent("ACTIVITYTIME",{startTime,endTime});
			time_open = true;
		end
		-- npc_uuid
		local value = _data.npcs[1];
		if value.uuid then
			npc_uuid = value.uuid;
		end
		if flag then
			UpdateInterNpc(_data.npcs);
		end

		enemybuff = {};
		selfbuff = {}
		local length = 0
		for k,v in pairs(_data.npcs) do
			length  = length +1;
		end
		-- print("长度==========",table.maxn(_data.npcs));
		for i=2,length do
			local item_value = _data.npcs[i].value[3];
			-- print("======",item_value);
			if item_value ~= 0 then

				if item_value - 4000000 > 100  then
					
					table.insert(selfbuff,item_value);
				else
					table.insert(enemybuff,item_value);
				end
			end
		end

		-- ERROR_LOG("更新后的npc信息",sprinttb(npc_inter));
		if value then
			count = ChangeMazeData(value.value[1],value.value[2],value.value[3],value.value[4],value.value[5]);
		end



	--获取npc数据改变的表
		return isloading,data_maze ,_data.npcs;
	else
		startTime = nil;
		endTime = nil;
		return isloading,data_maze;
	end
	
end

--获取npc信息
local function getNpcData(npcid)
	local _,__,npcs= Get();
	npc_data = npcs; 
	if npcid then
		for k,v in pairs(npc_data) do
			if v.id == npcid then
				return v
			end
		end
	else
		return npc_data;
	end
end




local function GetNpcIsKill(gid)
	-- ERROR_LOG("交互的npc数据",sprinttb(getNpcData() or {}));
	if npc_inter then
		local npcinfo = {};
		local npcdata = getNpcData() or {};
		for k,v in pairs(npcdata) do

			npcinfo[v.id] = npcinfo[v.id] or {}
			table.insert(npcinfo[v.id],v.dead);
		end

		-- ERROR_LOG("交互的npc数据",sprinttb(npcinfo));

		if not npcinfo[gid] then
			return nil
		end

		local index = 0

		for k,v in pairs(npcinfo[gid]) do
			if v == 1 then
				index = index +1
			end
		end

		return index;

	end
end

local function GetBoss()
	local num = GetNpcIsKill(1601106)
	-- ERROR_LOG("bossStatus",num,bossStatus);
	--开始的时候boss没有死
	if not bossStatus then
		return num;
	else
		return -1;
	end
end


local function Interact(npcid,mazeid,_callback)
	if not npcid then return end
	local _,data = Get();
	if npcid == 1 then
		callback = nil
	else
		if _callback and _callback.callback then
			callback = callback or {}
			local c_callback = _callback.callback;

			table.insert(callback,c_callback);
		end
	end
	
	TeamActivityModule.Interact(1,tonumber(npcid),tonumber(mazeid));
end


local function getCallBack()

	if callback then
		local value = callback[1];

		table.remove(callback,1)
		return value;
	end
end


local activity_flag = nil
local function StartMazeActivity(sceneid)
	coroutine.resume(coroutine.create( function ( ... )
		local _,isloading = module.TeamActivityModule.Get();
		utils.NetworkService.Send(16204)
		local data = utils.NetworkService.SyncRequest(16200,{nil, 1});
		if data[2] == 1 then
			SceneStack.EnterMap(sceneid)
		elseif data[2] ==0 then
			local ret = utils.NetworkService.SyncRequest(16200,{nil, 1});
			if ret[2] ==1 then
				-- ERROR_LOG("开启失败");
				SceneStack.EnterMap(sceneid)
			end
		end
	end) )
end


local function ShowNpcDes(npc_view,name)
	npc_view.Root.Canvas.name[UI.Text].text = name;
end 

local function LoadNPCByType(type,mode,id,cfg)
	local _obj = nil
	if type ==1  then	
		local prefab = SGK.ResourcesManager.Load("prefabs/common/mazeNpc1.prefab");
		local root = UnityEngine.GameObject.Instantiate(prefab);
		root:SetActive(false);
		local obj = SGK.UIReference.Setup(root);
		local spine = obj.Root.spine[CS.Spine.Unity.SkeletonAnimation];
			--小人
		spine.skeletonDataAsset = SGK.ResourcesManager.Load("roles_small/"..cfg.mode.."/"..cfg.mode.."_SkeletonData.asset");
	  	spine:Initialize(true);
	  	if spine.state then
		  	spine.state:SetAnimation(0,"idle1",true);
		end
		obj.Root.spine.gameObject.transform.localScale = obj.Root.spine.gameObject.transform.localScale * cfg.scale_rate;
		_obj= obj;
	elseif type ==2 then
		local prefab = SGK.ResourcesManager.Load("prefabs/common/mazeNpc.prefab");
		local root = UnityEngine.GameObject.Instantiate(prefab);
		root:SetActive(false);
		local obj = SGK.UIReference.Setup(root);
		local spine = obj.Root.spine[CS.Spine.Unity.SkeletonAnimation];
			--小人
		spine.skeletonDataAsset = SGK.ResourcesManager.Load("roles/"..cfg.mode.."/"..cfg.mode.."_SkeletonData.asset");
	  	spine:Initialize(true);
	  	if spine.state then
		  	spine.state:SetAnimation(0,"idle",true);
		end
		obj.Root.spine.gameObject.transform.localScale = obj.Root.spine.gameObject.transform.localScale * cfg.scale_rate;

		_obj= obj;

	elseif type == 3 then
		local prefab = SGK.ResourcesManager.Load("prefabs/common/mazeNpc2.prefab");
		local root = UnityEngine.GameObject.Instantiate(prefab);
		root:SetActive(false);
		local obj = SGK.UIReference.Setup(root);
		_obj= obj;
	end
	_obj:SetActive(true);
	return _obj;
end

local function getNpc(uuid)
	if uuid and npc_obj then
		return npc_obj[uuid];
	end
	
end

local npc_id_obj = {}

local function LoadNPC(id,pos,_cubeid,uuid,_status)
	if getNpc(uuid) then
		return
	end
	npc_id_obj = npc_id_obj or {};
	pos = UnityEngine.Vector3(pos.x,0,pos.z);
	-- ERROR_LOG("加载"..id,"第".._cubeid.."格子上");

  	if not npc_obj then
  		npc_obj = {};
  	end
	local cfg = mazeConfig.GetInfo(id);
	if cfg then
		
		local obj = nil
		if cfg.mode then
			obj = LoadNPCByType(cfg.mode_type,cfg.mode,id,cfg)
		end
		if obj then
			ShowNpcDes(obj,cfg.name);
			obj.name = id;

			local scale = obj.Root.spine.gameObject.transform.localScale;
			
			local mul  = tonumber(cfg.scale_rate);

			-- print("缩放值-------->>>>>",mul);
			if not _status then

				if cfg.effect~="0" then
					local effect = LoadEffect(tostring(cfg.effect));

					if effect then
						effect.gameObject.transform.position = pos;
						effect.gameObject.transform.parent = obj.gameObject.transform;
					end
				end
			end
	  		obj.gameObject.transform.position = pos;
		end

	  	if cfg.script and obj then
	  		-- print("npc脚本",cfg.script);
	  		obj[CS.SGK.MapInteractableMenu].LuaTextName = cfg.script;
	  		obj[CS.SGK.MapInteractableMenu].values[1] = cfg.id;

	  		obj[CS.SGK.MapInteractableMenu].values[0] =uuid;

	  		-- print("born_script",cfg.born_script);
	  		if (cfg.born_script ~= "0") then
	  			local born = LoadEffect(cfg.born_script);
	  			born.transform.parent = obj.transform;
	  			born.transform.position = pos
	  		end

	  		--加载npc特效

	  	end
  		if cfg.halo_effect~= "0" then
  			local halo = LoadEffect(cfg.halo_effect);
  			halo.transform.parent = obj.transform;
  			halo.transform.position = pos;
  			-- ERROR_LOG("NPC加载特效"..cfg.halo_effect);
  		end

	  	

	  	if obj then
		  	npc_obj[uuid] = obj.gameObject;
		  	npc_id_obj[id] = obj.gameObject;
		  	 local _value = {[1] = _cubeid ,[2] = 0 };

		  	local _info = UpdateDoneNpc({["uuid"] = uuid ,["value"] = _value ,["id"] = id});
		  	if _info then
		  		DispatchEvent("NPCINFOCHANGE",_info);
		  	end
		  	
		end
		local npc_cfg = mazeConfig.GetInfo(id);
		if npc_cfg.type ~= 4 then
			count = count+1;
			DispatchEvent("MAZENPCCHANGE",count);
		end
		
	end

end

local function GetNPCObj( id )

	if id then
		return npc_id_obj[id];
	end
end

local function getTime()
	return startTime,endTime;
end


local function getNpcCount()
	return count;
end

local function getMazeCount()
	return mazeCount or 0;
end
local bossflag = 0



local function changeDeadNpc(uuid,cubeid,npcid)
	if uuid and npc_obj and npc_obj[uuid] then


		local _data_npc = getNpcData();
		
		if npc_obj[uuid].gameObject.activeInHierarchy then 
			-- ERROR_LOG("有怪物死亡",uuid);

			npc_obj[uuid].gameObject:SetActive(false);
			-- ERROR_LOG("cubeid "..cubeid);
			
			local __info = UpdateDoneNpc({["uuid"] = uuid , ["value"] = { cubeid , 1}, ["id"] = npcid});

			if __info then
				DispatchEvent("NPCINFOCHANGE",__info);
			end
			

			local npc_cfg = mazeConfig.GetInfo(_data_npc[tonumber(uuid)].id);
			if npc_cfg.type ~= 4 then
				count = count -1;
				DispatchEvent("MAZENPCCHANGE",count);
			end
			-- ERROR_LOG("boss死亡",_data_npc[tonumber(uuid)].id);
			if tonumber(_data_npc[tonumber(uuid)].id) == 1601106 then
				-- ERROR_LOG("boss死亡");
				if not deadBoss then
					DispatchEvent("MAZEBOSSDEAD");

					deadBoss= deadBoss or {};
					deadBoss.flag = true;
					bossflag = bossflag + 1
				end
			end
		end
	end
end

local function getInterNpc()
	return npc_inter;
end

local Notify = nil

local function setNotify(this_status)
	Notify = this_status;
end

local activity_open = nil

EventManager.getInstance():addListener("TEAM_ACTIVITY_START", function(event,activity_id)
	-- print("===439==",pid)
	print("活动开始---->>>");
	if activity_id == 1 then
    	-- ERROR_LOG("活动开始------->>>>");
    	time_open = nil;
    	flag = true;
    	npc_inter = nil;
		bossStatus = nil;
		activity_open = true;

    	local _,data,npcs = Get(true);
		
    	-- ERROR_LOG("活动开始",sprinttb(npcs));
		
    	for k,v in pairs(npcs) do
    		if v.id == 1601106 and v.dead == 1 then
    			bossStatus = true;
    		end
    	end
		DispatchEvent("TEAM_MAZE_ACTIVITY_START");

    end
end)

EventManager.getInstance():addListener("TEAM_ACTIVITY_FINISHED", function(event,activity_id)
	-- print("===439==",pid)
	if activity_id == 1 then
    	time_open = nil;
    	flag = true;
    	npc_inter = nil;
		bossStatus = nil;
		activity_open = nil;
    end
end)


EventManager.getInstance():addListener("LOGIN_SUCCESS", function(event, pid)

	local _,data,npcs = Get(true);
	-- ERROR_LOG(_);
	if _ == true then
		-- ERROR_LOG("开启活动=============>>>>>");
		module.mazeModule.Start();
	end
end);


--npc改变
EventManager.getInstance():addListener("TEAM_ACTIVITY_NPC_CHANGE", function(event,uuid)


	--如果离开场景了
	if Notify then
		Get(true);
	end
end)
--所有的元素领主都被杀死
local IsKillAllNpc = nil

local function GetIsAllKill ( ... )
	return IsKillAllNpc
end

local function SetIsAllKill( ... )
	IsKillAllNpc = true
end

local function GetOpen(  )
	return activity_open;
end

local function SetStatus( ... )
	bossStatus = true
end

return {
	SetData 	= 		setData,
	GetData 	= 		getData,
	GetCubePos	=		getCubePos,
	ChangeIDStatus 	= 	changeIDStatus,
	GetNPCID	=		getNPCID,
	RandomMaze  = 		randomMaze,
	Get 		= 		Get,
	Interact	= 		Interact,
	Start 		= 		StartMazeActivity,
	LoadNPC 	= 		LoadNPC,
	DeadNpc 	= 		changeDeadNpc,
	GetNpcData  = 		getNpcData,
	GetNpcCount = 		getNpcCount,
	GetMazeCount= 		getMazeCount,
	GetTime 	=		getTime,
	GetCallBack = 		getCallBack,
	GetInterNpc = 		getInterNpc,
	GetCubeInter= 		getCubeStatus,
	GetNpcIsKill = 		GetNpcIsKill,
	--获取这个npcid在npc表里存在不存在
	GetNpc 		= 		getNpc,
	SetTime		= 		setTime,
	SetNotify 	=		setNotify,
	GetBoss 	=		GetBoss,
	GetBuff     = 		getBuff,

	GetNPCObj   =       GetNPCObj,

	LoadEffect  = 		LoadEffect,

	SetIsAllKill = SetIsAllKill,

	GetIsAllKill  =GetIsAllKill,

	GetOpen    =   		GetOpen,

	SetStatus  =   SetStatus,
	changeIDClick = changeIDClick
}
