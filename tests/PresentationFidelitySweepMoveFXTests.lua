local checks=0
local function check(v,label) checks=checks+1;assert(v,label) end
local function near(a,b,label) check(math.abs(a-b)<1e-7,label) end
local draws,meshes,shaders={}, {}, {}
local activeShader
local function noop()end
local g={setColor=noop,setBlendMode=noop,setDepthMode=noop,push=noop,pop=noop,
 setShader=function(s)activeShader=s end,
 newShader=function(vertex,pixel)
  local s={uniforms={},pixel=pixel};function s:send(name,value)self.uniforms[name]=value end
  shaders[#shaders+1]=s;return s
 end,
 newMesh=function(format,capacity)
  check(type(capacity)=='number','trail allocated a fresh exact-size vertex buffer')
  local m={capacity=capacity};function m:setVertices(v)check(#v<=self.capacity,'trail overflow');self.vertices=v end
  function m:setDrawRange(a,b)self.range={a,b}end
  function m:setTexture(t)self.texture=t end
  function m:release()self.released=true end
  meshes[#meshes+1]=m;return m
 end,
 draw=function(item)draws[#draws+1]={item=item,shader=activeShader}end}
love={graphics=g}
local P=assert(loadfile('lib/CurrentSpriteModels.lua'))({})
local image={getDimensions=function()return 16,16 end,setFilter=noop}
local context={services={project=function(x,y,z)return x*10,100-y*10+z end}}
local fx={sourceWorld={0,0,0},right={1,0,0},up={0,1,0},forward={0,0,1},sourceUnit=1,referenceVisualHeight=10}
local p={prim={255,64,32,0},env={0,128,255,255},primEnv=true,alphaScale=.5,
 size=1,position={5,1,0}}
local prim,env=P._test.particleColors(p)
near(prim[4],0,'source transparent primary endpoint changed')
near(env[4],.5,'particle opacity did not scale the full Prim/Env gradient')
near(env[3],1,'source blue environment endpoint was recolored')
local shader=g.newShader('','');local entry={image=image,spec={fmt=6}}
check(P._test.drawParticleAt(g,shader,context,fx,p,entry,p.position,1),'visible environment gradient culled by transparent primary')
near(shader.uniforms.cbePrim[4],0,'transparent primary was replaced by environment alpha')
near(shader.uniforms.cbeEnv[4],.5,'environment opacity was lost on upload')
p.alphaScale=0
check(not P._test.drawParticleAt(g,shader,context,fx,p,entry,p.position,1),'fully transparent gradient submitted')
p.alphaScale=1;p.prim[4]=255
local history={{4,1,0},{3,1,0},{2,1,0},{1,1,0}}
check(P._test.drawTrailRibbon(g,shader,context,fx,p,entry,history),'source-textured trail did not draw')
local mesh=p._cbeTrailMesh
check(mesh.range[2]==10,'trail draw range did not match current history')
check(P._test.drawTrailRibbon(g,shader,context,fx,p,entry,{{4,1,0},{3,1,0}}),'shortened trail failed')
check(mesh==p._cbeTrailMesh and #meshes==1,'normal trail growth/shrink churns GPU buffers')
check(mesh.range[2]==6,'old trailing vertices remained visible after shorter history')
local large={};for i=1,20 do large[i]={5-i,1,0} end
check(P._test.drawTrailRibbon(g,shader,context,fx,p,entry,large),'expanded trail failed')
check(mesh.released and p._cbeTrailMesh~=mesh,'expanded ribbon leaked its replaced GPU buffer')
-- Type-2 colour keys are independent of whether the source group is textured.
local basis={origin={0,0,0},target={0,0,10},right={1,0,0},up={0,1,0},forward={0,0,1},modelTargetSpan=10}
local H=assert(loadfile('lib/WazaHandlers.lua'))({CurrentSpriteModels={wazaBasis=function()return basis end}})
local asset={cache='fixture-model',bounds={min={0,0,0},max={1,1,1}}}
H.modelCache[asset.cache]={bounds=asset.bounds,groups={{mesh={},image=image,diffuse={.8,.7,.6},alpha=.5}}}
local instance={frame=5,side='player',target='enemy',role='attack',spec={moveId=1}}
H.models.fixture={asset=asset,instance=instance,entry={},effectRec={instance=instance,startedFrame=0,duration=10,
 effect={keys={{from={255,128,0,128},to={0,128,255,128},duration=10}}}}}
local vp={1,0,0,0,0,1,0,0,0,0,1,0,0,0,0,1}
check(H.drawWorld({services={vp=vp}}),'source model effect failed to render')
local modelShader=draws[#draws].shader
near(modelShader.uniforms.effectTint[1],.5,'source red key absent on textured effect')
near(modelShader.uniforms.effectTint[2],128/255,'source green key absent on textured effect')
near(modelShader.uniforms.effectTint[3],.5,'source blue key absent on textured effect')
near(modelShader.uniforms.materialColor[1],.8,'source diffuse was tinted twice')
near(modelShader.uniforms.materialColor[4],.5*128/255,'source material/key alpha changed')
check(modelShader.pixel:find('mix(materialColor.rgb,t.rgb,useTexture)*effectTint',1,true)~=nil,'shader discards tint for textured groups')
check(H.drawAsset({},asset,vp,vp,0),'standalone source asset failed')
for i=1,3 do near(modelShader.uniforms.effectTint[i],1,'capture asset inherited preceding move tint')end
print('PresentationFidelitySweepMoveFXTests: '..checks..' assertions passed')
return true
