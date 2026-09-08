local AbilityData=assert(loadfile('lib/AbilityData.lua'))()
local A=assert(loadfile('lib/Abilities.lua'))({AbilityData=AbilityData})

-- Single-ability species: always the same id regardless of dvs/otId.
local mon1={dvs={attack=1,defense=1,speed=1,special=1},otId=111}
local mon2={dvs={attack=15,defense=15,speed=15,special=15},otId=99999}
assert(A.resolve(mon1,1)=='OVERGROW','single-ability species varied with mon1')
assert(A.resolve(mon2,1)=='OVERGROW','single-ability species varied with mon2')

-- Dual-ability species (dex 58, Growlithe: Flash Fire / Intimidate) must
-- actually vary across different dvs/otId combinations, and every result
-- must be one of the two listed options.
local options=A.speciesOptions(58)
assert(#options==2,'expected dex 58 to have 2 ability options')
local seen={}
for otId=1,40 do
 local mon={dvs={attack=otId%16,defense=(otId*3)%16,speed=(otId*7)%16,special=(otId*11)%16},otId=otId}
 local id=A.resolve(mon,58)
 assert(id==options[1] or id==options[2],'resolved id not one of the two listed options: '..tostring(id))
 seen[id]=true
end
assert(seen[options[1]] and seen[options[2]],'dual-ability resolution never varied across 40 sampled mons')

-- Determinism: same inputs always resolve to the same output.
local monA={dvs={attack=5,defense=6,speed=7,special=8},otId=4242}
local first=A.resolve(monA,58)
for i=1,20 do assert(A.resolve(monA,58)==first,'resolve is not deterministic') end

-- Resolution is read-only; explicit external abilities remain authoritative.
local monB={dvs={attack=3,defense=3,speed=3,special=3},otId=1}
local id=A.ensure(monB,58)
assert(id==A.resolve(monB,58))
assert(monB.abilityId==nil and monB.abilityName==nil,'resolver must not stamp a save')
assert(A.ensure(monB,1)=='OVERGROW','evolution/species re-resolution stuck on previous species')
monB.abilityId='TRACE';assert(A.ensure(monB,58)=='TRACE','known external assignment discarded')
monB.abilityId='OTHER_MOD_CUSTOM';assert(A.ensure(monB,58)==nil,'unknown external assignment replaced with a guess')
local b={save={colosseumBattle={abilitiesEnabled=true}}};monB.abilityId='TRACE'
A.runtime(b,monB).trace='INTIMIDATE'
assert(A.current(b,monB,58)=='INTIMIDATE' and monB.abilityId=='TRACE','temporary copy leaked to save')
A.reset(b,monB);assert(A.current(b,monB,58)=='TRACE','Trace failed to clear')
b.save.colosseumBattle.abilitiesEnabled=false;assert(A.current(b,monB,58)==nil,'OFF exposed active mechanics')
for _,flag in ipairs({'link','spectator','demo','safari','ghost','inBattleTowerBattle','tutorial'})do
 b.save.colosseumBattle.abilitiesEnabled=true;b[flag]=true
 assert(not A.enabledBattle(b),'excluded battle enabled: '..flag);b[flag]=nil
end

-- Species-only label formatting (Pokedex dossier path: no live mon).
local single=A.speciesLabel(1)
assert(single=='Overgrow','unexpected single-ability label: '..tostring(single))
local dual=A.speciesLabel(58)
assert(dual:find('/')~=nil,'dual-ability species label missing separator: '..tostring(dual))

-- Contact move table sanity.
assert(A.isContactMove('TACKLE')==true,'TACKLE should be a contact move')
assert(A.isContactMove('THUNDERBOLT')~=true,'THUNDERBOLT should not be a contact move')
assert(A.isContactMove(nil)~=true,'nil moveId must not be treated as contact')

-- enabled() reads the same save shape BattleSettings.lua manages.
assert(A.enabled(nil)~=true,'enabled() must be false with no game/save')
assert(A.enabled({save={colosseumBattle={abilitiesEnabled=true}}})==true,'enabled() did not read true from save')
assert(A.enabled({save={colosseumBattle={abilitiesEnabled=false}}})~=true,'enabled() did not read false from save')

print('AbilitiesResolverTests: dual-ability spread, determinism, ensure() idempotency, labels, enabled() OK')
