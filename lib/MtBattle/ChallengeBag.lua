











local CB={}
local function quantity(v)
if v==nil then return 1 end
v=tonumber(v)
if not v or v~=v or v==math.huge or v<1 or v~=math.floor(v) then return nil end
return v
end

function CB.remaining(game,SaveState,itemId)
local s=SaveState.state(game)
return s.bag[itemId] or 0
end

function CB.has(game,SaveState,itemId,qty)
qty=quantity(qty)
return qty~=nil and CB.remaining(game,SaveState,itemId)>=qty
end




function CB.consume(game,SaveState,itemId,qty)
qty=quantity(qty)
if not qty then return false end
local s=SaveState.state(game)
local have=s.bag[itemId] or 0
if have<qty then return false end
s.bag[itemId]=have-qty
return true
end





function CB.resetToDefault(game,SaveState,overrides,totalFights)
local s=SaveState.state(game)
local base=overrides or SaveState.DEFAULT_BAG
totalFights=totalFights or s.totalFights
local fresh
if type(SaveState.scaledBagForTotalFights)=="function" then
fresh=SaveState.scaledBagForTotalFights(totalFights,base)
else
fresh={};for id,qty in pairs(base) do fresh[id]=qty end
end
s.bag=fresh
s.bagInitial={};for id,qty in pairs(fresh) do s.bagInitial[id]=qty end
s.bagSnapshot=SaveState.snapshotBag(game)
return s.bag
end



function CB.snapshot(game,SaveState) return SaveState.snapshotBag(game) end
function CB.restore(game,SaveState) return SaveState.restoreBag(game) end








function CB.totalConsumed(game,SaveState)
local s=SaveState.state(game)



local base=type(s.bagInitial)=="table" and s.bagInitial or SaveState.DEFAULT_BAG
local used=0
for id,startQty in pairs(base) do
used=used+math.max(0,startQty-(s.bag[id] or 0))
end
return used
end


local function refreshTeamRow(row)
local maxHp=math.max(1,math.floor(tonumber(row and row.maxHp) or 1))
row.hp=math.max(0,math.min(maxHp,math.floor(tonumber(row.hp) or 0)))
row.maxHp=maxHp;row.fainted=row.hp<=0
row.hpPercent=math.max(0,math.min(100,math.floor((row.hp/maxHp)*100+.5)))
end





function CB.useIntermissionItem(game,SaveState,itemId,partyIndex,moveIndex)
if type(SaveState.repairTeamPP)=="function" then SaveState.repairTeamPP(game) end
local s=SaveState.state(game)
local row=type(s.lastTeamStatus)=="table" and s.lastTeamStatus[math.floor(tonumber(partyIndex) or 0)] or nil
if type(row)~="table" then return false,"NO POKEMON" end
itemId=tostring(itemId or "")
if not CB.has(game,SaveState,itemId,1) then return false,"NONE LEFT" end
refreshTeamRow(row)
local effect=false
if itemId=="FULL_RESTORE" then
if row.fainted then return false,"FAINTED - USE REVIVE" end
effect=row.hp<row.maxHp or (row.status~=nil and row.status~="")
if effect then row.hp=row.maxHp;row.status=nil end
elseif itemId=="HYPER_POTION" then
if row.fainted then return false,"FAINTED - USE REVIVE" end
effect=row.hp<row.maxHp
if effect then row.hp=math.min(row.maxHp,row.hp+200) end
elseif itemId=="REVIVE" then
effect=row.fainted
if effect then row.hp=math.max(1,math.floor(row.maxHp/2)) end
elseif itemId=="FULL_HEAL" then
if row.fainted then return false,"FAINTED" end
effect=row.status~=nil and row.status~=""
if effect then row.status=nil end
elseif itemId=="ETHER" then
local moves=type(row.moves)=="table" and row.moves or {}
local mv=moves[math.floor(tonumber(moveIndex) or 0)]
if type(mv)~="table" then return false,"CHOOSE A MOVE" end
local maxPp=math.max(0,math.floor(tonumber(mv.maxPp) or tonumber(mv.pp) or 0))
local pp=math.max(0,math.floor(tonumber(mv.pp) or 0))
effect=pp<maxPp
if effect then mv.pp=math.min(maxPp,pp+10) end
elseif itemId=="ELIXER" then
for _,mv in ipairs(type(row.moves)=="table" and row.moves or {}) do
local maxPp=math.max(0,math.floor(tonumber(mv.maxPp) or tonumber(mv.pp) or 0))
local pp=math.max(0,math.floor(tonumber(mv.pp) or 0))
if pp<maxPp then mv.pp=math.min(maxPp,pp+10);effect=true end
end
else return false,"ITEM NOT USABLE HERE" end
if not effect then return false,"NO EFFECT" end
if not CB.consume(game,SaveState,itemId,1) then return false,"NONE LEFT" end
refreshTeamRow(row)
return true,"USED "..itemId
end
return CB
