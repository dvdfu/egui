# EGUI

EGUI is a GUI library written for the LÖVE2D framework. Its goal is to provide performant tools to build simple and lightweight GUI components. It targets mobile-like interaction but supports regular mouse input.

[hump](https://github.com/vrld/hump) is used for `Class`, `Vector`, and `Timer` modules.

# Usage

## Container

A new `Container` is created by calling `EGUI.Container()`. A table of properties and children can be passed to the constructor. See **Properties** for a list of all container properties.

```lua
EGUI = require('EGUI')
container = EGUI.Container(properties, children)
```

* it is useful to store the properties table in a variable for reuse
* the children table is useful for creating nested container structures

## ListContainer

A new `ListContainer` is created by calling `EGUI.ListContainer()`. These containers arrange children in a single column so that none overlap. When a child is removed, the gap is closed.

* the `separation` property defines vertical spacing between children
* if `expands` is set, the height of the container matches the height of its children combined

```lua
listProperties = {
    width = 100,
    expands = true
}

itemProperties = {
    height = 20,
    fillWidth = true
}

list = EGUI.ListContainer(listProperties, {
        EGUI.Container(itemProperties),
        EGUI.Container(itemProperties),
        EGUI.Container(itemProperties)
    })
```

## RowContainer

A `RowContainer` is identical to a `ListContainer`, except it aligns its children horizontally.

# Properties

```lua
x
y
width
height
fillWidth -- fills parent container dimension
fillHeight
alignH -- alignment within parent container
alignV

marginTop
marginBottom
marginLeft
marginRight
separation -- separation between children of a ListContainer
expands -- ListContainer expands size as children are added

backgroundVisible
backgroundColor -- hex string
borderVisible
borderColor

onMouseEnter -- callback in the form of function(self, event)
onMouseHover
onMouseClick
onMouseWheel
onMouseLeave
```
