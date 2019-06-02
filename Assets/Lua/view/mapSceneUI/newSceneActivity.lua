local activityConfig = require "config.activityConfig"
local DialogCfg = require "config.DialogConfig"
local MapConfig = require "config.MapConfig"
local Time = require "module.Time"
local view = {}
function view:Start(data)

    
    


   -- ERROR_LOG("ding--->>",sprinttb(data))
    if data then
      self.id=data.id or 1002
    else
        return
    end
    self._ActivetyList={}
    self:initUI()
    self:upMiddle(self.id)

end
function view:initUI()
    self.view = CS.SGK.UIReference.Setup(self.gameObject)
end

function view:getActivityTime(cfg)
    local total_pass = module.Time.now() - cfg.begin_time
    local period_pass = math.floor(total_pass % cfg.period)
    local period_begin = 0;
    if period_pass >= cfg.loop_duration then
        period_begin = cfg.begin_time + math.ceil(total_pass / cfg.period) * cfg.period
    else
        period_begin = cfg.begin_time + math.floor(total_pass / cfg.period) * cfg.period
    end
    return period_begin
end

function view:Update()
    if self._ActivetyList then
       for i,v in ipairs(self._ActivetyList) do
        v.object[UI.Text].text=self:upTime({_tab=v.tab,_object=v.object})
       -- ERROR_LOG("ding--->>>>>",v.object1.lockInfo.Text[UI.Text].text)
        if v.object1.lockInfo and v.object1.lockInfo.Text[UI.Text].text=="活动未开启" then
           v.object.lock:SetActive(true)
           v.object[UI.Text].text="<color=#FF0000FF>"..v.tab.activity_time.."开启".."</color>"
        else
           --v.object.lock:SetActive(false)
        end
       end
    end
end


function view:lockFunc(cfg,_activeCount)
    local _open = function(tabCfg)
        if tabCfg.lv_limit > module.HeroModule.GetManager():Get(11000).level then
            return true, {desc = SGK.Localize:getInstance():getValue("huodong_lv_01", cfg.lv_limit)}
        end
        if tabCfg.depend_quest_id ~= 0 then
            local _quest = module.QuestModule.GetCfg(tabCfg.depend_quest_id)
            if not _quest or _quest.status ~= 1 then
                if _quest then
                    return true, {desc = SGK.Localize:getInstance():getValue("huodong_lv_02", _quest.name)}
                end
            end
        end
        if cfg.advise_times ~= 0 then
            -- ERROR_LOG("_activeCount.countTen------------ding",_activeCount.countTen)
            -- ERROR_LOG(" _activeCount.countTen", _activeCount.countTen)
            -- ERROR_LOG(" _activeCount._activeCouunt", sprinttb(_activeCount))
            if ((_activeCount.countTen + _activeCount.countTen) <=0) or _activeCount.activeCouunt >0 then
                return true, {desc = SGK.Localize:getInstance():getValue("huosong_wancheng_01")}--已完成
            end
        end
        if tabCfg.begin_time > 0 and tabCfg.end_time > 0 and tabCfg.period > 0 and tabCfg.loop_duration then
            if not activityConfig.CheckActivityOpen(tabCfg.id) then
                return false, {desc = SGK.Localize:getInstance():getValue("common_weikaiqi")}
            else
                return true, {desc = os.date("%H:%M"..SGK.Localize:getInstance():getValue("common_kaiqi"), tabCfg.begin_time)}
            end
        end
        return false
    end

    if cfg and cfg.activity_group ~= 0 then
        local _list = activityConfig.GetCfgByGroup(cfg.activity_group)
        local _desc = ""
        local _timeList = {}
        for i,v in ipairs(_list) do
            local _op, _tab = _open(v)
            -- ERROR_LOG(v.id,_op,"v----->>>>",sprinttb(v))
            if _op then
              if self.activityList and i > 1 then
                for i1,v1 in ipairs(self.activityList) do
                  if v1.id == _list[1].id then
                    self.activityList[i1].begin_time = v.begin_time
                    self.activityList[i1].end_time = v.end_time
                    self.activityList[i1].loop_duration = 3600
                    break
                  end
                end
              end
              return true, {desc = _tab}
            end
        end
        return false, {desc = SGK.Localize:getInstance():getValue("common_weikaiqi")}
    elseif cfg then
        return _open(cfg)
    end
    return true
end

