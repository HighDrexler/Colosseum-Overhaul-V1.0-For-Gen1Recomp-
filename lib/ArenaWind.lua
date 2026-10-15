

local W={none={0,0,0,0},particleCount=144}
W.vertex=[[
uniform float windTime;
uniform vec4 windInfo;
vec4 applyArenaWind(vec4 p,vec2 uv){
  if(windInfo.x<.5)return p;
  float phase=p.x*.033+p.z*.027;
  float gust=.62+.64*sin(windTime*.78539816-phase)
                  +.28*sin(windTime*.34361170+phase*.61);
  float tip=windInfo.x>1.5?clamp((windInfo.y-p.y)/windInfo.z,0.0,1.0)
                          :smoothstep(.18,.92,1.0-clamp(uv.y,0.0,1.0));
  float flutter=sin(windTime*5.69413668+phase*1.7+tip*7.0)*.18;
  float bend=(gust+flutter)*windInfo.w*tip;
  p.x+=bend;p.z+=bend*.36;
  return p;
}
]]
local LEAVES={
['cache/stages/relic_chamber/source/tex_051420_512x256_f14.rgba']=true,
['cache/stages/relic_chamber/source/tex_062420_256x128_f14.rgba']=true,
['cache/stages/relic_chamber/source/tex_061420_64x128_f14.rgba']=true,
}
function W.bind(g,id,path)
if id=='outdoor_wild'and (g.mode or 0)>3.1 and (g.mode or 0)<3.4 then return true end
if id=='relic_chamber'and LEAVES[path]then g.wind={1,0,1,4.2};return true end



local e=g.extent
if id=='water'and (path=='cache/stages/water/source/tex_0abb60_512x512_f14.rgba'
or path=='cache/stages/water/source/tex_08bb60_512x512_f14.rgba')
and e and math.abs((e[2]or 0)-36.278018)<.01
and g.mesh and g.mesh:getVertexCount()==12 then
local top
for i=1,12 do local _,y=g.mesh:getVertex(i);top=math.max(top or y,y)end
g.wind={2,top,e[2],6.0};return true
end
return false
end
local PROFILES={outskirts={.89,.77,.58,.12,0},orre={.86,.79,.65,.09,0},
outdoor={.47,.60,.24,.18,1},relic={.43,.58,.22,.17,1},
realgam={.86,.85,.72,.07,0},summit={.67,.63,.59,.10,0},open_water={.69,.85,.91,.10,0}}
local mesh,shader
local FORMAT={{'VertexPosition','float',3},{'WindSeed','float',4},{'WindSize','float',1},{'VertexTint','float',4}}
local VERTEX=[[
uniform mat4 vp;uniform mat4 model;uniform float windTime;uniform vec4 windColor;uniform float foliage;
attribute vec4 WindSeed;attribute float WindSize;attribute vec4 VertexTint;
varying vec4 tint;
vec4 position(mat4 transform_projection,vec4 p){
  float x=mod(WindSeed.x+windTime*16.0,768.0)-384.0;
  float y=mix(3.0+WindSeed.z*5.0,6.0+WindSeed.z*48.0,foliage);
  y+=sin(windTime*1.57079633+WindSeed.w)*1.1;
  float z=WindSeed.y+sin(windTime*.78539816+WindSeed.w)*9.0;
  float a=WindSeed.w+windTime*1.96349541;
  vec3 v=p.xyz*WindSize*mix(1.0,2.5,foliage);
  vec3 leaf=vec3(cos(a)*v.x-sin(a)*v.y,sin(a)*v.x+cos(a)*v.y,v.z);
  vec3 r=mix(vec3(v.x*4.0,v.y*.45,v.x*1.44),leaf,foliage);
  float edge=smoothstep(-384.0,-350.0,x)*(1.0-smoothstep(350.0,384.0,x));
  tint=windColor*VertexTint;tint.a*=edge;
  return vp*model*vec4(vec3(x,y,z)+r,1.0);
}
]]
local PIXEL=[[
uniform vec4 worldModulate;varying vec4 tint;
vec4 effect(vec4 color,Image tex,vec2 uv,vec2 p){
 return vec4(clamp(tint.rgb*worldModulate.rgb*2.0,0.0,1.0),tint.a)*color;
}
]]
local color={1,1,1,1}
function W.prepare(profile)
if not PROFILES[profile]or mesh then return end
local G=love.graphics;shader=shader or G.newShader(PIXEL,VERTEX)
local rows={};local corners={{-.5,-.5},{.5,-.5},{.5,.5},{-.5,-.5},{.5,.5},{-.5,.5}}
for i=1,W.particleCount do
local x=((i*.61803398875)%1)*768;local z=(((i*.41421356237)%1)-.5)*760
local h=(i*.27182818)%1;local phase=(i*.347111)%1*math.pi*2
local size=.45+(i%7)*.07
for _,v in ipairs(corners)do rows[#rows+1]={v[1],v[2],0,x,z,h,phase,size,1,1,1,.55+(i%5)*.09}end
end
mesh=G.newMesh(FORMAT,rows,'triangles','static')
end
function W.draw(profile,vp,model,time,modulation,depth)
local p=PROFILES[profile];if not p or not mesh then return end
local G=love.graphics;G.setShader(shader);G.setColor(1,1,1,1);G.setMeshCullMode('none')
G.setBlendMode('alpha','alphamultiply');if depth then G.setDepthMode('lequal',false)else G.setDepthMode()end
color[1],color[2],color[3],color[4]=p[1],p[2],p[3],p[4]
shader:send('vp','row',vp);shader:send('model','row',model);shader:send('windTime',(tonumber(time)or 0)%128)
shader:send('windColor',color);shader:send('foliage',p[5]);shader:send('worldModulate',modulation)
G.draw(mesh)
end
function W.reset()
if mesh then mesh:release();mesh=nil end
if shader then shader:release();shader=nil end
end
function W.status(profile)
local active=PROFILES[profile]~=nil
return {ready=mesh~=nil,active=active,particles=active and W.particleCount or 0,draws=active and mesh and 1 or 0,clock='real-time',cacheWrites=0}
end
W._test={profiles=PROFILES,particleVertex=VERTEX,particlePixel=PIXEL}
return W
