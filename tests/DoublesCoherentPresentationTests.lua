-- Native logic is separately exercised by tests/doubles/RegressionTests.lua.
-- This fixture drives real Core/Presenter/Waza scheduling with mock actor/GPU
-- boundaries, checking concurrent channels and the detached HP presentation.
local n=0
local function eq(a,b,label)n=n+1;assert(a==b,label..': '..tostring(a)..' ~= '..tostring(b))end
local function yes(a,label)n=n+1;assert(a,label)end
local V={MoveFXVM={hasEntry=function()return true end},WazaAudioRuntime={readyForSpec=function()return true end}}
local Core=assert(loadfile('lib/doubles/Core.lua'))()
V.WazaPhasePolicy=assert(loadfile('lib/WazaPhasePolicy.lua'))(V)
V.WazaSequenceRuntime=assert(loadfile('lib/WazaSequenceRuntime.lua'))(V)
V.CurrentSpriteModels=assert(loadfile('lib/CurrentSpriteModels.lua'))(V)
V.DoublesPresenter=assert(loadfile('lib/doubles/Presenter.lua'))(V)
V.WazaHandlers={models={},effects={},controllers={player={},enemy={}}}
V.DoublesMovePresentation=assert(loadfile('lib/doubles/MovePresentation.lua'))(V)
local M,W,C=V.DoublesMovePresentation,V.WazaSequenceRuntime,V.CurrentSpriteModels
local spec={wazaPhases={{name='attack',complete=true,entries={{index=1,identifier=1,kind='particle',timingPoints={0,0}}}},
 {name='damage',complete=true,entries={{index=1,identifier=1,kind='particle',timingPoints={0,0}}}}}}
