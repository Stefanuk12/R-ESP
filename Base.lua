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

-- // CIELUV - https://gist.github.com/Fraktality/8a833e3bea7471a05e388062efaf9886
local CIELUV = {}
do
    -- Combines two colors in CIELUV space.
	-- function<function<Color3 result>(float t)>(Color3 fromColor, Color3 toColor)

	-- https://www.w3.org/Graphics/Color/srgb

	local clamp = math.clamp
	local C3 = Color3.new
	local black = C3(0, 0, 0)

	-- Convert from linear RGB to scaled CIELUV

    function CIELUV.RgbToLuv13(c)
        local r, g, b = c.r, c.g, c.b
        -- Apply inverse gamma correction
		r = r < 0.0404482362771076 and r/12.92 or 0.87941546140213*(r + 0.055)^2.4
		g = g < 0.0404482362771076 and g/12.92 or 0.87941546140213*(g + 0.055)^2.4
		b = b < 0.0404482362771076 and b/12.92 or 0.87941546140213*(b + 0.055)^2.4
		-- sRGB->XYZ->CIELUV
		local y = 0.2125862307855956*r + 0.71517030370341085*g + 0.0722004986433362*b
		local z = 3.6590806972265883*r + 11.4426895800574232*g + 4.1149915024264843*b
		local l = y > 0.008856451679035631 and 116*y^(1/3) - 16 or 903.296296296296*y
		if z > 1e-15 then
			local x = 0.9257063972951867*r - 0.8333736323779866*g - 0.09209820666085898*b
			return l, l*x/z, l*(9*y/z - 0.46832)
		else
			return l, -0.19783*l, -0.46832*l
		end
    end

    function CIELUV.Lerp(t, c0, c1)
		local l0, u0, v0 = CIELUV.RgbToLuv13(c0)
		local l1, u1, v1 = CIELUV.RgbToLuv13(c1)

        -- Interpolate
        local l = (1 - t)*l0 + t*l1
        if l < 0.0197955 then
            return black
        end
        local u = ((1 - t)*u0 + t*u1)/l + 0.19783
        local v = ((1 - t)*v0 + t*v1)/l + 0.46832

        -- CIELUV->XYZ
        local y = (l + 16)/116
        y = y > 0.206896551724137931 and y*y*y or 0.12841854934601665*y - 0.01771290335807126
        local x = y*u/v
        local z = y*((3 - 0.75*u)/v - 5)

        -- XYZ->linear sRGB
        local r =  7.2914074*x - 1.5372080*y - 0.4986286*z
        local g = -2.1800940*x + 1.8757561*y + 0.0415175*z
        local b =  0.1253477*x - 0.2040211*y + 1.0569959*z

        -- Adjust for the lowest out-of-bounds component
        if r < 0 and r < g and r < b then
            r, g, b = 0, g - r, b - r
        elseif g < 0 and g < b then
            r, g, b = r - g, 0, b - g
        elseif b < 0 then
            r, g, b = r - b, g - b, 0
        end

        return C3(
            -- Apply gamma correction and clamp the result
            clamp(r < 3.1306684425e-3 and 12.92*r or 1.055*r^(1/2.4) - 0.055, 0, 1),
            clamp(g < 3.1306684425e-3 and 12.92*g or 1.055*g^(1/2.4) - 0.055, 0, 1),
            clamp(b < 3.1306684425e-3 and 12.92*b or 1.055*b^(1/2.4) - 0.055, 0, 1)
        )
	end
