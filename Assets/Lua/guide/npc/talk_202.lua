local obj = ...
local TypeName = StringSplit(obj.name,"_")
local gid = tonumber(TypeName[2])
local npc = module.EncounterFightModule.GUIDE.NPCInit(...);

--1:普通  2：尖刺   3：圈圈
local TableTalking = {
    {1018800,"吼吼吼！！",2},
    {1018800,"嗷嗷嗷嗷！！",2},
    {1018800,"鲜……血！！",2},
    {1018802,"我奉命守在这里！",1},
    {1018802,"下面可不是你们能去的地方！",1},
    {1018802,"我似乎忘记了很多东西，我的仇人，我的亲人……",3},
    {1018802,"我生前是个怎样的人呢？",3},
    {1018802,"想从这里下去吗？",1},
    {2018800,"没想到最后还要靠陆水银来救我……",3},
    {2018800,"只要得到那件东西……",3},
    {2018800,"我好歹曾经也是守墓人的一员呢！",1},
    {2018800,"这里曾经是守墓人的秘密基地。",1},
    {2018801,"爸爸！",1},
}

local talkNum = 0
local myTalking = {}
for i = 1 ,#TableTalking do
    if gid == TableTalking[i][1] then
        table.insert(myTalking,TableTalking[i])
        talkNum = talkNum +1
    end
end

if talkNum > 0 then 
    local temp
    while true do
        temp = math.random(1,#myTalking)
        Sleep(math.random(5,30))
        LoadNpcDesc(gid,myTalking[temp][2],nil,myTalking[temp][3])  
    end
else
    utils.SGKTools.SetNPCSpeed(gid,0.25)
    utils.SGKTools.SetNPCTimeScale(gid,0.25)
    while true do

        --npc:Interact("dengzuo_1 (2)");
        --npc:Roll(3);

        local tempX = math.random(-4,4)
        local tempZ = math.random(3,18)
        npc:MoveTo(Vector3(tempX,-1.9,tempZ))

        local temp = math.random(1,2)
        npc:Sleep(temp)
        if temp > 1.8 then
            LoadNpcDesc(gid,"吼...吼...吼...",nil,2)
        elseif temp > 1.6 then
            npc:Roll(1)
        end
    end
end




