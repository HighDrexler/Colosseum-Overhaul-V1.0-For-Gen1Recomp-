local rows={
 {kind='model',identifier=1,index=1,anchorEntry=0,anchorPoint=0,localPoint=0,timingPoints={0,30},modelAsset={cache='ball'}},
 {kind='particle',identifier=2,index=2,anchorEntry=1,anchorPoint=1,localPoint=0,timingPoints={0,20,80}},
 {kind='type1',identifier=3,index=3,anchorEntry=2,anchorPoint=1,localPoint=0,timingPoints={0}},
}
local spec={wazaPhases={{name='open',entries=rows}},generatorPrograms={}}
local starts,draws=0,0
local V={MoveFXExtractor={peek=function(_,move)assert(move.name=='monsterball');return spec end},
 DoublesPresenter={anchor=function()return 12,20 end},
 CurrentSpriteModels={stageReleaseParticles=function(_,ctx,side,view,e,g)
  starts=starts+1;assert(side=='enemy' and g.origin[1]==24 and g.origin[3]==40,'wrong slot/world conversion')
 end},WazaHandlers={drawAsset=function(_,asset,vp,m,frame)
  draws=draws+1;assert(m[4]==12 and m[12]==20,'source ball left its slot');return true
 end}}
V.WazaPhasePolicy=assert(loadfile('lib/WazaPhasePolicy.lua'))(V)
V.WazaSequenceRuntime=assert(loadfile('lib/WazaSequenceRuntime.lua'))(V)
local R=assert(loadfile('lib/doubles/ReleasePresentation.lua'))(V)
local s={context={groundY=0,services={figureScale=.5,stageVP={}}},actorOrder={}}
local r={visible=true,slot='enemy-right',mon={},actor={height=16,worldScale=1}};s.actorOrder={r}
R.begin(s,r)
assert(r.release.entries[2].startFrame==30 and r.release.entries[3].startFrame==50,'source dependency timing lost')
assert(rows[2].resolvedStartFrame==nil,'cached timeline mutated')
R.update(s,r,.25);R.draw(s,s.context);assert(starts==0 and draws==1)
R.update(s,r,.26);assert(starts==1 and r.actor.releaseFlash==1)
R.update(s,r,.1);assert(starts==1,'particle entry started twice')
R.update(s,r,1);assert(r.actor.releaseFlash==0,'white flash persisted')
R.finish(s,r);assert(r.release==nil and r.actor.releaseFlash==0)
print('ReleasePresentationTests: source timing, one-shot launch, slot geometry and cleanup OK')
