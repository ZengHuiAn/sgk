local mapid,gid = ...
mapid = tonumber(mapid)

local View = {};
function View:Start(data)
	self.view = CS.SGK.UIReference.Setup(self.gameObject)
	self.view.mask[CS.UGUIClickEventListener].onClick = function ( ... )
		--DialogStack.Pop()
		DialogStack.Destroy("guild/elevatorFrame")
	end
	self.view.close[CS.UGUIClickEventListener].onClick = function ( ... )
		--DialogStack.Pop()
		DialogStack.Destroy("guild/elevatorFrame")
	end
	self.select_idx = nil
	self.view.getBtn[CS.UGUIClickEventListener].onClick = function ( ... )
		if self.select_idx then
			if self.select_idx == 1 then--A
				SceneStack.EnterMap(25)            --传送至公会大厅
				--utils.MapHelper.OpUnionExplore()  --打开军团探险界面
			elseif self.select_idx == 2 then--B
				SceneStack.EnterMap(251)            --传送至甲板        
			elseif self.select_idx == 3 then--C
				showDlgError(nil,"此区域装修中")
			elseif self.select_idx == 4 then--D
				showDlgError(nil,"此区域装修中")
			elseif self.select_idx == 5 then--E
				showDlgError(nil,"此区域装修中")
			elseif self.select_idx == 6 then--F
				showDlgError(nil,"此区域装修中")
			elseif self.select_idx == 7 then--G
				showDlgError(nil,"此区域装修中")
			elseif self.select_idx == 8 then--H
				showDlgError(nil,"此区域装修中")
			end
		end
	end
	for i = 1,#self.view.group do
		if i == 3 or i == 4 or i == 5 or i == 6 or i == 7 or i == 8 then
			self.view.group[i][UI.Image].color = {r=200/255,g=200/255,b=200/255,a=128/255}
		end
		self.view.group[i][CS.UGUIClickEventListener].onClick = function ( ... )
			self.select_idx = i
			self.view.select.transform.position = self.view.group[i].transform.position
			--self.view.select.transform.position = Vector3(self.view.group[i].transform.position.x,self.view.group[i].transform.position.y,0)
			self.view.select:SetActive(true)
		end
	end
end
function View:OnDestroy( ... )
	--DialogStack.Destroy("guild/elevatorFrame")
end
return View