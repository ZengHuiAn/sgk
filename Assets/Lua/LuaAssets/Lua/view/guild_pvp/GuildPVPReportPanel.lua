local GuildPVPGroupModule = require "guild.pvp.module.group"
local GuildPVPRoomModule = require "guild.pvp.module.room"
local Time = require "module.Time"
local View = {};

local function _T(...)
    return ...;
end

local function _F(...)
    return string.format(...);
end

local function fingGroupByGID(gid)
    for i = 1, 4 do
        local info = GuildPVPGroupModule.GetGroundByGroup(i);
        if info then
            for x = 1, 2 do
                for y = 1, 2 do
                    for z = 1, 2 do
                        if info[x][y][z].guild.id == gid then
                            return i;
                        end
                    end
                end
            end
        end
    end
end

function View:Start(ctx)

    self.lastPage=SceneStack.savedValues.FormationLastPage and SceneStack.savedValues.FormationLastPage or 0
    
    GuildPVPGroupModule.QueryReport();
    
    local this = self;

    self.savedValue = self.savedValue or {};
    local savedValue = self.savedValue;

    self.view = SGK.UIReference.Setup(self.gameObject);

    self.show_top_4 = self.show_top_4 or false;
    self.show_top_3 = self.show_top_3 or false;
    self.updateTime = 0;
    self.selfUnion = false;

    if self.show_top_4 then
        self.view.Toggle.Tab2[UnityEngine.UI.Toggle].isOn = true;
    elseif self.show_top_3 then
        self.view.Toggle.Tab3[UnityEngine.UI.Toggle].isOn = true;
    else
        self.view.Toggle.Tab1[UnityEngine.UI.Toggle].isOn = true;
    end

        self.view.Toggle.Tab1.Image:SetActive(true)
        module.RedDotModule.PlayRedAnim(self.view.Toggle.Tab1.Image)

    --存储数据
    if self.lastPage ==1 then
        self.view.Toggle.Tab1[UnityEngine.UI.Toggle].isOn = true;
        self.show_top_4 = false;
        self.show_top_3 = false;
        self.view.CallBtn:SetActive(false);
        self.view.CallDesc:SetActive(false);

        self.view.Toggle.Tab3.Image:SetActive(false)
        self.view.Toggle.Tab2.Image:SetActive(false)
        self.view.Toggle.Tab1.Image:SetActive(true)
        module.RedDotModule.PlayRedAnim(self.view.Toggle.Tab1.Image)
        self:updateGroupInfo();
    elseif self.lastPage==2 then
        self.view.Toggle.Tab2[UnityEngine.UI.Toggle].isOn = true;
        self.view.win:SetActive(false)
        self.show_top_4 = true;
        self.show_top_3 = false;
        self.view.CallBtn:SetActive(false);
        self.view.CallDesc:SetActive(false);

        self.view.Toggle.Tab3.Image:SetActive(false)
        self.view.Toggle.Tab1.Image:SetActive(false)
        self.view.Toggle.Tab2.Image:SetActive(true)
        module.RedDotModule.PlayRedAnim(self.view.Toggle.Tab2.Image)
        self:updateTop4Info();
    elseif self.lastPage==3 then
        self.view.Toggle.Tab3[UnityEngine.UI.Toggle].isOn = true;
        self.view.win:SetActive(false)
        self.show_top_3 = true;
        self.show_top_4 = true;
        self.view.CallBtn:SetActive(false);
        self.view.CallDesc:SetActive(false);
        
        self.view.Toggle.Tab1.Image:SetActive(false)
        self.view.Toggle.Tab2.Image:SetActive(false)
        self.view.Toggle.Tab3.Image:SetActive(true)
         module.RedDotModule.PlayRedAnim(self.view.Toggle.Tab3.Image)
         self:updateTop4Info();
    end

    CS.UGUIClickEventListener.Get(self.view.Toggle.Tab1.gameObject).onClick = function()
        
        
        SceneStack.savedValues.FormationLastPage=1

        self.show_top_4 = false;
        self.show_top_3 = false;
        self.view.CallBtn:SetActive(false);
        self.view.CallDesc:SetActive(false);

        self.view.Toggle.Tab3.Image:SetActive(false)
        self.view.Toggle.Tab2.Image:SetActive(false)
        self.view.Toggle.Tab1.Image:SetActive(true)
        module.RedDotModule.PlayRedAnim(self.view.Toggle.Tab1.Image)
        self:updateGroupInfo();
    end

    CS.UGUIClickEventListener.Get(self.view.Toggle.Tab2.gameObject).onClick = function()

        SceneStack.savedValues.FormationLastPage=2

        self.view.win:SetActive(false)
        self.show_top_4 = true;
        self.show_top_3 = false;
        self.view.CallBtn:SetActive(false);
        self.view.CallDesc:SetActive(false);

        self.view.Toggle.Tab3.Image:SetActive(false)
        self.view.Toggle.Tab1.Image:SetActive(false)
        self.view.Toggle.Tab2.Image:SetActive(true)
        module.RedDotModule.PlayRedAnim(self.view.Toggle.Tab2.Image)
        self:updateTop4Info();
    end

    CS.UGUIClickEventListener.Get(self.view.Toggle.Tab3.gameObject).onClick = function()

        SceneStack.savedValues.FormationLastPage=3

        self.view.win:SetActive(false)
        self.show_top_3 = true;
        self.show_top_4 = true;
        self.view.CallBtn:SetActive(false);
        self.view.CallDesc:SetActive(false);
        
        self.view.Toggle.Tab1.Image:SetActive(false)
        self.view.Toggle.Tab2.Image:SetActive(false)
        self.view.Toggle.Tab3.Image:SetActive(true)
         module.RedDotModule.PlayRedAnim(self.view.Toggle.Tab3.Image)
         self:updateTop4Info();
     end


    local index = (ctx and ctx.index) or savedValue.index or nil;
    self.index = index;

    if self.index == nil then
        self.index = 1;
        local guild = module.unionModule.Manage:GetSelfUnion();
        if guild then
            self.index = fingGroupByGID(guild.id) or 1;
        end
    end

    local toggles = {
        self.view.Content1.Head.Toggle1,
        self.view.Content1.Head.Toggle2,
        self.view.Content1.Head.Toggle3,
        self.view.Content1.Head.Toggle4,
    }

    for i, t in ipairs(toggles) do
        if i == self.index then
            t[UnityEngine.UI.Toggle].isOn = true;
        end

        CS.UGUIClickEventListener.Get(t.gameObject).onClick = function()
            self.index = i;
            self:updateGroupInfo();
        end
    end

    if not savedValue.isInBattle then
        GuildPVPGroupModule.Enter();
        savedValue.isInBattle = true;
    end
    CS.UGUIClickEventListener.Get(self.view.Info.gameObject).onClick = function()
    
    end

    CS.UGUIClickEventListener.Get(self.view.CallBtn.gameObject).onClick = function()
        if GuildPVPRoomModule.isInspired() then
            showDlgError(nil,"不能重复鼓舞");
            return
        end
        GuildPVPRoomModule.Inspire();
    end
    -- self.view.mask[CS.UGUIClickEventListener].onClick = function ( ... )
    --     DispatchEvent("GUILD_REPORT_CLOSE");
    --     DialogStack.Pop();
    -- end
    self.view.exitBtn[CS.UGUIClickEventListener].onClick = function ( ... )
        SceneStack.savedValues.FormationLastPage=0
        DialogStack.Pop();
        DispatchEvent("GUILD_REPORT_CLOSE");
    end

    self:updateGroupInfo();
    self:updateTop4Info();
    self:updateFightButtonEvent()

    self.listData = GuildPVPGroupModule.GetGroundGuildList()
	if self.listData then
        table.sort(self.listData,function (a,b)
            if a.order ~= b.order then
                return a.order < b.order;
            end
            return a.id < b.id;
        end)
    end
    -- self.Win={}
    -- if self.listData then
    --     for i,v in ipairs(self.listData) do
    --         local info = utils.Container("UNION"):Get(v.id);
    --         table.insert( self.Win,info)
    --     end
    -- end
