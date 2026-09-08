-- Actual native Gen I/II menus, hooks and StateStack. Source/GPU work is a
-- controlled fixture; title/startup entries now offer choices before any work.
package.path='./?.lua;./?/init.lua;'..package.path
local T=require('tests.modkit')
local Data=T.fixtures.fresh();require('src.render.Font').load(Data)
local Hooks=require('src.mods.Hooks');local Runtime=require('src.mods.Runtime')
local Stack=require('src.core.StateStack');local root=assert(os.getenv('UI_COMPAT_DIR'))
local checks=0
local function yes(v,k)checks=checks+1;assert(v,k)end
local function eq(a,b,k)checks=checks+1;assert(a==b,k..' '..tostring(a)..' ~= '..tostring(b))end
local function module(p,v)return assert(loadfile(root..'/'..p))(v)end
local now=0;love.timer.getTime=function()return now end
local oldWarn=require('src.core.Logger').warn;local warnings={}
require('src.core.Logger').warn=function(...)warnings[#warnings+1]={...}end
for _,gen in ipairs{1,2}do
 local hook=Hooks.new();Runtime.install({emit=function()end},hook,{})
 local save={colosseumBattle={pokemonModelsEnabled=true},playerName='BLAKE',pokedex={seen={},owned={}},
   party={{dex=1},{dex=2},{dex=3,shiny=true}},playTime=0}
 local stack=setmetatable({}, {__index=Stack});stack:init()
 local pressed={};local game={data=Data,stack=stack,input={wasPressed=function(_,k)return pressed[k]end}}
 local oldWorldTicks=0;local titleBase={update=function()oldWorldTicks=oldWorldTicks+1 end};stack:push(titleBase)
 local epoch=1;local prepared={};local faults={};local calls={};local cancelled=0;local slow=false;local warmed=0
 local V={mod={hooks=hook,cache={write=function()return true end}},engineRequire=require,
  ShinySupport=module('lib/ShinySupport.lua'),ResidentPrewarm={cancel=function()end,queueStartup=function()warmed=warmed+1 end}}
 V.ModelIdentity=module('lib/ModelIdentity.lua',V)
 V.WorkBudget=module('lib/WorkBudget.lua')
 V.CacheScreen=module('lib/CacheScreen.lua')
 V.GenerationCompat=module('lib/GenerationCompat.lua',V);V.GenerationCompat.current=function()return gen end
 local function key(d,v)return d..':'..v end
 V.PokemonActors={sessionCacheIdentity=function()return 'identity:'..epoch end,
  sessionResidentCount=function()local n=0;for _ in pairs(prepared)do n=n+1 end;return n end,
  peek=function(_,d,v)return {resident=prepared[key(d,v)]==true}end,
  prepareSessionModel=function(d,v,progress)
   calls[#calls+1]=key(d,v)
   if slow then V.WorkBudget.onCancel(function()cancelled=cancelled+1 end);now=now+.020;progress('yielding exact '..key(d,v))end
   if faults[key(d,v)] then return false,faults[key(d,v)]end
   prepared[key(d,v)]=true;return true,'resident'
  end}
 local B=require(gen==1 and 'src.battle.BattleState' or 'src.ui.gen2.BattleState')
 local originalUpdate=B.update;local updated=0;B.update=function()updated=updated+1 end;B.__cbeModelCache=nil
 local Main=gen==2 and require('src.ui.gen2.MainMenu');local originalChoose=Main and Main.choose
 if Main then Main.__cbeModelCache=nil end
 local Save=require(gen==1 and 'src.core.SaveData' or 'src.core.gen2.Save')
 local loadSave=Save.load;Save.load=function()return save end
 local oldInfo=love.filesystem.getInfo
 love.filesystem.getInfo=function(p,...)if tostring(p):match('save.*%.lua$')then return {type='file',size=100}end;return oldInfo(p,...)end
 local C=module('lib/BattleCache.lua',V);V.BattleCache=C
 C.install();C.install();eq(#hook.chains['input.step'],1,'idempotent hook install')
 local plan=C.plan();eq(#plan,502,'full plan retains every normal and shiny appearance')
 for i=1,251 do eq(plan[2*i-1].dex,i,'normal dex');eq(plan[2*i].variant,'shiny','shiny row')end
 local newCount,continueCount=0,0;local nativeMenu
 if gen==1 then
  local Title=require('src.ui.TitleState')
  local title=setmetatable({game=game,onNewGame=function()newCount=newCount+1 end,onContinue=function()continueCount=continueCount+1 end},Title)
  title:openMenu();nativeMenu=stack:top()
  eq(nativeMenu.items[#nativeMenu.items].label,'BATTLE CACHE','Gen I native menu row')
 else
  nativeMenu=Main.new(game,{save=save,hasSave=true,onNewGame=function()newCount=newCount+1 end,onContinue=function(s)eq(s,save,'saved object unchanged');continueCount=continueCount+1 end})
  stack:push(nativeMenu)
  eq(nativeMenu.list.items[#nativeMenu.list.items].value,'cbe_battle_cache','Gen II native menu row')
 end
 local function step(n)
  for i=1,n or 1 do now=now+.02;stack:update(.016) end
  pressed={}
 end
 local function finish()
  local limit=0
  while C.busy() and not C.status().error do step();limit=limit+1;assert(limit<1100,'cache did not finish')end
 end
 local function chooseContinue()
  if gen==1 then nativeMenu.items[1].onSelect() else nativeMenu:choose('continue') end
  if C.busy() then
   yes(stack:top().selector and stack:top().startupRequest,'Continue must offer options first')
   local before=#calls;step();eq(#calls,before,'Continue options alone do no work')
   pressed.a=true;step();eq(C.status().mode,'startup','explicit team-only selection')
  end
 end
 local function restoreMenu()
  if gen==1 then yes(stack:top()~=nativeMenu,'native Continue info opens after cache');stack:pop()
  else nativeMenu.phase='menu' end
 end
 Runtime.call('input.step',function()end,game,.016)
 yes(C.busy() and stack:top().__cbeBattleCache,'initial options own native stack')
 eq(C.status().mode,'choice','initial prompt asks for a mode');eq(C.status().total,0,'no unselected work')
 step(20);eq(#calls,0,'leaving the options idle does not prepare models')
 eq(game.save,nil,'before save load');eq(oldWorldTicks,0,'underlying world has not advanced')
 -- Touch cancellation owns input and never loads a save or discards artifacts.
 local state=stack:top();Runtime.call('render.hud',function()end,game,{});local button=state.buttons[#state.buttons]
 local pointerNext=0
 Runtime.call('input.pointer',function()pointerNext=pointerNext+1 end,game,{phase='pressed',source='touch',x=button.x+4,y=button.y+4})
 step();yes(not C.busy() and not C.ready(),'cancel cannot publish full readiness')
 eq(stack:top(),nativeMenu,'cancel returns native menu');eq(pointerNext,0,'touch consumed')
 eq(continueCount+newCount,0,'no save callback on cancel')
 -- Quick Continue errors still block; a shorter plan is not a fail-open path.
 chooseContinue();faults['2:normal']='controlled extraction error';finish()
 yes(C.status().error and not C.ready(),'failed quick entry not ready')
 eq(C.status().done,1,'failed row not counted');eq(continueCount,0,'Continue blocked')
 pressed.b=true;step();eq(stack:top(),nativeMenu,'error cancel returns title')
 faults={};chooseContinue();finish()
 yes(C.quickReady(C.quickPlan(game,save)),'exact team readiness')
 yes(not C.ready() and not C.busy(),'quick completion never claims full catalog')
 eq(C.status().total,3,'no unrequested species added')
 if gen==1 then restoreMenu()
 else
  eq(nativeMenu.phase,'confirm','Gen II native Continue confirm preserved');eq(nativeMenu.confirmDelay,20,'native delay preserved')
  step(20);pressed.a=true;step();eq(continueCount,1,'native callback exactly once');nativeMenu.phase='menu'
 end
 eq(warmed,0,'no overworld prewarm before save loads')
 local before=#calls;chooseContinue();yes(not C.busy(),'warm team does not reopen screen')
 eq(#calls,before,'warm re-entry does no preparation');restoreMenu()
 -- Selecting a changed save/party must not use a global ready bit from another.
 save.party[4]={dex=6,shiny=true};chooseContinue();yes(C.busy(),'changed party checked')
 eq(C.status().total,4,'new team identity included');finish();restoreMenu()
 yes(prepared['6:shiny'],'separate rare shiny prepared, no normal substitution')
 -- Full catalog is an explicit menu selection, with team first for useful
 -- cancellation. Merely opening the choice page performs no model work.
 if gen==1 then nativeMenu.items[#nativeMenu.items].onSelect()else nativeMenu:choose('cbe_battle_cache')end
 local menu=stack:top();yes(menu.selector and C.status().mode=='choice','cache row opens choice screen')
 eq(menu.choice,1,'quick is default');before=#calls;step();eq(#calls,before,'choice page does not bake')
 Runtime.call('render.hud',function()end,game,{});local full=menu.buttons[2]
 Runtime.call('input.pointer',function()pointerNext=pointerNext+1 end,game,{phase='pressed',source='mouse',button=1,x=full.x+4,y=full.y+4})
 step();eq(C.status().mode,'full','explicit full request');eq(C.status().total,502,'all identities retained')
 local fullState=stack:top();eq(fullState.rows[1].dex,1,'team first');eq(fullState.rows[3].variant,'shiny','team colour first')
 finish();yes(C.ready(),'full completion publishes full readiness');eq(stack:top(),nativeMenu,'full returns title')
 for dex=1,251 do yes(prepared[key(dex,'normal')] and prepared[key(dex,'shiny')],'full coverage '..dex)end
 -- OFF stays OFF. New Game uses only its native starter models, not the old
 -- saved party and not the entire catalog; cancellation preserves the save.
 C._test.reset();prepared={};epoch=epoch+1;save.colosseumBattle.pokemonModelsEnabled=false
 chooseContinue();yes(not C.busy(),'models OFF continue');restoreMenu()
 if gen==1 then nativeMenu.items[2].onSelect()else nativeMenu:choose('new')end
 yes(C.busy() and stack:top().selector,'New Game starter choice guarded');eq(C.status().total,0,'no starter bake before selection')
 step();pressed.a=true;step();eq(C.status().mode,'startup','explicit starter selection');yes(C.status().total<=3,'only starter models')
 pressed.b=true;step();eq(newCount,0,'cancel New Game preserves save')
 save.colosseumBattle.pokemonModelsEnabled=true
 -- Cancellation unwinds a yielded source task, not only its screen.
 slow=true;C.open(game,{{dex=100,variant='shiny'}});step();yes(stack:top().task~=nil,'yielded task resumable')
 pressed.b=true;step();eq(cancelled,1,'cancel cleanup runs once');slow=false
 -- Runtime readiness retains exact identities and authoritative objects while
 -- buffering on the update boundary, without creating a cache screen.
 game.save=save;prepared={};local screen={game=game};local slots={}
 local defs={A={index=100},B={index=156},C={index=246}};game.data={pokemon=defs}
 local mons={{species='A'},{species='A',shiny=true},{species='B'},{species='C',dvs={attack=10,defense=10,speed=10,special=10}}}
 for i,id in ipairs{'player-left','player-right','enemy-left','enemy-right'}do slots[id]={mon=mons[i]}end
 V.DoublesRuntime={combat=function()return {core={slots=slots}}end}
 -- Preview residency alone must not bypass action-sidecar preparation.
 for _,mon in ipairs(mons)do local d,v=V.ModelIdentity.resolve(game,mon);prepared[key(d,v)]=true end
 stack:push(screen);B.update(screen,.016)
 yes(not C.busy(),'runtime never opens cache screen');eq(updated,1,'native combat advances after synchronous preparation');eq(C.runtimeStatus(game).prepared,4,'four exact identities')
 eq(stack:top(),screen,'native battle remains current');B.update(screen,.016);eq(updated,2,'warm battle progresses')
 for i,id in ipairs{'player-left','player-right','enemy-left','enemy-right'}do eq(slots[id].mon,mons[i],'authoritative object unchanged')end
 slots['enemy-right'].mon={species='C'};B.update(screen,.016);yes(not C.busy(),'replacement variant buffers without a screen');eq(C.runtimeStatus(game).prepared,5,'replacement variant prepared')
 C.noteRenderError(game,'GPU draw failed');B.update(screen,.016);yes(C.runtimeStatus(game).error and not C.ready(),'renderer fault explicit')
 local beforeError=updated;pressed.b=true;B.update(screen,.016);pressed={};eq(updated,beforeError,'battle error cannot be cancelled into sprite mode')
 pressed.a=true;B.update(screen,.016);pressed={};yes(not C.runtimeStatus(game).error,'renderer retry explicit');yes(not C.busy(),'retry never opens screen')
 local d,why=V.ModelIdentity.resolve(game,{species='MISSING'});yes(not d and why,'invalid identity refused')
 eq(select(2,V.ModelIdentity.resolve(game,{mon=mons[4]})),'shiny','Gen II DVs preserved')
 C._test.reset();stack:clear();B.update=originalUpdate;B.__cbeModelCache=nil
 if Main then Main.choose=originalChoose;Main.__cbeModelCache=nil end
 Save.load=loadSave;love.filesystem.getInfo=oldInfo
end
require('src.core.Logger').warn=oldWarn
Runtime.reset();eq(#warnings,0,'no hook fail-open warnings')
print('NativeModelCacheTests: '..checks..' checks PASS; actual Gen I/II menu/hooks/stack, controlled source/GPU')
