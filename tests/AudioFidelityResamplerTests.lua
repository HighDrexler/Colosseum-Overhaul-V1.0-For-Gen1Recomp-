local root=os.getenv('CBE_DOUBLES_MOD_DIR') or '.'
local checks=0
local function check(v,msg)checks=checks+1;assert(v,msg)end
local function near(a,b,t,msg)check(math.abs(a-b)<=(t or 1e-8),(msg or 'mismatch')..': '..tostring(a)..' / '..tostring(b))end
local function loadRenderer(noFfi)
 local saved=require
 if noFfi then require=function(n)if n=='ffi' then error('string PCM fixture')end;return saved(n)end end
 local ok,P=pcall(assert(loadfile(root..'/extract/PortableMusyX.lua')))
 require=saved;assert(ok,P);return P
end
local P=loadRenderer(false);local Q=loadRenderer(true)
local t=P._test;local q=Q._test
check(q.ffi==nil,'non-FFI path really active')
local function sample(values,loopStart,loopEnd,ffi)
 local pcm
 if ffi then pcm=ffi.new('int16_t[?]',#values);for i,v in ipairs(values)do pcm[i-1]=v end
 else local bytes={};for i,v in ipairs(values)do v=v%65536;bytes[i]=string.char(v%256,math.floor(v/256))end;pcm=table.concat(bytes)end
 return {pcm=pcm,count=#values,looped=loopStart~=nil,loopStart=loopStart or 0,loopEnd=loopEnd or 0}
end
check(#t.lanczosWeights==256,'256 positive-index phases')
for _,w in ipairs(t.lanczosWeights)do
 check(#w==8 and w[0]==nil and w[9]==nil,'exactly eight dense positive-index taps')
 local sum=0;for i=1,8 do sum=sum+w[i]end;near(sum,1,1e-12,'unity DC gain')
end
local values={};for i=1,40 do values[i]=(i<=20 and -1000+i*15 or 10000+i*40)end
local a=sample(values,20,30,t.ffi);local b=sample(values,20,30,nil)
local unlooped=sample(values,nil,nil,t.ffi)
for i=0,39 do near(t.pcmAtLanczos(a,i),values[i+1],0,'integer identity')end
for i=0,19 do
 for _,f in ipairs({.125,.25,.5,.875})do
  near(t.pcmAtLanczos(a,i+f,false),t.pcmAtLanczos(unlooped,i+f,false),1e-9,'attack not replaced by sustain samples')
 end
end
check(t.loopAwareTapIndex(a,3,false)==3,'attack prefix left intact')
check(t.loopAwareTapIndex(a,19,false)==19,'first loop traversal uses real attack history')
check(t.loopAwareTapIndex(a,19,true)==29,'after actual wrap left history comes from loop tail')
check(t.loopAwareTapIndex(a,30,false)==20,'right lookahead crosses upcoming loop seam')
check(t.loopAwareTapIndex(a,-3,false)==0,'initial sample edge clamps, not tail')
for _,span in ipairs({1,2,3,4,7,10})do
 local s=sample(values,20,20+span,t.ffi)
 for idx=-51,81 do
  local wrapped=t.loopAwareTapIndex(s,idx,true)
  check(wrapped>=20 and wrapped<20+span,'arbitrary tap offset safely modulo wrapped')
 end
 for i=0,399 do
  local idx=i/10
  near(t.pcmAtLanczos(s,idx,false),q.pcmAtLanczos(sample(values,20,20+span,nil),idx,false),1e-7,'FFI/string parity (first pass)')
  near(t.pcmAtLanczos(s,idx,true),q.pcmAtLanczos(sample(values,20,20+span,nil),idx,true),1e-7,'FFI/string parity (looped)')
 end
end
for _,count in ipairs({1,2,3,4,8,16})do
 local v={};for i=1,count do v[i]=1234 end
 local s=sample(v,0,count,t.ffi)
 for n=0,count*10-1 do near(t.pcmAtLanczos(s,n/10,true),1234,1e-8,'constant short-loop gain')end
 near(t.pcmAtLanczos(s,-.25,true),0,0,'negative position guard')
 near(t.pcmAtLanczos(s,count,true),0,0,'end position guard')
end
local empty=sample({},nil,nil,t.ffi)
near(t.pcmAtLanczos(empty,0),0,0,'empty sample guard')
-- Malformed loop metadata is never used for FFI index math; SDIR rejects it.
local invalid=sample(values,35,99,t.ffi)
for idx=-10,65 do local mapped=t.loopAwareTapIndex(invalid,idx,true);check(mapped>=0 and mapped<40,'invalid loop uses sample-safe boundaries')end
-- Compare interpolation against the analytic signal, not another copied kernel.
for _,freq in ipairs({.05,.10,.20,.30})do
 local vals={};for i=0,4095 do vals[i+1]=math.floor(12000*math.sin(2*math.pi*freq*i)+.5)end
 local s=sample(vals,nil,nil,t.ffi);local high,fast=0,0
 for i=10,2040 do for _,f in ipairs({.25,.5,.75})do
  local want=12000*math.sin(2*math.pi*freq*(i+f))
  high=high+(t.pcmAtLanczos(s,i+f)-want)^2;fast=fast+(t.pcmAtLinear(s,i+f)-want)^2
 end end
 check(high<fast*.12,'sine interpolation error improves at '..freq)
end
-- Explicit FAST retains the exact v1.0.5 math, including its endpoint behavior.
for i=0,399 do
 local pos=i/10;local at=math.floor(pos);local frac=pos-at
 local v=values[at+1];local want=(frac<=0 or at+1>=#values) and v or v+(values[at+2]-v)*frac
 near(t.pcmAtLinear(a,pos),want,1e-8,'legacy FAST arithmetic')
end
check(t.qualityName(nil)=='high' and t.qualityName({})=='high','new public default is HIGH')
check(t.qualityName({quality='fast'})=='fast','explicit FAST escape hatch')
-- renderAll threads the chosen option to BOTH themes and one-shots.
local calls={};P.prepare=function()return{}end
P.renderSong=function(ctx,seq,setup,loop,rate,progress,opts)
 calls[#calls+1]={loop=loop,quality=opts.quality};return 'wav','loop',{peak=.5}
end
local request={music={},quality='fast',songs={{sequence='s',setup=1,introPath='a',loopPath='b'}},oneShots={{sequence='s',setup=1,outputPath='c'}}}
local emitted=0;local stats=P.renderAll(request,function(m)if m.kind=='asset'then emitted=emitted+1 end end)
check(#calls==2 and calls[1].quality=='fast' and calls[2].quality=='fast','both public batch routes carry FAST')
check(calls[1].loop==true and calls[2].loop==nil and emitted==3 and stats.complete==3,'loop split and emission contract unchanged')
print('AudioFidelityResamplerTests: '..checks..' assertions passed')
