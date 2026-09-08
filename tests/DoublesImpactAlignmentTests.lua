-- Timing contracts use actual production modules; GPU/actor boundaries here
-- are controlled fixtures. Source-backed integration runs remain separate.
local n=0
local function eq(a,b,k)n=n+1;assert(a==b,k..': '..tostring(a)..' ~= '..tostring(b))end
local function yes(a,k)n=n+1;assert(a,k)end
local V={};local M=assert(loadfile('lib/doubles/MovePresentation.lua'))(V)
V.CurrentSpriteModels={particleTransitSpan=function(_,id,role,e)return e.span or 100 end}
local m={awaitTransit=true,chapterAge=20,impactTime=1,instance={},spec={moveId=59},world={particles={}}}
eq(M._test.readyForImpact(m),false,'clock alone cannot short-circuit a live traveling core')
local fx={wazaEntry={span=60},vm={particles={{alive=true,position={0,0,53}}}}};m.world.particles={fx}
eq(M._test.readyForImpact(m),false,'not yet at destination')
fx.vm.particles[1].position[3]=54
eq(M._test.readyForImpact(m),true,'leading edge starts receiving at 90% lane');eq(m.impactTimingSource,'source-particle-arrival','arrival evidence')
fx.vm.particles[1].alive=false;eq(M._test.readyForImpact(m),false,'dead particles cannot trigger')
fx.vm.particles[1].alive=true;fx.modelLinked=true;eq(M._test.readyForImpact(m),false,'model attachments not treated as lane cores')
fx.modelLinked=nil;fx.wazaEntry.span=nil;eq(M._test.readyForImpact(m),false,'muzzle/impact particles do not trigger travel')
m.done=true;eq(M._test.readyForImpact(m),true,'exhausted asset cannot deadlock')
m.done=nil;m.instance=nil;eq(M._test.readyForImpact(m),true,'uncached provider can safely fall back')
eq(M._test.readyForImpact{awaitTransit=false,chapterAge=.2,impactTime=.3},false,'other effects retain authored timing')
eq(M._test.readyForImpact{awaitTransit=false,chapterAge=.3,impactTime=.3},true,'other effects start at authored boundary')
-- Receiver Waza starts at the current impact, not at impact + PKX time-zero.
local Core=assert(loadfile('lib/doubles/Core.lua'))()
local observed,bodyCalls,mutated= {},0,false
local W={active={},serial=0,update=function()end}
V.WazaSequenceRuntime=W;V.WazaHandlers={models={},effects={},controllers={player={},enemy={}}}
V.DoublesPresenter={actorAnchor=function(_,id)if id=='player-left'then return 0,50,0,-1 else return 0,-50,0,1 end end}
local spec={moveId=58};V.MoveFXExtractor={peek=function()return spec end};V.WazaPhasePolicy={select=function(s)return s end};V.WazaAudioRuntime={readyForSpec=function()return true end}
V.CurrentSpriteModels={moveFxActive={},withDoublesPair=function(_,ctx,actors,fn)return fn(ctx)end,
 sourceNativeSlot=function()return 1 end,startDoublesWaza=function(_,ctx,s,o)
  observed[#observed+1]=o;W.serial=W.serial+1;local i={serial=W.serial,done=false};W.active[#W.active+1]=i;return i
 end,updateReleaseFx=function()end,hasDoublesWazaParticles=function()return false end}
local points={130,220,0,0}
local attacker={dex=6,stateDuration=function()return 4 end,wazaTimingPoints=function()return {120,150,240,0}end,attack=function(self,_,_,o)o.onStarted(self)end}
local receiver={dex=19,stateDuration=function()return 220/60 end,wazaTimingPoints=function()return points end,hit=function(self,_,o)bodyCalls=bodyCalls+1;o.onStarted(self)end}
local e={eventId=1,kind='move',slot='player-left',battlerId='a',move=58,moveDef={},targets={'enemy-left'},targetBattlers={['enemy-left']='b'}}
local imp={eventId=2,impactOf=1,kind='damage',slot='enemy-left',battlerId='b',sourceSlot='player-left',sourceBattlerId='a',move=58,moveDef={},amount=40,hp=60}
e.impacts={imp}
local c={currentEvent=e,slots={['player-left']={battlerId='a'},['enemy-left']={battlerId='b'}},display={b={hp=100}},bump=function()end,presentImpact=Core.presentImpact}
local s={actors={a={actor=attacker},b={actor=receiver}},core=c,screen={game={data={}}},context={arena={},services={}},generation=1}
M.begin(s,e);for i=1,149 do M.update(s,1/60)end
eq(bodyCalls,0,'no receiver before authored primary impact');M.update(s,1/60);M.update(s,1/60)
eq(bodyCalls,1,'one target body request');eq(observed[1].role,'attack','source channel retained');eq(observed[2].role,'damage','receiving role preserved')
eq(observed[2].globalTimingPoints[1],0,'receiver primary time-zero rebased')
eq(observed[2].globalTimingPoints[2],90,'relative receiving duration preserved')
eq(points[1],130,'native PKX timings not mutated');eq(points[2],220,'native clip clock not modified')
eq(s.movePresentation.channels[2].bodyDuration,220/60,'body not accelerated');eq(c.display.b.hp,60,'same impact starts detached HP change')
eq(imp.presentationConsumed,true,'later queued receiving record cannot replay')
-- Per-entry ribbon mesh reuse: no per-frame GPU allocation/release churn.
local frame=0;local C={wazaBasis=function(_,ctx,a,b,part)return {origin={part or 1,2,frame}}end,
 projectWazaWorld=function(_,ctx,p)return p[1]+p[3],p[2]end}
local H=assert(loadfile('lib/WazaHandlers.lua')){CurrentSpriteModels=C}
local counts={built=0,released=0,draws=0,uploads=0}
local g={newMesh=function(fmt,capacity,mode,usage)
 counts.built=counts.built+1;assert(type(capacity)=='number' and mode=='strip' and usage=='stream')
 return {setVertices=function(_,v)assert(#v<=capacity);counts.uploads=counts.uploads+1 end,
 setDrawRange=function(_,first,num)assert(first==1 and num<=capacity)end,setTexture=function()end,
 release=function()counts.released=counts.released+1 end}
 end,draw=function()counts.draws=counts.draws+1 end}
local rec={instance={spec={},role='attack',side='player',target='enemy'},history={},context={}}
for i=1,1000 do frame=i;rec.instance.frame=i;H._test.drawTraceRibbon(g,{},rec,{partA=1,partB=2,maxSegments=24},1)end
yes(counts.built<=4,'1000 ribbon frames bounded to capacity growth');eq(counts.draws,999,'every populated ribbon draws');eq(counts.uploads,999,'geometry still animates every frame')
eq(rec.traceCapacity,64,'bounded reusable capacity');eq(#rec.history,24,'history remains bounded')
H._test.releaseDynamicMeshes(rec);eq(counts.released,counts.built,'all reusable buffers released');eq(rec.dynamicMeshes,nil,'no retained buffer after finish')
print('DoublesImpactAlignmentTests: '..n..' assertions passed; 1000-frame ribbon workload')
