-- guide_picture

local Config = {}
local picture = LoadDatabaseWithKey("guide_picture","id") or {};
function Config.getConfig(id)
    if picture then
        if id then
            return picture[id]
        else
            return picture
        end
    else
        ERROR_LOG("说明表为空")
    end
end
return Config;
--  {
--  GetConfig=getConfig,
--  GetConfigList=getConfigList,
-- }