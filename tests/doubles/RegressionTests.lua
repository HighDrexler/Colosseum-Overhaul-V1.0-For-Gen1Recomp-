-- Run from the supplied engine source root:
-- POKEPORT_DATA_DIR=tests/fixture_data texlua ../test/doubles_spec.lua
package.path='./?.lua;./?/init.lua;'..package.path
unpack=unpack or table.unpack;loadstring=loadstring or load
if not pcall(require, "bit") then
  package.preload["bit"] = assert(loadstring([=[
    local M = {}
    function M.band(a, ...) local r = a; for _, v in ipairs({...}) do r = r & v end; return r & 0xFFFFFFFF end
    function M.bor(a, ...) local r = a; for _, v in ipairs({...}) do r = r | v end; return r & 0xFFFFFFFF end
    function M.bxor(a, ...) local r = a; for _, v in ipairs({...}) do r = r ~ v end; return r & 0xFFFFFFFF end
    function M.bnot(a) return (~a) & 0xFFFFFFFF end
    function M.lshift(a, n) return (a << n) & 0xFFFFFFFF end
    function M.rshift(a, n) return (a & 0xFFFFFFFF) >> n end
    return M

]=], "@doubles-test-bit-shim"))
end


love=require('tests.love_stub');love.timer=nil
love.graphics.polygon=love.graphics.polygon or function()end
love.graphics.getScissor=function()end
love.graphics.setDepthMode=function()end
love.graphics.getDimensions=function()return 1000,700 end
local checks=0
local function eq(label,a,b) checks=checks+1;assert(a==b,label..': '..tostring(a)..' ~= '..tostring(b)) end
local function ok(label,v) checks=checks+1;assert(v,label) end
local CBE_DIR=os.getenv('CBE_DOUBLES_MOD_DIR') or '../cbe'
local UI_DIR=os.getenv('CBE_DOUBLES_UI_DIR') or '../ui'
local function loadMod(name,V) return assert(loadfile(CBE_DIR..'/lib/doubles/'..name..'.lua'))(V) end
local V={engineRequire=require}
if os.getenv('CBE_TEST_ABILITIES_INSTALLED')=='1' then
 for _,name in ipairs({'AbilityData','Abilities','AbilityWeather','AbilityEffectsGen1','AbilityEffectsGen2'})do
  V[name]=assert(loadfile(CBE_DIR..'/lib/'..name..'.lua'))(V)
 end
 V.AbilityEffectsGen1.installGlobal();V.AbilityEffectsGen2.installGlobal()
 V.AbilityLifecycle=assert(loadfile(CBE_DIR..'/lib/AbilityLifecycle.lua'))(V);V.AbilityLifecycle.install()
end
local Core=loadMod('Core',V);local A=loadMod('NativeAdapter',V)
V.DoublesCore=Core;V.DoublesNativeAdapter=A;V.DoublesItems=loadMod('Items',V)
local f=dofile(CBE_DIR..'/tests/doubles/fixture_gen2.lua');local B2=require('src.battle.gen2.Battle')
local function rand(lo,hi) return lo or 0 end
local function g2(n,playerCount,move)
 local party,enemies={},{}
 for i=1,playerCount or 3 do party[i]=f.Mon.new(f.data,'CYNDAQUIL',25,{dvs={attack=15,defense=15,speed=15,special=15}});party[i].moves={{id=move or 'TACKLE',pp=30},{id='EMBER',pp=20}} end
 for i=1,n or 3 do enemies[i]=f.Mon.new(f.data,'PIDGEY',10);enemies[i].moves={{id='TACKLE',pp=30}} end
 local save={party=party,player={id=1,name='TEST'},badges={},kantoBadges={},money=1000,colosseumBattle={doubleBattlesEnabled=true},pokedex={seen={},owned={}}}
 local host=B2.new{data=f.data,party=party,trainer={name='TEST',party=enemies,baseMoney=20},random=function()return 0 end,save=save}
 local c=Core.new{adapter=A.new(host,2),id='test-'..checks,generation=2,playerParty=party,enemyParty=host.enemyParty,playerIndex=1,enemyIndex=1,rng=rand}
 return c,host,save
end
local function req(c,kind) local s=c.slots[c.commandSlot];return {battleId=c.id,ticket=c.ticket,turn=c.turn,slot=s and s.id,battlerId=s and s.battlerId,kind=kind} end
local function firstCommand(c)
 local s=c.slots[c.commandSlot];local m
 for _,candidate in ipairs(c:legalMoves(s)) do if candidate.enabled then m=candidate;break end end
 local targets=c:targets(s,c.adapter:moveDef(m.id));local target=targets[1]
 for _,id in ipairs(targets) do if id:find('enemy',1,true) then target=id;break end end
 local r=req(c,'move');r.moveIndex=m.index;r.target=target
 return r
