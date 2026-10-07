






local V=...
local D={version=1,lines={},dirty=false,lastFlush=0,sessions=0,MAX=600}
D.PATH='build/battle_fx_diagnostics.txt'

local function now()
local ok,t=pcall(function() return love and love.timer and love.timer.getTime() end)
return ok and tonumber(t) or os.clock()
end
local function fmt(v)
if type(v)=='number' then
if v~=v then return 'nan' end
if math.floor(v)==v and math.abs(v)<1e9 then return tostring(v) end
return ('%.3f'):format(v)
end
if type(v)=='table' then
local out={}
for i=1,math.min(4,#v) do out[#out+1]=fmt(v[i]) end
return '{'..table.concat(out,',')..'}'
end
local s=tostring(v):gsub('[\r\n]+',' | ')
if #s>220 then s=s:sub(1,220)..'...' end
return s
end

function D.enabled()
local S=V and V.BattleSettings
if S and type(S.prefs)=='function' then
local ok,p=pcall(S.prefs,V.mod and V.mod.game)
if ok and type(p)=='table' and p.fxDiagnostics==false then return false end
end
return true
end

function D.note(kind,fields)
if not D.enabled() then return end
local parts={('%9.3f'):format(now()),tostring(kind)}
if type(fields)=='table' then
local keys={};for k in pairs(fields) do keys[#keys+1]=tostring(k) end;table.sort(keys)
for _,k in ipairs(keys) do parts[#parts+1]=k..'='..fmt(fields[k]) end
elseif fields~=nil then parts[#parts+1]=fmt(fields) end
D.lines[#D.lines+1]=table.concat(parts,' ')
while #D.lines>D.MAX do table.remove(D.lines,1) end
D.dirty=true
end

function D.flush(force)
if not D.dirty then return false end



if not force and V.Gen3Runtime and V.Gen3Runtime.active then return false end
local t=now()
if not force and t-D.lastFlush<1.0 then return false end
local mod=V and V.mod;local cache=mod and mod.cache
if not (cache and type(cache.write)=='function') then return false end
local version=(V.VERSION or (mod and mod.version) or '?')
local body='Colosseum Overhaul battle FX diagnostics '..tostring(version)..'\n'..table.concat(D.lines,'\n')..'\n'
local ok,wrote=pcall(cache.write,cache,D.PATH,body)
D.lastFlush=t
if ok and wrote then D.dirty=false;return true end
return false
end

function D.battleStart(ctx)
D.sessions=D.sessions+1
local b=ctx and ctx.battle
D.note('battle.start',{session=D.sessions,generation=b and b.__cbeGeneration,double=b and b.double==true,
arena=ctx and ctx.arena and ctx.arena.id})
end


function D.world(world)
local out={models=0,effects=0,particles=0,surfaces=''}
if type(world)~='table' then return out end
for _ in pairs(world.models or {}) do out.models=out.models+1 end
local surf={}
for _,rec in pairs(world.effects or {}) do
out.effects=out.effects+1
if tonumber(rec.family)==0 then surf[#surf+1]='m'..tostring(rec.effect and rec.effect.mode) end
end
out.surfaces=table.concat(surf,'+')
for _,fx in ipairs(world.particles or {}) do
local n=0;for _,p in ipairs(fx.vm and fx.vm.particles or {}) do if p.alive~=false then n=n+1 end end
out.particles=out.particles+n
end
return out
end


function D.sample(track,kind,extra,every)
if not D.enabled() or type(track)~='table' then return end
track.__fxDiagAge=(track.__fxDiagAge or 0)
local t=now()
if track.__fxDiagLast and t-track.__fxDiagLast<(every or .25) then return end
track.__fxDiagLast=t
local w=D.world(track.world)
local inst=track.instance
local H=V.WazaHandlers
local fields={frame=inst and inst.frame,done=inst and inst.done,models=w.models,effects=w.effects,
particles=w.particles,surfaces=w.surfaces,drew=track.__fxDiagDrew,drawError=H and H.drawError,
renderFaults=H and H.renderFaults}
for k,v in pairs(extra or {}) do fields[k]=v end
D.note(kind,fields)
end

function D.status()
return {lines=#D.lines,path=D.PATH,sessions=D.sessions,enabled=D.enabled()}
end
return D
