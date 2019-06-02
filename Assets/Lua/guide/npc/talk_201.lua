local obj = ...
local TypeName = StringSplit(obj.name,"_")
local gid = tonumber(TypeName[2])

--1:普通  2：尖刺   3：圈圈
local TableTalking = {
    {2017801,"水银你有想我吗？",1},
    {2017801,"好久不见呢水银~",1},
    {2017801,"想见到你的小情人就要先通过我的试炼哦~",1},
    {2017801,"最近新得到了一只小猫咪呢~",1},
    {1017800,"我……是谁？",1},
    {1017800,"鲜血……给！我！",1},
    {1017800,"这是……哪里？",1},
    {1017800,"吼吼吼！！",1},
    {1017801,"你惹女王大人不高兴了！",2},
    {1017801,"我会打败你给女王出气！",1},
    {1017801,"你小子究竟哪里好了？",1},
    {1017801,"你可不要被我英俊的外表迷住哦！",1},
    {1017802,"为了给主人报仇！",2},
    {1017802,"我要亲手解决你这个叛徒！",2},
    {1017802,"不可……原谅！",2},
    {1017802,"陆水银必须死！",2},

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