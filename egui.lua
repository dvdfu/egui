local Class = require('hump/class')
local Vector = require('hump/vector')

--============================================================================== HELPERS

function hexToRGB(hex)
    hex = hex:gsub('#', '')
    return
        tonumber('0x'..hex:sub(1, 2)),
        tonumber('0x'..hex:sub(3, 4)),
        tonumber('0x'..hex:sub(5, 6))
end

--============================================================================== RECTANGLE

local Rectangle = Class {}

function Rectangle:init(x, y, w, h)
    self.pos = Vector(x, y)
    self.size = Vector(w, h)
end

function Rectangle:intersects(other)
    return self.pos.x < other.pos.x + other.size.x and
        self.pos.x + self.size.x > other.pos.x and
        self.pos.y < other.pos.y + other.size.y and
        self.pos.y + self.size.y > other.pos.y
end

function Rectangle:intersectsChild(child)
    return child.pos.x + child.size.x > 0 and
        child.pos.x < self.size.x and
        child.pos.y + child.size.y > 0 and
        child.pos.y < self.size.y
end

function Rectangle:draw(mode)
    mode = mode or 'line'
    love.graphics.rectangle(mode, self.pos.x, self.pos.y, self.size.x, self.size.y)
end

--============================================================================== CONTAINER

local Container = Class {
    defaultProps = {
        x = 0,
        y = 0,
        width = 0,
        height = 0,
        fillWidth = false,
        fillHeight = false,
        marginTop = 0,
        marginBottom = 0,
        marginLeft = 0,
        marginRight = 0,
        backgroundVisible = true,
        backgroundColor = '#ffffff',
        borderVisible = true,
        borderColor = '#888888',
    }
}

function Container:init(props, children)
    self.props = {}
    props = props or {}
    for prop, val in pairs(Container.defaultProps) do
        self.props[prop] = props[prop] or val
    end

    self.parent = nil
    self.children = {}
    children = children or {}
    for _, child in pairs(children) do
        self:add(child)
    end
end

function Container:add(child)
    table.insert(self.children, child)
    child.parent = self
    child:refresh()
end

function Container:refresh()
    self.bounds = nil
    self.innerBounds = nil

    for prop, val in pairs(self.props) do
        if prop == 'fillWidth' and val then
            self.props.width = self.parent:getInnerBounds().size.x
        elseif prop == 'fillHeight' and val then
            self.props.height = self.parent:getInnerBounds().size.y
        end
    end

    for _, child in pairs(self.children) do
        child:refresh()
    end
end

function Container:getBounds()
    if self.bounds then return self.bounds end
    self.bounds = Rectangle(self.props.x, self.props.y, self.props.width, self.props.height)
    return self.bounds
end

function Container:getInnerBounds()
    if self.innerBounds then return self.innerBounds end
    self.innerBounds = Rectangle(
        self.props.x + self.props.marginLeft,
        self.props.y + self.props.marginRight,
        self.props.width - self.props.marginLeft - self.props.marginRight,
        self.props.height - self.props.marginTop - self.props.marginBottom)
    return self.innerBounds
end

function Container:draw()
    if self.props.backgroundVisible then
        love.graphics.setColor(hexToRGB(self.props.backgroundColor))
        self:getBounds():draw('fill')
        love.graphics.setColor(255, 255, 255)
    end

    if self.props.borderVisible then
        love.graphics.setColor(hexToRGB(self.props.borderColor))
        self:getBounds():draw('line')
        love.graphics.setColor(255, 255, 255)
    end

    if #self.children > 0 then
        love.graphics.push()
        love.graphics.translate(
            self.props.x + self.props.marginLeft,
            self.props.y + self.props.marginTop)

        for _, child in pairs(self.children) do
            if self:getBounds():intersectsChild(child:getBounds()) then
                child:draw()
            end
        end

        love.graphics.pop()
    end
end

--============================================================================== CONTAINER

local ListContainer = Class { __includes = Container }

return {
    Container = Container,
    ListContainer = ListContainer
}
