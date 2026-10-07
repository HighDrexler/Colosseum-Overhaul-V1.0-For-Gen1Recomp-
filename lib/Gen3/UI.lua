
local V=...
local req=V.engineRequire or require
local U={installed=false,clock=0}
local function g() return love.graphics end
local function font()
if not U.font then U.font=g().newFont(8) end
g().setFont(U.font)
end
local function text(s,x,y,w,color)
font();g().setColor(unpack(color or {1,1,1,1}))
if w then g().printf(tostring(s or ''),x,y,w,'left') else g().print(tostring(s or ''),x,y) end
end
local function panel(x,y,w,h,selected)
g().setColor(selected and .14 or .045,selected and .3 or .1,selected and .37 or .15,.97)
g().rectangle('fill',x,y,w,h,2,2)
g().setColor(.36,.7,.72,1);g().rectangle('line',x+.5,y+.5,w-1,h-1,2,2)
end
local function summaryOwnsViewer()
local v=U.viewer
if not v then return false end
local N=req('src.ui.game3.summary_menu')
return N.open and v.owner==N and N._party and N._party[N._cursor]==v.mon
end
function U.close(keepLobby)
if not keepLobby then
if V.Gen3MtBattleHub then V.Gen3MtBattleHub.close('menu-closed') end
if V.Gen3Audio then V.Gen3Audio.leaveLobby() end
end
req('src.ui.game3.stack').pop('cbe-gen3');U.menu=nil
local top=req('src.ui.game3.stack').top()


