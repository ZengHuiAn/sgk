local obj = ...
local TypeName = StringSplit(obj.name,"_")
local gid = tonumber(TypeName[2])

--1:普通  2：尖刺   3：圈圈
local TableTalking = {
    {1015800,"想要入侵？先问过我小蜜桃同不同意！",2},
    {1015801,"我一定会成为像父亲一样伟大的蘑菇！",1},
    {1015801,"我今天做得够好了吗？",3},
    {1015801,"不！还不够！我还能做得更好！",3},
    {1015804,"我从不后悔自己的选择！",3},
    {1015804,"我必须回应人民的期许！",3},
    {1015804,"真想看到有一天蘑菇一族能光明正大的出现在世人面前啊……",1},
    {1015804,"吾心吾行澄如明镜，所作所为皆为正义！",1},
    {1015805,"疼痛真是世界上最愉悦的享受！",2},
    {1015806,"呷呷呷！今天恶作剧的对象选谁呢？",3},
    {1015807,"怎么会有人怕痛？",1},
    {1015808,"唔……不可以打架哦！",3},
    {1015809,"我……我想回家了……",1},
    {1015810,"唔噫！谁……谁在那里？！",3},
    {1015811,"我会变得更强，谁也别想入侵蘑菇一族！",2},
    {1015812,"怎么？你想和我打一架吗？",2},
    {2015801,"我一定会保护你的！",3},
    {2015802,"嗯？小紫去哪里了……",1},
    {2015805,"这里真美啊~",1},
    {2015806,"嘿嘿……看不到我~",3},
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