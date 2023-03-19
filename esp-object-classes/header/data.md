---
description: The options for Data in the constructor
---

# Data

## Parameters

<table><thead><tr><th>Name</th><th>Description</th><th>Type</th><th>Default</th><th data-type="checkbox">Optional</th></tr></thead><tbody><tr><td>Enabled</td><td>Toggle the entire instance</td><td>boolean</td><td>N/A</td><td>true</td></tr><tr><td>OutlineEnabled</td><td>Toggle the outline</td><td>boolean</td><td>N/A</td><td>true</td></tr><tr><td>Type</td><td>The type of header</td><td><a href="data.md#headertype">HeaderType</a></td><td>Name</td><td>true</td></tr><tr><td>Value</td><td>The value to display</td><td>string, number</td><td>N/A</td><td>true</td></tr><tr><td>Formats</td><td>The string formats for each <code>Type</code></td><td><a href="data.md#headerformat">HeaderFormat</a></td><td>N/A</td><td>true</td></tr><tr><td>Offset</td><td>Additional offset</td><td>Vector2</td><td><code>0, 0</code></td><td>true</td></tr></tbody></table>

## HeaderType

| Name     | Description                           | Type   |
| -------- | ------------------------------------- | ------ |
| Name     | Displays the name of the object       | string |
| Distance | Displays the distance from the object | string |
| Weapon   | Displays the object's weapon          | string |

## HeaderFormat

| Name     | Default       | Type   |
| -------- | ------------- | ------ |
| Name     | `%s`          | string |
| Weapon   | `%s`          | string |
| Distance | `%0.1f studs` | string |

