-- Test render orchestration with controlled PCM; no copyrighted samples.
local root=os.getenv('CBE_DOUBLES_MOD_DIR') or '.'
local checks=0
local function yes(v,m)checks=checks+1;assert(v,m)end
local function near(a,b,m)yes(math.abs(a-b)<1e-10,m)end
local function replaceUpvalue(fn,want,value)
 for i=1,100 do local name=debug.getupvalue(fn,i);if not name then break end
  if name==want then debug.setupvalue(fn,i,value);return end
 end
 error('missing test seam '..want)
end
for _,quality in ipairs({'high','fast'})do
 for _,peak in ipairs({.7,1,1.5})do
  for _,looped in ipairs({false,true})do
   local P=assert(loadfile(root..'/extract/PortableMusyX.lua'))()
   local calls=0;local clean=string.rep('\3\0\4\0',3200)
   local clipped=string.rep('\255\127\255\127',3200)
   replaceUpvalue(P.renderSong,'parseSong',function()return {events={},tempos={},initialTempo=120}end)
   replaceUpvalue(P.renderSong,'renderPcm',function(project,pool,sdir,samp,song,setup,rate,minFrames,progress,cache,prepared,opts)
    calls=calls+1;yes(opts.quality==quality,'interpolation choice survives headroom pass')
    if calls==1 then yes(opts.outputGain==nil,'first pass measures unscaled source mix');return peak>1 and clipped or clean,peak,4,peak>1 and 64 or 0 end
    near(opts.outputGain,.98/peak,'second pass has one exact track-wide gain')
    return clean,peak*opts.outputGain,4,0
   end)
   local a,b,st=P.renderSong({project={},pool={},sdir={},sampleCache={}},'',1,looped and 4800 or nil,8000,nil,{quality=quality})
   yes(calls==(peak>1 and 2 or 1),'only overloaded tracks require a second render')
   near(st.sourcePeak,peak,'source peak remains visible in diagnostics')
   near(st.outputGain,peak>1 and .98/peak or 1,'reported gain is exact')
   yes(st.clipped==0 and st.frames==3200,'final render has no clipped samples or changed duration')
   yes(st.voiceRenderer=='midi-note-ownership-v2','voice identity reported')
   if looped then
    yes(st.loopStartFrame==800,'headroom keeps original intro/loop split')
    yes(a:sub(45)..b:sub(45)==clean,'intro and loop come from same clean rerender, not attenuated clipped PCM')
   else yes(a:sub(45)==clean and b==nil,'one-shot comes from clean rerender')end
  end
 end
end
print('AudioHeadroomTests: '..checks..' checks passed')
