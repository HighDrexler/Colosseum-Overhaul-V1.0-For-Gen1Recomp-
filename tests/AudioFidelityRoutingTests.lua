local root=os.getenv('CBE_DOUBLES_MOD_DIR') or '.'
local function loadMod(p,v)return assert(loadfile(root..'/'..p))(v)end
local checks=0;local function check(v,msg)checks=checks+1;assert(v,msg)end
local F=loadMod('lib/AudioFidelity.lua');local S=loadMod('lib/BattleAudioSpec.lua')
local platform='Linux';love={system={getOS=function()return platform end}}
local function le(n,k)local t={};for i=1,k do t[i]=string.char(n%256);n=math.floor(n/256)end;return table.concat(t)end
local function wav(frames,word)
 local raw=string.rep(word or '\1\0\2\0',frames)
 return 'RIFF'..le(#raw+36,4)..'WAVEfmt '..le(16,4)..le(1,2)..le(2,2)..le(48000,4)..le(192000,4)..le(4,2)..le(16,2)..'data'..le(#raw,4)..raw
end
local files={};local reads,writes,opens,renders=0,0,0,0
local mod={cache={}}
function mod.cache:read(p)reads=reads+1;return files[p]end
function mod.cache:write(p,b)writes=writes+1;files[p]=b;return true end
function mod.cache:delete(p)files[p]=nil;return true end
function mod.cache:info(p)return files[p] and {type='file',size=#files[p]}end
local names={'snd_music_proj','snd_music_pool','snd_music_sdir','me_snatch_song','fanfare00_song'}
local archive={list=function()local out={};for _,n in ipairs(names)do out[#out+1]={name=n}end;return out end,extract=function(_,e)return e.name end}
local P={validWav=function(b)return S.validWav(b,48000)end}
local seen
function P.renderAll(payload,send)
 renders=renders+1;seen=payload;local count=0
 for _,song in ipairs(payload.songs)do
  send({kind='asset',path=song.introPath,bytes=wav(111),source=song.source,stats={peak=.5}});count=count+1
  send({kind='asset',path=song.loopPath,bytes=wav(333),source=song.source,stats={peak=.5}});count=count+1
 end
 for _,shot in ipairs(payload.oneShots)do send({kind='asset',path=shot.outputPath,bytes=wav(22),stats={peak=.5}});count=count+1 end
 return {complete=count}
end
function P.prepare()return {}end
local bossQuality
function P.renderSong(_,_,setup,loops,rate,progress,opts)
 check(setup==12 and loops==nil and rate==48000,'boss route preserves source/rate/one-shot semantics')
 bossQuality=opts.quality;return wav(222),nil,{peak=.5}
end
local A=loadMod('extract/AudioProbe.lua',{AudioFidelity=F,PortableMusyX=P,FSYS={open=function()opens=opens+1;return archive end}})
for _,t in ipairs(A.themes)do names[#names+1]=t.source end
local sizes={}
for _,p in ipairs(A.portableAssets)do files[p]=wav(100);sizes[p]=#files[p]end
files[A.portableLedgerPath]=A.fidelityLedger(mod,sizes)
files['.cbe-audio-portable-v9.complete']=A.portableFullMarker
files['build/audio_portable_v9.complete']=A.portableFullMarker
files['.cbe-audio-portable-v1.complete']=A.portableMarker
local disc={file=function(_,n)return n end,readFile=function()return 'source'end}
local before=writes
check(A.runPortableFull(mod,disc,nil,{}).cached,'existing verified v9 reused on desktop')
check(opens==0 and renders==0 and writes==before,'AUTO high does not force old soundtrack rebuild')
local t=A.themes[1];local oldIntro=files[t.intro];files[t.loop]=nil
local result=A.runPortableFull(mod,disc,nil,{})
check(result.ready and seen.quality=='high' and #seen.songs==1 and #seen.oneShots==0,'one missing loop requests one high theme unit')
check(files[t.intro]~=oldIntro and #files[t.loop]==#wav(333),'repair writes BOTH intro and loop')
check(F.assetReady(mod,t.intro,nil,'high') and F.assetReady(mod,t.loop,nil,'high'),'both halves receive matching provenance')
check(A.portableFullReady(mod),'original v9 size ledger and gate accept repaired pair')
local quiet=opens;A.runPortableFull(mod,disc,nil,{});check(opens==quiet and renders==1,'subsequent boot no render')
platform='Android';files[t.loop]=nil;A.runPortableFull(mod,disc,nil,{})
check(seen.quality=='fast' and F.assetReady(mod,t.intro,nil,'fast') and F.assetReady(mod,t.loop,nil,'fast'),'AUTO Android repairs whole pair in FAST mode')
check(not F.assetReady(mod,t.loop,nil,'high'),'no false high stamp after fast repair')
check(A.runBossIntro(mod,disc) and bossQuality=='fast','boss direct call receives FAST mobile gate')
local saveOpen=opens;check(A.runBossIntro(mod,disc) and opens==saveOpen,'boss cache reused independent of new preference')
F.setPreference(mod,'high');files['assets/audio/intro/fanfare00.wav']=nil
check(A.runBossIntro(mod,disc) and bossQuality=='high','explicit mobile HIGH reaches boss direct call')
check(F.assetReady(mod,'assets/audio/intro/fanfare00.wav',nil,'high'),'boss quality stamp matches file')
local function source(p)local f=assert(io.open(root..'/'..p,'rb'));local b=f:read('*a');f:close();return b end
local main=source('main.lua')
local recover=assert(main:find('FidelityBuilder.recover(mod)',1,true))
local pipeline=assert(main:find('pcall(BuildPipeline.run',1,true))
local optional=assert(main:find('if extractionStatus.audioReady==true and AudioFidelity.pending(mod)',1,true))
check(recover<pipeline and optional>pipeline,'recovery precedes native startup gate; optional job follows canonical readiness')
check(main:find('result.recoveryRequired then error',1,true)~=nil,'failed rollback cannot expose partial runtime audio')
local waza=source('extract/WazaSfxBuilder.lua')
check(waza:find('{quality="fast"}',1,true)~=nil,'unrelated attack-bank synthesis remains explicit FAST')
local builder=source('extract/BattleAudioBuilder.lua')
check(builder:find('Fidelity and Fidelity.resolve(mod)',1,true) and builder:find('{quality=quality}',1,true),'small native cue builder receives same cache policy')
print('AudioFidelityRoutingTests: '..checks..' assertions passed')
