-- // Services
local Workspace = game:GetService("Workspace")

-- // Vars
local IsSynapseV3 = PolyLineDynamic ~= nil
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
    function Utilities.SetDrawingProperties(Object, Properties)
        -- // Set properties
        for Property, Value in pairs(Properties) do
            Object[Property] = Value
        end

        -- // Return
        return Object
    end

    -- // Creates a new drawing object
    function Utilities.CreateDrawing(Type, Properties)
        -- // Create the object
        local Object = IsSynapseV3 and getgenv()[Type].new() or Drawing.new(Type)

        -- // Return
        return Utilities.SetDrawingProperties(Object, Properties)
    end
end

-- // Box (Square) Class
local BoxSquare = {}
do
    -- // Initialise box data
    BoxSquare.__index = BoxSquare
    BoxSquare.__type = "Box"

    BoxSquare.DefaultData = {
        Enabled = true,
        OutlineEnabled = true
    }
    BoxSquare.DefaultProperties = {
        Main = {
            Thickness = 1,
            Visible = false
        },
        Outline = {
            Thickness = 3,
            Visible = false
        }
    }
    BoxSquare.AdditionalData = {
        ColorTransparency = function(self)
            return Color3.new(1, 0, 0), 1
        end,

        ColorTransparencyOutline = function(self)
            return Color3.new(0, 0, 0), 1
        end,
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
        self.Objects = {
            Main = Utilities.CreateDrawing("Square", Utilities.CombineTables(DefaultProperties.Main, Properties.Main)),
            Outline = Utilities.CreateDrawing("Square", Utilities.CombineTables(DefaultProperties.Outline, Properties.Outline))
        }

        -- // Return the object
        return self
    end

    -- // Destroys all of the objects
    function BoxSquare.Destroy(self)
        -- // Loop through all objects
        for i = #self.Objects, 1, -1 do
            -- // Remove the object and from the table
            self.Objects[i]:Remove()
            table.remove(self.Objects, i)
        end
    end

    -- // Updates the properties
    function BoxSquare.Update(self, Corners)
        -- // Check for visibility
        local BoxVisible = self.Data.Enabled and Corners.Corners[1].Z < 0
        if (not BoxVisible) then
            return
        end

        -- // Vars
        local MainData = {self.AdditionalData.ColorTransparency(self)}
        local OutlineData = {self.AdditionalData.ColorTransparencyOutline(self)}

        local BoxPosition = Corners.TopLeft
        local BoxSize = Corners.BottomRight - Corners.TopLeft

        -- // Set the properties
        Utilities.SetDrawingProperties(self.ObjectsMain, {
            Position = BoxPosition,
            Size = BoxSize,
            Color = MainData[1],
            Transparency = MainData[2]
        })

        -- // Make sure outline enabled
        if (not self.Data.OutlineEnabled) then
            return
        end

        -- // Set properties
        Utilities.SetDrawingProperties(self.ObjectsMain, {
            Position = BoxPosition,
            Size = BoxSize,
            Color = OutlineData[1],
            Transparency = OutlineData[2]
        })
    end
end

-- // Return
return {
    BoxSquare = BoxSquare
}