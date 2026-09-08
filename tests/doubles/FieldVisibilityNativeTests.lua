local T=...;local eq,ok=T.eq,T.ok
for _,gen in ipairs{1,2}do for _,id in ipairs{'DIG','FLY'}do for _,side in ipairs{'player','enemy'}do
 local data=gen==1 and T.Data or T.f.data
 local old=data.moves[id]
 data.moves[id]={id=id,index=id=='DIG' and 91 or 19,name=id,power=60,type=id=='DIG' and 'GROUND' or 'FLYING',accuracy=100,pp=10,effect=gen==1 and 'FLY_EFFECT' or 'EFFECT_FLY'}
 local c
 if gen==2 then c=T.g2(3,3,id)else
  local host,game,save=T.g1(3)
  c=T.Core.new{adapter=T.A.new(host,1),id='field-'..id..side,generation=1,playerParty=save.party,enemyParty=host.enemyParty,playerIndex=1,enemyIndex=1,rng=T.rand}
 end
 local src=c.slots[side..'-right'];local dst=c.slots[(side=='player' and 'enemy' or 'player')..'-left'];local partner=c.slots[side..'-left']
 c.queue={};c.qhead=1
 src.mon.moves={{id=id,pp=10}};if gen==1 then src.battler.curMoves=src.mon.moves end
 dst.mon.hp=10000
 local before=c:captureVitals();local hp=dst.mon.hp
 local e=c.adapter:perform(src,{dst},{moveId=id,moveIndex=1});ok('native charge event '..gen..id..side,e)
 c:recordVitals(before,e)
 eq('native charge stage '..gen..id..side,e.stage,'charge')
 eq('actual native semantic hide '..gen..id..side,c.adapter:structuralHidden(src),true)
 eq('charge before snapshot '..gen..id..side,e.structuralHiddenBefore,false)
 eq('charge after snapshot '..gen..id..side,e.structuralHiddenAfter,true)
 eq('charge never hides partner '..gen..id..side,c.adapter:structuralHidden(partner),false)
 eq('charge does not hit '..gen..id..side,dst.mon.hp,hp)
 local count=0;for _,v in ipairs(c.queue)do if v.kind=='visibility' and v.battlerId==src.battlerId then count=count+1;eq('hide token '..gen..id..side,v.hidden,true)end end
 eq('single hide transition '..gen..id..side,count,1)
 local pp=src.mon.moves[1].pp;before=c:captureVitals()
 e=c.adapter:perform(src,{dst},{moveId=id,moveIndex=1});c:recordVitals(before,e)
 eq('native release flag '..gen..id..side,e.release,true)
 eq('native release visible '..gen..id..side,c.adapter:structuralHidden(src),false)
 eq('release before snapshot '..gen..id..side,e.structuralHiddenBefore,true)
 eq('release after snapshot '..gen..id..side,e.structuralHiddenAfter,false)
 eq('no second charge PP '..gen..id..side,src.mon.moves[1].pp,pp)
 -- A cancelled charge with no move event still queues visibility restoration.
 if gen==1 then src.battler.invulnerable=true;src.battler.charging={id=id}
 else src.mon.volatile.vanished=true;src.mon.volatile.chargeMove=id end
 before=c:captureVitals()
 if gen==1 then c.adapter.k:clearVolatiles(src.battler,true)
 else src.mon.volatile.vanished=nil;src.mon.volatile.chargeMove=nil end
 local qn=#c.queue;c:recordVitals(before)
 eq('no-move cancellation restored '..gen..id..side,c.queue[qn+1].kind,'visibility')
 eq('cancellation shows actor '..gen..id..side,c.queue[qn+1].hidden,false)
 data.moves[id]=old
end end end
print('NATIVE: Dig/Fly charge/release/cancellation visibility, both generations and sides PASS')
