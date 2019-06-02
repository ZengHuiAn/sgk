local obj = ...
local TypeName = StringSplit(obj.name,"_")
local gid = tonumber(TypeName[2])

--1:普通  2：尖刺   3：圈圈
local TableTalking = {
    {1041802,"啾啾啾……",1},
    {1041801,"哈呋哈呋！",1},
    {1041800,"最强冰系玩家是我！",2},
    {1041800,"我就是最强！",2},
    {1041800,"是我！",2},
    {2041800,"我才是最强！",2},
    {2041800,"明明是我！",2},
    {2041800,"是我！",2},
    {1041804,"等我融合了【玉魄之心】……",3},
    {1041804,"哦，何等强大的力量！",1},
    {1041804,"我已经可以想象以后的xing福生活了！",3},
    {1041804,"只要得到了这股力量，那我就可以为所欲为！",1},
    {2041800,"快阻止他！",2},
    {2041800,"千万不能让他得逞！",2},
    {2041800,"快把这个变态解决了！",2},
    {2041800,"【玉魄之心】可是所有冰系玩家都梦寐以求的至宝！",2},
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
end