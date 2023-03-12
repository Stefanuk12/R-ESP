--[[
    Information:
    Contains the classes needed for the ESP. Additional logic is needed to make it functional

    Note:
    - This only works for Synapse V3, I may make a v2 -> v3 converter in the future
]]

-- // Services
local Workspace = game:GetService("Workspace")

-- // Vars
local ZeroVector3 = Vector3.zero
local ZeroVector2 = Vector2.zero
local Vertices = {
	Vector3.new(-1, -1, -1),
	Vector3.new(-1,  1, -1),
	Vector3.new(-1,  1,  1),
	Vector3.new(-1, -1,  1),
	Vector3.new( 1, -1, -1),
	Vector3.new( 1,  1, -1),
	Vector3.new( 1,  1,  1),
	Vector3.new( 1, -1,  1)
}

-- // Utilities
local Utilities = {}
do
    -- // Gets the current camera
    function Utilities.GetCurrentCamera()
        return Workspace.CurrentCamera
    end

    -- // Applies operation to Vector2
    function Utilities.ApplyVector2(Vector, f)
        return Vector2.new(f(Vector.X), f(Vector.Y))
    end

    -- // Combine two tables
    function Utilities.CombineTables(Base, ToAdd)
        -- // Default
        ToAdd = ToAdd or {}
        Base = Base or {}

        -- // Loop through data we want to add
        for i, v in pairs(ToAdd) do
            -- // If data does not exist
            if (not Base[i]) then
                Base[i] = v
                continue
            end

            -- // Check if table
            if (typeof(v) == "table") then
                Base[i] = Utilities.CombineTables(Base, v)
                continue
            end

            -- // Add
            Base[i] = v
        end

        -- // Return
        return Base
    end
end

-- // Polyfill for getboundingbox
local getboundingbox = getboundingbox or function (parts, orientation)
    -- // Vars
    local MinPosition
    local MaxPosition

    -- // Loop through part
    for _, Part in ipairs(parts) do
        -- // Part data
        local PartPosition = Part.CFrame.Position
        local HalfPartSize = Part.Size / 2

        -- // Set min/max
        MinPosition = (MinPosition or PartPosition):Min(PartPosition - HalfPartSize)
        MaxPosition = (MaxPosition or PartPosition):Max(PartPosition + HalfPartSize)
    end

    -- // Calculate the some things
    local Center = (MinPosition + MaxPosition) / 2
    local Front = Vector3.new(Center.X, Center.Y, MaxPosition.Z)

    -- // Return
    local BoxCFrame = CFrame.new(Center, Front)
    local BoxSize = MaxPosition - MinPosition
    return BoxCFrame, BoxSize
end

-- // Polyfill for worldtoscreen
local worldtoscreen = worldtoscreen or function (points, offset)
    -- // Vars
    offset = offset or ZeroVector3
    local CurrentCamera = Utilities.GetCurrentCamera()
    local Results = {}

    -- // Loop through each point
    for i, Point in pairs(points) do
        -- // Get on screen position and add to table
        local Position, _ = CurrentCamera:WorldToViewportPoint(Point + offset)
        Results[i] = Position
    end

    -- // Return
    return Results
end