end

function View:UpdateGuildInfo(view, gid, order, minOrder, maxOrder,idx)
--    ERROR_LOG("minOrder",minOrder)
    minOrder = minOrder or 4;
    maxOrder = maxOrder or 7;
    view.Tag:SetActive(false)

    
    -- local desc = "比赛尚未开始"
    -- if minOrder == 4 then
    --     desc = "季军比赛进行中"
    -- elseif minOrder == 2 then
    --     desc ="冠军比赛进行中"
    -- elseif minOrder == 1  then
    --     desc = "比赛结束"
    -- end
--    print("刷新公会数据", gid, order, minOrder, maxOrder,idx)--order排名  minOrder状态
    if gid ~= 0 then
        view.bg.bg:SetActive(false)
        view.bg[UnityEngine.UI.Image].material=nil
        local info = utils.Container("UNION"):Get(gid);
--        ERROR_LOG("info.unionName",info.unionName)
        if info then
            local id =module.unionModule.Manage:GetUionId()
            view.isMe:SetActive(id == info.id)
            view.Name[UnityEngine.UI.Text].text = info.unionName
            view.Level[UnityEngine.UI.Text].text = 'Lv' .. info.unionLevel;
            if not self.show_top_3 and self.show_top_4 then
                if minOrder==4 then
                    view.Tag.BG:SetActive(false)
                else
                    if order==1 or order==2 then
                      view.Tag:SetActive(true)
                      view.Tag.BG:SetActive(true)
                      view.bg.bg:SetActive(false)
                    else
                      view.bg.bg:SetActive(true) 
                    end
                end
            elseif self.show_top_3 then
                if minOrder==2 then
                    view.Tag:SetActive(false)
                    view.bg.bg:SetActive(false)
                elseif minOrder==4  then
                    view.Name:TextFormat("无");
                    view.Level[UnityEngine.UI.Text].text = ''
                    view.isMe:SetActive(false)
                    view.bg.bg:SetActive(true)
                else  
                    if order==1 then
                        view.Tag:SetActive(true)
                        view.Tag.BG[CS.UGUISpriteSelector].index=0
                    elseif order==2 then
                        view.Tag:SetActive(true)
                        view.bg.bg:SetActive(true)
                        view.Tag.BG[CS.UGUISpriteSelector].index=1
                    elseif order==3 then
                        view.Tag:SetActive(true)
                        view.Tag.BG[CS.UGUISpriteSelector].index=2
                    elseif order==4 then
                        view.Tag:SetActive(true)
                        view.bg.bg:SetActive(true)
                        view.Tag.BG[CS.UGUISpriteSelector].index=3
                    end
                end
            else
                --第一页
            end
        end
    else
       -- view.bg[UnityEngine.UI.Image].material=SGK.QualityConfig.GetInstance().grayMaterial
        view.Name:TextFormat("无");
        view.Level[UnityEngine.UI.Text].text = ''
        view.isMe:SetActive(false)
        view.bg.bg:SetActive(true) 
    end
    -- if gid ~= 0 then
    --     view.bg.bg:SetActive(false)

    --     view.bg[UnityEngine.UI.Image].material=nil
    --     local info = utils.Container("UNION"):Get(gid);
    --     ERROR_LOG("info.unionName",info.unionName)
    --     if info then
    --         local id = module.unionModule.Manage:GetUionId()
    --         view.isMe:SetActive(id == info.id)
    --        -- print("info.unionName")
    --         view.Name[UnityEngine.UI.Text].text = info.unionName-- .. '(' .. order .. ')';
           
    --         if not self.show_top_3 and self.show_top_4 then
    --             local isWin = false
    --             for i=1,2 do
    --                 if  self.Win and self.Win[i].unionName == info.unionName then
    --                     -- ERROR_LOG("view  win------------>>>>",view.gameObject.name)
    --                     -- ERROR_LOG("name  win------------>>>>",info.unionName)
    --                     view.bg.bg:SetActive(false)
    --                     view.Tag:SetActive(true)
    --                     isWin=true  
    --                 end
    --             end
    --             if not isWin then
    --                 view.bg.bg:SetActive(true)
    --                 -- ERROR_LOG("view loser------------>>>>",view.gameObject.name)
    --                 -- ERROR_LOG("name loser------------>>>>",info.unionName)
    --             end

    --         elseif self.show_top_3 then
                
    --             if self.Win and self.Win[1].unionName ==info.unionName then
    --                 view.Tag:SetActive(true)
    --                 view.Tag.BG[CS.UGUISpriteSelector].index=0
    --             elseif self.Win and self.Win[2].unionName ==info.unionName then
    --                 view.Tag:SetActive(true)
    --                 view.Tag.BG[CS.UGUISpriteSelector].index=1
    --                 view.bg.bg:SetActive(true)
    --             elseif self.Win and self.Win[3].unionName ==info.unionName then
    --                 view.Tag:SetActive(true)
    --                 view.Tag.BG[CS.UGUISpriteSelector].index=2
    --             else
    --                 view.Tag:SetActive(true)
    --                 view.Tag.BG[CS.UGUISpriteSelector].index=3
    --                 view.bg.bg:SetActive(true)
    --             end
    --         end

    --         view.Level[UnityEngine.UI.Text].text = 'Lv' .. info.unionLevel;
    --     else
    --         view.Name[UnityEngine.UI.Text].text = 'loading...'
    --         view.Level[UnityEngine.UI.Text].text = ''
    --     end
    -- else
    --     view.bg[UnityEngine.UI.Image].material=SGK.QualityConfig.GetInstance().grayMaterial
    --     view.Name:TextFormat("无");
    --     view.Level[UnityEngine.UI.Text].text = ''
    --     view.isMe:SetActive(false)
    --     view.bg.bg:SetActive(true)
    -- end

    -- StartCoroutine(function()
    --     if SceneStack.savedValues.FormationLastPage==3 and obj ~=nil then
    --        for i=3,4 do
    --         if obj.Fight[i][CS.UGUISpriteSelector].index == 0 then
    --             view.bg[UnityEngine.UI.Image].material=SGK.QualityConfig.GetInstance().grayMaterial
    --             view.Name:TextFormat("无");
    --             view.Level[UnityEngine.UI.Text].text = ''
    --             view.isMe:SetActive(false)
    --             view.bg.bg:SetActive(true)
    --             view.Tag:SetActive(false)
    --         elseif obj.Fight[i][CS.UGUISpriteSelector].index == 1 then
    --             view.Tag:SetActive(false)
    --         else

    --         end
    --        end
    --     end
    -- end)
    
    
    if gid == 0 then
        view[CS.UGUISpriteSelector].index = 0;
    --elseif order <= minOrder and minOrder < maxOrder then
    elseif order <= minOrder and minOrder <= 4 then
        view[CS.UGUISpriteSelector].index = 2;
        if self.show_top_4 then
            -- view.Tag2:SetActive(true)
            -- view.Tag2[CS.UGUISelectorGroup].index = idx - 1
            -- self.view.win2.bg.name[UI.Text].text = view.Name[UI.Text].text
            -- self.view.win2:SetActive(true)
            self.view.win:SetActive(false)
        else
            self.view.win.bg.name[UI.Text].text = view.Name[UI.Text].text
            self.view.win:SetActive(true)
            --self.view.win2:SetActive(false)
        end
    else
        view[CS.UGUISpriteSelector].index = (gid > 0 and order <= maxOrder) and 1 or 0;
    end

    if minOrder == 1 then
        -- view.Tag2:SetActive(false)
        -- view.Tag:SetActive(true)
        --view.Tag[CS.UGUISelectorGroup].index = order - 1
    end
