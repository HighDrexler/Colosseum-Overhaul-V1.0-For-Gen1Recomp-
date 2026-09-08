-- Real engine Input, Hooks and StateStack; deterministic model/cache fixtures.
-- Opening title/model-cache UI must NEVER grant consent to a preparation task.
package.path='./?.lua;./?/init.lua;'..package.path
require('tests.modkit')
local Hooks=require('src.mods.Hooks');local Runtime=require('src.mods.Runtime')
local Stack=require('src.core.StateStack');local Input=require('src.core.Input')
local root=assert(os.getenv('UI_COMPAT_DIR'))
local function M(path,v)return assert(loadfile(root..'/'..path))(v)end
local count=0
local function yes(v,m)count=count+1;assert(v,m)end
local function eq(a,b,m)count=count+1;assert(a==b,m..': '..tostring(a)..' ~= '..tostring(b))end
for _,gen in ipairs{1,2} do for _,osName in ipairs{'Windows','Android'} do
 local now=0;love.timer.getTime=function()return now end
 love.system=love.system or {};love.system.getOS=function()return osName end
 local hooks=Hooks.new();Runtime.install({emit=function()end},hooks,{})
 local stack=setmetatable({}, {__index=Stack});stack:init()
 local input=setmetatable({}, {__index=Input});input:init()
 local save={party={{dex=100,level=16},{dex=6,level=20,shiny=true}},
  colosseumBattle={pokemonModelsEnabled=true},pokedex={seen={},owned={}}}
 local game={save=save,data={pokemon={}},stack=stack,input=input}
 local native={update=function()end};stack:push(native)
 local resident,disk={},{};local builds,inventory,writes,prewarms=0,0,0,0
 local loadCount,newCount=0,0;local fail
 local B={update=function()end};local Main={choose=function(_,v)
  if v=='continue'then loadCount=loadCount+1 elseif v=='new'then newCount=newCount+1 end
 end}
 local V={mod={hooks=hooks,cache={write=function()writes=writes+1;return true end}},
  ShinySupport=M('lib/ShinySupport.lua'),ColosseumDex=M('lib/ColosseumDex.lua'),
  WorkBudget=M('lib/WorkBudget.lua'),GenerationCompat={current=function()return gen end},
  ResidentPrewarm={cancel=function()end,queueStartup=function()prewarms=prewarms+1 end}}
 V.engineRequire=function(name)
  if name=='src.core.SaveData' or name=='src.core.gen2.Save'then return {load=function()return save end}end
  if name=='src.core.GameVersion'then return {get=function()return gen==1 and 'red' or 'gold'end}end
  if name=='src.core.Strings'then return function(s)return s end end
  if name=='src.battle.BattleState' or name=='src.ui.gen2.BattleState'then return B end
  if name=='src.ui.gen2.MainMenu'then return Main end
  error('unneeded import '..name)
 end
 V.ModelIdentity=M('lib/ModelIdentity.lua',V);V.QuickCachePlanner=M('lib/QuickCachePlanner.lua',V)
 V.PokemonActors={sessionCacheIdentity=function()return 'consent-test' end,
  peek=function(_,d,v)return {resident=resident[d..':'..v]}end,
  persistentModelState=function(d,v,progress)
   inventory=inventory+1;progress('Checking completed files')
   return disk[V.ColosseumDex.modelKey(d,v)]==true
  end,
  prepareSessionModel=function(d,v)
   builds=builds+1;if d==fail then return false,'controlled build error'end
   resident[d..':'..v]=true;disk[V.ColosseumDex.modelKey(d,v)]=true;return true,'resident'
  end}
 local C=M('lib/BattleCache.lua',V);C.install()
 local sourceRows={{label='CONTINUE',value='continue',keepOpen=true},
  {label='NEW GAME',value='new',keepOpen=true}}
 if gen==1 then
  sourceRows[1].onSelect=function()loadCount=loadCount+1 end
  sourceRows[2].onSelect=function()newCount=newCount+1 end
 end
 local items=Runtime.call('ui.title_menu.items',function(_,rows)return rows end,game,sourceRows)
 local function tick(n)
  for _=1,n or 1 do
   now=now+1/60;Runtime.call('input.step',function()end,game,1/60)
   input:step();stack:update(1/60)
  end
 end
 local function tap(k)input:keypressed(k);tick();input:keyreleased(k);tick()end
 local function request(kind)
  if gen==1 then items[kind=='continue' and 1 or 2].onSelect()
  else Main.choose({game=game,save=save},kind)end
 end
 local function manual()
  if gen==1 then items[#items].onSelect()else Main.choose({game=game,save=save},'cbe_battle_cache')end
 end
 local function untilTrue(fn)
  for _=1,100 do if fn()then return end;tick()end;error('state did not finish')
 end
 local function assertNoWork(beforeBuilds,beforeInventory,beforeWrites,label)
  -- A selector may now perform a read-only persisted-cache eligibility scan so it
  -- can expose REUSE CACHE at >=30 units. That scan is not preparation consent:
  -- it may increase inventory probes, but it must never build or write a model.
  eq(builds,beforeBuilds,label..' builds');yes(inventory>=beforeInventory,label..' read-only inventory only');eq(writes,beforeWrites,label..' writes')
 end
 -- The input hook precedes Input:step in BOTH real engines. A title-opening
 -- press may be queued rather than visible to wasPressed when options open.
 input:keypressed('z');tick()
 eq(C.status().mode,'choice','initial title prompt offers choices, not startup work')
 local selector=stack:top();yes(selector.selector and not selector.task,'no worker created just by opening')
 tick(120);yes(stack:top()==selector and not selector.selectionArmed,'held opening A cannot confirm default')
 selector.buttons={{key='quick',x=10,y=10,w=100,h=40}}
 Runtime.call('input.pointer',function()error('pointer leaked to title')end,game,
  {phase='pressed',source='touch',x=20,y=20})
 tick();eq(selector.pointerAction,nil,'pointer ignored until initial confirmation released')
 assertNoWork(0,0,0,'unselected options')
 input:keyreleased('z');tick();yes(selector.selectionArmed,'neutral step arms fresh choice')
 tick(60);assertNoWork(0,0,0,'idle options after release')
 tap('x');eq(stack:top(),native,'Back returns to native menu');eq(prewarms,0,'Back from choices cannot enqueue background models')
 tick(5);yes(not C.busy(),'cancelled prompt is not queued again')
 -- Navigation and cancel do not start the highlighted mode.
 manual();tick();selector=stack:top();tap('up');eq(selector.choice,3,'up wraps to Back')
 tap('z');eq(stack:top(),native,'explicit Back row closes without work');assertNoWork(0,0,0,'navigation only')
 -- A new touchscreen/mouse choice is accepted after arming; it grants only
 -- its named mode, and inventory/extraction begins AFTER that selection.
 manual();tick();selector=stack:top();selector.buttons={{key='quick',x=10,y=10,w=100,h=40}}
 local fallthrough=0
 Runtime.call('input.pointer',function()fallthrough=fallthrough+1 end,game,
  {phase='pressed',source='mouse',button=2,x=20,y=20})
 tick();eq(C.status().mode,'choice','right mouse button cannot start work')
 Runtime.call('input.pointer',function()fallthrough=fallthrough+1 end,game,
  {phase='pressed',source='touch',x=20,y=20})
 tick();eq(C.status().mode,'quick','explicit touch Quick Start selects quick mode')
 assertNoWork(0,0,0,'mode-selection step');eq(fallthrough,0,'cache consumes pointer')
 local batch=stack:top();untilTrue(function()return batch.complete end)
 eq(#batch.rows,30,'explicit quick still builds a 30-new-model batch')
 eq(C.status().cachedModels,30,'batch completion retained')
 tap('z');eq(stack:top(),native,'acknowledged batch returns, no automatic next batch')
 local oldBuilds,oldInventory,oldWrites=builds,inventory,writes
 manual();tick(50);assertNoWork(oldBuilds,oldInventory,oldWrites,'reopened manual options')
 stack:pop();yes(not C.busy(),'external pop releases selector')
 -- Continue has a team-only choice. It cannot start team extraction from the
 -- same confirm that selected Continue, and B cannot load the save.
 resident={};request('continue');selector=stack:top()
 yes(selector.selector and selector.startupRequest,'cold Continue shows options')
 eq(selector.startupRequest.newGame,false,'Continue context identified')
 input:keypressed('z');tick(60);assertNoWork(oldBuilds,oldInventory,oldWrites,'Continue opening confirm held')
 input:keyreleased('z');tick();tap('x');eq(loadCount,0,'cancelled Continue never loads save')
 request('continue');tick();tap('up');eq(stack:top().choice,4,'four-choice wrap includes Back')
 tap('down');eq(stack:top().choice,1,'wrap returns to required team only')
 fail=6;tap('z');untilTrue(function()return C.status().error~=nil end)
 eq(loadCount,0,'failed team build cannot Continue');eq(C.status().total,2,'team-only work is not a new batch')
 tap('x');fail=nil;request('continue');tick();tap('z');untilTrue(function()return not C.busy()end)
 eq(loadCount,1,'explicit team-only success resumes native Continue once')
 oldBuilds=builds;request('continue');eq(loadCount,2,'already session-ready Continue proceeds normally')
 eq(builds,oldBuilds,'already ready Continue builds nothing');yes(not C.busy(),'no redundant chooser when no work remains')
 -- New Game does not inherit the old save's party for model batch priorities.
 resident={};request('new');selector=stack:top();yes(selector.startupRequest.newGame,'New Game context')
 eq(selector.selectedSave.party[1].dex,gen==1 and 1 or 152,'new-game options prioritize native starters')
 eq(save.party[1].dex,100,'old save party unchanged');eq(#save.party,2,'old party size unchanged')
 tick();selector.pointerAction='quick';tick();local newBatch=stack:top()
 untilTrue(function()return not newBatch.planning end)
 local expectedStarter
 for _,r in ipairs(C.startupPlan(game,nil,true)) do
  if not disk[V.ColosseumDex.modelKey(r.dex,r.variant)] then expectedStarter=r.dex;break end
 end
 if expectedStarter then eq(newBatch.rows[1].dex,expectedStarter,'explicit new-game Quick prioritizes uncached starters')
 else
  for _,r in ipairs(newBatch.rows) do yes(not disk[V.ColosseumDex.modelKey(r.dex,r.variant)],'cached starters are not reselected')end
 end
 tap('x');eq(newCount,0,'cancelling optional batch never begins New Game')
 request('new');tick();tap('z');untilTrue(function()return not C.busy()end)
 eq(newCount,1,'explicit starter-only success resumes New Game once')
 -- Full catalog also needs an explicit selection and has no hidden team/load
 -- callback. Exiting before the worker starts leaves all completed disk work.
 resident={};request('continue');tick();selector=stack:top();selector.pointerAction='full';tick()
 eq(C.status().mode,'full','explicit Full selection works in contextual options')
 eq(C.status().total,502,'full scope unchanged')
 local startBuilds=builds;stack:pop();tick();eq(builds,startBuilds,'external removal never runs unstarted full work')
 eq(loadCount,2,'optional full cancellation does not Continue')
 -- An explicitly opening chooser consumes any deferred initial title prompt.
 C._test.reset();Runtime.call('ui.title_menu.items',function(_,rows)return rows end,game,sourceRows)
 manual();stack:pop();tick();yes(not C.busy(),'manual open clears deferred automatic prompt')
 save.colosseumBattle.pokemonModelsEnabled=false
 request('continue');yes(not C.busy(),'models OFF keeps native Continue');eq(loadCount,3,'OFF callback intact')
 C._test.reset();stack:clear();Runtime.reset()
end end
local f=assert(io.open(root..'/main.lua','r'));local main=f:read('*a');f:close()
yes(main:find('prepare=function%(game%)return BattleCache%.openMenu'), 'generic public prepare opens options')
yes(main:find('prepareStartup=function%(game%)return BattleCache%.requestStartup'), 'public startup request also asks first')
yes(main:find('prepareQuick=function%(game%)return BattleCache%.openQuick'), 'explicit quick service retained')
yes(main:find('prepareFull=function%(game%)return BattleCache%.openFull'), 'explicit full service retained')
print('CacheChoiceConsentTests: '..count..' checks PASS; both generations/platform profiles, real Input/stack/hooks; source/GPU fixtures')
