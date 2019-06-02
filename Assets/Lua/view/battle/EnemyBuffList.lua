local EnemyBuffList = {}

local function SortBuffs(buffs)
    local passive_buff = {}
    local other_buff = {}

    for _, buff in ipairs(buffs) do
        if buff.icon and buff.icon ~= "0" and buff.icon ~= "" and buff.icon ~= 0 then
            if buff.id >= 3000000 and buff.id < 4000000 then
                table.insert(passive_buff, buff)
            else
                table.insert(other_buff, buff)
            end
        end
    end
 
    return passive_buff ,other_buff
end

function EnemyBuffList:Start()
    self.view = SGK.UIReference.Setup(self.gameObject);
    self.view.transform:DOScale(Vector3(1, 0.1, 1), 0)
    self.view:SetActive(false)
end

function EnemyBuffList:ShowView(buffs)
    local passive_buff ,other_buff = SortBuffs(buffs)
    if #passive_buff == 0 and #other_buff == 0 then return end

    local item_count = 0
    local id_list = {}

    for k, buff in ipairs(passive_buff) do 
        if id_list[buff.id] then
        else
            item_count = item_count + 1
            if item_count > 10 then break end

            local item = self.view["item"..item_count]
            id_list[buff.id] = true
            SGK.ResourcesManager.LoadAsync("icon/" .. buff.icon .. ".png", typeof(UnityEngine.Sprite), function(o) 
                item.icon[UnityEngine.UI.Image].sprite = o;
                item.icon[UnityEngine.UI.Image]:SetNativeSize()
                item.icon.transform.localScale = Vector3.one * (buff.icon_scale ~= 0 and buff.icon_scale or 1)
                item.Text[UI.Text].text = buff._desc;
                item:SetActive(true)            
            end);
        end
    end

    for k, buff in ipairs(other_buff) do 
        if id_list[buff.id] then
        else
            item_count = item_count + 1
            if item_count > 10 then break end

            local item = self.view["item"..item_count]
            id_list[buff.id] = true
            SGK.ResourcesManager.LoadAsync("icon/" .. buff.icon .. ".png", typeof(UnityEngine.Sprite), function(o) 
                item.icon[UnityEngine.UI.Image].sprite = o;
                item.icon[UnityEngine.UI.Image]:SetNativeSize()
                item.icon.transform.localScale = Vector3.one * (buff.icon_scale ~= 0 and buff.icon_scale or 1)
                item.Text[UI.Text].text = buff._desc;
                item:SetActive(true)            
            end);
        end
    end

    self.view.transform.localScale = Vector3(1, 0.1, 1)
    self.view:SetActive(true)   
    self.view.transform:DOScale(Vector3.one, 0.3) 
end

function EnemyBuffList:CloseView()
    for i = 1,10,1 do
        self.view["item"..i]:SetActive(false)
    end
    self.view:SetActive(false)
    self.view.transform.localScale = Vector3(1, 0.1, 1)
end

return EnemyBuffList;