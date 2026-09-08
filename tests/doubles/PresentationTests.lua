-- Standalone Lua 5.1+/LuaJIT tests. No ROM, GPU or network needed.
-- CBE_DOUBLES_MOD_DIR=/path/to/cbe CBE_DOUBLES_UI_DIR=/path/to/ui texlua this.lua
local root=os.getenv('CBE_DOUBLES_MOD_DIR') or '.'
local uiRoot=os.getenv('CBE_DOUBLES_UI_DIR') or '../ui'
local n=0
local function eq(tag,a,b)n=n+1;assert(a==b,tag..': '..tostring(a)..' != '..tostring(b))end
local function yes(tag,a)n=n+1;assert(a,tag)end
local function close(tag,a,b)n=n+1;assert(math.abs(a-b)<1e-5,tag..': '..a..' != '..b)end
local function module(path,ns)return assert(loadfile(root..'/'..path))(ns or {})end
-- FOBJ descriptors are big-endian; their scalar streams are little-endian.
local H=module('extract/HSD.lua')._test
local function le16(v)return string.char(v%256,math.floor(v/256)%256)end
local function be32(v)return string.char(math.floor(v/16777216)%256,math.floor(v/65536)%256,math.floor(v/256)%256,v%256)end
local function descriptor(payload,start)
 local starts={[0]='\0\0\0\0',[5]='\64\160\0\0',[-5]='\192\160\0\0'}
 local blob=be32(0)..be32(#payload)..assert(starts[start])..string.char(8,0x40,0x40,0)..be32(24)..be32(0)..payload
 return {blob=blob,ptr=function(_,off)if off==0x10 then return 24 end end}
end
local p=string.char(0x22)..le16(10)..string.char(10)..le16(20)..string.char(10)..le16(30)..string.char(0)
local track,keys=H.decodeFobj(descriptor(p,5),0)
eq('scale track',track,8);eq('negative preroll retained',#keys,3);eq('seek origin',keys[1].frame,-5)
close('preroll interpolation at zero',H.fobjValue(keys,0),15)
close('interior linear interpolation',H.fobjValue(keys,10),25)
close('end sample',H.fobjValue(keys,30),30)
local _,delay=H.decodeFobj(descriptor(p,-5),0)
eq('delayed track does not overwrite bind',H.fobjValue(delay,0),nil)
local _,constant=H.decodeFobj(descriptor(string.char(1)..le16(1)..string.char(0),5),0)
eq('pre-rolled constant scale is one',H.fobjValue(constant,0),1)
local _,zero=H.decodeFobj(descriptor(string.char(1)..le16(0)..string.char(0),5),0)
eq('authored hidden zero scale preserved',H.fobjValue(zero,0),0)
local _,key=H.decodeFobj(descriptor(string.char(0x26)..le16(10)..string.char(5)..le16(20)..string.char(5)..le16(30)..string.char(0),0),0)
eq('KEY waits consumed',#key,3);eq('KEY time 2',key[2].frame,5);eq('KEY time 3',key[3].frame,10)
close('KEY holds first',H.fobjValue(key,2),10);close('KEY holds second',H.fobjValue(key,7),20)
close('KEY at boundary',H.fobjValue(key,5),20);close('KEY final',H.fobjValue(key,15),30)
close('Hermite zero tangents',H.fobjValue({{frame=0,value=0,tan=0,op=4},{frame=10,value=10,tan=0,op=4}},5),5)
eq('empty FOBJ',H.fobjValue({},0),nil)
print('PASS: FOBJ preroll, waits, constant/linear/Hermite/KEY, delayed and zero-scale contracts')
-- Strict eligibility and wall-clock prelude; fake native audio interface only.
local clock,pressed,held,playCount,resumeCount,duckCount,nativeUpdates=0,false,false,0,0,0,0
local source
local Music={}
function Music.duckForFanfare(s)duckCount=duckCount+1;Music.held=s end
function Music.update()if Music.held and not Music.held.playing then resumeCount=resumeCount+1;Music.held=nil end end
local class={update=function()nativeUpdates=nativeUpdates+1 end,bottomUIVisible=function()return true end,statusHUDVisible=function()return true end}
local Runtime={wantsHook=function()return false end}
love={timer={getTime=function()return clock end},filesystem={newFileData=function(bytes)return bytes end},audio={newSource=function()
 source={playing=false,length=2}
 function source:getDuration()return self.length end
 function source:setLooping(v)self.loop=v end
 function source:setPitch(v)self.pitch=v end
 function source:setVolume(v)self.volume=v end
 function source:play()self.playing=true;playCount=playCount+1 end
 function source:stop()self.playing=false end
 function source:release()self.released=true end
 return source
end}}
local V={engineRequire=function(name)
 if name=='src.core.Music' then return Music elseif name=='src.mods.Runtime' then return Runtime else return class end
end,mod={exports={},events={on=function()end}},GenerationCompat={current=function()return 1 end},
 GeneratedAssets={read=function()return 'RIFF\0\0\0\0WAVE'..string.rep('\0',64)end},StandaloneHost={}}
local B=module('lib/BossIntro.lua',V)
local function screen(id,enabled)
 local s={kind='trainer',oppClass=id,phase='messages',trainer={class=id},game={save={options={musicVol=3},colosseumBattle={bossIntroEnabled=enabled,arenasEnabled=true,doubleBattlesEnabled=false}},input={wasPressed=function()return pressed end,isDown=function()return held end}}}
 V.StandaloneHost.session={battle=s,started=true};return s
end
for _,id in ipairs({'BROCK','OPP_MISTY','LT_SURGE','LORELEI','BRUNO','AGATHA','LANCE','WILL','KAREN','CHAMPION','RIVAL1','RIVAL2','RIVAL3','GIOVANNI','FALKNER','JANINE','BLUE','RED'})do
 yes('explicit boss '..id,B.classify(screen(id,true)))
end
for _,id in ipairs({'YOUNGSTER','OPP_ROCKET','GRUNTM','GRUNTF','HIKER','TRAINER_BROCK_FAN','FAKE_RIVAL2','SCHOOLBOY','EXECUTIVE_FAKE'})do
 local s=screen(id,true);s.trainer.party={1,2,3,4,5,6};s.trainer.level=100;s.musicKind='gym';eq('ordinary excluded '..id,B.classify(s),nil)
end
for _,field in ipairs({'wild','link','spectator','tutorial','demo','ghost','contest','inBattleTowerBattle'})do
 local s=screen('BROCK',true);s[field]=true;eq('special excluded '..field,B.classify(s),nil)
end
local s=screen('NONE',true);s.trainer.cbeBossIntro=true;eq('custom boss explicit opt-in',B.classify(s),'story-boss')
s.trainer.cbeBossIntro=false;eq('custom explicit exclusion',B.classify(s),nil)
local g2={battle={trainer={classId='RIVAL2'},wild=false}};eq('Gen II model classification',B.classify(g2),'rival')
local off=screen('BROCK',false);eq('toggle default/off',B.begin(off),nil);off.game.save.colosseumBattle.bossIntroEnabled=true;eq('mid-battle toggle does not inject intro',B.begin(off),nil)
local resumed=screen('BROCK',true);resumed.phase='menu';eq('checkpoint does not replay',B.begin(resumed),nil)
local bad=screen('BROCK',true);local bytes=V.GeneratedAssets.read;V.GeneratedAssets.read=function()return nil end;eq('missing cue fails open',B.begin(bad),nil);V.GeneratedAssets.read=bytes
B.install();s=screen('BROCK',true);class.update(s,4)
yes('starts with doubles OFF',B.active(s));eq('native queue held',nativeUpdates,0);eq('single source plays',playCount,1);eq('native soundtrack ducked',duckCount,1);eq('cue does not pitch at 4x',source.pitch,1);eq('no repeat',source.loop,false);close('music volume respected',source.volume,.7*3/7)
eq('native HUD suppressed',class.bottomUIVisible(s),false)
clock=clock+.05;class.update(s,4);close('wall-time not game dt',B.current.elapsed,.05)
for i=1,5 do class.update(s,4)end;close('repeated fast ticks do not accelerate',B.current.elapsed,.05)
local base={eye={45,28,65},focus={0,5,0},fov=.8}
local context={battle=s,groundY=0,arena={player={-20,0},enemy={20,0},mid={0,0}}}
for _,t in ipairs({0,.4,.7,1,1.4,1.7,1.95})do
 B.current.elapsed=t;local pose=B.camera(base,context)
 for _,a in ipairs({pose.eye,pose.focus})do for _,v in ipairs(a)do yes('finite boss camera',v==v and math.abs(v)<1e7)end end
 yes('boss FOV range',pose.fov>.1 and pose.fov<2)
end
B.current.elapsed=.4;pressed=true;held=true;clock=clock+.05;class.update(s,4)
pressed=false;for i=1,4 do clock=clock+.06;class.update(s,4)end
eq('skip closes cinematic',B.active(s),nil);yes('source released',source.released);eq('soundtrack resumes once',resumeCount,1);eq('skip never runs native queue same frame',nativeUpdates,0)
class.update(s,4);eq('held skip consumed',nativeUpdates,0);held=false;clock=clock+.05;class.update(s,4);eq('native queue resumes',nativeUpdates,1)
class.update(s,4);eq('no restart after menu',playCount,1)
s=screen('RIVAL1',true);class.update(s,1);for i=1,23 do clock=clock+.1;class.update(s,1)end
eq('natural completion releases prelude',B.active(s),nil);eq('normal completion resumes audio',resumeCount,2)
local loopHandle={source='existing canonical loop'}
s=screen('BROCK',true);s.game.data={audio={songs={COLOSSEUM_ENV_LINK1={loopFile=loopHandle}}}}
Music.current=function()return 'COLOSSEUM_ENV_LINK1'end
local selectedBody
Music.play=function(data,song,loop,ctx)selectedBody=song;eq('handoff keeps existing cached loop',data.audio.songs[song].file,loopHandle);eq('handoff loops body',loop,true)end
B.begin(s);B.finish('complete')
eq('independent fanfare preserves selected theme intro',selectedBody,nil)
print('PASS: boss whitelist/exclusions, toggle, cache fail-open, once-only, native hold/handoff, skip and real-time camera')
-- The rendered UI reads an immutable event subject, never a live slot alias.
local Core=module('lib/doubles/Core.lua')
local adapter={name=function(_,m)return m.name end,maxHP=function(_,m)return m.maxHP end,makeBattler=function(_,slot)return {mon=slot.mon,stages={}}end,newStages=function()return {}end,withdraw=function()end}
local function mon(i)return {species='SPECIES_'..i,name='MON '..i,hp=100,maxHP=120,level=30,dvs={attack=i}}end
local c=Core.new{adapter=adapter,id='presentation',playerParty={mon(1),mon(2),mon(3)},enemyParty={mon(4),mon(5),mon(6)}}
local U=assert(loadfile(uiRoot..'/lib/DoublesUI.lua')){mod={}}
local function visible(s)local k=0;for _ in pairs(U.visibility(s))do k=k+1 end;return k end
c.queue={};c.qhead=1;c.currentEvent=nil;c.afterEvents=nil
local outgoing=c.slots['player-left'].battlerId
c:occupy('player-left',3,false)
c:presentNext();local snap=c:snapshot()
eq('recall identifies outgoing',snap.presentation.subject.name,'MON 1');eq('recall has old token',snap.presentation.battlerId,outgoing);eq('recall hides HUD',visible(snap),0)
snap.presentation.subject.portrait.dvs.attack=99;eq('nested event snapshot detached',c.currentEvent.subject.portrait.dvs.attack,1)
c:presentNext();snap=c:snapshot();eq('send identifies incoming',snap.presentation.subject.name,'MON 3');eq('send shows one plate',visible(snap),1)
c.phase='command';eq('command overview four',visible(c:snapshot()),4)
c.phase='replace';eq('forced replacement shows own two',visible(c:snapshot()),2)
c.phase='present';local slot=c.slots['enemy-right'];c.queue={};c.qhead=1;c:enqueue{kind='damage',slot=slot.id,battlerId=slot.battlerId,mon=slot.mon,hp=45,amount=55};c:presentNext();snap=c:snapshot()
eq('health tween starts at visible HP',snap.presentation.previousHP,100);eq('health tween ends at updated HP',snap.presentation.subject.hp,45);eq('damage only one panel',visible(snap),1)
snap.presentation.subject.hp=999;eq('health snapshot cannot mutate event',c.currentEvent.subject.hp,45)
for _,kind in ipairs({'move','message','recall'})do c.currentEvent.kind=kind;eq('cinematic hides overview '..kind,visible(c:snapshot()),0)end
for _,kind in ipairs({'send','heal','faint','status'})do c.currentEvent.kind=kind;eq('subject-only '..kind,visible(c:snapshot()),1)end
c.queue={};c.qhead=1;c:presentNext();eq('no stale previous battle text',c:snapshot().message,'');eq('quiet gap has no health overlays',visible(c:snapshot()),0)
for _,size in ipairs({{360,640},{640,360},{1000,700},{1707,896},{1920,1080},{2560,1440}})do
 for _,page in ipairs({'commands','moves','targets','party'})do
  local l=U.layout(size[1],size[2],page,size[1]<size[2]);local b=l.menu
  yes('menu on screen',b.x>=0 and b.y>=0 and b.x+b.w<=size[1]+.01 and b.y+b.h<=size[2]+.01)
  yes('compact plates do not collide',2*l.totalW+3*l.margin<=size[1]+.01)
  yes('compact plates clear commands',l.margin+2*l.ch+l.gap<b.y)
 end
end
print('PASS: event identity, snapshot isolation, 0/1/2/4 panel visibility, HP tween and six viewport layouts')
local P=module('lib/doubles/Presenter.lua')
context.battle=nil
local session={core={eventTime=.25},actors={}}
for _,id in ipairs(Core.positions)do
 for _,kind in ipairs({'send','damage','heal','faint','move'})do
  session.core.currentEvent={kind=kind,slot=id,targets={'player-left','enemy-left','enemy-right'}}
  local pose=P.camera(base,session,context)
  for _,a in ipairs({pose.eye,pose.focus})do for _,v in ipairs(a)do yes('finite subject/spread camera',v==v and math.abs(v)<1e7)end end
  local x,z=P.anchor(context,id)
  if kind~='move' then close('subject framing x',pose.focus[1],x);close('subject framing z',pose.focus[3],z)end
 end
end
print('PASS: all four position/target-specific camera shots and spread framing')
print('PRESENTATION ASSERTIONS PASSED: '..n)

-- The paired UI submits item requests; it never modifies inventory itself.
do
 local snap={battleId='item-ui',ticket=1,turn=1,phase='command',commandSlot='player-left',battlerId='p1',itemApiVersion=1,limitations={bag=true},slots={},
  items={{id='ETHER',name='ETHER',available=1,moveRequired=true,target='party'}},
  party={{index=2,name='ALLY',hp=5,maxHP=20,active='player-right',moves={{index=1,id='TACKLE',name='TACKLE',pp=0,maxPP=35}}}}}
 local sent;local api={submit=function(r)sent=r;return true end}
 local state=U._test.state(snap);state.index=3;U.input(api,snap,{a=true})
 eq('Bag button opens inventory',state.page,'bag');U.input(api,snap,{a=true});eq('Item opens party targets',state.page,'item-party')
 U.input(api,snap,{a=true});eq('Ether asks move slot',state.page,'item-moves');U.input(api,snap,{a=true})
 eq('UI submits item kind',sent.kind,'item');eq('UI preserves target party identity',sent.partyIndex,2);eq('UI sends PP move index',sent.moveIndex,1)
 eq('UI preserves ticket',sent.ticket,1);eq('UI inventory untouched',snap.items[1].available,1)
end
print('ITEM UI ASSERTIONS TOTAL: '..n)
