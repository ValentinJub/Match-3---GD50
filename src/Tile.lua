--[[
    GD50
    Match-3 Remake

    -- Tile Class --

    Author: Colton Ogden
    cogden@cs50.harvard.edu

    The individual tiles that make up our game board. Each Tile can have a
    color and a variety, with the varietes adding extra points to the matches.
]]

Tile = Class{}

-- shiny tile will have their alpha go up and down, rendering a shiny effect
local function tweenAlpha(tile)

    if tile.alpha < 255 then
        Timer.tween(1, {
            [tile] = {alpha = 255, red = 255, green = 255, blue = 255}
        }):finish(function() tweenAlpha(tile) end)
    else
        Timer.tween(1, {
            [tile] = {alpha = 0, red = 0, green = 0, blue = 0}
        }):finish(function() tweenAlpha(tile) end)
    end

end


function Tile:init(x, y, color, variety, shiny) 
    
    -- board x position from 1 to 8
    self.gridX = x
    -- board y position from 1 to 8
    self.gridY = y

    -- screen coordinate positions for rendering
    self.x = (self.gridX - 1) * 32
    self.y = (self.gridY - 1) * 32

    -- tile appearance/points
    self.color = color
    self.variety = variety
    self.multiplier = 1

    -- set shiny if we drew 1
    -- shiny tiles destroy entire row when matched
    self.shiny = shiny == 1 and true or false

    self.alpha = 0
    self.red = 0
    self.green = 0
    self.blue = 0

    -- only tweenAlpha if the tile is shiny
    if shiny == 1 then
        tweenAlpha(self)
    end
    
    
end

-- x,y params are the board's 0,0 coordinates
-- we use that because we want to render inside our board
function Tile:render(x, y)
    
    -- draw shadow
    love.graphics.setColor(34/255, 32/255, 52/255, 255/255)
    love.graphics.draw(gTextures['main'], gFrames['tiles'][self.color][self.variety],
        self.x + x + 2, self.y + y + 2)
    
    -- draw tile itself
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.draw(gTextures['main'], gFrames['tiles'][self.color][self.variety],
        self.x + x, self.y + y)

    -- render shiny
    if self.shiny then
        love.graphics.setColor(self.red / 255, self.green / 255, self.blue / 255, self.alpha / 255)
        love.graphics.rectangle('fill', self.x + x, self.y + y, 30, 30, 6,6)
    end
end