end

local roomStatusString = {
    "{1}将在<color=#ffd800>{0}</color>后开始",         --0未开始
    "打call棒领取时间还剩<color=#ffd800>{0}</color>",   --1准备
    "距离{1}结束还剩<color=#ffd800>{0}</color>",   --2战斗中
    "距离{1}开始还剩<color=#ffd800>{0}</color>",       --3战斗结束
    "距离{1}结束还剩<color=#ffd800>{0}</color>",       --4战斗结束
}

local FightStatusString = {
    [7] = "小组赛第一轮比赛",
    [6] = "小组赛第二轮比赛",
    [5] = "小组赛第三轮比赛",
    [4] = "半决赛",
    [3] = "半决赛",
    [2] = "决赛",
}

function  View:TimeRef(endTime)
    local timeCD = "00:00:00" 
    if endTime then
        local time = endTime
        timeCD = string.format("%02d",math.floor(math.floor(time/60)%60))..":"..string.format("%02d",math.floor(time%60))
    end
    return timeCD
end

function View:Update()
    if Time.now() - self.updateTime >= 1 then
        self.updateTime = Time.now();
        local status,fight_status = GuildPVPGroupModule.GetStatus();
        local isInspired = GuildPVPRoomModule.isInspired();
        self.view.CallBtn:SetActive(fight_status == 1 and self.selfUnion and not isInspired);
        self.view.CallDesc:SetActive(self.selfUnion and isInspired);
        local minOrder = GuildPVPGroupModule.GetMinOrder()
        local time = GuildPVPGroupModule.GetLeftTime(true);
        --print("状态", fight_status, minOrder, time);
        -- if fight_status == 3 then
        --     minOrder = minOrder + 1;
        -- end
        if minOrder == 1 then
            self.view.Desc1:TextFormat("比赛结束")
        elseif time >= 0 then
            self.view.Desc1:TextFormat(roomStatusString[fight_status+1], self:TimeRef(time), FightStatusString[minOrder])
        else
            self.view.Desc1[UnityEngine.UI.Text].text = "";
        end
    end
