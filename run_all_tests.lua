-- Historical Windows/LÖVE integration runner retained from the input build.
-- This fixed list is NOT exhaustive and was not executed for this release.
-- For the current top-level headless checks use: python tests/run_headless.py
-- The tests/doubles subtree needs separate engine/ROM fixtures. See VALIDATION.md.
package.cpath=package.cpath..';C:/Program Files/LOVE/?.dll'
love=require('love')
require('love.filesystem');require('love.font');require('love.system');require('love.window');require('love.graphics');require('love.image');require('love.data');require('love.event');require('love.timer')
assert(love.window.setMode(640,480))
love.window.minimize()
local atan=math.atan;math.atan=function(y,x) if x then return math.atan2(y,x) end return atan(y) end
local pack=love.data.pack
string.pack=string.pack or function(fmt,...)return pack('string',fmt,...) end

-- UI-bridge tests need UI_COMPAT_DIR/CBE_TEST_BASE and are run separately
-- (work/run_ui_tests.py); doubles/ has its own chained runner. Everything
-- else here is self-contained given only a real LOVE environment.
local SKIP={
  AbilityBridgeTests=true,DoublesItemUITests=true,DoublesPerformanceUITests=true,
  DoublesDisplayCompatTests=true,
}

local names={}
for _,path in ipairs({
  'AbilitiesResolverTests','AbilityDataTests','AbilityEffectsGen1Tests','AbilityEffectsGen2Tests',
  'AbilityGenerationBoundaryTests','AbilityWeatherTests',
  'ArenaExpansionParityTests','ArenaFidelity1925Tests','ArenaMoveFXIntegrationTests','ArenaSourceIntegrationTests',
  'AudioParityContractTests',
  'BattleAnimationRegression1929Tests','BattleAutoProgressTests','BattleExitBoundaryTests','BattleFieldVisibilityTests',
  'BossIntroCueTests',
  'CameraFXTests',
  'DeepColosseumFidelity1930Tests',
  'DoublesCameraDirectorTests','DoublesCoherentPresentationTests','DoublesCoordinatesTests',
  'DoublesImpactAlignmentTests','DoublesMovePresentationTests','DoublesPerformanceTests',
  'DoublesSendoutTests','DoublesSourceTimingIntegrationTests',
  'HSDScaleTests','HardCacheStorageQueueTests',
  'InformationMenuPerformanceTests',
  'MenuPrewarmBoundaryTests',
  'MoveFXAttackHandoffTests','MoveFXCacheReuseTests','MoveFXNativeIdentityTests',
  'MoveFXRetailParticleRuntimeTests','MoveFXSourceChainTests','MoveFXSweepTests','MoveFXTransitRegressionTests',
  'MovePresentationTests',
  'ParticleIntensityAlphaTests',
  'PokemonPresentationIntegrityTests','PokemonReactionQueueTests',
  'PyriteCameraSafetyTests',
  'ReleasePresentationTests',
  'RelicCameraSafetyTests','RelicChamberArenaTests','RelicForest360Fidelity1928Tests',
  'RelicOutskirtsLock1927Tests','RelicOutskirtsPresentationTests','RelicPresentationCleanupTests',
  'RelicRetailSource1926Tests','RelicVisualFidelity1931Tests',
  'TrainerBallReleaseTests','TrainerClockReactionTests','TrainerIdleContinuityTests',
  'TrainerNativeTrackTests','TrainerReactionEventsTests','TrainerSendoutCameraTests',
  'TrainerSourceCacheTests','TrainerStreamingTests',
  'WazaSfxMappingTests',
}) do names[#names+1]=path end

local pass,fail=0,{}
for _,name in ipairs(names) do
  if not SKIP[name] then
    local path='tests/'..name..'.lua'
    local ok,err=pcall(function() assert(loadfile(path))() end)
    if ok then pass=pass+1;print(path..' PASS')
    else fail[#fail+1]={path,err};print(path..' FAIL: '..tostring(err)) end
  end
end
print(('TOTAL: %d passed, %d failed (of %d files; %d skipped as UI-bridge/version-fixture tests run separately)')
  :format(pass,#fail,#names,#names-pass-#fail))
if #fail>0 then os.exit(1) end
