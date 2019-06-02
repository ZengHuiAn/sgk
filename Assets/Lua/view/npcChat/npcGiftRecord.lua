

local View = {}
function View:Start(data)
	self.view = SGK.UIReference.Setup(self.gameObject);
	self.Data=data
	CS.UGUIClickEventListener.Get(self.view.log.BG.gameObject).onClick = function ()
        DialogStack.Pop()
    end
    CS.UGUIClickEventListener.Get(self.view.log.title.close.gameObject).onClick = function ()
        DialogStack.Pop()
    end
    self:initCount(data.id)
end
local function get_timezone()
    local now = os.time()
    return os.difftime(now, os.time(os.date("!*t", now)))/3600
end

local function date(now)
    local now = now or module.Time.now();
    return os.date ("!*t", now + 8 * 3600);
end

local function getTimeByDate(year,month,day,hour,min,sec)

   local east8 = os.time({year = year, month = month, day = day, hour = hour, min = min, sec = sec})+ (get_timezone()-8) * 3600
   return east8
end

function View:initCount(npc_id)
	self.allRecord = module.NPCModule.GetNPClikingList(self.Data.id)
	self:InitScollview()
end

function View:InitScollview()
	self.view.log.logView[CS.UIMultiScroller].RefreshIconCallback = function (go,idx)
		local _View = CS.SGK.UIReference.Setup(go)
		local time_t = date(self.allRecord[idx+1].time)
		if tonumber(time_t.min) < 10 then
			_View[CS.InlineText].text=time_t.month.."月"..time_t.day.."日"..time_t.hour..":0"..time_t.min.."  "..self.allRecord[idx+1].desc
		else
			_View[CS.InlineText].text=time_t.month.."月"..time_t.day.."日"..time_t.hour..":"..time_t.min.."  "..self.allRecord[idx+1].desc
		end
		-- _View.desc[CS.InlineText].text=self.allRecord[idx+1].desc
		_View.gameObject:SetActive(true)
	end
	if self.allRecord then
		self.view.log.logView[CS.UIMultiScroller].DataCount=#self.allRecord
		self.view.log.logView[CS.UIMultiScroller]:ScrollMove(#self.allRecord-1)
	else
		self.view.log.logView[CS.UIMultiScroller].DataCount=0
	end
end

function View:OnDestory()

end

function View:listEvent()
    return {
    }
end

function View:onEvent(event,data)

end


return View;