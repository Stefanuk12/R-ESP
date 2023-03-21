-- // Dependencies
local RESP = RESP_MANAGER or loadstring(game:HttpGet("https://raw.githubusercontent.com/Stefanuk12/R-ESP/master/Manager.lua"))()

-- // Create the manager and initialise it
local Manager = RESP.PlayersManager.new()
Manager:Initialise()

-- // Add all of the objects
Manager:Add("BoxSquare")
Manager:Add("Tracer")
Manager:Add("Header", {
    Type = "Name"
})
Manager:Add("Header", {
    Type = "Distance"
})
Manager:Add("Header", {
    Type = "Weapon",
    Weapon = "AK-47"
})
Manager:Add("Header", {
    Type = "MiscTop",
    Value = "Cool Person"
})
Manager:Add("Header", {
    Type = "MiscBottom",
    Value = "Bottom Text"
})
Manager:Add("Healthbar")
Manager:Add("OffArrow")
Manager:Add("Box3D")