local obj = ...
local TypeName = StringSplit(obj.name,"_")
local gid = tonumber(TypeName[2])

--1:普通  2：尖刺   3：圈圈
local TableTalking = {
    {2039801,"黄金之灵原来藏在这么深的地方。",1},
    {2039801,"嘿嘿，这次发达了！",3},
    {2039801,"陆水银你来的正是时候。",1},
    {2039801,"黑虎之力还真是好用！",3},
    {1039803,"卑劣者！交还黄金之灵！",2},
    {1039803,"我是黄金之灵孕育的生命！",1},
    {1039803,"我的职责就是守护黄金之灵！",1},
    {1039803,"我能调动整个黄金矿脉内的土元素！",1},
    {1039802,"抢回……黄金……灵！",1},
    {1039802,"吼！！不可……原谅！",2},
    {1039802,"去把……兄弟……们……叫来！",1},
    {1039802,"撕成……碎片！",1},
    {1039800,"嗷嗷！",1},
    {1039800,"嗷呜！",1},
    {1039800,"吼——",2},
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