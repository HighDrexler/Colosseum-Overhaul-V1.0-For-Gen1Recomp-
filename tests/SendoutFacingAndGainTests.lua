local root=os.getenv('CBE_DOUBLES_MOD_DIR') or '.'
local checks=0
local function yes(x,m)checks=checks+1;assert(x,m)end
local function near(a,b,m)yes(math.abs(a-b)<1e-8,m..': '..tostring(a)..' / '..tostring(b))end
local function load(p,v)return assert(loadfile(root..'/'..p))(v)end
local function up(fn,name,value,set)
 for i=1,100 do local n,v=debug.getupvalue(fn,i);if not n then break end
  if n==name then if set then debug.setupvalue(fn,i,value)end;return v end
 end;error('missing upvalue '..name)
end
local function put(fn,name,v)return up(fn,name,v,true)end
local V={Mat4=load('lib/Mat4.lua'),TrainerRig=load('lib/TrainerRig.lua'),TrainerPerformance=load('lib/TrainerPerformance.lua',{}),
 TrainerMorph={dense=function()return false end},BattleSides={other=function()end}}
local player=load('lib/PlayerTrainer.lua',V);local enemy=load('lib/Trainer.lua',V);V.PlayerTrainer=player
local pp=up(up(player.drawBall,'ballPose'),'normalThrowBallPose');local ep=up(enemy.drawBall,'ballPose')
put(pp,'performanceId',function()return 'red'end);put(pp,'releaseAnchor',function()return {3,4,37}end)
put(ep,'performanceId',function()return 'dakim'end);put(ep,'idleMotion',function()return {}end)
put(player.beginSendout,'activeNow',true);put(enemy.beginSendout,'activeNow',true)
local profiles={
 {pokemon={player={0,60},enemy={0,-60}}},
 {pokemon={player={31,-14},enemy={-29,32}}},
 {pokemon={player={-32,-10},enemy={27,-10}}},
}
for _,profile in ipairs(profiles)do
 player:setArenaProfile(profile);enemy:setArenaProfile(profile)
 for _,side in ipairs{'player','enemy'}do
  local obj=side=='player' and player or enemy;local pose=side=='player' and pp or ep
  local id=side=='player' and 'red' or 'dakim';local kind=side=='player' and 'throw' or 'sendout'
  local own=profile.pokemon[side];local other=profile.pokemon[side=='player' and 'enemy' or 'player']
  local dx,dz=other[1]-own[1],other[2]-own[2];local len=math.sqrt(dx*dx+dz*dz)
  for _,lane in ipairs{-1,1}do
   obj:beginSendout({lane*17,3.85,lane*23},{dx,dz})
   local d=V.TrainerPerformance.duration(id,kind)
   for _,phase in ipairs{.2,.31,.5,.79}do
    put(pose,'actionAge',phase*d);local bp=assert(pose())
    near(math.sin(bp.yaw),dx/len,'throw front equals Pokémon +Z on X');near(math.cos(bp.yaw),dz/len,'throw front equals Pokémon +Z on Z')
    local m=player._test.sourceBallModel({bounds={min={-.5,-.5,-.5},max={.5,.5,.5}}},bp)
    local scale=math.sqrt(m[3]^2+m[11]^2)
    near(m[3]/scale,dx/len,'retail button orientation X');near(m[11]/scale,dz/len,'retail button orientation Z')
   end
  end
  -- No explicit doubles forward: singles must inherit the same actor axis.
  obj:clearSendoutTarget();obj:beginSendout();put(pose,'actionAge',.5*V.TrainerPerformance.duration(id,kind))
  local bp=assert(pose());near(math.sin(bp.yaw),dx/len,'single player/enemy arena facing X');near(math.cos(bp.yaw),dz/len,'single player/enemy arena facing Z')
 end
end
-- Opponent source draw uses the exact shared source path, not procedural spin.
local called=false;V.PlayerTrainer={drawSendoutBall=function(_,ctx,vp,p,bp)called=bp.kind=='sendout';return true end}
enemy:drawBall({}, {}, {});yes(called,'enemy uses shared source prop draw')
-- Release-only gain does not compound on clone-less implementations or change
-- ordinary attack SFX which happen to reuse the same cached sample.
local function source(clones)
 local s={volume=1};function s:setVolume(v)self.volume=v end;function s:play()self.plays=(self.plays or 0)+1 end
 function s:isPlaying()return true end
 if clones then function s:clone()return source(false)end end
 return s
end
for _,clones in ipairs{false,true}do
 local A=load('lib/WazaAudioRuntime.lua',{});local template=source(clones);A.cache[139]=template;A.readyForSpec=function()return true end
 local e={soundId=139,index=1,phase='open'}
 for i=1,4 do A:start({}, {serial=i,spec={stem='monsterball'},presentation='release'},e);near(A.active[i..':1'].source.volume,.85,'15 percent quieter release, stable on reuse')end
 A:start({}, {serial=5,spec={stem='tackle'}},{soundId=139,index=1,phase='attack'})
 near(A.active['5:1'].source.volume,1,'non-release SFX unchanged')
 if clones then near(template.volume,1,'cloned playback never mutates template gain')end
end
print('SendoutFacingAndGainTests: '..checks..' checks passed')
