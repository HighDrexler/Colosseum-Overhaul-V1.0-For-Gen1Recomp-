-- Real disk-validation/preparation code, synthetic source and graphics. A fresh
-- module instance deliberately shares only persisted files with the previous run.
local H=assert(loadfile('tests/support/ShinyHarness.lua'))()
local function loadM(p,v)return assert(loadfile(p))(v)end
local checks=0
local function yes(v,msg)checks=checks+1;assert(v,msg)end
local function eq(a,b,msg)checks=checks+1;assert(a==b,msg..': '..tostring(a)..' ~= '..tostring(b))end
local function total(t)local n=0;for _,v in pairs(t)do n=n+v end;return n end
local function has(rows,d,v)for i,r in ipairs(rows)do if r.dex==d and (not v or r.variant==v)then return i,r end end end
local function planner(h,gen)
 local V={ColosseumDex=h.Dex,ShinySupport=h.Shiny,GenerationCompat={current=function()return gen end}}
 V.ModelIdentity=loadM('lib/ModelIdentity.lua',V);V.QuickCachePlanner=loadM('lib/QuickCachePlanner.lua',V)
 return V,V.QuickCachePlanner
end
for _,gen in ipairs{1,2}do
 local h=H.new({disk=true});local V,P=planner(h,gen)
 eq(P.batchSize,30,'latest user-selected batch cap')
 local pokemon={}
 for d=1,251 do pokemon['MON'..d]={dex=d,name='Mon '..d,evolutions={}} end
 pokemon.MON25.evolutions={{method='LEVEL',level=23,species='MON26'}}
 local game={generation=gen,data={pokemon=pokemon}}
 local save={party={{species='MON25',level=20},{species='MON6',level=18,shiny=true}},
  boxes={{{species='MON156',level=21}}},position={map='HERE'},pokedex={seen={MON100=true},caught={MON246=true}}}
 if gen==1 then save.pokedex.owned=save.pokedex.caught;save.pokedex.caught=nil end
 game.data[gen==1 and 'maps' or 'gen2Maps']={HERE={connections={east={map='NEXT'}}}}
 if gen==1 then
  game.data.encounters={HERE={grass={{species='MON58',level=20}}},NEXT={water={{species='MON60',level=20}}},OTHER={grass={{species='MON147',level=20},{species='MON149',level=65}}}}
 else game.data.gen2Encounters={grass={HERE={day={{species='MON58',level=20}}},NEXT={day={{species='MON60',level=20}}},OTHER={day={{species='MON147',level=20},{species='MON149',level=65}}}}}end
 local ranked,profile=P.rank(game,save)
 eq(profile.level,18,'team median level');eq(profile.caught,1,'native caught/owned map');eq(profile.seen,1,'seen map')
 yes(has(ranked,25)<has(ranked,58),'team first');yes(has(ranked,6,'shiny')<has(ranked,6,'normal'),'owned exact shiny first')
 yes(has(ranked,58)<has(ranked,147),'current encounter before remote same-level')
 yes(has(ranked,156)<has(ranked,100),'owned PC before seen')
 yes(has(ranked,246)<has(ranked,100),'caught before seen')
 yes(has(ranked,26)<has(ranked,147),'near evolution before remote same-level')
 yes(has(ranked,147)<has(ranked,149),'matching level before distant level')
 local selected,info=P.select(game,save,h.A.persistentModelState)
 eq(#selected,30,'first selection contains 30 new source models');eq(info.cachedModels,0,'cold disk is empty')
 local completed={};local covered=0
 -- Complete 7 units and leave mid-batch. Other 23 must not be marked complete.
 for i=1,7 do
  local row=selected[i];for _,variant in ipairs(row.variants)do yes(h.A.prepareSessionModel(row.dex,variant),'first partial batch unit')end
  completed[row.key]=true;covered=covered+#row.variants
 end
 local files=h.files
 local fresh=H.new({disk=true,files=files,os='Android'});local V2,P2=planner(fresh,gen);fresh.source=false
 local following,snapshot=P2.select(game,save,fresh.A.persistentModelState)
 eq(#following,30,'fresh process selects 30 additional units, not previous list')
 eq(snapshot.cachedModels,7,'partial-batch progress persisted');eq(snapshot.cachedAppearances,covered,'shared shiny counterpart counted')
 for _,r in ipairs(following)do yes(not completed[r.key],'completed unit excluded after restart')end
 eq(total(fresh.writes),0,'inventory does not write');eq(fresh.meshes+fresh.images,0,'inventory does not load GPU models')
 eq(#fresh.extracts+#fresh.metadataReads,0,'inventory never reads source')
 -- Startup reload from fresh disk flags must never re-extract or rewrite any unit.
 for i=1,7 do local row=selected[i];for _,v in ipairs(row.variants)do yes(fresh.A.prepareSessionModel(row.dex,v),'disk-only reload of completed unit')end end
 eq(total(fresh.writes),0,'fresh process warm has zero cache writes')
 eq(#fresh.extracts+#fresh.metadataReads,0,'fresh process warm has zero source reads')
 -- Repeated fresh sessions eventually finish every unit. No in-memory progress
 -- list or selected save is carried across sessions; files are the authority.
 local rounds=0
 repeat
  local session=H.new({disk=true,files=files,os=rounds%2==0 and 'Android' or 'Windows'})
  local _,PP=planner(session,gen);local rows,inv=PP.select(game,save,session.A.persistentModelState)
  if #rows==0 then eq(inv.cachedModels,270,'complete source catalog');eq(inv.cachedAppearances,502,'complete normal/shiny catalog');break end
  eq(#rows,math.min(30,270-inv.cachedModels),'only final batch may be short')
  for _,row in ipairs(rows)do
   yes(not completed[row.key],'no duplicate across fresh sessions')
   for _,variant in ipairs(row.variants)do yes(session.A.prepareSessionModel(row.dex,variant),'finish new model')end
   completed[row.key]=true
  end
  files=session.files;rounds=rounds+1;yes(rounds<=9,'catalog completion is bounded by batch count')
 until false
 eq(rounds,9,'7 completed plus nine chunks reaches all 270')
 local complete=H.new({disk=true,files=files});complete.source=false
 local _,PP=planner(complete,gen)
 local all,newInfo=PP.select(game,{party={{species='MON251',level=100}},pokedex={},boxes={}},complete.A.persistentModelState)
 eq(#all,0,'different save reuses installation cache');eq(newInfo.cachedAppearances,502,'shared persistent catalog')
 eq(total(complete.writes)+#complete.extracts,0,'no recaching when catalog complete')
 -- A known-incomplete/removed unit is eligible, but unrelated completions remain.
 local path=complete.Dex.cacheRoot(25)..'/runtime_mesh_v1/base_01.f32'
 complete.files[path]=nil
 local missing=PP.select(game,save,complete.A.persistentModelState)
 eq(#missing,1,'deletion invalidates only one unit');eq(missing[1].dex,25,'correct damaged unit eligible')
 -- Save data is never mutated by planning.
 eq(save.party[1].level,20,'party level unchanged');eq(save.position.map,'HERE','position unchanged')
end
-- Animation aliases/pages, textures and colour metadata are part of disk
-- completeness. Real validator is exercised without decoding text vertices.
local h=H.new({disk=true});assert(h.A.prepareSessionModel(25,'normal'))
local root=h.Dex.cacheRoot(25)..'/runtime_mesh_v1/'
local stamp='fixture-geometry-37';local base=h.R.readLua(root..'base.lua')
base.actions={idle={},attack={}};h.R.writeLua(root..'base.lua',base)
local function meta(t)t.runtimeMeshVersion=1;t.stamp=stamp;return t end
local mins={};for i=1,13 do mins[i]=0 end
h.R.writeLua(root..'action_idle.lua',meta({groupCount=1}))
h.R.writeLua(root..'action_idle_floor.lua',meta({floorMinYSlots=mins}))
h.files[root..'action_idle_01.f32']=h.files[root..'base_01.f32']
h.R.writeLua(root..'action_attack.lua',meta({alias='idle'}))
yes(h.A.persistentModelState(25,'normal'),'complete authored action/alias accepted')
h.files[root..'action_idle_01.f32']=nil
yes(not h.A.persistentModelState(25,'normal'),'missing action binary is not falsely complete')
h.files[root..'action_idle_01.f32']=h.files[root..'base_01.f32']
yes(h.A.persistentModelState(25,'shiny'),'repaired shared-body action reused')
h.R.writeLua(root..'action_attack.lua',meta({pages={{groupCount=1},{groupCount=1}}}))
for i=1,2 do
 h.files[root..'action_attack_page'..i..'_01.f32']=h.files[root..'base_01.f32']
 h.R.writeLua(root..'action_attack_page'..i..'_floor.lua',meta({floorMinYSlots=mins}))
end
yes(h.A.persistentModelState(25,'normal'),'complete paged action accepted')
h.files[root..'action_attack_page2_floor.lua']=nil
yes(not h.A.persistentModelState(25,'normal'),'missing page descriptor invalidates only this unit')
print('QuickCachePersistenceTests: '..checks..' checks PASS; 30 new units, save-aware rank, partial completion, process restarts, disk-only reuse and all 502 appearances')
