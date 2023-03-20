---
description: <Base> InstanceObject:Add(<string> Type, <table> Data, <table> Properties)
---

# Add

Attempts to initialise a [base ESP object](../../esp-object-classes/base/) of `Type` with `Data` and `Properties`. Uses [Base.new](../../esp-object-classes/base/constructor.md) to initialise the object.

{% hint style="danger" %}
Do not add many objects of same `Type` and `SubType`. It will error otherwise.
{% endhint %}

## Parameters

<table><thead><tr><th>Name</th><th>Description</th><th>Type</th><th>Default</th><th data-type="checkbox">Optional</th></tr></thead><tbody><tr><td>Type</td><td>The type to search for</td><td>string</td><td>N/A</td><td>false</td></tr><tr><td>Data</td><td>Special data properties</td><td>table</td><td>N/A</td><td>false</td></tr><tr><td>Properties</td><td>The properties to use for the objects</td><td>table</td><td>N/A</td><td>false</td></tr></tbody></table>

## Return

`<Base> the created object`
