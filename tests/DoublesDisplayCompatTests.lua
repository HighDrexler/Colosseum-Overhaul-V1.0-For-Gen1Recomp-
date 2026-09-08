-- Run with UI_COMPAT_DIR=/path/to/UI and CBE_TEST_BASE=/path/containing/cbe1,cbe2,cbe3.
-- Exercises actual released CBE snapshot producers and the UI factory. Graphics
-- are stubs; no live device/ROM-backed battle is implied by these checks.
local root=os.getenv('UI_COMPAT_DIR') or '.'
local base=os.getenv('CBE_TEST_BASE') or '/mnt/data/compat_check'
local C=assert(loadfile(root..'/lib/DoublesDisplayCompat.lua'))()
local count=0
local function eq(name,a,b)count=count+1;assert(a==b,name..': '..tostring(a)..' ~= '..tostring(b))end
local function yes(name,a)count=count+1;assert(a,name)end
local function copy(t,seen)
 if type(t)~='table' then return t end
 seen=seen or {};if seen[t] then return seen[t] end
 local out={};seen[t]=out;for k,v in pairs(t)do out[copy(k,seen)]=copy(v,seen)end;return out
end
local function same(a,b,seen)
 if type(a)~=type(b)then return false end
 if type(a)~='table'then return a==b end
 seen=seen or {};if seen[a]==b then return true end;seen[a]=b
 for k,v in pairs(a)do if not same(v,b[k],seen)then return false end end
 for k in pairs(b)do if a[k]==nil then return false end end;return true
end
local data={pokemon={ARTICUNO={types={'ICE','FLYING'},name='ARTICUNO'},BLASTOISE={types={'WATER'},name='BLASTOISE'}},
 moves={ICE_BEAM={id='ICE_BEAM',name='ICE BEAM',type='ICE',pp=10}}}
local function mon(i,gen)
 local m={species=i%2==1 and 'ARTICUNO' or 'BLASTOISE',nickname='MON '..i,level=65,
 hp=110+i,stats={hp=205,attack=100+i,defense=99,speed=108,special=111,specialAttack=111,specialDefense=102},
 item='BERRY',dvs={attack=i,defense=14},moves={{id='ICE_BEAM',pp=i,maxPP=10}},shiny=i==5}
 if gen==1 then m.exp=279980+i else m.experience=279980+i end
 m.stats.cycle=m;m.moves[1].back=m -- must never leak or recursively clone
 return m
end
local function fixture(version,gen)
 local Core=assert(loadfile(base..'/cbe'..version..'/lib/doubles/Core.lua'))()
 local adapter={data=data,name=function(_,m)return m.nickname end,maxHP=function(_,m)return m.stats.hp end,
 makeBattler=function(_,s)return {mon=s.mon,types=data.pokemon[s.mon.species].types}end,
 newStages=function()return {}end,withdraw=function()end,switchLocked=function()return false end,
 moveDef=function(_,id)return data.moves[id]end}
 local party={};for i=1,6 do party[i]=mon(i,gen)end
 local core=Core.new{adapter=adapter,id='compat-'..version..'-'..gen,generation=gen,
 playerParty=party,enemyParty={mon(2,gen),mon(1,gen),mon(2,gen)},playerIndex=5}
 core:occupy('player-right',3,true)
 core.queue={};core.qhead=1;core.currentEvent=nil;core.phase='command';core.commandSlot='player-left';core.ticket=10
 core.legalMoves=function()return {{index=1,id='ICE_BEAM',name='ICE BEAM',enabled=true,type='ICE',pp=8,maxPP=10}}end
 core.targets=function()return {'player-right','enemy-left','enemy-right'},'selected'end
 return core,{save={party=party},data=data}
