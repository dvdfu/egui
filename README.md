# EGUI

EGUI is a GUI library written for the LÖVE2D framework. Its goal is to provide tools to build simple and lightweight GUI components. It targets mobile-like interaction but supports regular mouse input.

[hump](https://github.com/vrld/hump) is used for `Class`, `Vector`, and `Timer` modules.

## Example Use

```lua
EGUI = require('EGUI')
```

A new EGUI container can be created by calling `EGUI.Container()`. A table of properties and children can also be passed to the constructor. See **Properties** for a list of container properties.

```lua
container = EGUI.Container(props, children)
```

It may be useful to store property tables in a variable for reuse. The children table can be useful for creating nested container structures.

```lua
listProperties = {
    width = 160,
    height = 320,
    marginLeft = 16
}

itemProperties = {
    height = 32,
    fillWidth = true
}

list = EGUI.Container(listProperties, {
        EGUI.Container(itemProperties),
        EGUI.Container(itemProperties),
        EGUI.Container(itemProperties)
    })
```

## Properties

```lua
x
y
width
height
fillWidth -- fills parent container dimension
fillHeight

marginTop
marginBottom
marginLeft
marginRight
separation -- separation between children of a ListContainer

backgroundVisible
backgroundColor -- hex string
borderVisible
borderColor

onMouseEnter -- callback in the form of function(self, event)
onMouseHover
onMouseClick
onMouseLeave
```
