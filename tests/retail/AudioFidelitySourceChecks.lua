-- Optional actual-source check; NOT part of the ROM-free test runner.
-- LuaJIT on Linux/macOS: luajit tests/retail/AudioFidelitySourceChecks.lua MOD_DIR DISC_CISO OUTPUT_CACHE
-- OUTPUT_CACHE is PRIVATE: this script writes the user's generated soundtrack.
-- Do not redistribute it. A baseline Amuse reference comparison is not performed.
local root=assert(arg[1],'mod directory required');local output=assert(arg[3],'private output directory required');local iso=assert(arg[2],'verified source CISO required')
local originalLoad=load
if loadstring then load=function(s,n)if type(s)=='string' then return loadstring(s,n)end;return originalLoad(s,n)end end
if arg[4]=='noffi' then local req=require;require=function(n)if n=='ffi' then error('non-FFI test')end;return req(n)end end
local f=assert(io.open(iso,'rb'))
local header=assert(f:read(32768));assert(header:sub(1,4)=='CISO')
local a,b,c,d=header:byte(5,8);local block=a+b*256+c*65536+d*16777216
assert(block>0 and block<=16*1024*1024,"invalid CISO block size")
local offsets={};local n=32768
for i=0,32759 do if header:byte(i+9)==1 then offsets[i]=n;n=n+block end end
local mod={imports={}}
function mod.imports:info()return {size=1459978240}end
function mod.imports:read(id,offset,length)
 local parts={}
 while length>0 do
  local index=math.floor(offset/block);local inside=offset%block;local count=math.min(length,block-inside)
  if offsets[index] then f:seek('set',offsets[index]+inside);parts[#parts+1]=assert(f:read(count))
  else parts[#parts+1]=string.rep('\0',count)end
  length=length-count;offset=offset+count
 end
 return table.concat(parts)
end
local function loadModule(p,v)return assert(loadfile(root..'/'..p))(v)end
local D=loadModule('extract/GameCubeDisc.lua');local FSYS=loadModule('extract/FSYS.lua')
local P=loadModule('extract/PortableMusyX.lua');local F=loadModule('lib/AudioFidelity.lua');local S=loadModule('lib/BattleAudioSpec.lua')
local function mkdir(path)
 assert(package.config:sub(1,1)=='/','source validation harness needs a POSIX host')
 local quoted="'"..path:gsub("'", "'\"'\"'").."'"
 local ok=os.execute('mkdir -p '..quoted)
 assert(ok==0 or ok==true,'cannot create private output directory')
end
mod.cache={}
function mod.cache:read(path)local h=io.open(output..'/'..path,'rb');if not h then return nil end;local b=h:read('*a');h:close();return b end
function mod.cache:write(path,b)mkdir(output..'/'..path:match('(.+)/'));local h=assert(io.open(output..'/'..path,'wb'));h:write(b);h:close();return true end
function mod.cache:delete(path)os.remove(output..'/'..path);return true end
function mod.cache:info(path)local h=io.open(output..'/'..path,'rb');if not h then return nil end;local n=h:seek('end');h:close();return {type='file',size=n}end
local A=loadModule('extract/AudioProbe.lua',{FSYS=FSYS,PortableMusyX=P,AudioFidelity=F})
local B=loadModule('extract/BattleAudioBuilder.lua',{FSYS=FSYS,PortableMusyX=P,BattleAudioSpec=S,AudioFidelity=F})
local U=loadModule('extract/AudioFidelityBuilder.lua',{FSYS=FSYS,PortableMusyX=P,BattleAudioSpec=S,AudioFidelity=F,AudioProbe=A,BattleAudioBuilder=B})
local native=P.renderSong
P.renderSong=function(ctx,sequence,setup,loops,rate,progress,opts)
 local t=os.clock();local a,b,st=native(ctx,sequence,setup,loops,rate,progress,opts)
 assert(st.clipped==0 and st.peak>0 and st.peak<=1,'final source render is silent or clipped')
 assert(st.voiceRenderer=='midi-note-ownership-v2','new note renderer identity')
 print(('RENDER\tsetup=%d\tcpu=%.6f\tframes=%d\tpeak=%.9f\tclipped=%d\tsourcePeak=%.9f\toutputGain=%.9f\tloopStart=%s\tloopEnd=%s'):format(setup,os.clock()-t,st.frames,st.peak,st.clipped,st.sourcePeak,st.outputGain,tostring(st.loopStartFrame),tostring(st.loopEndFrame)))
 io.stdout:flush();return a,b,st
end
local nativeSfx=P.renderSfx
P.renderSfx=function(...)
 local wav,st=nativeSfx(...)
 assert(st.clipped==0 and st.peak>0 and st.peak<=1,'EXP source render is silent or clipped')
 print(('SFX\tid=%d\tframes=%d\tpeak=%.9f\tclipped=%d'):format(st.sfxId,st.frames,st.peak,st.clipped))
 return wav,st
end
F.setPreference(mod,'high');F.request(mod)
local opens=0;local total=os.clock()
local result=U.run(mod,function()opens=opens+1;return D.open(mod)end,function(label,current,count)
 if label:find(' OF ',1,true) then print(label);io.stdout:flush()end
end)
assert(result.ready,result.error);assert(result.complete==16 and #U.plan()==16,'source-unit count')
print(('FIRST\tbuilt=%d\treused=%d\topens=%d\tcpu=%.6f'):format(result.built,result.reused,opens,os.clock()-total));io.stdout:flush()
local targets=0
for _,unit in ipairs(U.plan())do
 for _,path in ipairs(unit.paths)do
  assert(F.assetReady(mod,path,nil,'high'),'stamp '..path);targets=targets+1
 end
 if unit.cue then assert(S.ready(unit.cue,mod.cache:read(unit.paths[1]),mod.cache:read(S.markerPath(unit.cue))),'cue marker')end
end
assert(targets==27);assert(A.bossIntroReady(mod),'boss marker')
local ledger=assert(load(mod.cache:read(A.portableLedgerPath)))()
for _,unit in ipairs(U.plan())do if unit.soundtrack then for _,path in ipairs(unit.paths)do assert(ledger.assets[path].size==#mod.cache:read(path))end end end
assert(not F.pending(mod),'completed request consumed')
F.request(mod);total=os.clock()
local warm=U.run(mod,function()error('warm source read forbidden')end)
assert(warm.ready and warm.built==0 and warm.reused==16)
print(('WARM\tbuilt=%d\treused=%d\tcpu=%.6f'):format(warm.built,warm.reused,os.clock()-total))
print('PASS actual-source 16 units / 27 WAVs / native cue+boss+ledger metadata / no source access on warm queue')
