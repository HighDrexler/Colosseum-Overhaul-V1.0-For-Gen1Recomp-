local n=0
local function eq(a,b,tag)n=n+1;assert(a==b,tag..': '..tostring(a)..' ~= '..tostring(b))end
local chosen,launches={},{}
local spec={wazaPhases={
 {name='attack',sequenceKind=1,entries={{kind='particle'}}},
 {name='pikachu',sequenceKind=3,entries={{kind='particle'}}},
 {name='special',sequenceKind=6,entries={{kind='particle'}}},
 {name='damage',sequenceKind=9,entries={{kind='particle'}}}
}}
local V={ColosseumDex={species={[25]={'pikachu'},[9]={'kamex'}}},MoveFXExtractor={peek=function()return spec end},WazaAudioRuntime={readyForSpec=function()return true end}}
V.WazaPhasePolicy=assert(loadfile('lib/WazaPhasePolicy.lua'))(V)
V.CurrentSpriteModels=assert(loadfile('lib/CurrentSpriteModels.lua'))(V)
local C=V.CurrentSpriteModels
C.startDoublesWaza=function(_,ctx,view,opts)
 launches[#launches+1]={view=view,opts=opts}
 return {done=true}
end
C.clearDoublesWaza=function()end;C.updateReleaseFx=function()end
V.WazaSequenceRuntime={isBusy=function()return false end,update=function()end}
V.DoublesPresenter=assert(loadfile('lib/doubles/Presenter.lua'))(V)
local P=V.DoublesPresenter
V.DoublesMovePresentation=assert(loadfile('lib/doubles/MovePresentation.lua'))(V)
local M=V.DoublesMovePresentation
local function actor(dex)
 return {dex=dex,stateDuration=function()return 2.5 end,wazaTimingPoints=function()return {0,15,80,150}end,
 attack=function(self,move,def,opts)chosen[#chosen+1]={dex=dex,role='attack',opts=opts};opts.onStarted(self)end,
 hit=function(self,ev,opts)chosen[#chosen+1]={dex=dex,role='damage',opts=opts};opts.onStarted(self)end}
end
local source={slot='player-right',battlerId='source-1',actor=actor(25),mon={species='PIKACHU'}}
local target={slot='enemy-left',battlerId='target-1',actor=actor(9),mon={species='BLASTOISE'}}
local s={generation=1,screen={game={data={}}},context={arena={player={0,20},enemy={0,-20}},services={}},actors={['source-1']=source,['target-1']=target},core={slots={['player-right']={battlerId='source-1'},['enemy-left']={battlerId='target-1'}}}}
local function begin(kind,stage)
 local e={kind=kind,slot=kind=='move' and source.slot or target.slot,battlerId=kind=='move' and source.battlerId or target.battlerId,
 sourceSlot=source.slot,sourceBattlerId=source.battlerId,targets={target.slot},targetBattlers={[target.slot]=target.battlerId},move='TEST',moveDef={},stage=stage,amount=10,hp=20}
 M.begin(s,e);M.update(s,.05);return e
end
local e=begin('move','attack')
eq(chosen[#chosen].opts.nativeSlot,'physicalB','species bank overrides generic bank')
eq(chosen[#chosen].opts.sourceSequenceKind,3,'same bank kind handed to actor')
eq(launches[#launches].view.phaseSelection.attack,'pikachu','attacker-specific source chapter')
eq(launches[#launches].opts.presentationFrames,150,'source body duration provides FX frames')
eq(launches[#launches].opts.globalTimingPoints[3],80,'body bank timing points reach scheduler')
eq(e.presentationPending,true,'event waits for body even if FX ended')
for i=1,15 do M.update(s,.1)end
eq(e.presentationPending,true,'no legacy one-second timeout')
for i=1,15 do M.update(s,.1)end
eq(e.presentationPending,nil,'event unlocks after body')
e=begin('move','charge')
eq(chosen[#chosen].opts.nativeSlot,'specialB','charge selects source special bank')
eq(launches[#launches].view.phaseSelection.attack,'special','charge chapter not attack chapter')
eq(launches[#launches].view.phaseSelection.stage,'charge','charge stage preserved')
e=begin('damage','attack')
eq(chosen[#chosen].dex,9,'target performs its reaction')
eq(chosen[#chosen].opts.nativeSlot,'damageHeavy','source damage sequence selects reaction bank')
eq(launches[#launches].view.phaseSelection.dex,25,'damage source uses attacker species not target species')
M.finish(s)
-- A queued event retains its captured actor even when the slot is occupied anew.
local newTarget={slot=target.slot,battlerId='target-2',actor=actor(25),mon={species='PIKACHU'}}
s.actors['target-2']=newTarget;s.core.slots[target.slot].battlerId='target-2'
e=begin('damage','attack')
eq(chosen[#chosen].dex,9,'replacement never lends body to outgoing damage')
M.finish(s)
-- Faint/recall completion follows actor clocks, including queued hurt->faint.
local releaseCount=0
local a={faintAge=0,pendingFaint=true,terminalDuration=function()return 2.8 end,
 faint=function()end,release=function()releaseCount=releaseCount+1 end,
 update=function(self,dt)if not self.pendingFaint then self.faintAge=self.faintAge+dt end end}
local r={slot='enemy-left',battlerId='f',actor=a,mon={},visible=true,attempted=true}
local session={actors={f=r},actorOrder={r},visualClock=0,context={}}
local ev={kind='faint',slot=r.slot,battlerId='f'}
P.event(session,ev)
for i=1,20 do P.update(session,.1)end
eq(releaseCount,0,'queued faint never retires behind hurt clip');eq(ev.presentationPending,true,'queued terminal holds')
a.pendingFaint=nil
for i=1,20 do P.update(session,.1)end
eq(releaseCount,0,'long source faint not truncated')
for i=1,10 do P.update(session,.1)end
eq(releaseCount,1,'terminal actor released once');eq(ev.presentationPending,nil,'terminal gate cleared')
P.update(session,.1);eq(#session.actorOrder,0,'retired actor removed')
print('DoublesSourceTimingIntegrationTests: '..n..' assertions passed')