end
local g={}
for _,key in ipairs{'push','pop','origin','setShader','setScissor','setColor','setLineWidth','rectangle','line','setFont','print','polygon'}do g[key]=function()end end
g.getDimensions=function()return 1722,896 end
love={graphics=g}
local font={getWidth=function(_,s)return #s*6 end,getHeight=function()return 12 end}
for version=1,3 do for gen=1,2 do
 local core,game=fixture(version,gen);local s=core:snapshot();local original=copy(s);local saved=copy(game.save.party)
 local field=gen==1 and 'exp' or 'experience'
 local out=C.enrich(game,{},s,'party')
 eq('active5 XP '..version..'/'..gen,out.slots[1].portrait[field],279985)
 eq('active3 XP distinct duplicate',out.slots[2].portrait[field],279983)
 eq('allied species type1',out.slots[1].types[1],'ICE')
 eq('allied species type2',out.slots[1].types[2],'FLYING')
 eq('enemy species type',out.slots[3].types[1],'WATER')
 for i,row in ipairs(out.party)do
  eq('original index intact',row.index,i)
  eq('party species',row.display.species,game.save.party[i].species)
  eq('party XP',row.display[field],279980+i)
  eq('party PP',row.display.moves[1].pp,i)
  eq('party stat',row.display.stats.attack,100+i)
  eq('party held item',row.display.item,'BERRY')
  eq('party DV',row.display.dvs.attack,i)
  eq('nested move graph excluded',row.display.moves[1].back,nil)
  eq('nested stats graph excluded',row.display.stats.cycle,nil)
 end
 yes('producer unchanged',same(s,original));yes('native party unchanged',same(game.save.party,saved))
 local current=s;local facade,experience,submitted={}, {},{}
 local api={version=1,snapshot=function()return current end,submit=function(req)submitted[#submitted+1]=copy(req);return true end}
 -- Colosseum Overhaul merge: DoublesUI.lua's service() now reads
 -- T.mod.exports.doubles directly (CBE and the paired UI are the same mod).
 local U=assert(loadfile(root..'/lib/DoublesUI.lua')){
  mod={exports={doubles=api},find=function()return {exports={doubles=api}}end},font=function()return font end,displayCompat=C,
  experience=function(_,m)experience[#experience+1]=m;return .42 end,
  party=function(_,state)facade=state end}
 local u=U._test.state(s)
 U.draw(game,{})
 eq('real UI EXP left',experience[1][field],279985);eq('real UI EXP right',experience[2][field],279983)
 u.page='party';u.index=1;U.draw(game,{})
 eq('shared party active5',facade.doublesCards[1].index,5);eq('shared party active3',facade.doublesCards[2].index,3)
 eq('shared party details PP',facade.party[6].moves[1].pp,6)
 eq('transparent party',facade.isOpaque,false)
 U.input(api,s,{a=true},game)
 eq('switch exact index',submitted[1].partyIndex,1);eq('switch exact actor',submitted[1].battlerId,s.battlerId)
 eq('switch exact ticket',submitted[1].ticket,s.ticket);eq('switch exact turn',submitted[1].turn,s.turn)
 eq('switch exact battle',submitted[1].battleId,s.battleId);eq('switch exact slot',submitted[1].slot,s.commandSlot)
 yes('draw/input producer unchanged',same(s,original));yes('draw/input party unchanged',same(game.save.party,saved))
 if version<3 then
  out.party[1].display.moves[1].pp=0;out.party[1].display.stats.attack=0;out.party[1].display.dvs.attack=0
  out.slots[1].portrait[field]=0;out.slots[1].types[1]='FIRE'
  yes('fallback records detached',same(game.save.party,saved))
  local advanced=copy(s);advanced.slots[1].portrait=advanced.slots[1].portrait or {species=advanced.slots[1].species};advanced.slots[1].portrait.exp=0;advanced.slots[1].portrait.experience=nil
  local enriched=C.enrich(game,{},advanced,'commands')
  eq('snapshot zero XP not overwritten',enriched.slots[1].portrait.exp,0)
  eq('no alternate native XP alias injected',enriched.slots[1].portrait.experience,nil)
  game.save.party[5].status='PAR';game.save.party[5].hp=1
  enriched=C.enrich(game,{},s,'party')
  eq('HUD HP remains presented',enriched.slots[1].hp,s.slots[1].hp)
  eq('HUD clear status preserved',enriched.slots[1].status,s.slots[1].status)
  eq('Party HP follows snapshot',enriched.party[5].display.hp,s.party[5].hp)
  eq('Party active clear status preserved',enriched.party[5].display.status,s.slots[1].status)
  local ev=copy(s);ev.phase='present';ev.presentation={kind='damage',slot=s.slots[1].id,subject=copy(s.slots[1])}
  enriched=C.enrich(game,{},ev,'commands')
  eq('matching event gets its own XP',enriched.presentation.subject.portrait[field],279985)
  ev.slots[1].battlerId='replacement-token';ev.slots[1].partyIndex=1
  enriched=C.enrich(game,{},ev,'commands')
  eq('outgoing event never borrows same-species incoming XP',enriched.presentation.subject.portrait[field],nil)
  local mismatch=copy(s);mismatch.slots[1].species='BLASTOISE'
  enriched=C.enrich(game,{},mismatch,'party')
  eq('known identity conflict rejects XP',enriched.slots[1].portrait[field],nil)
  eq('known identity conflict rejects PP',#enriched.party[5].display.moves,0)
  local missing=C.enrich({data=data},{},s,'party')
  eq('absent party not guessed',missing.slots[1].portrait[field],nil)
  eq('absent data keeps controls',missing.party[1].enabled,s.party[1].enabled)
 else
  local native=C.nativeParty;C.nativeParty=function()error('should not read native tables')end
  eq('complete producer fast path',C.enrich(game,{},s,'party'),s)
  C.nativeParty=native
 end
end end
-- Direct host party views take precedence over a possibly unrelated save party.
do
 local core,game=fixture(2,2);local party=game.save.party
 eq('native Gen2 screen party',C.nativeParty({save={party={}}},{battle={party=party}}),party)
 eq('native Gen2 model party',C.nativeParty({save={party={}}},{party=party}),party)
 eq('native Gen1 playerParty override',C.nativeParty(game,{playerParty={}})[1],nil)
 eq('native generation wrapper',C.nativeParty(game,{_model={party=party}}),party)
 local b={};b._model=b;b._view=b;b.battle=b
 eq('cyclic wrapper bounded',C.nativeParty(game,b),party)
 local U=assert(loadfile(root..'/lib/DoublesUI.lua')){mod={exports={doubles={version=1}},find=function()return {exports={doubles={version=1}}}end},font=function()return font end,displayCompat=C}
 eq('malformed bridge rejected before draw',U.draw(game,{}),false)
 U=assert(loadfile(root..'/lib/DoublesUI.lua')){mod={find=function()return nil end},font=function()return font end,displayCompat=C}
 eq('absent doubles bridge leaves singles draw',U.draw(game,{}),false)
end
print('UI-ONLY DISPLAY COMPATIBILITY ASSERTIONS PASSED: '..count)
