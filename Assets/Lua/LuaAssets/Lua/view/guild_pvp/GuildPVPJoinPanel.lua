-- 公会战报名
--0 报名
--1 检查数据
--2 开始
--3 发放奖励
--4 结束
local Time = require "module.Time"
local unionConfig = require "config.unionConfig"
local GuildPVPGroupModule = require "guild.pvp.module.group"

local GuildPVPJoinPanel = {};

local function isAlreadyJoined()
    local guild = module.unionModule.Manage:GetSelfUnion();
    if guild == nil then
        return false;
    end

    local list = GuildPVPGroupModule.GetGuildList();
    for _, v in ipairs(list) do
        if v.id == guild.id then
            return true
        end
    end
    return false;
end

function GuildPVPJoinPanel:Start(ctx)
    GuildPVPGroupModule.QueryReport();
    GuildPVPGroupModule.QueryHeros();
    
    self.view = SGK.UIReference.Setup(self.gameObject);
    local init_obj = CS.UnityEngine.GameObject.Instantiate(SGK.ResourcesManager.Load("prefabs/base/CurrencyChat.prefab"), self.view.transform);
    self.updateTime = 0;
    CS.UGUIClickEventListener.Get(self.view.History.gameObject).onClick = function()
        --上期榜单
        local guilds = GuildPVPGroupModule.GetGroundGuildList()
        if guilds == nil or #guilds == 0 then
            showDlgError(nil, "暂无上期榜单，无法查看")
            return;
        end
        DialogStack.Push("guild_pvp/GuildPVPHistorical")
    end

    CS.UGUIClickEventListener.Get(self.view.Report.gameObject).onClick = function()
        local guilds = GuildPVPGroupModule.GetGroundGuildList();
        if guilds == nil or #guilds == 0 then
            return showDlgError(nil,"暂无战报记录")
        end
        DialogStack.Push("guild_pvp/GuildPVPReportPanel")
    end

    CS.UGUIClickEventListener.Get(self.view.close.gameObject).onClick = function()
        DialogStack.Pop();
    end
    -- CS.UGUIClickEventListener.Get(self.view.close.gameObject).onClick = function()
    --     DialogStack.Pop();
    -- end
    if not isAlreadyJoined() then
        self.view.Schedule:SetActive(false)
    else
        self.view.Schedule:SetActive(true)
    end
    CS.UGUIClickEventListener.Get(self.view.Schedule.gameObject).onClick = function()
        local guilds = GuildPVPGroupModule.GetGroundGuildList();
        if guilds == nil or #guilds == 0 then
            return showDlgError(nil,"暂无战报记录")
        end
        DialogStack.Push("guild_pvp/GuildPVPReportPanel")
    end

    self:UpdatePVPStatus();
    self:updateStartTime();
    self:updateGuildList();
end



function GuildPVPJoinPanel:UpdateGuildInfo(index, obj)
    if index < 1 or index > #self.guilds then
        return;
    end

    obj = obj or self.view.List[CS.UIMultiScroller]:GetItem(index-1);
    if not obj then
        return
    end

    local _view = SGK.UIReference.Setup(obj)
    -- local guild = module.unionModule.Manage:GetUnion(self.guilds[index].id);
    local guild = utils.Container("UNION"):Get(self.guilds[index].id);

    if guild then
        _view.Name[UnityEngine.UI.Text].text = guild.unionName
        _view.Level:TextFormat("Lv {0}", guild.unionLevel)
        _view.Num[UnityEngine.UI.Text]:TextFormat("{0}/{1}", guild.mcount, unionConfig.GetNumber(guild.unionLevel).MaxNumber + guild.memberBuyCount)
        _view.Power[UnityEngine.UI.Text].text = tostring(guild.rank)
    else
        _view.Name[UnityEngine.UI.Text].text  = 'loading...';
        _view.Level[UnityEngine.UI.Text].text = ''
        _view.Power[UnityEngine.UI.Text].text = '';
    end
end

function GuildPVPJoinPanel:reloadData(index)
    if index then
        self:UpdateGuildInfo(index);
    else
        self:updateGuildList();
    end
end



local function canSignup()
    local status, _ = GuildPVPGroupModule.GetStatus();
    if status ~= 0 then
        return false, "报名已结束";
    end
    local guild = module.unionModule.Manage:GetSelfUnion()
    if guild == nil then
        return false, "您还没有加入公会";
    end
    if isAlreadyJoined() then
        return false, "您的公会已经参加了本次公会战";
    end
    local memberInfo = module.unionModule.Manage:GetSelfInfo()
    if memberInfo == nil or (memberInfo.title ~= 1 and memberInfo.title ~= 2) then
        return false, "只有会长和副会长可报名"
    end
    if guild.unionLevel < GuildPVPGroupModule.signupLevel then
        return false, "公会等级不足"
    end
    if guild.mcount < GuildPVPGroupModule.signupCount then
        return false, "公会人员不足"
    end
    if module.ItemModule.GetItemCount(90002) < 100000 then
        return false, "银币不足"
    end

    return true, nil;
