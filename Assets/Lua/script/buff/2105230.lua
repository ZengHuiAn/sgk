local be_hit = 0

function onPostTick(target, buff)
    if be_hit == 1 then
        target.hp = 0
    end
end

function targetWillHit(target, buff, bullet)  
    if bullet.hurt_disabled == 0 then
        be_hit = 1
        bullet.name_id = buff.id
        bullet.hurt_final_value = -1
    end
end

