---
description: Getting started on using the library
---

# ⁉ Usage

## Base Class

This library is designed to be very customisable and provides you a lot of power. All ESP object classes are subclasses of the [Base ](../esp-object-classes/base/)class. This allows you to easily make custom objects, all you have to do is copy the constrcutor and change the metatable to your own. Then, change the update method.

You can use this template below, make sure to change the class name in every place. You don't need to change the constructor after that, only the update function.

```lua
local NewClass = {}
NewClass.__index = NewClass
NewClass.__type = "NewClass"
setmetatable(NewClass, Base)
do
    -- // Constructor
    function NewClass.new(Data, Properties)
        -- // Default values
        Data = Data or {}
        Properties = Properties or {}
    
        -- // Create the object
        local self = setmetatable({}, NewClass)
    
        -- // Vars
        self.Data = Utilities.CombineTables(Utilities.DeepCopy(NewClass.DefaultData), Data)
        self.Properties = Utilities.CombineTables(Utilities.DeepCopy(NewClass.DefaultProperties), Properties)
    
        -- // Make the object(s)
        self.Objects = self:InitialiseObjects(self.Data, self.Properties)
    
        -- // Return the object
        return self
    end
    
    -- // Updates the properties
    function NewClass:Update(Corners)
        -- // Check for visibility
        local Data = self.Data
        local Properties = Utilities.DeepCopy(self.Properties)
        local IsVisible = Data.Enabled
        local OutlineVisible = IsVisible and Data.OutlineEnabled
    
        -- // Set the properties
        Utilities.SetDrawingProperties(self.Objects.Main, Utilities.CombineTables(Properties.Main, {
            Outlined = OutlineVisible,
            Visible = IsVisible
        }))
    end
end
```

## Changing data

Some classes have special data that you can change. For example, [Headers ](../esp-object-classes/header/)have [custom types](../esp-object-classes/header/data.md#headertype). When initialising the object, the first argument is a table with all of the custom data.

{% hint style="info" %}
The tables are merged so no need to copy and paste every single property from the defaults
{% endhint %}

```lua
local HeaderObject = Header.new({
    Type = "Distance"
    Value = 0
})
```

## Changing properties

Similiarly to [changing data](usage.md#changing-data), you can change individual object properties. Certain properties like `Size` are omitted from `Data` as they are here instead. These properties reflect the properties of the DrawEntry connected to it.

{% hint style="danger" %}
Do not pass properties that are not properties of the `DrawEntry` otherwise it will error. For example, if the `Type` is `TextDynamic`, do not pass a property like `Value` as it's not a valid property of `TextDynamic`.
{% endhint %}

```lua
local HeaderObject = Header.new(nil, {
    Main = {
        Size = 15
    }
})
```

## Rendering

By default, there are `Managers` which help you with updating and rendering the objects. For more information, please go to their respected page. Essentially, these managers allow you to pass an object, be it a `Player` or a `Model`, and it will automatically update the position, visibility, etc based upon the [Update ](../esp-object-classes/base/update.md)function of the ESP objects connected to it.

## Globals

When loading the library, some globals will be set in `getgenv()`. Mainly `RESP_BASE` when loading `Base.lua` and `RESP_MANAGER` when loading `Manager.lua`. If you want to see what they include, simply scroll to the bottom the script.
