local obj = ...
local TypeName = StringSplit(obj.name,"_")
local gid = tonumber(TypeName[2])

--1:普通  2：尖刺   3：圈圈
local TableTalking = {
    {2016802,"三带一！",2},
    {2016802,"王炸！",2},
    {2016802,"小弟你能不能快一点？",1},
    {2016802,"又赢了，真是无聊！",1},
    {2016803,"呜呜呜……",1},
    {2016804,"你是不是出老千了？",1},
    {2016804,"你怎么又有炸！",1},
    {2016804,"我能不打了吗？",1},
    {2016804,"真是个可怕的女人……",3},
    {2016801,"伊赛菲亚你不来帮忙吗？",1},
    {2016801,"这条大鱼真难搞……",1},
    {2016801,"我倒是想快点……",1},
    {2016801,"等我完成这次试炼就是名副其实的最强冰法了！",3},
    {2016801,"快来帮我！",2},
    {2016802,"没看我正忙着吗？一对二！",2},
    {2016801,"……你就是来这里斗地主的？",1},
    {2016802,"我这纤纤玉手只适合用来摸牌~",1},
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