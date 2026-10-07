local V=...
local req=V.engineRequire or require
local M={}
local function pokemon()return req('src.core.game3.pokemon')end
function M.owned(mon)
local session=V.Gen3Runtime.session(V.mod.game)
for _,m in ipairs(session and session.party or {}) do if m==mon then return true end end
for _,box in ipairs(session and session.storage and session.storage.boxes or {}) do
for _,m in pairs(box.mons or {}) do if m==mon then return true end end
end
return false
end
function M.canRemember(mon)
return mon and not pokemon().isEgg(mon) and M.owned(mon)
and not req('src.core.game3.battle').isActive()
and not (V.Gen3Challenge and V.Gen3Challenge.liveSession)
end
function M.canManageSummary(N)
local mon=N._party and N._party[N._cursor]
return N.open and (N._page==2 or N._page==3) and not N._swapSlot
and not N._enemyParty and (N._mode==nil or N._mode=='party')
and N._context~='factory' and M.canRemember(mon)
end
function M.openSummary(N)
if not M.canManageSummary(N) then return false end


V.Gen3UI.prep(N._party[N._cursor],false,function()V.Gen3UI.close()end)
return true
end
function M.record(mon)
local d=V.Gen3Runtime.data();if not d or not mon then return {} end
d.moveMemory=d.moveMemory or {}
local key=tostring(mon.personality or 0)..':'..tostring(mon.otId or mon.trainerId or 0)


local r=d.moveMemory[key];if not r then r={moves={}};d.moveMemory[key]=r end
for i=1,4 do local id=pokemon().moveIdAt(mon,i);if id and id>0 then r.moves[tostring(id)]=true end end
return r
end
function M.pool(mon)
local P=pokemon();local r=M.record(mon);local ids,seen={},{}
local function add(id)
id=tonumber(id);if id and id>0 and P.battleMove(id) and not seen[id] then seen[id]=true;ids[#ids+1]=id end
end
local visited={}
local function lineage(species)
if not species or visited[species] then return end;visited[species]=true
for _,row in ipairs(P.learnset(species) or {}) do
if (row.level or row[1] or 1)<=(mon.level or 1) then add(row.move or row.moveId or row[2]) end
end
for dex=1,386 do local ancestor=P.speciesFromNational(dex)
for _,e in ipairs(P.evolutions(ancestor) or {}) do
if tonumber(e.target or e[3])==species then lineage(ancestor) end
end
end
end
if not P.isEgg(mon) then lineage(P.speciesOf(mon)) end
for id in pairs(r.moves or {}) do add(id) end
table.sort(ids,function(a,b)return P.moveName(a)<P.moveName(b) end)
return ids
end
function M.install()
if M.installed then return end
local P=pokemon();local replace=P.replaceMove
P.replaceMove=function(mon,slot,id)
local owned=M.owned(mon) and not (V.Gen3Challenge and V.Gen3Challenge.liveSession)
if owned then M.record(mon) end
local old,why=replace(mon,slot,id)
if not why and owned then M.record(mon) end
return old,why
end
local N=req('src.ui.game3.party_menu');local input=N.handleInput
N.handleInput=function(inp,...)
local mon=N._party and N._party[N.cursor]
local allowed=M.canRemember(mon) and not N._onSelect
if allowed and N.mode=='action' and N.ACTIONS[N.actionCursor]=='REMEMBER MOVES' and inp:wasPressed('a') then
V.Gen3UI.prep(mon,false,function()V.Gen3UI.close()end);return
end
local result=input(inp,...)
if allowed and N.mode=='action' then
local found=false;for _,label in ipairs(N.ACTIONS) do if label=='REMEMBER MOVES' then found=true end end
if not found then table.insert(N.ACTIONS,math.max(1,#N.ACTIONS),'REMEMBER MOVES') end
end
return result
end
M.installed=true
end
return M
