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
local tmp = fm(modulo,freq,1,ticopl_frame)
```
