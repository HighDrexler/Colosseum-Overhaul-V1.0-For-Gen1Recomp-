-- Headless palette/settings regression. Exercises shipped functions, not a game.
local root=os.getenv('UI_COMPAT_DIR') or '.'
local count=0
local function yes(v,k) count=count+1;assert(v,k) end
local function eq(a,b,k) count=count+1;assert(a==b,k..': '..tostring(a)..' ~= '..tostring(b)) end
local function near(a,b,k) yes(math.abs(a-b)<.0000001,k) end
local function equalColor(a,b,k) for i=1,4 do near(a[i],b[i],k..' channel '..i) end end
local function read(p) local f=assert(io.open(p,'rb'));local s=f:read('*a');f:close();return s end
local source=read(root..'/UIMain.lua')
local function section(first,last)
 local a=assert(source:find(first,1,true),'missing '..first)
 local b=assert(source:find(last,a+#first,true),'missing '..last)
 return source:sub(a,b-1)
end
local function compile(code,env)
 local f=assert(loadstring(code,'@UIThemeSettings/extracted-shipped-code'))
 if setfenv then setfenv(f,env) end
 return f()
end
local optionReads,epoch=0,0
local values={uiPrimaryColor='default',uiSecondaryColor='default'}
local function makeTheme()
 return assert(loadfile(root..'/lib/UITheme.lua'))({get=function(k) optionReads=optionReads+1;return values[k] end,epoch=function() return epoch end})
end
local theme=makeTheme()
local samples={{.025,.065,.068,.94},{.90,.23,.13,1},{.33,.35,.32,.80},{.18,.2,.19,.75},{1,1,1,0}}
for _,role in ipairs({'surface','trim','selection','accent','hp','art','type','text'}) do
 for _,color in ipairs(samples) do equalColor({theme.color(role,unpack(color))},color,'default preserves original '..role) end
end
local colors={'gold','red','orange','yellow','green','cyan','blue','purple','pink','brown','gray','white','black'}
for _,primary in ipairs(colors) do
 for _,secondary in ipairs(colors) do
  values.uiPrimaryColor=primary;values.uiSecondaryColor=secondary;epoch=epoch+1
  for _,role in ipairs({'surface','trim','selection','accent'}) do
   local rgb={theme.color(role,.78,.14,.10,.53)}
   for i=1,3 do yes(rgb[i]>=0 and rgb[i]<=1,'bounded color') end
   eq(rgb[4],.53,'opacity preserved')
   if role=='surface' or role=='selection' then
    local cap=role=='surface' and .27 or .32
    yes(.2126*rgb[1]+.7152*rgb[2]+.0722*rgb[3]<=cap+.0000001,'pale text keeps dark surface')
   end
  end
  for _,semantic in ipairs({'hp','exp','type','status','gender','portrait','trainer','text','target'}) do
   local original={.96,.70,.09,1}
   equalColor({theme.color(semantic,unpack(original))},original,'semantic colors unchanged')
  end
 end
end
values.uiPrimaryColor='purple';values.uiSecondaryColor='orange';epoch=epoch+1
local p1={theme.color('surface',.055,.105,.115,1)}
local s1={theme.color('accent',.9,.23,.13,1)}
values.uiSecondaryColor='blue';epoch=epoch+1
equalColor({theme.color('surface',.055,.105,.115,1)},p1,'secondary never changes primary')
local s2={theme.color('accent',.9,.23,.13,1)};yes(s1[1]~=s2[1] or s1[3]~=s2[3],'secondary does change accent')
values.uiPrimaryColor='green';epoch=epoch+1
equalColor({theme.color('accent',.9,.23,.13,1)},s2,'primary never changes secondary')
local p2={theme.color('surface',.055,.105,.115,1)};yes(p1[1]~=p2[1] or p1[3]~=p2[3],'primary does change surface')
local before=theme.status();local readsBefore=optionReads
for i=1,10000 do theme.color('surface',.055,.105,.115,(i%100)/100);theme.color('accent',.9,.23,.13,1) end
local after=theme.status();eq(after.shadeBuilds,before.shadeBuilds,'20,000 warm color calls allocate zero new shades')
eq(optionReads,readsBefore,'no repeated settings-facade reads for warmed colors')
yes(after.shadeHits>=before.shadeHits+20000,'color cache hits recorded')
for i=1,1200 do theme.color('surface',i/1300,.02,.03,1) end
yes(theme.status().cachedShades<=256*4,'cache remains bounded')
values.uiPrimaryColor='missing';values.uiSecondaryColor=false;epoch=epoch+1
equalColor({theme.color('surface',.1,.2,.3,.4)},{.1,.2,.3,.4},'invalid primary fails open')
equalColor({theme.color('accent',.1,.2,.3,.4)},{.1,.2,.3,.4},'invalid secondary fails open')

-- Extract the actual shipped options registration, cache, rendering adapter and
-- setters without loading unrelated engine-dependent menus in the 1 MB entry.
local code=section('GoldCompat.UI_COLOR_VALUES=','-- Font width queries')
 ..section('function GoldCompat.colosseumColor(','function GoldCompat.battlePresentationEnabled(')
 ..section('DexUI.uiRows={','local function bagStateForMenu(')
 ..section('local function installVerifiedOptions(mod)','local fonts = {}')
 ..'\nreturn {G=GoldCompat,D=DexUI,S=State,install=installVerifiedOptions,read=optionValue,defaults=OPTION_DEFAULTS}'
local function deepCopy(t) if type(t)~='table' then return t end;local c={};for k,v in pairs(t) do c[k]=deepCopy(v) end;return c end
local function fixture(id,initial,noEvents)
 local stored={modOptions={[id]=deepCopy(initial or {})},unrelated={textSpeed=3}}
 local writes=0;local emitted={};local definitions={}
 local save={party={{species='PIKACHU',hp=100,level=75}}}
 local game={save=save,mods={modOptions=deepCopy(stored.modOptions),fs={write=function() end}}}
 local mod={id=id,game=game,options={}}
 mod.options.get=function(_,key)
  local bucket=game.mods.modOptions[id] or {}
  if bucket[key]~=nil then return bucket[key] end
  return definitions[key] and definitions[key].default
 end
 mod.options.define=function(_,defs) for _,def in ipairs(defs) do definitions[def.key]=def end end
 local graphics={getDimensions=function() return 1280,720 end,rectangle=function() end}
 local last
 local nativeSetColor=function(...) last={...} end;graphics.setColor=nativeSetColor
 local env=setmetatable({GoldCompat={generation='gen1'},DexUI={},State={},modRef=mod,
  SCREEN_TOGGLE_SPECS={{key='someGen2Toggle',label='GEN II',gen='gen2'}},
  TEXT_PROFILE_ORDER={'og'},TEXT_PROFILE_DISPLAY={og='OG'},love={graphics=graphics},
  require=function(name)
   assert(name=='src.core.SaveData','unexpected engine request '..name)
   return {loadOptions=function() return deepCopy(stored) end,
    saveOptions=function(opts) stored=deepCopy(opts);writes=writes+1 end}
  end},{__index=_G})
 local api=compile(code,env);api.install(mod)
 api.S.uiTheme=assert(loadfile(root..'/lib/UITheme.lua'))({get=api.read,epoch=function() return api.G.__optionValueEpoch end})
 if not noEvents then
  game.mods.events={emit=function(_,name,payload)
   emitted[#emitted+1]=payload
   api.G.invalidateOptionValue(payload.key,payload.value,true)
  end}
 end
 return api,game,mod,definitions,function() return stored,writes,emitted,last,nativeSetColor end,env
end
for _,id in ipairs({'COLOSSEUM_OVERHAUL','colosseum_ui_overhaul'}) do
 for _,gen in ipairs({'gen1','gen2'}) do
  local api,game,mod,defs,status,env=fixture(id,{uiBorderColor='pink',uiPrimaryColor='purple',uiSecondaryColor='orange'})
  api.G.generation=gen
  local rows=api.D.rowsForGame(game);local found={}
  for i,row in ipairs(rows) do
   if row.key=='uiPrimaryColor' or row.key=='uiSecondaryColor' then
    found[row.key]=row;yes(i<=7,'color controls visible near top of UI screen')
   end
  end
  for _,key in ipairs({'uiPrimaryColor','uiSecondaryColor'}) do
   yes(found[key],'control exists in '..gen)
   eq(defs[key].default,'default','upgrades do not force a new palette')
   eq(#defs[key].choices,14,'default plus 13 choices in mod manager')
   eq(#found[key].values,#defs[key].choices,'same palette in UI and manager')
   for i,v in ipairs(found[key].values) do eq(v,defs[key].choices[i][2],'identical option value ordering') end
  end
  eq(api.read('uiPrimaryColor'),'purple','existing primary retained')
  eq(api.read('uiSecondaryColor'),'orange','existing secondary retained')
  eq(api.D.optionDisplay(found.uiPrimaryColor),'PURPLE','current primary displayed')
  api.D.activateUIRow(game,found.uiPrimaryColor)
  eq(api.read('uiPrimaryColor'),'pink','UI cycles chosen primary')
  eq(api.read('uiSecondaryColor'),'orange','cycling primary preserves secondary')
  eq(api.read('uiBorderColor'),'pink','border setting remains independent')
  local stored,writes=status();eq(stored.modOptions[id].uiPrimaryColor,'pink','primary persisted through normal SaveData')
  eq(writes,1,'one persistent write per UI action')
  api.D.setOption(game,'uiSecondaryColor','blue')
  stored,writes=status();eq(stored.modOptions[id].uiSecondaryColor,'blue','secondary persisted')
  eq(writes,2,'no extra persistence loop')
  eq(game.save.party[1].species,'PIKACHU','Pokemon unchanged');eq(game.save.party[1].hp,100,'HP unchanged')
  eq(stored.unrelated.textSpeed,3,'unrelated options untouched')
  local reloaded=fixture(id,stored.modOptions[id])
  eq(reloaded.read('uiPrimaryColor'),'pink','primary survives recreated UI instance')
  eq(reloaded.read('uiSecondaryColor'),'blue','secondary survives recreated UI instance')
  api.G.setUIColor('surface',.055,.105,.115,.9)
  local _,_,_,custom=status();yes(custom[1]~=.055 or custom[3]~=.115,'actual graphic call receives custom primary')
  -- The donor adapter retains its original mapping. Explicit chrome bypasses
  -- it after conversion, and direct white texture draws remain exact white.
  api.D.setOption(game,'uiPrimaryColor','default');api.D.setOption(game,'uiSecondaryColor','default')
  api.G.withColosseumSkin(function() api.G.setUIColor('surface',.99,.985,.95,1) end)
  local _,_,_,last,native=status()
  equalColor(last,{.025,.060,.065,.92},'default donor panel exactly preserved')
  api.G.withColosseumSkin(function() env.love.graphics.setColor(1,1,1,1) end)
  local _,_,_,last=status();equalColor(last,{1,1,1,1},'texture tint stays white')
  eq(env.love.graphics.setColor,native,'graphics setter restored')
  eq(api.G.__skinNativeSetColor,nil,'scoped color override removed')
  local ok=pcall(api.G.withColosseumSkin,function() error('test draw failure') end)
  eq(ok,false,'drawing errors still propagate');eq(env.love.graphics.setColor,native,'setter restored after draw error')
  eq(api.G.__skinNativeSetColor,nil,'no color state leaks after errors')
 end
end
-- Older launchers without events still refresh immediately through the setter.
local api,game=fixture('colosseum_ui_overhaul',{},true)
eq(api.read('uiPrimaryColor'),'default','sample default before older-launcher change')
api.D.setOption(game,'uiPrimaryColor','cyan');eq(api.read('uiPrimaryColor'),'cyan','local settings cache updated without events')
-- The combined mod migrates an old standalone color bucket once, not every draw.
local api,game,mod,defs,status=fixture('COLOSSEUM_OVERHAUL',{})
game.mods.modOptions.COLOSSEUM_OVERHAUL=nil
game.mods.modOptions.colosseum_ui_overhaul={uiPrimaryColor='green',uiSecondaryColor='brown',uiBorderColor='blue'}
api.G.migrateLegacyModOptions(game)
eq(game.mods.modOptions.COLOSSEUM_OVERHAUL.uiPrimaryColor,'green','legacy primary copied')
api.D.setOption(game,'uiPrimaryColor','pink');api.G.migrateLegacyModOptions(game)
eq(game.mods.modOptions.COLOSSEUM_OVERHAUL.uiPrimaryColor,'pink','migration cannot override later choice')
-- Verify the actual event callback exits before expensive provider invalidation.
local handler=section('mod.events:on("mod.options_changed", function(payload)','-- Colosseum Overhaul merge: run the legacy-UI-settings migration')
local captured,providerResets,handled=0,0,0
local mod={id='colosseum_ui_overhaul',events={on=function(_,name,fn) captured=fn end}}
local env=setmetatable({mod=mod,GoldCompat=api.G,State={Installers={handleModOptionChanged=function() handled=handled+1 end}}},{__index=_G})
api.G.invalidatePresentationProviders=function() providerResets=providerResets+1 end
compile(handler,env)
captured{mod=mod.id,key='uiPrimaryColor',value='red'}
captured{mod=mod.id,key='uiSecondaryColor',value='cyan'}
eq(providerResets,0,'palette changes do not flush model/sprite caches')
eq(handled,0,'palette changes do not invoke heavyweight option handler')
captured{mod='BATTLE_ART_VOXEL_GEN2',key='sprites',value='new'}
eq(providerResets,1,'real sprite-provider changes still invalidate')
eq(handled,1,'real provider change still processed')
print('UIThemeSettingsTests: '..count..' assertions passed; 20,000 warm color calls created zero new shades.')
