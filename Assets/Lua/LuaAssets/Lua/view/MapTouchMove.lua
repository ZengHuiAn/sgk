local View = {}


function View:Start(args)
    -- local canvas = SGK.UIReference.Instantiate(SGK.ResourcesManager.Load("prefabs/newSelectMap/selectMaps/newnewSelectMapUpCanvas.prefab"))

    self.view = SGK.UIReference.Setup(self.gameObject);

    self.controller = self.view.MapSceneController[SGK.MapSceneController];
    -- canvas[UnityEngine.Canvas].worldCamera = self.controller.UICamera;

    self.cameraTarget = UnityEngine.GameObject();
    self.cameraTarget.name = "camera_target";
    local cameraController = self.controller.playerCamera;
    cameraController.target = self.cameraTarget.transform;
    cameraController.speed = 0;

    local viewArea = cameraController.viewArea;

    local min = viewArea.position - viewArea.lossyScale / 2
    local max = viewArea.position + viewArea.lossyScale / 2

    self.min = {x = min.x, y = min.y, z = min.z}
    self.max = {x = max.x, y = max.y, z = max.z}

    local playerCamera = self.controller.playerCamera:GetComponent(typeof(UnityEngine.Camera));
    if playerCamera.orthographic then
        self.min.x = self.min.x + playerCamera.orthographicSize * playerCamera.aspect;
        self.max.x = self.max.x - playerCamera.orthographicSize * playerCamera.aspect;

        self.min.z = self.min.z + playerCamera.orthographicSize;
        self.max.z = self.max.z - playerCamera.orthographicSize;

        if max.x < min.x then
            max.x = (min.x + max.x) / 2;
            min.x = max.x;
        end

        if max.z < min.z then
            max.z = (min.z + max.z) / 2;
            min.z = max.z
        end
    end

    self.y = viewArea.y;
    self.cameraTarget.transform.position = self:AddjustCameraTarget(args and args.pos or Vector3(0, 0, 0));
end

function View:AddjustCameraTarget(pos)
    pos.y = self.y;
    if pos.x < self.min.x then pos.x = self.min.x end;
    if pos.z < self.min.z then pos.z = self.min.z end;

    if pos.x > self.max.x then pos.x = self.max.x end;
    if pos.z > self.max.z then pos.z = self.max.z end;

    return pos;
end

local function  GetTouchPostion()
    if UnityEngine.Application.isEditor then
        if not UnityEngine.EventSystems.EventSystem.current then
            return;
        end
        if UnityEngine.EventSystems.EventSystem.current:IsPointerOverGameObject() then
            return;
        end
    
        if UnityEngine.Input.GetMouseButton(0) then
            return UnityEngine.Input.mousePosition;
        end
    else
        if UnityEngine.Input.touchCount == 0 then
            return;
        end

        local touch = UnityEngine.Input.GetTouch(0);

        if not touch or UnityEngine.EventSystems.EventSystem.current:IsPointerOverGameObject(touch.fingerId) then
            return;
        end

        if touch.phase == UnityEngine.TouchPhase.Began or touch.phase == UnityEngine.TouchPhase.Moved then
            return touch.position;
        end
    end
end

function View:Update()
    local pos = GetTouchPostion();
    if not pos then
        self.last_postion = nil;
        return;
    end

    if self.last_postion == nil then
        self.last_postion = {x=pos.x,y=pos.y};
        return;
    end

    local offset = {
        x = pos.x - self.last_postion.x,
        y = pos.y - self.last_postion.y,
    }

    local cameraPostion = self.cameraTarget.transform.position;
    local rate = 0.01;
    cameraPostion.x = cameraPostion.x - offset.x * rate;
    cameraPostion.z = cameraPostion.z - offset.y * rate;
    
    self.cameraTarget.transform.position = self:AddjustCameraTarget(cameraPostion);

    self.last_postion = {x=pos.x,y=pos.y,z= pos.z};
end

function View:listEvent()
	return {
        "LOCAL_GUIDE_OPT_CAMERA",
	}
end

function View:onEvent(event, ...)
    local data = ...
    if event == "LOCAL_GUIDE_OPT_CAMERA" then
        local x = tonumber(data[1])
        self.cameraTarget.transform.position = self:AddjustCameraTarget(Vector3(-1.07 + x, 0, 0));
	end
end



return View;