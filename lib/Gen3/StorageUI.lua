local V=...
local req=V.engineRequire or require
local S=V.Gen3Services
local M={}
local BOX_ACTIONS={'SWITCH BOX','WALLPAPER','CANCEL'}
local WALLPAPER_GROUPS={'SCENERY 1','SCENERY 2','SCENERY 3','OTHER'}
local MARKINGS={'CIRCLE','SQUARE','TRIANGLE','HEART'}
local YES_NO={'YES','NO'}
local RELEASE_TEXT={released='WasReleased',bye='ByeBye',surprise='Surprise',came_back='CameBack',worried='Worried'}
function M.draw(c,N,events)
local P=req('src.core.game3.pokemon');local storage=req('src.core.game3.storage').ensure(N._session)
local version=N._session.version or req('src.core.GameVersion').get()
local nativeRS=version=='ruby' or version=='sapphire'
local rs=nativeRS and req('src.ui.game3.rs.storage_policy')
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
local picked=N.holdingSource and N.holdingMon==box.mons[i] and N.holdingSource.loc=='box' and N.holdingSource.boxId==storage.currentBox and N.holdingSource.slot==i
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
local picked=N.holdingSource and N.holdingMon==party[i] and N.holdingSource.loc=='party' and N.holdingSource.slot==i
local mon=not picked and party[i] or nil
if mon then c.portrait(mon,x+2,y+1,17,17);c.text(P.displayMonName(mon),x+21,y+3,cw-24,12,4)
else c.text('EMPTY',x+5,y+5,cw-10,9,4,S.muted) end
end
c.panel(145,129,91,16,N.partyCursor==7);c.text('CANCEL',150,133,81,9,4.5)
end
if N.mode=='action_menu' then
local rows={};for i,a in ipairs(N._activeActions or {})do rows[i]=nativeRS and rs.menuText(a) or a end
c.panel(131,47,105,math.min(99,#rows*15+7));c.rows(rows,N.actionCursor,135,51,96,15)
elseif N.mode=='box_menu' then
local actions=nativeRS and rs.boxActions() or BOX_ACTIONS
local rows={};for i,a in ipairs(actions)do rows[i]=nativeRS and rs.menuText(a) or a end
c.panel(115,43,121,#rows*15+7);c.rows(rows,N.boxMenuCursor,119,47,113,15)
elseif N.mode=='pick_box' or N.mode=='deposit_box_full' then
local selected=nativeRS and (N._pickBox or storage.currentBox) or storage.currentBox
local rows={};for i,b in ipairs(storage.boxes)do rows[i]=b.name or ('BOX '..i)end
local first=math.max(1,math.min(selected-2,#rows-5))
c.panel(111,38,128,108);c.text(N._pendingDeposit and 'DEPOSIT IN BOX' or 'SWITCH BOX',117,42,116,10,5)
c.rows(rows,selected,116,57,118,14,first,6)
c.text(nativeRS and '← / → SELECT   A CONFIRM   B BACK' or '↑ / ↓ SELECT   A CONFIRM   B BACK',116,135,118,8,3.2,S.muted)
if N.mode=='deposit_box_full' then c.panel(15,112,220,36);c.text(rs.text('BoxIsFull'),22,119,206,25,5)end
elseif N.mode=='pick_wallpaper_group' then
c.panel(112,40,124,91);c.text('WALLPAPER GROUP',118,45,111,10,5)
c.rows(WALLPAPER_GROUPS,N._wallpaperGroup or 1,117,61,114,15)
elseif N.mode=='markings' then
local st=N._markings;c.panel(143,38,96,108);c.text('MARKINGS',149,43,84,10,5)
local rows={};for i,name in ipairs(MARKINGS)do local bit=2^(i-1);rows[i]=(st.value%(bit*2)>=bit and '[X] 'or'[ ] ')..name end
rows[5]='CONFIRM';rows[6]='CANCEL';c.rows(rows,st.cursor+1,147,56,88,14)
elseif N.mode=='pick_wallpaper' then
c.panel(112,40,124,91);c.text('WALLPAPER',118,45,111,10,5)
local rows={};local R=req('src.core.game3.rom_text');local idx=S.rse(N._session) and 23 or 22
local base=nativeRS and ((N._wallpaperGroup or 1)-1)*4 or 0
for i=1,4 do rows[i]=nativeRS and rs.wallpaperName(base+i) or R.at('sMenuTexts',idx+((N.wallpaperCursor+i-2)%16)) end
c.rows(rows,nativeRS and N.wallpaperCursor-base or 1,117,61,114,15)
elseif N.mode=='message' then c.panel(15,112,220,36);c.text(N._status,22,119,206,25,5) end
local R=req('src.ui.game3.release_seq')
if R.isActive() then
c.panel(16,109,219,40)
if R.state=='confirm' then
c.text('Release '..P.displayMonName(R.mon)..'?',22,116,168,20,5)
c.panel(166,64,69,38);c.rows(YES_NO,R.yesNoCursor,170,68,61,15)
elseif R.state=='anim' or R.state=='return_anim' then c.text(R.state=='anim' and 'Releasing…' or 'Returning…',22,119,206,18,5)
else
local key=R.state=='released' and 'gText_PkmnWasReleased' or 'gText_ByeByePkmn'
local text=nativeRS and rs.text(RELEASE_TEXT[R.state] or 'ByeBye',R.mon)
or req('src.core.game3.rom_text').plain(key,{dynamic={[0]=P.displayMonName(R.mon)}})
c.text(text,22,116,206,25,5)
end
end
M.last={box=storage.currentBox,selected=N.cursorSlot,hover=hover,mode=N.mode}
end
function M.install()
if M.installed then return end
local storage=req('src.core.game3.storage');local P=req('src.core.game3.pokemon')
local hasRestorer,restorer=pcall(req,'src.core.game3.rse.storage_rs')
local nativeHeal=storage.fullHealMon
storage.fullHealMon=function(mon,session,...)
local result=nativeHeal(mon,session,...)


if type(mon)=='table' and type(mon.moves)=='table' then
local numeric=false;for _,id in ipairs(mon.moves)do if type(id)=='number'and id>0 then numeric=true;break end end
if numeric and hasRestorer and restorer.restorePP then restorer.restorePP(mon)
elseif numeric then
for slot,id in ipairs(mon.moves)do if type(id)=='number' and id>0 then
local base=P.movePp(id);local bonus
if type(mon.ppBonusesPacked)=='number'then bonus=math.floor(mon.ppBonusesPacked/4^(slot-1))%4
elseif type(mon.ppBonuses)=='table'then bonus=tonumber(mon.ppBonuses[slot])end
local max
if bonus~=nil then max=base+math.floor(base*math.max(0,math.min(3,bonus))/5)
else max=type(mon.maxPp)=='table'and tonumber(mon.maxPp[slot])or base end
mon.pp=mon.pp or {};mon.maxPp=mon.maxPp or {};mon.pp[slot]=max;mon.maxPp[slot]=max
end end
end
end
return result
end


S.wrap(req('src.ui.game3.box_storage_ui'),'POKéMON STORAGE',M.draw,nil,false)
M.installed=true
end
return M