end

function View:updateGroupInfo()
    if self.show_top_4 then
        return;
    end

    local info = GuildPVPGroupModule.GetGroundByGroup(self.index);

    if info == nil then
        return nil;
    end

    local guild_slot_list = {
        [1] = {1, 1, 1},
        [2] = {1, 1, 2},
        [3] = {1, 2, 1},
        [4] = {1, 2, 2},
        [5] = {2, 1, 1},
        [6] = {2, 1, 2},
        [7] = {2, 2, 1},
        [8] = {2, 2, 2},
    }

    local line_list = {
        [1] = {[6] = self.view.Content1.Line.Line_1, [5] = self.view.Content1.Line.Line_1_2, [4] = self.view.Content1.Line.Line_12_34},
        [2] = {[6] = self.view.Content1.Line.Line_2, [5] = self.view.Content1.Line.Line_1_2, [4] = self.view.Content1.Line.Line_12_34},
        [3] = {[6] = self.view.Content1.Line.Line_3, [5] = self.view.Content1.Line.Line_3_4, [4] = self.view.Content1.Line.Line_12_34},
        [4] = {[6] = self.view.Content1.Line.Line_4, [5] = self.view.Content1.Line.Line_3_4, [4] = self.view.Content1.Line.Line_12_34},
        [5] = {[6] = self.view.Content1.Line.Line_5, [5] = self.view.Content1.Line.Line_5_6, [4] = self.view.Content1.Line.Line_56_78},
        [6] = {[6] = self.view.Content1.Line.Line_6, [5] = self.view.Content1.Line.Line_5_6, [4] = self.view.Content1.Line.Line_56_78},
        [7] = {[6] = self.view.Content1.Line.Line_7, [5] = self.view.Content1.Line.Line_7_8, [4] = self.view.Content1.Line.Line_56_78},
        [8] = {[6] = self.view.Content1.Line.Line_8, [5] = self.view.Content1.Line.Line_7_8, [4] = self.view.Content1.Line.Line_56_78},
    }
    
    for k, v in ipairs(line_list) do
        for i = 4, 6 do
            v[i][CS.UGUISelectorGroup].index = 0;
        end
    end

    local minOrder = GuildPVPGroupModule.GetMinOrder()
    local _minOrder = minOrder;
    if _minOrder < 4 then
        _minOrder = 4;
    end
    local isMe = false;
    --print("info", sprinttb(info))
    for k, v in ipairs(guild_slot_list) do
        local x, y, z = v[1], v[2], v[3];
        local c = info[x][y][z];
        if not isMe then
            local id = module.unionModule.Manage:GetUionId()
            isMe = c.guild.id == id;
        end
        self:UpdateGuildInfo(self.view.Content1.Guild[k], c.guild.id, c.guild.order, _minOrder, 7, self.index);
        --ERROR_LOG("---------->",c.guild.order,c.guild.id)
        if (c.guild.order <= 4 or c.guild.order <= GuildPVPGroupModule.GetMinOrder()) and c.guild.id ~= 0 then
            if c.guild.order <= 6 then
                line_list[k][6][CS.UGUISelectorGroup].index = 2;
                -- ERROR_LOG(line_list[k][6].gameObject, 2)
            end

            if c.guild.order <= 5 then
                line_list[k][5][CS.UGUISelectorGroup].index = 2;
                -- ERROR_LOG(line_list[k][5].gameObject, 2)
            end

            if c.guild.order <= 4 then
                line_list[k][4][CS.UGUISelectorGroup].index = 2;
                -- ERROR_LOG(line_list[k][4].gameObject, 2)
            end
        else
            for i = 6, c.guild.order, -1 do
                if c.guild.id > 0 and line_list[k][i][CS.UGUISelectorGroup].index ~= 2 then
                    line_list[k][i][CS.UGUISelectorGroup].index = 1;
                    -- ERROR_LOG(line_list[k][i].gameObject, 1)
                end
            end
        end
    end
    self.selfUnion = isMe;

    local Fight_list = {
        [7] = {[1] = self.view.Content1.Fight.Fight_1_2,[2] = self.view.Content1.Fight.Fight_3_4,[3] = self.view.Content1.Fight.Fight_5_6,[4] = self.view.Content1.Fight.Fight_7_8},
        [6] = {[1] = self.view.Content1.Fight.Fight_12_34,[2] = self.view.Content1.Fight.Fight_56_78},
        [5] = {[1] = self.view.Content1.Fight.Fight_1234_5678},
    }
    local status,fight_status = GuildPVPGroupModule.GetStatus();
   -- print("minOrder, status, fight_status",minOrder, status, fight_status)

    -- for k,v in pairs(Fight_list) do
    --     for i = 1,#v do
    --         v[i][CS.UGUISpriteSelector].index = 0;
    --     end
    -- end
    -- if status == 2 and Fight_list[minOrder] then
    --     if fight_status == 2 then
    --         for i = 1,#Fight_list[minOrder] do
    --             Fight_list[minOrder][i][CS.UGUISpriteSelector].index = 1;
    --         end
    --     elseif fight_status > 2 then
    --         for i = 1,#Fight_list[minOrder] do
    --             Fight_list[minOrder][i][CS.UGUISpriteSelector].index = 2;
    --         end
    --     end
    -- end

    local function setIndex(list, index)
        for i,v in ipairs(list) do
            v[CS.UGUISpriteSelector].index = index;
        end
    end

    for k,v in pairs(Fight_list) do
        if status < 2 then
            setIndex(v, 2)
        elseif status == 2 then
            if minOrder < k then
                setIndex(v, 2)
            elseif minOrder == k then
                if fight_status == 0 or fight_status == 3 then       --比赛未开始或上一场比赛未结束
                    setIndex(v, 0)
                elseif fight_status <= 2 then   --打call或者已经开始战斗
                    setIndex(v, 1)
                else
                    setIndex(v, 2)
                end
            else
                setIndex(v, 0)
            end
        else
            setIndex(v, 2)
        end
    end
