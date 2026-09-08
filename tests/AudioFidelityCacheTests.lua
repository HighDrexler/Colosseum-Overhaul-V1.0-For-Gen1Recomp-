local root=os.getenv('CBE_DOUBLES_MOD_DIR') or '.'
local function loadMod(p,v)return assert(loadfile(root..'/'..p))(v)end
local F=loadMod('lib/AudioFidelity.lua');local S=loadMod('lib/BattleAudioSpec.lua')
local checks=0
local function check(v,msg)checks=checks+1;assert(v,msg)end
local function clone(t)local n={};for k,v in pairs(t)do n[k]=v end;return n end
local function fixture(init)
 local data=clone(init or {});local mod={cache={}}
 function mod.cache:read(path)return data[path]end
 function mod.cache:write(path,b)data[path]=b;return true end
 function mod.cache:delete(path)data[path]=nil;return true end
 function mod.cache:info(path)return data[path] and {type='file',size=#data[path]} or nil end
 return mod,data
end
local platform='Android';love={system={getOS=function()return platform end}}
local mod,data=fixture()
check(F.preference(mod)=='auto' and F.resolve(mod)=='fast','AUTO Android remains fast')
platform='iOS';check(F.resolve(mod)=='fast','AUTO iOS remains fast')
platform='Linux';check(F.resolve(mod)=='high','AUTO desktop opts into quality for NEW renders')
check(F.setPreference(mod,'high'),'explicit HIGH persisted');platform='Android';check(F.resolve(mod)=='high','mobile HIGH is available')
check(not F.setPreference(mod,'ultra'),'invalid preference rejected')
check(F.request(mod) and F.pending(mod)=='high','HIGH update requested')
check(F.setPreference(mod,'fast') and F.pending(mod)=='high','queued job keeps requested quality until explicitly replaced')
check(F.request(mod) and F.pending(mod)=='fast','new request changes frozen job quality')
check(F.cancelRequest(mod) and not F.pending(mod),'queued update cancels without changing files')
check(F.checksum('')=='00000001' and F.checksum('hello world')=='1a0b045d','Adler reference vectors')
check(F.checksum(string.rep('z',9000))==S.checksum(string.rep('z',9000)),'batched hash matches prior checksum across blocks')
local path='assets/audio/themes/demo_intro.wav';local bytes=string.rep('x',100)
F.record(mod,path,bytes,'high');data[path]=bytes
check(F.assetReady(mod,path,nil,'high'),'exact high output recognized')
local currentStamp=data[F.stampPath(path)]
for _,oldIdentity in ipairs({'lanczos4-256-v1','lanczos4-256-v1-notes-v2'})do
 data[F.stampPath(path)]=currentStamp:gsub(F.identity('high'):gsub('([^%w])','%%%1'),oldIdentity)
 check(not F.assetReady(mod,path,nil,'high'),'old HIGH notes/mix must rebuild on explicit Apply: '..oldIdentity)
 check(data[path]==bytes,'old WAV stays playable until explicitly replaced')
end
data[F.stampPath(path)]=currentStamp
check(not F.assetReady(mod,path,nil,'fast'),'quality provenance distinguishes same file sizes')
data[path]=bytes:sub(1,-2)..'y';check(not F.assetReady(mod,path,nil,'high'),'same-size corruption not promoted')
check(not pcall(F.stampPath,'../../save.sav'),'stamp traversal rejected')
local P={validWav=function(b)return type(b)=='string' and b:sub(1,4)=='RIFF'end}
local A=loadMod('extract/AudioProbe.lua',{FSYS={},PortableMusyX=P})
-- Exercise an actual intro/loop pair plus the associated original ledger.
local U=loadMod('extract/AudioFidelityBuilder.lua',{AudioFidelity=F,PortableMusyX=P,FSYS={},AudioProbe=A,BattleAudioSpec=S,BattleAudioBuilder={}})
local p1,p2='assets/audio/themes/a_intro.wav','assets/audio/themes/a_loop.wav'
local meta='build/audio_portable_v9_assets.lua'
local initial={[p1]='OLD INTRO',[p2]='OLD LOOP',[meta]='OLD LEDGER',['cache/pokemon/058']='SHINY',
 ['cache/arena/water']='CROWD',['.cbe-audio-portable-v9.complete']='ORIGINAL V9 MARKER'}
local writes={{path=p1,bytes='NEW INTRO'},{path=p2,bytes='NEW LOOP'},{path=meta,bytes='NEW LEDGER'}}
local function unrelated(d)
 check(d['cache/pokemon/058']=='SHINY' and d['cache/arena/water']=='CROWD' and d['.cbe-audio-portable-v9.complete']=='ORIGINAL V9 MARKER','non-target caches untouched')
end
mod,data=fixture(initial);U.commit(mod,writes)
check(data[p1]=='NEW INTRO' and data[p2]=='NEW LOOP' and data[meta]=='NEW LEDGER','whole unit committed')
check(not data[U.journalPath] and not data[U.commitPath],'successful transaction cleaned');unrelated(data)
-- A write error after the intro changed restores both old halves and metadata.
mod,data=fixture(initial);local ordinary=mod.cache.write;local failed=false
function mod.cache:write(p,b)if p==p2 and not failed then failed=true;return false,'disk fixture'end;return ordinary(self,p,b)end
check(not pcall(U.commit,mod,writes),'failed write propagated')
check(data[p1]=='OLD INTRO' and data[p2]=='OLD LOOP' and data[meta]=='OLD LEDGER','error rolled back complete old snapshot')
check(not data[U.journalPath],'rollback completed');unrelated(data)
-- Simulate process death by abandoning the coroutine at persisted write points.
for _,cut in ipairs({U.journalPath,p1,p2,meta,U.commitPath})do
 mod,data=fixture(initial);ordinary=mod.cache.write
 local hit=false
 function mod.cache:write(p,b)
  local r=ordinary(self,p,b)
  if p==cut and not hit then hit=true;coroutine.yield('simulated process death')end
  return r
 end
 local co=coroutine.create(function()U.commit(mod,writes)end)
 local ok,why=coroutine.resume(co)
 check(ok and hit and coroutine.status(co)=='suspended','interrupted at '..cut..' / '..tostring(why))
 mod.cache.write=ordinary
 local rebooted=loadMod('extract/AudioFidelityBuilder.lua',{AudioFidelity=F,PortableMusyX=P,FSYS={},AudioProbe=A,BattleAudioSpec=S,BattleAudioBuilder={}})
 check(rebooted.recover(mod),'fresh module recovers persisted journal')
 local new=cut==U.commitPath
 check(data[p1]==(new and 'NEW INTRO' or 'OLD INTRO') and data[p2]==(new and 'NEW LOOP' or 'OLD LOOP') and data[meta]==(new and 'NEW LEDGER' or 'OLD LEDGER'),'no mixed pair/ledger after restart')
 check(not data[U.journalPath],'restart cleanup completed');unrelated(data)
end
-- A present-but-unreadable journal or old WAV is not treated as absent.
mod,data=fixture(initial);local ordinaryRead=mod.cache.read
function mod.cache:read(p)if p==p1 then return nil,'read fixture'end;return ordinaryRead(self,p)end
check(not pcall(U.commit,mod,writes),'unreadable old target refuses commit')
check(data[p1]=='OLD INTRO' and data[p2]=='OLD LOOP','old targets retained when backup cannot be read')
mod,data=fixture({[U.journalPath]='PRESENT BUT UNREADABLE'});ordinaryRead=mod.cache.read
function mod.cache:read(p)if p==U.journalPath then return nil,'read fixture'end;return ordinaryRead(self,p)end
check(not pcall(U.recover,mod),'present unreadable journal blocks readiness')
mod,data=fixture(initial);ordinaryRead=mod.cache.read
function mod.cache:read(p)if p==p1 then return 'OLD'end;return ordinaryRead(self,p)end
check(not pcall(U.commit,mod,writes) and data[p1]=='OLD INTRO','truncated old read is not used as rollback backup')
-- Absent original outputs are removed on rollback, not invented as empty WAVs.
mod,data=fixture({[p1]='OLD INTRO'});ordinary=mod.cache.write
function mod.cache:write(p,b)local r=ordinary(self,p,b);if p==p2 then coroutine.yield('cut')end;return r end
local co=coroutine.create(function()U.commit(mod,writes)end);check(coroutine.resume(co),'new-file interruption')
mod.cache.write=ordinary;U.recover(mod)
check(data[p1]=='OLD INTRO' and data[p2]==nil and data[meta]==nil,'original absence restored')
-- Damaged backups do not get accepted as a successful recovery.
mod,data=fixture(initial);ordinary=mod.cache.write
function mod.cache:write(p,b)local r=ordinary(self,p,b);if p==p1 then coroutine.yield('cut')end;return r end
co=coroutine.create(function()U.commit(mod,writes)end);check(coroutine.resume(co),'backup-corruption setup')
mod.cache.write=ordinary;data[F.root..'transaction/old_1']='CORRUPT'
check(not pcall(U.recover,mod) and data[U.journalPath]~=nil,'bad backup leaves repair journal and refuses readiness')
-- Builder integration with controlled source banks and two representative songs.
local function le(n,count)local out={};for i=1,count do out[i]=string.char(n%256);n=math.floor(n/256)end;return table.concat(out)end
local function wav(rate,frames,word)
 local raw=string.rep(word or '\1\0\2\0',frames)
 return 'RIFF'..le(36+#raw,4)..'WAVEfmt '..le(16,4)..le(1,2)..le(2,2)..le(rate,4)..le(rate*4,4)..le(4,2)..le(16,2)..'data'..le(#raw,4)..raw
end
local names={'snd_music_proj','snd_music_pool','snd_music_sdir','snd_se_proj','snd_se_pool','snd_se_sdir','common_rel','a_song','b_song','me_snatch_song','fanfare00_song','level_up_song','me_win_song'}
local archive={list=function()local out={};for _,name in ipairs(names)do out[#out+1]={name=name}end;return out end,extract=function(_,e)return e.name end}
local FSYS={open=function()return archive end};local disc={file=function(_,n)return n end,readFile=function(_,n)return n end}
P.prepare=function()return{}end;P.prepareSfx=function()return{}end
local renders,seenQuality,failAt=0,{},nil
P.renderSong=function(ctx,seq,setup,loop,rate,progress,opts)
 renders=renders+1;if renders==failAt then error('injected renderer failure')end
 seenQuality[#seenQuality+1]=opts.quality
 local w=wav(rate,100,opts.quality=='high' and '\3\0\4\0' or '\1\0\2\0')
 return w,loop and w or nil,{frames=100,peak=.5,clipped=0}
end
P.renderSfx=function(ctx,id,rate,progress,opts)
 renders=renders+1;seenQuality[#seenQuality+1]=opts.quality
 return wav(rate,3072),{peak=.5,clipped=0,entry={obj=390},frames=3072}
end
A.themes={{source='a_song',setup=1,intro=p1,loop=p2},{source='b_song',setup=2,intro='assets/audio/themes/b_intro.wav',loop='assets/audio/themes/b_loop.wav'}}
local cueBuilder=loadMod('extract/BattleAudioBuilder.lua',{FSYS=FSYS,PortableMusyX=P,BattleAudioSpec=S})
cueBuilder.validateExpSource=function()return true end
U=loadMod('extract/AudioFidelityBuilder.lua',{AudioFidelity=F,PortableMusyX=P,FSYS=FSYS,AudioProbe=A,BattleAudioSpec=S,BattleAudioBuilder=cueBuilder})
local openCount=0;local function openDisc()openCount=openCount+1;return disc end
mod,data=fixture(initial)
F.setPreference(mod,'high');F.request(mod)
local result=U.run(mod,openDisc)
check(result.ready and result.built==7 and result.complete==7,'all theme/cue units built')
check(openCount==1 and renders==7,'one source open and one render per unit')
for _,q in ipairs(seenQuality)do check(q=='high','all upgraded music and cue calls receive HIGH')end
check(F.pending(mod)==nil and F.status(mod).state=='ready','request clears only on complete success')
check(#data[S.cues[1].path]==6188,'EXP keeps exact 48ms source cycle')
check(S.ready(S.cues[2],data[S.cues[2].path],data[S.markerPath(S.cues[2])]),'old reward runtime accepts upgraded marker')
check(A.bossIntroReady(mod),'old boss runtime accepts upgraded marker')
unrelated(data)
F.request(mod);local oldRenders=renders
local hitResult=U.run(mod,function()error('cached pass must not access source')end)
check(hitResult.ready and hitResult.reused==7 and renders==oldRenders,'warm upgrade source-free; all completed units reused')
data[p2]=data[p2]:sub(1,-2)..'x';F.request(mod)
local repair=U.run(mod,openDisc)
check(repair.ready and repair.built==1 and repair.reused==6,'corrupt loop repairs one entire source unit only')
F.setPreference(mod,'fast');F.request(mod)
local fastResult=U.run(mod,openDisc)
check(fastResult.ready and fastResult.built==7,'FAST restoration renders the same plan')
check(F.assetReady(mod,p1,nil,'fast') and not F.assetReady(mod,p1,nil,'high'),'restored fast quality stamped accurately')
-- Resume completed units after a rendering failure without discarding old audio.
F.setPreference(mod,'high');F.request(mod);failAt=renders+3
local partial=U.run(mod,openDisc)
check(not partial.ready and partial.complete==2 and partial.built==2 and F.pending(mod)=='high','mid-batch failure retains request and progress')
check(F.status(mod).state=='incomplete','failure visible to settings')
failAt=nil
local resume=U.run(mod,openDisc)
check(resume.ready and resume.reused==2 and resume.built==5,'restart skips exactly the two complete units')
unrelated(data)
print('AudioFidelityCacheTests: '..checks..' assertions passed')
