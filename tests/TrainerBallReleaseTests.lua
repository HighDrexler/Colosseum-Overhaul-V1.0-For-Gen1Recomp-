local function up(fn,name,value,set)
  for i=1,100 do
    local n,v=debug.getupvalue(fn,i)
    if not n then break end
    if n==name then if set then debug.setupvalue(fn,i,value) end;return v end
  end
  error('missing upvalue '..name)
end
local function put(fn,name,v) up(fn,name,v,true) end
local rig=assert(loadfile('lib/TrainerRig.lua'))()
local perf=assert(loadfile('lib/TrainerPerformance.lua'))({})
local V={TrainerRig=rig,TrainerPerformance=perf,TrainerMorph={dense=function() return false end},BattleSides={other=function() end}}
local player=assert(loadfile('lib/PlayerTrainer.lua'))(V)
local pose=up(up(player.drawBall,'ballPose'),'normalThrowBallPose')
put(pose,'performanceId',function() return 'red' end)
put(pose,'actionKind','throw');put(pose,'actionStrength',1)
local hand={1,4,2};local samples=0
put(pose,'releaseAnchor',function() samples=samples+1;return {hand[1],hand[2],hand[3]} end)
local d=perf.duration('red','throw')
put(pose,'actionAge',.2*d)
local p=pose();assert(p.handAttached and p[1]==1,'wind-up must attach')
hand={2,5,3};put(pose,'actionAge',.31*d);p=pose();assert(p[1]==2,'release origin')
local calls=samples
hand={100,100,100};put(pose,'actionAge',.55*d);p=pose();assert(samples==calls,'airborne ball resampled moving hand')
put(pose,'actionAge',.8*d);assert(pose()==nil,'ball persists past opening')
-- A new accepted throw must clear the previous projectile origin.
local trigger=up(player.event,'trigger');trigger('throw',1,true)
put(pose,'actionAge',.31*d);p=pose();assert(p[1]==100,'new throw retained stale release')
-- Slow frame that skips wind-up still obtains one fixed origin.
trigger('throw',1,true);put(pose,'actionAge',.5*d);pose();calls=samples
put(pose,'actionAge',.6*d);pose();assert(samples==calls,'skipped seam failed to latch')
local base={{0,2,0}};local poses={gesture1={{4,6,8}},gesture2={{8,10,12}}}
local q=rig.mixJointPoint(base,poses,1,{gesture1=.25,gesture2=.25})
assert(q[1]==3 and q[2]==5 and q[3]==5,'source joint interpolation mismatch')
assert(rig.mixJointPoint(nil,nil,1,{})==nil,'missing cache must fall back')
print('Trainer ball tests passed')

local enemy=assert(loadfile('lib/Trainer.lua'))(V)
local ep=up(enemy.drawBall,'ballPose')
put(ep,'performanceId',function() return 'dakim' end)
put(ep,'actionKind','sendout');put(ep,'actionStrength',1)
put(ep,'scene',{jointPositions={{1,4,2}},poseJointPositions={},releaseJoint=1})
put(ep,'idleMotion',function() return {} end)
put(ep,'animatedModel',function() return {1,0,0,10,0,1,0,0,0,0,1,20} end)
enemy.entryPose=function() return {} end
local ed=perf.duration('dakim','sendout')
put(ep,'actionAge',.2*ed);local e=ep()
assert(e.handAttached and e[1]==11 and e[3]==22,'enemy source hand transform')
put(ep,'actionAge',.31*ed);e=ep();assert(e[1]==11,'enemy release')
put(ep,'scene',{jointPositions={{90,4,90}},poseJointPositions={},releaseJoint=1})
put(ep,'actionAge',.4*ed);e=ep();assert(e[1]<30,'enemy flight follows recovering hand')
print('Enemy source hand tests passed')
-- The doubles entry point keeps the source hand/release but redirects the
-- ball to the requested lane for both trainers. Generic throws reset it.
put(player.beginSendout,'activeNow',true)
assert(player:beginSendout({-12,3.85,25}))
put(pose,'actionAge',.79*d);p=pose()
assert(math.abs(p[1]+12)<.001 and math.abs(p[3]-25)<.001,'player ball missed second slot')
trigger('throw',1,true);put(pose,'actionAge',.79*d);p=pose()
assert(math.abs(p[1]+12)>.001,'player lane override leaked to generic throw')
put(enemy.beginSendout,'activeNow',true)
assert(enemy:beginSendout({14,3.85,-25}))
put(ep,'actionAge',.79*ed);e=ep()
assert(math.abs(e[1]-14)<.001 and math.abs(e[3]+25)<.001,'enemy ball missed second slot')
enemy:clearSendoutTarget()
print('Doubles trainer ball target tests passed')
