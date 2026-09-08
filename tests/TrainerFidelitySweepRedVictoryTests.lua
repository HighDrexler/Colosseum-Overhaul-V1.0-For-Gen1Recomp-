local P=assert(loadfile('lib/TrainerPerformance.lua'))({})
local checks=0
local function check(v,label)checks=checks+1;assert(v,label)end
local oldLove=love
local function mesh()
 return {setVertices=function(self,data)self.bytes=data.bytes end,
  attachAttribute=function(self,name,buffer)self[name]=buffer end,release=function()end}
end
love={graphics={newMesh=mesh},data={newByteData=function(bytes)return {bytes=bytes,release=function()end}end}}
local function clip(value)
 return {count=3,endFrame=2,groups={{vertices=3,path='clip'..value}},bytes={string.rep(string.char(value),3*24*3)}}
end
local idle,victory,throw,defeat=clip(11),clip(22),clip(33),clip(44)
local track={version=1,fps=60,roles={idle=idle,victory=victory,throw=throw,defeat=defeat,gesture=victory,reaction=defeat}}
local M=assert(loadfile('lib/TrainerMorph.lua'))({RuntimeMeshCache={readLua=function()return track end},GeneratedAssets={read=function()end}})
for _,side in ipairs({'player','enemy'})do
 local groups={{mesh=mesh()}}
 check(M.loadTracks('red',groups)==track,'native trainer fixture did not bind')
 local state=P.newState('red')
 -- Start from a real active gesture so the result transition must clear old
 -- fallback weights as well as avoid selecting the native victory track.
 P.step(state,'red',3,'throw',P.duration('red','throw')*.5,1,side,1/60)
 for i=0,90 do
  local age=4+i/30;local actionAge=math.min(i/30,P.duration('red','victory'))
  local motion;motion,state=P.step(state,'red',age,'victory',actionAge,1,side,1/30)
  check(motion.nativeKind==nil,'Red result selected an action track')
  check(motion.nativeAge==age,'Red idle playback clock stopped during held victory')
  for _,key in ipairs(M.ACTION_KEYS)do check(motion[key]==0,'Red victory retained fallback '..key)end
  local _,_,_,_,role=M.trackSample(track,motion.nativeKind,motion.nativeAge,motion.nativeActionAge,motion.nativeDuration)
  check(role=='idle','Red result sample did not resolve idle')
  M.bindPair(groups,motion)
  check(motion.nativeBound and groups[1].nativeClip==idle,'Red native frame binding selected victory')
  check(groups[1].nativeBuffers[1].bytes:byte(1)==11,'Red result uploaded a victory/throw pose')
 end
 M.releaseTracks(groups)
 local direct=P.motion('red','victory',.6,1,side)
 check(direct.command==0 and direct.arm==0 and direct.turn==0,'direct fallback still gestures for Red victory')
 for _,kind in ipairs({'throw','defeat'})do
  local motion=P.idle('red',4,kind,P.duration('red',kind)*.5,1,side)
  check(motion.nativeKind==kind,'Red '..kind..' changed')
  local selected=M.trackSample(track,motion.nativeKind,4,motion.nativeActionAge,motion.nativeDuration)
  check(selected==(kind=='throw' and throw or defeat),'Red '..kind..' source track changed')
  local sum=0;for _,key in ipairs(M.ACTION_KEYS)do sum=sum+motion[key]end
  check(sum>0,'Red '..kind..' sparse source fallback removed')
 end
end
for _,id in ipairs({'leaf','wes','brendan','may','cooltrainer_m','cooltrainer_f','dakim','nascour','miror_b'})do
 local motion=P.idle(id,4,'victory',P.duration(id,'victory')*.5,1,'player')
 check(motion.nativeKind=='victory','other trainer victory was replaced: '..id)
 check(M.trackSample(track,motion.nativeKind,4,motion.nativeActionAge,motion.nativeDuration)==victory,'other native victory changed: '..id)
 local sum=0;for i=1,5 do sum=sum+motion['gesture'..i]end;check(sum>0,'other victory fallback changed: '..id)
end
check(P.terminal('victory'),'victory no longer terminal')
check(not P.shouldTrigger({},'victory',20,'command',P.duration('red','victory')),'terminal result can be overwritten')
check(P.idle('RED',4,'victory',.5,1,'player').nativeKind==nil,'canonical Red identity was not normalized')
love=oldLove
print('TrainerFidelitySweepRedVictoryTests: '..checks..' assertions passed; Red neutral native idle and zero gesture fallback, held terminal result, both trainer sides, other actions/trainers preserved')
return true
