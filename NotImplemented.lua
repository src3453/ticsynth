--[[
function wfmul(a,b)
local tmp={}
    for i=1,32 do
        tmp[i] = a[i]*b[i]
    end
end
return tmp
end
function wfsub(wf)
local tmp=wf[1]
for i=2,#wf do
    for j=1,32 do
        tmp[i] = (tmp[i]or 0)-wf[i][j]
    end
end
return tmp
end
function wfdiv(wf)
local tmp=wf[1]
for i=2,#wf do
    for j=1,32 do
        tmp[i] = (tmp[i]or 0)/wf[i][j]
    end
end
return tmp
end
]]