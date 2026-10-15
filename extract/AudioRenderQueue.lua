local V=...
local P=assert(V.PortableMusyX)
local Q={}
local support=setmetatable({},{__mode="k"})
local backgroundThreads=setmetatable({},{__mode="k"})
local jobApi
local function now()return love and love.timer and love.timer.getTime and love.timer.getTime() or os.clock()end
local function pause()
local ticket=backgroundThreads[coroutine.running()]
if ticket then
assert(not ticket.cancelled,"background audio cancelled")
coroutine.yield()
assert(not ticket.cancelled,"background audio cancelled")
return
end
if love and love.event and love.event.pump then love.event.pump()end
if love and love.timer and love.timer.sleep then love.timer.sleep(.02)end
end
function Q.pumpBackground(ticket,force)
if not ticket or ticket.done then return end
if not force and now()-(ticket.lastPoll or 0)<.02 then return end
ticket.lastPoll=now()
local ok,value=coroutine.resume(ticket.thread)
if not ok or coroutine.status(ticket.thread)=="dead"then
ticket.done=true;ticket.result=ok and value or nil;ticket.error=not ok and tostring(value)or nil
backgroundThreads[ticket.thread]=nil
end
end
function Q.startBackground(mod,work)


if not jobApi(mod)then return nil end
local ticket={thread=coroutine.create(work)}
backgroundThreads[ticket.thread]=ticket
Q.pumpBackground(ticket,true);return ticket
end
function Q.finishBackground(ticket)
while not ticket.done do Q.pumpBackground(ticket,true);if not ticket.done then pause()end end
return ticket.result,ticket.error
end
function Q.cancelBackground(ticket)
if ticket and not ticket.done then ticket.cancelled=true;Q.pumpBackground(ticket,true)end
end
jobApi=function(mod)
if support[mod]==false then return nil end
local ok,api=pcall(function()return mod.job end)
if not ok or not api or type(api.available)~="function" then support[mod]=false;return nil end
local available,value=pcall(api.available,api)
if not available or not value then support[mod]=false;return nil end
if support[mod] then return api end
local ran,handle=pcall(api.run,api,"extract/PortableMusyX.lua",{cbeAudioJob=1,mode="probe"},{assetIO=true,maxSeconds=5})
if not ran or not handle then return nil end
while true do
local r=api:poll(handle)
if r.status~="pending" then
api:release(handle)
support[mod]=r.status=="ok" and type(r.result)=="table" and r.result.assetIO==true
return support[mod] and api or nil
end
pause()
end
end


function Q.map(mod,tasks,receive,progress)
local api=jobApi(mod);local pending={};local nextTask,done=1,0
local lastHeartbeat=0;local started=now();local workers,fallbacks=0,0
local contexts={}
local function serial(task)
fallbacks=fallbacks+1
local bank=task.music or task.sfx
if not contexts[bank] then contexts[bank]=task.music and P.prepare({music=bank})or P.prepareSfx({sfx=bank})end
receive(P.renderJob(task,function(frame,total)
if progress then progress(task,frame,total)end
if backgroundThreads[coroutine.running()]then pause()end
end,contexts[bank]),task)
done=done+1
end
local function run()
while done<#tasks do
for slot=1,2 do
if not pending[slot] and nextTask<=#tasks then
local task=tasks[nextTask];nextTask=nextTask+1
task.cbeAudioJob=1;task.progressPath=api and progress and ("build/audio_jobs_v1/slot_%d.txt"):format(slot)or nil
if task.progressPath then pcall(mod.cache.write,mod.cache,task.progressPath,"")end
if progress then progress(task,0,0)end
local ok,handle
if api then ok,handle=pcall(api.run,api,"extract/PortableMusyX.lua",task,{assetIO=true,maxSeconds=300})end
if ok and handle then pending[slot]={handle=handle,task=task};workers=workers+1
else serial(task)end
end
end
local heartbeat=now()-lastHeartbeat>=1
if heartbeat then lastHeartbeat=now()end
for slot=1,2 do
local item=pending[slot]
if item then
local r=api:poll(item.handle)
if r.status~="pending" then
api:release(item.handle);pending[slot]=nil
if r.status=="ok" and type(r.result)=="table" then receive(r.result,item.task);done=done+1
else serial(item.task)end
elseif heartbeat and progress then
local ok,raw=pcall(mod.cache.read,mod.cache,item.task.progressPath)
local frame,total=0,0
if ok and type(raw)=="string" then frame,total=raw:match("^(%d+)\t(%d+)$")end
progress(item.task,tonumber(frame)or 0,tonumber(total)or 0)
end
end
end
if pending[1] or pending[2] then pause()end
end
end
local ok,why=pcall(run)
for _,item in pairs(pending)do pcall(api.cancel,api,item.handle);pcall(api.release,api,item.handle)end
assert(ok,why)
return {workers=workers,fallbacks=fallbacks,seconds=now()-started}
end
function Q.renderAll(mod,payload,send)
local tasks={};local complete=0;local rate=tonumber(payload.sampleRate)or 48000
for _,song in ipairs(payload.songs or {})do tasks[#tasks+1]={mode="song",music=payload.music,sequence=song.sequence,setup=song.setup,
quality=payload.quality,rate=rate,loop=true,source=song.source,introPath=song.introPath,loopPath=song.loopPath}end
for _,shot in ipairs(payload.oneShots or {})do tasks[#tasks+1]={mode="song",music=payload.music,sequence=shot.sequence,setup=shot.setup,
quality=payload.quality,rate=rate,source=shot.source,outputPath=shot.outputPath}end
local stats=Q.map(mod,tasks,function(r,t)
assert(type(r.stats)=="table" and r.stats.peak>0.00001,t.source..": portable synthesis produced silence")
if t.loop then
send({kind="asset",source=t.source.." intro",path=t.introPath,bytes=r.intro,stats=r.stats});complete=complete+1
send({kind="asset",source=t.source.." loop",path=t.loopPath,bytes=r.loop,stats=r.stats});complete=complete+1
else send({kind="asset",source=t.source,path=t.outputPath,bytes=r.intro,stats=r.stats});complete=complete+1 end
end,function(t,frame,total)send({kind=total>0 and "heartbeat"or "source",source=t.source,frame=frame,total=total})end)
stats.complete=complete;stats.rate=rate;stats.quality=payload.quality;stats.renderer="Lua MusyX / "..tostring(payload.quality).." / 48 kHz source timing"
return stats
end
return Q
