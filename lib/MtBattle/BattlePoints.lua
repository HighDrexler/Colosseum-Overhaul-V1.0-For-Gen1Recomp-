



local V=... or {}
local S=V.MtBattleSaveState
local BP={}
BP.POLICY_VERSION=2
BP.WIN_BP=0
BP.CLEAN_WIN_BP=1
BP.MAX_BALANCE=999999999
BP.MAX_ITEM_STOCK=99


BP.CATALOG={
{id="FULL_HEAL",name="FULL HEAL",cost=2},
{id="HYPER_POTION",name="HYPER POTION",cost=3},
{id="ETHER",name="ETHER",cost=3},
{id="REVIVE",name="REVIVE",cost=5},
{id="FULL_RESTORE",name="FULL RESTORE",cost=5},
{id="ELIXER",name="ELIXER",cost=8},
}
local function integer(v,fallback,max)
v=tonumber(v)
if not v or v~=v or v==math.huge or v==-math.huge or v<0 then return fallback or 0 end
return math.min(max or BP.MAX_BALANCE,math.floor(v))
end
local function copy(v)
if type(v)~="table" then return v end
local out={};for k,x in pairs(v) do out[k]=copy(x) end;return out
end
local function defaults()
return {version=1,balance=0,lifetimeEarned=0,lifetimeSpent=0,runSequence=0,spendSequence=0,receipts={}}
end
function BP.state(game)
if not (type(game)=="table" and type(game.save)=="table") then return defaults() end
local w=game.save.mtBattleBP
if type(w)~="table" then w=defaults();game.save.mtBattleBP=w end
w.version=1
for _,key in ipairs({"balance","lifetimeEarned","lifetimeSpent","runSequence","spendSequence"}) do
w[key]=integer(w[key],0)
end
if type(w.receipts)~="table" then w.receipts={} end
for i=#w.receipts,1,-1 do
local row=w.receipts[i]
if type(row)~="table" or (row.kind~="win" and row.kind~="purchase") then
table.remove(w.receipts,i)
end
end
while #w.receipts>64 do table.remove(w.receipts,1) end
return w
end
local function append(w,row)
w.receipts[#w.receipts+1]=copy(row)
if #w.receipts>64 then table.remove(w.receipts,1) end
end
function BP.ensureRun(game,run)
run=run or S.state(game)
if not (game and game.save and run.active==true) then return nil,"run is not active" end
local w=BP.state(game)
if type(run.bpRunId)~="string" or run.bpRunId=="" then
w.runSequence=integer(w.runSequence,0)+1
run.bpRunId="BP-RUN-"..tostring(w.runSequence)


run.bpAwardedThrough=math.max(integer(run.fightsWon),integer(run.currentFight,1)-1)
run.bpEarned=0;run.bpSpent=0;run.lastBPAward=nil
end
run.bpAwardedThrough=integer(run.bpAwardedThrough)
run.bpEarned=integer(run.bpEarned);run.bpSpent=integer(run.bpSpent)
return run.bpRunId
end
function BP.bindBattle(game,battle,encounter)
local run=S.state(game);local id,why=BP.ensureRun(game,run)
if not id then return false,why end
battle.__cbeMtBattleBPOwnerSave=game.save
battle.__cbeMtBattleBPRunId=id
battle.__cbeMtBattleBPAttempt=integer((run.attemptsByFight or {})[run.currentFight])+1
battle.cbeMtBattleNumber=(encounter and encounter.fightIndex) or run.currentFight
return true
end


function BP.cleanWin(battle,team)
if type(battle)~="table" then return false,"KO history unavailable" end
local native=type(battle._model)=="table" and battle._model or battle
if battle.__cbeMtBattleKOTracking~=true and native.__cbeMtBattleKOTracking~=true then
return false,"KO history unavailable"
end
for _,owner in ipairs({battle,native}) do
local ledger=owner.__cbeMtBattlePlayerKnockouts


if (owner.__cbeMtBattleKOTracking==true or ledger~=nil) and type(ledger)~="table" then
return false,"KO history unavailable"
end
if type(ledger)=="table" and next(ledger)~=nil then
return false,"team fainted during battle"
end
end
if type(team)~="table" or #team~=6 then return false,"incomplete team status" end
for i=1,6 do
local row=team[i];local hp=type(row)=="table" and tonumber(row.hp)
if not hp or hp~=hp or hp==math.huge or hp<=0 or row.fainted==true then return false,"team has a fainted Pokemon" end
end
return true,"no Pokemon fainted"
end



function BP.recordWin(game,run,fight,evidence)
local id,why=BP.ensureRun(game,run);if not id then return false,why end
fight=integer(fight)
if fight<1 or fight>integer(run.totalFights,100) or fight~=run.currentFight then return false,"fight mismatch" end
if fight<=run.bpAwardedThrough then return false,"already awarded" end
if type(run.currentEncounter)~="table" or run.currentEncounter.fightIndex~=fight then return false,"encounter mismatch" end
local w=BP.state(game)
local clean=type(evidence)=="table" and evidence.clean==true
local amount=clean and math.min(integer(BP.CLEAN_WIN_BP),BP.MAX_BALANCE-w.balance) or 0



local row={kind="win",runId=id,fight=fight,totalFights=run.totalFights,
base=0,bonus=0,noFaintReward=amount,amount=amount,clean=clean,
reason=(type(evidence)=="table" and evidence.reason) or "KO history unavailable",policy=BP.POLICY_VERSION,
balanceAfter=w.balance+amount}
w.balance=row.balanceAfter;w.lifetimeEarned=integer(w.lifetimeEarned+amount)
run.bpEarned=integer(run.bpEarned+amount);run.bpAwardedThrough=fight
run.lastBPAward=copy(row);append(w,row)
return row
end
function BP.summary(game)
local w=BP.state(game);local run=S and S.state(game) or {}
return {balance=w.balance,lifetimeEarned=w.lifetimeEarned,lifetimeSpent=w.lifetimeSpent,
runEarned=integer(run.bpEarned),runSpent=integer(run.bpSpent),lastAward=copy(run.lastBPAward),
receipts=copy(w.receipts),winBP=BP.WIN_BP,cleanWinBP=BP.CLEAN_WIN_BP}
end
function BP.canExchange(game)
local run=S.state(game);local p=run.pendingIntermission
return run.active==true and type(p)=="table" and (p.kind=="between" or p.kind=="areaBreak")
and run.currentEncounter==nil and run.awaitingFinale~=true
end
function BP.purchaseToken(game)
if not BP.canExchange(game) then return nil,"exchange opens between victories" end
local run=S.state(game);local id,why=BP.ensureRun(game,run)
if not id then return nil,why end
return {runId=id,fight=run.currentFight,sequence=BP.state(game).spendSequence+1}
end
function BP.purchase(game,itemId,token)
if not BP.canExchange(game) then return false,"EXCHANGE OPENS BETWEEN VICTORIES" end
local run=S.state(game);local w=BP.state(game)
if type(token)~="table" or token.runId~=run.bpRunId or token.fight~=run.currentFight
or token.sequence~=w.spendSequence+1 then return false,"PURCHASE EXPIRED OR ALREADY PROCESSED" end
local item
for _,row in ipairs(BP.CATALOG) do if row.id==itemId then item=row;break end end
if not item then return false,"UNKNOWN BP REWARD" end
local price=integer(item.cost)
if price<1 or w.balance<price then return false,"NOT ENOUGH BP" end
local have=integer(run.bag[itemId])
if have>=BP.MAX_ITEM_STOCK then return false,"CHALLENGE BAG STOCK FULL" end
if type(game.writeSave)~="function" then return false,"SAVE UNAVAILABLE - NOTHING SPENT" end


local owner=game.save;local beforeWallet=owner.mtBattleBP
local beforeBag,beforeInitial,beforeSpent=run.bag,run.bagInitial,run.bpSpent
local nextWallet=copy(w);local bag=copy(run.bag);local initial=copy(run.bagInitial or {})
nextWallet.balance=nextWallet.balance-price
nextWallet.lifetimeSpent=integer(nextWallet.lifetimeSpent+price)
nextWallet.spendSequence=token.sequence
bag[itemId]=have+1;initial[itemId]=integer(initial[itemId])+1
local receipt={kind="purchase",runId=run.bpRunId,fight=run.currentFight,item=itemId,
quantity=1,amount=price,sequence=token.sequence,balanceAfter=nextWallet.balance}
append(nextWallet,receipt)
owner.mtBattleBP=nextWallet;run.bag=bag;run.bagInitial=initial;run.bpSpent=integer(run.bpSpent)+price
local called,written=pcall(game.writeSave,game)
if not called or written==false or game.save~=owner then
owner.mtBattleBP=beforeWallet;run.bag=beforeBag;run.bagInitial=beforeInitial;run.bpSpent=beforeSpent
return false,"SAVE FAILED - NOTHING SPENT"
end
return true,"BOUGHT "..item.name.." - "..tostring(price).." BP",receipt
end
BP._test={integer=integer,copy=copy}
return BP
