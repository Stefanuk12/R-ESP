# R-ESP

An ESP library heavily inspired by [sense](https://github.com/shlexware/Sirius/blob/request/library/sense/source.lua).

```diff 
- For Synapse V3 only (unless a wrapper is written for V2)
- Untested at the moment
```

# Features

These are all of the features...

## Base
- [x] Box
- [ ] Box (3D)
- [x] Tracer
- [x] Header
  - [x] Distance
  - [x] Name
  - [x] Weapon
- [x] Healthbar
- [ ] Out of view Arrows

## Manager

Haven't started yet...

# Usage

This library uses OOP heavily. The base contains the objects you might need, the manager helps manage these objects by updating and rendering them. Within the manager, you can install plugins to add functionality for different games and for players, in general.

## Base Documentation

I'm not really bothered to write the entirety of the documentation for the base since most of it is self-documented within the code itself. Instead, I'll provide links to each function and such.

### Base

[Base.Destroy(self: Base, TableObject: self.Objects?)](https://github.com/Stefanuk12/R-ESP/blob/master/Base.lua#L226-L243)

### BoxSquare
[BoxSquare.DefaultData](https://github.com/Stefanuk12/R-ESP/blob/master/Base.lua#L277-L280)

[BoxSquare.DefaultProperties](https://github.com/Stefanuk12/R-ESP/blob/master/Base.lua#L281-L296)

[BoxSquare.new(Data: BoxSquare.DefaultData?, Properties: BoxSquare.DefaultProperties?)](https://github.com/Stefanuk12/R-ESP/blob/master/Base.lua#L298-L316)

[BoxSquare.Update(self: BoxSquare, Corners: Utilities.CalculateCorners)](https://github.com/Stefanuk12/R-ESP/blob/master/Base.lua#L318-L343)

### Tracer
[Tracer.DefaultData](https://github.com/Stefanuk12/R-ESP/blob/master/Base.lua#L353-L356)

[Tracer.DefaultProperties](https://github.com/Stefanuk12/R-ESP/blob/master/Base.lua#L357-L372)

[Tracer.new(Data: Tracer.DefaultData?, Properties: Tracer.DefaultProperties?)](https://github.com/Stefanuk12/R-ESP/blob/master/Base.lua#L374-L392)

[Tracer.Update(self: Tracer, Corners: Utilities.CalculateCorners)](https://github.com/Stefanuk12/R-ESP/blob/master/Base.lua#L394-L423)

### Header
[Header.DefaultData](https://github.com/Stefanuk12/R-ESP/blob/master/Base.lua#L433-L467)

[Header.DefaultProperties](https://github.com/Stefanuk12/R-ESP/blob/master/Base.lua#L468-L474)

[Header.new(Data: Header.DefaultData?, Properties: Header.DefaultProperties?)](https://github.com/Stefanuk12/R-ESP/blob/master/Base.lua#L476-L494)

[Header.GetPosition(self: Header, Corners: Utilities.CalculateCorners)](https://github.com/Stefanuk12/R-ESP/blob/master/Base.lua#L496-L518)

[Header.Update(self: Header, Corners: Utilities.CalculateCorners)](https://github.com/Stefanuk12/R-ESP/blob/master/Base.lua#L520-L544)