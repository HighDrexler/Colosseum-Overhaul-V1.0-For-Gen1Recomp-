love={system={getOS=function() return "Windows" end},timer={getTime=function() return 0 end}}

local inputWrapper
local mod={hooks={}}
function mod.hooks:wrap(name,fn)
  if name=="input.step" then inputWrapper=fn end
end

local pumps=0
local viewer=false
local hard=false
local ResidentPrewarm={}
function ResidentPrewarm.pump(game) pumps=pumps+1;return true end
function ResidentPrewarm.viewerActive() return viewer end
function ResidentPrewarm.hardCacheRunning() return hard end

local runtime=assert(loadfile("lib/BattleRuntime.lua"))({
  mod=mod,
  engineRequire=function() error("unavailable test module") end,
  GenerationCompat={current=function() return 1 end,prepare=function(v) return v end,matches=function(a,b) return a==b end},
  ResidentPrewarm=ResidentPrewarm,
})
assert(runtime.install()==true and type(inputWrapper)=="function","input.step wrapper not installed")

local top={}
local game={stack={top=function() return top end}}
local function step() return true end

-- Ordinary menu/dialogue states are NOT cache/prewarm windows anymore.
inputWrapper(step,game,1/60)
assert(pumps==0,"resident prewarm ran in an unrelated menu state")

-- Stable true overworld remains the normal background-prewarm window.
top={isOverworld=true}
inputWrapper(step,game,1/60)
assert(pumps==1,"resident prewarm did not run on stable overworld")

-- Information viewer may request its one scheduler-filtered safe promotion.
top={};viewer=true
inputWrapper(step,game,1/60)
assert(pumps==2,"viewer-safe information promotion was not serviced")

-- Explicit Hard Cache Save must continue progressing in its settings screen.
viewer=false;hard=true
inputWrapper(step,game,1/60)
assert(pumps==3,"explicit hard-cache build did not progress outside overworld")

print("MenuPrewarmBoundaryTests: OK")
