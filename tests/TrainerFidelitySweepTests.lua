-- Exercise the two real trainer draw paths. No source assets are distributed:
-- the material fixture models GC6E01's opaque body plus unlit XLU overlays.
local savedLove=love
local function up(fn,name,value,set)
  for i=1,100 do
    local n,v=debug.getupvalue(fn,i);if not n then break end
    if n==name then if set then debug.setupvalue(fn,i,value) end;return v end
  end
  error('missing upvalue '..name)
end
local function put(fn,name,value) return up(fn,name,value,true) end
local M=assert(loadfile('lib/TrainerMorph.lua'))({})
local function wraps(spec,g,id,s,t)
  local a,b=M.textureWrap(spec,g,id)
  assert(a==s and b==t,('wrong wrap %s/%s expected %s/%s'):format(a,b,s,t))
end
wraps({w=16,h=8},{renderFlags=0x60006013},'nascour','repeat','repeat')
wraps({w=16,h=8},{renderFlags=0x60006013},'wes','clamp','clamp')
wraps({w=16,h=8},{renderFlags=0x60006017},'nascour','clamp','clamp')
wraps({w=32,h=8},{renderFlags=0x60006013},'nascour','clamp','clamp')
wraps({w=16,h=8,wrapS=0,wrapT=2},{renderFlags=0x60006013},'nascour','clamp','mirroredrepeat')

-- Cache serialization must keep each TOBJ's sampler even when atlas pixels
-- share one path. Both canonical and packed metadata use this serializer.
local extractor=assert(loadfile('extract/TrainerExtractor.lua'))({})
local serialize=up(extractor.run,'cacheLua')
local model={bounds={min={0,0,0},max={1,1,1},center={.5,.5,.5}},groups={
  {texture={wrapS=1,wrapT=2},vertices={}},
  {texture={wrapS=0,wrapT=0},vertices={}},
}}
local paths={{path='same.rgba',w=16,h=8},{path='same.rgba',w=16,h=8}}
for _,bins in ipairs({false,{'first.f32','second.f32'}}) do
  local meta=assert(load(serialize({id='fixture'},model,paths,'fixture',bins or nil,0)))()
  assert(meta.groups[1].texture.wrapS==1 and meta.groups[1].texture.wrapT==2)
  assert(meta.groups[2].texture.wrapS==0 and meta.groups[2].texture.wrapT==0)
end

