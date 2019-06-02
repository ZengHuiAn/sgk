local defensiveModule = require "module.DefensiveFortressModule"
local playerModule = require "module.playerModule";
local View = {};

function View:Start()
	self.view=CS.SGK.UIReference.Setup(self.gameObject)
	self.moveMapItemsUI={}
end

function View:InitData(data)
	self.PlayerData=data.PlayerData
	self.BossData=data.BossData
	self.teamInfo=data.teamInfo

	self.boss=UnityEngine.GameObject.Find("Boss_"..self.BossData.Id)
 
	local root=UnityEngine.GameObject.Find("MapSceneController")
	self.mapController = root.gameObject:GetComponent(typeof(SGK.MapSceneController));

	self.Pid=module.playerModule.GetSelfID()
	self.Obj=self.mapController:Get(self.Pid)

	local bossCfg=defensiveModule.GetBossCfg(self.BossData.Id)

	local prefab=SGK.ResourcesManager.Load("prefabs/MapUI/moveMapItem.prefab")
	local item
	item,self.moveMapItemsUI=defensiveModule.CopyUI(self.moveMapItemsUI,self.view.transform,prefab,self.BossData.Id)
	if item then
		item[SGK.moveMapItem]:SetInfo(bossCfg.Monster_icon,0)
	end
	for k,v in pairs(self.teamInfo.members) do
		if v.pid ~= self.Pid then
			local _item
			_item,self.moveMapItemsUI=defensiveModule.CopyUI(self.moveMapItemsUI,self.view.transform,prefab,v.pid)
			if _item then
				if playerModule.IsDataExist(v.pid) then
					local player=playerModule.IsDataExist(v.pid)
					_item[SGK.moveMapItem]:SetInfo(player.head.."")
				else
					playerModule.Get(pid,function ( ... )
						_item[SGK.moveMapItem]:SetInfo(player.head.."")
					end)
				end
			end
			_item.localPosition=Vector3(100000,100000,0)
		end
	end
end

function View:InMoveMap(targetObj,mapItem)
	if targetObj and mapItem then
		mapItem=CS.SGK.UIReference.Setup(mapItem)
		--是否可见

		local posViewport=UnityEngine.Camera.main:WorldToViewportPoint(targetObj.transform.position)
		if not posViewport then return end
		local _orthographicSize=UnityEngine.Camera.main.orthographicSize
		local _rect = UnityEngine.Rect(0, 0, 1, 1);
		local _visible = _rect:Contains(posViewport);
		mapItem:SetActive(not _visible)

		local _x=targetObj.transform.position.x-self.Obj.transform.position.x
		local _z=targetObj.transform.position.z-self.Obj.transform.position.z
		--arrow旋转
		local a=UnityEngine.Mathf.Atan2(_z,_x)* UnityEngine.Mathf.Rad2Deg
		mapItem.arrow.transform.localRotation = Quaternion.Euler(0, 0, a-90);

		--更新位置
		local _off_x=UnityEngine.Screen.width/2-mapItem[UnityEngine.RectTransform].sizeDelta.x/2
		local _off_y=UnityEngine.Screen.height/2-mapItem[UnityEngine.RectTransform].sizeDelta.y/2

		if _x>=0 and _z>=0 then
			_off_y=_off_y-115
			local limitA=math.atan(_off_y,_off_x)*CS.UnityEngine.Mathf.Rad2Deg
			local _a=Vector3.Angle(Vector3(_x,_z,0),Vector3(1,0,0))
			if _a<limitA then
				local _y=math.tan(math.rad(_a))*_off_x
				mapItem.transform.localPosition=Vector3(_off_x,_y,0)
			elseif limitA<_a then
				local _y=math.tan(math.rad(90-_a))*_off_y
				mapItem.transform.localPosition=Vector3(_y,_off_y,0)
			else
				mapItem.transform.localPosition=Vector3(_off_x,_off_y,0)
			end
		elseif _x<=0 and _z>=0 then
			_off_y=_off_y-115
			local limitA=math.atan(_off_y,_off_x)*CS.UnityEngine.Mathf.Rad2Deg
			local _a=Vector3.Angle(Vector3(_x,_z,0),Vector3(-1,0,0))
			if _a<limitA then
				local _y=math.tan(math.rad(_a))*_off_x
				mapItem.transform.localPosition=Vector3(-_off_x,_y,0)
			elseif limitA<_a then
				local _y=math.tan(math.rad(90-_a))*_off_y
				mapItem.transform.localPosition=Vector3(-_y,_off_y,0)
			else
				mapItem.transform.localPosition=Vector3(-_off_x,_off_y,0)
			end
		elseif _x>=0 and _z<=0 then
			_off_y=_off_y-150
			local limitA=math.atan(_off_y,_off_x)*CS.UnityEngine.Mathf.Rad2Deg
			local _a=Vector3.Angle(Vector3(_x,_z,0),Vector3(1,0,0))
			if _a<limitA then
				local _y=math.tan(math.rad(_a))*_off_x
				mapItem.transform.localPosition=Vector3(_off_x,-_y,0)
			elseif _a>limitA then
				local _y=math.tan(math.rad(90-_a))*_off_y
				mapItem.transform.localPosition=Vector3(_y,-_off_y,0)
			else
				mapItem.transform.localPosition=Vector3(_off_x,-_off_y,0)
			end
		elseif _x<=0 and _z<=0 then
			_off_y=_off_y-150
			local limitA=math.atan(_off_y,_off_x)*CS.UnityEngine.Mathf.Rad2Deg
			local _a=Vector3.Angle(Vector3(_x,_z,0),Vector3(-1,0,0))
			if _a<limitA then
				local _y=math.tan(math.rad(_a))*_off_x
				mapItem.transform.localPosition=Vector3(-_off_x,-_y,0)
			elseif _a>limitA then
				local _y=math.tan(math.rad(90-_a))*_off_y
				mapItem.transform.localPosition=Vector3(-_y,-_off_y,0)
			else
				mapItem.transform.localPosition=Vector3(-_off_x,-_off_y,0)
			end
		end
	end
end

function View:Update()
	if self.BossData then
		self:InMoveMap(self.boss,self.moveMapItemsUI[self.BossData.Id])
	end
	if self.teamInfo then
		for k,v in pairs(self.teamInfo.members) do
			if self.moveMapItemsUI[v.pid] then
				local playerObj=self.mapController:Get(v.pid)
				self:InMoveMap(playerObj,self.moveMapItemsUI[v.pid])
			end
		end
	end
end

function View:listEvent()
	return {
		"FORTRESS_GAME_OVER",
	}
end

function View:onEvent(event, data)
	if event =="FORTRESS_GAME_OVER" then
		CS.UnityEngine.GameObject.Destroy(self.boss.gameObject)
	end
end
return View;