end

function View:updateTop4Info()
    
    if not self.show_top_4 then
        return;
    end

	local info = GuildPVPGroupModule.GetGroundByGroup(0);
	if info == nil then
		return;
	end
  --  print("info", sprinttb(info))
	local minOrder = GuildPVPGroupModule.GetMinOrder();
  --  ERROR_LOG("minOrder---------------->>>>",minOrder)
    

    local desc = "比赛尚未开始"
    if minOrder == 4 then
        desc = "季军比赛进行中"
    elseif minOrder == 2 then
        desc ="冠军比赛进行中"
    elseif minOrder == 1  then
        desc = "比赛结束"
    end
    self.view.Content2.Tips[1]:TextFormat(desc)
    local isMe = false;
    if not self.show_top_3 then
        local guild_slot_list = {
            [1] = {1, 1},
            [2] = {1, 2},
    
            [3] = {2, 2},
            [4] = {2, 1},
        }
        local line_list = {
            -- [1] = {[4] = self.view.Content2.Line.Line_1,[2] = self.view.Content2.Line.Line_1_2},
            -- [2] = {[4] = self.view.Content2.Line.Line_3,[2] = self.view.Content2.Line.Line_3_4},
            -- [3] = {[4] = self.view.Content2.Line.Line_4,[2] = self.view.Content2.Line.Line_7_8},
            -- [4] = {[4] = self.view.Content2.Line.Line_2,[2] = self.view.Content2.Line.Line_5_6},

            [1]=self.view.Content2.Line.Line_1_2,
            [2]=self.view.Content2.Line.Line_3_4,
            [3]=self.view.Content2.Line.Line_7_8,
            [4]=self.view.Content2.Line.Line_5_6,

        }
        for k, v in ipairs(guild_slot_list) do
            local x, y = v[1], v[2];
            local c = info[x][y]; --{1,1}   {2.1}   {2,2}    {1,2}
        --    ERROR_LOG("info-------------------->>>",sprinttb(c))
            
            local key = k
           -- ERROR_LOG("minOrder------->>>>",minOrder)
            -- if minOrder == 1 then  --比赛结束
            --     key = c.guild.order;
            -- elseif minOrder == 2 then  --半决赛
            --     -- if k == 1 or k == 4 then
            --     --     if c.guild.order == 2 then
            --     --         key = 1
            --     --     end
            --     -- elseif k == 2 or k == 3 then
            --     --     if c.guild.order == 4 then
            --     --         key = 3
            --     --     end
            --     -- end
            --     if k == 1 and c.guild.order > 2 then        --第一组比赛失败者
            --         key = 4
            --     elseif k == 4 and c.guild.order <= 2 then   --第一组比赛胜利者
            --         key = 1
            --     elseif k == 2 and c.guild.order > 2 then    --第二组比赛失败者
            --         key = 3
            --     elseif k == 3 and c.guild.order <= 2 then   --第二组比赛胜利者
            --         key = 2
            --     end
            -- end
            -- ERROR_LOG("--------->", k, key, sprinttb(c))
    
            if not isMe then
                local id = module.unionModule.Manage:GetUionId()
                isMe = c.guild.id == id;
            end
           -- ERROR_LOG("key------------------->>>",key)
            self:UpdateGuildInfo(self.view.Content2.Guild[key], c.guild.id, c.guild.order, minOrder, 4,k);
            -- if minOrder <= 4 then
            --     if c.guild.order <= 4 or c.guild.order <= minOrder then
            --         line_list[key][2][CS.UGUISelectorGroup].index = 0
            --         line_list[key][4][CS.UGUISelectorGroup].index = 1
            --         if minOrder <= 2 then
            --             line_list[key][2][CS.UGUISelectorGroup].index = 1
            --         end
            --         if c.guild.order <= 1 then
            --             line_list[key][2][CS.UGUISelectorGroup].index = 2
            --         end
            --     end
            --     line_list[k][4]:SetActive(minOrder <= 4 and minOrder > 2)
            --     line_list[k][2]:SetActive(minOrder == 2)
            -- else
            --     line_list[k][4][CS.UGUISelectorGroup].index = 0
            --     line_list[k][2][CS.UGUISelectorGroup].index = 0
            --     line_list[k][4]:SetActive(false)
            --     line_list[k][2]:SetActive(false)
            -- end 
            -- if minOrder<=4 then
            --     if c.guild.order <= 4 then
            --         -- body
            --     end
            -- end
            if  minOrder == 4 then
                line_list[k][CS.UGUISelectorGroup].index =2
            else
                if c.guild.order==1 or c.guild.order ==2 then
                    line_list[k][CS.UGUISelectorGroup].index=1
                else
                    line_list[k][CS.UGUISelectorGroup].index=0
                end
            end
        end
    else
        local guild_slot_list = {
            [1] = {1, 1},
            [4] = {1, 2},
    
            [2] = {2, 1},
            [3] = {2, 2},
        }

        local line_list = {
            -- [1] = {[4] = self.view.Content2.Line.Line_1,[2] = self.view.Content2.Line.Line_1_2},
            -- [2] = {[4] = self.view.Content2.Line.Line_3,[2] = self.view.Content2.Line.Line_3_4},
            -- [3] = {[4] = self.view.Content2.Line.Line_4,[2] = self.view.Content2.Line.Line_7_8},
            -- [4] = {[4] = self.view.Content2.Line.Line_2,[2] = self.view.Content2.Line.Line_5_6},

            [1]=self.view.Content3.Line.Line_1_2,
            [3]=self.view.Content3.Line.Line_3_4,
            [4]=self.view.Content3.Line.Line_7_8,
            [2]=self.view.Content3.Line.Line_5_6,

        }

        for k, v in ipairs(guild_slot_list) do
            local x, y = v[1], v[2];
    
    
            local c = info[x][y]; --{1,1}   {2.1}   {2,2}    {1,2}
        --    ERROR_LOG("info-------------------->>>",sprinttb(c))
            --ERROR_LOG("--------->",x,y)
            local key = k
        --    ERROR_LOG("minOrder------->>>>",minOrder)
            if minOrder == 1 then  --比赛结束
                key = c.guild.order;
            elseif minOrder == 2 then  --半决赛
                -- if k == 1 or k == 4 then
                --     if c.guild.order == 2 then
                --         key = 1
                --     end
                -- elseif k == 2 or k == 3 then
                --     if c.guild.order == 4 then
                --         key = 3
                --     end
                -- end
                if k == 1 and c.guild.order > 2 then        --第一组比赛失败者
                    key = 4
                elseif k == 4 and c.guild.order <= 2 then   --第一组比赛胜利者
                    key = 1
                elseif k == 2 and c.guild.order > 2 then    --第二组比赛失败者
                    key = 3
                elseif k == 3 and c.guild.order <= 2 then   --第二组比赛胜利者
                    key = 2
                end
               -- ERROR_LOG("c.guild.order--------->>>>",c.guild.order)
            end
            -- ERROR_LOG("--------->", k, key, sprinttb(c))
    
            if not isMe then
                local id = module.unionModule.Manage:GetUionId()
                isMe = c.guild.id == id;
            end
            self:UpdateGuildInfo(self.view.Content3.Guild[key], c.guild.id, c.guild.order, minOrder, 4,k);
            if  minOrder == 2 then
                line_list[k][CS.UGUISelectorGroup].index =2
            else
                if c.guild.order==1 or c.guild.order ==3 then
                    line_list[k][CS.UGUISelectorGroup].index=1
                else
                    line_list[k][CS.UGUISelectorGroup].index=0
                end
            end 
        end
    end
    self.selfUnion = isMe;

    local Fight_list = {
        [4] = {[1] = self.view.Content2.Fight.Fight_1_2,[2] = self.view.Content2.Fight.Fight_3_4},
        [2] = {[1] = self.view.Content3.Fight.Fight_12_34,[2] = self.view.Content3.Fight.Fight_34_12},
    }
    local status,fight_status = GuildPVPGroupModule.GetStatus();
    --print("minOrder, status, fight_status",minOrder, status, fight_status)
    -- for i = 1,2 do
    --     Fight_list[2][i][CS.UGUISpriteSelector].index = 0;
    --     Fight_list[4][i][CS.UGUISpriteSelector].index = 0;
    -- end
    -- if status == 2 and Fight_list[minOrder] then
    --     if fight_status == 2 then
    --         for i = 1,2 do
    --             Fight_list[minOrder][i][CS.UGUISpriteSelector].index = 1;
    --         end
    --     elseif fight_status > 2 then
    --         for i = 1,2 do
    --             Fight_list[minOrder][i][CS.UGUISpriteSelector].index = 2;
    --         end
    --     end
    -- end

    local function setIndex(list, index)
        for i,v in ipairs(list) do
            v[CS.UGUISpriteSelector].index = index;
        end
    end

    for k,v in pairs(Fight_list) do
        if status < 2 then
            setIndex(v, 2)
        elseif status == 2 then
            if minOrder < k then
                setIndex(v, 2)
            elseif minOrder == k then
                if fight_status == 0 or fight_status == 3 then       --比赛未开始
                    setIndex(v, 0)
                elseif fight_status <= 2 then   --打call或者已经开始战斗
                    setIndex(v, 1)
                else
                    setIndex(v, 2)
                end
            else
                setIndex(v, 0)
            end
        else
            setIndex(v, 2)
        end
    end