for _,file in ipairs({'PlayerTrainer.lua','Trainer.lua'}) do
  local uniforms,draws={},{}
  local images={}
  local depthWrite=true
  local function newMesh(format,rows)
    return {rows=rows,setTexture=function(self,img)self.texture=img end,
      setVertices=function(self,v)self.rows=v end,release=function()end}
  end
  love={graphics={
    newMesh=newMesh,
    newImage=function()
      local img={setFilter=function()end,setWrap=function(self,s,t)self.wrapS=s;self.wrapT=t end,release=function()end}
      images[#images+1]=img;return img
    end,
    newShader=function()return {send=function(_,name,value)uniforms[name]=value end,release=function()end} end,
    setShader=function()end,setColor=function()end,setMeshCullMode=function()end,setBlendMode=function()end,
    setDepthMode=function(_,write)depthWrite=write end,
    draw=function(mesh)
      draws[#draws+1]={mesh=mesh,material=uniforms.materialColor,useTexture=uniforms.useTexture,
        unlit=uniforms.unlit,depthWrite=depthWrite,opacity=uniforms.opacity}
    end,
  },image={newImageData=function()return {setPixel=function()end}end}}
  local cache=[[return {formatVersion=26,bounds={min={0,0,0},max={1,2,1}},groups={
    {material='glow',texture={path='shared.rgba',w=16,h=8},renderFlags=0x60006013,useDiffuseLighting=false,
      alpha=.4,xlu=true,noz=true,vertices={{101,0,0},{101,1,0},{101,0,1}}},
    {material='body',texture={path='shared.rgba',w=16,h=8,wrapS=0,wrapT=0},useDiffuseLighting=true,
      alpha=1,vertices={{202,0,0},{202,1,0},{202,0,1}}},
    {material='opaque trim',diffuse={.2,.3,.4},alpha=1,vertices={{303,0,0},{303,1,0},{303,0,1}}},
  }}]]
  local cfg={id='nascour',label='NASCOUR',cache='fixture.lua',directSource=true}
  local V={mod={},GeneratedAssets={read=function(path)return path=='fixture.lua' and cache or 'pixels' end},
    BattleSides={other=function(side)return side=='player' and 'enemy' or 'player' end},
    TrainerRoster={modelFor=function()return cfg end,playerModelFor=function()return cfg end},
    Mat4=assert(loadfile('lib/Mat4.lua'))(),TrainerRig=assert(loadfile('lib/TrainerRig.lua'))(),
  }
  V.TrainerPerformance=assert(loadfile('lib/TrainerPerformance.lua'))(V)
  V.TrainerMorph=assert(loadfile('lib/TrainerMorph.lua'))(V)
  local actor=assert(loadfile('lib/'..file))(V)
  put(actor.draw,'activeNow',true)
  local idle=up(actor.draw,'idleMotion');put(idle,'age',5)
  -- A first-frame shadow must not depend on having drawn a body beforehand.
  actor:drawShadow({},V.Mat4.identity(),{})
  assert(#draws==1,file..' did not draw the initial shadow')
  assert(draws[1].material[4]==1 and draws[1].useTexture==1 and draws[1].unlit==1,
    file..' shadow inherits uninitialized material state')
  actor:draw({},V.Mat4.identity(),{})
  assert(#draws==4,file..' lost a source material group')
  assert(draws[2].mesh.rows[1][1]==202 and draws[3].mesh.rows[1][1]==303 and draws[4].mesh.rows[1][1]==101,
    file..' draws translucent source groups before the opaque body')
  assert(draws[2].depthWrite and draws[3].depthWrite and not draws[4].depthWrite,
    file..' changed source depth-write flags')
  assert(draws[2].unlit==0 and draws[4].unlit==1,file..' applies studio lighting to source unlit glow')
  assert(draws[4].material[4]==.4,file..' lost authored material alpha')
  assert(draws[2].mesh.texture~=draws[4].mesh.texture,file..' shares one sampler across different TOBJ wrap states')
  assert(draws[2].mesh.texture.wrapS=='clamp' and draws[4].mesh.texture.wrapS=='repeat',file..' lost sampler modes')
  -- Draw the helper after a translucent material as well as before first use.
  actor:drawShadow({},V.Mat4.identity(),{})
  assert(draws[5].material[4]==1 and draws[5].useTexture==1 and draws[5].unlit==1,
    file..' shadow inherits the last translucent source material')
  actor:resetRuntime()
end

-- Sorting the visible material pass must not reindex native source tracks.
-- Each source group has unmistakably different bytes; ensure its own mesh
-- retains its corresponding animated positions/normals after pass ordering.
do
  local function mesh()
    return {attached={},setVertices=function(self,data)self.bytes=data.bytes end,
      attachAttribute=function(self,name,buffer,step,attribute)
        self.attached[name]={buffer=buffer,attribute=attribute}
      end,release=function()end}
  end
  love={graphics={newMesh=mesh},data={newByteData=function(bytes)
    return {bytes=bytes,release=function()end}
  end}}
  local clip={count=2,endFrame=1,groups={}}
  local sourceBytes={}
  for i=1,3 do
    clip.groups[i]={path='group_'..i..'.f32',vertices=3}
    sourceBytes[clip.groups[i].path]=string.rep(string.char(i),3*24*2)
  end
  local track={version=1,fps=60,roles={idle=clip}}
  local native=assert(loadfile('lib/TrainerMorph.lua'))({
    RuntimeMeshCache={readLua=function()return track end},
    GeneratedAssets={read=function(path)return sourceBytes[path]end},
  })
  local groups={{mesh=mesh(),xlu=true},{mesh=mesh()},{mesh=mesh()}}
  local drawOrder=native.materialOrder(groups)
  assert(drawOrder~=groups and drawOrder[3]==groups[1] and drawOrder[1]==groups[2],
    'material pass mutated the source group array')
  assert(native.loadTracks('fixture',groups)==track)
  native.bindPair(groups,{nativeAge=.005})
  for i,g in ipairs(groups) do
    for _,name in ipairs({'ActionAPosition','ActionBPosition','BreathPosition','LookPosition'}) do
      local bound=g.mesh.attached[name]
      assert(bound and bound.buffer.bytes:byte(1)==i,'source-track group index drifted on '..name)
    end
  end
  native.releaseTracks(groups)
end
love=savedLove
print('TrainerFidelitySweepTests: player/enemy material passes, helper isolation, sampler compatibility and cache metadata passed')
return true
