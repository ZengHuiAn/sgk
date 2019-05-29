local WorldAnswerConfig = require "config.WorldAnswerConfig"
local WorldAnswerModule = require "module.WorldAnswerModule"
local ItemHelper = require "utils.ItemHelper"

local View = {};

function View:Close()
    DialogStack.Pop();
    SceneStack.EnterMap(25)
end

function View:Start(data)

    -- print(sprinttb(data));
    
    self.data = data;
    self:InitSelfData();

    self.pid = module.playerModule.GetSelfID();
    local union = module.unionModule.GetPlayerUnioInfo(self.pid);

    self.unionName = union.unionName;


	self.view = SGK.UIReference.Setup(self.gameObject)

    CS.UGUIClickEventListener.Get(self.view.area.title.close.gameObject,true).onClick = function (obj)
        self:Close();
    end

    self:Fresh();
    

    self.time = (data and data.time or nil) or 15;
    self.title = data and data.title or nil;
    if self.title then
        self.view.area.title.Text[UI.Text].text = self.title;
    end
    self.lock =nil;
    self.view.area.btnOK[UI.Button].onClick:AddListener(function ()
        self:Close();
    end);

end


function View:Fresh()
    self.tempdata = {};
    local selfinfo,cout = self:InitData(self.data);
    -- ERROR_LOG(selfinfo,cout);
    -- ERROR_LOG(sprinttb(self.tempdata));
    if not selfinfo or not cout then
        local ret = self:InitSelfData();
        self.view.area.playerInfo.top.gameObject:SetActive(true);
        self.view.area.playerInfo.rank.gameObject:SetActive(false);
        self.view.area.playerInfo.top.Text.gameObject:SetActive(false);
        self.view.area.playerInfo.top[UI.Image]:LoadSprite("icon/".."rank_dw1");
        -- self.view.area.playerInfo.top.Text
        self:FreshItem(self.view.area.playerInfo,ret,ret.cout);
    else
        self:FreshItem(self.view.area.playerInfo,selfinfo,cout);
    end
    self:FreshScrollView();
end

function View:InitSelfData()
    local info = module.playerModule.Get(self.pid);
    if info then
        return {name = info.name ,guild = self.unionName ,score = 0 ,pid = self.pid};
    end
end


function View:FreshScrollView()
    self.UIDragIconScript = self.view.area.ScrollView[CS.UIMultiScroller];
    self.UIDragIconScript.RefreshIconCallback = function (obj, idx)
        obj.gameObject:SetActive(true);
        local item = SGK.UIReference.Setup(obj);
        -- print(sprinttb(item));
        self:FreshItem(item,self.tempdata[idx+1],idx+1);
    end;
    self.UIDragIconScript.DataCount = #self.tempdata >50 and 50 or #self.tempdata;
end


function View:Update()
    if not self.lock and self.time and self.time > 0 then

        self.time = self.time - UnityEngine.Time.deltaTime;

        self.view.area.btnOK.time[UI.Text].text = math.floor(self.time);
    else

        if not self.lock then
        --活动结束
            self.view.area.btnOK.time[UI.Text].text = 0;
            -- print("活动结束");
            self.lock =true;
            self:Close();
        end
    end
end

function View:InitData(value)

    if not value then return end 

    local selfdata = nil
    for k,v in pairs(value) do
        self.tempdata = self.tempdata or {};
        local info = module.playerModule.Get(k);
        if info then
            local temp = {name = info.name ,guild = self.unionName ,score = ( v.count or 0 )*10 ,pid = k};
            table.insert(self.tempdata, temp);
        end
    end

    table.sort(self.tempdata, function (a,b)
        return a.score > b.score;
    end )

    for i,v in ipairs(self.tempdata) do

        if v.pid == self.pid then
            return v,i; 
        end
    end
end

function View:FreshItem(parent,data,idx)

    if not data then
        parent.gameObject:SetActive(false); 
        return 
    end
    parent.name[UI.Text].text = data.name;

    parent.score[UI.Text].text = data.score;

    parent.guild[UI.Text].text = data.guild;

    parent.rank[UI.Text].text = idx or 1;

    if idx and idx < 4 then
        parent.top.gameObject:SetActive(true);
        parent.top.Text.gameObject:SetActive(false);
        parent.top[UnityEngine.UI.Image]:LoadSprite("icon/rank_"..idx)
    end
    utils.IconFrameHelper.Create(parent.IconFrame, {pid = data.pid});
end
-- PLAYER_INFO_CHANGE
function View:listEvent()
    return {
    "PLAYER_INFO_CHANGE",
    }
end

function View:onEvent( event,data )

    if event == "PLAYER_INFO_CHANGE" then
        if not self.flag then
            self:Fresh();
            self.flag= true
        end
    end

end

return View