end

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

    -- // Deep copying
    function Utilities.DeepCopy(Original)
        -- // Vars
        local Copy = {}

        -- // Loop through original
        for i, v in pairs(Original) do
            -- // Recursion if table
            if (typeof(v) == "table") then
                v = Utilities.DeepCopy(v)
            end

            -- // Set
            Copy[i] = v
        end

        -- // Return the copy
        return Copy
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
    function Base:InitialiseObjects(Data, Properties)
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
    function Base:Destroy(TableObject)
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
    function Base:Update(Corners)
        -- // Check for visibility
        local IsVisible = self.Data.Enabled and Corners.Corners[1].Z < 0

        -- // Vars
        local MainData = {self.AdditionalData.ColorOpacity(self)}
        local OutlineData = {self.AdditionalData.ColorOpacityOutline(self)}

        -- // Set the properties
        Utilities.SetDrawingProperties(self.Objects.Main, {
            Color = MainData[1],
            Opacity = MainData[2],
            Visible = IsVisible
        })

        -- // Set properties
        Utilities.SetDrawingProperties(self.Objects.Main, {
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

            Color = Color3.new(1, 0, 0),
            Opacity = 1,

            Outlined = true,
            OutlineColor = Color3.new(0, 0, 0),
            OutlineOpacity = 1,
            OutlineThickness = 3,

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
    function BoxSquare:Update(Corners)
        -- // Check for visibility
        local Data = self.Data
        local Properties = Utilities.DeepCopy(self.Properties)
        local IsVisible = Data.Enabled and Corners.Corners[1].Z < 0
        local OutlineVisible = IsVisible and Data.OutlineEnabled

        -- // Vars
        local BoxPosition = Corners.TopLeft
        local BoxSize = Corners.BottomRight - Corners.TopLeft

        -- // Set the properties
        Utilities.SetDrawingProperties(self.Objects.Main, Utilities.CombineTables(Properties.Main, {
            Position = BoxPosition,
            Size = BoxSize,

            Outlined = OutlineVisible,
            Visible = IsVisible
        }))
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

            Color = Color3.new(1, 0, 0),
            Opacity = 1,

            Outlined = true,
            OutlineColor = Color3.new(0, 0, 0),
            OutlineOpacity = 1,
            OutlineThickness = 3,

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
    function Tracer:Update(Corners)
        -- // Check for visibility
        local Data = self.Data
        local Properties = Utilities.DeepCopy(self.Properties)
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
        Utilities.SetDrawingProperties(self.Objects.Main, Utilities.CombineTables(Properties.Main, {
            To = To,
            From = From,

            Outlined = OutlineVisible,
            Visible = IsVisible
        }))
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

            Font = 2,
            Size = 13,

            Color = Color3.new(1, 0, 0),
            Opacity = 1,

            OutlineColor = Color3.new(0, 0, 0),
            OutlineOpacity = 1,

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
    function Header:GetPosition(Corners)
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
    function Header:Update(Corners)
        -- // Check for visibility
        local Data = self.Data
        local Properties = Utilities.DeepCopy(self.Properties)
        local IsVisible = Data.Enabled and Corners.Corners[1].Z < 0
        local OutlineVisible = IsVisible and Data.OutlineEnabled

        -- // Set the properties
        Utilities.SetDrawingProperties(self.Objects.Main, Utilities.CombineTables(Properties.Main, {
            Position = self:GetPosition(),
            Text = Data.Formats[Data.Type]:format(Data.Value),

            Outlined = OutlineVisible,
            Visible = IsVisible
        }))
    end
end

-- // Healthbar Class
local Healthbar = {}
Healthbar.__index = Healthbar
Healthbar.__type = "Healthbar"
setmetatable(Healthbar, Base)
do
    -- // Initialise box data
    Healthbar.DefaultData = {
        Enabled = true,
        OutlineEnabled = true,

        Value = 0, -- // Current Health
        MaxValue = 100, -- // Maximum Health

        MinColour = Color3.new(1, 0, 0),
        MaxColour = Color3.new(0, 1, 0),

        Offset = Vector2.new(0, 2)
    }
    Healthbar.DefaultProperties = {
        Main = {
            Type = "LineDynamic",

            Thickness = 1,

            Color = Color3.new(1, 0, 0),
            Opacity = 1,

            Outlined = true,
            OutlineColor = Color3.new(0, 0, 0),
            OutlineOpacity = 1,
            OutlineThickness = 3,

            Visible = false,
        },
        Text = {
            Type = "TextDynamic",

            Font = 2,
            Size = 13,

            Color = Color3.new(1, 0, 0),
            Opacity = 1,

            OutlineColor = Color3.new(0, 0, 0),
            OutlineOpacity = 1,

            Visible = false
        }
    }

    -- // Constructor
    function Healthbar.new(Data, Properties)
        -- // Default values
        Data = Data or Healthbar.DefaultData
        Properties = Properties or Healthbar.DefaultProperties

        -- // Create the object
        local self = setmetatable({}, Healthbar)

        -- // Vars
        self.Data = Data

        -- // Combine the properties and make the object(s)
        local DefaultProperties = Healthbar.DefaultProperties
        self.Objects = self:InitialiseObjects(Data, Utilities.CombineTables(DefaultProperties, Properties))

        -- // Return the object
        return self
    end

    -- // Updates the properties
    function Healthbar:Update(Corners)
        -- // Check for visibility
        local Data = self.Data
        local Properties = Utilities.DeepCopy(self.Properties)
        local IsVisible = Data.Enabled and Corners.Corners[1].Z < 0
        local OutlineVisible = IsVisible and Data.OutlineEnabled

        -- // Vars
        local To = Corners.BottomLeft - Data.Offset
        local From = Corners.TopLeft - Data.Offset

        local ValueRatio = Data.Value / Data.MaxValue
        local LerpFrom = To:Lerp(From, ValueRatio)
        local LerpedColour = CIELUV.Lerp(ValueRatio, Data.MinColour, Data.MaxColour)

        -- // Set the properties
        Utilities.SetDrawingProperties(self.Objects.Main, Utilities.CombineTables(Properties.Main, {
            To = To,
            From = LerpFrom,

            Color = LerpedColour,

            Outlined = OutlineVisible,
            Visible = IsVisible
        }))

        local TextObject = self.Objects.Text
        Utilities.SetDrawingProperties(TextObject, Utilities.CombineTables(Properties.Text, {
            Text = math.round(Data.Value) .. "HP",
            Position = From - Data.Offset - TextObject.TextBounds / 2,

            Outlined = OutlineVisible,
            Visible = IsVisible
        }))
    end
end

-- // OffArrow Class
local OffArrow = {}
OffArrow.__index = OffArrow
OffArrow.__type = "OffArrow"
setmetatable(OffArrow, Base)
do
    -- // Initialise box data
    OffArrow.DefaultData = {
        Enabled = true,
        OutlineEnabled = true,

        Value = Vector2.zero, -- // direction -> Vector2.new(math.cos(Angle), math.sin(Angle))
        Radius = 5,

        Offset = Vector2.new(0, 2)
    }
    OffArrow.DefaultProperties = {
        Main = {
            Type = "PolyLineDynamic",

            Thickness = 1,

            FillType = PolyLineFillType.Closed,

            Color = Color3.new(1, 0, 0),
            Opacity = 1,

            Outlined = true,
            OutlineColor = Color3.new(0, 0, 0),
            OutlineOpacity = 1,
            OutlineThickness = 3,

            Visible = false,
        }
    }

    -- // Constructor
    function OffArrow.new(Data, Properties)
        -- // Default values
        Data = Data or OffArrow.DefaultData
        Properties = Properties or OffArrow.DefaultProperties

        -- // Create the object
        local self = setmetatable({}, OffArrow)

        -- // Vars
        self.Data = Data

        -- // Combine the properties and make the object(s)
        local DefaultProperties = OffArrow.DefaultProperties
        self.Objects = self:InitialiseObjects(Data, Utilities.CombineTables(DefaultProperties, Properties))

        -- // Return the object
        return self
    end

    -- // Calulcates direction
    function OffArrow:Direction(Origin, Destination)
        -- // Maths in order to get the angle
        local _, Yaw, Roll = Origin:ToOrientation()
        local FlatCFrame = CFrame.Angles(0, Yaw, Roll) + Origin.Position
        local ObjectSpace = FlatCFrame:PointToObjectSpace(Destination)
        local Angle = math.atan2(ObjectSpace.Z, ObjectSpace.X)

        -- // Return the direction
        return Vector2.new(math.cos(Angle), math.sin(Angle))
    end

    -- // Updates the properties
    function OffArrow:Update(Corners)
        -- // Check for visibility
        local Data = self.Data
        local Properties = Utilities.DeepCopy(self.Properties)
        local IsVisible = Data.Enabled and Corners.Corners[1].Z < 0
        local OutlineVisible = IsVisible and Data.OutlineEnabled

        -- // Vars
        local ViewportSize = Utilities.GetCurrentCamera().ViewportSize
        local Vector25 = Vector2.one * 25

        local Value = Data.Value
        local Radius = Data.Radius

        local PointA = (ViewportSize / 2 + Value * Radius):Max(Vector25):Min(ViewportSize - Vector25)
        local PointB = PointA - Utilities.RotateVector2(Value, 0.45) * Radius
        local PointC = PointA - Utilities.RotateVector2(Value, -0.45) * Radius

        -- // Set the properties
        Utilities.SetDrawingProperties(self.Objects.Main, Utilities.CombineTables(Properties.Main, {
            Points = {
                PointA,
                PointB,
                PointC
            },

            Outlined = OutlineVisible,
            Visible = IsVisible
        }))
    end
end

-- // Return
return {
    Utilities = Utilities,
    Base = Base,
    BoxSquare = BoxSquare,
    Tracer = Tracer,
    Header = Header,
    Healthbar = Healthbar,
    OffArrow = OffArrow
}