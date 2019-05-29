local class = require "utils.class"

local M = class();

function M:_init_()
    self.round     = 0
    self.wave      = 0
    self.max_wave  = 0

    self.win_type   = 0
    self.fight_type = 0
    self.scene      = ""
    self.fight_id   = 0
    self.star       = {}

    self.win_round_limit    = 0
    self.failed_round_limit = 0

    self._last_round = 0
    self._last_scene = nil
    self._last_star  = self.star;
end

function M:Serialize()
    local star = {}
    for _, v in ipairs(self.star or {}) do
        table.insert(star, {v.type, v.v1, v.v2})
    end

    if self.scene == "" then
        return {self.round, self.wave, star}
    else
        return {self.round, self.wave, star,
            self.max_wave,
            self.win_type,
            self.fight_type,
            self.scene,
            self.fight_id,
            self.win_round_limit,
            self.failed_round_limit,
        }
    end
end

function M:DeSerialize(data)
    self.star = {}
    self.round, self.wave, self.win_type = 
        data[1], data[2];

    for _, v in ipairs(data[3] or {}) do
        table.insert(self.star, {type = v[1], v1 = v[2], v2 = v[3]})
    end

    if data[4] then
        self.max_wave = data[4]
        self.win_type = data[5]
        self.fight_type = data[6]
        self.scene = data[7]
        self.fight_id = data[8]
        self.win_round_limit = data[9]
        self.failed_round_limit = data[10]
    end
end

function M:ChangeRound(round, wave)
    self.round = round
    self.wave  = wave or self.wave
end

function M:ChangeScene(scene)
    self.scene = scene;
end

function M:SerializeChange()
    local info = {}
    if self._last_round ~= self.round then  
        self._last_round = self.round;
        table.insert(info, {1, self.wave, self.round});
    end

    if self._last_scene ~= self.scene then
        self._last_scene = self.scene;
        table.insert(info, {2, self.scene})
    end

    if self._last_star ~= self.star then
        self._last_star = self.star;

        local star = {}
        for _, v in ipairs(self.star or {}) do
            table.insert(star, {v.type, v.v1, v.v2})
        end

        table.insert(info, {3, star, self.win_type, self.fight_type, self.scene, self.fight_id, self.win_round_limit, self.failed_round_limit, self.max_wave});
    end

    if #info > 0 then
        return info;
    end
end

function M:ApplyChange(changes)
    for _, v in ipairs(changes) do
        if v[1] == 1 then
            self.wave, self.round = v[2], v[3]
        elseif v[1] == 2 then
            self.scene = v[2]
        elseif v[1] == 3 then
            self.start = {}
            for _, x in ipairs(v[2] or {}) do
                table.insert(self.star, {type = x[1], v1 = x[2], v2 = x[3]})
            end

            self.win_type           = v[3]
            self.fight_type         = v[4] 
            self.scene              = v[5]
            self.fight_id           = v[6] 
            self.win_round_limit    = v[7] 
            self.failed_round_limit = v[8]
            self.max_wave           = v[9]
        end
    end
end
 
return M;