end

function View:updateFightButtonEvent( ... )
    local battleFightID_1 = {
        ["Fight_1_2"]       = { 1, 2, 3, 4},
        ["Fight_3_4"]       = {16,15,14,13},
        ["Fight_5_6"]       = { 8, 7, 6, 5},
        ["Fight_7_8"]       = { 9,10,11,12},
        ["Fight_12_34"]     = {17,18,19,20},
        ["Fight_56_78"]     = {24,23,22,21},
        ["Fight_1234_5678"] = {33,34,35,36},
    };
    local battleFightID_1_minOrder = {
        ["Fight_1_2"]       = 7,
        ["Fight_3_4"]       = 7,
        ["Fight_5_6"]       = 7,
        ["Fight_7_8"]       = 7,
        ["Fight_12_34"]     = 6,
        ["Fight_56_78"]     = 6,
        ["Fight_1234_5678"] = 5,
    };
    for k, v in pairs(battleFightID_1) do
        CS.UGUIClickEventListener.Get(self.view.Content1.Fight[k].gameObject).onClick = function()
            if self.view.Content1.Fight[k][CS.UGUISpriteSelector].index == 0 then
                showDlgError(nil, "该比赛尚未开始")
            else
                local roomid = v[self.index];
                self:EnterFight(roomid,battleFightID_1_minOrder[k])
            end
        end
    end

    local battleFightID_2 = {
        ["Fight_1_2"]       = 49,
        ["Fight_3_4"]       = 50,
    --    ["Fight_12_34"]     = 65,
    --    ["Fight_34_12"]     = 67,
    };
    local battleFightID_2_minOrder = {
        ["Fight_1_2"]       = 4,
        ["Fight_3_4"]       = 4,
    --    ["Fight_12_34"]     = 2,
    --    ["Fight_34_12"]     = 2,
    };
    for k, v in pairs(battleFightID_2) do
        CS.UGUIClickEventListener.Get(self.view.Content2.Fight[k].gameObject).onClick = function()
            if self.view.Content2.Fight[k][CS.UGUISpriteSelector].index == 0 then
                showDlgError(nil, "该比赛尚未开始")
            else
                self:EnterFight(v,battleFightID_2_minOrder[k])
            end
        end
    end

    local battleFightID_3 = {
        --    ["Fight_1_2"]       = 49,
        --    ["Fight_3_4"]       = 50,
            ["Fight_12_34"]     = 65,
            ["Fight_34_12"]     = 67,
        };
        local battleFightID_3_minOrder = {
        --    ["Fight_1_2"]       = 4,
        --    ["Fight_3_4"]       = 4,
            ["Fight_12_34"]     = 2,
            ["Fight_34_12"]     = 2,
        };
        for k, v in pairs(battleFightID_3) do
            CS.UGUIClickEventListener.Get(self.view.Content3.Fight[k].gameObject).onClick = function()
                if self.view.Content3.Fight[k][CS.UGUISpriteSelector].index == 0 then
                    showDlgError(nil, "该比赛尚未开始")
                else
                    self:EnterFight(v,battleFightID_3_minOrder[k])
                end
            end
        end
