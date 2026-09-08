local function up(fn,name,value,set)
 for i=1,100 do local n,v=debug.getupvalue(fn,i);if not n then break end;if n==name then if set then debug.setupvalue(fn,i,value) end;return v end end
 error('missing '..name)
end
local A=assert(loadfile('lib/TrainerPerformance.lua'))({})
local sides={payload=function(ctx,p,fields)for _,k in ipairs(fields)do if p[k]=='player' or p[k]=='enemy' then return p[k] end end end,other=function(s)return s=='player' and 'enemy' or 'player' end}
for _,row in ipairs({{'PlayerTrainer.lua','player'},{'Trainer.lua','enemy'}}) do
 local actor=assert(loadfile('lib/'..row[1]))({TrainerRig=assert(loadfile("lib/TrainerRig.lua"))(),TrainerPerformance=A,BattleSides=sides,TrainerMorph={dense=function()return false end}})
 local trigger=up(actor.event,'trigger')
 if row[2]=='enemy' then up(actor.event,'activeNow',true,true) end
 local ctx={battle={player={mon={stats={hp=100}}},enemy={mon={stats={hp=100}}}}}
 up(trigger,'actionKind',nil,true)
 actor:event(ctx,'battle.damage_dealt',{targetSide=row[2],damage=1})
 assert(up(trigger,'actionKind')=='brace','chip hit not routed to '..row[2])
 up(trigger,'actionKind','throw',true);up(trigger,'actionAge',.2,true)
 actor:event(ctx,'battle.damage_dealt',{targetSide=row[2],damage=40})
 assert(up(trigger,'actionKind')=='throw','hit interrupts release')
 assert(up(trigger,'pendingReaction').kind=='concern','blocked hit was discarded')
 actor:event(ctx,'battle.ended',{result=row[2]=='player' and 'loss' or 'win'})
 assert(up(trigger,'actionKind')=='defeat','final loss not routed')
 assert(up(trigger,'pendingReaction')==nil,'stale hit retained after result')
 trigger('frustration',1)
 assert(up(trigger,'actionKind')=='defeat','delayed faint replaced defeat')
end
print('Player/enemy reaction event routing tests passed')

