local Class = require('hump/class')
local Vector = require('hump/vector')
local Timer = require('hump/timer')

--============================================================================== HELPERS

local function hexToRGB(hex)
    hex = hex:gsub('#', '')
    return
        tonumber('0x'..hex:sub(1, 2)),
        tonumber('0x'..hex:sub(3, 4)),
        tonumber('0x'..hex:sub(5, 6))
end

local function nullFunction() end

--============================================================================== RECTANGLE

local Rectangle = Class {}

function Rectangle:init(x, y, w, h)
    self.pos = Vector(x, y)
    self.size = Vector(w, h)
end

function Rectangle:intersects(other)
    return self.pos.x <= other.pos.x + other.size.x and
        self.pos.x + self.size.x >= other.pos.x and
        self.pos.y <= other.pos.y + other.size.y and
        self.pos.y + self.size.y >= other.pos.y
end

function Rectangle:getIntersection(other)
    local l = math.max(self.pos.x, other.pos.x)
    local r = math.min(self.pos.x + self.size.x, other.pos.x + other.size.x)
    local u = math.max(self.pos.y, other.pos.y)
    local d = math.min(self.pos.y + self.size.y, other.pos.y + other.size.y)
    if r - l < 0 or d - u < 0 then return nil end
    return Rectangle(l, u, r - l, d - u)
end

function Rectangle:contains(x, y)
    return x >= self.pos.x and x < self.pos.x + self.size.x and
        y >= self.pos.y and y < self.pos.y + self.size.y
end

function Rectangle:unpack()
    return self.pos.x, self.pos.y, self.size.x, self.size.y
end

function Rectangle:draw(mode)
    mode = mode or 'line'
    love.graphics.rectangle(mode, self.pos.x, self.pos.y, self.size.x, self.size.y)
end

--============================================================================== CONTAINER

local Container = Class {
    defaultProps = {
        -- position and size
        x = 0,
        y = 0,
        width = 0,
        height = 0,
        fillWidth = false,
        fillHeight = false,
        alignH = 'none', --TODO
        alignV = 'none',
        -- margin and spacing
        marginTop = 0,
        marginBottom = 0,
        marginLeft = 0,
        marginRight = 0,
        -- background and border
        backgroundVisible = false,
        backgroundColor = '#ffffff',
        borderVisible = false,
        borderColor = '#888888',
        -- callbacks
        onDraw = nullFunction,
        onMouseClick = nullFunction,
        onMouseWheel = nullFunction,
        onMouseEnter = nullFunction,
        onMouseLeave = nullFunction,
        -- ListContainer
        separation = 0,
        expands = false,
        -- ScrollContainer
        showScrollbar = true,
        scrollMultiplier = 8,
        scrollDecay = 0.9,
        -- Text
        font = love.graphics.newFont(12),
        fontColor = '#000000'
    },
    defaultLayout = {
        offsetX = 0,
        offsetY = 0,
        alpha = 1,
        visible = true,
        scrollSpeed = 0
    },
    mouseTarget = nil
}

function Container:init(props, children)
    props = props or {}
    children = children or {}

    self.parent = nil
    self.children = {}
    self.props = {}
    self.temp = {}
    self.layout = {}

    for prop, val in pairs(Container.defaultProps) do
        self.props[prop] = props[prop] or val
    end

    for item, val in pairs(Container.defaultLayout) do
        self.layout[item] = val
    end

    for _, child in pairs(children) do
        self:add(child)
    end
end

function Container:add(child)
    table.insert(self.children, child)
    child.parent = self
    child:refresh()

    self:refresh() -- TODO reduce uses of refresh
end

function Container:remove(child)
    for k, v in pairs(self.children) do
        if v == child then
            table.remove(self.children, k)
        end
    end

    self:refresh()
end

function Container:removeIndex(index)
    self:remove(self.children[index])
end

-- update animation timers
function Container:update(dt)
    if self.timer then
        self.timer.update(dt)
    end

    for _, child in pairs(self.children) do
        child:update(dt)
    end
end

-- called when a change is made to a container or any of its parents
-- clears temporary properties and forces recalculation
function Container:refresh()
    self.temp = {}
    self:refreshProps()
    self:refreshChildren()
end

