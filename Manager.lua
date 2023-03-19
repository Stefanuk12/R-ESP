--[[
    Information:
    This handles rendering the Base objects.

    If you require it, you can hook the functions and it would not affect other instances. -> e.g.
    ```lua
    local Object = InstanceObject.new()
    Object.Weapon = function()
        return "Hello"
    end
    ```
]]

-- // Dependencies
local Base = RESP_BASE or loadstring(game:HttpGet("https://raw.githubusercontent.com/Stefanuk12/R-ESP/master/Base.lua"))()

-- // Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

-- // Vars
local LocalPlayer = Players.LocalPlayer
local InstanceObjects = {}

-- // InstanceObject Class
local InstanceObject = {}
InstanceObject.__index = InstanceObject
InstanceObject.__type = "InstanceObject"
do
    -- // Constructor
    function InstanceObject.new(Object, NoInsert)
        -- // Check object type
        assert(typeof(Object) == "Instance" and Object:IsA("BasePart") or Object:IsA("Model"), "invalid object, must be a BasePart or Model")

        -- // Create the object
        local self = setmetatable({}, InstanceObject)

        -- // Vars
        self.Instance = Object
        self.Objects = {}

        -- // Add it to InstanceObjects
        if (not NoInsert) then
            table.insert(InstanceObjects, self)
        end

        -- // Return the object
        return self
    end

    -- // Gets all objects of a certain type
    function InstanceObject:Get(Type, SubType)
        -- // Vars
        local Found = {}

        -- // Loop through objects
        for _, Object in ipairs(self.Objects) do
            -- // Check types match, then add
            if (Object.__type == Type and (SubType == Object.Data.Type or not SubType)) then
                table.insert(Found, Object)
            end
        end

        -- // Return found
        return Found
    end

    -- // Check if has object of type
    function InstanceObject:Has(Type, SubType)
        -- // Grab all objects that match
        local Objects = self:Get(Type, SubType)

        -- // Check subtypes if header
        if (Type == "Header") then
            -- // Vars
            local FoundSubTypes = {}

            -- // Loop through all headers
            for _, Header in ipairs(Objects) do
                -- // Return if subtype already found
                local HeaderSubType = Header.Data.Type
                if (table.find(FoundSubTypes, HeaderSubType)) then
                    return true
                end

                -- // Add
                table.insert(FoundSubTypes, HeaderSubType)
            end

            -- // Not found
            return false
        end

        -- // Return
        return #Objects > 0
    end

    -- // Adds an object of type
    function InstanceObject:Add(Type, Data, Properties)
        -- // Get the object builder
        local ObjectBuilder = Base[Type]
        assert(ObjectBuilder, "type does not exist - invalid object type")

        -- // Make sure does not have
        assert(not self:Has(Type), "object of type (and subtype) already exists")

        -- // Construct it
        local Object = ObjectBuilder.new(Data, Properties)
        table.insert(self.Objects, Object)

        -- // Special case for headers
        if (Type == "Header") then
            Object.Data.Offset = function()
                return self:HeaderOffset(Object)
            end
        end

        -- // Return it
        return Object
    end

    -- // Renders all objects
    function InstanceObject:Render()
        -- // Ensure we have some objects and an instance
        if (#self.Objects == 0 or not self.Instance) then
            return false
        end

        -- // Check
        local ObjectInstance = self.Instance
        local PartCFrame, PartSize = getboundingbox({ObjectInstance})

        -- // Get corners
        local Corners = Base.Utilities.CalculateCorners(PartCFrame, PartSize)

        -- // Update each object
        for _, Object in ipairs(self.Objects) do
            local Data = Object.Data
            local SubType = Data.Type

            -- // Setting values
            if (Object.__type == "Header") then
                -- // Weapon SubType
                if (SubType == "Weapon") then
                    Data.Value = Data.Weapon or self:Weapon()
                end

                -- // Name SubType
                if (SubType == "Name") then
                    Data.Value = Data.Name or self:Name()
                end

                -- // Distance SubType
                if (SubType == "Distance") then
                    Data.Value = Data.Distance or self:Distance()
                end
            end

            if (Object.__type == "Healthbar") then
                local HealthData = Data.Health or {self:Health()}
                Data.Value = HealthData[1]
                Data.MaxValue = HealthData[2]
            end

            -- // Update
            Object:Update(Corners)
        end
    end

    -- // Destroy all
    function InstanceObject:Destroy()
        -- // Loop through all objects
        for i = #self.Objects, 1, -1 do
            self.Objects[i]:Destroy()
            table.remove(self.Objects, i)
        end
    end

    -- // Below are additional functions, designed to be hooked in order to add support for other features!

    -- // Header offset
    function InstanceObject:HeaderOffset(HeaderObject)
        -- // Vars
        local Headers = self:Get("Header")
        local BaseOffset = Vector2.new(0, 2)

        -- // Loop through headers
        for _, Header in ipairs(Headers) do
            -- // Check if matches
            if (Header == HeaderObject) then
                break
            end

            -- // Add bounds
            local YTextBounds = Header.Objects.Main.TextBounds * Vector2.yAxis
            BaseOffset = BaseOffset + YTextBounds
        end

        -- // Return
        return BaseOffset
    end

    -- // Gets the name of the object
    function InstanceObject:Name()
        return self.Instance.Name
    end

    -- // Gets current weapon
    function InstanceObject:Weapon()
        return "N/A"
    end

    -- // Gets the max/health of the object
    function InstanceObject:Health()
        -- // Ensure we got an instance
        if not (self.Instance and self.Instance.Parent) then
            return 100, 100
        end

        -- // Check there is a humanoid
        local Humanoid = self.Instance:FindFirstChildWhichIsA("Humanoid")
        if (not Humanoid) then
            return 100, 100
        end

        -- // Return
        return Humanoid.Health, Humanoid.MaxHealth
    end

    -- // Gets distance from point
    function InstanceObject:Distance()
        return LocalPlayer:DistanceFromCharacter(self.Instance:GetPivot().Position)
    end
end

-- // PlayerManager Class
local PlayerManager = {}
PlayerManager.__index = PlayerManager
PlayerManager.__type = "PlayerManager"
do
    -- // Constructor
    function PlayerManager.new(Player, NoInsert)
        -- // Create the object
        local self = setmetatable({}, PlayerManager)

        -- // Set vars
        self.Player = Player
        self.InstanceObject = InstanceObject.new(nil, true)

        -- // Add it
        if (not NoInsert) then
            table.insert(InstanceObjects, self)
        end

        -- // Return the object
        return self
    end

    -- // Gets the character
    function PlayerManager:Character()
        return self.Player.Character
    end

    -- // Renders
    function PlayerManager:Render()
        -- // Make sure instanceobject
        if (not self.InstanceObject) then
            return
        end

        -- // Set the character
        self.InstanceObject.Instance = self:Character()

        -- // Render it
        self.InstanceObject:Render()
    end

    -- // Destroys instance object
    function PlayerManager:Destroy()
        -- // Check for instance object
        if (self.InstanceObject) then
            self.InstanceObject:Destroy()
            self.InstanceObject = nil
        end
    end
end

-- // PlayersManager Class (for many players)
local PlayersManager = {}
PlayersManager.__index = PlayersManager
PlayersManager.__type = "PlayersManager"
do
    -- // Constructor
    function PlayersManager.new()
        -- // Create the object
        local self = setmetatable({}, PlayerManager)

        -- // Set vars
        self.Managers = {}

        -- // Return the object
        return self
    end

    -- // Ran whenever a new player (not LocalPlayer) is added
    function PlayersManager:OnPlayerAdded(Player)
        table.insert(self.Managers, PlayerManager.new(Player))
    end

    -- // Destroys everything
    function PlayersManager:Destroy()
        -- // Disconnect if there already is one
        if (self.PlayerAddedConnection) then
            self.PlayerAddedConnection:Disconnect()
        end

        -- // Disconnect all managers
        for i = #self.Managers, 1, -1 do
            self.Managers[i]:Destroy()
            table.remove(self.Managers, i)
        end
    end

    -- // Initialises connection
    function PlayersManager:InitialiseConnections()
        -- // Set
        self.PlayerAddedConnection = Players.PlayerAdded:Connect(function(Player)
            self:OnPlayerAdded(Player)
        end)
    end

    -- // Initialises the entire thing
    function PlayersManager:Initialise()
        -- // Deinitialise previous
        self:Destroy()

        -- // Initialise for current players
        for _, Player in ipairs(Players:GetPlayers()) do
            -- // Make sure is not LocalPlayer
            if (Player == LocalPlayer) then
                continue
            end

            -- // Add
            self:OnPlayerAdded(Player)
        end

        -- // Initialise connections
        self:InitialiseConnections()
    end
end

-- // Render loop
RunService:BindToRenderStep("R-ESP-Render", 0, function(dT)
    -- // Loop through each instance object, then render
    for _, v in ipairs(InstanceObjects) do
        v:Render(dT)
    end
end)

-- // Return
local RESP_MANAGER = {
    Base,
    InstanceObject = InstanceObject,
    PlayerManager = PlayerManager,
    PlayersManager = PlayersManager,
    InstanceObjects = InstanceObjects
}
getgenv().RESP_MANAGER = RESP_MANAGER
return RESP_MANAGER