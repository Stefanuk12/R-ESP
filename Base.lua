--[[
    Information:
    Contains the classes needed for the ESP. Additional logic is needed to make it functional

    Note:
    - This only works for Synapse V3, I may make a v2 -> v3 converter in the future
]]

-- // Services
local Workspace = game:GetService("Workspace")

-- // Vars
local ZeroVector2 = Vector2.zero
local DefaultFont = DrawFont.RegisterDefault("SegoeUI", {})
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
        Base = Base or {}
        ToAdd = ToAdd or {}

        -- // Loop through data we want to add
        for i, v in pairs(ToAdd) do
            -- // Recursive
            local BaseValue = Base[i] or false
            if (typeof(v) == "table" and typeof(BaseValue) == "table") then
                Utilities.CombineTables(BaseValue, v)
                continue
            end

            -- // Set
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

-- // Utilities - continued
do
    -- // Converts Vector3 to Vector2
    function Utilities.ConvertV3toV2(Vector)
        -- // Convert if vector 3
        if (typeof(Vector) == "Vector3") then
            return Vector2.new(Vector.X, Vector.Y)
        end

        -- // Loop through all vectors
        local Vectors = {}
        for i, v in ipairs(Vector) do
            Vectors[i] = Utilities.ConvertV3toV2(v)
        end

        -- // Return
        return Vectors
    end

    -- // Gets the corners of a part (or bounding box)
    function Utilities.CalculateCorners(PartCFrame, PartSize)
        -- // Vars
        local HalfSize = PartSize / 2
        local Corners = table.create(#Vertices)

        -- // Calculate each corner
        for i, Vertex in ipairs(Vertices) do
            Corners[i] = (PartCFrame + (HalfSize * Vertex)).Position
        end

        -- // Convert to screen
        local Corners2D = worldtoscreen(Corners)
        local Corners2DV2 = Utilities.ConvertV3toV2(Corners2D)

        -- // Get min and max
        local CurrentCamera = Utilities.GetCurrentCamera()
        local MinPosition = CurrentCamera.ViewportSize:Min(unpack(Corners2DV2))
        local MaxPosition = ZeroVector2:Max(unpack(Corners2DV2))

        -- // Add data to table
        local mathfloor = math.floor
        local ApplyVector2 = Utilities.ApplyVector2
        local Data = {
            Corners = Corners2D,
            Centre3D = PartCFrame.Position,

            TopLeft = ApplyVector2(MinPosition, mathfloor),
            TopRight = ApplyVector2(Vector2.new(MaxPosition.X, MinPosition.Y), mathfloor),
            BottomLeft = ApplyVector2(Vector2.new(MinPosition.X, MaxPosition.Y), mathfloor),
            BottomRight = ApplyVector2(MaxPosition, mathfloor),
        }

        -- // Get centre and onscreen
        local CentrePos, OnScreen = CurrentCamera:WorldToViewportPoint(Data.Centre3D)
        Data.Centre = CentrePos
        Data.OnScreen = OnScreen

        -- // Return
        return Data
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
    function Utilities.CreateDrawing(Properties)
        -- // Create the object
        local Object = getgenv()[Properties.Type].new()

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
            if (typeof(Property) ~= "table") then
                continue
            end

            -- // Create the object and add it
            Objects[i] = Utilities.CreateDrawing(Property)
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
        local IsVisible = self.Data.Enabled

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
            OutlineThickness = 1,

            Visible = false
        }
    }

    -- // Constructor
    function BoxSquare.new(Data, Properties)
        -- // Default values
        Data = Data or {}
        Properties = Properties or {}

        -- // Create the object
        local self = setmetatable({}, BoxSquare)

        -- // Vars
        self.Data = Utilities.CombineTables(Utilities.DeepCopy(BoxSquare.DefaultData), Data)
        self.Properties = Utilities.CombineTables(Utilities.DeepCopy(BoxSquare.DefaultProperties), Properties)

        -- // Make the object(s)
        self.Objects = self:InitialiseObjects(self.Data, self.Properties)

        -- // Return the object
        return self
    end

    -- // Updates the properties
    function BoxSquare:Update(Corners)
        -- // Check for visibility
        local Data = self.Data
        local Properties = Utilities.DeepCopy(self.Properties)
        local IsVisible = Data.Enabled and Corners.OnScreen
        local OutlineVisible = IsVisible and Data.OutlineEnabled

        -- // Set the properties
        Utilities.SetDrawingProperties(self.Objects.Main, Utilities.CombineTables(Properties.Main, {
            Position = Corners.TopLeft,
            BottomRight = Corners.BottomRight,

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
        OutlineEnabled = true,

        TracerOrigin = "Bottom" -- // Top, Middle, Bottom
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
            OutlineThickness = 1,

            Visible = false,
        }
    }

    -- // Constructor
    function Tracer.new(Data, Properties)
        -- // Default values
        Data = Data or {}
        Properties = Properties or {}

        -- // Create the object
        local self = setmetatable({}, Tracer)

        -- // Vars
        self.Data = Utilities.CombineTables(Utilities.DeepCopy(Tracer.DefaultData), Data)
        self.Properties = Utilities.CombineTables(Utilities.DeepCopy(Tracer.DefaultProperties), Properties)

        -- // Make the object(s)
        self.Objects = self:InitialiseObjects(self.Data, self.Properties)

        -- // Return the object
        return self
    end

    -- // Updates the properties
    function Tracer:Update(Corners)
        -- // Check for visibility
        local Data = self.Data
        local Properties = Utilities.DeepCopy(self.Properties)
        local IsVisible = Data.Enabled and Corners.OnScreen
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
            Weapon = "%s",
            Distance = "%0.1f studs",
        },

        --[[
            Below can be a function to return a dynamic offset. For example, if you have a Weapon and Distance header this helps avoid clashes:

            PSEUDOCODE
            function (self)
                local Base = Vector2.new(0, 0)
                if (not DistanceObject.Visible) then
                    return Base
                end

                return (Base + DistanceObject.TextBounds) * Vector2.yAxis
            end

            SEE MANAGER FOR A BETTER EXAMPLE
        ]]
        Offset = Vector2.new(0, 0)
    }
    Header.DefaultProperties = {
        Main = {
            Type = "TextDynamic",

            Font = DefaultFont,
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
        Data = Data or {}
        Properties = Properties or {}

        -- // Create the object
        local self = setmetatable({}, Header)

        -- // Vars
        self.Data = Utilities.CombineTables(Utilities.DeepCopy(Header.DefaultData), Data)
        self.Properties = Utilities.CombineTables(Utilities.DeepCopy(Header.DefaultProperties), Properties)

        -- // Make the object(s)
        self.Objects = self:InitialiseObjects(self.Data, self.Properties)

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
        local IsVisible = Data.Enabled and Corners.OnScreen
        local OutlineVisible = IsVisible and Data.OutlineEnabled

        -- // Set the properties
        Utilities.SetDrawingProperties(self.Objects.Main, Utilities.CombineTables(Properties.Main, {
            Position = self:GetPosition(Corners),
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

        Offset = Vector2.new(0, 0),
        TextOffset = Vector2.new(5, 0),
        WidthOffset = 5 -- // %
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
            OutlineThickness = 1,

            Visible = false,
        },
        Text = {
            Type = "TextDynamic",

            Font = DefaultFont,
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
        Data = Data or {}
        Properties = Properties or {}

        -- // Create the object
        local self = setmetatable({}, Healthbar)

        -- // Vars
        self.Data = Utilities.CombineTables(Utilities.DeepCopy(Healthbar.DefaultData), Data)
        self.Properties = Utilities.CombineTables(Utilities.DeepCopy(Healthbar.DefaultProperties), Properties)

        -- // Make the object(s)
        self.Objects = self:InitialiseObjects(self.Data, self.Properties)

        -- // Return the object
        return self
    end

    -- // Updates the properties
    function Healthbar:Update(Corners)
        -- // Check for visibility
        local Data = self.Data
        local Properties = Utilities.DeepCopy(self.Properties)
        local IsVisible = Data.Enabled and Corners.OnScreen
        local OutlineVisible = IsVisible and Data.OutlineEnabled

        -- // Vars
        local Width = (Corners.TopLeft - Corners.BottomRight) * (Data.WidthOffset / 100) * Vector2.xAxis
        local CombinedOffset = Width - Data.Offset
        local To = Corners.BottomLeft + CombinedOffset
        local From = Corners.TopLeft + CombinedOffset

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
            Position = LerpFrom - Data.TextOffset - TextObject.TextBounds / 2,

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

        Radius = 150,
        Size = 15,

        Offset = Vector2.new(0, 0)
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
            OutlineThickness = 1,

            Visible = false,
        }
    }

    -- // Constructor
    function OffArrow.new(Data, Properties)
        -- // Default values
        Data = Data or {}
        Properties = Properties or {}

        -- // Create the object
        local self = setmetatable({}, OffArrow)

        -- // Vars
        self.Data = Utilities.CombineTables(Utilities.DeepCopy(OffArrow.DefaultData), Data)
        self.Properties = Utilities.CombineTables(Utilities.DeepCopy(OffArrow.DefaultProperties), Properties)

        -- // Make the object(s)
        self.Objects = self:InitialiseObjects(self.Data, self.Properties)

        -- // Return the object
        return self
    end

    -- // Calulcates direction
    function OffArrow:Direction(Destination, Origin)
        -- // Default
        Origin = Origin or Utilities.GetCurrentCamera().CFrame

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
        local Centre3D = Corners.Centre3D
        local IsVisible = Data.Enabled and not Corners.OnScreen
        local OutlineVisible = IsVisible and Data.OutlineEnabled

        -- // Vars
        local ViewportSize = Utilities.GetCurrentCamera().ViewportSize
        local Vector25 = Vector2.one * 25

        -- // Workout the value (direction)
        local Value = Data.Value or self:Direction(Centre3D)

        -- // Work out points
        local Size = Data.Size
        local PointA = (ViewportSize / 2 + Value * Data.Radius):Max(Vector25):Min(ViewportSize - Vector25)
        local PointB = PointA - Utilities.RotateVector2(Value, 0.45) * Size
        local PointC = PointA - Utilities.RotateVector2(Value, -0.45) * Size

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

-- // Box 3D Class
local Box3D = {}
Box3D.__index = Box3D
Box3D.__type = "Box3D"
setmetatable(Box3D, Base)
do
    -- // Initialise box data
    Box3D.DefaultData = {
        Enabled = true,
        OutlineEnabled = true,
    }
    Box3D.DefaultProperties = table.create(4, {-- // Create each face
        Type = "PolyLineDynamic",
        Thickness = 1,

        Outlined = true,
        OutlineColor = Color3.new(0, 0, 0),
        OutlineOpacity = 1,
        OutlineThickness = 1,

        Visible = false,
        ZIndex = -1
    })

    -- // Constructor
    function Box3D.new(Data, Properties)
        -- // Default values
        Data = Data or {}
        Properties = Properties or {}

        -- // Create the object
        local self = setmetatable({}, Box3D)

        -- // Vars
        self.Data = Utilities.CombineTables(Utilities.DeepCopy(Box3D.DefaultData), Data)
        self.Properties = Utilities.CombineTables(Utilities.DeepCopy(Box3D.DefaultProperties), Properties)

        -- // Make the object(s)
        self.Objects = self:InitialiseObjects(self.Data, self.Properties)

        -- // Return the object
        return self
    end

    -- // Updates the properties
    function Box3D:Update(Corners)
        -- // Check for visibility
        local Data = self.Data
        local Properties = Utilities.DeepCopy(self.Properties)
        local IsVisible = Data.Enabled and Corners.OnScreen
        local OutlineVisible = IsVisible and Data.OutlineEnabled

        -- // Loop through each face
        local CornersArray = Utilities.ConvertV3toV2(Corners.Corners)
        local PointArray = {1, 5, 4}
        for i = 1, #Properties do
            -- // Create the points table
            local Points = {CornersArray[i]}
            for j = 1, 2 do
                local Point = CornersArray[(i % 4) + PointArray[j]]
                table.insert(Points, Point)
            end
            table.insert(Points, CornersArray[i == 4 and 8 or (i + PointArray[3])])

            -- // Set properties
            Utilities.SetDrawingProperties(self.Objects[i], Utilities.CombineTables(Properties[i], {
                Points = Points,

                Outlined = OutlineVisible,
                Visible = IsVisible
            }))
        end
    end
end

-- // Return
local RESP_BASE = {
    Utilities = Utilities,
    Base = Base,
    BoxSquare = BoxSquare,
    Tracer = Tracer,
    Header = Header,
    Healthbar = Healthbar,
    OffArrow = OffArrow,
    Box3D = Box3D
}
getgenv().RESP_BASE = RESP_BASE
return RESP_BASE