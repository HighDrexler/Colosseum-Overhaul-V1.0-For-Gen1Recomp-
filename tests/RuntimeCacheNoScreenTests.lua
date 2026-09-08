-- Exercise the installed update hooks for both generations with controlled host
-- objects. Real engine/ROM integration remains a separate release check.
local checks=0
local function eq(a,b,label)checks=checks+1;assert(a==b,label..': '..tostring(a)..' ~= '..tostring(b))end
for _,gen in ipairs{1,2} do
  local now,updates,builds,pushes,pumps,writes,quits,notices=0,0,0,0,0,0,0,0
  local keys,resident,ready={}, {}, {}
  local epoch='a';local fail,throwing=false,false
  local screen;local top;local building=false;local cleanup=0
  love={timer={getTime=function()return now end},system={getOS=function()return 'Android'end},
    graphics={getDimensions=function()return 1280,720 end,push=function()end,pop=function()end,
      origin=function()end,setShader=function()end,setScissor=function()end,setBlendMode=function()end},
    event={pump=function()pumps=pumps+1;eq(updates,0,'cold preparation cannot advance native combat')end,
      quit=function()quits=quits+1 end}}
  local game={save={party={},colosseumBattle={pokemonModelsEnabled=true}},input={wasPressed=function(_,k)return keys[k]end}}
  game.stack={top=function()return top end,push=function(_,s)pushes=pushes+1;top=s end,pop=function()top=nil end}
  local function key(d,v)return tostring(d)..':'..v end
  local B={update=function()assert(not building);updates=updates+1 end}
  local W=assert(loadfile('lib/WorkBudget.lua'))()
  local V={mod={game=game,cache={write=function()writes=writes+1 end},hooks={wrap=function()end}},
    GenerationCompat={current=function()return gen end,prepare=function(s)return s end},
    engineRequire=function(name)
      if name==(gen==2 and 'src.ui.gen2.BattleState' or 'src.battle.BattleState')then return B end
      error('unused host module '..name)
    end,
    ModelIdentity={resolve=function(_,m)if not m.dex then return nil,'unknown species' end;return m.dex,m.shiny and 'shiny' or 'normal' end},
    WorkBudget=W,
    CacheScreen={draw=function()error('runtime must never draw full-screen cache UI')end,
      drawRuntimeError=function()notices=notices+1 end},
    PokemonActors={sessionCacheIdentity=function()return epoch end,
      peek=function(_,d,v)return {resident=resident[key(d,v)]}end,
      sessionModelReady=function(d,v)return ready[key(d,v)]==epoch and resident[key(d,v)] end,
      prepareSessionModel=function(d,v,checkpoint)
        builds=builds+1;building=true
        now=now+.06;checkpoint();building=false
        if throwing then W.onCancel(function()cleanup=cleanup+1 end);error('GPU unavailable')end
        if fail then return false,'source unavailable' end
        resident[key(d,v)]=true;ready[key(d,v)]=epoch;return true,'prepared'
      end}}
  local C=assert(loadfile('lib/BattleCache.lua'))(V);C.install()
  screen={game=game,player={dex=25},enemy={dex=6,shiny=true}};top=screen
  B.update(screen,.016)
  eq(builds,2,'cold exact pair prepared');eq(updates,1,'native update resumes after readiness')
  eq(pushes,0,'cold encounter never pushes cache state');eq(C.busy(),false,'no modal loading state')
  eq(pumps,2,'long checkpoints pump OS messages');eq(C.status().runtimeLoadingScreen,false,'status contract')
  eq(C.drawHud(function()return 'native hud'end,game),'native hud','native HUD result retained')
  eq(notices,0,'successful buffering has no runtime notice')
  for _=1,100 do B.update(screen,.016)end
  eq(builds,2,'100 warm frames do no preparation');eq(pushes,0,'warm encounter no cache screen')
  -- A shared-body normal/shiny pair is still checked as two exact appearances.
  updates=0;screen.enemy={dex=25,shiny=true};B.update(screen,.016)
  eq(builds,3,'Transform/switch exact appearance checked');eq(updates,1,'switch advances after preparation')
  local slots={};local mons={{dex=25},{dex=25,shiny=true},{dex=156},{dex=246,shiny=true}}
  for i,id in ipairs{'player-left','player-right','enemy-left','enemy-right'}do slots[id]={mon=mons[i]}end
  V.DoublesRuntime={combat=function()return {core={slots=slots}}end}
  updates=0;B.update(screen,.016);eq(builds,5,'doubles prepares only two new identities')
  eq(updates,1,'doubles native update resumes');eq(pushes,0,'doubles no modal')
  for i,id in ipairs{'player-left','player-right','enemy-left','enemy-right'}do eq(slots[id].mon,mons[i],'authoritative battler retained')end
  slots['enemy-right'].mon=mons[1];updates=0;B.update(screen,.016);eq(builds,5,'duplicate identity no extra work')
  resident[key(25,'normal')]=nil;updates=0;B.update(screen,.016);eq(builds,6,'evicted body reloads silently')
  epoch='b';updates=0;B.update(screen,.016);eq(builds,9,'epoch change invalidates three unique models')
  ready[key(25,'normal')]=nil;updates=0;B.update(screen,.016)
  eq(builds,10,'explicit cache validation revocation overrides controller memo')
  -- Fail closed, no sprite substitution, no per-frame retry/log storm, no popup.
  V.DoublesRuntime=nil;screen.enemy={dex=99};fail=true;updates=0;B.update(screen,.016)
  eq(updates,0,'source failure holds battle');eq(C.runtimeStatus(game).error,'source unavailable','failure exposed')
  local attempts=builds;for _=1,30 do B.update(screen,.016)end
  C.drawHud(function()end,game);eq(notices,1,'fault only draws compact notice')
  top={};C.drawHud(function()end,game);eq(notices,1,'covered battle does not leak notice');top=screen
  eq(builds,attempts,'failure retries back off');eq(writes,1,'same fault logged once');eq(pushes,0,'failure no cache screen')
  keys.start=true;B.update(screen,.016);eq(quits,1,'explicit exit available while fault held');keys={}
  fail=false;keys.a=true;B.update(screen,.016);keys={}
  eq(updates,1,'manual retry resumes native battle');eq(C.runtimeStatus(game).error,nil,'successful retry clears fault')
  C.drawHud(function()end,game);eq(notices,1,'recovered battle has no notice')
  updates=0;screen.enemy={dex=101};throwing=true;B.update(screen,.016)
  eq(updates,0,'thrown GPU error also holds');eq(pushes,0,'thrown error no modal')
  eq(cleanup,1,'failed runtime worker releases registered resources')
  throwing=false;now=now+9;B.update(screen,.016);eq(updates,1,'automatic retry recovers')
  updates=0;C.noteRenderError(game,'draw failed');B.update(screen,.016)
  eq(updates,0,'renderer error retains readiness barrier');eq(C.runtimeStatus(game).kind,'renderer','renderer fault identified')
  keys.a=true;B.update(screen,.016);keys={};eq(updates,1,'renderer retry releases one native update')
  updates=0;game.save.colosseumBattle.pokemonModelsEnabled=false;screen.enemy={dex=201}
  local before=builds;B.update(screen,.016);eq(updates,1,'Models OFF native behavior');eq(builds,before,'Models OFF no source work')
  eq(C.open(game,{},nil,true),false,'legacy public battle-open cannot show screen')
  eq(pushes,0,'all runtime paths preserve native stack')
end
print('RuntimeCacheNoScreenTests: '..checks..' checks PASS; Gen I/II hook fixtures, cold/warm/switch/doubles/shiny/eviction/faults')