-- properties that need to be updated when a container is refreshed
function Container:refreshProps()
    -- TODO reduce number of properties that need to be redone
    for prop, val in pairs(self.props) do
        if prop == 'fillWidth' and val and self.parent then
            self.props.width = self.parent:getInnerBounds().size.x
        elseif prop == 'fillHeight' and val and self.parent then
            self.props.height = self.parent:getInnerBounds().size.y
        end
    end
end

function Container:refreshChildren()
    for _, child in pairs(self.children) do
        child:refresh()
    end
end

function Container:sendMouseEvent(event)
    if not self.layout.visible then return false end
    local sent = false

    for _, child in pairs(self.children) do
        if event.type == 'moved' or child:getTrueBounds():contains(event.x, event.y) then
            if child:sendMouseEvent(event) then
                sent = true
            end
        end
    end

    if sent then return true end

    if event.type == 'press' then
        if self.props.onMouseClick ~= nullFunction then
            self.props.onMouseClick(self, event)
            return true
        end
    elseif event.type == 'wheel' then
        if self.props.onMouseWheel ~= nullFunction then
            self.props.onMouseWheel(self, event)
            return true
        end
    elseif event.type == 'moved' then
        if self:getTrueBounds():contains(event.x, event.y) then
            local target = Container.mouseTarget
            if target ~= self then
                if target and target.props.onMouseLeave ~= nullFunction then
                    target.props.onMouseLeave(target, event)
                end
                if self.props.onMouseEnter ~= nullFunction then
                    self.props.onMouseEnter(self, event)
                end
            end
            Container.mouseTarget = self
            return true
        end
    end

    return false
end

function Container:tween(duration, layout, easing, after)
    if not self.timer then
        self.timer = Timer.new()
    end

    self.timer.clear()
    self.timer.tween(duration, self.layout, layout, easing, after)
end

function Container:getBounds()
    if self.temp.bounds then return self.temp.bounds end
    self.temp.bounds = Rectangle(self.props.x, self.props.y, self.props.width, self.props.height)
    return self.temp.bounds
end

-- calculates inner bounds of a container, acknowledging margins
function Container:getInnerBounds()
    if self.temp.innerBounds then return self.temp.innerBounds end
    self.temp.innerBounds = Rectangle(
        self.props.x + self.props.marginLeft,
        self.props.y + self.props.marginRight,
        self.props.width - self.props.marginLeft - self.props.marginRight,
        self.props.height - self.props.marginTop - self.props.marginBottom)
    return self.temp.innerBounds
end

function Container:getTrueBounds()
    if self.temp.trueBounds then return self.temp.trueBounds end
    local x, y = self:getTruePosition():unpack()
    self.temp.trueBounds = Rectangle(x, y, self.props.width, self.props.height)
    return self.temp.trueBounds
end

-- calculates container position relative to the GUI root container
function Container:getTruePosition()
    if self.temp.truePosition then return self.temp.truePosition end
    self.temp.truePosition = Vector(self.props.x, self.props.y)
    if self.parent then
        self.temp.truePosition = self.temp.truePosition +
            self.parent:getTruePosition() +
            Vector(self.parent.props.marginLeft, self.parent.props.marginTop)
    end
    return self.temp.truePosition
end

function Container:draw(region)
    if not self.layout.visible then return end
    region = region or self:getTrueBounds()
    love.graphics.push()
    love.graphics.translate(self.layout.offsetX, self.layout.offsetY)

    -- draw background
    if self.props.backgroundVisible then
        love.graphics.setColor(hexToRGB(self.props.backgroundColor))
        self:getBounds():draw('fill')
        love.graphics.setColor(255, 255, 255)
    end

    -- draw custom
    love.graphics.push()
    love.graphics.translate(self.props.x, self.props.y)
    if self.props.onDraw ~= nullFunction then
        self.props.onDraw()
    end

    -- draw children
    if next(self.children) then
        love.graphics.push()
        love.graphics.translate(self.props.marginLeft, self.props.marginTop)
        local intersect = nil
        for _, child in pairs(self.children) do
            intersect = region:getIntersection(child:getTrueBounds())
            if intersect then
                love.graphics.setScissor(intersect:unpack())
                child:draw(intersect)
            end
        end
        love.graphics.setScissor()
        love.graphics.pop()
    end

    love.graphics.pop()

    -- draw border
    if self.props.borderVisible then
        love.graphics.setColor(hexToRGB(self.props.borderColor))
        self:getBounds():draw('line')
        love.graphics.setColor(255, 255, 255)
    end

    love.graphics.pop()
end

--============================================================================== LIST CONTAINER

