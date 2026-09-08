local clock=0;local oldLove=love
love={timer={getTime=function()return clock end}}
local A=assert(loadfile('lib/BattleAutoProgress.lua'))({})
local input={wasPressed=function()return false end,isDown=function()return false end}
local screen={game={input=input,save={}},phase='messages',current={text='A critical hit!'},msgPrompt=true,lineIndex=1}
local function tick(n,generation)
 local result=false
 for i=1,n do clock=clock+1/60;result=A.update(screen,generation or 1,100) or result end
 return result
end
assert(not tick(30),'Fast game dt skipped real read time')
assert(tick(30),'Complete message did not auto advance')
for _,phase in ipairs({'menu','moves','stats-box','learn-move','replace','cbe_doubles'})do
 screen.phase=phase;assert(not tick(100),'Auto answered '..phase)
end
screen.phase='messages';screen.current.choice=function()end;assert(not tick(100),'Auto chose yes/no');screen.current.choice=nil
screen.waitingUI=true;assert(not tick(100),'Auto progressed covered UI');screen.waitingUI=nil
screen.game.save.colosseumBattle={autoProgressEnabled=false};assert(not tick(100),'OFF ignored');screen.game.save.colosseumBattle.autoProgressEnabled=true
screen.msgPrompt=nil;screen.msgWaiting=true;screen.msgPreWait=0;assert(tick(65),'Continuation page stuck')
local seen=false
A.call(function(s)seen=s.game.input:wasPressed('a');assert(not s.game.input:isDown('a'))end,screen,true)
assert(seen and screen.game.input==input and not input:wasPressed('a'),'Synthetic input leaked')
assert(not pcall(A.call,function()error('test')end,screen,true));assert(screen.game.input==input,'Failed callback leaked input')
screen.phase='resolving';screen.message='It is super effective!';screen.messageTimer=1;screen.typedText=screen.message
screen.typer={done=function()return false end};assert(not tick(100,2),'Unread text skipped')
screen.typer.done=function()return true end;screen.hpAnim={};assert(not tick(100,2),'HP animation skipped');screen.hpAnim=nil
screen.anim={done=function()return false end};assert(not tick(100,2),'Move animation skipped');screen.anim=nil
assert(tick(65,2),'Gen II completed message stuck')
local Core=assert(loadfile('lib/doubles/Core.lua'))()
local steps=0;local core=setmetatable({clock=0,phase='present',eventTime=0,currentEvent={duration=.2,presentationPending=true},presentNext=function()steps=steps+1 end},Core)
for i=1,100 do core:update(.1,true)end
assert(steps==0,'A bypassed animation hold')
core.currentEvent.presentationPending=nil;core.autoProgress=false
core:update(.1,false);assert(steps==0,'Manual option ignored')
core:update(.1,true);assert(steps==1,'Manual advance failed after animation')
love=oldLove
print('BattleAutoProgressTests: wall clock, readable pages, prompts, choice/menu guards, animation gates and input restoration OK')
