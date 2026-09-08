-- Optional audit of a privately extracted music bank and song files.
-- luajit AudioNoteSourceChecks.lua MOD_ROOT BANK_ROOT
-- BANK_ROOT/bank/snd_music.{proj,pool,sdir,samp}
-- BANK_ROOT/songs/{battle5_song,mirrorbo_song,tool_battle1_song}.song
-- Only statistics are printed. Never redistribute the input samples/sequences.
local root=assert(arg[1],'mod root required');local private=assert(arg[2],'private bank root required')
local function read(p)local f=assert(io.open(p,'rb'));local b=f:read('*a');f:close();return b end
local P=assert(loadfile(root..'/extract/PortableMusyX.lua'))();local T=P._test
local payload={music={}};for _,n in ipairs{'proj','pool','sdir','samp'}do payload.music[n]=read(private..'/bank/snd_music.'..n)end
local ctx=P.prepare(payload);local checks=0
local function yes(v,m)checks=checks+1;assert(v,m)end
for _,track in ipairs{{'battle5_song',51,328,50},{'mirrorbo_song',65,140,28},{'tool_battle1_song',20,464,231}}do
 local song=T.parseSong(read(private..'/songs/'..track[1]..'.song'))
 local vv=T.noteVoices(ctx.project,ctx.pool,ctx.sdir,song,track[2],48000)
 local nextOff,nextEvent={},{}
 for i=#song.events,1,-1 do local e=song.events[i]
  if e.kind=='note' and e.velocity>0 then
   local k=e.ch..':'..e.key;nextOff[i]=nextEvent[k];nextEvent[k]=T.tickSeconds(song,e.tick)
  end
 end
 local same,different=0,0
 for j,v in ipairs(vv)do
  local e=song.events[v.noteEventId];yes(e and e.key==v.midiKey and e.ch==v.channel,'voice retains original event identity')
  local off=nextOff[v.noteEventId]
  if off then yes(v.retriggerKeyoff~=nil and math.abs(v.retriggerKeyoff-math.max(0,off-v.startSec))<1e-10,'retrigger follows next original-key event')
  else yes(v.retriggerKeyoff==nil,'no unrelated sample voice creates a retrigger')end
  for k=j-1,1,-1 do local o=vv[k];if o.startFrame<v.startFrame then break end
   if o.channel==v.channel and o.key==v.key then
    if o.noteEventId==v.noteEventId then same=same+1 else different=different+1 end
   end
  end
 end
 yes(same==track[3] and different==track[4],'expected original bank collision candidates')
 print(('SOURCE\t%s\tvoices=%d\tsibling_pair_candidates=%d\tdifferent_event_pair_candidates=%d'):format(track[1],#vv,same,different))
end
print('PASS AudioNoteSourceChecks: '..checks..' checks; source identity/choke candidates, not an audible-fidelity metric')
