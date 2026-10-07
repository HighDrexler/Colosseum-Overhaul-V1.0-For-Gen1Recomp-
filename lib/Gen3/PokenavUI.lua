

local V=...
local req=V.engineRequire or require
local S=V.Gen3Services
local M={}
local function gfx()return req('src.ui.game3.rse.pokenav.gfx')end
local function info()return req('src.ui.game3.rse.pokenav.mon_info')end
local labels={[0]='HOENN MAP','CONDITION','MATCH CALL','RIBBONS','SWITCH OFF','PARTY','SEARCH','BACK',
'COOL','BEAUTY','CUTE','SMART','TOUGH','BACK'}
local function clip(c,x,y,w,h,draw)
local G=love.graphics;G.push('all');G.setScissor(c.x+x*c.k,c.y+y*c.k,w*c.k,h*c.k)
draw(G);G.pop()
end
function M.map(c,n)
c.panel(0,7,174,141);c.panel(179,7,61,141)
clip(c,4,20,166,166*160/240,function(G)
G.translate(c.x+4*c.k,c.y+20*c.k);G.scale(c.k*166/240,c.k*166/240)
local old=gfx().dim;gfx().setDim(0);n:drawMap();gfx().setDim(old*16)
end)
local it=n.info or {};c.text(it.name or (n.rm and n.rm.mapSecName) or 'HOENN',185,14,49,31,6,S.accent)
if it.sec and it.pos then
local names=n.landmarkNames(it.sec,it.pos);c.text(table.concat(names,'\n'),185,48,49,58,4.5,S.muted)
for i,row in ipairs(gfx().manifest().cityMaps or {}) do if row.mapSec==it.sec and row.index==it.pos then
local img=gfx().image(gfx().manifest().sprites.cityMaps)
if img then c.image(img,183,53,53,53,love.graphics.newQuad(0,(i-1)*80,80,80,img:getDimensions())) end;break
end end
end
c.text(n.zoomed and 'ZOOMED IN' or 'REGION VIEW',185,116,49,20,4,S.muted)
c.footer(n.zoomed and 'D-PAD PAN   A ZOOM OUT   B BACK' or 'D-PAD EXPLORE   A ZOOM IN   B BACK')
end
local function condition(c,n,owner)
local w=n.window or {};local mon=n.picMon
c.panel(0,7,91,141);c.panel(96,7,144,141)
if mon then c.model(mon,2,25,87,101,owner) end
c.text(w.name or (mon and info().nickname(mon)) or 'CANCEL',7,12,77,12,5.5,S.accent)
c.text(w.location or '',7,130,77,12,4,S.muted)
c.text('CONTEST CONDITION',102,12,132,13,5.5,S.accent)
local G=love.graphics;local graph=n.graph
if graph and n.graphVisible then
local Graph=req(n.rs and 'src.ui.game3.rs.pokenav.condition_graph' or 'src.ui.game3.rse.pokenav.graph')
local max=n.rs and n.rs.graph:calcPositions({255,255,255,255,255}) or Graph.calcPositions(n.man,{[0]=255,255,255,255,255})
local function xy(p)return c.x+(168+(p.x-Graph.CENTER_X)*1.25)*c.k,c.y+(80+(p.y-Graph.CENTER_Y)*1.25)*c.k end
local polygon={};local values={}
for i=0,4 do local x,y=xy(max[i]);polygon[#polygon+1]=x;polygon[#polygon+1]=y
local p=graph.cur[i];x,y=xy(p);values[#values+1]=x;values[#values+1]=y
end
G.setColor(.67,.73,.69,.35);G.setLineWidth(math.max(1,c.k*.3));G.polygon('line',polygon)
G.setColor(.93,.73,.24,.42);G.polygon('fill',values);G.setColor(S.accent);G.polygon('line',values)
for i,label in ipairs(n.rs and {'COOL','TOUGH','SMART','CUTE','BEAUTY'} or {'COOL','BEAUTY','CUTE','SMART','TOUGH'}) do
local p=max[i-1];local x=168+(p.x-Graph.CENTER_X)*1.6;local y=80+(p.y-Graph.CENTER_Y)*1.5
c.text(label,x-16,y-5,32,10,3.6,S.muted,'center')
end
end
local sheen=mon and mon.contest and mon.contest.sheen or 0
c.text('SHEEN   '..sheen..' / 255',105,130,126,10,4.2,S.muted)
if n.marksMenu then
local m=n.marksMenu;local rows={}
for i,label in ipairs({'CIRCLE','SQUARE','TRIANGLE','HEART'}) do rows[i]=label..(m.array[i-1] and '  ON' or '  OFF') end
rows[5]='OK';rows[6]='CANCEL';c.panel(144,29,96,111);c.rows(rows,(m.cursorPos or 0)+1,148,33,88,17)
end
c.footer(n.searchMode and 'UP / DOWN POKéMON   A MARKINGS   B LIST' or 'UP / DOWN POKéMON   B BACK')
end
local function monlist(c,n,owner,ribbons)
c.panel(0,7,89,141);local list=n.list
if not list then return end
local rows={};for i,item in ipairs(list.entries or {}) do
local mon=info().mon(n.session,item)
rows[i]=info().nickname(mon)..'  Lv. '..info().level(mon)..'   '..tostring(item.data or 0)
end
local idx=list:selectedIndex()+1;local item=list.entries[idx];local mon=item and info().mon(n.session,item)
if mon then c.model(mon,2,22,85,113,owner) end
c.text(ribbons and 'RIBBON COLLECTION' or 'CONDITION RANKING',6,12,77,13,4.5,S.accent)
c.rows(rows,idx,94,7,146,17,(list.top or 0)+1,8)
c.footer('UP / DOWN SELECT   LEFT / RIGHT PAGE   A DETAILS   B BACK')
end
local function ribbons(c,n,owner)
c.panel(0,7,89,141);c.panel(94,7,146,98);c.panel(94,110,146,38)
local mon=n.picMon;if mon then c.model(mon,2,25,85,109,owner) end
c.text(n.info and n.info.name or '',6,12,77,13,5.5,S.accent)
local man=n.man;local img=gfx().image(man.sprites.ribbonsSmall.png)
local function row(pos,id)
local g=man.ribbonGfx[id];if not g or not img then return end
local x,y=99+pos%9*15,32+math.floor(pos/9)*17
if n.textMode=='desc' and n.selectedPos==pos then c.panel(x-1,y-1,16,17,true) end
c.image(img,x,y,14,14,love.graphics.newQuad(g.pal*16,g.tile*16,16,16,img:getDimensions()))
end
for i,id in ipairs(n.normalIds or {}) do row(i-1,id) end
for i,id in ipairs(n.giftIds or {}) do row(27+i-1,id) end
c.text('RIBBONS',100,12,134,12,5.5,S.accent)
local desc={};for _,key in ipairs(n.desc or {}) do desc[#desc+1]=gfx().plain(key) end
c.text(n.textMode=='desc' and table.concat(desc,' ') or n.countText or '',100,115,134,28,5)
c.footer(n.textMode=='desc' and 'D-PAD SELECT RIBBON   B BACK' or 'UP / DOWN POKéMON   A RIBBON DETAILS   B LIST')
end
local function calls(c,n,events)
c.panel(0,7,89,141);c.panel(94,7,146,141)
local entry=n:entry(n.checkPage and n.top or n:selectedIndex())
local MC=req('src.core.game3.rse.match_call')
c.text(entry and MC.mapName(entry.mapSec) or 'MATCH CALL',6,12,77,24,5,S.accent)
if n.checkPage then
S.replay(c,events,function(e)return e.kind=='text' and e.x>=96 and e.y>8 and e.y<144 end)
elseif n.entries then
local rows={};for i,e in ipairs(n.entries) do local d,name=n:entryText(e);rows[i]=tostring(d or '')..' '..tostring(name or '') end
c.rows(rows,n:selectedIndex()+1,98,12,138,16,(n.top or 0)+1,8)
end
if n.picVisible and n.picId and n.picId>=0 then
local img=req('src.ui.game3.rse.scene_kit').rgbaImage(req('src.core.game3.cache_paths').CACHE_ROOT..'/trainers/front/'..n.picId..'.rgba',64,64)
c.image(img,13,46,63,63)
elseif n.showOptions and not n.callBox then
local rows={};for i,id in ipairs(n.options or {}) do rows[i]=gfx().plain(gfx().manifest().optionTexts[id]) end
c.rows(rows,(n.optionCursor or 0)+1,5,53,79,20)
else c.text('REGISTERED\n'..#(n.entries or {}),7,64,75,37,5,S.muted) end
c.footer(n.callBox and 'A / B CONTINUE' or n.showOptions and 'UP / DOWN SELECT   A CONFIRM   B BACK' or 'D-PAD CONTACT   A CALL / CHECK   B BACK')
end
function M.draw(c,N,events)
local shell=N._s;if not shell then return end
local n=shell.screen;local id=shell.menuId
c.panel(0,7,240,141)
if not n then c.text('POKéNAV',8,49,224,25,10,S.accent,'center');c.footer('OPENING');return end
if n.menuType~=nil then
local MM=req('src.ui.game3.rse.pokenav.main_menu');local rows={}
for i,it in ipairs(MM.ITEMS[n.menuType]) do rows[i]=labels[it] end
c.panel(0,7,95,141);c.text(n.menuType==3 and 'CONDITION' or n.menuType==4 and 'SEARCH' or 'POKéNAV',8,16,79,23,8,S.accent)
c.text(gfx().plain(n.description),8,57,79,69,5.5,S.muted)
c.rows(rows,(n.cursorPos or 0)+1,101,7,139,22)
c.footer('UP / DOWN SELECT   A OPEN   B BACK')
elseif id=='region_map' then M.map(c,n)
elseif id=='condition_graph_party' or id=='condition_graph_search' then condition(c,n,N)
elseif id=='ribbons_summary_screen' then ribbons(c,n,N)
elseif id=='match_call' then calls(c,n,events)
elseif n.list then monlist(c,n,N,id=='ribbons_mon_list' or id=='ribbons_return_to_mon_list')
else c.footer('A SELECT   B BACK') end
M.last={page=id,menuType=n.menuType}
end
function M.rsDraw(c,N,events)
local s=N._s;if not s then return end
local n,id=s.feature,s.menu;local Gfx=req('src.ui.game3.rs.pokenav.gfx')
local Data=req('src.ui.game3.rs.pokenav.condition_data');local P=req('src.core.game3.pokemon')
c.panel(0,7,240,141)
if not n then
local names={main={'HOENN MAP','CONDITION',"TRAINER'S EYES",'RIBBONS','SWITCH OFF'},
condition={'PARTY','SEARCH','BACK'},search={'COOL','BEAUTY','CUTE','SMART','TOUGH','BACK'}}
local rows={};for i,name in ipairs(names[id] or {}) do rows[i]=s.rows[i] and name or '—' end
c.panel(0,7,95,141);c.text(id=='main' and 'POKéNAV' or id:upper(),8,16,79,23,8,S.accent)
local menu=s.nav.menus[id];c.text(menu.help[s.helpOverride or s.cursor+1] or '',8,57,79,69,5.5,S.muted)
c.rows(rows,s.cursor+1,101,7,139,22);c.footer('UP / DOWN SELECT   A OPEN   B BACK')
elseif id=='map' then
c.panel(0,7,174,141);c.panel(179,7,61,141)
clip(c,4,20,166,166*160/240,function(G)
G.translate(c.x+4*c.k,c.y+20*c.k);G.scale(c.k*166/240,c.k*166/240);n:draw(s.nav,s.shell)
end)
c.text(n.name or 'HOENN',185,14,49,32,6,S.accent)
local landmarks=req('src.ui.game3.rs.pokenav.data').landmarks(s.shell,s.session,n.section,n.pos,n.man.mapsecs.NONE)
c.text(table.concat(landmarks,'\n'),185,52,49,54,4.5,S.muted)
c.text(n.zoomed and 'ZOOMED IN' or 'REGION VIEW',185,116,49,20,4,S.muted)
c.footer(n.zoomed and 'D-PAD PAN   A ZOOM OUT   B BACK' or 'D-PAD EXPLORE   A ZOOM IN   B BACK')
elseif id=='graph_party' or id=='graph_search' then
local row=n.rows[n.displayIndex or n.index];local marks
if n.markings then
marks={cursorPos=n.markings.cursor,array={}}
for i=0,3 do marks.array[i]=math.floor(n.markings.value/2^i)%2==1 end
end
condition(c,{rs=n,picMon=n.mon,window={name=n.mon and P.displayMonName(n.mon) or 'CANCEL',
location=row and not row.cancel and Data.location(s.session,row,n.man) or ''},
graph={cur=n.graph.curPositions},graphVisible=true,searchMode=n.searchMode,marksMenu=marks},N)
elseif id=='condition_results' or id=='ribbons_list' then
c.panel(0,7,89,141);local rows={}
for i,row in ipairs(n.rows) do local mon=Data.mon(s.session,row)
rows[i]=P.displayMonName(mon)..'  Lv. '..Data.level(mon,row.box~=14)..'   '..tostring(row.value)
end
local mon=Data.mon(s.session,n.rows[n.index]);if mon then c.model(mon,2,22,85,113,N) end
c.text(id=='ribbons_list' and 'RIBBON COLLECTION' or 'CONDITION RANKING',6,12,77,13,4.5,S.accent)
c.rows(rows,n.index,94,7,146,17,n.top,8);c.footer('UP / DOWN SELECT   LEFT / RIGHT PAGE   A DETAILS   B BACK')
elseif id=='ribbons_detail' then
c.panel(0,7,89,141);c.panel(94,7,146,98);c.panel(94,110,146,38)
c.model(n.mon,2,25,85,109,N);c.text(P.displayMonName(n.mon),6,12,77,13,5.5,S.accent)
c.text('RIBBONS',100,12,134,12,5.5,S.accent)
local function icon(pos,id)
local x,y=99+pos%9*15,32+math.floor(pos/9)*17
if n.selecting and n.row*9+n.column==pos then c.panel(x-1,y-1,16,17,true) end
c.image(Gfx.image(n.man.icons[id].small),x,y,14,14)
end
for i,ribbon in ipairs(n.normal) do icon(i-1,ribbon) end
for i,ribbon in ipairs(n.gift) do icon(27+i-1,ribbon) end
c.text(n.selecting and table.concat(n:description(),' ') or n.man.strings.Ribbons..' '..n.rows[n.index].value,100,115,134,28,5)
c.footer(n.selecting and 'D-PAD SELECT RIBBON   B BACK' or 'UP / DOWN POKéMON   A RIBBON DETAILS   B LIST')
elseif id=='eyes' then
c.panel(0,7,89,141);c.panel(94,7,146,141)
local row=n.entries[n.index];local T=req('src.core.game3.scripting.trainers')
c.text(row and req('src.ui.game3.rs.pokenav.data').sectionName(n.region,row.regionMapSectionId) or "TRAINER'S EYES",6,12,77,24,5,S.accent)
if n.detail and row then
local trainer=assert(T.get(row.opponentId));local pic=req('src.core.game3.trainer_pic').front(trainer.pic)
if pic then c.image(pic.image,13,46,63,63) end
c.text(trainer.className..' '..trainer.name,100,12,134,20,5.5,S.accent)
local text=n.man.descriptions[row.descriptionId] or {}
c.text(table.concat({n.man.strings.Strategy,text[1] or '',n.man.strings.TrainersPokemon,text[2] or '',
n.man.strings.SelfIntroduction,text[3] or '',text[4] or ''},'\n'),100,37,134,99,4.5)
else
local rows={};for i,entry in ipairs(n.entries) do local trainer=assert(T.get(entry.opponentId))
rows[i]=trainer.className..' '..trainer.name..(entry.rematchNo~=0 and ' *' or '')
end
c.rows(rows,n.index,98,12,138,16,n.top,8)
c.text('REGISTERED\n'..#rows,7,64,75,37,5,S.muted)
end
c.footer(n.detail and 'UP / DOWN TRAINER   B LIST' or 'D-PAD TRAINER   A DETAILS   B BACK')
end
M.last={page=id,rs=true}
end
function M.install()
local ok,P=pcall(req,'src.ui.game3.rse.pokenav.init');if not ok or M.installed then return end



local K=req('src.ui.game3.rse.scene_kit');local play=K.playSe;local SE=req('src.core.game3.se_ids')
K.playSe=function(name)
if SE[name]==nil then
local id=req('src.core.game3.constants').of(req('src.core.GameVersion').get()):id('songs',name)
if id then return req('src.core.game3.audio').playSe(id) end
end
return play(name)
end
S.wrap(P.Host,'POKéNAV',M.draw)



local navDraw=P.Host.draw
P.Host.draw=function(...)
local eligible=S.alive(P.Host) and V.Gen3Overlay.available()
local result={navDraw(...)}
local shell=P.Host._s;local n=shell and shell.screen
if eligible and shell and shell.menuId=='match_call' and n and n.visible and n.callBox then
V.Gen3FieldUI.printerDialogue(n.printer,shell.frames or 0)
end
return unpack(result)
end
local found,Rs=pcall(req,'src.ui.game3.rs.pokenav.init')
if found then S.wrap(Rs.Host,'POKéNAV',M.rsDraw) end
M.installed=true
end
return M
