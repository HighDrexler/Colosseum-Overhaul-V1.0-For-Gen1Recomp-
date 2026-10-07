

local V=...
local req=V.engineRequire or require
local S=V.Gen3Services
local M={}
local function pokemon() return req('src.core.game3.pokemon') end
local function list(c,rows,cursor,first,model,owner,counts)
c.panel(0,7,98,141);c.text(counts or '',6,12,86,20,4.5,S.muted)
if model then c.model(model,3,34,92,104,owner) else c.text('NO DATA',8,68,82,13,7,S.muted,'center') end
c.rows(rows,cursor,103,7,137,15,first,9)
end
local function tabs(c,selected,labels)
labels=labels or {'AREA','CRY','SIZE','BACK'}
for i,name in ipairs(labels) do local x=(i-1)*60;c.panel(x,134,58,14,selected==i-1);c.text(name,x+3,137,52,8,4,S.ink,'center') end
end
local function info(c,texts,mon,owner)
c.panel(0,7,91,88);c.model(mon,1,9,89,85,owner);c.panel(96,7,144,88);c.panel(0,99,240,32)
for _,row in ipairs(texts or {}) do
if row.y>=90 then c.text(row.text,7,105,226,23,5)
elseif row.y>0 then c.text(row.text,math.max(103,row.x+7),row.y-9,math.max(1,233-row.x),14,5.7) end
end
end
function M.emerald(c,N,events,s)
s=s or N.active();if not s then return end
local P=pokemon();local page=s.page
if page==0 or page==3 then
local rows={};for i=0,s.list.count-1 do
local it=s.list.items[i];rows[i+1]=string.format('%03d  %s%s',s.dexMode==0 and (N.hoennNumber(it.dexNum) or it.dexNum) or it.dexNum,it.owned and '● ' or '',it.seen and P.name(N.speciesOf(it.dexNum)) or '-----')
end
local it=s.list.items[s.selected];local mon=it and it.seen and S.mon(N.speciesOf(it.dexNum),s.dex) or nil
list(c,rows,s.selected+1,math.max(1,math.min(s.selected-3,#rows-8)),mon,N.Host,'SEEN '..(s.seenCount or 0)..'  /  CAUGHT '..(s.ownCount or 0))
c.footer('A DETAILS   SELECT SEARCH / SORT   START LIST MENU   B BACK')
if s.menuIsOpen or s.menuY~=0 then
local rows={'CANCEL','FIRST ENTRY','LAST ENTRY'};if page==3 then rows[#rows+1]='BACK TO LIST' end;rows[#rows+1]='CLOSE POKéDEX'
c.panel(124,40,112,#rows*16+8);c.rows(rows,s.menuCursorPos+1,128,44,104,16)
end
elseif page==1 or page==8 then
local data=page==8 and s.caught or s.info
if data then info(c,data.text,S.mon(N.speciesOf(data.dexNum),s.dex),N.Host) end
if page==1 then tabs(c,s.selectedScreen);c.footer('← / → SELECT   A OPEN   ↑ / ↓ POKéMON   B LIST')
else c.footer('NEW POKéDEX ENTRY   A CONTINUE') end
elseif page==2 then
c.panel(0,7,240,141);local q=s.searchState or {};local names={'SEARCH','ORDER','CANCEL'}
for i,name in ipairs(names) do c.panel((i-1)*80,7,78,14,q.phase=='topbar' and q.topBar==i-1);c.text(name,(i-1)*80+4,10,70,9,4.5) end
local labels={'NAME','COLOR','TYPE','ORDER','DEX MODE','SEARCH'}
local ys={27,43,59,75,91,107};local positions={[0]={0,27,140},[1]={0,43,140},[2]={0,59,86},[3]={86,59,54},[4]={0,75,140},[5]={0,91,140},[6]={0,107,140}}
local p=positions[q.menuItem or 0];if q.phase~='topbar' and p then c.panel(p[1]+1,p[2]-1,p[3]-2,16,true) end
for i,label in ipairs(labels) do if i~=5 or s.nationalEnabled then c.text(label,5,ys[i]+1,38,12,4,S.muted) end end
if q.phase=='param' then c.panel(141,23,98,103) end
for _,row in ipairs(s.searchText or {}) do
local yy=row.y>=120 and row.y+6 or row.y+12
c.text(row.text,row.x,yy,math.min(row.x<140 and 139-row.x or 238-row.x,230),13,5)
end
c.footer('D-PAD SELECT   A CONFIRM   B BACK')
elseif page==5 then
c.panel(0,7,240,124);local a=s.area
if a and a.map then
local G=love.graphics;G.push('all');G.setScissor(c.x+3*c.k,c.y+10*c.k,175*c.k,117*c.k)
G.translate(c.x,c.y+9*c.k);G.scale(c.k*.76,c.k*.76)
G.setColor(1,1,1,1);G.draw(a.map,0,0)
if a.glow then G.setColor(1,.8,.25,.6);G.draw(a.glow,0,0) end
G.setColor(1,.8,.2,1);for _,m in ipairs(a.markers or {}) do G.circle('fill',m.x,m.y-8,3) end
if a.player and not a.player.hidden then G.setColor(1,1,1,1);G.circle('line',a.player.x,a.player.y-8,4) end
G.pop();c.text(a.unknown and 'AREA UNKNOWN' or 'KNOWN HABITATS',181,22,54,22,5,S.accent)
end
tabs(c,0);c.footer('← / → PAGE   B ENTRY')
elseif page==6 then
c.panel(0,7,240,124);c.text('VOICE ANALYSIS',8,13,210,12,6)
if s.cry and s.cry.pixels then
local G=love.graphics;G.setColor(.68,.73,.7,.16);G.setLineWidth(math.max(1,c.k*.2))
for x=0,224,16 do G.line(c.x+(8+x)*c.k,c.y+31*c.k,c.x+(8+x)*c.k,c.y+87*c.k) end
for y=0,56,8 do G.line(c.x+8*c.k,c.y+(31+y)*c.k,c.x+232*c.k,c.y+(31+y)*c.k) end
G.setColor(S.accent)
for x=0,223 do for y=0,55 do
local v=s.cry.pixels[y*256+(x+(s.cry.playhead or 0))%256] or 0
if v>=8 then G.rectangle('fill',c.x+(8+x)*c.k,c.y+(31+y)*c.k,c.k,c.k) end
end end
end
c.text('A  PLAY CRY',8,109,224,12,5,S.accent);tabs(c,1);c.footer('A PLAY   ← / → PAGE   B ENTRY')
elseif page==7 then
c.panel(0,7,240,124);c.text(s.sizeText and s.sizeText.text or 'SIZE COMPARISON',8,13,224,15,6)
local G=love.graphics;G.push('all');G.translate(c.x,c.y);G.scale(c.k,c.k);G.setColor(.83,.84,.76,1)
for _,t in ipairs({s.sizeTrainer,s.sizeMon}) do if t and t.img then local k=256/math.max(1,t.scale);G.draw(t.img,t.x,t.y+t.y2,0,k,k,32,32) end end
G.pop();tabs(c,2);c.footer('← / → PAGE   B ENTRY')
else c.panel(0,7,240,141) end
M.last={page=page,selected=s.selected,owner=N.Host}
end
function M.frlg(c,N,events)
local P=pokemon();local D=req('src.core.game3.dex');local Data=req('src.core.game3.pokedex_data')
if N.screen=='ordered_list' then
local order=Data.getOrderList(N.currentOrder,N._dex);local rows={}
for i,sp in ipairs(order) do rows[i]=string.format('%03d  %s%s',P.national(sp) or sp,D.isCaught(N._dex,sp) and '● ' or '',D.isSeen(N._dex,sp) and P.name(sp) or '-----') end
local sp=order[N.listCursor];local mon=sp and D.isSeen(N._dex,sp) and S.mon(sp,N._dex) or nil
list(c,rows,N.listCursor,N.listScroll+1,mon,N,'SEEN '..D.countSeen(N._dex,N.mode)..' / CAUGHT '..D.countCaught(N._dex,N.mode))
c.footer('↑ / ↓ SELECT   A DETAILS   B CONTENTS')
elseif N.screen=='mode_select' then
c.panel(0,7,240,141)
for i=N.modeScroll+1,math.min(#N.MODES,N.modeScroll+9) do
local row=N.MODES[i];local y=8+(i-N.modeScroll-1)*15
c.panel(0,y,157,14,N.modeCursor==i);c.text(row.label,6,y+2,145,10,5,row.unlocked==false and S.muted or row.isHeader and S.accent or S.ink)
end
c.text('SEEN\n'..D.countSeen(N._dex,'national')..'\n\nCAUGHT\n'..D.countCaught(N._dex,'national'),169,31,60,100,6)
c.footer('↑ / ↓ SELECT   A OPEN   B BACK')
elseif N.screen=='category_grid' then
local pages=Data.getUnlockedCategoryPages(N.currentCategory,N._dex);local mons=pages[N.categoryPage] and pages[N.categoryPage].mons or {}
c.panel(0,7,240,141);c.text(tostring(N.currentCategory):upper():gsub('_',' '),7,11,180,12,6)

local width=228/math.max(1,#mons)
for i,sp in ipairs(mons) do
local x=6+(i-1)*width;c.panel(x,32,width-3,103,N.categorySlot==i)
if D.isSeen(N._dex,sp) then c.portrait(S.mon(sp,N._dex),x+2,38,width-7,66);c.text(P.name(sp),x+4,111,width-11,15,5)
else c.text('-----',x+4,70,width-11,20,5) end
end
c.footer('D-PAD SELECT / PAGE   A DETAILS   B CONTENTS')
else
local sp=N._regSpecies or N.selectedSpecies;if not sp then return end
local caught=D.isCaught(N._dex,sp);local C=req('src.ui.game3.pokedex_chrome');local entry=C.getEntry(sp)
c.panel(0,7,91,123);c.model(S.mon(sp,N._dex),1,12,89,110,N);c.panel(96,7,144,123)
c.text(string.format('%03d  %s',P.national(sp) or sp,P.name(sp)),103,13,131,16,6)
if N.dataPage~=2 then
c.text(caught and entry.categoryName or 'UNKNOWN',103,34,131,12,5,S.accent)
c.text(caught and ('HEIGHT  '..entry.heightFormatted..'\nWEIGHT  '..entry.weightFormatted) or 'HEIGHT  ???\nWEIGHT  ???',103,51,131,29,5)
c.text(caught and entry.description or 'Catch this Pokémon to record its research data.',103,87,131,36,4.5,S.muted)
else


local G=love.graphics;G.push('all');G.translate(c.x+99*c.k,c.y+33*c.k);G.scale(c.k*.57,c.k*.57)
C.drawMap('kanto',132,52)
local areas=0;for _,key in ipairs(Data.getWildAreasForSpecies(sp)) do if Data.getAreaMapKey(key)=='kanto' then local m=Data.getAreaMarker(key);if m then C.drawAreaMarker(m.shape,132+m.x-32,52+m.y);areas=areas+1 end end end
if caught then
local pic=P.dexFrontPic(sp,D.defaultPersonality(N._dex,sp));local trainer=C.getTrainerPic(N.playerGender())
if pic then C.drawSilhouette(pic.image,37,108+(entry.pokemonOffset or 0),N.silhouetteScale(entry.pokemonScale),N.silhouetteScale(entry.pokemonScale),32,32) end
if trainer then C.drawSilhouette(trainer,80,108+(entry.trainerOffset or 0),N.silhouetteScale(entry.trainerScale),N.silhouetteScale(entry.trainerScale),32,32) end
end
G.pop();c.text('SIZE / HABITAT',103,34,131,12,5,S.accent);if areas==0 then c.text('AREA UNKNOWN',169,101,66,20,4,S.muted) end
end
tabs(c,(N.dataPage or 1)-1,{'ENTRY','SIZE / AREA','START: CRY','B: BACK'})
c.footer(N.screen=='registration' and 'NEW POKéDEX ENTRY   A CONTINUE' or (N.dataPage==2 and 'A LIST   B PREVIOUS DATA   START CRY' or 'A NEXT DATA   B LIST   START CRY   ↑ / ↓ POKéMON'))
end
M.last={page=N.screen,owner=N}
end
function M.install()
if M.installed then return end
S.wrap(req('src.ui.game3.pokedex'),'POKéDEX',M.frlg)
local ok,N=pcall(req,'src.ui.game3.rse.pokedex');if ok then S.wrap(N,'POKéDEX / HOENN',M.emerald,N.Host) end
M.installed=true
end
return M
