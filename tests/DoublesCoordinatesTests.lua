local C=assert(loadfile('lib/ArenaCatalog.lua'))()
local P=assert(loadfile('lib/doubles/Presenter.lua'))({})
local CSM=assert(loadfile('lib/CurrentSpriteModels.lua'))({})
local count=0
for name,def in pairs(C.status().definitions)do if def.pokemon then
 local k=def.figureScale or .38
 local ctx={groundY=0,arena={figureScale=k,player={def.pokemon.player[1]/k,def.pokemon.player[2]/k},enemy={def.pokemon.enemy[1]/k,def.pokemon.enemy[2]/k}},services={figureScale=k,project=function(x,y,z)return x*k,y*k end}}
 for _,id in ipairs({'player-left','player-right','enemy-left','enemy-right'})do
  local x,z=P.anchor(ctx,id);local ax,az=P.actorAnchor(ctx,id)
  assert(math.abs(x-ax*k)<1e-8 and math.abs(z-az*k)<1e-8,name..': mismatched arena/mesh landing')
  local px,py=CSM:projectWazaWorld(ctx,{ax,3.85/k,az})
  assert(math.abs(px-x)<1e-8 and math.abs(py-3.85)<1e-8,name..': effect projected through figure scale twice')
  local side=id:match('^player') and 'player' or 'enemy';local other=side=='player' and 'enemy' or 'player'
  local trainer=def.trainers and def.trainers[side]
  if trainer then
   local a,b=def.pokemon[side],def.pokemon[other]
   assert((x-trainer[1])*(b[1]-a[1])+(z-trainer[2])*(b[2]-a[2])>0,name..': ball flies away from fight')
  end
  local camera=def.camera
  if camera then
   local s={core={currentEvent={kind='send',slot=id}},actors={}}
   local pose=P.camera({eye={camera.side,camera.height,camera.back},focus={camera.lookX or 0,camera.lookY or 5,0},fov=.8},s,ctx)
   assert(math.abs(pose.focus[1]-x)<1e-8 and math.abs(pose.focus[3]-z)<1e-8,name..': camera misses release')
  end
 end
 count=count+1
end end
assert(count>=10)
print('DoublesCoordinatesTests: '..count..' maps, four slots each; throw, mesh, particles and reveal camera agree')
