intensity=0
freq=3.0
modint=1.0
ticopl_frame = 0
syn_enable = {true, true, true, true}
vols,sfx_frame = {0,0,0,0},{0,0,0,0}
function ticsyn()
local function peekwfrl(index)
local out
local f = string.format
out = {}
local j=1
for i=2*0xff9c+index*36+4, 2*0xff9c+(index)*36+35 do
u = peek4(i)
out[j] = u
j=j+1
end
return out
end
local function peekwfr(index)
    local out
    local f = string.format
    out = ""
    for i=0xff9c+index*18+2, 0xff9c+(index)*18+17 do
    u = peek(i)
    out = out .. f("%02x",u)
    end
    return out
    end
local function pokewfr(index,data)
local j
j = 1
for i=0xff9c+index*18+2, 0xff9c+(index)*18+17 do
poke(i,tonumber(string.sub(data,j,j+1),16))
j = j + 2
end
end
local sub = string.sub
local function nclip(num,min,max)if num==nil or tostring(num)=="nan" then return 0 else return math.min(math.max(num,min),max)end end
local function fm(int,freq,freq2,ticopl_frame,theta,vol)
    local f = string.format
    local tmp = {}
    local j=1
    local theta,vol = theta or 0,vol or 1
    for i = ticopl_frame, ticopl_frame+31 do
    tmp[j]=nclip(vol*math.sin(theta+math.rad(i*(360/32)*freq2+math.sin(math.rad(i*(360/32)*freq))*(int)))*8+8,0,15)
    j=j+1
    end
    return tmp
end
    local function fm2(carrier,int,freq,timestate)
        --timestate = timestate or 1
        local f = math.floor
        local tmp = {}
        local j=1
        for i = timestate, timestate+31 do
      --j = tonumber(sub(peekwf(operator),i,i),16)
            --tmp = tmp .. f("%01x",math.floor((tonumber(sub(peekwf(carrier),i,i),16) + tonumber(sub(peekwf(operator),i,i),16))%16))
            local res = (i-timestate+1)+(math.sin(math.rad(i*(360/32)*freq))*(int/360))*16%32+1
            local val = carrier[1+f(res)%32]+(carrier[1+f(res+1)%32]-carrier[1+f(res)%32])*res%1
            tmp[j] = nclip(val,0,15)
            j=j+1
        end
        return tmp
    end
    local function fm3(carrier,modulator)
        --timestate = timestate or 1
        local f = math.floor
        local tmp = {}
        local j=1
        for i = 0, 0+31 do
      --j = tonumber(sub(peekwf(operator),i,i),16)
            --tmp = tmp .. f("%01x",math.floor((tonumber(sub(peekwf(carrier),i,i),16) + tonumber(sub(peekwf(operator),i,i),16))%16))
            local res = (nclip(modulator[i+1],0,15)+1)*2
            local val = carrier[1+f(res)%32]+(carrier[1+f(res+1)%32]-carrier[1+f(res)%32])*res%1
            tmp[j] = nclip(val,0,15)
            j=j+1
        end
        return tmp
    end
    local function wfsum(wf)
        local tmp={}
        for j=1,#wf do
            for i=1,32 do
            tmp[i] = (tmp[i]or 0)+wf[j][i]
            end
        end
        return tmp
    end
    local function wfmul(a,b)local tmp={}for i=1,32 do if type(b)=="number"then tmp[i]=a[i]*b else tmp[i]=a[i]*b[i]end end return tmp end
	local function wfmod(wf,b)
		local tmp={wf[1]}
		if b==nil then
		for i=2,#wf do
			for j=1,32 do
				tmp[i] = (tmp[i]or 0)%wf[i][j]
			end
		end
		else
			for j=1,32 do
				tmp[j] = (wf[j] or 0)%b
			end
		end
		return tmp
	end
    local function normalize(wf)
        local tmp={}
        local mx,mn=math.max(table.unpack(wf)),math.min(table.unpack(wf))
       	for i=1,32 do
            tmp[i] = nclip((wf[i]-mn)*16/((mx-mn)+0.01),0,15)
        end
        return tmp
    end
local ftype = {
    LP = 0,
    HP = 1,
    BP = 2,
    NOT= 3
}
local function filter(input,cutoff,filtType,bw,q,omega,a0,a1,a2,b0,b1,b1f,b2)
if filtType == ftype.LP then
    b1f = 1
elseif filtType == ftype.HP then
    b1f = -1
else b1f = 1 end
local sin,cos=math.sin,math.cos
local filt_q=q or 0.707106781
local omega= (2.0 or omega) *3.14159265*cutoff/32
local alpha=sin(omega)/(2.0*filt_q) 
local a0= ( 1.0 or a0) +alpha
local a1= (-2.0 or a1) *cos(omega)
local a2= ( 1.0 or a2) -alpha
local b0=(( 1.0 or b0) -cos(omega))/2.0
local b1= b1f*(( 1.0 or b1) -cos(omega))
local b2=(( 1.0 or b2) -cos(omega))/2.0
if filtType == ftype.BP then
    alpha = sin(omega) * math.sinh(math.log(2.0) / 2.0 * bw * omega / sin(omega));
    b0 =  alpha
    b1 =  0.0
    b2 = -alpha
end
if filtType == ftype.NOT then
    alpha = sin(omega) * math.sinh(math.log(2.0) / 2.0 * bw * omega / sin(omega));
    b0 = 1.0
    b1 = -2*cos(omega)
    b2 = 1.0
