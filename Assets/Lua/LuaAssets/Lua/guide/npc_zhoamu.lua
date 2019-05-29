--[[ local npc = module.EncounterFightModule.GUIDE.NPCInit(...);

local i=1
while true do
    --移动至坐标
  npc:MoveTo(Vector3(5,5,5))
    --移动至标志物
    npc:Interact("dengzuo_1 (2)");
    npc:Roll(3);
    npc:Interact("dengzuo_2 (3)"); 
    npc:Sleep(3);
    --npcid（nil为自己），对话，function，框id
    LoadNpcDesc(nil,"测试消息测试、\n消息测试消息测试",nil,2)
end ]]

local NPC_OBJ = ...
local view = CS.SGK.UIReference.Setup(NPC_OBJ)
local npc = module.EncounterFightModule.GUIDE.NPCInit(NPC_OBJ)

while true do
  npc:Roll(math.random( 5,10 ))
  --ShowNpcDesc(view.Root.Canvas.dialogue,"哈哈哈",nil,1,5)
  local istalkRan = math.random(1,100)
  --local sleepTime = math.raddom(1,2) + math.random()
  --sleepTime = tonumber(string.format("%.2f",sleepTime))
  if istalkRan < 31 then 
    ShowNpcDesc(view.Root.Canvas.dialogue,"哈哈哈",nil,2,5)
    npc:Sleep(1);
  end 
  --npc:Sleep(1)

end 