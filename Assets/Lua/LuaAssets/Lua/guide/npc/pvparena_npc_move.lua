
local PVPArenaModule = require "module.PVPArenaModule";

--正在匹配
local function atk_pos_ran(posNum)
	--math.randomseed(os.time())
	local pos_ran1= {1,3}
	local pos_ran = {pos_ran1[math.random(1,2)]}
	
    --print(pos_ran[1])
	local i = 2
    while true do
		local a = 0
        local newpos = math.random(1,posNum)
        for j = 1 , #pos_ran do
            if pos_ran[j] == newpos then 
                a = 1
            end
        end
        if a ~= 1 then 
            pos_ran[#pos_ran+1] = newpos
        else 
            i = i - 1
        end 
		i = i + 1
		if i > posNum then
			break
		end
		--print(newpos,"    ",pos_ran[m],"    ",i)
    end 
    return pos_ran
end 


local TalkingTable = {"!","切~","呃。。。","溜了溜了"}
local TalkingTable_qianggou = {"隔壁超市薯片半价耶！！","冲啊！"}
local TalkingTable_pangguan = {"打架啦打架啦！","好热闹啊！","你挡着了我了嘿！","买定离手！"}

local function arena_npc_waiting()

    -- local atk_info,def_info = PVPArenaModule.GetPVPFormation();
    local RoleTable = {11000,11001,11002,11003,11004,
    11007,11008,11009,11012,11013,
    11014,11022,11023,11024,11028}
    local ShowType = math.random(1,100)
    local atk_pos = atk_pos_ran(5)
  
    if ShowType > 30 then
        local RoleNum = math.random(1,5)
        for i = 1 , RoleNum do
            local index = math.random(1,#RoleTable)
            local RoleID =  tonumber((tostring(os.time()):reverse():sub(1, 3))) * 100000 + RoleTable[index]
            table.remove(RoleTable, index)
            PVPArenaModule.AddCharacter(RoleID)
            if i == 1 then
                PVPArenaModule.MoveCharacter(RoleID,"def"..atk_pos[i],function ()      
                    PVPArenaModule.CharacterTalk(RoleID,TalkingTable[math.random(1,#TalkingTable)], 2)
                    coroutine.resume(coroutine.create( function ()
                        Sleep(1)
                        PVPArenaModule.MoveCharacterByPosition(RoleID,Vector3(400,-20,0),function ()      
                            PVPArenaModule.RemoveCharacter(RoleID)
                            coroutine.resume(coroutine.create( function ()
                                Sleep(2.0)
                                DispatchEvent("ARENA_NPC_MOVE_END");
                            end));
                        end)
                    end));
                end)
            else
                PVPArenaModule.MoveCharacter(RoleID,"def"..atk_pos[i], function ()
                    coroutine.resume(coroutine.create( function ()
                        Sleep(1)
                        PVPArenaModule.MoveCharacterByPosition(RoleID,Vector3(400,-20,0),function ()      
                            PVPArenaModule.RemoveCharacter(RoleID)
                        end)
                    end));
                end)
            end
        end      
    elseif ShowType > 5 then 
        local RoleID_dageng = RoleTable[math.random(1,#RoleTable)] + tonumber((tostring(os.time()):reverse():sub(1, 3))) * 100000
        PVPArenaModule.AddCharacterByPosition(RoleID_dageng,Vector3(400,-330,0))
        PVPArenaModule.MoveCharacterByPosition(RoleID_dageng,Vector3(-400,-330,0),function ()      
            PVPArenaModule.RemoveCharacter(RoleID_dageng)
            coroutine.resume(coroutine.create( function ()
                Sleep(2.0)
                DispatchEvent("ARENA_NPC_MOVE_END");
            end));
        end)
        coroutine.resume(coroutine.create( function ()
            Sleep(0.5)
            PVPArenaModule.CharacterTalk(RoleID_dageng,"天干物燥，小心火烛", 2)
        end));
    else
        local RoleNum_qianggou = math.random(3,5)
        for i = 1 , RoleNum_qianggou do
            local index = math.random(1,#RoleTable)
            local RoleID_qianggou = RoleTable[index] + tonumber((tostring(os.time()):reverse():sub(1, 3))) * 100000
            table.remove(RoleTable, index)
            PVPArenaModule.AddCharacterByPosition(RoleID_qianggou,Vector3(400+(i-1)*100,-330+math.random(0,60),0))
            PVPArenaModule.MoveCharacterByPosition(RoleID_qianggou,Vector3(-400,-330+math.random(0,60),0),function ()      
                PVPArenaModule.RemoveCharacter(RoleID_qianggou)
                coroutine.resume(coroutine.create( function ()
                    Sleep(2.0)
                    DispatchEvent("ARENA_NPC_MOVE_END");
                end));
            end)
            coroutine.resume(coroutine.create( function ()
                --Sleep(0.5)
                PVPArenaModule.CharacterTalk(RoleID_qianggou,TalkingTable_qianggou[math.random(1,#TalkingTable_qianggou)], 2)
            end));
        end
    end 
end

--突袭匹配成功
local function arena_npc_tuxi()
    --local PVPArenaModule = require "module.PVPArenaModule";
    local atk_info,def_info = PVPArenaModule.GetPVEFormation();
    --ERROR_LOG("@@@@@@@@@@@@@@",sprinttb(def_info))
    PVPArenaModule.CharacterTalk(atk_info[1].id,"好像发现软柿子了", 2, nil, 1)
    for i,v in ipairs(def_info) do
        PVPArenaModule.AddCharacter(v.id);
        if i == 1 then
            PVPArenaModule.MoveCharacter(v.id,"def"..i,function ()      
                PVPArenaModule.CharacterTalk(v.id,"如果认为我是软柿子，你会输的很惨", 1)
                coroutine.resume(coroutine.create( function ()
                    Sleep(1.0)
                    DispatchEvent("ARENA_NPC_MOVE_END");
                end));
            end)
        else
            PVPArenaModule.MoveCharacter(v.id,"def"..i)
        end
    end
end

--决斗匹配成功
local function arena_npc_juedou()
    local RoleTable = {11000,11001,11002,11003,11004,
                    11007,11008,11009,11012,11013,
                    11014,11022,11023,11024,11028}
    --local PVPArenaModule = require "module.PVPArenaModule";
    local pangguan_pos_x_table = {{-300,-250},{-230,-190},{-170,-130},{-110,-70},{-50,-10},
                                  {10,50},{70,110},{130,170},{190,230},{250,300}}
    local atk_info,def_info = PVPArenaModule.GetPVPFormation();
     --旁观者
    local RoleNum_pangguan = math.random(5,10)
    for i = 1 , RoleNum_pangguan do
        local index = math.random(1 , #pangguan_pos_x_table)
        local pangguan_pos_x = math.random( pangguan_pos_x_table[index][1],pangguan_pos_x_table[index][2])
        table.remove( pangguan_pos_x_table, index )
        local pangguan_pos_y = math.random(-400,-300)
         local index = math.random(1,#RoleTable)
         local RoleID_pangguan = RoleTable[index] + tonumber((tostring(os.time()):reverse():sub(1, 3))) * 100000
         table.remove(RoleTable, index)
         PVPArenaModule.AddCharacterByPosition(RoleID_pangguan,Vector3(pangguan_pos_x + math.random(-60,60),pangguan_pos_y - math.random(100,250),0),3)
         PVPArenaModule.MoveCharacterByPosition(RoleID_pangguan,Vector3(pangguan_pos_x,pangguan_pos_y,0),function ()   
            if i == RoleNum_pangguan then
                coroutine.resume(coroutine.create( function ()
                    Sleep(1.0)
                    --DispatchEvent("ARENA_NPC_MOVE_END");
                        --自己
                    PVPArenaModule.CharacterTalk(atk_info[1].id,"光明正大地打一场吧！", 2, nil, 1)       
                    --敌人
                    for j,v in ipairs(def_info) do
                        -- print("敌人", v.id)
                        PVPArenaModule.AddCharacter(v.id);
                        if j == 1 then
                            PVPArenaModule.MoveCharacter(v.id,"def"..j,function ()      
                                PVPArenaModule.CharacterTalk(v.id,"奉陪到底！", 2)
                                coroutine.resume(coroutine.create( function ()
                                    Sleep(1.0)
                                    DispatchEvent("ARENA_NPC_MOVE_END");
                                end));
                            end)
                        else
                            PVPArenaModule.MoveCharacter(v.id,"def"..j)
                        end
                    end   
                end));    
            end
        end, 3)
        coroutine.resume(coroutine.create( function ()
           -- math.randomseed(os.time())
            local ran_talking = math.random( 1,100 )
             --Sleep(0.5)
            if ran_talking < 51 then 
                PVPArenaModule.CharacterTalk(RoleID_pangguan,TalkingTable_pangguan[math.random(1,#TalkingTable_pangguan)], 2, nil, 3)
            end
        end));
     end
    
   
end 

return {
    arena_npc_waiting = arena_npc_waiting,
    arena_npc_tuxi = arena_npc_tuxi,
    arena_npc_juedou = arena_npc_juedou,
}