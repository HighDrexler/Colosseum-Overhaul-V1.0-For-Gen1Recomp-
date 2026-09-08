-- Execute the actual released UI bridge helpers, isolated from drawing only.
-- Tests both missing/old producers and malformed optional ability exports.
local root=os.getenv('UI_COMPAT_DIR')or'.';local cbe=os.getenv('CBE_DOUBLES_MOD_DIR')or'../cbe'
-- Colosseum Overhaul merge: the paired UI's main.lua now ships as UIMain.lua
-- (this merged mod's own main.lua is CBE's original file, verbatim, with a
-- small bootstrap appended -- see main.lua's own trailing comment).
local f=assert(io.open(root..'/UIMain.lua','rb'));local source=f:read('*a');f:close()
local block=assert(source:match('(function GoldCompat%.cbeAbilitiesBridge%(%).-\nend)\n\nfunction DexUI%.memoAbilityLabel'))
local found;local GC={findLoadedMod=function()return found end};local env=setmetatable({GoldCompat=GC},{__index=_G})
local chunk=assert(loadstring(block));setfenv(chunk,env);chunk()
local Data=assert(loadfile(cbe..'/lib/AbilityData.lua'))();local A=assert(loadfile(cbe..'/lib/Abilities.lua')){AbilityData=Data}
local n=0;local function eq(tag,a,b)n=n+1;assert(a==b,tag..': '..tostring(a)..' ~= '..tostring(b))end
local game={save={colosseumBattle={abilitiesEnabled=true}},data={}}
local function bridge()return{version=1,enabled=function()return A.enabled(game)end,resolve=function(mon,def)return A.ensure(mon,A.dexOf(mon,def))end,nameFor=A.displayName,speciesLabel=A.speciesLabel}end
for _,gen in ipairs{'gen1','gen2'}do
 GC.generation=gen;local absent=gen=='gen2'and'NOT USED IN GEN II'or'NOT USED IN GEN I'
 found=nil;eq(gen..' no CBE producer',GC.abilityLabel(game,{},{dex=58}),absent)
 eq(gen..' cache key ON',GC.cbeAbilitySetting(game),true)
 found={exports={abilities=bridge()}};local api=found.exports.abilities
 local mon={otId=3,dvs={attack=3,defense=4,speed=5,special=6}};local def={dex=58}
 eq(gen..' individual resolved label',GC.abilityLabel(game,mon,def),A.displayName(A.resolve(mon,58)):upper())
 eq(gen..' no saved mutation',mon.abilityId,nil)
 eq(gen..' dex both slots label',GC.abilityLabel(game,nil,def),A.speciesLabel(58):upper())
 eq(gen..' existing external display priority',GC.abilityLabel(game,{abilityName='External custom'},def),'EXTERNAL CUSTOM')
 game.save.colosseumBattle.abilitiesEnabled=false;eq(gen..' cache key OFF',GC.cbeAbilitySetting(game),false);eq(gen..' toggle OFF fallback',GC.abilityLabel(game,mon,def),absent);game.save.colosseumBattle.abilitiesEnabled=true
 for _,field in ipairs{'enabled','resolve','nameFor','speciesLabel'}do
  local old=api[field];api[field]=function()error('bad optional export')end
  local subject=mon;if field=='speciesLabel'then subject=nil end
  eq(gen..' throwing '..field,GC.abilityLabel(game,subject,def),absent);api[field]=old
 end
 local old=api.nameFor;api.nameFor=function()return{}end;eq(gen..' malformed name',GC.abilityLabel(game,mon,def),absent);api.nameFor=old
 api.version=99;eq(gen..' incompatible bridge version',GC.abilityLabel(game,mon,def),absent)
 -- Display enrichment keeps full individual seed and existing authoritative
 -- ability labels for non-leading/duplicate-species party identities.
 local C=assert(loadfile(root..'/lib/DoublesDisplayCompat.lua'))()
 local m1={species='S',otId=10,dvs={attack=3},abilityName='One',hp=30,moves={}}
 local m2={species='S',otId=11,dvs={attack=4},abilityName='Two',hp=25,moves={}}
 game.save.party={m1,m2};game.data.pokemon={S={dex=58,types={'FIRE'}}}
 local s={generation=gen=='gen2'and 2 or 1,slots={{id='player-left',side='player',partyIndex=2,portrait={species='S',hp=25}}},party={{index=1,hp=30},{index=2,hp=25}}}
 local out=C.enrich(game,{},s,'party')
 eq(gen..' original party OT seed',out.slots[1].portrait.otId,11)
 eq(gen..' original party ability label',out.slots[1].portrait.abilityName,'Two')
 eq(gen..' display fallback does not mutate producer',s.slots[1].portrait.otId,nil)
 out.slots[1].portrait.dvs.attack=15;eq(gen..' seed fields detached',m2.dvs.attack,4)
end
print('AbilityBridgeTests: '..n..' assertions PASS')