end
local output = {}
local in1,in2,out1,out2=input[1],input[1],input[1],input[1]
for i=1,#input*3 do
output[i]=b0/a0*input[i%#input+1]+b1/a0*in1+b2/a0*in2-a1/a0*out1-a2/a0*out2
in2= in1   -- 2つ前の入力信号を更新
in1 = input[i%#input+1]  -- 1つ前の入力信号を更新
out2 = out1  -- 2つ前の出力信号を更新
out1 = output[i] 
end
local tmp = {}
for i=1,#input do
    tmp[i] = output[i+#input]
end
return tmp
end

local wft={
        SQU=0,
        TRI=1,
        SAW=2,
        SIN=3,
        NOI=4
    }
local function psg(wftype,vol,freq,duty,phase)
    duty=duty or 15
    freq=freq or 1
    vol=vol/16 or 1
    phase=math.floor(phase or 0)
    --freq=freq/2
    tmp={}
    
    for i=1,32 do
        if wftype==wft.SQU then
            tmp[(phase+i)%32+1]=(math.max(math.min((duty)-((i-1)*freq)%32,1),0)//1)*15
        end if wftype==wft.TRI then
            tmp[(phase+i)%32+1]=math.abs((i*freq%31)-15)*vol
        end if wftype==wft.SAW then
            tmp[(phase+i)%32+1]=(i*freq%31)*vol/2
        end if wftype==wft.SIN then
            tmp[(phase+i)%32+1]=math.sin(math.rad((i*freq)*(360/32)))*vol*7+8
        end if wftype==wft.NOI then
            tmp[(phase+i)%32+1]=math.random()*vol*15
        end
    end
    return tmp
end
local function wfclip(wf,min,max)
    local tmp=wf
    
        for j=1,32 do
            tmp[i] = nclip(wf[i],min,max)
    
    end
    return tmp
    end
local function ismelodic(ch)
    local tmp=math.max(table.unpack(peekwfrl(ch)))
    if tmp == 0 then return 0 else return 1 end
end
local function pd(wf,mul)
    local ind=0
    local out={}
    for i=1,32 do
        local val=math.cos(math.rad(ind*(360/32)*mul))*8+7
        out[i]=val
        ind=ind+wf[i]
    end
    return out
end
local function keypermchanger()
    if btnp(0,20,2) then modint=modint+0.1 end
    if btnp(1,20,2) then modint=modint-0.1 end
    if btnp(2,20,2) then freq=freq-0.1 end
    if btnp(3,20,2) then freq=freq+0.1 end
    end
local f = string.format
local function synthesis()
local intensity=modint*9

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

local tmp = peekwfrl(ch) -- to grab original waveform
--tmp = fm2(tmp,modulo,freq,0)
tmp = pd(tmp,1/4)

tmp = normalize(tmp) -- to normalize synthesis results

local tmp2=""
for _,i in pairs(tmp) do
tmp2=tmp2..f("%x",math.floor(tonumber(i))) 
end
--print(tmp2)
pokewfr(ch,tmp2) -- poke results to sound registers
end
end
ticopl_frame=ticopl_frame+32
end

local function visualize()
tstr=tostring
floor=math.floor
rect(0,86,100,16,1)
print("TicSynth",0,87,0)
print("v3.10 "..sub(tstr(freq),1,4)..","..floor(modint*10)/10,44,87,0,1,1,0) 
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
rect(math.log(freqnum,2)*2,100+8*ch,1,8,2)
print(frequency..volume,0,101+8*ch,0,1,1,0)
--print(f("%4d,%-4s",math.floor(modulo),sub(tstr(freq),1,4)),63,101+8*ch,0,1,1,0)
end
for ch=0,3 do
local val_,vol_,freq_
val_ = peek(0xFF9C+18*ch+1)<<8|peek(0xFF9C+18*ch)
vol_ = (val_&0xf000)>>12
freq_ = (val_&0x0fff)+1
freq_ = 90.35*2
vol_ = 15
for i=0,68 do
local j=freq_/192
local f=math.floor
    local wf=peekwfr(ch)
line(i*1+30,107+ch*8-tonumber(sub(wf,f(i*j%31+1)or 0,f(i*j%31+1)or 0),16)*(vol_/16)/(16/7),i*1+31,107+ch*8-tonumber(sub(wf,f((i+1)*j%31+1)or 0,f((i+1)*j%31+1)or 0),16)*(vol_/16)/(16/7),0)
end end
end
function wave()
    sub=string.sub
    for ch=0,3 do
        local val_,vol_,freq_
        val_ = peek(0xFF9C+18*ch+1)<<8|peek(0xFF9C+18*ch)
        vol_ = (val_&0xf000)>>12
        freq_ = (val_&0x0fff)+1
        --vol_ = 15
        rect(0,0+ch*33,240,37,12)
        local wf=peekwfrl(ch)
        local j=freq_/384
        local f=math.floor
        local r=math.random
        if math.max(table.unpack(wf)) == 0 then for i=1,32 do wf[i]=r(0,1)*15 end end
        for i=-120,120 do
            local val = wf[f(i*j%31+1)] or 0
            local val2 = wf[f((i+1)*j%31+1)] or 0
            
            line(i*1+120,16+ch*33-(val-8)*(vol_/16)/(16/32),i*1+121,16+ch*33-(val2-8)*(vol_/16)/(16/32),15)
        end end
end
keypermchanger()   -- key parameter changer
synthesis() -- core of synthesis part
--wave()    -- additional wave visualizer
visualize() -- visualizer of sound registers
end
function OVR()vbank(1)ticsyn()end --execute
--function OVR()vbank(1)ticsyn()for ch=0,3 do if peek4(2*0xff9c+ch*36+3)~=0 then poke4(2*0xff9c+ch*36+3,15)end end end --unused