intensity=0
freq=3.0
modint=1.0
ticopl_frame = 0
syn_enable = {true, true, true, true}
vols,sfx_frame = {0,0,0,0},{0,0,0,0}
function ticsyn()
function peekwfrl(index)
local out
f = string.format
out = {}
local j=1
for i=2*0xff9c+index*36+4, 2*0xff9c+(index)*36+35 do
u = peek4(i)
out[j] = u
j=j+1
end
return out
end
function peekwfr(index)
    local out
    f = string.format
    out = ""
    for i=0xff9c+index*18+2, 0xff9c+(index)*18+17 do
    u = peek(i)
    out = out .. f("%02x",u)
    end
    return out
    end
function pokewfr(index,data)
local j
j = 1
for i=0xff9c+index*18+2, 0xff9c+(index)*18+17 do
poke(i,tonumber(string.sub(data,j,j+1),16))
j = j + 2
end
end
sub = string.sub
function nclip(num,min,max)if num==nil or tostring(num)=="nan" then return 0 else return math.min(math.max(num,min),max)end end
function fm(int,freq,freq2,ticopl_frame,theta,vol)
    f = string.format
    local tmp = carrier or {}
    local j=1
    local theta,vol = theta or 0,vol or 1
    for i = ticopl_frame, ticopl_frame+32 do
    tmp[j]=nclip(vol*math.sin(theta+math.rad(i*(360/32)*freq2+math.sin(math.rad(i*(360/32)*freq))*(int)))*8+8,0,15)
    j=j+1
    end
    return tmp
end
    function fm2(carrier,int,freq,timestate)
        --timestate = timestate or 1
        local f = math.floor
        local tmp = {}
        local j=1
        for i = timestate, timestate+32 do
      --j = tonumber(sub(peekwf(operator),i,i),16)
            --tmp = tmp .. f("%01x",math.floor((tonumber(sub(peekwf(carrier),i,i),16) + tonumber(sub(peekwf(operator),i,i),16))%16))
            local res = (i-timestate+1)+(math.sin(math.rad(i*(360/32)*freq))*(int/360))*16%32+1
            local val = carrier[1+f(res)%32]+(carrier[1+f(res+1)%32]-carrier[1+f(res)%32])*res%1
            tmp[j] = nclip(val,0,15)
            j=j+1
        end
        return tmp
    end
    function wfsum(wf)
        local tmp={}
        for j=1,#wf do
            for i=1,32 do
            tmp[i] = (tmp[i]or 0)+wf[j][i]
            end
        end
        return tmp
    end
    function normalize(wf)
        local tmp={}
        local mx,mn=math.max(table.unpack(wf)),math.min(table.unpack(wf))
       	for i=1,32 do
            tmp[i] = nclip((wf[i]-mn)*16/((mx-mn)+0.01),0,15)
        end
        return tmp
    end
