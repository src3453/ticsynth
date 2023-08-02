# TicSynth
A fully-customizable software synth for TIC-80
## Description
Software synth for TIC-80 written in lua. You can freely define the synthesis method by recombining functions.
## Supported synth methods
- FM
- Filter
- PSG (Sin/Square/Triangle/Sawtooth/Noise)
- AM
- mod/mul
- and more in future updates
## Sample Algorithms
### Simple FM Synthesis
```lua
local tmp = fm(modulo,freq,1,0) -- do FM synthesis
```
### Apply Low-pass Filter to original waveforms
```lua
local tmp = peekwfrl(ch) -- to grab original waveform
tmp = filter(tmp,volume,ftype.LP) -- "volume" is volume of current channel
```
### Simple PWM (using volume to parameter)
```lua
local tmp = psg(wft.SQU,15,1,volume) -- make Pulse Wave (range of duty is 0~31)
```