end

function View:EnterFight(roomid,minOrder)
    if roomid == 67 then
		local info = GuildPVPGroupModule.GetFightByRoomId(65);
		for x = 1, 2 do
			for y = 1, 2 do
				if info[x][y].guild.id == 0 then
					return showDlgError(nil,"无战斗记录");
				end
			end
		end
    else
        local info = GuildPVPGroupModule.GetFightByRoomId(roomid);
        if info == nil or info[1].guild.id == 0 or info[2].guild.id == 0 then
            return showDlgError(nil, "无战斗记录");
        end
    end

    local info = GuildPVPGroupModule.GetFightByRoomId(roomid);
   -- print("数据", sprinttb(info)--[[ , sprinttb(info[1].guild), sprinttb(info[2].guild) ]])
    SceneStack.Push("GuildPVPRoom", "view/guild_pvp/GuildPVPRoomScene.lua", {room = roomid,minOrder = minOrder});
end

function View:listEvent()
    return {
        "GUILD_PVP_GROUND_CHANGE",
        "CONTAINER_UNION_INFO_CHANGE",
        "GUILD_PVP_GROUP_STATUS_CHANGE",
        "GUILD_PVP_INSPIRE_RESULT",
    };
end

function View:onEvent(event, ...)
    -- print("onEvent", event)
    if event == "GUILD_PVP_GROUND_CHANGE" then
        self:updateGroupInfo();
        self:updateTop4Info();
    elseif event == "CONTAINER_UNION_INFO_CHANGE" then
        self:updateGroupInfo();
        self:updateTop4Info();
    elseif event == "GUILD_PVP_GROUP_STATUS_CHANGE" then
        self:updateGroupInfo();
        self:updateTop4Info();
    elseif event == "GUILD_PVP_INSPIRE_RESULT" then
        local success = select(1, ...)
        if success then
            showDlgError(nil,"鼓舞成功");
        else
            showDlgError(nil,"鼓舞失败");
        end
    end
end

function View:onExit(ctx, savedValue)
  --  print("退出")
    savedValue.fromDule = (ctx and ctx.fromDule);
    savedValue.index = self.index;
end

function View:onSetting()
    local guild = GUILD.PlayerGuild();
    local find = false;

    if guild then
        local list = GuildPVPGroupModule.GetGuildList();
        for _, v in ipairs(list) do
            if v.id == guild.id then
                find = true;
            end
        end
    else
        return showDlgError(nil,"@str/error/guild/empty");
    end

    if not find then
        return showDlgError(nil,"@str/guild/pvp/not_joined");
    end

    if GuildPVPGroupModule.GetHero() then
        Application.SendNotify(Application.SWITCH_TO_SCENE, "GuildPVPSettingScene");
    else
       showDlgError(nil,"@str/loading");
    end
end
function View:OnDestroy()
	
end

return View;