-- // Utilities - continued
do
    -- // Gets the corners of a part (or bounding box)
    function Utilities.CalculateCorners(PartCFrame, PartSize)
        -- // Vars
        local HalfSize = PartSize / 2
        local Corners = table.create(#Vertices)
    
        -- // Calculate each corner
        for i, Vertex in ipairs(Vertices) do
            Corners[i] = PartCFrame + (HalfSize * Vertex)
        end
    
        -- // Convert to screen
        Corners = worldtoscreen(Corners)
    
        -- // Get min and max
        local MinPosition = Utilities.GetCurrentCamera().ViewportSize:Min(unpack(Corners))
        local MaxPosition = ZeroVector2:Max(unpack(Corners))
    
        -- // Return corners
        local mathfloor = math.floor
        local ApplyVector2 = Utilities.ApplyVector2
        return {
            Corners = Corners,
    
            TopLeft = ApplyVector2(MinPosition, mathfloor),
            TopRight = ApplyVector2(Vector2.new(MaxPosition.X, MinPosition.Y), mathfloor),
            BtoomLeft = ApplyVector2(Vector2.new(MinPosition.X, MaxPosition.Y), mathfloor),
            BottomRight = ApplyVector2(MaxPosition, mathfloor),
        }
    end

    -- // Rotates a vector2
    function Utilities.RotateVector2(Vector, Angle)
        -- // Calculate the trig values
        local CosValue = math.cos(Angle)
        local SinValue = math.sin(Angle)
    
        -- // Return the rotated vector
        return Vector2.new(
            (CosValue * Vector.X) - (SinValue * Vector.Y),
            (SinValue * Vector.X) + (CosValue * Vector.Y)
        )
    end

    -- // Sets a drawing object's properties
    Utilities.IgnoredDrawingProperties = {"Type", "SubType"}
    function Utilities.SetDrawingProperties(Object, Properties)
        -- // Set properties
        for Property, Value in pairs(Properties) do
            -- // Ignore if property is type
            if (table.find(Utilities.IgnoredDrawingProperties, Property)) then
                continue
            end

            -- // Set
            Object[Property] = Value
        end

        -- // Return
        return Object
    end


    -- // Creates a new drawing object
    function Utilities.CreateDrawing(Type, Properties)
        -- // Create the object
        local Object = getgenv()[Type].new()

        -- // Return
        return Utilities.SetDrawingProperties(Object, Properties)
    end
end

-- // Base class. This is an abstract class used to build the rest, make sure to duplicate the constructor, update method, and others
local Base = {}
Base.__index = Base
Base.__type = "Base"
do
    -- // Constructor
    function Base.new(Data, Properties)
        -- // Create the object
        local self = setmetatable({}, Base)

        -- // Vars
        self.Objects = self:InitialiseObjects(Data, Properties)

        -- // Return the object
        return self
    end

    -- // Initialises the objects by using the properties
    function Base.InitialiseObjects(self, Data, Properties)
        -- // Vars
        local Objects = {}

        -- // Loop through the properties
        for i, Property in pairs(Properties) do
            -- // Check if table
            if (typeof(Property) == "table") then
                Objects[i] = self:InitialiseObjects(Data, Property)
                continue
            end

            -- // Create the object and add it
            Objects[i] = Utilities.CreateDrawing(Property.Type, Property)
        end

        -- // Return
        return Objects
    end

    -- // Destroys all of the objects
    function Base.Destroy(self, TableObject)
        -- // Default
        TableObject = TableObject or self.Objects

        -- // Loop through
        for i, Object in pairs(TableObject) do
            -- // Check if is a table
            if (typeof(Object) == "table") then
                self:Destroy(Object)
                continue
            end

            -- // Destroy
            Object:Remove()
            TableObject[i] = nil
        end
    end

    -- // Updates the properties of properties (assumes only main and outline)
    function Base.Update(self, Corners)
        -- // Check for visibility
        local IsVisible = self.Data.Enabled and Corners.Corners[1].Z < 0

        -- // Vars
        local MainData = {self.AdditionalData.ColorOpacity(self)}
        local OutlineData = {self.AdditionalData.ColorOpacityOutline(self)}

        -- // Set the properties
        Utilities.SetDrawingProperties(self.ObjectsMain, {
            Color = MainData[1],
            Opacity = MainData[2],
            Visible = IsVisible
        })

        -- // Set properties
        Utilities.SetDrawingProperties(self.ObjectsMain, {
            Color = OutlineData[1],
            Opacity = OutlineData[2],
            Visible = IsVisible and self.Data.OutlineEnabled
        })
    end
end

-- // Box (Square) Class
local BoxSquare = {}
BoxSquare.__index = BoxSquare
BoxSquare.__type = "BoxSquare"
setmetatable(BoxSquare, Base)
do
    -- // Initialise box data
    BoxSquare.DefaultData = {
        Enabled = true,
        OutlineEnabled = true
    }
    BoxSquare.DefaultProperties = {
        Main = {
            Type = "RectDynamic",
            Thickness = 1,

            Outlined = true,
            OutlineColour = Color3.new(0, 0, 0),
            OutlineOpacity = 1,
            OutlineThickness = 3,

            MainColour = Color3.new(1, 0, 0),
            MainOpacity = 1,

            Visible = false,
        }
    }

    -- // Constructor
    function BoxSquare.new(Data, Properties)
        -- // Default values
        Data = Data or BoxSquare.DefaultData
        Properties = Properties or BoxSquare.DefaultProperties

        -- // Create the object
        local self = setmetatable({}, BoxSquare)

        -- // Vars
        self.Data = Data

        -- // Combine the properties and make the object(s)
        local DefaultProperties = BoxSquare.DefaultProperties
        self.Objects = self:InitialiseObjects(Data, Utilities.CombineTables(DefaultProperties, Properties))

        -- // Return the object
        return self
    end

    -- // Updates the properties
    function BoxSquare.Update(self, Corners)
        -- // Check for visibility
        local Data = self.Data
        local IsVisible = Data.Enabled and Corners.Corners[1].Z < 0
        local OutlineVisible = IsVisible and Data.OutlineEnabled

        -- // Vars
        local BoxPosition = Corners.TopLeft
        local BoxSize = Corners.BottomRight - Corners.TopLeft

        -- // Set the properties
        Utilities.SetDrawingProperties(self.ObjectsMain, {
            Position = BoxPosition,
            Size = BoxSize,

            Color = Data.MainColour,
            Opacity = Data.MainOpacity,

            Outlined = OutlineVisible,
            OutlineColor = Data.OutlineColour,
            OutlineOpacity = Data.OutlineOpacity,

            Visible = IsVisible
        })
    end
end

-- // Tracer Class
local Tracer = {}
Tracer.__index = Tracer
Tracer.__type = "Tracer"
setmetatable(Tracer, Base)
do
    -- // Initialise box data
    Tracer.DefaultData = {
        Enabled = true,
        OutlineEnabled = true
    }
    Tracer.DefaultProperties = {
        Main = {
            Type = "LineDynamic",
            Thickness = 1,

            Outlined = true,
            OutlineColour = Color3.new(0, 0, 0),
            OutlineOpacity = 1,
            OutlineThickness = 3,

            MainColour = Color3.new(1, 0, 0),
            MainOpacity = 1,

            Visible = false,
        }
    }

    -- // Constructor
    function Tracer.new(Data, Properties)
        -- // Default values
        Data = Data or Tracer.DefaultData
        Properties = Properties or Tracer.DefaultProperties

        -- // Create the object
        local self = setmetatable({}, Tracer)

        -- // Vars
        self.Data = Data

        -- // Combine the properties and make the object(s)
        local DefaultProperties = Tracer.DefaultProperties
        self.Objects = self:InitialiseObjects(Data, Utilities.CombineTables(DefaultProperties, Properties))

        -- // Return the object
        return self
    end

    -- // Updates the properties
    function Tracer.Update(self, Corners)
        -- // Check for visibility
        local Data = self.Data
        local IsVisible = Data.Enabled and Corners.Corners[1].Z < 0
        local OutlineVisible = IsVisible and Data.OutlineEnabled

        -- // Vars
        local ViewportSize = Utilities.GetCurrentCamera().ViewportSize
        local To = (Corners.BottomLeft + Corners.BottomRight) / 2
        local From =
            Data.TracerOrigin == "Middle" and ViewportSize / 2 or
            Data.TracerOrigin == "Top" and ViewportSize * Vector2.new(0.5, 0) or
            Data.TracerOrigin == "Bottom" and ViewportSize * Vector2.new(0.5, 1)

        -- // Set the properties
        Utilities.SetDrawingProperties(self.ObjectsMain, {
            To = To,
            From = From,

            Color = Data.MainColour,
            Opacity = Data.MainOpacity,

            Outlined = OutlineVisible,
            OutlineColor = Data.OutlineColour,
            OutlineOpacity = Data.OutlineOpacity,

            Visible = IsVisible
        })
    end
end

-- // Header (name) Class
local Header = {}
Header.__index = Header
Header.__type = "Header"
setmetatable(Header, Base)
do
    -- // Initialise box data
    Header.DefaultData = {
        Enabled = true,
        OutlineEnabled = true,

        Type = "Name", -- // Options: Name, Distance, Weapon
        Value = "N/A", -- // Name -> "PLAYERNAME", Distance -> 12.0, Weapon -> "AK-47"
        Font = 2,
        Size = 13,

        MainColour = Color3.new(1, 0, 0),
        MainOpacity = 1,

        OutlineColour = Color3.new(0, 0, 0),
        OutlineOpacity = 1,

        Formats = {
            Name = "%s",
            Distance = "%f studs"
        },

        --[[
            Below can be a function to return a dynamic offset. For example, if you have a Weapon and Distance header this helps avoid clashes:

            PSEUDOCODE
            function (self)
                local Base = Vector2.new(0, 2)
                if (not DistanceObject.Visible) then
                    return Base
                end

                return (Base + DistanceObject.TextBounds) * Vector2.yAxis
            end
        ]]
        Offset = Vector2.new(0, 2)
    }
    Header.DefaultProperties = {
        Main = {
            Type = "TextDynamic",

            Visible = false,
        }
    }

    -- // Constructor
    function Header.new(Data, Properties)
        -- // Default values
        Data = Data or Header.DefaultData
        Properties = Properties or Header.DefaultProperties

        -- // Create the object
        local self = setmetatable({}, Header)

        -- // Vars
        self.Data = Data

        -- // Combine the properties and make the object(s)
        local DefaultProperties = Header.DefaultProperties
        self.Objects = self:InitialiseObjects(Data, Utilities.CombineTables(DefaultProperties, Properties))

        -- // Return the object
        return self
    end

    -- // Calculates the position
    function Header.GetPosition(self, Corners)
        -- // Vars
        local Data = self.Data
        local Type = Data.Type
        local MainObject = self.Objects.Main

        -- // Grab the offset
        local Offset = typeof(Data.Offset) == "function" and Data.Offset(self) or Data.Offset

        -- // Name
        if (Type == "Name") then
            return ((Corners.TopLeft + Corners.TopRight) / 2) - (MainObject.TextBounds * Vector2.yAxis) - Offset
        end

        -- // Distance
        if (Type == "Distance" or Type == "Weapon") then
            return ((Corners.BottomLeft + Corners.BottomRight) / 2) + Offset
        end

        -- // Default
        return Vector2.zero
    end

    -- // Updates the properties
    function Header.Update(self, Corners)
        -- // Check for visibility
        local Data = self.Data
        local IsVisible = Data.Enabled and Corners.Corners[1].Z < 0
        local OutlineVisible = IsVisible and Data.OutlineEnabled

        -- // Set the properties
        Utilities.SetDrawingProperties(self.Objects.Main, {
            Position = self:GetPosition(),
            Text = Data.Formats[Data.Type]:format(Data.Value),

            Font = Data.Font,
            Size = Data.Size,

            Color = Data.MainColour,
            Opacity = Data.MainOpacity,

            Outlined = OutlineVisible,
            OutlineColor = Data.OutlineColour,
            OutlineOpacity = Data.OutlineOpacity,

            Visible = IsVisible
        })
    end
end


-- // Return
return {
    Utilities = Utilities,
    Base = Base,
    BoxSquare = BoxSquare,
    Tracer = Tracer,
    Header = Header
}