function filter(input,cutoff,q)
local sin,cos=math.sin,math.cos
local filt_q=q or 0.707106781
local omega= 2.0 *3.14159265*cutoff/32
local alpha=sin(omega)/(2.0*filt_q) 
local a0=  1.0 +alpha
local a1= -2.0 *cos(omega)
local a2=  1.0 -alpha
local b0=( 1.0 -cos(omega))/2.0
local b1=  1.0 -cos(omega)
local b2=( 1.0 -cos(omega))/2.0
local output = {}
local in1,in2,out1,out2=input[1],input[1],input[1],input[1]
for i=1,#input*3 do
output[i]=nclip(b0/a0*input[i%#input+1]+b1/a0*in1+b2/a0*in2-a1/a0*out1-a2/a0*out2,0,15)
in2= in1   -- 2つ前の入力信号を更新
in1 = input[i%#input+1]  -- 1つ前の入力信号を更新
out2 = out1  -- 2つ前の出力信号を更新
out1 = output[i] 
end
tmp = {}
for i=1,#input do
    tmp[i] = output[i+#input]
end
return tmp
end
function window(input,freq)
    local out={}
    freq=freq or 1
    for i=0,31 do
        win = nclip(2*math.sin(math.rad(i/32*180*freq)),0,1)

        out[i+1] = (input[i+1])*win

    end
    return out
end
function window2(after,before)
    local diff={}
    for i=1,32 do
    diff[i] = after[i]-before[i]
    end
    diff = window(diff,1)
    for i=1,32 do
    after[i] = before[i]+diff[i]
    end
    return after
end
function wfmul(wf)
local tmp=wf[1]
for i=2,#wf do
    for j=1,32 do
        tmp[i] = (tmp[i]or 0)*wf[i][j]
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
function wfmod(wf,b)
local tmp=wf[1]
if b==nil then
for i=2,#wf do
    for j=1,32 do
        tmp[i] = (tmp[i]or 0)%wf[i][j]
    end
end
else
    for j=1,32 do
        tmp[i] = (wf[j] or 0)%b
    end
end
return tmp
end
wft={
        SQU=0,
        TRI=1,
        SAW=2,
        SIN=3
    }
function psg(wftype,vol,freq,duty,phase)
    duty=duty or 15
    freq=freq or 1
    vol=vol/16 or 1
    phase=math.floor(phase or 0)
    --freq=freq/2
    tmp={}
    
    for i=1,32 do
        if wftype==wft.SQU then
            tmp[(phase+i)%32+1]=(math.max(math.min((duty)-(i-1),1),0)//1)*15
        end if wftype==wft.TRI then
            tmp[(phase+i)%32+1]=math.abs((i*freq%31)-15)*vol
        end if wftype==wft.SAW then
            tmp[(phase+i)%32+1]=(i*freq%31)*vol/2
        end if wftype==wft.SIN then
            tmp[(phase+i)%32+1]=math.sin(math.rad((i*freq)*(360/32)))*vol*15
        end
    end
    return tmp
end
function wfclip(wf,min,max)
local tmp=wf
for i=1,#wf do
    for j=1,32 do
        tmp[i] = nclip(wf[i],min,max)
    end
end
return tmp
end

f = string.format
function synthesis()
local intensity=modint*9
if btnp(0,20,2) then modint=modint+0.1 end
if btnp(1,20,2) then modint=modint-0.1 end
if btnp(2,20,2) then freq=freq-0.1 end
if btnp(3,20,2) then freq=freq+0.1 end
--cls(13)
--fm2(1,0,frq,frq2,ticopl_frame)
--for i=0,15 do
--pokewf(i,peekwf(0))end
for ch=0,3 do
if syn_enable[ch+1] then
local tmp,tmp_={},{}
local value,volume,modulo,freqnum



local rate = 1
value = peek(0xFF9C+18*ch+1)<<8|peek(0xFF9C+18*ch)
volume = vols[ch+1]
vols[ch+1] = vols[ch+1]+(((value&0xf000)>>12)-vols[ch+1])/rate
if (value&0xf000)>>12 == 15 then
    sfx_frame[ch+1]=0
else
    sfx_frame[ch+1]=sfx_frame[ch+1]+1
end
freqnum = value&0x0fff
modulo = volume*intensity

--put your algolithm here...

--tmp_[1] = fm(modulo,freq,1,ticopl_frame)
--tmp_[2] = fm(90,freq,1,ticopl_frame)
--tmp_[1] = pwm(volume*2)
--tmp_[2] = fm2(tmp_[1],modulo,freq,ticopl_frame)
--tmp_[1] = pwm(volume*2)
--local tmp = wfsum(tmp_)

local tmp = peekwfrl(ch)
--tmp = psg(wft.SAW,15,1,0,15)
--local tmp = pwm(nclip(time()/10%30+1,1,30))
tmp = filter(tmp,16-(0.01+volume))
--tmp = window(tmp)
tmp = normalize(tmp)
--trace(tmp[1])
local tmp2=""
for _,i in pairs(tmp) do
tmp2=tmp2..f("%x",math.floor(tonumber(i)))
end
--print(tmp2)
pokewfr(ch,tmp2)
end
end
ticopl_frame=ticopl_frame+32
end

function visualize()
tstr=tostring
floor=math.floor
rect(0,86,100,16,1)
print("TicSynth",0,87,0)
print("v3.3 "..sub(tstr(freq),1,4)..","..floor(modint*10)/10,44,87,0,1,1,0) 
print(f("%7s","#"..f("%1d",peek(0x13ffc))..":"..f("%1X",peek(0x13ffd)).."."..f("%2d",peek(0x13ffe))),0,93,fgc,1,1,0) 

for ch=0,3 do
local value,volume,frequency,freqnum,modulo
value = peek(0xFF9C+18*ch+1)<<8|peek(0xFF9C+18*ch)
volume = (value&0xf000)>>12
frequency = f("%4dv",value&0x0fff)
freqnum = value&0x0fff
modulo = volume*intensity
rect(0,100+8*ch,100,8,1)
rect(0,100+8*ch,volume*2,7,12)
rect(0,107+8*ch,vols[ch+1]*2,1,12)
rect(math.log(freqnum,2)*1.33,100+8*ch,1,8,2)
print(frequency..volume,0,101+8*ch,0,1,1,0)
--print(f("%4d,%-4s",math.floor(modulo),sub(tstr(freq),1,4)),63,101+8*ch,0,1,1,0)
end
for ch=0,3 do
local val_,vol_,freq_
val_ = peek(0xFF9C+18*ch+1)<<8|peek(0xFF9C+18*ch)
vol_ = (val_&0xf000)>>12
freq_ = (val_&0x0fff)+1
freq_ = 120
vol_ = 15
for i=0,68 do
local j=freq_/192
local f=math.floor
    local wf=peekwfr(ch)
line(i*1+30,107+ch*8-tonumber(sub(wf,f(i*j%31+1)or 0,f(i*j%31+1)or 0),16)*(vol_/16)/(16/7),i*1+31,107+ch*8-tonumber(sub(wf,f((i+1)*j%31+1)or 0,f((i+1)*j%31+1)or 0),16)*(vol_/16)/(16/7),0)
end end
function writesfx()
    local vol="0123456789abcedfffffffffffffff"
    for ch=0,63 do
        for i=1,30 do
            poke4(0x201c4+128*ch+i*4,tonumber(string.sub(vol,i,i),16))
        end
        poke4(2*0x100e4+121,7)
        poke(0x100e4+63+64*ch,0xf1)
    end
end
end
function BOOT()writesfx()end
synthesis()
visualize()
end
function OVR()vbank(1)ticsyn()end