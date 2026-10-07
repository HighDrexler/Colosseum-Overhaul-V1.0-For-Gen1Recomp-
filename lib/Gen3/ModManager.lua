

local V=...
local req=V.engineRequire or require
local M={installed=false}
local function G() return love.graphics end
local function clamp(v,a,b) return math.max(a,math.min(b,v)) end
local function text(value,x,y,w,h,size,color,align)
V.Gen3Screens.text(value,x,y,w,h,size,color,align)
end
local function panel(x,y,w,h,u)
V.Gen3Screens.panel(x,y,w,h,u)
end
local function wrapped(value,width,size,maxRows)
local font=V.Gen3Screens.font(size)
local _,rows=font:getWrap(tostring(value or ''),math.max(1,width))
while maxRows and #rows>maxRows and size>12 do
size=size-1;font=V.Gen3Screens.font(size)
_,rows=font:getWrap(tostring(value or ''),math.max(1,width))
end
return rows,size
end
local function rowValue(row)
local value=row and (row.value or row.status)
if type(value)=='function' then
local ok,result=pcall(value,row)
value=ok and result or ''
end
if type(value)=='boolean' then return value and 'ON' or 'OFF' end
return value~=nil and tostring(value) or ''
end
local function heading(manager)
local screen=manager.screen or 'list'
if screen=='list' then return 'MOD MANAGER' end
if screen=='detail' or screen=='options' or screen=='permissions' then
local mod=manager.currentMod
if mod then return tostring(mod.name or mod.id or 'MOD') end
end
return ({errors='ERRORS',apply='PENDING CHANGES'})[screen]
or string.upper(screen)
end
local function status(manager,row)
if row and row.mod then
local mod=row.mod
if manager.isStaged and manager:isStaged(mod) then return 'STAGED' end
if mod.error then return 'ERROR' end
if mod.enabled==false then return 'OFF' end
if manager.runsHere and not manager:runsHere(mod) then return 'OTHER GAME' end
return 'ON'
end
if row and row.profile then return 'PROFILE' end
if row and row.header then return '' end
return rowValue(row)
end
local function detailText(manager)
local m=manager.currentMod
if not m then return 'Select a mod to see its details.' end
local parts={}
if m.version then parts[#parts+1]='Version '..tostring(m.version) end
if m.category then parts[#parts+1]=tostring(m.category) end
if manager.isStaged and manager:isStaged(m) then
parts[#parts+1]='Changes staged for restart'
elseif m.enabled==false then parts[#parts+1]='Disabled'
else parts[#parts+1]='Enabled' end
parts[#parts+1]=m.error and ('Error: '..tostring(m.error))
or m.note or m.description or ''
return table.concat(parts,'\n')
end
function M.draw(manager,w,h)
local g=G();local S=V.Gen3Screens
local u=clamp(math.min(w/1280,h/720),.78,1.55)
local gap=18*u
local margin=clamp(26*u,16,w*.06)
local x,y=margin,margin
local fullW,fullH=w-2*margin,h-2*margin
panel(x,y,fullW,fullH,u)
local pad=30*u
local bodyX=x+pad
local bodyY=y+126*u
local bodyH=fullH-193*u
local leftW=fullW*.625
local rightX=bodyX+leftW+gap
local rightW=fullW-2*pad-leftW-gap
text(heading(manager),bodyX,y+23*u,fullW-2*pad,43*u,36*u)
if manager.banner then
text(manager.banner,bodyX,y+69*u,fullW-2*pad,24*u,17*u,
{.99,.45,.28,1})
end
local tabs={'MODS','PROFILES','ERRORS'}
if manager.screen=='list' then
local tx=bodyX
for i,label in ipairs(tabs) do
local tw=math.min(167*u,leftW/3-8*u)
if i==(manager.tab or 1) then S.select(tx,y+76*u,tw,36*u,u) end
text(label,tx+12*u,y+79*u,tw-24*u,30*u,20*u,
i==(manager.tab or 1) and nil or {.60,.76,.77,1})
tx=tx+tw+8*u
end
else
text(string.upper(manager.screen or ''),bodyX,y+79*u,leftW,28*u,
19*u,{.62,.82,.83,1})
end
panel(bodyX,bodyY,leftW,bodyH,u)
panel(rightX,bodyY,rightW,bodyH,u)
local rows=manager.screen=='options' and (manager.optionRows or {})
or (manager.rowsForScreen and manager:rowsForScreen() or {})
local visible=math.min(11,math.max(1,math.floor((bodyH-44*u)/(45*u))))
local first=manager.screen=='options' and (manager.scroll or 0)+1
or (manager.scroll or 1)
first=clamp(first,1,math.max(1,#rows-visible+1))
local rowH=(bodyH-36*u)/visible
for i=first,math.min(#rows,first+visible-1) do
local row=rows[i]
local yy=bodyY+18*u+(i-first)*rowH
if i==manager.cursor and not row.header and not row.inert then
S.select(bodyX+14*u,yy,leftW-28*u,rowH-3*u,u)
end
local color=row.header and {.59,.77,.76,1}
or row.inert and {.67,.71,.70,1} or nil
local label=tostring(row.label or row.name or row.id or '')
local tag=status(manager,row)
local labelW=leftW-(tag~='' and 186*u or 68*u)
text(label,bodyX+31*u,yy+3*u,labelW,rowH-7*u,
row.header and 17*u or 22*u,color)
if tag~='' then
text(tag,bodyX+leftW-168*u,yy+3*u,139*u,rowH-7*u,17*u,
tag=='ERROR' and {.98,.43,.29,1} or {.62,.82,.83,1},'right')
end
end
if #rows==0 then
text('No entries',bodyX+28*u,bodyY+32*u,leftW-56*u,36*u,21*u,
{.65,.75,.74,1})
end
if #rows>visible then
text(string.format('%d–%d / %d',first,
math.min(#rows,first+visible-1),#rows),
bodyX+24*u,bodyY+bodyH-30*u,leftW-48*u,22*u,15*u,
{.58,.72,.72,1},'right')
end
local note
if manager.screen=='list' and manager.tab==1 then
local focus=rows[manager.cursor]
if focus and focus.mod then
local mod=focus.mod
note=(mod.description or mod.note or '')
if mod.error then note='Error: '..tostring(mod.error) end
else note='Choose a mod to inspect its options and status.' end
elseif manager.screen=='detail' or manager.screen=='options'
or manager.screen=='permissions' then
note=detailText(manager)
elseif manager.screen=='apply' then
local staged=manager.stagedList and manager:stagedList() or {}
note=#staged==0 and 'No changes are waiting.' or
tostring(#staged)..' change(s) will take effect after restart.'
elseif manager.screen=='errors' or
(manager.screen=='list' and manager.tab==3) then
note='Review the reported errors here. The selected item stays in the native manager.'
else
note='Profiles save and restore a set of enabled mods and their options.'
end
text('DETAILS',rightX+24*u,bodyY+20*u,rightW-48*u,30*u,20*u,
{.63,.82,.82,1})
local lines,size=wrapped(note,rightW-56*u,20*u,
math.max(1,math.floor((bodyH-94*u)/(27*u))))
local max=math.floor((bodyH-94*u)/(size*1.45))
for i=1,math.min(#lines,max) do
text(lines[i],rightX+26*u,bodyY+60*u+(i-1)*size*1.45,
rightW-52*u,size*1.34,size)
end
local footer=manager.notice or
(manager.screen=='list' and manager.tab==1
and 'A  OPEN     SELECT  TOGGLE     START  APPLY     B  BACK'
or 'A  CHOOSE     B  BACK')
text(footer,bodyX,y+fullH-55*u,fullW-2*pad,31*u,18*u,
{.66,.82,.80,1})
if manager.overlay then
local overlay=manager.overlay
local ow=math.min(fullW*.72,650*u)
local oh=clamp((#(overlay.lines or {})+3)*40*u,190*u,fullH*.65)
local ox,oy=(w-ow)/2,(h-oh)/2
g.setColor(0,0,0,.64);g.rectangle('fill',0,0,w,h)
panel(ox,oy,ow,oh,u)
for i,line in ipairs(overlay.lines or {}) do
text(line,ox+27*u,oy+(19+(i-1)*36)*u,ow-54*u,32*u,22*u)
end
local choice=overlay.kind=='confirm'
and ((overlay.index or 1)==1 and '> YES       NO' or 'YES       > NO')
or 'A  OK'
text(choice,ox+28*u,oy+oh-58*u,ow-56*u,34*u,21*u,
{.95,.56,.40,1},'center')
end
g.setColor(1,1,1,1)
end
function M.install()
if M.installed then return end
local Manager=req('src.mods.ManagerState')
if not (Manager and type(Manager.draw)=='function') then return end
local native=Manager.draw
Manager.draw=function(self,...)
local g=G();local R=req('src.render.Renderer')
local target=g.getCanvas()
if target==R.canvas and not req('src.core.game3.display').planesBroken
and type(R.frameRects)=='function' then
return V.Gen3Screens.present('gen3-mod-manager',
function(w,h) M.draw(self,w,h) end)
end
if target==nil and g.getWidth()>400 and g.getHeight()>300 then
g.push('all');g.origin();g.clear(.025,.038,.044,1)
local ok,err=pcall(M.draw,self,g.getWidth(),g.getHeight())
g.pop()
if not ok then error(err,0) end
return
end
return native(self,...)
end
M.installed=true
end
return M
