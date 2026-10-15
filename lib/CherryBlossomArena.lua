

local V=...
local C={revision=1}
local ROOT='assets/cbe/cherry_blossom/'
local meta,shader,petalShader
local FORMAT={{'VertexPosition','float',3},{'VertexTexCoord','float',2},
{'VertexTint','float',4},{'VertexNormal','float',3}}
local PETAL_FORMAT={{'VertexPosition','float',3},{'PetalSeed','float',4},
{'PetalSize','float',1},{'VertexTint','float',4}}
-- Shared materialMode precision must agree on GLES; avoid reserved GLSL names.
local VERTEX=[[
uniform mat4 vp;
uniform mat4 model;
uniform float sceneTime;
uniform mediump float materialMode;
attribute vec4 VertexTint;
attribute vec3 VertexNormal;
varying vec4 tint;
varying vec3 world;
varying vec3 normal;
vec4 position(mat4 transform_projection,vec4 p){
  tint=VertexTint;
  if(materialMode>1.5){
    float tip=1.0-clamp(VertexTexCoord.y,0.0,1.0);
    float phase=p.x*.033+p.z*.027;
    float gust=.62+.64*sin(sceneTime*.78539816-phase)+.28*sin(sceneTime*.34361170+phase*.61);
    float flutter=sin(sceneTime*5.69413668+phase*1.7+tip*7.0)*.18;
    float bend=(gust+flutter)*3.8*tip;
    p.x+=bend;p.z+=bend*.36;
  }
  vec4 w=model*p;world=w.xyz;
  normal=normalize((model*vec4(VertexNormal,0.0)).xyz);
  return vp*w;
}
]]
local PIXEL=[[
uniform mediump float materialMode;
uniform vec3 cameraEye;
uniform vec4 worldModulate;
varying vec4 tint;
varying vec3 world;
varying vec3 normal;
vec4 effect(vec4 color,Image tex,vec2 uv,vec2 p){
  vec4 t=Texel(tex,uv);
  if(materialMode>1.5 && t.a<.38)discard;
  vec3 c=t.rgb*tint.rgb;
  if(materialMode>=0.0){
    vec3 n=normalize(normal);
    float sun=max(dot(n,normalize(vec3(-.45,.82,.35))),0.0);
    float light=.67+.32*sun;
    if(materialMode>1.5)light=.82+.16*abs(dot(n,normalize(vec3(-.45,.82,.35))));
    c*=vec3(1.015,.996,.975)*light;
    if(materialMode<.5){
      float groundPattern=sin(world.x*.12+world.z*.08)*sin(world.z*.11-world.x*.06);
      c*=.94+.06*groundPattern;
    }
    float distance100=length((world-cameraEye)*.01);
    float haze=smoothstep(.75,2.65,distance100)*(materialMode>1.5?.38:.69);
    c=mix(c,materialMode>1.5?vec3(.93,.88,.90):vec3(.83,.88,.83),haze);
  }
  return vec4(clamp(c*worldModulate.rgb*2.0*color.rgb,0.0,1.0),color.a);
}
]]
local PETAL_VERTEX=[[
uniform mat4 vp;
uniform mat4 model;
uniform float sceneTime;
attribute vec4 PetalSeed;
attribute float PetalSize;
attribute vec4 VertexTint;
varying vec4 tint;
varying float fade;
vec4 position(mat4 transform_projection,vec4 p){
  float t=sceneTime;
  float y=140.0-mod(PetalSeed.z+t*4.375,140.0);
  float drift=t*.049087385+PetalSeed.w;
  float x=mod(PetalSeed.x+384.0+t*12.0,768.0)-384.0;
  vec3 center=vec3(x,y,PetalSeed.y+14.0*sin(drift*2.0));
  float a=PetalSeed.w+t*.39269908;
  float flutter=sin(t*.78539816+PetalSeed.w)*.70;
  vec3 v=p.xyz*PetalSize;
  vec3 r=vec3(cos(a)*v.x-sin(a)*v.y,sin(a)*v.x+cos(a)*v.y,v.z);
  r=vec3(r.x,cos(flutter)*r.y-sin(flutter)*r.z,sin(flutter)*r.y+cos(flutter)*r.z);
  fade=smoothstep(0.0,6.0,y)*(1.0-smoothstep(130.0,140.0,y));
  tint=VertexTint;
  return vp*model*vec4(center+r,1.0);
}
]]
local PETAL_PIXEL=[[
uniform vec4 worldModulate;
varying vec4 tint;
varying float fade;
vec4 effect(vec4 color,Image tex,vec2 uv,vec2 p){
  return vec4(tint.rgb*worldModulate.rgb*2.0*color.rgb,tint.a*fade*.86*color.a);
}
]]
local NEUTRAL={128/255,128/255,128/255,1}
local function read(path)
if not(V.mod and V.mod.read)then return nil,'package reader unavailable'end
return V.mod:read(path)
end
function C.metadata()
if meta then return meta end
local bytes,why=read(ROOT..'scene.lua');if not bytes then return nil,why end
local chunk,err=load(bytes,'@'..ROOT..'scene.lua');if not chunk then return nil,err end
local ok,value=pcall(chunk)
if not(ok and type(value)=='table'and value.revision==C.revision and type(value.groups)=='table')then
return nil,'invalid cherry blossom scene metadata'
end
meta=value;return meta
end
function C.available()return C.metadata()~=nil end
local function textureBytes(row)
return assert(V.PackageRGBA.read(V.mod,row.texture,row.textureSize,row.textureSize))
end
function C.release(scene)
if scene and scene.petalMesh then scene.petalMesh:release();scene.petalMesh=nil end
end
function C.load()
local metadata,why=C.metadata();if not metadata then return nil,why end
local g=love.graphics
local scene={opaque={},cutout={},crowd={},translucent={},additive={},textures={},
source=metadata.source,cachePath=ROOT..'scene.lua',packaged=true,runtimeSidecar=true,
vertexCount=0,petalCount=metadata.petalCount,treeCount=metadata.treeCount}
local function cleanup()
C.release(scene)
for _,bucket in ipairs{scene.opaque,scene.cutout}do for _,row in ipairs(bucket)do row.mesh:release()end end
for _,row in pairs(scene.textures)do row.image:release()end
end
local ok,err=pcall(function()
if not shader then shader=g.newShader(PIXEL,VERTEX)end
if not petalShader then petalShader=g.newShader(PETAL_PIXEL,PETAL_VERTEX)end
for _,row in ipairs(metadata.groups)do
local key=row.texture or 'white';local texture=scene.textures[key]
if not texture then
local data
if row.texture then data=love.image.newImageData(row.textureSize,row.textureSize,'rgba8',textureBytes(row))
else data=love.image.newImageData(1,1);data:setPixel(0,0,1,1,1,1)end
local image=g.newImage(data,{mipmaps=true});data:release()
texture={image=image};scene.textures[key]=texture
image:setFilter('linear','linear')
if not row.cutout then
image:setWrap('repeat','repeat')
end
if image:getMipmapCount()>1 then image:setMipmapFilter('linear')end
end
local mesh,count
mesh,why,count=V.RuntimeMeshCache.meshFromBytes(FORMAT,assert(read(row.mesh)),12,'static')
assert(mesh,why)
local bucket=row.cutout and scene.cutout or scene.opaque
bucket[#bucket+1]={mesh=mesh,mode=row.mode}
assert(count==row.vertices,'cherry mesh vertex count mismatch')
mesh:setTexture(texture.image)
scene.vertexCount=scene.vertexCount+count
end
local mesh,count
mesh,why,count=V.RuntimeMeshCache.meshFromBytes(PETAL_FORMAT,assert(read(ROOT..'petals.f32')),12,'static')
assert(mesh,why)
scene.petalMesh=mesh
assert(count==metadata.petalVertices,'cherry petal vertex count mismatch')
end)
if not ok then cleanup();return nil,tostring(err)end
return scene
end
function C.draw(scene,bucket,vp,model,pose,time,modulate,depth)
local g=love.graphics
g.setShader(shader);g.setColor(1,1,1,1);g.setMeshCullMode('none')
shader:send('vp','row',vp);shader:send('model','row',model)
shader:send('sceneTime',(tonumber(time)or 0)%128)
shader:send('cameraEye',pose.eye);shader:send('worldModulate',modulate or NEUTRAL)
for _,row in ipairs(scene[bucket])do
if depth==false then g.setDepthMode()else g.setDepthMode('lequal',row.mode>=0)end
shader:send('materialMode',row.mode);g.draw(row.mesh)
end
end
function C.drawPetals(scene,vp,model,time,modulate,depth)
local g=love.graphics
g.setShader(petalShader)
if depth==false then g.setDepthMode()else g.setDepthMode('lequal',false)end
g.setMeshCullMode('none');g.setBlendMode('alpha','alphamultiply');g.setColor(1,1,1,1)
petalShader:send('vp','row',vp);petalShader:send('model','row',model)
petalShader:send('sceneTime',(tonumber(time)or 0)%128)
petalShader:send('worldModulate',modulate or NEUTRAL);g.draw(scene.petalMesh)
end
function C.reset()
if shader then shader:release();shader=nil end
if petalShader then petalShader:release();petalShader=nil end
meta=nil
end
C._test={vertex=VERTEX,pixel=PIXEL,petalVertex=PETAL_VERTEX,petalPixel=PETAL_PIXEL,textureBytes=textureBytes}
return C
