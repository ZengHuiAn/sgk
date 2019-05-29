

function Preload()
    print('Preload', root, game);
end

function Start()
    print('Start', root, game);
end

-- function Update(dt) end
-- function OnDestroy() end

function Test()
end


function API.Test()
    print('Test')
end

function EVENT.UNIT_Hurt(...)
    print('EVENT.UNIT_Hurt', ...);
end
