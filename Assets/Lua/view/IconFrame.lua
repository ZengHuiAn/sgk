local IconFrameHelper = require "utils.IconFrameHelper"

local View={}

local TYPE = utils.ItemHelper.TYPE;

function View:OnDestroy()
    if self.icon then
        IconFrameHelper.Release(self.icon.gameObject);
    end
end

return View;