-- Tests use actual work/frame modules and a deterministic clock, not wall-clock claims.
local checks=0
local function eq(a,b,label)checks=checks+1;assert(a==b,label..': '..tostring(a)..' ~= '..tostring(b))end
local t=0;love={timer={getTime=function()return t end}}
local W=assert(loadfile('lib/WorkBudget.lua'))()
local n=0;local co=W.new(function()for i=1,30 do n=n+1;t=t+.001;W.checkpoint('row '..i)end;return true,'complete' end)
local ok,state=W.resume(co,3);eq(ok,true,'first resume');eq(state,'working','CPU loop yields');eq(n<=4,true,'first slice bounded in fixture')
for i=1,30 do ok,state=W.resume(co,3);if state=='done' then break end end
eq(n,30,'all work finishes without loss');eq(state,'done','completion');eq(W.status().yields>1,true,'multiple yields counted')
local cleaned,committed=0,0
co=W.new(function()W.onCancel(function()cleaned=cleaned+1 end);local done=W.onCancel(function()committed=committed+1 end);done();t=t+.01;W.checkpoint();return true end)
W.resume(co,3);W.cancel(co);W.cancel(co);eq(cleaned,1,'cancel cleanup once');eq(committed,0,'published resource retained');eq(W.resume(co,3),false,'cancelled task cannot resume')
co=W.new(function()W.onCancel(function()cleaned=cleaned+1 end);error('expected-fixture-error')end)
ok=W.resume(co,3);eq(ok,false,'exception propagated');eq(cleaned,2,'failure cleanup');eq(W.status().failed,1,'failure reported')
-- Non-cooperative callers never yield even after a deadline.
W.checkpoint('ordinary draw caller');eq(true,true,'ordinary caller unaffected')
local F=assert(loadfile('lib/FrameWork.lua'))()
local top=nil;local calls,steps=0,0
local game={phase='play',world={map={}},stack={top=function()return top end}}
function game:update(dt,extra)for i=1,8 do steps=steps+1;eq(F.active(self),true,'inside frame seam')end;return nil,extra,dt end
local before,after
F.attach(game,function(g,a,b)calls=calls+1;before=a;after=b;eq(steps,8*calls,'work after every fixed step')end)
local a,b,c=game:update(.016,'sentinel');eq(a,nil,'nil result');eq(b,'sentinel','second result');eq(c,.016,'third result');eq(calls,1,'8x speed one work budget')
eq(F.isOverworld(game,nil),true,'Gen2 world with empty stack admitted')
eq(F.isOverworld(game,{isBattle=true}),false,'battle not idle');eq(F.isOverworld(game,{isOverworld=true}),true,'Gen1 overworld admitted')
game.phase='title';eq(F.isOverworld(game,nil),false,'title excluded');game.phase='play'
local old=game.update;game.update=function(self,dt,...)return old(self,dt,...)end
F.attach(game,function()calls=calls+1 end);game:update(.016,'again');eq(calls,2,'third-party wrapper no double budget');eq(F.active(game),false,'depth cleared')
local failed={update=function()error('native-failure')end};local runs=0
F.attach(failed,function()runs=runs+1 end);local success,err=pcall(failed.update,failed,.016)
eq(success,false,'native error not swallowed');eq(tostring(err):find('native-failure',1,true)~=nil,true,'native error preserved');eq(runs,0,'failed update runs no work');eq(F.active(failed),false,'depth restored after error')
local switching={stack={top=function()return top end},update=function()top={isBattle=true}end}
F.attach(switching,function(_,b,a)before=b;after=a end);top=nil;switching:update(.016)
eq(before,nil,'pre-input top retained');eq(after.isBattle,true,'post-input battle detected')
print('PerformanceFrameBudgetTests: '..checks..' checks passed')
