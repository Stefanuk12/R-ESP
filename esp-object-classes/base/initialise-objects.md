---
description: <table> Base:InitialiseObjects(<table> Data, <table> Properties)
---

# Initialise Objects

This initialises all of the Drawing objects based upon the `Properties` table.

{% hint style="info" %}
Follow this format for each entry in the `Properties` parameter

`[Key] = [Properties of object]`



Make sure to specify the `Type` in the `Properties of object`
{% endhint %}

## Parameters

<table><thead><tr><th>Name</th><th>Description</th><th>Type</th><th>Default</th><th data-type="checkbox">Optional</th></tr></thead><tbody><tr><td>Data</td><td>Special data properties</td><td>table</td><td>N/A</td><td>false</td></tr><tr><td>Properties</td><td>The properties to apply</td><td>table</td><td>N/A</td><td>false</td></tr></tbody></table>

## Return

`<table> the objects with the properties applied`