function view:upTime(tab)
    if not tab then
        return
    end
    local _tab=tab._tab
    local total_pass=Time.now()-_tab.begin_time
    local period_pass=total_pass - math.floor(total_pass / _tab.period) * _tab.period
    local period_begin=0
    if period_pass >= _tab.loop_duration then
      period_begin=_tab.begin_time +math.ceil(total_pass / _tab.period) * _tab.period
    else
      period_begin=_tab.begin_time +math.floor(total_pass / _tab.period ) *_tab.period
    end 
    local _offTime = period_begin -Time.now()
    if _offTime >0 then
        tab._object.lock:SetActive(true)
        --os.date("%H:%M开启",_tab.begin_time)
        return "<color=#FF0000FF>".._tab.activity_time.."开启".."</color>"
    else
        tab._object.lock:SetActive(false)
        local _endTime =_offTime + _tab.loop_duration
        if _endTime >0 then
           if _endTime >3600 then
             local hour=math.floor(_endTime/3600)
             local minute=math.floor((_endTime-hour*3600)/60)
             return  "剩余时间:"..hour.."时"..minute.."分" 
           else
             local minute=math.floor(_endTime/60)
             return  "剩余时间:".. minute.."分"
           end
        end
    end
end


function view:upMiddle(id)
      local _list = activityConfig.GetAllActivityTitle(1, id) or {} --——list是按钮相对的活动
      self.activityList={}   
      if true then
          local _tabList1={}
          local _tabList2={}
          for i,v in ipairs(_list) do
            local _activeCount = activityConfig.GetActiveCountById(v.id)--{countTen,count,joinLimit,maxCount,finishCount}
            local _Lock, _InfoTab = self:lockFunc(v,_activeCount)
            local _Text=nil
            if _InfoTab and _InfoTab.desc then
               _Text=_InfoTab.desc
            end
            --ERROR_LOG("_Text--->>",_Text)
            if _Text=="活动未开启" or module.HeroModule.GetManager():Get(11000).level <v.lv_limit or (v.advise_times~=0 and v.advise_times <= activityConfig.GetActiveCountById(v.id).finishCount) then
                table.insert(_tabList1 ,v)
            else
                table.insert(_tabList2 ,v)
            end
          end
  
          table.sort(_tabList1 , function(a,b)
              return b.activity_order>a.activity_order
          end)
          table.sort(_tabList2 , function(a,b)
              return b.activity_order>a.activity_order
          end)
  
          for i,v in ipairs(_tabList1) do
            table.insert(_tabList2 ,v)
          end
          self.activityList=_tabList2
         -- activityList=_list
          self.scrollView = self.view.root.middle.ScrollView[CS.UIMultiScroller]
          self.scrollView.RefreshIconCallback = function (obj, idx)
              local _view = CS.SGK.UIReference.Setup(obj)
              _view:SetActive(false)
              local _tab =self.activityList[idx+1]
              table.insert(self._ActivetyList,{tab=_tab,object=_view.icon.time,object1=_view})
              -- print(_tab.name,idx,self.scrollView.DataCount)
              _view[UI.Image]:LoadSprite(_tab.use_icon)

              local _activeCount = activityConfig.GetActiveCountById(_tab.id)--{countTen,count,joinLimit,maxCount,finishCount}
              local _lock, _infoTab = self:lockFunc(_tab,_activeCount)
              -- ERROR_LOG(_tab.name,"--->>",sprinttb(_infoTab))
              
              if  _tab.activity_order <=9 then
                  _view.gameObject.name=  "Scroll0".. _tab.activity_order
              else
                  _view.gameObject.name=  "Scroll".. _tab.activity_order
              end
              
              if _infoTab and _infoTab.desc then
                _view.icon.time:SetActive(true)
                _view.icon.time[UI.Text].text=_infoTab.desc
              else
                _view.icon.time:SetActive(true)
                --_view.icon.time[UI.Text].text=self:upTime(_tab)
              end
  
          --此处是倍率显示的剩余次数
          -- ERROR_LOG("倍率------->>>>",sprinttb(_activeCount))
          --if _activeCount.countTen>_activeCount.finishCount and _activeCount.countTen ~=0 then
            _view.icon.tip:SetActive(true)
            _view.icon.tip.severalfold:SetActive(true)
            local rate=nil
            if _tab.join_limit_double==3 then
                rate="三倍"
                _view.icon.tip.severalfold[UI.Image]:LoadSprite("icon/allActivity/huodong_16")
            elseif _tab.join_limit_double==2 then
                rate="双倍"
                _view.icon.tip.severalfold[UI.Image]:LoadSprite("icon/allActivity/huodong_06")
            elseif _tab.join_limit_double==10 then
                rate="十倍"
                _view.icon.tip.severalfold[UI.Image]:LoadSprite("icon/allActivity/huodong_07")
            else 
                rate=""
                _view.icon.tip.severalfold[UI.Image]:LoadSprite("icon/allActivity/huodong_015")
            end
           -- ERROR_LOG("join_limit=======>>>",_tab.join_limit)
            if _tab.join_limit == 999 then
                if _activeCount.countTen > 0 then
                    _view.icon.tip:SetActive(true)
                    _view.icon.number[UI.Text].text= rate.."奖励剩余".."<color=#F49C00FF>".._activeCount.countTen.."</color>".."次"
                elseif _activeCount.countOne >0  then
                --    _view.icon.tip:SetActive(false)
                    _view.icon.tip.severalfold[UI.Image]:LoadSprite("icon/allActivity/huodong_015")
                    _view.icon.number[UI.Text].text="进入次数剩余".."<color=#F49C00FF>".._activeCount.countOne.."</color>".."次"
                else
                --    _view.icon.tip:SetActive(false)
                    _view.icon.tip.severalfold[UI.Image]:LoadSprite("icon/allActivity/huodong_015")
                    _view.icon.number[UI.Text].text="无次数限制"
                end
            elseif _tab.join_limit == -1 then
                if _activeCount.countTen > 0 then
                    _view.icon.tip:SetActive(true)
                    _view.icon.number[UI.Text].text= rate.."奖励剩余".."<color=#F49C00FF>".._activeCount.countTen.."</color>".."次"
                elseif _activeCount.countOne >0  then
                --    _view.icon.tip:SetActive(false)
                    _view.icon.tip.severalfold[UI.Image]:LoadSprite("icon/allActivity/huodong_015")
                    _view.icon.number[UI.Text].text="进入次数剩余".."<color=#F49C00FF>".._activeCount.countOne.."</color>".."次"
                else
                --    _view.icon.tip:SetActive(false)
                    _view.icon.tip.severalfold[UI.Image]:LoadSprite("icon/allActivity/huodong_015")
                    _view.icon.number[UI.Text].text="<color=#FF0000FF>".."本活动已无奖励".."</color>"
                end
            else 
                if _activeCount.countTen > 0 then
                    _view.icon.tip:SetActive(true)
                    _view.icon.number[UI.Text].text= rate.."奖励剩余".."<color=#F49C00FF>".._activeCount.countTen.."</color>".."次"
                elseif _activeCount.countOne >0  then
                --    _view.icon.tip:SetActive(false)
                    _view.icon.tip.severalfold[UI.Image]:LoadSprite("icon/allActivity/huodong_015")
                    _view.icon.number[UI.Text].text="进入次数剩余".."<color=#F49C00FF>".._activeCount.countOne.."</color>".."次"
                else 
                    _view.icon.tip:SetActive(false)
                    if _tab.name =="答题竞赛" or _tab.name == "趣味答题" then
                        if _tab.join_limit-_activeCount.activeCouunt>0 then
                            _view.icon.tip:SetActive(false)
                            _view.icon.tip.severalfold[UI.Image]:LoadSprite("icon/allActivity/huodong_015")
                            _view.icon.number[UI.Text].text="进入次数剩余".."<color=#F49C00FF>".._tab.join_limit-_activeCount.activeCouunt .."</color>".."次"
                         else
                --             _view.icon.tip:SetActive(false)
                            _view.icon.tip.severalfold[UI.Image]:LoadSprite("icon/allActivity/huodong_015")
                             _view.icon.number[UI.Text].text="<color=#FF0000FF>".."进入次数剩余".."0次".."</color>"
                         end
                    else
                        _view.icon.number[UI.Text].text="<color=#FF0000FF>".."进入次数剩余".."0次".."</color>"
                    end
                    
                end
            end

            CS.UGUIClickEventListener.Get(_view.gameObject).onClick=function()
                DispatchEvent("REFRESH_THE_TITLE", {isShown = true, tab=_tab})
            end 
            -- if _tab["reward_id"..1]==0 or not _tab["reward_id"..1] then
            --     _view.award:SetActive(false)
            -- else
            --     utils.IconFrameHelper.Create(_view.award, {id = _tab["reward_id"..1], type = _tab["reward_type"..1], count = _tab["reward_value"..1] or 0,showDetail = true})
            --     _view.award:SetActive(true)
            -- end

            if _tab.type ==1 then
              _view.icon.pattern[UI.Image]:LoadSprite("icon/allActivity/bg_hd_duoren")
            elseif _tab.type ==2 then
              _view.icon.pattern[UI.Image]:LoadSprite("icon/allActivity/bg_hd_duorenhd")
            elseif _tab.type ==3 then
              _view.icon.pattern[UI.Image]:LoadSprite("icon/allActivity/bg_hd_danren")
            elseif _tab.type ==4 then
              _view.icon.pattern[UI.Image]:LoadSprite("icon/allActivity/bg_hd_gonghuihuodong")
            elseif _tab.type ==5 then
              _view.icon.pattern[UI.Image]:LoadSprite("icon/allActivity/bg_hd_danrenjingji")
            else
              _view.icon.pattern[UI.Image]:LoadSprite("icon/allActivity/bg_hd_danren")
            end

            if  module.HeroModule.GetManager():Get(11000).level <_tab.lv_limit   then
              _view.icon.time:SetActive(false)
              _view.lockInfo:SetActive(true)

              -- _view.icon:SetActive(false)
              -- _view.award:SetActive(false)
              -- _view[UI.Image].raycastTarget=false
              _view.lockInfo[UI.Image].raycastTarget=false
              _view.lockInfo.Text[UI.Text].raycastTarget=false

              _view.lockInfo.Text[UI.Text].text=SGK.Localize:getInstance():getValue("huodong_lv_01", _tab.lv_limit)
            elseif _tab.advise_times~=0 and _tab.advise_times <= _activeCount.finishCount then
              _view.icon.time:SetActive(false) 
              _view.lockInfo:SetActive(true)

              -- _view.icon:SetActive(false)
              -- _view.award:SetActive(false)
              -- _view[UI.Image].raycastTarget=false--按钮失效
              _view.lockInfo[UI.Image].raycastTarget=false
              _view.lockInfo.Text[UI.Text].raycastTarget=false
        
              _view.lockInfo.Text[UI.Text].text=SGK.Localize:getInstance():getValue("huosong_wancheng_01")
            else 
                _view[UI.Image].raycastTarget=true
                _view.lockInfo[UI.Image].raycastTarget=true
                _view.lockInfo.Text[UI.Text].raycastTarget=true
                _view.lockInfo:SetActive(false)
            end
            if _view.icon.time[UI.Text].text and _view.icon.time[UI.Text].text=="活动未开启" then
                _view.icon.time:SetActive(true)
                _view.lockInfo:SetActive(true)

                -- _view.icon:SetActive(false)
                -- _view.award:SetActive(false)
                -- _view[UI.Image].raycastTarget=false
                _view.lockInfo[UI.Image].raycastTarget=false
                _view.lockInfo.Text[UI.Text].raycastTarget=false

                _view.lockInfo.Text[UI.Text].text="活动未开启"
            else
            end
           self:ItemAnim(_view,idx)
        end
          self.scrollView.DataCount = #self.activityList
      else
      end 
 end

 function view:listEvent( ... )
	return {
	"LOCAL_GUIDE_OPT_ACTIVITY",
   }
end

function view:onEvent(event, data)
    if event=="LOCAL_GUIDE_OPT_ACTIVITY" then
        local count = nil
        for i,v in ipairs(self.activityList) do
           if v.id == tonumber(data[1]) then
            --self.view.root.middle.ScrollView.Viewport.Content[UnityEngine.RectTransform].anchoredPosition = UnityEngine.Vector2(0, 465);
            --ERROR_LOG("name--------->>>>",self.view.root.middle.ScrollView.Viewport.Content.transform:GetChild(i))
            self.view.root.middle.ScrollView.Viewport.Content.transform:DOLocalMove(Vector3(0, 465, 0), 0.5):SetRelative(true);
           end
        end
    end
end

function view:ItemAnim(view,idx)
	--print(idx)
        view.transform:DOLocalMoveX(300,0.1):OnComplete(function ()
            view:SetActive(true)
		    view.transform:DOLocalMoveX(25,0.5):OnComplete(function ()
                
		    end)
        end):SetDelay(idx*0.05) 
end
return view
