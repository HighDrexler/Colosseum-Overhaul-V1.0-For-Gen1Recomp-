

local V=...
local req=V.engineRequire or require
local E={installed=false,gen3Installed=false}
local awardShares
local function eligible(mon)
return type(mon)=='table' and (tonumber(mon.hp) or 0)>0
and not mon.isEgg and not mon.egg and (tonumber(mon.level) or 1)<100
end
local function protected(b)
return b and (b.link or b.linkBattle or b.spectate or b.battleTower or b.trainerTower
or b.cbeMtBattleLevelLock or b.cbeMtBattleChallenge or b.cbeMtBattleNumber)
end
function E.enabled(game)
local p=V.Gen3Runtime and V.Gen3Runtime.prefs(game) or V.BattleSettings.prefs(game or V.mod.game)
return p.expShareEnabled==true
end
function E.install(mod)
if E.installed then return true end
if not (mod and mod.hooks and mod.hooks.wrap) then return false end
mod.hooks:wrap('exp.gain',function(next,ctx,...)
local amount=next(ctx,...)
local share=awardShares and ctx and awardShares[ctx.mon]
if share then return math.max(0,math.floor((tonumber(amount) or 0)*share)) end
return amount
end,100,'colosseum-exp-share-amount')
mod.hooks:wrap('battle.exp_award',function(proceed,ctx,...)
local b=ctx and ctx.battle
if not b or protected(b) or not E.enabled(b.game or mod.game) then return proceed(ctx,...) end
local party=b.party or (b.playerPartyView and b:playerPartyView()) or {}
local fought,shares={},{}
for _,m in ipairs(ctx.alive or {}) do fought[m]=true end

if not next(fought) then return proceed(ctx,...) end
for _,m in ipairs(party) do if eligible(m) then shares[m]=fought[m] and 1 or .5 end end
local previous=awardShares;awardShares=shares
local ok,err=pcall(function()
for index,mon in ipairs(party) do if shares[mon] then
if b.giveExperiencePass then


b:giveExperiencePass(ctx.loser,b:speciesDef(ctx.loser),{index},1,false,false)
else ctx.applyShare(mon,1,true) end
end end
end)
awardShares=previous
if not ok then error(err,0) end
end,100,'colosseum-exp-share-distribution')
E.installed=true;return true
end



function E.installGen3()
if E.gen3Installed then return true end
local XP=req('src.core.game3.battle.experience')
local P=req('src.core.game3.pokemon');local Runtime=req('src.mods.Runtime')
local original=XP.awardFoe
XP.awardFoe=function(st,foe,opts)
if not st or not foe or protected(st) or not E.enabled(V.mod.game) then return original(st,foe,opts) end
opts=opts or {}
local sent={}
if opts.partyIndices then for _,i in ipairs(opts.partyIndices) do sent[i]=true end
elseif foe.participants and next(foe.participants) then for i in pairs(foe.participants) do sent[i]=true end
elseif st.player and st.player.mon and (tonumber(st.player.mon.hp) or 0)>0 and not P.isEgg(st.player.mon) then
sent[st.player.partyIndex or 1]=true
end
local party=st.playerParty or {};local hasParticipant=false
for i,m in ipairs(party) do
if sent[i] and (tonumber(m.hp) or 0)>0 and not P.isEgg(m) then hasParticipant=true end
end
if not hasParticipant then return original(st,foe,opts) end
local species=foe.species or (foe.mon and (foe.mon.species or foe.mon.speciesId))
local level=foe.mon and foe.mon.level or foe.level or 1
local trainer=opts.trainer;if trainer==nil then trainer=not st.wild end
local b0=st.player;local b2=st.double and st.battlers and st.battlers[2]
local absent=st.absent or {};local out={}
local friendship={mapSec=P.currentMapSec(st.session)}
for pi=1,6 do
local mon=party[pi]
if eligible(mon) and not P.isEgg(mon) and P.speciesOf(mon)~=0 then
local per=opts.getOpts and opts.getOpts(mon,pi) or XP.recipientOpts(st,mon)
local ratio=sent[pi] and 1 or .5
local function amountFor()
return math.floor(XP.gainFor(species,level,{participants=1,trainer=trainer,
traded=per.traded,luckyEgg=per.luckyEgg})*ratio)
end
local amount
if Runtime.wantsHook('exp.gain') then
amount=Runtime.call('exp.gain',amountFor,{
defeatedDef=req('src.mods.Gen3Compat').speciesView(species),level=level,isTrainer=trainer,
participants=1,traded=per.traded,luckyEgg=per.luckyEgg,expShare=ratio==.5,
mon=mon,index=pi,battle=st,loser=foe,cbeExpShareRatio=ratio})
else amount=amountFor() end
amount=math.max(0,math.floor(tonumber(amount) or 0))
P.gainEVs(mon,species)
local result=XP.apply(mon,amount)
for _=1,#result.levels do P.adjustFriendship(mon,P.FRIENDSHIP_EVENT_GROW_LEVEL,friendship) end
local fieldB
if b0 and b0.partyIndex==pi and not absent[0] then fieldB=b0
elseif b2 and b2.partyIndex==pi and not absent[2] then fieldB=b2 end
if fieldB then fieldB.mon=mon;fieldB.fainted=(tonumber(mon.hp) or 0)<=0 end
local getter=st.double and ((b2 and b2.partyIndex==pi and not absent[2] or absent[0]) and 2 or 0) or 0
if Runtime.wants('battle.exp_gained') then Runtime.emit('battle.exp_gained',{
battle=st,mon=mon,gained=result.gained,levels=result.levels,index=pi,battler=fieldB,battlerId=getter}) end
out[#out+1]={mon=mon,partyIndex=pi,battler=fieldB,expGetterBattlerId=getter,
amount=amount,boosted=per.traded and true or false,result=result}
end
end
return out
end
E.gen3Installed=true;return true
end
return E