if not (summaryOwnsViewer() and top and top.mod==U.viewer.owner) then
if U.viewer and U.viewer.actor then U.viewer.actor:release() end
U.viewer=nil
if V.PokemonActors.cancelInformation then V.PokemonActors.cancelInformation() end
end
end
function U.show(title,rows,footer,back,draw)
if not draw and U.viewer and not summaryOwnsViewer() then
if U.viewer.actor then U.viewer.actor:release() end
U.viewer=nil
if V.PokemonActors.cancelInformation then V.PokemonActors.cancelInformation() end
end
local menu={title=title,rows=rows,cursor=1,footer=footer,back=back,extra=draw}
function menu.handleInput(input)
if input:wasPressed('b') or input:wasPressed('start') then
if back then back() else U.close() end;return
end
if input:wasPressed('down') then menu.cursor=menu.cursor%#rows+1 end
if input:wasPressed('up') then menu.cursor=(menu.cursor-2)%#rows+1 end
if input:wasPressed('right') then menu.cursor=math.min(#rows,menu.cursor+7) end
if input:wasPressed('left') then menu.cursor=math.max(1,menu.cursor-7) end
if input:wasPressed('a') then
local row=rows[menu.cursor]
if row and row.run then
local ok,err=pcall(row.run)
if not ok then menu.footer=tostring(err);U.lastError=tostring(err) end
end
end
end
function menu.draw()
if not menu.extra and V.BattleMenuUI then
local function draw(w,h)
menu.index=menu.cursor;menu.scroll=math.max(0,menu.cursor-10)
V.BattleMenuUI.mark(menu,menu.title,menu.rows,10,menu.footer)
V.BattleMenuUI.draw(nil,menu,{width=w,height=h})
end
if V.Gen3MtBattleHub and V.Gen3MtBattleHub.active() then
V.Gen3MtBattleHub.present(draw);return
end
if V.Gen3Overlay.paint(draw) then return end
end
if V.Gen3Menus and V.Gen3Menus.generic(menu) then return end
local G=g();G.push('all');G.setShader();G.setDepthMode();G.clear(.025,.055,.09,1)
panel(4,4,232,21);text(menu.title,10,10)
local first=math.max(1,math.min(menu.cursor-3,#rows-6))
local width=menu.extra and 125 or 232
for i=first,math.min(#rows,first+6) do
local y=29+(i-first)*15;panel(4,y,width,14,i==menu.cursor)
local label=rows[i].label;if type(label)=='function' then label=label() end
text((i==menu.cursor and '> ' or '  ')..label,8,y+3,width-8)
end
if menu.extra then menu.extra(menu) end
text(menu.footer or 'A SELECT   B BACK   LEFT/RIGHT PAGE',7,143,227,{.65,.83,.86,1})
G.pop()
end
U.menu=menu
if V.Gen3MenuScene then V.Gen3MenuScene.register(menu) end
req('src.ui.game3.stack').push('cbe-gen3',menu,{fullscreen=true})
return menu
end
function U.home()
if V.Gen3Audio then V.Gen3Audio.lobby() end
if V.Gen3MtBattleHub then V.Gen3MtBattleHub.close('home') end
U.show('COLOSSEUM',{
{label='MT. BATTLE',run=function() V.Gen3Challenge.open() end},
{label=U.dexSettingLabel,run=U.toggleDex},
{label=U.expShareLabel,run=U.toggleExpShare},
{label=U.battleSpeedLabel,run=U.cycleBattleSpeed},
{label='POKEMON CATALOG - 386 SPECIES',run=U.dex},
{label='BATTLE SETTINGS',run=U.settings},
{label='PARTY / MOVE PREP',run=U.party},
{label='MODEL CACHE',run=U.cache},
{label='RETURN TO GAME',run=U.close},
},'ENVIRONMENT / CAMERA / POKEMON / AUDIO / TRAINERS')
end
function U.dexSettingLabel()
return 'COLOSSEUMDEX ENCOUNTERS: '..(V.Gen3Runtime.prefs().expandedWild~=false and 'ON' or 'OFF')
end
function U.toggleDex()
local p=V.Gen3Runtime.prefs();p.expandedWild=not (p.expandedWild~=false)
if U.menu then U.menu.footer=p.expandedWild and 'EXTRA WILD ENCOUNTERS ENABLED' or 'NATIVE WILD ENCOUNTERS RESTORED / OWNED POKEMON KEPT' end
end
function U.expShareLabel()
return 'EXP SHARE: '..(V.Gen3Runtime.prefs().expShareEnabled==true and 'ON / BENCH 50%' or 'OFF')
end
function U.toggleExpShare()
local p=V.Gen3Runtime.prefs();p.expShareEnabled=not p.expShareEnabled
if U.menu then U.menu.footer=p.expShareEnabled and 'PARTICIPANTS: 100% EXP / ELIGIBLE BENCH: 50% EACH' or 'EXP SHARE OFF / NATIVE EXP RULES RESTORED' end
end
function U.battleSpeedLabel()
local T=V.BattleTempo
return 'BATTLE SPEED: '..(T and T.label(T.setting(V.Gen3Runtime.game or V.mod.game)) or 'MATCH GAME SPEED')
end
function U.cycleBattleSpeed()
local T=V.BattleTempo;if not T then return end
local v=T.cycle(V.Gen3Runtime.game or V.mod.game)
if U.menu then U.menu.footer=v=='game' and 'BATTLES FOLLOW THE GAME SPEED SETTING'
or ('BATTLES RUN AT '..tostring(v)..'X / OVERWORLD KEEPS THE GAME SPEED') end
end
function U.settings()
local p=V.Gen3Runtime.prefs()
local rows={}
for _,pair in ipairs({{'arenasEnabled','3D ARENAS'},{'pokemonModelsEnabled','3D POKEMON'},
{'doubleBattlesEnabled','TRAINER DOUBLES'},{'cameraEnabled','CAMERA'},
{'menuModels','MENU MODELS'}}) do
local key,label=pair[1],pair[2]
rows[#rows+1]={label=function() return label..'  '..(p[key]~=false and 'ON' or 'OFF') end,
run=function() p[key]=not (p[key]~=false) end}
end
rows[#rows+1]={label=U.dexSettingLabel,run=U.toggleDex}
rows[#rows+1]={label=U.expShareLabel,run=U.toggleExpShare}
rows[#rows+1]={label=U.battleSpeedLabel,run=U.cycleBattleSpeed}
rows[#rows+1]={label=function() return 'ARENA: '..tostring(p.arena or 'auto'):upper() end,run=function()
local order=V.ArenaCatalog.order();local i=0
for n,id in ipairs(order) do if id==p.arena then i=n end end
V.ArenaCatalog.setSelected(V.Gen3Runtime.game or V.mod.game,order[i%#order+1])
end}
rows[#rows+1]={label=function() return 'MUSIC: '..tostring(p.music):upper() end,run=function()
p.music=V.Music.nextMode(V.Gen3Runtime.game or V.mod.game,p.music)
end}
rows[#rows+1]={label=function() return 'WILD POOL: '..(p.wildSpawnMode=='new_only' and 'COLOSSEUMDEX ONLY' or '50/50 MIXED') end,
run=function() p.wildSpawnMode=p.wildSpawnMode=='new_only' and 'mixed' or 'new_only' end}
if V.TrainerRoster and V.TrainerRoster.options then
for _,row in ipairs({{'playerModel','PLAYER TRAINER','player'},{'enemyTrainerModel','ENEMY TRAINERS','enemy'},{'rivalModel','RIVAL TRAINER','rival'}}) do
local key,label,role=unpack(row)
rows[#rows+1]={label=function() return label..': '..tostring(p[key]):upper():gsub('_',' ') end,run=function()
local choices={}
for _,entry in ipairs(V.TrainerRoster.options(role)) do local option=entry
if option.available then choices[#choices+1]={label=option.label,run=function() p[key]=option.id;U.settings() end} end
end
choices[#choices+1]={label='BACK',run=U.settings};U.show(label,choices,'A SELECT   B BACK',U.settings)
end}
end
end
U.show('BATTLE SETTINGS',rows,'NATIVE GEN 3 ABILITIES AND ITEMS ALWAYS ACTIVE',U.home)
end
function U.view(mon)
local game=V.Gen3Runtime.game or V.mod.game
local dex,variant=V.ModelIdentity.resolve(game,mon)
local old=U.viewer
if old and old.mon==mon and old.dex==dex and old.variant==variant then return old end
if old and old.actor then old.actor:release() end
if old and V.PokemonActors.cancelInformation then V.PokemonActors.cancelInformation() end
U.viewer={mon=mon,dex=dex,variant=variant,game=game,battler={mon=mon},
nativeForm=dex==201 or dex==327 or dex==386}
return U.viewer
end
function U.modelControls(owner)
local v=U.viewer
if not v or not v.actor or v.noControls or v.nativeForm or v.owner~=owner then return end
return 'DRAG: ROTATE   WHEEL: ZOOM   MIDDLE DRAG: PAN   HOME: RESET'
end
function U.drawModel(mon,x,y,w,h)
local v=U.view(mon);local G=g()
local hd=U.modelViewport
if hd then
x,y,w,h=unpack(hd)
if not hd.noFrame then V.Gen3Screens.panel(x,y,w,h,math.min(w/300,h/360)) end
else panel(x,y,w,h) end
if V.Gen3ModelCamera then V.Gen3ModelCamera.bind(v,x,y,w,h,hd) end
if v.actor then
local bodyHeight=math.max(1,h)
v.modelRect={x=x,y=y,w=w,h=bodyHeight}
v.hintRect=nil
local cw,ch=hd and math.ceil(w) or 256,hd and math.ceil(bodyHeight) or 256
if not U.modelCanvas or U.modelCanvas:getWidth()~=cw or U.modelCanvas:getHeight()~=ch then
if U.modelCanvas then U.modelCanvas:release() end
U.modelCanvas=G.newCanvas(cw,ch,{dpiscale=1})
end
local target=G.getCanvas()
G.push('all');G.setCanvas({U.modelCanvas,depth=true});G.origin();G.clear(0,0,0,0);G.setShader()
local bounds=v.actor.scene and v.actor.scene.bounds
local span=v.actor.height or 16
if bounds and bounds.min and bounds.max then
span=math.max(span,bounds.max[1]-bounds.min[1],bounds.max[3]-bounds.min[3])
end
local scale=v.framingScale or v.actor.worldScale or 1
local radius=span*scale*.62
local center=9
if bounds and bounds.min and bounds.max then
local lo,hi=bounds.min,bounds.max
local rx=math.max(math.abs(lo[1]),math.abs(hi[1]))
local rz=math.max(math.abs(lo[3]),math.abs(hi[3]))
radius=math.sqrt(rx*rx+rz*rz+((hi[2]-lo[2])*.5)^2)*scale
center=((lo[2]+hi[2])*.5+math.max(0,-(v.actor.scene.floorMinY or lo[2])))*scale
end


v.modelFocus={0,center,0}
local halfFov=math.atan(math.tan(math.rad(20))*math.min(1,cw/ch))
local distance=math.max(33,radius/math.sin(halfFov)*1.12)
local eye={0,center+distance*.15,distance};local focus={0,center,0};local yaw=0
if V.Gen3ModelCamera then eye,focus,yaw=V.Gen3ModelCamera.pose(v,distance) end
local vp=V.Mat4.mul(V.Mat4.perspective(math.rad(40),cw/ch,.1,math.max(300,distance*3.2+radius*2)),V.Mat4.lookAt(eye,focus,{0,1,0}))
vp=V.Mat4.mul(V.Mat4.scale(1,-1,1),vp)
V.PokemonActors.service.withRenderer(vp,function()
local matrix=v.actor:matrix(0,0,0,math.sin(yaw),math.cos(yaw))
v.actor:draw(matrix);return true
end,{eye=eye,focus=focus,width=cw,height=ch,context={services={informationSurface=true}}})
G.setCanvas(target);G.pop();G.setColor(1,1,1,1)
if v.silhouette then
U.modelSilhouette=U.modelSilhouette or G.newShader('vec4 effect(vec4 c, Image t, vec2 uv, vec2 px) { vec4 s=Texel(t,uv); return vec4(1.0,1.0,1.0,s.a)*c; }')
G.push('all');G.setShader(U.modelSilhouette);G.draw(U.modelCanvas,x,y,0,w/cw,bodyHeight/ch);G.pop()
else G.draw(U.modelCanvas,x,y,0,w/cw,bodyHeight/ch) end
else
local size=math.min(128,math.min(w,h)*.8)
local shown=not v.nativeForm and V.Gen3Screens.drawPortrait(mon,x+(w-size)/2,y+(h-size)/2,size)
local pic=not shown and req('src.core.game3.pokemon').monFrontPic(mon)
if pic and pic.image then
local scale=hd and math.min(w*.65/64,h*.65/64) or 1
G.setColor(1,1,1,1);G.draw(pic.image,x+w/2-32*scale,y+h/2-32*scale,0,scale,scale)
end
local label=v.nativeForm and 'NATIVE FORM ART' or v.error and 'MODEL UNAVAILABLE' or ''
if hd then V.Gen3Screens.text(label,x+12,y+h-40,w-24,26,16,{.7,.85,.9,1},'center')
else text(label,x+5,y+h-12,w-10,{.7,.85,.9,1}) end
end
end
function U.pump(dt)
U.clock=U.clock+(dt or 1/60)
if V.Gen3Screens and not U.viewer then V.Gen3Screens.pump(dt) end
local v=U.viewer;if not v or not v.dex then return end
if V.Gen3ModelCamera then V.Gen3ModelCamera.update(v) end
local summary=req('src.ui.game3.summary_menu')
if not U.menu and not summary.isOpen() and not (v.owner and V.Gen3Services and V.Gen3Services.alive(v.owner)) then
if v.actor then v.actor:release() end;U.viewer=nil
if V.PokemonActors.cancelInformation then V.PokemonActors.cancelInformation() end
return
end
if not v.actor and not v.nativeForm then
local ready,why,pending=V.PokemonActors.pumpInformation(v.game,v.battler,'body')
if ready then
v.actor,v.error=V.PokemonActors.acquireCached('cbe-gen3-info',v.dex,v.variant,
{context={game=v.game,arena={figureScale=1},services={informationSurface=true}},battler=v.battler,noSource=true})
if v.actor then v.actor.worldScale=18/math.max(.1,v.actor.height or 16);v.actor:spawn(1);v.actor:idle() end
elseif pending then v.error=nil
elseif why then v.error=tostring(why) end
end
if v.actor then v.actor:update(dt or 1/60) end
end
function U.dex()
local P=req('src.core.game3.pokemon');local rows={};local mons={}
local session=V.Gen3Runtime.session(V.mod.game)
for n=1,386 do
local species=P.speciesFromNational(n)
if species then
local mon={species=species,speciesNumbering='internal',isShiny=false}
mons[#mons+1]=mon
rows[#rows+1]={label=string.format('%03d %s',n,V.ColosseumDexNames[n] or P.name(species)),run=function()
U.show(P.name(species),{{label='VIEW NATIVE DEX ENTRY',run=function()
U.close();req('src.ui.game3.pokedex').show(session.dex,{session=session,mode='national'})
end},{label='BACK',run=U.dex}},'COLOSSEUM MODEL CATALOG / NATIVE OWNERSHIP',U.dex,function() U.drawModel(mon,137,31,96,102) end)
end}
end
end
U.show('COLOSSEUMDEX / NATIONAL ORDER',rows,nil,U.home,function(menu)
local mon=mons[menu.cursor];if mon then U.drawModel(mon,137,31,96,102) end
end)
end
function U.party()
local s=V.Gen3Runtime.session(V.mod.game);local rows={};local P=req('src.core.game3.pokemon')
for _,mon in ipairs(s and s.party or {}) do
local m=mon
rows[#rows+1]={label=P.displayMonName(m),run=function() U.prep(m,false) end}
end
rows[#rows+1]={label='BACK',run=U.home}
U.show('PARTY / MOVE PREP',rows,'FIELD TEAM: NATIVE LEARNSET + TM COMPATIBILITY',U.home)
end
function U.prep(mon,challenge,back)
local P=req('src.core.game3.pokemon');local rows={};local moves={};local seen={}
local species=P.speciesOf(mon)
if not challenge and V.Gen3MoveMemory then
for _,id in ipairs(V.Gen3MoveMemory.pool(mon)) do moves[#moves+1]=id;seen[id]=true end
end


for _,entry in ipairs(P.learnset(species) or {}) do
local id=entry.move or entry.moveId or entry[2];local lv=entry.level or entry[1] or 1
if tonumber(id) and (challenge or lv<=(mon.level or 1)) and not seen[id] then moves[#moves+1]=id;seen[id]=true end
end
if challenge then
local pool=V.ColosseumMoveCatalog.pool(V.Gen3Runtime.game or V.mod.game,mon)
for _,row in ipairs(pool or {}) do
local id=tonumber(row.id)
if id and not seen[id] then moves[#moves+1]=id;seen[id]=true end
end
end
for _,move in ipairs(moves) do local id=move
rows[#rows+1]={label=P.moveName(id),run=function()
local slots={}
for i=1,4 do local slot=i
local current=P.moveIdAt(mon,slot)
slots[#slots+1]={label=(current and current>0 and P.moveName(current) or 'EMPTY'),run=function()
if not challenge and P.knowsMove(mon,id) then U.menu.footer='ALREADY KNOWS THIS MOVE';return end
if not challenge and P.isHmMove(P.moveIdAt(mon,slot)) then U.menu.footer='HM MOVE: VISIT THE MOVE DELETER';return end
local _,why=P.replaceMove(mon,slot,id)
if why then U.menu.footer='COULD NOT LEARN MOVE: '..tostring(why);return end

for _,key in ipairs({'ppBonuses','ppBonus','ppUp'}) do
if type(mon[key])=='table' then mon[key][slot]=0 end
end
if type(mon.ppBonusesPacked)=='number' then
local bit=req('bit');mon.ppBonusesPacked=bit.band(mon.ppBonusesPacked,bit.bnot(bit.lshift(3,(slot-1)*2)))
end
U.prep(mon,challenge,back)
U.menu.footer=P.moveName(id)..' LEARNED   /   A SELECT   B BACK'
end}
end
U.show('REPLACE WHICH MOVE?',slots,'LEARN '..P.moveName(id)..'   /   A CONFIRM   B CANCEL',function() U.prep(mon,challenge,back) end)
end}
end
rows[#rows+1]={label='BACK',run=back or U.party}
U.show('REMEMBER MOVES / '..P.displayMonName(mon),rows,'LEVEL-UP HISTORY THROUGH LV. '..tostring(mon.level or 1)..'   /   A SELECT   B BACK',back or U.party)
end
function U.cache()
local C=V.CacheManager
local function status() return C.hardCacheStatus() end
local function prepare(scope)
V.Gen3Runtime.prepareCache()
local _,message=C.hardCacheSave(V.Gen3Runtime.game or V.mod.game,scope)
U.menu.footer=message
end
U.show('CACHE PREPARATION',{
{label='PREPARE FULL CACHE - 386 SPECIES',run=function() prepare('catalog') end},
{label=function()
local s=status()
local game=V.Gen3Runtime.game or V.mod.game
if game and game.__cbeAssetUpdateError then return 'PREPARATION ERROR - A FOR DETAILS' end
if s.running then return (s.paused and 'PAUSED: ' or 'PREPARING: ')..tostring(s.done or 0)..' / '..tostring(s.total or 0)..' JOBS' end
if (s.failed or 0)>0 or s.stage=='failed' then return 'CACHE INCOMPLETE - '..tostring(s.failed or 0)..' FAILED JOBS' end
if s.catalogReady then return 'FULL 386 CACHE READY' end
return 'READY TO PREPARE / EXISTING FILES REUSED'
end,run=function()
local s=status();local game=V.Gen3Runtime.game or V.mod.game
U.menu.footer=(game and game.__cbeAssetUpdateError) or s.lastError or s.lastFailed or '151 / 251 / 386: MODELS + AUTHORED IDLE ANIMATIONS'
end},
{label=function() return status().paused and 'RESUME PREPARATION' or 'PAUSE PREPARATION' end,run=function()
local s=status()
if not s.running then U.menu.footer='START A CACHE JOB FIRST';return end
C.pauseHardCache(not s.paused)
end},
{label='PREPARE KANTO CACHE - 151 SPECIES',run=function() prepare('catalog151') end},
{label='PREPARE KANTO + JOHTO - 251 SPECIES',run=function() prepare('catalog251') end},
{label='WARM CURRENT PARTY',run=function()
V.PokemonActors.queuePartyPrewarm(V.Gen3Runtime.game or V.mod.game);U.menu.footer='PARTY PREPARATION QUEUED'
end},
{label='BROWSE / PREPARE A SPECIES',run=U.dex},
{label='BACK',run=U.home},
},'MODELS + AUTHORED IDLE / SAVED TO DISK / A SELECT   B BACK',U.home)
end
function U.drawBattle(f,ui,w,h)
if V.Gen3Screens then
V.Gen3Screens.battlePainted=nil;V.Gen3Screens.battleMessagePainted=nil
end
local st=f._model
local p=V.Gen3Runtime.prefs(f.game)
if V.Gen3Runtime.waitingForModels then return V.Gen3Screens.waitForBattleModels() end
local floating=V.Gen3MenuScene and V.Gen3MenuScene.floating()
if not p.arenasEnabled or st.safari or st.pokedude or st.oldManTutorial or st.ghostBattle
or (st.kinds and st.kinds.tutorial) then return false end
local surface=V.StandaloneHost.renderGen3Frame(f)
if not surface then return false end
if floating or (V.Gen3Capture and V.Gen3Capture.cinematic()) then
V.Gen3Screens.present('battle-menu-world',function() end,surface)
return true
end
if V.Gen3Screens then return V.Gen3Screens.battle(f,ui,surface) end
w=w or 240;h=h or 160
local G=g();G.push('all');G.setShader();G.setDepthMode();G.setColor(1,1,1,1)




local Renderer=req('src.render.Renderer')
local Display=req('src.core.game3.display')
local highRes=not Display.planesBroken and Renderer and Renderer.canvas
and G.getCanvas and G.getCanvas()==Renderer.canvas
and type(Renderer.setWorldOverride)=='function'
if highRes then
Renderer:setWorldOverride(surface)
G.clear(0,0,0,0)
else
G.draw(surface,0,0,0,w/surface:getWidth(),h/surface:getHeight())
end
local Anim=req('src.core.game3.battle.anim');local P=req('src.core.game3.pokemon')
local stage=Anim.stage()
for id=0,(st.double and 3 or 1) do
local b=f.battlers[id];local hb=stage and stage.healthbox and stage.healthbox[id]
if b and not b.absent and (not hb or hb.visible~=false) then
local x=id%2==1 and 4 or 130
local y=id%2==1 and (id==1 and 5 or 30) or (id==0 and 63 or 88)
local ratio=Anim.displayHpRatio(id,b.native)
panel(x,y,106,22,ui._mode=='target' and ui._target and ui._target.cursor==id)
text(P.displayMonName(b.mon),x+4,y+2,77);text('L'..tostring(b.mon.level),x+81,y+2)
G.setColor(.15,.22,.25,1);G.rectangle('fill',x+4,y+14,98,4)
G.setColor(ratio<.2 and .95 or .25,ratio<.2 and .25 or .85,.45,1);G.rectangle('fill',x+4,y+14,98*ratio,4)
if b.mon.status then text(tostring(b.mon.status),x+66,y+11,36,{1,.75,.25,1}) end
end
end
panel(2,115,236,43)
local active=f.battlers[ui._active or 0] or f.player
if ui._mode=='menu' then
text('What will '..P.displayMonName(active.mon)..' do?',8,121,111)
for i,label in ipairs({'FIGHT','BAG','POKEMON','RUN'}) do
local x=126+((i-1)%2)*55;local y=120+math.floor((i-1)/2)*18
panel(x,y,53,16,i==ui._menuIndex);text(label,x+4,y+4)
end
elseif ui._mode=='moves' or ui._mode=='target' then
for i=1,4 do
local id=active.mon and active.mon.moves[i];local x=7+((i-1)%2)*78;local y=120+math.floor((i-1)/2)*17
panel(x,y,76,15,i==ui._moveIndex);text(id and id~=0 and P.moveName(id) or '-',x+3,y+3,71)
end
local slot=ui._moveIndex or 1
text(ui._mode=='target' and 'PICK TARGET' or 'PP',168,122,67)
text(tostring(active.mon.pp and active.mon.pp[slot] or 0)..' / '..tostring(active.mon.maxPp and active.mon.maxPp[slot] or '?'),168,138,67)
end
G.pop();return true
end
local function themedColors()
return {fg={.92,.98,.98,1},shadow={.02,.10,.13,1},bg={.045,.10,.15,1}}
end
local NAMING_PAGES={
{id='UPPER',rows={{'A','B','C','D','E','F',' ','.'},{'G','H','I','J','K','L',' ',','},
{'M','N','O','P','Q','R','S'},{'T','U','V','W','X','Y','Z'}},colX={0,12,24,56,68,80,92,123}},
{id='LOWER',rows={{'a','b','c','d','e','f',' ','.'},{'g','h','i','j','k','l',' ',','},
{'m','n','o','p','q','r','s'},{'t','u','v','w','x','y','z'}},colX={0,12,24,56,68,80,92,123}},
{id='OTHERS',rows={{'0','1','2','3','4'},{'5','6','7','8','9'},
{'!','?','♂','♀','/','-'},{'…','“','”','‘',"'"}},colX={0,22,44,66,88,110}},
}
local function namingFont(size)
if V.Gen3Screens then return V.Gen3Screens.font(size) end
size=math.max(8,math.floor(size+.5))
U.namingFonts=U.namingFonts or {}
if not U.namingFonts[size] then


local f=g().newFont(size,'normal',1)
f:setFilter('linear','linear');U.namingFonts[size]=f
end
return U.namingFonts[size]
end
local function releaseNamingSurface()
if U.namingCanvas then U.namingCanvas:release();U.namingCanvas=nil end
for _,f in pairs(U.namingFonts or {}) do f:release() end
U.namingFonts=nil
end


function U.drawNamingSurface(st,w,h,rect,floating)
local G=g();G.push('all');G.origin();G.setShader();G.setDepthMode()
G.setScissor();G.setBlendMode('alpha');G.setLineStyle('smooth')
if not floating then G.clear(.035,.045,.041,1) end
rect=rect or {x=0,y=0,w=w,h=h}
local s=math.min(rect.w/960,rect.h/640)
local ox=rect.x+(rect.w-960*s)/2;local oy=rect.y+(rect.h-640*s)/2
local function xy(x,y) return math.floor(ox+x*s+.5),math.floor(oy+y*s+.5) end
local ink={.88,.90,.82,1};local muted={.65,.69,.62,1};local accent={.96,.82,.49,1}
local function label(value,x,y,width,size,color,align)
value=tostring(value or '')
local f=namingFont(size*s);local maxWidth=width*s
if f:getWidth(value)>maxWidth then f=namingFont(size*s*maxWidth/f:getWidth(value)) end
local px,py=xy(x,y)
if align=='center' then px=px+(maxWidth-f:getWidth(value))/2
elseif align=='right' then px=px+maxWidth-f:getWidth(value) end
G.setFont(f);G.setColor(0,0,0,.753);G.print(value,math.floor(px+.5)+1,py+1)
G.setColor(color or ink);G.print(value,math.floor(px+.5),py)
end
local function card(x,y,cw,ch,selected,key)
local px,py=xy(x,y)
if not key then V.Gen3Screens.panel(px,py,cw*s,ch*s,s) end
if selected then V.Gen3Screens.select(px+7*s,py+3*s,(cw-14)*s,(ch-6)*s,s) end
end
local function glyph(ch,x,y,cw,chh,size,color)
if ch=='♂' or ch=='♀' then


local cx,cy=xy(x+cw/2,y+chh*.42);local r=size*s*.21
G.setColor(color or ink);G.setLineWidth(math.max(1,size*s*.065))
G.circle('line',cx,cy,r,32)
if ch=='♀' then
G.line(cx,cy+r,cx,cy+r*2.3);G.line(cx-r*.6,cy+r*1.75,cx+r*.6,cy+r*1.75)
else
local ex,ey=cx+r*1.8,cy-r*1.8
G.line(cx+r*.7,cy-r*.7,ex,ey);G.line(ex-r,ey,ex,ey,ex,ey+r)
end
else
local f=namingFont(size*s)
label(ch,x,y+(chh-f:getHeight()/s)/2,cw,size,color,'center')
end
end
local title=tostring(st.title or 'Name')
if st.template=='PLAYER' then title='Your name' end
label(title,40,32,880,30,ink)
card(40,90,880,122)
local chars={}
for ch in tostring(st.name or ''):gmatch('[%z\1-\127\194-\244][\128-\191]*') do chars[#chars+1]=ch end
local count=math.max(1,tonumber(st.maxLen) or 7)
label(#chars..' / '..count,770,104,126,14,muted,'right')
local step=math.min(56,800/count)
for i=1,count do
local x=64+(i-1)*step
local current=i==#chars+1
if current then card(x,128,step-9,60,true,true) end
if chars[i] then glyph(chars[i],x,128,step-9,60,30) end
local px,py=xy(x+5,190)
G.setColor(current and accent or {.35,.39,.34,1})
G.rectangle('fill',px,py,(step-19)*s,math.max(1,2*s))
end
local pages=st.pages or NAMING_PAGES
local pageIndex=(st.swapT and st.swapT>=64 and st.swapTo) or st.page or 1
local page=pages[pageIndex] or pages[1]
local pageNames={UPPER='Uppercase',LOWER='Lowercase',OTHERS='Symbols'}
card(40,236,648,318)
label(pageNames[page.id] or 'Keyboard',64,251,410,17,muted)
label(pageIndex..' / '..#pages,590,251,74,15,muted,'right')
local columns=1
for _,row in ipairs(page.rows or {}) do columns=math.max(columns,#row) end
local keyStep=608/columns
for rowIndex,row in ipairs(page.rows or {}) do
for col,ch in ipairs(row) do
local x=64+(col-1)*keyStep;local y=286+(rowIndex-1)*62
local selected=st.swapT==nil and st.row==rowIndex and st.col==col
card(x,y,keyStep-8,52,selected,true)
glyph(ch==' ' and 'Space' or ch,x,y,keyStep-8,52,ch==' ' and 12 or 25,selected and accent or ink)
end
end
local nextPage=pages[pageIndex%#pages+1]
local hints={pageNames[nextPage.id] or 'Next page','B button','START, then A'}
for i,value in ipairs({'Page','Delete','Confirm'}) do
local x,y=712,236+(i-1)*112
local selected=st.col>(#((page.rows or {})[st.row] or {})) and st.btn==i
card(x,y,208,94,selected)
label(value,x+22,y+18,164,23,selected and accent or ink)
label(hints[i],x+22,y+55,164,13,muted)
end
label('D-pad  Move     A  Select     B  Delete     SELECT  Page',40,583,880,14,muted,'center')
if st.pcPages then
G.setColor(0,0,0,.65);G.rectangle('fill',0,0,w,h)
card(70,220,820,190)
local px,py=xy(100,248)
G.setFont(namingFont(24*s));G.setColor(ink)
G.printf(st.pcPages[st.pcPage or 1] or '',px,py,760*s,'left')
label('A  Continue',100,369,760,17,accent,'right')
end
G.pop();return true
end
function U.drawNaming(st)
if not st then return false end
if st.template~='PLAYER' and st.template~='RIVAL' and V.Gen3MenuScene.floating()
and V.Gen3Overlay.available() then


if V.Gen3Overlay.namingPainted==st then return true end
local painted=V.Gen3Overlay.paint(function(w,h) U.drawNamingSurface(st,w,h,nil,true) end)
if painted then V.Gen3Overlay.namingPainted=st end
return painted
end
if V.Gen3Overlay then V.Gen3Overlay.reset() end
local G=g();local Renderer=req('src.render.Renderer')
local Display=req('src.core.game3.display')
local target=G.getCanvas()
if not Display.planesBroken and target and target==Renderer.canvas
and type(Renderer.frameRects)=='function' and type(Renderer.setWorldOverride)=='function' then
local r=Renderer:frameRects()
local w,h=math.max(1,math.floor(r.pw)),math.max(1,math.floor(r.ph))
if not U.namingCanvas or U.namingCanvas:getWidth()~=w or U.namingCanvas:getHeight()~=h then
releaseNamingSurface()
U.namingCanvas=G.newCanvas(w,h,{dpiscale=1})
U.namingCanvas:setFilter('linear','linear')
end
G.push('all');G.setCanvas(U.namingCanvas)
U.drawNamingSurface(st,w,h,{x=(r.uox-r.vux)*r.dpiX,y=(r.uoy-r.vuy)*r.dpiY,
w=r.uvpw*r.dpiX,h=r.uvph*r.dpiY})
G.pop()
Renderer:setWorldOverride(U.namingCanvas)

G.clear(0,0,0,0)
return true
end

return U.drawNamingSurface(st,240,160)
end
function U.install()
if U.installed then return end
V.mod.hooks:wrap('ui.start_menu.items',function(next,game,rows)
rows=next(game,rows) or rows
for _,r in ipairs(rows) do if r.id=='cbe-gen3' then return rows end end
table.insert(rows,math.max(1,#rows),{id='cbe-gen3',label='COLOSSEUM',onSelect=U.home})
return rows
end,115)


local Chrome=req('src.ui.game3.chrome')
local function frame(tx,ty,tw,th)
local G=g();G.push('all');G.setShader();G.setDepthMode()
panel(tx*8-3,ty*8-3,tw*8+6,th*8+6)
G.pop()
end
Chrome.stdFrame=frame;Chrome.fixedStdFrame=frame
Chrome.userFrame=function(_,...) return frame(...) end
Chrome.dialogueFrame=function()
local l,t,w,h=2,15,26,4
if Chrome.dialogueWindow then l,t,w,h=Chrome.dialogueWindow() end
frame(math.max(0,l-2),math.max(0,t-1),math.min(30,w+4),h+2)
end
local Message=req('src.ui.game3.message')
local originalText=Message.drawText
Message.drawText=function(...)
local Screens=V.Gen3Screens
if Screens and Screens.ownsBattleMessage and Screens.ownsBattleMessage(Message) then return end
if Message._frame=='battle' or Message._frame=='braille' then return originalText(...) end
local old=Message._colors
Message._colors=req('src.ui.game3.frlg_font').COLOR.WHITE
local result={pcall(originalText,...)}
Message._colors=old
if not result[1] then error(result[2],0) end
return unpack(result,2)
end
local Naming=req('src.ui.game3.naming')
V.Gen3MenuScene.register(Naming,function()
local st=Naming._state
return st and st.template~='PLAYER' and st.template~='RIVAL'
end)
local nativeNamingDraw=Naming.draw
Naming.draw=function(...)
if Naming.isOpen and Naming.isOpen() and Naming._state then return U.drawNaming(Naming._state) end
return nativeNamingDraw(...)
end
local namingClose,namingDismiss=Naming.close,Naming.dismiss
Naming.close=function(...)
local result={namingClose(...)}
if not Naming.isOpen() then releaseNamingSurface() end
return unpack(result)
end
Naming.dismiss=function(...) local result={namingDismiss(...)};releaseNamingSurface();return unpack(result) end
if V.Gen3Screens then V.Gen3Screens.install() end
local okKit,Kit=pcall(req,'src.ui.game3.rse.scene_kit')
local okBirch,Birch=pcall(req,'src.ui.game3.rse.birch_speech')
if okKit and okBirch and Kit and Birch then
Kit.birchDialogueFrame=function(tx,ty,tw,th)
local G=g();G.push('all');G.setShader();G.setDepthMode()
panel((tx-1)*8,(ty-1)*8,(tw+1)*8,(th+2)*8)
G.pop()
end
local nativeBirchDraw=Birch.draw
Birch.draw=function(self,...)
local normal=Kit.messageColors
Kit.messageColors=themedColors
local result={pcall(nativeBirchDraw,self,...)}
Kit.messageColors=normal
if not result[1] then error(result[2],0) end
return unpack(result,2)
end
end
for _,path in ipairs({'src.ui.game3.rse.main_menu_rse','src.ui.game3.rs.main_menu'}) do
local okMenu,MainMenu=pcall(req,path)
if okMenu and MainMenu and type(MainMenu.colors)=='function' then
local nativeColors=MainMenu.colors
MainMenu.colors=function(self,...)
local colors=nativeColors(self,...)
colors.headers=themedColors()
colors.info=themedColors()
colors.error=themedColors()
colors.fill={.045,.10,.15,1}
return colors
end
end
end
if V.Gen3FieldUI then V.Gen3FieldUI.install() end
if V.Gen3FRLGStarters then V.Gen3FRLGStarters.install() end
if V.Gen3ModManager then V.Gen3ModManager.install() end
if V.Gen3Menus then V.Gen3Menus.install() end
if V.Gen3Summary then V.Gen3Summary.install() end
if V.Gen3Services then V.Gen3Services.install() end
if V.Gen3StorageUI then V.Gen3StorageUI.install() end
if V.Gen3PokedexUI then V.Gen3PokedexUI.install() end
if V.Gen3ProgressUI then V.Gen3ProgressUI.install() end
if V.Gen3NavigationUI then V.Gen3NavigationUI.install() end
U.installed=true
end
return U
