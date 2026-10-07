local V=...
local req=V.engineRequire or require
local S=V.Gen3Services
local M={}
function M.draw(c,N,events)
local P=req('src.core.game3.pokemon');local storage=req('src.core.game3.storage').ensure(N._session)
if not storage then return end
local box=storage.boxes[storage.currentBox];local party=N._session.party or {}
local drawer=N.drawerOpen or N.mode=='party_drawer'
local hover=N.holdingMon or (drawer and party[N.partyCursor] or box.mons[N.cursorSlot])
c.panel(0,7,75,140);c.text(hover and P.displayMonName(hover) or 'POKéMON STORAGE',5,11,65,11,6)
if hover then
c.model(hover,2,24,71,81,N)
c.text(hover.isEgg and 'EGG' or 'Lv. '..tostring(hover.level or ''),6,108,63,10,5,S.accent)
local held=tonumber(hover.heldItem or hover.item) or 0
local name=held>0 and req('src.core.game3.items_data').displayName(held) or 'No held item'
c.text(name,6,120,63,10,4,S.muted)
local markings=tonumber(hover.markings) or 0
c.text('MARKS  '..markings,6,133,63,8,3.6,S.muted)
else c.text('Select a Pokémon\nto view its details.',7,58,61,32,5,S.muted) end
c.panel(80,7,84,14,N.cursorSlot==-10);c.text('PARTY POKéMON',85,10,74,8,4.5)
c.panel(167,7,73,14,N.cursorSlot==-20);c.text('CLOSE BOX',172,10,63,8,4.5)
c.panel(80,24,160,16,N.cursorSlot==0);c.text('←  '..(box.name or ('BOX '..storage.currentBox))..'  →',85,28,150,9,5,S.ink,'center')
for i=1,30 do
local x,y=80+((i-1)%6)*27,43+math.floor((i-1)/6)*21
local picked=N.holdingSource and N.holdingMon and N.holdingSource.loc=='box' and N.holdingSource.boxId==storage.currentBox and N.holdingSource.slot==i
local mon=not picked and box.mons[i] or nil
c.panel(x,y,25,20,N.cursorSlot==i and not drawer)
if mon then
c.portrait(mon,x+3,y+1,19,18)
if (tonumber(mon.heldItem or mon.item) or 0)>0 then c.text('*',x+19,y+1,5,6,4,S.accent) end
end
end
c.footer(N.holdingMon and ('HOLDING '..P.displayMonName(N.holdingMon)..'   A PLACE / SWAP   B CANCEL') or 'A ACTIONS   B BACK   ← / → SWITCH BOX AT GRID EDGES')
if drawer then

c.panel(79,23,161,126)
for i=1,6 do
local x,y=i==1 and 82 or 145,i==1 and 39 or 27+(i-2)*20
local cw=i==1 and 60 or 91;c.panel(x,y,cw,19,N.partyCursor==i)
local picked=N.holdingSource and N.holdingMon and N.holdingSource.loc=='party' and N.holdingSource.slot==i
local mon=not picked and party[i] or nil
if mon then c.portrait(mon,x+2,y+1,17,17);c.text(P.displayMonName(mon),x+21,y+3,cw-24,12,4)
else c.text('EMPTY',x+5,y+5,cw-10,9,4,S.muted) end
end
c.panel(145,129,91,16,N.partyCursor==7);c.text('CANCEL',150,133,81,9,4.5)
end
if N.mode=='action_menu' then c.panel(131,47,105,math.min(95,#N._activeActions*15+7));c.rows(N._activeActions,N.actionCursor,135,51,96,15)
elseif N.mode=='box_menu' then c.panel(115,43,121,52);c.rows({'SWITCH BOX','WALLPAPER','CANCEL'},N.boxMenuCursor,119,47,113,15)
elseif N.mode=='pick_wallpaper' then
c.panel(112,40,124,91);c.text('WALLPAPER',118,45,111,10,5)
local rows={};local R=req('src.core.game3.rom_text');local idx=S.rse(N._session) and 23 or 22
for i=1,4 do rows[i]=R.at('sMenuTexts',idx+((N.wallpaperCursor+i-2)%16)) end
c.rows(rows,1,117,61,114,15)
elseif N.mode=='message' then c.panel(15,112,220,36);c.text(N._status,22,119,206,25,5) end
local R=req('src.ui.game3.release_seq')
if R.isActive() then
c.panel(16,109,219,40)
if R.state=='confirm' then
c.text('Release '..P.displayMonName(R.mon)..'?',22,116,168,20,5)
c.panel(166,64,69,38);c.rows({'YES','NO'},R.yesNoCursor,170,68,61,15)
elseif R.state=='anim' then c.text('Releasing…',22,119,206,18,5)
else
local key=R.state=='released' and 'gText_PkmnWasReleased' or 'gText_ByeByePkmn'
c.text(req('src.core.game3.rom_text').plain(key,{dynamic={[0]=P.displayMonName(R.mon)}}),22,116,206,25,5)
end
end
M.last={box=storage.currentBox,selected=N.cursorSlot,hover=hover,mode=N.mode}
end
function M.install()
if M.installed then return end
S.wrap(req('src.ui.game3.box_storage_ui'),'POKéMON STORAGE',M.draw)
M.installed=true
end
return M