end

function GuildPVPJoinPanel:UpdatePVPStatus()
    --  print("报名资格", canSignup())
      local status, _ = GuildPVPGroupModule.GetStatus();
    --  ERROR_LOG("join status------>>",status)
      if status == 0 then
          self.view.Report.Text:TextFormat("上期赛程");
          self.view.Title.Text[UI.Text].text="比赛报名中！"
          if isAlreadyJoined() then
             -- self.view.Join.Text:TextFormat("已报名");
              self.view.apply:SetActive(true)
              self.view.Join:SetActive(false);
              self.view.Report:SetActive(true)
              self.view.History:SetActive(true)
              self.view.Schedule:SetActive(false)
            
              -- CS.UGUIClickEventListener.Get(self.view.Join.gameObject).onClick = function()
              --     local teamInfo = module.TeamModule.GetTeamInfo();
              --     if SceneStack.GetBattleStatus() then
              --         showDlgError(nil, "战斗内无法进行该操作")
              --     elseif teamInfo.id > 0 then
              --         showDlgError(nil, "组队状态无法进行该操作")
              --     else
              --         showDlgError(nil, "公会已报名")
              --         --SceneStack.Push("GuildPVPPreparation", "view/guild_pvp/GuildPVPPreparation.lua");
              --     end
              -- end
  
          else
              --self.view.Join.Text:TextFormat("报名");
              self.view.Join:SetActive(true);
              self.view.apply:SetActive(false)
              self.view.Report:SetActive(true)
              self.view.History:SetActive(true)
              self.view.Schedule:SetActive(false)
             
              self.view.Join.coin.bg[UI.Image]:LoadSprite("icon/".."90002_small")
              self.view.Join.coin.Text[UI.Text].text=100000
              CS.UGUIClickEventListener.Get(self.view.Join.gameObject).onClick = function()
                  local canSign, error = canSignup();
                  if not canSign then
                      return showDlgError(nil, error);
                  end
                      showDlg(nil,"报名参加公会战需要消耗 100000 银币",function()
                      GuildPVPGroupModule.Join();
                  end, function() end)
              end
          end
        elseif status == 1 then
          --self.view.Report.Text:TextFormat("本期战报");
          self.view.Title.Text[UI.Text].text="战斗准备中！"
  
          if isAlreadyJoined() then
              self.view.Join:SetActive(false);
              self.view.Report:SetActive(false)
              self.view.History:SetActive(false)
              self.view.Schedule:SetActive(true)
              self.view.apply:SetActive(true)
              self.view.apply[CS.UGUISpriteSelector].index=0
             -- self.view.Join.Text:TextFormat("进入战场");
              --self.view.Join:SetActive(false);
  
              -- CS.UGUIClickEventListener.Get(self.view.Join.gameObject).onClick = function()
              --     local teamInfo = module.TeamModule.GetTeamInfo();
              --     if SceneStack.GetBattleStatus() then
              --         showDlgError(nil, "战斗内无法进行该操作")
              --     elseif teamInfo.id > 0 then
              --         showDlgError(nil, "组队状态无法进行该操作")
              --     else
              --         SceneStack.Push("GuildPVPPreparation", "view/guild_pvp/GuildPVPPreparation.lua");
              --     end
              -- end
  
          else
              --self.view.Join:SetActive(false);
              -- self.view.Join[UI.Image].material=SGK.QualityConfig.GetInstance().grayMaterial
              -- self.view.Join[UI.Image].raycastTarget=false
              self.view.Join:SetActive(false);
              self.view.Report:SetActive(false)
              self.view.History:SetActive(false)
              self.view.Schedule:SetActive(true)
              self.view.apply:SetActive(true)
              self.view.apply[CS.UGUISpriteSelector].index=1
          end
        elseif status==2 then
            self.view.Title.Text[UI.Text].text="战斗进行中！"
            if  isAlreadyJoined() then
              self.view.Join:SetActive(false);
              self.view.Report:SetActive(false)
              self.view.History:SetActive(false)
              self.view.Schedule:SetActive(true)
              self.view.apply:SetActive(true)
              self.view.apply[CS.UGUISpriteSelector].index=0
            else
              self.view.Join:SetActive(false);
              self.view.Report:SetActive(false)
              self.view.History:SetActive(false)
              self.view.Schedule:SetActive(true)
              self.view.apply:SetActive(true)
              self.view.apply[CS.UGUISpriteSelector].index=1
            end
        elseif status==4 or status==3 then
            self.view.Title.Text[UI.Text].text="战斗结束！"
            if  isAlreadyJoined() then
                self.view.Join:SetActive(false);
                self.view.Report:SetActive(false)
                self.view.History:SetActive(false)
                self.view.Schedule:SetActive(true)
                self.view.apply:SetActive(false)
            else
              self.view.Join:SetActive(false);
              self.view.Report:SetActive(false)
              self.view.History:SetActive(false)
              self.view.Schedule:SetActive(true)
              self.view.apply:SetActive(true)
              self.view.apply[CS.UGUISpriteSelector].index=1
            end
      end
  end

