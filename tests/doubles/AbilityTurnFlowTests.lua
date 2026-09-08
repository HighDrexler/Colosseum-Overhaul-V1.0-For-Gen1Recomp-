-- Active ability mechanics combined with the preserved live native progression
-- continuation. These are native-screen fixtures with stubbed graphics.
local H=...;local T=H.T;local count=0
local function eq(n,a,b)count=count+1;T.eq('ABILITY TURN FLOW '..n,a,b)end
local function ok(n,v)count=count+1;T.ok('ABILITY TURN FLOW '..n,v)end
local function configure(host,game,save)
 save.colosseumBattle.abilitiesEnabled=true
 for _,p in ipairs({save.party,host.enemyParty})do for _,m in ipairs(p)do m.abilityId='RUN_AWAY'end end
 save.party[1].abilityId='SPEED_BOOST';host.enemyParty[1].abilityId='PRESSURE';host.enemyParty[2].abilityId='PRESSURE';host.enemyParty[3].abilityId='INTIMIDATE'
end
for _,gen in ipairs{1,2}do
 local p='Gen'..gen..' '
 local s,c,h,g,save=H.start(gen,4,configure);local l=c.slots['player-left'];local r=c.slots['player-right'];local e=c.slots['enemy-left']
 e.mon.hp=1;c.slots['enemy-right'].mon.hp=1000
 local pp1=l.mon.moves[1].pp;local pp2=r.mon.moves[1].pp
 c.actionQueue={H.action(c,l.id,e.id),H.action(c,r.id,e.id)};c.actionIndex=1
 c:performNext();H.drainVisual(s)
 eq(p..'KO pauses for native rewards with abilities ON',s.progressing,true)
 eq(p..'Pressure spent exactly one extra PP at KO',l.mon.moves[1].pp,pp1-2)
 eq(p..'partner PP frozen in native progression',r.mon.moves[1].pp,pp2)
 eq(p..'reserve Intimidate not active midturn',l.stages.attack or 0,0)
 eq(p..'Speed Boost not a progression residual',l.stages.speed or 0,0)
 H.drainProgress(s)
 eq(p..'same queued continuation restored',c.actionIndex,2)
 eq(p..'KO award exactly once',s.rewardsCompleted,1)
 eq(p..'native reward screen did not repeat Pressure',l.mon.moves[1].pp,pp1-2)
 c:performNext();H.drainVisual(s)
 eq(p..'retargeted surviving Pressure charges once',r.mon.moves[1].pp,pp2-2)
 eq(p..'reserve not present for either committed attack',c.slots['enemy-left'].partyIndex,1)
 H.settleTurn(s)
 eq(p..'reserve enters at after-residual boundary',c.slots['enemy-left'].partyIndex,3)
 eq(p..'reserve Intimidate affects first ally',l.stages.attack,-1)
 eq(p..'reserve Intimidate affects second ally',r.stages.attack,-1)
 eq(p..'Speed Boost once across KO UI and replacement',l.stages.speed,1)
 eq(p..'next legitimate command phase',c.phase,'command')
 eq(p..'no native reward replay during entry',s.rewardsCompleted,1)
 H.close(s)
end
-- Keep a real native charge lock through an ability-enabled final KO/progression;
-- no attempt may escape into a native singles takeTurn.
do
 local s,c,h=H.start(2,3,configure);local left=c.slots['player-left'];left.mon.moves={{id='SOLARBEAM',pp=10}}
 c.adapter:perform(left,{c.slots['enemy-left']},{moveId='SOLARBEAM',moveIndex=1})
 eq('Gen2 charge Pressure cost once',left.mon.moves[1].pp,8)
 eq('Gen2 actual charge remains locked',left.mon.volatile.chargeMove,'SOLARBEAM')
 local original=h.takeTurn;local calls=0;h.takeTurn=function(...)calls=calls+1;return original(...)end
 for _,m in ipairs(c.enemyParty)do m.hp=0 end
 c.defeated[#c.defeated+1]={mon=c.enemyParty[3],battler={},participants={[1]=true,[2]=true},partyIndex=3,rewardState='pending'}
 c:noteFaints();c.phase='present';c.afterEvents='finished';H.drainVisual(s);H.drainProgress(s);H.finish(s)
 eq('Gen2 ON final handoff no native singles attack',calls,0)
 eq('Gen2 ON final all rewards once',s.rewardsCompleted,3)
 ok('Gen2 ON session closes',s.closed)
 eq('Gen2 ON native win preserved',h.outcome,'win')
end
print('ABILITY TURN FLOW: '..count..' assertions PASS')
