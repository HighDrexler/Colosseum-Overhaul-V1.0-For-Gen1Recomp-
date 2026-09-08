-- Actual engine hook and StateStack teardown; controlled model work. No ROM/GPU.
package.path='./?.lua;./?/init.lua;'..package.path
local T=require('tests.modkit')
local Hooks=require('src.mods.Hooks');local Runtime=require('src.mods.Runtime')
local Stack=require('src.core.StateStack');local root=assert(os.getenv('UI_COMPAT_DIR'))
local function M(p,v)return assert(loadfile(root..'/'..p))(v)end
local count=0
local function yes(v,msg)count=count+1;assert(v,msg)end
local function eq(a,b,msg)count=count+1;assert(a==b,msg..': '..tostring(a)..' ~= '..tostring(b))end
for _,gen in ipairs{1,2}do
 local now=0;love.timer.getTime=function()return now end
 local hooks=Hooks.new();Runtime.install({emit=function()end},hooks,{})
 local stack=setmetatable({}, {__index=Stack});stack:init()
 local keys={};local save={party={{dex=25,level=15}},colosseumBattle={pokemonModelsEnabled=true}}
 local game={data={pokemon={}},stack=stack,input={wasPressed=function(_,key)return keys[key]end}}
 local base={};stack:push(base)
 local saved,prepared={},{};local cleanup,callbacks=0,0;local slow=false;local language='english'
 local labels={CONTINUE='REPRENDRE',['NEW GAME']='COMMENCER'}
 local V={mod={hooks=hooks,cache={write=function()return true end}},
  GenerationCompat={current=function()return gen end},ShinySupport=M('lib/ShinySupport.lua'),
  WorkBudget=M('lib/WorkBudget.lua')}
 local B={update=function()end};local Main={choose=function()end}
 V.engineRequire=function(n)
  if n=='src.core.Strings'then return function(s)return language=='english' and s or labels[s] or s end end
  if n=='src.core.SaveData' or n=='src.core.gen2.Save'then return {load=function()return save end}end
  if n=='src.core.GameVersion'then return {get=function()return gen==1 and 'red' or 'gold'end}end
  if n=='src.battle.BattleState' or n=='src.ui.gen2.BattleState'then return B end
  if n=='src.ui.gen2.MainMenu'then return Main end
  error('unneeded dependency '..n)
 end
 V.ModelIdentity=M('lib/ModelIdentity.lua',V)
 V.PokemonActors={sessionCacheIdentity=function()return 'same-cache-stamp'end,
  peek=function(_,d,v)return {resident=prepared[d..':'..v]==true}end,
  prepareSessionModel=function(d,v,checkpoint)
   if slow then
    V.WorkBudget.onCancel(function()cleanup=cleanup+1 end)
    now=now+.03;checkpoint('cooperative source work')
   end
   saved[d]=true;prepared[d..':'..v]=true;return true,'prepared'
  end}
 local C=M('lib/BattleCache.lua',V);C.install()
 local function step()now=now+.02;stack:update(.016);keys={}end
 local function selectStartup()
  yes(C.busy() and stack:top().selector,'startup action opens chooser')
  step();keys.a=true;step();eq(C.status().mode,'startup','explicit required-only choice')
 end
 local function finish()for _=1,50 do if not C.busy()then return end;step()end;error('worker did not finish')end
 -- External pop/clear must cancel an in-flight task without claiming completion
 -- or invoking its deferred Continue callback. Already saved units stay saved.
 saved[1]=true;slow=true
 yes(C.open(game,{{dex=25,variant='normal'}},function()callbacks=callbacks+1 end,false,'startup'),'open worker')
 step();local state=stack:top();yes(state.task~=nil,'work yielded')
 stack:pop();yes(not C.busy(),'external pop released cache ownership')
 eq(cleanup,1,'external pop cancelled source worker once');eq(callbacks,0,'cancel did not run Continue')
 yes(saved[1] and not saved[25],'saved completion retained, unfinished unit not marked ready')
 state:exit();eq(cleanup,1,'repeated exit is idempotent')
 yes(C.open(game,{{dex=25,variant='normal'}},nil,false,'startup'),'reopen after external pop')
 step();stack:clear();eq(cleanup,2,'whole-stack reset cancelled worker');yes(not C.busy(),'whole-stack reset released owner')
 stack:push(base);slow=false;yes(C.open(game,{{dex=25,variant='normal'}},function()callbacks=callbacks+1 end,false,'startup'),'reopen after clear')
 finish();eq(callbacks,1,'successful callback still once');yes(saved[25],'new completed model retained')
 yes(C.openMenu(game,save),'open selector');stack:pop();yes(not C.busy(),'selector external pop also released owner')
 if gen==1 then
  for _,lang in ipairs{'english','translated'}do
   language=lang;prepared={};C._test.reset()
   local counts={continue=0,new=0,options=0,exit=0,custom=0}
   local function fn(k)return function()counts[k]=counts[k]+1 end end
   local labelContinue=lang=='english' and 'CONTINUE' or labels.CONTINUE
   local labelNew=lang=='english' and 'NEW GAME' or labels['NEW GAME']
   -- Neither array position nor keepOpen identifies a game's entry action.
   local items={{label='CUSTOM TOOLS',onSelect=fn('custom')},
    {label='EXIT GAME',onSelect=fn('exit')},
    {label='OPTIONS',keepOpen=true,onSelect=fn('options')},
    {label=labelContinue,keepOpen=true,onSelect=fn('continue')},
    {label=labelNew,onSelect=fn('new')}}
   local out=Runtime.call('ui.title_menu.items',function(_,rows)return rows end,game,items)
   eq(#out,6,'one cache row appended')
   for i=1,3 do
    eq(out[i].onSelect,items[i].onSelect,'foreign action not intercepted')
    eq(out[i].keepOpen,items[i].keepOpen,'foreign closing semantics preserved')
    out[i].onSelect();yes(not C.busy(),'foreign action does not start cache')
   end
   eq(counts.custom+counts.exit+counts.options,3,'foreign callbacks preserved')
   yes(items[4].__cbeStartupGuard==nil and items[5].keepOpen==nil,'input rows never mutated')
   local menu={items=out};stack:push(menu)
   out[4].onSelect();yes(C.busy(),'reordered translated Continue guarded')
   eq(counts.continue,0,'Continue waits for models');selectStartup();finish()
   eq(counts.continue,1,'Continue invoked once after models');eq(stack:top(),menu,'Continue keepOpen retained')
   -- A second hook pass must not double-wrap or create another BATTLE CACHE row.
   local second=Runtime.call('ui.title_menu.items',function(_,rows)return rows end,game,out)
   eq(#second,#out,'cache entry deduplicated on repeated hook pass')
   eq(second[4].onSelect,out[4].onSelect,'Continue not double-wrapped')
   eq(second[5].onSelect,out[5].onSelect,'New Game not double-wrapped')
   second[5].onSelect();yes(C.busy(),'reordered New Game guarded')
   eq(counts.new,0,'New Game waits for starter preparation');selectStartup();finish()
   eq(counts.new,1,'New Game invoked once');eq(stack:top(),base,'New Game native closing semantics retained')
   -- Explicit semantic values still work for a provider's custom display label.
   local named={{label='LOAD ADVENTURE',value='continue',keepOpen=true,onSelect=fn('continue')},
     {label='FRESH ADVENTURE',value='new',onSelect=fn('new')}}
   local n=Runtime.call('ui.title_menu.items',function(_,rows)return rows end,game,named)
   yes(n[1].__cbeStartupGuard and n[2].__cbeStartupGuard,'semantic action values recognized')
  end
 end
 C._test.reset();stack:clear();Runtime.reset()
end
print('ReleaseLifecycleCompatibilityTests: '..count..' checks PASS; native hook/stack, external cancellation, localized/reordered menus, no duplicate cache rows')
