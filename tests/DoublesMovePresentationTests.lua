local nativeSounds,launches,attacks,hits=0,0,0,0
local spec={wazaPhases={{name='attack',complete=false,entries={
 {kind='model',index=1,identifier=1,timingPoints={0,30}},
 {kind='particle',index=2,identifier=2,anchorEntry=1,anchorPoint=1,timingPoints={0,8}},
 }},{name='damage',complete=true,entries={{kind='particle',index=1,identifier=1,timingPoints={0,8}}}}}}
local V={MoveFXExtractor={peek=function()return spec end},MoveFXVM={hasEntry=function()return true end},
 WazaAudioRuntime={readyForSpec=function()return false end},
 engineRequire=function(name)
  if name=='src.core.Sound' then return {playMove=function(_,anim)assert(anim.sound=='test');nativeSounds=nativeSounds+1 end}end
  error('unexpected module')
 end}
V.WazaPhasePolicy=assert(loadfile('lib/WazaPhasePolicy.lua'))(V)
V.WazaSequenceRuntime=assert(loadfile('lib/WazaSequenceRuntime.lua'))(V)
local W=V.WazaSequenceRuntime
W:registerHandler('particle','test',{start=function()launches=launches+1;return true end,update=function(_,inst,entry,frame,state)return frame-state.startFrame<8 end})
V.CurrentSpriteModels=assert(loadfile('lib/CurrentSpriteModels.lua'))(V)
local CSM=V.CurrentSpriteModels
-- Keep real pair scoping/cleanup, observe the scheduler without requiring GPU assets.
CSM.startDoublesWaza=function(_,ctx,view,opts)
 assert(CSM.stadiumActors.player.slot=='enemy-right','attacker identity lost')
 assert(CSM.stadiumActors.enemy.slot=='player-left','target identity lost')
 return W:start(ctx,'player',view,opts)
end
CSM.updateReleaseFx=function()end
V.DoublesPresenter=assert(loadfile('lib/doubles/Presenter.lua'))(V)
local M=assert(loadfile('lib/doubles/MovePresentation.lua'))(V);V.DoublesMovePresentation=M
local function actor()
 return {stateDuration=function()return .5 end,wazaTimingPoints=function()return {0,0,0,0}end,
  matrix=function()end,attack=function(self,move,def,opts)attacks=attacks+1;opts.onStarted(self)end,
  hit=function(self,p,opts)hits=hits+1;opts.onStarted(self)end}
end
local src={slot='enemy-right',actor=actor(),mon={species='A'}};local dst={slot='player-left',actor=actor(),mon={species='B'}}
local s={generation=1,screen={game={data={}}},actors={a=src,b=dst},
 core={slots={['enemy-right']={battlerId='a'},['player-left']={battlerId='b'}}},
 context={arena={player={0,50},enemy={0,-50},figureScale=.34},services={}}}
-- Source aliases are temporary. Every update/draw must derive geometry from
-- the original four-slot arena, never from the previously rebound pair.
for _,rec in ipairs({src,dst})do
 local x,z,dx,dz=V.DoublesPresenter.actorAnchor(s.context,rec.slot)
 rec.actor.matrix=function(_,px,py,pz,pdx,pdz)
  assert(math.abs(px-x)<1e-9 and math.abs(pz-z)<1e-9,'effect anchor drifts between frames')
  assert(math.abs(pdx-dx)<1e-9 and math.abs(pdz-dz)<1e-9,'effect facing changed with alias rebinding')
 end
end
local original=CSM.stadiumActors
local e={kind='move',slot='enemy-right',targets={'player-left','player-right'},move=53,moveDef={anim={sound='test'}}}
M.begin(s,e);M.update(s,.05)
assert(attacks==1 and e.presentationPending and nativeSounds==1,'attack/body/audio not started')
assert(s.movePresentation.instance.partial and #s.movePresentation.instance.skipped==1,'unsupported sibling suppresses entire move')
for i=1,40 do M.update(s,.05)end
assert(launches==1 and not e.presentationPending and not s.movePresentation,'source timing failed to finish')
assert(CSM.stadiumActors==original,'pair bindings leaked into singles')
e={kind='damage',slot='player-left',sourceSlot='enemy-right',move=53,moveDef={},amount=5,hp=20}
M.begin(s,e);for i=1,40 do M.update(s,.05)end
assert(hits==1 and launches==2 and nativeSounds==1,'impact lost its attacking move or replayed attack audio')
assert(not e.presentationPending)
local ok=pcall(CSM.withDoublesPair,CSM,{}, {},function()error('test')end)
assert(not ok and CSM.stadiumActors==original,'failed renderer leaked pair bindings')
assert(not W:canOwn(spec,'attack'),'partial doubles playback changed strict singles ownership')
print('DoublesMovePresentationTests: attack, delayed source FX, impact, audio fallback, holds and scoped identities OK')
