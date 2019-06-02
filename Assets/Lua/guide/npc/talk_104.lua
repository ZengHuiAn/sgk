local obj = ...
local TypeName = StringSplit(obj.name,"_")
local gid = tonumber(TypeName[2])

--1:普通  2：尖刺   3：圈圈
local TableTalking = {
    {1042800,"桀桀桀！",2},
    {1042801,"嗡嗡嗡嗡……",1},
    {1042802,"吾乃血海之意志，亦为血莲之守护！",1},
    {1042802,"胆敢觊觎血海之莲？",1},
    {1042802,"卑鄙的盗墓者，死！",2},
    {1042802,"杀生为护生，斩业非斩人！",1},
    {1042804,"我已经天下无敌了！",2},
    {1042804,"有了这么强大的力量，还有谁是我的对手？",1},
    {1042804,"你看我像是会信守承诺之人吗？",1},
    {1042804,"嘿嘿，到头来还不是被我利用了！",1},
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