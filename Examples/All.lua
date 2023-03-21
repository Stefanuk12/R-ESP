-- // Dependencies
local RESP = RESP_MANAGER or loadstring(game:HttpGet("https://raw.githubusercontent.com/Stefanuk12/R-ESP/master/Manager.lua"))()

-- // Services
local Players = game:GetService("Players")

-- // Vars
local LocalPlayer = Players.LocalPlayer

-- // Add
local Object = RESP.InstanceObject.new(LocalPlayer.Character)
Object:Add("BoxSquare")
Object:Add("Tracer")
Object:Add("Header", {
    Type = "Name"
})
Object:Add("Header", {
    Type = "Distance"
})
Object:Add("Header", {
    Type = "Weapon",
    Weapon = "AK-47"
})
Object:Add("Header", {
    Type = "MiscTop",
    Value = "Cool Person"
})
Object:Add("Header", {
    Type = "MiscBottom",
    Value = "Bottom Text"
})
Object:Add("Healthbar")
Object:Add("OffArrow")
Object:Add("Box3D")