
local V=...
local req=V.engineRequire or require
local M={}
local function clean(s) return V.Gen3Screens.decodeText(tostring(s or '')) end
local types={'NORMAL','FIGHTING','FLYING','POISON','GROUND','ROCK','BUG','GHOST','STEEL','???','FIRE','WATER','GRASS','ELECTRIC','PSYCHIC','ICE','DRAGON','DARK'}
local function typeName(id) return type(id)=='number' and (types[id+1] or '???') or clean(id):gsub('TYPE_','') end
local function ability(mon,P) return tonumber(mon.ability or mon.abilityId) or P.abilityId(mon.species,mon.personality or 0) end
local function memo(mon,N,Skin)
local D=req('src.core.game3.summary_data')
if Skin and Skin.nativePolicy then
local K=req('src.ui.game3.rse.scene_kit')
local sections=K.loadLua('data/generated/gba/region_map/map_sections.lua')
local sec=sections and sections.sections and sections.sections[tonumber(mon.metLocation)]
local runs=Skin.nativePolicy.memo(mon,N._playerState,sec and sec.name)
local out={};for _,run in ipairs(runs) do out[#out+1]=run.text end
return {table.concat(out)}
end
if not Skin then return D.formatTrainerMemo(mon,N._playerState,{enemyParty=N._enemyParty,owner=N._owner}) end
local T=req('src.core.game3.rom_text');local Kit=req('src.ui.game3.rse.scene_kit')
local sections=Kit.loadLua('data/generated/gba/region_map/map_sections.lua')
local sec=sections and sections.sections and sections.sections[tonumber(mon.metLocation)]
local place=sec and sec.name;local level=tonumber(mon.metLevel) or 0;local session=N._playerState or {}
local own=tostring(mon.otName or mon.ot or '')==tostring(session.name or session.playerName or '')
and (tonumber(mon.otId) or 0)%65536==(tonumber(session.trainerId) or 0)%65536
local key
if own then
if level==0 then key=place and 'gText_XNatureHatchedAtYZ' or 'gText_XNatureHatchedSomewhereAt'
else key=place and 'gText_XNatureMetAtYZ' or 'gText_XNatureMetSomewhereAt' end
else key=place and 'gText_XNatureProbablyMetAt' or 'gText_XNatureObtainedInTrade' end
local nature=D.nature(mon)
return {T.plain(key,{dynamic={[0]='',[1]='',
[2]=T.at('gNatureNamePointers',nature),[3]=tostring(level==0 and 5 or level),[4]=place or '',[5]=''}})}
end
function M.moves(mon,N)
local P=req('src.core.game3.pokemon');local out={}
for i=1,5 do
local raw
if i<=4 then raw=(mon.moves or {})[i] elseif N._mode=='select_move' then raw=N._moveToLearn end
local id=type(raw)=='table' and (raw.id or raw.move or raw.moveId or raw.num or raw.name or raw[1]) or raw
if type(id)=='string' then
local C=req('src.core.game3.constants').of(N._playerState or N._session)
id=tonumber(id) or (C and C:id('moves',id)) or (P.battleMoveId and P.battleMoveId(id))
end
if id and id~=0 then
local def=P.battleMove(id) or {};local pp=type(raw)=='table' and raw.pp or (mon.pp or {})[i]
local max=i<=4 and (mon.maxPp or {})[i] or nil;max=max or def.pp or 5
out[i]={id=id,name=P.moveName(id),pp=pp or max,maxPP=max,def=def}
end
end
return out
end
function M.facade(N)
local P=req('src.core.game3.pokemon');local D=req('src.core.game3.summary_data')
local native=N._party and N._party[N._cursor];if not native then return end
local game,state=V.Gen3Menus.partyFacade({_party={native},cursor=1,movesFor=function() return M.moves(native,N) end})
local mon=state.party[1];mon.moves=M.moves(native,N);mon.exp=native.exp
mon.eggCycles=D.eggCycles(native)
local def=game.data.pokemon[mon.species];def.dex=P.national(mon.species);def.types={}
for _,id in ipairs(P.types(mon.species)) do
local name=typeName(id);if def.types[1]~=name then def.types[#def.types+1]=name end
end
local meta=P.speciesMeta(mon.species) or {}
local progress=D.expProgress(native,meta.growthRate)
local summary={mon=mon,pokemon=game.data.pokemon,items=game.data.items,
page=({[0]=3,[1]=1,[2]=2,[3]=2,[4]=1})[N._page],moveDetail=N._page==3,
moveIndex=N._moveCursor,swapFrom=N._swapSlot,nativeMenu=N,
otName=function()
local name=clean(native.otName or native.ot or native.originalTrainer or '')
return name~='' and name or '—'
end,
otId=function() return (tonumber(native.otId) or 0)%65536 end,
expToNext=function() return progress.expNeeded end}
return game,summary
end
function M.context(w,h,N,Skin)
local ctx=V.Gen3Menus.context(w,h);local C=ctx.compat
local P=req('src.core.game3.pokemon');local D=req('src.core.game3.summary_data')
ctx.timer=love.timer
ctx.statValueX=128;ctx.statValueWidth=23
ctx.hpColor=function(r) if r<.2 then return .9,.18,.14 elseif r<.5 then return .96,.72,.15 else return .22,.84,.36 end end
ctx.tabs={{id=3,label='PROFILE'},{id=1,label='STATUS'},{id=2,label='MOVES'}}
local contest=Skin and Skin._st.contest
local contestData
if Skin then
ctx.tabsStart=58;ctx.tabs[4]={id=4,label='CONTEST'}
if contest and (N._page==2 or N._page==3) then ctx.activeTab=4 end
contestData=req('src.ui.game3.rse.scene_kit').loadLua('data/generated/gba/pokemon/contest_moves.lua')
end
local function contestMove(mv)
local cm=mv and contestData and contestData.moves[mv.id]
return cm,cm and contestData.effects[cm.effect]
end
local function moveType(mv)
if not contest then return typeName(mv.def.type) end
local cm=contestMove(mv)
return ({'COOL','BEAUTY','CUTE','SMART','TOUGH'})[cm and cm.category+1 or 1]
end
C.normalizeTypeLabel=typeName
C.summaryAbilityName=function(_,mon) return P.abilityName(ability(mon.native,P)) end
C.drawStatsInformationPortrait=function(_,mon,x,y,cw,ch)
if V.Gen3Runtime.prefs().menuModels==false then
return V.Gen3Screens.drawPortrait(mon.native,x,y,math.min(cw,ch))
end
V.Gen3UI.modelViewport={x,y,cw,ch,noFrame=true}
local ok,err=pcall(V.Gen3UI.drawModel,mon.native,x,y,cw,ch)
V.Gen3UI.modelViewport=nil
if ok and V.Gen3UI.viewer then V.Gen3UI.viewer.owner=N.__cbeOwner or N end
if not ok then error(err,0) end
return true
end
local white,muted,gold={.98,.98,.94,1},{.70,.79,.77,1},{1,.82,.32,1}
local function cameraFooter(ox,oy,sc)
local controls=V.Gen3UI.modelControls(N.__cbeOwner or N)
if controls then ctx.finalTextFitted(controls,7,139,1.8,1.5,muted,ox,oy,sc,'left',147,4) end
end
ctx.afterStatus=function(_,ox,oy,sc) cameraFooter(ox,oy,sc) end
ctx.drawBody=function(game,summary,ox,oy,sc,section)
local mon=summary.mon;local native=mon.native;local def=game.data.pokemon[mon.species]
local function text(s,x,y,size,color,width)
ctx.finalText(clean(s),x,y,size,color or white,ox,oy,sc,'left',width)
end
local function fit(s,x,y,width,size)
ctx.finalTextFitted(clean(s),x,y,size or 2.65,1.65,white,ox,oy,sc,'left',width,7)
end
local function footer(s) fit(s,7,134,147,1.85);cameraFooter(ox,oy,sc) end
local manage=V.Gen3MoveMemory and V.Gen3MoveMemory.canManageSummary(N)
local function selection(y,h,active,held)
local G=love.graphics;G.push('all');G.translate(ox,oy);G.scale(sc,sc)
G.setColor(active and {.09,.31,.28,.96} or {.015,.035,.04,.88})
ctx.roundedRect('fill',63,y,90,h,2)
G.setColor(held and {1,.82,.32,1} or active and {1,.32,.17,1} or {.42,.63,.63,1})
ctx.roundedRect('line',63,y,90,h,2);G.pop()
end
if summary.moveDetail then
local learning=N._mode=='select_move'
section(62,25,92,learning and 'CHOOSE A MOVE TO REPLACE' or contest and 'CONTEST MOVE DETAILS' or 'MOVE DETAILS')
for i=1,5 do
local mv=mon.moves[i];local y=34+(i-1)*13
selection(y,12,i==N._moveCursor,i==N._swapSlot)
fit(mv and mv.name or (i==5 and 'CANCEL' or '—'),66,y+1,54,2.4)
if mv then
text(moveType(mv),66,y+7,1.6,gold,48)
text(mv.pp..'/'..mv.maxPP,123,y+3,2.0,muted,27)
end
end
local mv=mon.moves[N._moveCursor]
if N._hmNotice then
text("HM moves can't be forgotten.",64,108,2.05,gold,87)
elseif mv and contest then
local _,effect=contestMove(mv)
if effect then
local appeal=effect.appeal~=255 and math.floor(effect.appeal/10) or 0
local jam=effect.jam~=255 and math.floor(effect.jam/10) or 0
text('APPEAL  '..appeal..'    JAM  '..jam,64,102,1.9,gold,87)
text((effect.description or ''):gsub('\n',' '),64,110,2,muted,87)
end
elseif mv then
text('POWER  '..((mv.def.power or 0)>1 and mv.def.power or '—')..'    ACC.  '..((mv.def.accuracy or 0)>0 and mv.def.accuracy or '—'),64,102,1.9,gold,87)
text(D.moveDescription(mv.id,mv.name):gsub('\n',' '),64,110,2,muted,87)
end
footer(learning and '↑/↓ MOVE   A: REPLACE   B: CANCEL' or N._swapSlot and '↑/↓ MOVE   A: PLACE   B: CANCEL' or
('↑/↓ MOVE   A: PICK UP   '..(manage and 'START: REMEMBER   ' or '')..'B: BACK'))
elseif summary.page==2 then
section(62,25,92,contest and 'CONTEST MOVES' or 'CURRENT MOVES')
for i=1,4 do
local mv=mon.moves[i];local y=34+(i-1)*13
fit(mv and mv.name or '—',64,y,51)
if mv then
text('PP '..mv.pp..'/'..mv.maxPP,117,y,2,muted,35)
text(moveType(mv),117,y+6,1.8,gold,35)
end
end
local rows=P.learnset(mon.species);local pages=math.max(1,math.ceil(#rows/10))
local page=(N.__cbeLearnPage or 0)%pages
section(62,86,92,('LEVEL-UP LEARNSET  %d/%d'):format(page+1,pages))
for i=1,10 do
local row=rows[page*10+i];if not row then break end
fit(('L%02d %s'):format(row.level or row[1],P.moveName(row.move or row[2])),64+math.floor((i-1)/5)*44,94+(i-1)%5*6,42,1.85)
end
footer('←/→ PAGE   ↑/↓ MON   A: DETAILS   '..(manage and 'START: REMEMBER   ' or '')..'SELECT: LEARNSET   B: BACK')
else
section(62,25,92,'TRAINER')
fit('OT  '..summary:otName(),65,34,48)
text(('ID %05d'):format(summary:otId()),116,34,2.3,gold,36)
text(table.concat(def.types,' / '),65,43,2.3,white,83)
local sub=(N.__cbeProfilePage or 0)
if sub==0 then
section(62,54,92,'TRAINER MEMO')
local lines=memo(native,N,Skin)
text(table.concat(lines,' '):gsub('\n',' '),65,63,2.3,white,84)
local abilityId=ability(native,P)
local name=P.abilityName(abilityId)
section(62,96,92,'ABILITY / '..name)
text(D.abilityDescription(abilityId,name):gsub('\n',' '),65,105,2.1,muted,84)
elseif sub==1 then
section(62,54,92,'SPECIES DATA')
local dex=P.dexEntry(mon.species) or {}
text(dex.category or def.name,65,64,2.65,white,83)
text(('HT %.1f m     WT %.1f kg'):format((dex.height or 0)/10,(dex.weight or 0)/10),65,74,2.2,muted,84)
section(62,87,92,'EVOLUTION')
local evos=P.evolutions(mon.species)
for i=1,math.min(4,#evos) do
local e=evos[i];local method=e.method
local how=method==4 and ('Lv '..e.param) or method==7 and req('src.core.game3.items_data').displayName(e.param)
or (method==5 or method==6) and 'TRADE' or (method==1 or method==2 or method==3) and 'FRIENDSHIP' or 'SPECIAL CONDITION'
fit(P.name(e.target)..' / '..how,64,96+(i-1)*7,88,2.0)
end
if #evos==0 then text('NONE',65,96,2.3,muted,84) end
else
local rows={}
for id=289,346 do if P.canLearnTmItem(mon.species,id) then rows[#rows+1]=P.moveName(P.moveFromTmItem(id)) end end
table.sort(rows)
local pages=math.max(1,math.ceil(#rows/16));local page=(sub-2)%pages
if sub<2+pages then
section(62,54,92,('TM/HM COMPATIBILITY  %d/%d'):format(page+1,pages))
for i=1,16 do
local name=rows[page*16+i];if not name then break end
fit(name,64+math.floor((i-1)/8)*44,64+(i-1)%8*7,42,2)
end
if #rows==0 then text('NONE',65,65,2.3,muted,84) end
else
section(62,54,92,'RIBBONS / MARKINGS')
local ribbonRows={};local ok,R=pcall(req,'src.core.game3.rse.ribbons')
if ok then for _,name in ipairs(R.COUNTED) do local n=R.get(native,name)
if n>0 then ribbonRows[#ribbonRows+1]=name:upper()..(n>1 and (' '..n) or '') end
end else
local word=tonumber(native.ribbons) or 0
for i,name in ipairs({'COOL','BEAUTY','CUTE','SMART','TOUGH'}) do
local n=math.floor(word/2^((i-1)*3))%8;if n>0 then ribbonRows[#ribbonRows+1]=name..' '..n end
end
for i,name in ipairs({'CHAMPION','WINNING','VICTORY','ARTIST','EFFORT','MARINE','LAND','SKY','COUNTRY','NATIONAL','EARTH','WORLD'}) do
if math.floor(word/2^(i+14))%2==1 then ribbonRows[#ribbonRows+1]=name end
end
end
for i,name in ipairs(ribbonRows) do fit(name,64+math.floor((i-1)/9)*44,63+(i-1)%9*6,42,1.9) end
if #ribbonRows==0 then text('NO RIBBONS',65,65,2.3,muted,84) end
local marks={};local bits=tonumber(native.markings) or 0
for i,name in ipairs({'CIRCLE','SQUARE','TRIANGLE','HEART'}) do if math.floor(bits/2^(i-1))%2==1 then marks[#marks+1]=name end end
fit('MARKS: '..(#marks>0 and table.concat(marks,' / ') or 'NONE'),64,120,88,1.7)
end
end
footer('←/→ PAGE   ↑/↓ POKéMON   SELECT: MORE INFO   B: BACK')
end
return true
end
return ctx
end
function M.draw(N,Skin)
local game,summary=M.facade(N);if not summary then return false end
return V.Gen3Overlay.paint(function(w,h)
V.SummaryPresentation.bind(M.context(w,h,N,Skin)).summary(game,summary)
M.drawCount=(M.drawCount or 0)+1
end)
end


function M.rsFacade(N)
local detail=N._page>=2 and N._state~='normal'
local party=N._party
if N._loaded then party={};for k,v in pairs(N._party) do party[k]=v end;party[N._cursor]=N._loaded end
return setmetatable({_party=party,_page=detail and 3 or N._page==3 and 2 or N._page,
_mode=(N._mode==2 or N._mode==3) and 'select_move' or (N._mode==0 or N._mode==5) and 'party' or 'read_only',
_moveCursor=(N._selected or 0)+1,_swapSlot=N._state=='swap' and (N._switch or 0)+1 or nil,
_hmNotice=N._state=='notice',_enemyParty=N._opts and N._opts.enemyParty,
_context=N._opts and N._opts.context,__cbeOwner=N},{__index=N})
end
function M.install()
if M.installed then return end
local N=req('src.ui.game3.summary_menu');local draw,input=N.draw,N.handleInput
V.Gen3MenuScene.register(N)
N.draw=function(...)
if not N.open or not V.Gen3Overlay.available() then return draw(...) end
V.Gen3Menus.nativePass(draw,...);return M.draw(N)
end
local ok,Skin=pcall(req,'src.ui.game3.rse.summary_menu')
if ok then
local skinDraw=Skin.draw
Skin.draw=function(Sm,...)
if not Sm.open or not V.Gen3Overlay.available() then return skinDraw(Sm,...) end
V.Gen3Menus.nativePass(skinDraw,Sm,...);return M.draw(Sm,Skin)
end
end
local found,Rs=pcall(req,'src.ui.game3.rs.summary_menu')
if found then
V.Gen3MenuScene.register(Rs)
local rd,ri=Rs.draw,Rs.handleInput
Rs.draw=function(...)
if not Rs.open or not V.Gen3Overlay.available() then return rd(...) end


local Registry=req('src.import.gba.map_sections_extract');local getInfo=Registry.getInfo
local pack=req('src.ui.game3.rse.scene_kit').loadLua('data/generated/gba/region_map/map_sections.lua')
Registry.getInfo=function(id) return pack and pack.sections and pack.sections[tonumber(id)] end
local result={pcall(V.Gen3Menus.nativePass,rd,...)};Registry.getInfo=getInfo
if not result[1] then error(result[2],0) end
return M.draw(M.rsFacade(Rs),{_st={contest=Rs._page==3},nativePolicy=Rs.policy})
end
Rs.handleInput=function(keys,...)
local ready=Rs.open and not Rs._fade and not Rs._pageTask and not Rs._reload and not Rs._pane
and not req('src.core.game3.display').planesBroken
if ready and keys:wasPressed('start') and V.Gen3MoveMemory
and V.Gen3MoveMemory.openSummary(M.rsFacade(Rs)) then return end
if ready and keys:wasPressed('select') then
if Rs._page==0 then
local mon=Rs._party[Rs._cursor];local count=0
for id=289,346 do if req('src.core.game3.pokemon').canLearnTmItem(mon.species,id) then count=count+1 end end
Rs.__cbeProfilePage=((Rs.__cbeProfilePage or 0)+1)%(3+math.max(1,math.ceil(count/16)));return
elseif Rs._page>=2 and Rs._state=='normal' then Rs.__cbeLearnPage=(Rs.__cbeLearnPage or 0)+1;return end
end
return ri(keys,...)
end
end


local P=req('src.core.game3.pokemon');local swap=P.swapMoves
P.swapMoves=function(mon,a,b,...)
local x,y=tonumber(a),tonumber(b)
local cache=mon and mon.maxPp;local aa=cache and cache[x];local bb=cache and cache[y]
local result=swap(mon,a,b,...)
if result and cache and x~=y and cache[x]==aa and cache[y]==bb then cache[x],cache[y]=bb,aa end
return result
end
N.handleInput=function(keys,...)
if N.open and keys and keys:wasPressed('start') and not N._slide.active
and not req('src.core.game3.display').planesBroken and V.Gen3MoveMemory
and V.Gen3MoveMemory.openSummary(N) then return end
if N.open and not req('src.core.game3.display').planesBroken and not N._slide.active and keys:wasPressed('select') then
if N._page==0 then
local P=req('src.core.game3.pokemon');local mon=N._party[N._cursor];local count=0
for id=289,346 do if P.canLearnTmItem(mon.species,id) then count=count+1 end end
N.__cbeProfilePage=((N.__cbeProfilePage or 0)+1)%(3+math.max(1,math.ceil(count/16)));return
elseif N._page==2 then N.__cbeLearnPage=(N.__cbeLearnPage or 0)+1;return end
end
return input(keys,...)
end
M.installed=true
end
return M
