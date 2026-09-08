local function up(fn,name,value,set)
 for i=1,100 do local n,v=debug.getupvalue(fn,i);if not n then break end;if n==name then if set then debug.setupvalue(fn,i,value) end;return v end end
 error('missing '..name)
end
local enemy={active=true,age=.4,phase=.79,ball={4,5,6}}
local player={active=false,age=.2,phase=.31,ball={7,8,9}}
local C=assert(loadfile('lib/Camera.lua'))({Trainer={sendoutStatus=function()return enemy end},PlayerTrainer={sendoutStatus=function()return player end}})
local live=up(C.shot,'liveSendoutShot')
up(live,'eventShot',function()return {eye={0,0,0},focus={0,0,0},fov=1} end,true)
up(live,'trainerPoint',function()return {1,2,3} end,true)
local p,side=live({},{})
assert(side=='enemy' and math.abs(p.focus[1]-4)<1e-8,'camera misses active enemy ball')
player.active=true;p,side=live({},{})
assert(side=='player' and p.focus[1]==1,'wind-up camera does not stay on trainer')
player.active=false;enemy.active=false;assert(live({},{})==nil,'finished throw retains camera ownership')
print('Trainer sendout camera tests passed')
