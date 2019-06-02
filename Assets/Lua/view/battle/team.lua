local View = {}


function View:Start()
    self.view = SGK.UIReference.Setup(self.gameObject);

    SGK.ResourcesManager.LoadAsync(self.view[SGK.LuaBehaviour], "prefabs/effect/UI/fx_icon_jiantou.prefab", function(o)
        self.fx_icon_jiantou = o;
    end)
    SGK.ResourcesManager.LoadAsync(self.view[SGK.LuaBehaviour], "prefabs/effect/UI/fx_icon_jiantou_dark.prefab", function(o)
        self.fx_icon_jiantou_dark = o;
    end)
    SGK.ResourcesManager.LoadAsync(self.view[SGK.LuaBehaviour], "prefabs/effect/UI/fx_icon_jiantou_ready.prefab", function(o)
        self.fx_icon_jiantou_ready = o;
    end)
    
    self.prefab = self.view.Members.MemberPrefab;
    self.members = {};
    self.audioSource_list = {}
end

function View:RemoveMember(pid)
    for k, v in ipairs(self.members) do
        if v.pid == pid then
            UnityEngine.GameObject.Destroy(v.view);
            table.remove(self.members,k);
            return;
        end
    end
end

local Local_AI_Data = {
	[-10001] = {head = 11000},
	[-10002] = {head = 11003},
	[-10003] = {head = 11025},
	[-10004] = {head = 11010},
}

function View:AddMember(hero)
    for k, v in ipairs(self.members) do
        if v.pid == hero.pid then
            self:UpdateHero(v, hero);
            return;
        end
    end

    if #self.members >= 5 then
        ERROR_LOG('more than 5 member');
        return;
    end

    local view = SGK.UIReference.Instantiate(self.prefab);
    view.transform:SetParent(self.view.Members.transform, false);
    view:SetActive(true);

    local member = {
        pid   = hero.pid,
        heros = {},
        view  = view,
    }

    self.audioSource_list[hero.pid] = {script = view[SGK.AudioSourceVolumeController]}

    table.insert(self.members, member);

    local icon_frame = utils.IconFrameHelper.Create(view.Player.IconFrame,{pid = hero.pid, level = hero.player_level});

    if Local_AI_Data[hero.pid] then
        icon_frame:GetComponent(typeof(SGK.CommonIcon)).Icon = "icon/" .. Local_AI_Data[hero.pid].head
    end

    view.Player.Name[UI.Text].text = hero.player_name;

    self:UpdateHero(member, hero);
end

function View:UpdateHero(info, hero)
    local find = false;
    for _, v in ipairs(info.heros) do
        if v.uuid == hero.uuid then
            find = true;
            break;
        end
    end

    if not find then
        table.insert(info.heros, hero)
        table.sort(info.heros, function(a,b)
            return a.pos < b.pos;
        end)
    end

    for i = 1, 5 do
        if info.heros[i] then
            info.view.Heros[i]:SetActive(true);
            utils.IconFrameHelper.Create(info.view.Heros[i].IconFrame,{
                customCfg = {
                    icon    = info.heros[i].icon,
                    quality = info.heros[i].quality or 0,
                    star    = 0, -- info.heros[i].star or 0,
                    level   = 0, -- info.heros[i].level or 0,
                },
                type=utils.ItemHelper.TYPE.HERO,
            });
        else
            info.view.Heros[i]:SetActive(false);
        end
    end
end

function View:CheckMemberStatus(partner_status)
    for _, member in ipairs(self.members) do
        local view = member.view
        if not partner_status[member.pid].have_live then
            view.Player.status[CS.UGUISpriteSelector].index = 1
            view.Heros:SetActive(false)
            view.Player.status:SetActive(true)
        elseif not partner_status[member.pid].not_all_action then
            view.Player.status[CS.UGUISpriteSelector].index = 2
            view.Heros:SetActive(false)
            view.Player.status:SetActive(true)
        else
            view.Heros:SetActive(true)
            view.Player.status:SetActive(false)   
        end
    end
end

function View:GetHeroView(pid, uuid)
    for k, v in ipairs(self.members) do
        if v.pid == pid then
            for i, h in ipairs(v.heros) do
                if h.uuid == uuid then
                    return v.view.Heros[i];
                end
            end
        end
    end
end

function View:UNIT_CAST_SKILL(pid, uuid, icon)
    if icon == nil or icon == 0 then
        return;
    end

    local view =self:GetHeroView(pid, uuid);
    if view then
        view.Skill.Icon[UnityEngine.UI.Image]:LoadSprite("icon/" .. icon);
        view.Skill:SetActive(true);
    end
end

function View:SetHP(pid, uuid, percent)
    local view = self:GetHeroView(pid, uuid);

    if view.HpSmall then
        view.HpSmall.value.handle:SetActive(percent ~= 1)
        view.HpSmall:SetActive(true);
        view.HpSmall.value[UI.Image].fillAmount = percent
        view.HpSmall.value.handle[UnityEngine.RectTransform]:SetSizeWithCurrentAnchors(UnityEngine.RectTransform.Axis.Horizontal, percent * 100)
    else
        view.BattlefiledBar:SetActive(true);
        view.BattlefiledBar.Value[UI.Image].fillAmount = percent
    end
end

function View:addSound(pid)
    local audioSource = self.audioSource_list[pid].script
    audioSource:Play("sound/red_line_hit.wav")
end

