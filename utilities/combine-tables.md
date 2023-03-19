---
description: <table> Utilities.CombineTables(<table> Base, <table> ToAdd)
---

# 🔨 Combine Tables

Merges the `ToAdd` table onto the `Base` table.

{% hint style="danger" %}
The `Base` table will get modified, if you do not want it to be affected, use the [DeepCopy](deep-copy.md) function.
{% endhint %}

## Parameters

<table><thead><tr><th>Name</th><th>Description</th><th>Type</th><th>Default</th><th data-type="checkbox">Optional</th></tr></thead><tbody><tr><td>Base</td><td>The table to merge onto</td><td>table</td><td><code>{}</code></td><td>true</td></tr><tr><td>ToAdd</td><td>The table to merge from</td><td>table</td><td><code>{}</code></td><td>true</td></tr></tbody></table>

## Return

`<table> the merged table`