function GuildPVPJoinPanel:updateStartTime()
    local t = GuildPVPGroupModule.GetNextBattleTime();
    if t then
        local s_time= os.date("*t",t.begin_time)

        local info = SGK.Localize:getInstance():getValue("guild_pvp_info2")
        self.view.Notice:TextFormat(info.."\n本次比赛将在"..s_time.year.."年"..s_time.month.."月"..s_time.day.."日"..(s_time.hour or 0).."点"..(s_time.min or 0).."分开始")
    end

end

function GuildPVPJoinPanel:updateGuildList()
    local guildList = GuildPVPGroupModule.GetGuildList() or {};

    self.guilds = {};
    for _, v in ipairs(guildList) do
        table.insert(self.guilds, v);
    end

    self.view.List[CS.UIMultiScroller].RefreshIconCallback = function (obj,idx)    
        self:UpdateGuildInfo(idx+1, obj)
        obj:SetActive(true)
    end
  --  print("数据", sprinttb(self.guilds))
    self.view.List[CS.UIMultiScroller].DataCount = #self.guilds;
end

function GuildPVPJoinPanel:Update( ... )
    if self.updateTime and Time.now() - self.updateTime >= 1 then
        self.updateTime = Time.now();
        local time = GuildPVPGroupModule.GetNextBattleTime()
        if time and time.begin_time then
            local status, fight_status = GuildPVPGroupModule.GetStatus();
            -- print("状态", status, GuildPVPGroupModule.GetLeftTime(true), time.prepare_time - Time.now(), time.begin_time - Time.now(), time.check_time - Time.now())
            local minOrder = GuildPVPGroupModule.GetMinOrder()
            --print("状态", status, fight_status, minOrder, GuildPVPGroupModule.GetLeftTime(true))
            if status == 0 then
                self.view.logArea[1].desc:TextFormat("报名时间还剩: {0}",self:TimeRef(GuildPVPGroupModule.GetLeftTime()));
            elseif status == 1 then
                self.view.logArea[1].desc:TextFormat("比赛准备时间还剩: {0}",self:TimeRef(GuildPVPGroupModule.GetLeftTime()));
            elseif status == 2 then 
                self.view.logArea[1].desc:TextFormat("比赛进行中")
            else
                self.view.logArea[1].desc:TextFormat("本次比赛已结束")
            end
            if status == 4 and GuildPVPGroupModule.GetLeftTime(true) <= 0 then
                GuildPVPGroupModule.QueryReport();
            end
            if status == 0 and not self.view.History.activeSelf then
                --self.view.History:SetActive(true);
                self.view.History[UI.Image].material=nil
                self.view.History[UI.Image].raycastTarget=true
            elseif status ~= 0 and self.view.History.activeSelf then
               -- self.view.History:SetActive(false);
                self.view.History[UI.Image].material=SGK.QualityConfig.GetInstance().grayMaterial
                self.view.History[UI.Image].raycastTarget=false
            end
        end
    end
end

function GuildPVPJoinPanel:TimeRef(endTime)
    local timeCD = "00:00:00" 
    if endTime then
        if endTime > 86400 then
            timeCD = math.floor(endTime/86400).."天"
        else
            timeCD = GetTimeFormat(endTime, 2)
        end
    end
    return timeCD
end

function GuildPVPJoinPanel:listEvent()
    return {
        "GUILD_PVP_GUILD_LIST_CHANGE",
        "GUILD_PVP_JOIN_STATUS_CHANGE",
        "CONTAINER_UNION_INFO_CHANGE",
    };
end

function GuildPVPJoinPanel:onEvent(event, ...)
    if event == "GUILD_PVP_GUILD_LIST_CHANGE" then
        self:updateGuildList();
        self:updateStartTime();
        self:UpdatePVPStatus();
    elseif event == "GUILD_PVP_JOIN_STATUS_CHANGE" then
        -- local errno = select(1, ...);
        -- if errno == 0 then
        --     showDlgError(nil,"@str/guild/pvp/join_success");
        -- elseif errno == 815 then
        --     showDlgError(nil,"@str/guild/pvp/already_joined");
        -- else
        --     showDlgError(nil,"@str/opt_error");
        -- end
        self:UpdatePVPStatus();
    elseif event == "CONTAINER_UNION_INFO_CHANGE" then
        local id = select(1, ...);
     --   print("CONTAINER_UNION_INFO_CHANGE", id);
        if id and self.guilds then
            for idx, v in ipairs(self.guilds) do
                if v.id == id then
                    self:reloadData(idx);
                end
            end
        end
    end
end


return GuildPVPJoinPanel;