end
local function pump(c,predicate)
 for i=1,50000 do
  if predicate and predicate(c) then return i end
  if c.phase=='finished' then return i end
  if c.phase=='progression' then
    local rt=assert(V.DoublesRuntime);local session=assert(rt.session())
    local game=session.screen.game;local original=game.input.wasPressed
    game.input.wasPressed=function()return true end
    local top=game.stack and game.stack:top()
    if top and top~=session.screen then if top.update then top:update(.1) end
    elseif not rt.rewardStep(session) then session.screen:update(.1) end
    game.input.wasPressed=original
  else
    if c.phase=='command' then assert(c:submit(firstCommand(c)))
    elseif c.phase=='replace' then local r=req(c,'switch');r.partyIndex=c:bench('player')[1];assert(c:submit(r)) end
    c:update(.1,true)
  end
 end
 error('Pump did not settle')
end
-- Native kernels, complete coordinated encounters, both active allies.
do
 local c=g2(6,3);local moves={};c.onEvent=function(e)if e.kind=='move' then moves[e.slot]=(moves[e.slot] or 0)+1 end end
 pump(c);eq('Gen2 six-mon trainer completes',c.outcome,'win');eq('All six KOs accounted once',#c.defeated,6)
 ok('Both allied actors took turns',moves['player-left'] and moves['player-right'])
 eq('A fainted enemy action is not inherited by a forced reserve',moves['enemy-right'],nil)
 eq('One turn counter across all battlers',c.turn,3)
end
do
 local c=g2(3,1);pump(c);eq('One usable player can finish doubles',c.outcome,'win')
 eq('No duplicate ally',c.slots['player-right'].mon,nil)
end
-- Exact actor tokens, stale requests, cancel and reservation handling.
do
 local c=g2(3,4);pump(c,function(x)return x.phase=='command'end)
 local r=firstCommand(c);local oldPP=c.playerParty[1].moves[1].pp
 eq('First command accepted',c:submit(r),true);eq('First selection does not spend PP',c.playerParty[1].moves[1].pp,oldPP)
 eq('Stale ticket rejected',c:submit(r),false)
 local undo=req(c,'cancel');eq('Second selection can revise first',c:submit(undo),true);eq('Revised actor is left',c.commandSlot,'player-left')
 local sw=req(c,'switch');sw.partyIndex=3;eq('Switch reservation accepted',c:submit(sw),true)
 local sw2=req(c,'switch');sw2.partyIndex=3;eq('Same reserve cannot fill both',c:submit(sw2),false)
 sw2.partyIndex=4;eq('Distinct second reserve accepted',c:submit(sw2),true)
 pump(c,function(x)return x.turn==2 and x.phase=='command'end)
 eq('Left replacement applied',c.slots['player-left'].partyIndex,3);eq('Right replacement applied',c.slots['player-right'].partyIndex,4)
end
-- Spread semantics: source-era Surf foes only, Earthquake also ally, PP once.
f.data.moves.SURF={id='SURF',name='SURF',power=95,type='WATER',accuracy=100,pp=15,effect='EFFECT_NORMAL_HIT'}
f.data.moves.EARTHQUAKE={id='EARTHQUAKE',name='EARTHQUAKE',power=100,type='GROUND',accuracy=100,pp=10,effect='EFFECT_NORMAL_HIT'}
f.data.moves.SELFDESTRUCT={id='SELFDESTRUCT',name='SELFDESTRUCT',power=200,type='NORMAL',accuracy=100,pp=5,effect='EFFECT_SELFDESTRUCT'}
do
 local c=g2(3,3,'SURF');local s=c.slots['player-left'];local ally=c.slots['player-right'];local a0=ally.mon.hp
 local foes=c:aliveSlots('enemy');local hp1,hp2=foes[1].mon.hp,foes[2].mon.hp
 c.adapter:perform(s,foes,{moveId='SURF',moveIndex=1})
 eq('Spread move costs one PP',s.mon.moves[1].pp,29)
 eq('Gen3-style Surf excludes ally',ally.mon.hp,a0)
 ok('Surf hits both enemies',foes[1].mon.hp<hp1 and foes[2].mon.hp<hp2)
 local fresh=g2(3,3,'EARTHQUAKE');local ids,mode=fresh:targets(fresh.slots['player-left'],f.data.moves.EARTHQUAKE);eq('Earthquake targets all other positions',#ids,3);eq('Earthquake targeting mode',mode,'all-other')
 local again=g2(3,3,'SELFDESTRUCT');local actor=again.slots['player-left'];local others={again.slots['player-right'],again.slots['enemy-left'],again.slots['enemy-right']}
 local old={others[1].mon.hp,others[2].mon.hp,others[3].mon.hp}
 again.adapter:perform(actor,others,{moveId='SELFDESTRUCT',moveIndex=1})
 eq('Selfdestruct user faints once after spread',actor.mon.hp,0);eq('Selfdestruct PP once',actor.mon.moves[1].pp,29)
 for i,t in ipairs(others)do ok('Selfdestruct reaches target '..i,t.mon.hp<old[i])end
end
-- Status/PP gate, priority, current HP after replacement, snapshots are detached.
do
 local c=g2(3,3);local s=c.slots['player-left'];local t=c.slots['enemy-left'];s.mon.status='sleep';s.mon.statusTurns=3
 local hp=t.mon.hp;local pp=s.mon.moves[1].pp
 c.adapter:perform(s,{t},{moveId='TACKLE',moveIndex=1})
 eq('Sleep prevents attack damage',t.mon.hp,hp);eq('Sleep does not spend PP',s.mon.moves[1].pp,pp)
 local moves=0;for _,e in ipairs(c.queue)do if e.kind=='move' then moves=moves+1 end end
 eq('Sleeping battler never starts attack animation',moves,0)
 eq('Quick Attack priority retained',c.adapter:priority('QUICK_ATTACK'),1)
 local snap=c:snapshot();snap.slots[1].hp=999;ok('Snapshot cannot edit native HP',s.mon.hp~=999)
 s.mon.moves[1].pp=0;s.mon.moves[2].pp=0;s.mon.status=nil
 eq('Zero PP supplies Struggle',c:legalMoves(s)[3].id,'STRUGGLE')
 ok('Unsafe native flow explicitly unavailable',not c.adapter:supports({id='BATON_PASS',effect='EFFECT_BATON_PASS'}))
end
-- A pending action belongs to a battler identity, never to its replacement.
do
 local c=g2(3,3);pump(c,function(x)return x.phase=='command'end)
 assert(c:submit(firstCommand(c)));assert(c:submit(firstCommand(c)))
 local s=c.slots['player-left'];local token=s.battlerId
 c:occupy(s.id,3,false);local pp=s.mon.moves[1].pp
 c.phase='resolving';c.actionQueue={{kind='move',slot=s.id,battlerId=token,moveId='TACKLE',moveIndex=1,target='enemy-left'}};c.actionIndex=1
 c:performNext();eq('Old queued move cannot spend replacement PP',s.mon.moves[1].pp,pp)
end
-- Simultaneous KOs demand unique replacement, never a duplicate or deadlock.
do
 local c=g2(3,3);c.queue={};c.qhead=1
 c.slots['player-left'].mon.hp=0;c.slots['player-right'].mon.hp=0;c:noteFaints();c.queue={};c.qhead=1;c:replaceFainted()
 eq('One reserve / two fainted asks once',c.phase,'replace')
 local r=req(c,'switch');r.partyIndex=3;eq('Replacement accepted',c:submit(r),true)
 c.queue={};c.qhead=1;c:replaceFainted()
 eq('Other allied position stays empty',c.slots['player-right'].mon,nil)
 eq('No second impossible selection',c.phase,'resolving')
 for _,m in ipairs(c.playerParty) do m.hp=0 end;for _,m in ipairs(c.enemyParty)do m.hp=0 end
 eq('Simultaneous full wipe uses loss contract',c:checkOutcome(),'lose')
end
-- Gen I actual damage/status implementation, not a mock move calculator.
local Data=require('src.core.Data');Data:load();require('src.battle.TypeChart').load(Data)
local B1=require('src.battle.BattleState');local Pokemon=require('src.pokemon.Pokemon');local Save=require('src.core.SaveData')
local function g1(n)
 local save=Save.newGame();save.party={};save.colosseumBattle={doubleBattlesEnabled=true}
 for i=1,3 do save.party[i]=Pokemon.new(Data,'FIXMON_A',20);save.party[i].moves={{id='FIX_TACKLE',pp=35}} end
 local roster={};for i=1,n or 3 do roster[i]={species='FIXMON_C',level=5}end
 Data.trainers.OPP_FIX_YOUNGSTER.parties[1]=roster
 local game={data=Data,save=save,stack={states={}},input={wasPressed=function()return false end,isDown=function()return false end}}
 function game.stack:top()return self.states[#self.states]end
 function game.stack:pop()return table.remove(self.states)end
 function game.stack:push(st)self.states[#self.states+1]=st;if st.enter then st:enter()end end
 local host=B1.newTrainer(game,'OPP_FIX_YOUNGSTER',1);host.rng=rand;game.stack.states={host};host.phase='menu';host.queue={};host.nextInsert=nil;host.afterQueue=nil
 return host,game,save
end
do
 local host,game,save=g1(6)
 local c=Core.new{adapter=A.new(host,1),id='gen1',generation=1,playerParty=save.party,enemyParty=host.enemyParty,playerIndex=1,enemyIndex=1,rng=rand}
 pump(c);eq('Gen1 six-mon trainer completes',c.outcome,'win');eq('Gen1 all enemies counted',#c.defeated,6)
 ok('Native Gen1 PP spent',save.party[1].moves[1].pp<35)
end
-- Real boundary integration and a compatible UI export.
-- Colosseum Overhaul merge: Runtime.lua's consumer() now reads
-- V.mod.exports.doublesUI directly (CBE and the paired UI are the same mod,
-- so no more find()/ModLookup string lookup for each other). uiHandle stays
-- as the fixture's mutable doublesUI record so the later
-- uiHandle.exports.doublesUI.version/.ready mutations below still take
-- effect on the exact same table V.mod.exports.doublesUI points to.
local uiHandle={exports={doublesUI={version=1,ready=function()return true end,input=function()end}}}
V.mod={exports={doublesUI=uiHandle.exports.doublesUI},find=function()return uiHandle end,log={info=function()end}}
V.ModLookup={find=function()return uiHandle end};V.GenerationCompat={current=function()return 1 end}
local D=loadMod('Runtime',V);V.DoublesRuntime=D
D.install()
do
 local h,g,save=g1(2);eq('Exactly two stays singles',D.tryBegin(h,1),nil)
 h,g,save=g1(3);save.colosseumBattle.doubleBattlesEnabled=false;eq('OFF stays singles',D.tryBegin(h,1),nil)
 h,g,save=g1(3);h.kind='wild';eq('Wild stays singles',D.tryBegin(h,1),nil)
 h,g,save=g1(3);uiHandle.exports.doublesUI.version=0;eq('Old UI declines before battle conversion',D.tryBegin(h,1),nil);uiHandle.exports.doublesUI.version=1
 h,g,save=g1(3);local session=D.tryBegin(h,1);ok('Three-mon trainer starts doubles',session)
 eq('Custom phase blocks unsupported native checkpoints',h.phase,'cbe_doubles')
 eq('Bridge reports authoritative doubles',D.service.snapshot(h).format,'double')
 local hp=save.party[1].hp;save.party[1].hp=1;save.party[1].moves[1].pp=0
 session.screen.game.save.inventory.POTION=99;session.backup.inventory.POTION=2
 eq('Test abort accepted',D.abort(session),true);eq('Abort restores inventory',save.inventory.POTION,2);eq('Abort restores native HP',save.party[1].hp,hp);eq('Abort restores PP',save.party[1].moves[1].pp,35)
 eq('Abort returns to native menu',h.phase,'menu')
end
-- Own the opening before either native singles release, preserve abort queue.
do
 local h,g,save=g1(3);h.phase='messages';h.showPlayerBack=true;h.showEnemyTrainer=true
 local originalQueue={{kind='native-intro'}};h.queue=originalQueue
 V.StandaloneHost={session={started=true,battle=h}}
 local s=D.tryBegin(h,1);ok('Gen1 initial opening acquired',s and s.groupedOpening)
 local order={};for _,e in ipairs(s.core.queue)do if e.kind=='send' then order[#order+1]=e.slot;ok('Initial send flagged',e.opening) end end
 eq('One complete side before the other',table.concat(order,','),'enemy-left,enemy-right,player-left,player-right')
 eq('Native singles opening suspended',#h.queue,0)
 D.abort(s);eq('Early abort restores original queue',h.queue,originalQueue);eq('Early abort restores original phase',h.phase,'messages')
 eq('Early abort restores trainer presentation',h.showEnemyTrainer,true)
 local c,host,sv=g2(3,3)
 local screen={battle=host,game={save=sv,data=f.data},phase='intro',showPlayerTrainer=true,queue={}}
 V.StandaloneHost={session={started=true,battle=screen}}
 s=D.tryBegin(screen,2);ok('Gen2 initial opening acquired',s and s.groupedOpening)
 D.abort(s);eq('Gen2 early abort restores intro',screen.phase,'intro')
 V.StandaloneHost=nil
end
-- Native Gen I reward queues, completion and callback; no detached save copies.
do
 local h,g,save=g1(3);local session=D.tryBegin(h,1);local startExp=save.party[1].experience or save.party[1].exp or 0
 pump(session.core);D.startHandoff(session)
 local done=false;h.onFinish=function(result)done=result end
 g.input.wasPressed=function()return true end
 for i=1,40000 do
   if not session.closed and (h.phase=='menu' or h.phase=='cbe_progression_idle') then D.rewardStep(session) end
   if h.phase=='messages' then h.frame=(h.frame or 0)+1;h:updateFx();if not h:updateQueue() then
     if h.afterQueue=='finish' then done=h.result;break else h.phase='menu';h.afterQueue=nil;h.nextInsert=nil end
   end end
 end
 eq('Gen1 native payout finishes with win',done,'win')
 ok('Gen1 prize money committed',save.money>3000)
 ok('Gen1 experience committed',((save.party[1].exp or save.party[1].experience or 0)>startExp))
 done=false;h:finish()
 for i=1,500 do local top=g.stack:top();if top and top.update then top:update(.1) end;if done then break end end
 eq('Gen1 native finish callback survives doubles handoff',done,'win')
end
-- Native Gen II full reward/event handoff.
do
 local c,host,save=g2(3,3)
 local game={data=f.data,save=save,input={wasPressed=function()return true end,isDown=function()return true end},stack={states={}}}
 function game.stack:top()return self.states[#self.states]end
 function game.stack:pop()return table.remove(self.states)end
 function game.stack:push(s)self.states[#self.states+1]=s end
 local View=require('src.ui.gen2.BattleState');local screen=View.new(game,{battle=host});game.stack.states={screen};screen.phase='menu';screen.slideFrame=100;screen.queue={}
 local s=D.tryBegin(screen,2);ok('Gen2 actual screen starts doubles',s);local initial=save.party[1].experience
 pump(s.core);D.startHandoff(s)
 for i=1,50000 do
  if not s.closed and (screen.phase=='menu' or screen.phase=='cbe_progression_idle' or screen.phase=='locked-in') then D.rewardStep(s) end
  if s.closed then break end
  screen:update(.1)
 end
 ok('Gen2 reward handoff completed',s.closed);eq('Gen2 native model owns final outcome',host.outcome,'win')
 ok('Gen2 experience committed',save.party[1].experience>initial)
 local done=false;screen.onDone=function(result)done=result end
 for i=1,50000 do screen:update(.1);if done then break end end
 eq('Gen2 native completion callback survives doubles handoff',done,'win')
 for _,mon in ipairs(save.party)do eq('Gen2 battle RAM removed before returning',mon.volatile,nil)end
end
-- UI layout and input: real module, fake graphics only. Every command goes
-- through the production v1 bridge and production scheduler validation.
do
 local c=g2(3,3);pump(c,function(x)return x.phase=='command'end)
 local api={version=1,snapshot=function()return c:snapshot()end,submit=function(r)return c:submit(r)end}
 -- Colosseum Overhaul merge: DoublesUI.lua's service() now reads
 -- T.mod.exports.doubles directly (see the uiHandle fixture note above for
 -- why), so this mock mod needs that field set directly too.
 local mod={exports={doubles=api},find=function()return {exports={doubles=api}}end}
 local U=assert(loadfile(UI_DIR..'/lib/DoublesUI.lua')){mod=mod,ready=function()return true end,font=function(size)return love.graphics.newFont(size)end}
 local snap=c:snapshot()
 U.input(api,snap,{a=true});U.input(api,snap,{a=true});U.input(api,snap,{a=true})
 eq('UI commands reach first native battler',c.commandSlot,'player-right')
 for _,size in ipairs({{1920,1080},{1000,700},{640,360},{360,640}}) do
  love.graphics.getDimensions=function()return size[1],size[2]end
  eq('Four-panel draw '..size[1]..'x'..size[2],U.draw({},{}),true)
 end
 for _,m in ipairs(c.slots['player-right'].mon.moves)do m.pp=0 end
 U.input(api,c:snapshot(),{a=true})
 eq('Zero PP/Struggle UI draws without nil arithmetic',U.draw({},{}),true)
end

-- Presenter routing and shared-handle lifecycle. These exercise real CBE
-- presenter code; fake actor methods stand in for GPU/ROM-backed rendering.
do
 local c=g2(3,3);local acquires,draws,releases,attacks,hits=0,0,0,{},{}
 local function actor(id)
  return {spawn=function()end,idle=function()end,update=function()end,
    matrix=function(_,x,y,z,dx,dz)return {x,y,z,dx,dz}end,
    build=function()return true end,draw=function()draws=draws+1;return true end,
    attack=function()attacks[id]=(attacks[id] or 0)+1 end,
    hit=function()hits[id]=(hits[id] or 0)+1 end,
    faint=function()end,recall=function()end,
    release=function()releases=releases+1 end}
 end
 local old={stadiumActors={player={actor=actor('player-left')},enemy={actor=actor('enemy-left')}},
   modeId='cbe:colosseum-pokemon',drawn={},presented={}}
 local PV={CurrentSpriteModels=old, PokemonActors={service={worldUnits=false,
   acquireCached=function(_,dex,variant,opts)acquires=acquires+1;return actor(opts.doublesPosition)end,
   withRenderer=function(vp,cb) return cb() end}},BattleSettings={pokemonModelsEnabled=function()return true end}}
 local P=loadMod('Presenter',PV);local session={core=c,adapter=c.adapter,screen={game={data=f.data}},generation=2}
 -- Production fixtures may not expose Dex fields. The actor mock only needs
 -- a supported identity; no art is read or generated in this test.
 f.data.pokemon.CYNDAQUIL.dex=155;f.data.pokemon.PIDGEY.dex=16
 P.begin(session);local opening={}
 for _,e in ipairs(c.queue)do if e.kind=='send' then opening[#opening+1]=e;P.event(session,e)end end
 eq('Two resident opening actors transferred',#session.actorOrder,4)
 eq('Transferred actors no longer owned by singles',old.stadiumActors.player,nil)
 local context={arena={player={-20,0},enemy={20,0}},groundY=0,services={vp={},renderSize={width=1000,height=700}}}
 P.draw(session,context);P.update(session,.05);eq('At most one new handle per update',acquires,1)
 P.update(session,.05);eq('Second ally/enemy acquired independently',acquires,2)
 draws=0;P.draw(session,context);eq('Only opening leads visible before second balls arrive',draws,2)
 for i=1,100 do P.update(session,.05) end
 draws=0;P.draw(session,context);eq('Four actor draws after second balls arrive',draws,4)
 local left=c.slots['player-left'];local right=c.slots['enemy-right']
 P.event(session,{kind='move',slot=left.id,battlerId=left.battlerId,move='TACKLE',moveDef=f.data.moves.TACKLE})
 P.event(session,{kind='damage',slot=right.id,battlerId=right.battlerId,amount=3,hp=7})
 eq('Attack routed only to selected actor',attacks['player-left'],1);eq('Partner does not attack',attacks['player-right'],nil)
 eq('Damage routed to selected target',hits['enemy-right'],1);eq('Other enemy does not flinch',hits['enemy-left'],nil)
 local px,pz=P.anchor(context,'player-left');local qx,qz=P.anchor(context,'player-right')
 ok('Distinct team positions',px~=qx or pz~=qz)
 local pose=P.camera{eye={0,40,80},focus={0,0,0},fov=.8}
 ok('Doubles framing widens camera',pose.fov>.8)
 P.finish(session);eq('All four actor handles released',releases,4)
end
-- Eligibility exceptions and real native loss handoff.
do
 local h,g,save=g1(3);save.party[2].isEgg=true;save.party[3].hp=0
 local s=D.tryBegin(h,1);ok('Egg/fainted-only partner does not prevent eligible encounter',s)
 eq('Egg cannot occupy partner position',s.core.slots['player-right'].mon,nil)
 save.party[1].hp=0;s.core:noteFaints();s.core.queue={};s.core.qhead=1;s.core.phase='finished'
 D.startHandoff(s);D.rewardStep(s);eq('Native Gen1 loss contract',h.result,'lose');ok('Loss releases custom session',s.closed)
 h,g,save=g1(3);save.colosseumBattle.arenasEnabled=false;eq('Unavailable arena presentation refuses conversion',D.tryBegin(h,1),nil)
 h,g,save=g1(3);uiHandle.exports.doublesUI.ready=function()return false end
 eq('Disabled paired HUD refuses conversion',D.tryBegin(h,1),nil);uiHandle.exports.doublesUI.ready=function()return true end
 local c,host,sv=g2(3,3);host.linkBattle=true
 eq('Native Gen2 link battle remains untouched',D.tryBegin({battle=host,game={save=sv},phase='menu'},2),nil)
end


-- Every supported move in the supplied Gen II fixture is exercised through
-- the native kernel twice (charge continuation included), with residual ticks.
do
 local ids={};for id,def in pairs(f.data.moves)do if A.new(select(2,g2(3,3)),2):supports(def) then ids[#ids+1]=id end end
 table.sort(ids)
 for _,id in ipairs(ids) do
  local c=g2(3,3,id);local actor=c.slots['player-left']
  for turn=1,2 do
   c.adapter:beginTurn()
   local targetIds,mode=c:targets(actor,f.data.moves[id]);local ts={}
   if mode=='foes' or mode=='all-other' then for _,key in ipairs(targetIds)do ts[#ts+1]=c.slots[key]end
   elseif mode=='self' or mode=='side' or mode=='field' then ts={actor}
   else ts={c.slots['enemy-left']}end
   if actor.mon.hp<=0 or #ts==0 then break end
   c.adapter:perform(actor,ts,{moveId=id,moveIndex=1});c.adapter:endTurn()
  end
  ok('Native fixture move smoke: '..id,actor.mon.hp>=0)
 end
end

-- Native Gen II sound scripts remain audible when source WAVs are unavailable.
do
 local played={}
 local tv={engineRequire=function(name)
   if name=='src.core.Sound' then return {playStereo=function(_,name)played[#played+1]=name end} end
   return require(name)
  end,MoveFXExtractor={peek=function()return nil end},
  CurrentSpriteModels={withDoublesPair=function(_,ctx,records,fn)return fn(ctx)end,updateReleaseFx=function()end,clearDoublesWaza=function()end},
  WazaSequenceRuntime={update=function()end},DoublesPresenter={actorAnchor=function()return 0,0,0,1 end}}
 local mp=loadMod('MovePresentation',tv)
 local data={audio={sfxOrder={'FIRST','SECOND'}},gen2BattleAnims={moves={TACKLE='test'},scripts={test={{'sound',0,0},{'wait',2},{'sound',0,1},{'ret'}}}}}
 local s={generation=2,screen={game={data=data}},context={arena={},services={}},core={slots={a={battlerId='a'},b={battlerId='b'}}},actors={a={mon={}},b={mon={}}}}
 local event={kind='move',slot='a',targets={'b'},move='TACKLE'}
 mp.begin(s,event);for i=1,60 do mp.update(s,.05) end
 eq('Gen2 fallback keeps both sequenced sounds',table.concat(played,','),'FIRST,SECOND')
 eq('Gen2 fallback releases presentation queue',event.presentationPending,nil)
end

-- Items use actual native effect modules without invoking a singles turn.
for generation=1,2 do
 local c,save
 if generation==2 then c,_,save=g2(3,3)
 else
  local host,game;host,game,save=g1(3)
  c=Core.new{adapter=A.new(host,1),id='items-gen1',generation=1,playerParty=save.party,enemyParty=host.enemyParty,playerIndex=1,enemyIndex=1,rng=rand}
 end
 local a=c.adapter;local I=V.DoublesItems
 for _,id in ipairs({'POTION','REVIVE','FULL_HEAL','ETHER','X_ATTACK','GUARD_SPEC','POKE_BALL','PP_UP'})do a.data.items[id]={id=id,name=id}end
 save.inventory={POTION=1,REVIVE=1,FULL_HEAL=1,ETHER=1,X_ATTACK=1,GUARD_SPEC=1,POKE_BALL=1,PP_UP=1}
 pump(c,function(x)return x.phase=='command'end)
 local left=c.slots['player-left'];local right=c.slots['player-right'];local mon=right.mon
 mon.hp=1;local initialPP=left.mon.moves[1].pp
 local r=req(c,'item');r.item='POTION';r.partyIndex=right.partyIndex
 eq('Item selection accepted gen '..generation,c:submit(r),true)
 eq('Selection does not heal gen '..generation,mon.hp,1)
 eq('Selection does not spend inventory gen '..generation,save.inventory.POTION,1)
 local duplicate=req(c,'item');duplicate.item='POTION';duplicate.partyIndex=right.partyIndex
 eq('Last copy reserved gen '..generation,c:submit(duplicate),false)
 eq('Cancel releases item gen '..generation,c:submit(req(c,'cancel')),true)
 eq('Reservation released gen '..generation,I.available(a,'POTION'),1)
 r=req(c,'item');r.item='POTION';r.partyIndex=right.partyIndex;eq('Reselect item',c:submit(r),true)
 local follow=firstCommand(c);eq('Partner move selected',c:submit(follow),true)
 eq('Item resolves before moves',c.actionQueue[1].kind,'item')
 c:performNext();eq('Correct partner healed',mon.hp,math.min(a:maxHP(mon),21));eq('One copy spent',save.inventory.POTION,nil)
 eq('Item does not spend action owner PP',left.mon.moves[1].pp,initialPP)
 local turn=c.turn
 for i=1,2000 do
  c:update(1/60,false)
  if c.phase=='command' and c.turn>turn then break end
 end
 eq('Item and partner move flow without A',c.turn,turn+1)
 eq('Flow stops at player choice',c.phase,'command')
 eq('Single item not consumed twice',save.inventory.POTION,nil)

 local bench=c.playerParty[3];bench.hp=0
 local used=I.perform(a,{item='REVIVE',partyIndex=3});eq('Bench revive succeeds',used,true);ok('Revived HP positive',bench.hp>0)
 mon.status=generation==1 and 'PSN' or 'poison'
 eq('Status cure succeeds',I.perform(a,{item='FULL_HEAL',partyIndex=right.partyIndex}),true);ok('Status cleared',not mon.status)
 mon.moves[1].pp=0;mon.moves[1].maxPp=35
 if right.battler.curMoves then right.battler.curMoves[1].pp=0 end
 eq('Ether requires a move',I.validate(a,{item='ETHER',partyIndex=right.partyIndex}),false)
 eq('Ether restores selected move',I.perform(a,{item='ETHER',partyIndex=right.partyIndex,moveIndex=1}),true)
 eq('Restored ten PP',mon.moves[1].pp,10)
 if right.battler.curMoves then eq('Active PP mirror restored',right.battler.curMoves[1].pp,10)end
 eq('Battle stat item targets partner',I.perform(a,{item='X_ATTACK',partyIndex=right.partyIndex}),true)
 eq('Partner attack stage raised',right.stages.attack,1);eq('Owner stage unchanged',left.stages.attack or 0,0)
 eq('Guard Spec available',I.classify(a,'GUARD_SPEC'),'battle')
 eq('Trainer capture unavailable',I.classify(a,'POKE_BALL'),nil)
 eq('Permanent PP Up unavailable in battle',I.classify(a,'PP_UP'),nil)
 save.inventory.POTION=1;mon.hp=a:maxHP(mon)
 eq('No-effect medicine rejected',I.validate(a,{item='POTION',partyIndex=right.partyIndex}),false)
 eq('No-effect item retained',save.inventory.POTION,1)
 eq('Eggs rejected',I.validate(a,{item='POTION',partyIndex=999}),false)
 local snap=c:snapshot();eq('Bag capability advertised',snap.limitations.bag,true);eq('Item API advertised',snap.itemApiVersion,1)
 ok('Snapshot exposes inventory',#snap.items>0)
end


-- Exercise real native message consumers with automatic acknowledgements.
do
 local Auto=assert(loadfile(CBE_DIR..'/lib/BattleAutoProgress.lua'))({})
 local host,game=g1(3);game.save.colosseumBattle.doubleBattlesEnabled=false;host.phase='messages';host.afterQueue='menu';host:say('A critical hit!')
 for i=1,500 do Auto.call(B1.update,host,Auto.update(host,1,1/60),1/60)end
 eq('Native Gen I message finishes without buttons',host.phase,'menu')
 local State2=require('src.ui.gen2.BattleState');local c,battle,save=g2(3,3)
 local input={wasPressed=function()return false end,isDown=function()return false end}
 local screen=State2.new({data=f.data,save=save,input=input},{battle=battle})
 screen.phase='resolving';screen.slideFrame=1000;screen.queue={};screen.message='A critical hit!';screen.messageTimer=1
 local advances=0;screen.advanceQueue=function(self)advances=advances+1;self.phase='menu'end
 -- Stub only unrelated visuals; native typer, prompt branch and input are real.
 screen.updateAlarm=function()end;screen.stepFrontAnim=function()end
 for i=1,400 do
  if screen.phase=='menu' then break end
  Auto.call(State2.update,screen,Auto.update(screen,2,1/60),1/60)
 end
 eq('Native Gen II message finishes without buttons',advances,1);eq('Native menu remains manual',screen.phase,'menu')
end

-- Secondary status effects mutate the animation row returned by animNext.
-- Exercise the real native effect pipeline, not a synthetic nil guard.
for _,case in ipairs({{'BRN','BURN_SIDE_EFFECT1'},{'FRZ','FREEZE_SIDE_EFFECT1'},{'PAR','PARALYZE_SIDE_EFFECT1'},{'PSN','POISON_SIDE_EFFECT1'}})do
 for _,side in ipairs({'player','enemy'})do
  local host,game,save=g1(3)
  local c=Core.new{adapter=A.new(host,1),id='status-'..case[1]..side,generation=1,playerParty=save.party,enemyParty=host.enemyParty,playerIndex=1,enemyIndex=1,rng=rand}
  local src=c.slots[side..'-right'];local dst=c.slots[(side=='player' and 'enemy' or 'player')..'-left']
  local partner=c.slots[(side=='player' and 'enemy' or 'player')..'-right']
  local id='FIX_SECONDARY_'..case[1]
  Data.moves[id]={id=id,name=id,type='NORMAL',power=10,accuracy=100,pp=20,effect=case[2]}
  src.mon.moves={{id=id,pp=20}};src.battler.curMoves=src.mon.moves
  dst.mon.hp=1000;dst.battler.curTypes={'GRASS'};dst.mon.status=nil
  local hp=dst.mon.hp
  c.adapter:perform(src,{dst},{moveId=id,moveIndex=1})
  eq('Secondary status applied '..case[1]..side,dst.mon.status,case[1])
  ok('Damage retained '..case[1]..side,dst.mon.hp<hp)
  eq('One PP spent '..case[1]..side,src.mon.moves[1].pp,19)
  eq('Partner status unaffected '..case[1]..side,partner.mon.status,nil)
  local hudRows=0;for _,row in ipairs(c.adapter.k.queue)do if row.anim=='ENEMY_HUD_SHAKE_ANIM' or row.anim=='SHAKE_SCREEN_ANIM' then hudRows=hudRows+1 end end
  eq('No singles status HUD queued '..case[1]..side,hudRows,0)
  eq('Host queue untouched '..case[1]..side,#host.queue,0)
 end
end

assert(loadfile(CBE_DIR..'/tests/doubles/StabilityTests.lua'))({g1=g1,g2=g2,Core=Core,A=A,V=V,Data=Data,f=f,rand=rand,eq=eq,ok=ok,pump=pump,req=req,firstCommand=firstCommand})
assert(loadfile(CBE_DIR..'/tests/doubles/IntegrationTests.lua'))({g1=g1,g2=g2,Core=Core,A=A,V=V,Data=Data,f=f,rand=rand,eq=eq,ok=ok,pump=pump,req=req,firstCommand=firstCommand})
assert(loadfile(CBE_DIR..'/tests/doubles/FieldVisibilityNativeTests.lua'))({g1=g1,g2=g2,Core=Core,A=A,V=V,Data=Data,f=f,rand=rand,eq=eq,ok=ok})
assert(loadfile(CBE_DIR..'/tests/doubles/TurnFlowTests.lua'))({g1=g1,g2=g2,Core=Core,A=A,V=V,Data=Data,f=f,rand=rand,eq=eq,ok=ok,pump=pump,req=req,firstCommand=firstCommand})
if V.Abilities then
 local context={g1=g1,g2=g2,Core=Core,A=A,V=V,Data=Data,f=f,rand=rand,eq=eq,ok=ok}
 for _,name in ipairs({'NativeAbilitiesTests','NativeAbilityLifecycleTests'})do
  assert(loadfile(CBE_DIR..'/tests/doubles/'..name..'.lua'))(context)
 end
end
print('PASS: '..checks..' assertions; real native Gen I/II moves and end-of-battle handoffs; graphics are stubbed.')
