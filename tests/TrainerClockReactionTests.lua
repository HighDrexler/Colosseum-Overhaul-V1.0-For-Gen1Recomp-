local oldLove=love;local now=0
love={timer={getTime=function()return now end}}
local A=assert(loadfile('lib/TrainerPerformance.lua'))({})
for _,speed in ipairs({1,2,4,10}) do
 now=0;local clock={};local total=0
 A.realDt({},1/60,clock)
 for frame=1,60 do now=frame/60;for tick=1,speed do total=total+A.realDt({},speed/60,clock) end end
 assert(math.abs(total-1)<1e-8,'trainer accelerates at '..speed..'x')
 now=10;assert(A.realDt({},10,clock)==.05,'stall fast-forwards an action')
 now=11;assert(A.realDt({},0,clock)==0,'paused actor advances')
end
love=oldLove
assert(A.damageReaction(0,100)==nil)
assert(A.damageReaction(1,100)=='brace','chip damage is silently ignored')
assert(A.damageReaction(35,100)=='concern')
assert(not A.shouldTrigger({},'throw',1,'command',1.5),'throw follow-through interrupted')
assert(A.shouldTrigger({},'throw',1,'defeat',1.5),'final defeat blocked')
assert(not A.shouldTrigger({},'defeat',99,'frustration',2.5),'faint overwrites final result')
local q=A.queueReaction(nil,'brace',.5);q=A.queueReaction(q,'concern',1);q=A.queueReaction(q,'brace',.5)
assert(q.kind=='concern','multi-hit coalescing loses stronger response')
local M=assert(loadfile('lib/TrainerMorph.lua'))({})
assert(M.actionWeight({nativeKind='throw',nativeActionAge=0,nativeDuration=1.5})==0)
assert(M.actionWeight({nativeKind='throw',nativeActionAge=.465,nativeDuration=1.5})==1,'release blended away')
assert(M.actionWeight({nativeKind='throw',nativeActionAge=1.5,nativeDuration=1.5})==1,'authored travelling recovery is pulled back to idle')
assert(M.actionWeight({nativeKind='defeat',nativeActionAge=3,nativeDuration=3})==1,'result fades to idle')
local hit={count=2,endFrame=1};local fallback={count=2,endFrame=1}
assert(M.trackSample({roles={brace=hit,reaction=fallback}},'brace',0,0,1)==hit,'specific hit clip ignored')
print('Trainer wall clock, reaction and throw recovery tests passed')

