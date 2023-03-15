# R-ESP

An ESP library heavily inspired by [sense]()

```diff 
- For Synapse V3 only (unless a wrapper is written for V2)
- Untested at the moment
```

# Features

These are all of the features...

## Base
- [x] Box
- [x] Box (3D)
- [x] Tracer
- [x] Header
  - [x] Distance
  - [x] Name
  - [x] Weapon
- [x] Healthbar
- [x] Out of view Arrows

## Manager

Haven't started yet...

# Usage

This library uses OOP heavily. The base contains the objects you might need, the manager helps manage these objects by updating and rendering them. Within the manager, you can install plugins to add functionality for different games and for players, in general.

## Base Documentation

I'm not really bothered to write the entirety of the documentation for the base since most of it is self-documented within the code itself. Instead, I'll provide links to each function and such.

```diff
! Note that if you want to change certain Drawing properties, you can do this via changing the class' Properties variable (example below). It may be overwritten though. 
```

```lua
local Box = BoxSquare.new()
Box.Properties.Filled = true
```

### Base

[Base:Destroy(TableObject: self.Objects?)](https://github.com/Stefanuk12/R-ESP/blob/master/Base.lua#L319-L336)

### BoxSquare

[BoxSquare.DefaultData](https://github.com/Stefanuk12/R-ESP/blob/master/Base.lua#L370-L373)

[BoxSquare.DefaultProperties](https://github.com/Stefanuk12/R-ESP/blob/master/Base.lua#L374-L389)

[BoxSquare.new(Data: BoxSquare.DefaultData?, Properties: BoxSquare.DefaultProperties?)](https://github.com/Stefanuk12/R-ESP/blob/master/Base.lua#L391-L409)

[BoxSquare:Update(Corners: Utilities.CalculateCorners)](https://github.com/Stefanuk12/R-ESP/blob/master/Base.lua#L411-L431)

### Tracer

[Tracer.DefaultData](https://github.com/Stefanuk12/R-ESP/blob/master/Base.lua#L441-L444)

[Tracer.DefaultProperties](https://github.com/Stefanuk12/R-ESP/blob/master/Base.lua#L445-L460)

[Tracer.new(Data: Tracer.DefaultData?, Properties: Tracer.DefaultProperties?)](https://github.com/Stefanuk12/R-ESP/blob/master/Base.lua#L462-L480)

[Tracer:Update(Corners: Utilities.CalculateCorners)](https://github.com/Stefanuk12/R-ESP/blob/master/Base.lua#L482-L506)

### Header

[Header.DefaultData](https://github.com/Stefanuk12/R-ESP/blob/master/Base.lua#L516-L542)

[Header.DefaultProperties](https://github.com/Stefanuk12/R-ESP/blob/master/Base.lua#L543-L558)

[Header.new(Data: Header.DefaultData?, Properties: Header.DefaultProperties?)](https://github.com/Stefanuk12/R-ESP/blob/master/Base.lua#L560-L578)

[Header:GetPosition(Corners: Utilities.CalculateCorners)](https://github.com/Stefanuk12/R-ESP/blob/master/Base.lua#L580-L602)

[Header:Update(Corners: Utilities.CalculateCorners)](https://github.com/Stefanuk12/R-ESP/blob/master/Base.lua#L604-L620)

### Healthbar

[Healthbar.DefaultData](https://github.com/Stefanuk12/R-ESP/blob/master/Base.lua#L630-L641)

[Healthbar.DefaultProperties](https://github.com/Stefanuk12/R-ESP/blob/master/Base.lua#L642-L672)

[Healthbar.new(Data: Healthbar.DefaultData?, Properties: Healthbar.DefaultProperties?)](https://github.com/Stefanuk12/R-ESP/blob/master/Base.lua#L674-L692)

[Healthbar:Update(Corners: Utilities.CalculateCorners)](https://github.com/Stefanuk12/R-ESP/blob/master/Base.lua#L694-L729)

### OffArrow

[OffArrow.DefaultData](https://github.com/Stefanuk12/R-ESP/blob/master/Base.lua#L739-L747)

[OffArrow.DefaultProperties](https://github.com/Stefanuk12/R-ESP/blob/master/Base.lua#L748-L766)

[OffArrow.new(Data: OffArrow.DefaultData?, Properties: OffArrow.DefaultProperties?)](https://github.com/Stefanuk12/R-ESP/blob/master/Base.lua#L768-L786)

[OffArrow:Direction(Origin: CFrame, Destination: Vector3)](https://github.com/Stefanuk12/R-ESP/blob/master/Base.lua#L788-L798)

[OffArrow:Update(Corners: Utilities.CalculateCorners)](https://github.com/Stefanuk12/R-ESP/blob/master/Base.lua#L800-L830)

### Box 3D

[Box3D.DefaultData](https://github.com/Stefanuk12/R-ESP/blob/master/Base.lua#L840-L843)

[Box3D.DefaultProperties](https://github.com/Stefanuk12/R-ESP/blob/master/Base.lua#L844-L856)

[Box3D.new(Data: Box3D.DefaultData?, Properties: Healthbar.DefaultProperties?)](https://github.com/Stefanuk12/R-ESP/blob/master/Base.lua#L858-L876)

[Box3D:Update(Corners: Utilities.CalculateCorners)](https://github.com/Stefanuk12/R-ESP/blob/master/Base.lua#L878-L906)