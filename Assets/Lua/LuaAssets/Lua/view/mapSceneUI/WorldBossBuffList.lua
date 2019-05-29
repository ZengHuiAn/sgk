
local View = {}
local HeroBuffModule = require "hero.HeroBuffModule"
local Time = require "module.Time"
local Buff = {}

local function getTimeHMS(time)
    local H = math.floor(time /3600);
    time = math.fmod(time ,3600)
    local M = math.floor(time/60);
    time = math.fmod(time ,60)
    local S = time
    return H,M,S
end
function Buff:NewBuff(data)
    local o = {}

    o.data = data;
    setmetatable(o, {__index = Buff});
    return o;
end

function Buff:updatebuffTime()

    local time = self.data.end_time - Time.now();

    local format = GetTimeFormat(time,2,2);
    if time >=0 then
        if time >=60 then
            return "<color=green>"..format.."</color>"
        end
        if time <= 10 then
            return "<color=red>"..format.."</color>"  
        end
        return "<color=green>"..format.."</color>";
    else
        return nil
    end
end

function Buff:InitObj( obj )
    self.obj = obj
end


local worldBossConfig = {
    [31014] = "buff/buff_19",
}


function View:Start( data )
    local parent = CS.SGK.UIReference.Setup(self.gameObject);
    self.view = parent.Root;
    self:Init();
    self:InitData();
end

function View:InitData(  )
    local bufflist = HeroBuffModule.GetList();
    local temp = {}
    self.end_time = nil;
    for k,v in pairs(bufflist) do
        if worldBossConfig[v.id] then
            ERROR_LOG("time",sprinttb(v))

            if v.end_time-Time.now()> 0 then
                table.insert( temp, Buff:NewBuff(v));
                if self.end_time then
                    self.end_time = self.end_time < v.end_time and v.end_time or self.end_time;
                else
                    self.end_time = v.end_time;
                end
            end
        end
    end

    if self.end_time then
        if self.action then
            self.action:Kill();
        end
        utils.SGKTools.loadEffect("caiji_buff",nil,{isWorldBoss = true});
        self.action = SGK.Action.DelayTime.Create(self.end_time - Time.now()):OnComplete(function()
            utils.SGKTools.DelEffect("caiji_buff");
        end)
    end

    self.buff = temp;

    if #self.buff == 0 then
       self.view:SetActive(false);
        self.view.ScrollView.item:SetActive(false);
    else
        self.view:SetActive(true);
    end
    self.view.ScrollView[CS.UIMultiScroller].DataCount = #self.buff
end

function View:OnDestroy( ... )
    utils.SGKTools.DelEffect("caiji_buff");
end

function View:Update( ... )

    if self.buff and #self.buff >0 then
        for k,v in pairs(self.buff) do
            if v then
                local ret = v:updatebuffTime();
                if not ret then
                    self:InitData();
                    return;
                else
                    if v.obj then
                        v.obj.Text[UI.Text].text = ret;
                    end
                end            
            end
        end
    end
end
function View:Init( ... )

    self.view.ScrollView[CS.UIMultiScroller].RefreshIconCallback = function(obj, idx)
        local view = CS.SGK.UIReference.Setup(obj);

        local value = self.buff[idx+1];

        local name = worldBossConfig[tonumber(value.data.id)]


        view.Image[UI.Image]:LoadSprite("icon/"..tostring(name))
        CS.UGUIClickEventListener.Get(view.Image.gameObject,true).onClick = function ( ... )
            -- self.view.ScrollView.item:SetActive(tr);
            -- self.view.ScrollView.item:SetActive(false);
            -- ERROR_LOG(string.sub( tostring(value.data.cfg.info), 2 ));
            self.view.ScrollView.item.tip.Text[UI.Text].text = value.data.cfg.info
            -- self.view.ScrollView.item.tip.Text[UI.Text]
            local height = self.view.ScrollView.item.tip.Text[UI.Text].preferredHeight;
            local width = self.view.ScrollView.item.tip.Text[UI.Text].preferredWidth;
            
			print(height,"===========",width);
			self.view.ScrollView.item.tip[UnityEngine.RectTransform].sizeDelta = UnityEngine.Vector2(self.view.ScrollView.item.tip.Text[UnityEngine.RectTransform].sizeDelta.x+25,height+30)
                
            self.view.ScrollView.item:SetActive(view.Image[UI.Toggle].isOn);
            
            -- value.data.cfg.info
        end
        -- view.Image
        value:InitObj(view);

        view:SetActive(true);
    end

    
end

function View:listEvent()
    return {
        "HERO_BUFF_CHANGE",
    }
end

function View:onEvent( event,data )
    if event == "HERO_BUFF_CHANGE" then
        self:InitData();
    end
end


return View