V.MoveFXExtractor={peek=function()return spec end}
W:registerHandler('particle','fixture',{
 start=function(_,inst)
  C.moveFxActive[#C.moveFxActive+1]={wazaSerial=inst.serial,vm={done=false}}
  V.WazaHandlers.models['serial:'..inst.serial]={serial=inst.serial}
  return true
 end,
 update=function(_,inst,_,frame)
  if frame<65 then return true end
  for _,fx in ipairs(C.moveFxActive)do fx.vm.done=true end
  return false
 end})
C.updateReleaseFx=function()end
local ids={'player-left','player-right','enemy-left','enemy-right'}
for _,gen in ipairs{1,2}do
 local stats={attack=0,hits={},matrix=0}
 local a={name=function(_,m)return m.species end,maxHP=function()return 100 end,newStages=function()return {}end,
  makeBattler=function(_,s)return {mon=s.mon,stages={}}end,withdraw=function()end,structuralHidden=function()return false end}
 local c=Core.new{id='coherent-'..gen,generation=gen,adapter=a,
  playerParty={{species='A',hp=100},{species='B',hp=100}},enemyParty={{species='C',hp=100},{species='D',hp=100}}}
 c.queue={};c.qhead=1;c.phase='present';c.currentEvent=nil
 local s={generation=gen,actors={},actorOrder={},core=c,screen={game={data={}}},context={arena={player={0,50},enemy={0,-50},figureScale=.38},services={}}}
 for _,id in ipairs(ids)do local slot=c.slots[id]
  local actor={stateDuration=function()return .9 end,wazaTimingPoints=function()return {0,18,54,0}end,matrix=function()stats.matrix=stats.matrix+1 end,
   attack=function(self,_,_,o)stats.attack=stats.attack+1;o.onStarted(self)end,
   hit=function(self,_,o)stats.hits[id]=(stats.hits[id]or 0)+1;o.onStarted(self)end}
  local rec={slot=id,battlerId=slot.battlerId,mon=slot.mon,actor=actor,visible=true}
  s.actors[slot.battlerId]=rec;s.actorOrder[#s.actorOrder+1]=rec
 end
 c.onEvent=function(e)V.DoublesPresenter.event(s,e)end
 local before=c:captureVitals()
 local source=c.slots['player-right']
 local e={kind='move',move=53,moveDef={},slot=source.id,battlerId=source.battlerId,targets={'enemy-left','enemy-right'},targetBattlers={}}
 for _,id in ipairs(e.targets)do e.targetBattlers[id]=c.slots[id].battlerId;c.slots[id].mon.hp=50 end
 source.mon.hp=90 -- separate recoil, not this attack's receiving chapter
 c:enqueue(e);c:recordVitals(before,e)
 eq(#e.impacts,2,'two receiving targets attached, recoil excluded')
 c:presentNext();eq(c.currentEvent,e,'source presented first')
 local originals={W.active,C.moveFxActive,V.WazaHandlers.models,V.WazaHandlers.controllers}
 for i=1,10 do M.update(s,1/60)end
 eq(stats.attack,1,'one attack-body animation');eq(stats.hits['enemy-left'],nil,'no premature target hit')
 eq(c.display[c.slots['enemy-left'].battlerId].hp,100,'HP remains preimpact')
 for i=1,15 do M.update(s,1/60)end
 eq(stats.hits['enemy-left'],1,'left target reacts once');eq(stats.hits['enemy-right'],1,'right target reacts once')
 eq(#s.movePresentation.channels,3,'three concurrent channels')
 yes(not s.movePresentation.channels[1].done,'source still active when targets start')
 eq(c.display[c.slots['enemy-left'].battlerId].hp,50,'impact updates detached display')
 eq(c.slots['enemy-left'].mon.hp,50,'native HP untouched')
 local snap=c:snapshot{view='render'}
 eq(#snap.presentation.impacts,2,'both HUD impacts in snapshot')
 snap.presentation.impacts[1].hp=999
 eq(e.impacts[1].hp,50,'nested impact snapshot detached')
 local serials={}
 for _,ch in ipairs(s.movePresentation.channels)do
  yes(not serials[ch.instance.serial],'channel serial unique');serials[ch.instance.serial]=true
  eq(#ch.world.active,1,'channel owns one active source instance')
 end
 eq(W.active,originals[1],'global sequence list restored');eq(C.moveFxActive,originals[2],'global particles restored')
 eq(V.WazaHandlers.models,originals[3],'global models restored');eq(V.WazaHandlers.controllers,originals[4],'global controller table restored')
 local m=s.movePresentation
 local ok=pcall(M._test.scope,s,m,function()W.active={};C.moveFxActive={};V.WazaHandlers.controllers={};error('injected fault')end)
 yes(not ok,'scope propagates error');eq(W.active,originals[1],'sequence binding restored after error');eq(C.moveFxActive,originals[2],'particles restored after error')
 -- Restore just the deliberately destroyed fixture channel for completion.
 m.world.active={m.instance};m.world.controllers={player={},enemy={}}
 for i=1,150 do M.update(s,1/60)end
 eq(s.movePresentation,nil,'all channels finish');eq(e.presentationPending,nil,'source event unlocks')
 -- The queued recoil still has its own legitimate reaction; paired target
 -- records become zero-duration bookkeeping without another body/source FX.
 c:presentNext();eq(c.currentEvent.kind,'damage','recoil record retained')
 eq(c.currentEvent.presentationConsumed,nil,'recoil not swallowed')
 M.finish(s);local attacks=stats.attack
 c:presentNext();eq(c.currentEvent.presentationConsumed,true,'target bookkeeping acknowledged')
 eq(s.movePresentation,nil,'target not replayed');eq(c.currentEvent.duration,0,'no extra target hold')
 c:presentNext();eq(s.movePresentation,nil,'second target not replayed')
 eq(stats.hits['enemy-left'],1,'left did not flinch twice');eq(stats.hits['enemy-right'],1,'right did not flinch twice')
 eq(stats.attack,attacks,'bookkeeping does not restart source')
 local nextHit={kind='damage',slot='enemy-left',battlerId=c.slots['enemy-left'].battlerId,sourceSlot=source.id,sourceBattlerId=source.battlerId,move=53,amount=1,hp=49}
 M.begin(s,nextHit);M.update(s,.02)
 eq(stats.hits['enemy-left'],2,'later same-move hit is not deduplicated');M.finish(s)
end
-- Attachment memoization is scoped to one update/draw, keyed by actor+joint,
-- including misses. It must not freeze an animated joint between frames.
local count=0
local actor={height=16,attachment=function(_,name)count=count+1;return {position={0,7,count}}end}
local ctx={groundY=0,arena={player={0,50},enemy={0,-50},figureScale=1}}
local records={player={actor=actor},enemy={actor={height=16,attachment=function()return {position={0,7,-50}}end}}}
C:withDoublesPair(ctx,records,function()
 for i=1,40 do C:wazaBasis(ctx,'player','enemy',1,{moveId=53,role='attack',sourceStrict=true})end
end)
local first=count;yes(first<10,'repeated joint work memoized')
C:withDoublesPair(ctx,records,function()C:wazaBasis(ctx,'player','enemy',1,{moveId=53,role='attack',sourceStrict=true})end)
yes(count>first,'new frame reevaluates joints');eq(C.doublesAttachmentMemo,nil,'memo does not leak')
print('DoublesCoherentPresentationTests: '..n..' assertions passed')
