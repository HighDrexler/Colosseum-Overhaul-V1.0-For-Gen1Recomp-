local V={ColosseumDex={species={[249]={'lugia'}}}}
local P=assert(loadfile('lib/WazaPhasePolicy.lua'))(V);V.WazaPhasePolicy=P
local function phase(name,n,broken)
 local entries={};for i=1,n do entries[i]={kind='sound',identifier=i,anchorEntry=0,timingPoints={0}} end
 return {name=name,complete=not broken,entries=entries}
end
local spec={style='projectile',wazaPhases={phase('attack',9),phase('sp1',9,true),phase('special',2),phase('damage',3),phase('damage2',4),phase('lugia',6)},generatorPrograms={}}
for _,ph in ipairs(spec.wazaPhases)do spec.generatorPrograms[#spec.generatorPrograms+1]={phase=ph.name} end
local W=assert(loadfile('lib/WazaSequenceRuntime.lua'))(V)
local selected=P.select(spec)
assert(#W._test.phaseEntries(spec,'attack')==9,'alternative banks layered onto attack')
assert(#W._test.phaseEntries(spec,'damage')==3,'numbered damage banks layered onto hit')
assert(W:canOwn(spec,'attack'),'unselected broken alternate blocks executable primary')
assert(#spec.wazaPhases==6 and #spec.generatorPrograms==6,'selection mutated shared cache')
assert(#selected.generatorPrograms==2 and P.select(spec)==selected,'selected program cache not reused')
assert(P.select(spec,{dex=249}).phaseSelection.attack=='lugia','species override missing')
assert(P.select(spec,{stage='charge'}).phaseSelection.attack=='special','explicit charge selection missing')
assert(P.select(spec,{hitIndex=2}).phaseSelection.damage=='damage','numbered variant guessed from hit ordinal')
assert(P.select(spec,{damagePhase='damage2'}).phaseSelection.damage=='damage2','explicit damage variant unavailable')
assert(P.role('damage6')=='damage','numbered damage treated as attack')

-- A queued hit hands the initialized native reaction to the effect scheduler
-- exactly once, and the lethal reaction still completes before faint.
local Actors=assert(loadfile('lib/PokemonActors.lua'))({})
local a=Actors._test.Actor.new(246,'normal',{actions={damage={groups={{}},duration=.10},faint={groups={{}},duration=.30}},bounds={min={0,0,0},max={1,1,1}}},{})
local calls=0
local opts={onStarted=function(actor,sampled,slot)
 calls=calls+1;assert(actor==a and sampled and slot=='damage' and a.state=='hit')
end}
local first={damage=10,target={hp=10,maxHP=20}}
local lethal={damage=10,target={hp=0,maxHP=20}}
assert(select(2,a:hit(first,opts))=='started' and calls==1)
assert(select(2,a:hit(first,opts))=='duplicate' and calls==1)
assert(select(2,a:hit(lethal,opts))=='queued' and calls==1,'damage FX fired before queued body reaction')
a:update(.11);assert(calls==2 and a.state=='hit','queued damage FX never started')
a:update(.11);assert(calls==2 and a.state=='faint','faint interrupted or repeated damage handoff')

-- Empty retail WZX chapters still carry a valid root; missing concrete rows
-- must remain rejected when the declared count requires them.
local X=assert(loadfile('extract/WazaSequenceExtractor.lua'))({})
local function empty(count)return string.rep('\0',0x74)..string.char(0,0,0,count)..string.rep('\0',0xA0-0x78) end
local parsed=assert(X.parse(empty(1),{phase='damage'}))
assert(parsed.complete and parsed.parsedCount==0 and parsed.root)
assert(not X.parse(empty(2),{phase='damage'}),'truncated nonempty WZX accepted')

-- All shared shot families hold their composition through a chapter; the
-- damage chapter cuts to the defender, for either attacking side.
for _,side in ipairs({'player','enemy'})do
 for _,style in ipairs({'projectile','wave','contact','aura','self','target','impact'})do
  local inst={serial=1,presentationSerial=1,role='attack',side=side,target=side=='player' and 'enemy' or 'player',frame=1,sourceEndFrame=100,spec={style=style},entries={}}
  local H=assert(loadfile('lib/WazaHandlers.lua'))({WazaSequenceRuntime={active={inst}},CurrentSpriteModels={wazaBasis=function(_,ctx,origin)
   local z=origin=='player' and 0 or 100
   return {origin={0,5,z},target={0,5,100-z},forward={0,0,z==0 and 1 or -1},right={1,0,0},fightDistance=100,sourceVisualHeight=10,targetVisualHeight=10}
  end}})
  local start=assert(H.cameraPose({}));inst.frame=99;local finish=assert(H.cameraPose({}))
  for i=1,3 do assert(start.eye[i]==finish.eye[i] and start.focus[i]==finish.focus[i],'unrelated sweep or shake in '..style) end
  inst.serial=2;inst.role='damage';local hit=assert(H.cameraPose({}))
  assert(hit.cut and hit.focus[3]==(side=='player' and 100 or 0),'damage camera did not cut to defender')
 end
end
print('MoveFXSweepTests: OK')
