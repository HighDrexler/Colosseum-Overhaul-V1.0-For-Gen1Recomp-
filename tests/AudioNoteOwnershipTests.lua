-- ROM-free graph and mixer regressions. MIDI identity is not sample pitch.
local root=os.getenv('CBE_DOUBLES_MOD_DIR') or '.'
local P=assert(loadfile(root..'/extract/PortableMusyX.lua'))();local T=P._test
local checks=0
local function yes(x,m)checks=checks+1;assert(x,m)end
local function near(a,b,m)yes(math.abs(a-b)<1e-8,m..': '..tostring(a)..' / '..tostring(b))end
local function macro(id,key)
 return {id=id,sampleId=id,sampleOffset=0,pitchOps=key and {{kind='set',key=key}} or {},adsr={attack=0,decay=0,sustain=1,release=.2}}
end
local pool={macros={},compiled={[1]=macro(1),[2]=macro(2),[3]=macro(3,60),[4]=macro(4,60)},tables={},
 layers={[32769]={{obj=1,volume=127,pan=64,keyLo=0,keyHi=127,transpose=0},{obj=2,volume=127,pan=64,keyLo=0,keyHi=127,transpose=0}}},keymaps={}}
for i=0,127 do pool.keymaps[16385]=pool.keymaps[16385] or {};pool.keymaps[16385][i]={obj=i==36 and 3 or 4,pan=64,transpose=0}end
local channels={};for ch=0,15 do channels[ch]={program=0,volume=100,pan=64,reverb=0}end
local project={setups={[1]=channels},normal={[0]={obj=32769}},drum={[0]={obj=16385}}}
local sdir={_raw=''};for i=1,4 do sdir[i]={id=i,rate=1000,pitch=60}end
local song={events={{kind='note',ch=0,tick=0,key=60,velocity=100,length=2000},
 {kind='note',ch=9,tick=0,key=36,velocity=100,length=2000},{kind='note',ch=9,tick=0,key=38,velocity=100,length=2000},
 {kind='note',ch=0,tick=384,key=60,velocity=100,length=960}},tempos={{tick=0,tempo=120}},initialTempo=120}
local voices=T.noteVoices(project,pool,sdir,song,1,1000)
yes(#voices==6,'two instrument layers for each note, two separate drums')
local groups={};for _,v in ipairs(voices)do groups[v.noteEventId]=groups[v.noteEventId] or {};table.insert(groups[v.noteEventId],v)end
yes(#groups[1]==2 and #groups[4]==2,'siblings retain one owner')
for _,v in ipairs(groups[1])do near(v.retriggerKeyoff,.5,'only the next MIDI event releases the old graph')end
for _,v in ipairs(groups[4])do yes(v.retriggerKeyoff==nil,'new siblings do not cut each other off')end
yes(groups[2][1].key==60 and groups[3][1].key==60,'different drums intentionally share sample pitch')
yes(groups[2][1].midiKey~=groups[3][1].midiKey,'original drum keys preserved')
yes(groups[2][1].retriggerKeyoff==nil and groups[3][1].retriggerKeyoff==nil,'drums do not mutually retrigger')
-- A delayed sample still belongs to its original note-on, not its arrival time.
pool.compiled[2].preStartWait={{msSwitch=true,value=700}}
local delayed=T.noteVoices(project,pool,sdir,song,1,1000)
for _,v in ipairs(delayed)do if v.noteEventId==1 and v.sampleId==2 then near(v.retriggerKeyoff,0,'retrigger before delayed attack is already pending')end end
-- Choke sample must not depend on where 512-sample blocks happen to begin.
local function render(block,kind,nominal,retrigger,pedal)
 local pcm
 if T.ffi then pcm=T.ffi.new('int16_t[?]',100);for i=0,99 do pcm[i]=1200 end
 else pcm=string.rep(string.char(176,4),100)end
 local cache={[1]={pcm=pcm,count=100,looped=true,loopStart=0,loopEnd=100}}
 local function v(frame,group)
  return {startSec=frame/1000,startFrame=frame,sampleId=1,sampleOffset=0,baseStep=1,
   key=60,channel=0,velocity=100,userVol=.7,targetUserVol=.7,userSlewStep=.2,
   pan=64,ctrl={[64]=pedal and 127 or 0},automation=pedal and {{sec=.35,ctrl=64,value=0}} or {},autoIndex=1,
   reverbGain=0,keygroup=group and {group=1,killNow=true} or nil,
   adsr={},adsrA=0,adsrD=0,adsrS=1,adsrR=.1,nominalKeyoff=nominal,retriggerKeyoff=retrigger}
 end
 local vv={v(0,kind=='choke'),v(kind=='layer' and 0 or 400,kind=='choke')}
 if kind~='layer' then vv[2].nominalKeyoff=.1;vv[2].retriggerKeyoff=nil end
 return T.renderPcm({},pool,sdir,'',song,1,1000,1000,nil,cache,vv,
  {quality='fast',lastSec=0,maxTail=1,releaseFloor=1,blockFrames=block}),vv
end
local a=render(512,'choke');local b=render(127,'choke');yes(a==b,'keygroup choke exact across block boundaries')
local _,vv=render(512,'layer',.6,nil);near(vv[1].keyoff,.6,'first layer keeps authored duration');near(vv[2].keyoff,.6,'second layer keeps authored duration')
local _,vv2=render(512,'layer',.2,.4);near(vv2[1].keyoff,.2,'future retrigger never delays earlier authored note-off')
local _,vv3=render(512,'layer',.2,.3,true);near(vv3[1].keyoff,.35,'pedal release stays authoritative for retrigger requests')
print('AudioNoteOwnershipTests: '..checks..' checks passed')