local ListContainer = Class { __includes = Container }

function ListContainer:refreshChildren()
    self.temp.tail = 0
    for _, child in pairs(self.children) do
        child.props.y = self.temp.tail
        child:refresh()
        self.temp.tail = self.temp.tail + child.props.height + self.props.separation
    end

    if self.props.expands then
        self.props.height = math.max(0, self.temp.tail - self.props.separation)
    end
end

--============================================================================== ROW CONTAINER

local RowContainer = Class { __includes = Container }

function RowContainer:refreshChildren()
    self.temp.tail = 0
    for _, child in pairs(self.children) do
        child.props.x = self.temp.tail
        child:refresh()
        self.temp.tail = self.temp.tail + child.props.width + self.props.separation
    end

    if self.props.expands then
        self.props.width = math.max(0, self.temp.tail - self.props.separation)
    end
end

--============================================================================== SCROLL CONTAINER

local ScrollContainer = Class { __includes = Container }

function ScrollContainer:init(props, children)
    props = props or {}
    props.onMouseWheel = function(self, event)
        self.layout.scrollSpeed = self.layout.scrollSpeed + event.wheelY * self.props.scrollMultiplier
    end

    local pane = ListContainer({
        fillWidth = true,
        separation = props.separation,
        expands = true
    }, children)

    Container.init(self, props, { pane })
end

function ScrollContainer:add(child)
    if self.pane then
        self.pane:add(child)
    else
        Container.add(self, child)
        self.pane = child
    end
end

function ScrollContainer:remove(child)
    self.pane:remove(child)
end

function ScrollContainer:removeIndex(index)
    self.pane:removeIndex(index)
end

function ScrollContainer:update(dt)
    Container.update(self, dt)

    if math.abs(self.layout.scrollSpeed) > 0.1 then
        self.pane.props.y = self.pane.props.y + self.layout.scrollSpeed

        -- contain the pane
        if self.pane.props.height < self.props.height then
            self.pane.props.y = 0
            self.layout.scrollSpeed = 0
        else
            if self.pane.props.y > 0 then
                self.pane.props.y = 0
                self.layout.scrollSpeed = 0
            elseif self.pane.props.y + self.pane.props.height < self.props.height then
                self.pane.props.y = self.props.height - self.pane.props.height
                self.layout.scrollSpeed = 0
            end
        end

        self.pane:refresh()

        self.layout.scrollSpeed = self.layout.scrollSpeed * self.props.scrollDecay
    else
        self.layout.scrollSpeed = 0
    end
end

-- TODO make scrollbar its own GUI object
function ScrollContainer:draw(region)
    Container.draw(self, region)

    if not self.layout.visible then return end
    if not self.props.showScrollbar then return end
    if self.pane.props.height <= self.props.height then return end

    love.graphics.push()
    love.graphics.translate(self.layout.offsetX + self.props.x, self.layout.offsetY + self.props.y)
    local y = -self.pane.props.y / self.pane.props.height * self.props.height
    local h = self.props.height / self.pane.props.height * self.props.height

    love.graphics.setColor(0, 0, 0, 64)
    love.graphics.rectangle('fill', self.props.width - 12, y, 8, h)
    love.graphics.setColor(255, 255, 255, 255)
    love.graphics.pop()
end

--============================================================================== TEXT

local Text = Class {
    __includes = Container,
    defaultProps = {
        fillWidth = true,
        fillHeight = true,
        alignH = 'left',
        alignV = 'center'
    }
}

function Text:init(text, props)
    props = props or {}
    for prop, val in pairs(Text.defaultProps) do
        props[prop] = props[prop] or val
    end
    Container.init(self, props)

    self.text = text
end

function Text:add(child) end

function Text:remove(child) end

function Text:draw()
    love.graphics.setColor(hexToRGB(self.props.fontColor))
    love.graphics.setFont(self.props.font)

    local y = 0
    if self.props.alignV == 'center' then
        y = (self.props.height - self.props.font:getHeight()) / 2
    elseif self.props.alignV == 'bottom' then
        y = self.props.height - self.props.font:getHeight()
    end
    love.graphics.printf(self.text, 0, y, self.props.width, self.props.alignH)
    love.graphics.setColor(255, 255, 255)
end

return {
    Container = Container,
    ListContainer = ListContainer,
    RowContainer = RowContainer,
    ScrollContainer = ScrollContainer,
    Text = Text
}