function View:Update()
    --[[
    for _, v in pairs(self.sound_list) do
        v = v - UnityEngine.Time.deltaTime
        if v <= 0 then
            sound_list[pid] = nil
        end
    end 
    --]]   
end

function View:CreateBullet(pid, from_uuid, pos)
    local view =self:GetHeroView(pid, from_uuid);
    if view then
        local bullet = SGK.UIReference.Instantiate(self.view.bullet.gameObject);
        bullet[CS.LookAtTargetWithScale].targetPosition = pos;
        bullet[CS.FollowTarget].target = view.transform;
        bullet:SetActive(true);
        UnityEngine.GameObject.Destroy(bullet.gameObject, 2);
        self:ShowRed(view)
        self:addSound(pid)

        local bulletHit = SGK.UIReference.Instantiate(self.view.bulletHit.gameObject);
        bulletHit.transform.position = pos
        bulletHit.transform:DOScale(Vector3(1,1,1),0.25):OnComplete(function ()
            bulletHit:SetActive(true);
            UnityEngine.GameObject.Destroy(bulletHit.gameObject, 2);    
        end)
    end
end

function View:RoleDead(pid, refid, sync_id)
    local view =self:GetHeroView(pid, refid, sync_id);
    if view then
        local bullet = SGK.UIReference.Instantiate(self.view.bullet.gameObject);
        bullet[CS.LookAtTargetWithScale].targetPosition = pos;
        bullet[CS.FollowTarget].target = view.transform;
        bullet:SetActive(true);
        UnityEngine.GameObject.Destroy(bullet.gameObject, 2);
    end
end

function View:SetReady(view, show)
    if not show then
        if view.Effect.fx_icon_jiantou_ready ~= nil then
            view.Effect.fx_icon_jiantou_ready:SetActive(false);
        end
        return;
    end

    if not self.fx_icon_jiantou_ready  then return end;

    if not view.Effect.fx_icon_jiantou_ready then
        view.Effect.fx_icon_jiantou_ready = UnityEngine.GameObject.Instantiate(self.fx_icon_jiantou_ready);
        view.Effect.fx_icon_jiantou_ready:GetComponent(typeof(UnityEngine.RectTransform)):SetParent(view.Effect.transform, false);
    end
    view.Effect.fx_icon_jiantou_ready:SetActive(true);
end

function View:SetDark(view, show)
    if not show then
        if view.Effect.fx_icon_jiantou_dark ~= nil then
            view.Effect.fx_icon_jiantou_dark:SetActive(false);
        end
        return;
    end

    if not view.Effect.fx_icon_jiantou_dark then
        view.Effect.fx_icon_jiantou_dark = UnityEngine.GameObject.Instantiate(self.fx_icon_jiantou_dark);
        view.Effect.fx_icon_jiantou_dark:GetComponent(typeof(UnityEngine.RectTransform)):SetParent(view.Effect.transform, false);
    end
    view.Effect.fx_icon_jiantou_dark:SetActive(true);
end

function View:ShowRed(view)
    if not view.Effect.fx_icon_jiantou then
        view.Effect.fx_icon_jiantou = SGK.UIReference.Instantiate(self.fx_icon_jiantou);
        view.Effect.fx_icon_jiantou.transform:SetParent(view.Effect.transform, false);
        view.Effect.fx_icon_jiantou.animator = view.Effect.fx_icon_jiantou:GetComponentInChildren(typeof(UnityEngine.Animator));
    end
    view.Effect.fx_icon_jiantou.animator:SetTrigger("restart");
end

function View:UNIT_BEFORE_ACTION(pid, uuid)
    local view =self:GetHeroView(pid, uuid)
    self:SetDark(view, false);
    self:SetReady(view, true);
end

function View:UNIT_AFTER_ACTION(pid, uuid)
    local view = self:GetHeroView(pid, uuid)
    -- self:SetDark(view, true);
    self:SetReady(view, false);
end

function View:ROUND_START()
    for k, v in ipairs(self.members) do
        for i, h in ipairs(v.heros) do
            self:SetDark(v.view.Heros[i], false);
            self:SetReady(v.view.Heros[i], false);
        end
    end
end

function View:HeroStatusChange(pid, uuid, status)
    local view =self:GetHeroView(pid, uuid)

    local icon = view.gameObject:GetComponentInChildren(typeof(SGK.CommonIcon));
    if status == 0 then
        icon.colorGray = true; -- 死亡
    else
        icon.colorGray = false; -- 死亡
    end
end

--[[
function View:onEvent(event, info)
    -- target 0  玩家  其他  对应位置的角色
    -- value  0 不存在或者未准备好 1 已准备好  2 已死亡   默认显示 0 的状态    10 开始输入 11 等待boss
    if event == "Player_Hero_Status_Change" then
        if info.target == 0 then
            if info.value == 10 then
                for i = 1, 5 do
                    local view = self:GetHeroViewByPos(info.pid, i);
                    if view then
                        self:SetDark(view, false);
                        self:SetReady(view, false);
                    end
                end
            end
            return;
        end

        local view = self:GetHeroViewByPos(info.pid, info.target);
        if not view then
            return;
        end

        local icon = view:GetComponentInChildren(typeof(SGK.CharacterIcon));
        if info.value == 2 then
            icon.gray = true; -- 死亡
            self:SetDark(view, false);
            self:SetReady(view, false);
        else
            icon.gray = false; -- 死亡
            self:SetDark(view, info.value == 11);
            self:SetReady(view, info.value == 10);
        end
    end
end
--]]

return View;