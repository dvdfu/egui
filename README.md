# EGUI

EGUI is a GUI library written for the LÖVE2D framework. Its goal is to provide performant tools to build simple and lightweight GUI components. It targets mobile-like interaction but supports regular mouse input.

[hump](https://github.com/vrld/hump) is used for `Class`, `Vector`, and `Timer` modules.

# Usage

Require the EGUI library:

```lua
EGUI = require('EGUI')
```

## Container

```lua
local container = EGUI.Container(properties, children)
```

`properties` is a table of container property values. If omitted, default property values will be assigned. It is convenient to store the properties table in a variable for reuse.

`children` is a table containing other containers that will become direct children. This is useful for immediately creating nested container structures.

```lua
local parentProperties = { ... }
local childProperties = { ... }

local container = EGUI.Container(parentProperties, {
        EGUI.Container(childProperties),
        EGUI.Container(childProperties),
        EGUI.Container(childProperties)
    })
```

## ListContainer

```lua
local container = EGUI.ListContainer(properties, children)
```

Functions like a `Container`. Children are arranged in a single column so that none overlap. When a child is removed, the gap is closed. There are some properties specific to `ListContainer`:

* `separation` - spacing between adjacent elements of the list
* `expands` - if set to true, the height of the list is purely determined by the list elements

## RowContainer

```lua
local container = EGUI.RowContainer(properties, children)
```

A `RowContainer` is identical to a `ListContainer`, except it aligns its children horizontally.
