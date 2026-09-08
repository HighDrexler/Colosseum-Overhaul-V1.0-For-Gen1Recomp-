local function scenario(legacy,throws)
  local released=0
  local screen={}
  local state={}
  function state:finishBattle() self.phase="fadeout";return "fade" end
  if not legacy then
    function state:completeBattle()
      assert(released==0,"presentation released before exit callback")
      if throws then error("exit failure") end
      self.phase="done";return "complete"
    end
  end
  local runtime=assert(loadfile("lib/BattleRuntime.lua"))({
    mod={},
    engineRequire=function(name)
      if name=="src.battle.BattleState" then return state end
      error("unavailable test module")
    end,
    GenerationCompat={current=function() return 2 end,prepare=function(value) return value end,
      matches=function(first,second) return first==second end},
    StandaloneHost={status=function() return {active=true} end,finish=function() released=released+1 end},
  })
  runtime.install()
  runtime.activeBattle=screen;runtime.pendingEnd=screen
  assert(state.finishBattle(screen)=="fade")
  if legacy then assert(released==1);return end
  assert(released==0 and runtime.activeBattle==screen,"CBE released at fade start")
  local ok,result=pcall(state.completeBattle,screen)
  if throws then
    assert(not ok and released==0 and runtime.pendingEnd==screen,"failed exit released presentation")
  else
    assert(ok and result=="complete" and released==1 and runtime.activeBattle==nil,"completion did not release CBE")
  end
end
scenario(false,false)
scenario(true,false)
scenario(false,true)
return true
