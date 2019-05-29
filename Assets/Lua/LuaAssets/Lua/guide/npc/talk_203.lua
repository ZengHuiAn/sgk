local obj = ...
local TypeName = StringSplit(obj.name,"_")
local gid = tonumber(TypeName[2])

--1:普通  2：尖刺   3：圈圈
local TableTalking = {
    {2040802,"大家坚持住！",2},
    {2040802,"千万不能让这条魔影龙脱离控制了！",2},
    {2040802,"可恶！要不是我们三个不擅长输出！",3},
    {2040802,"竟然选在这个时候……",3},
    {2040804,"我的刀对陵兽的伤害有限……",3},
    {2040804,"也不知道赫兹尔能不能找到首领……",3},
    {2040804,"陆伯当心！",2},
    {2040804,"只要拖住等赫兹尔回来就行了……",3},
    {2040803,"糟糕，我的花草被魔龙的火焰克制了！",3},
    {2040803,"铁墓真什么时候回来啊？",1},
    {2040803,"唉，我这把老骨头还要这么折腾……",3},
    {2040803,"人老了，身体吃不消了……",1},
    {2040800,"你快上啊，站在边上看什么呢？",2},
    {2040800,"你真的有能力对付魔影龙吗？",1},
    {2040800,"你不会是来骗吃骗喝的吧？",2},
    {1040800,"呼……好累啊！",1},
    {1040800,"怎么每次行动都有我……",3},
    {1040800,"回去我得好好补补！",3},
    {1040801,"水银我们又见面了呢~",1},
    {1040801,"这下我的小猫咪又可以变强大了！",1},
    {1040801,"没有铁墓真的铁墓还真是好进呢~",1},
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