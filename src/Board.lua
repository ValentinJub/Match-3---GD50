--[[
    GD50
    Match-3 Remake

    -- Board Class --

    Author: Colton Ogden
    cogden@cs50.harvard.edu

    The Board is our arrangement of Tiles with which we must try to find matching
    sets of three horizontally or vertically.
]]

-- only use half the colors to differentiate them better
local colorSet1 = {
    1,2,5,9,10,11,12,14,17
}

-- return a random color from our colorset
local function getColor() return colorSet1[math.random(#colorSet1)] end

Board = Class{}

function Board:init(x, y, level, tiles)
    self.x = x
    self.y = y
    self.matches = {}
    self.level = level

    -- only initialise random tiles if we're not already passing ones
    if not tiles then
        if self.level ~= 666 then
            self:initializeTiles()
        else 
            self:initDebugTiles()
        end
    else
        self.tiles = tiles
    end
end

-- still a random distribution but with twice as much colors, should trigger more out of move events
function Board:initDebugTiles()
    self.tiles = {}

    -- insert a row
    for tileY = 1, 8 do
        
        -- empty table that will serve as a new row
        table.insert(self.tiles, {})

        -- fill the row with tiles
        for tileX = 1, 8 do

            -- define color randomly, & variety depending on the level
            local variety = math.random(6)
            local color = math.random(18)
            
            -- create a new tile at X,Y with a random color and variety
            table.insert(self.tiles[tileY], Tile(tileX, tileY, color, variety))
        end
    end

    while self:calculateMatches() or isOutOfMove(self.tiles) do
        
        -- recursively initialize if matches were returned so we always have
        -- a matchless board on start
        self:initDebugTiles()
    end
end

function Board:initializeTiles()
    
    self.tiles = {}

    -- insert a row
    for tileY = 1, 8 do
        
        -- empty table that will serve as a new row
        table.insert(self.tiles, {})

        -- fill the row with tiles
        for tileX = 1, 8 do

            -- 1/32 chance of getting a shiny
            local shiny = math.random(12)

            -- define color randomly, & variety depending on the level
            local variety = self.level == 1 and 1 or math.random(1,math.min(6,self.level))
            local color = getColor()
            
            -- create a new tile at X,Y with a random color and variety
            table.insert(self.tiles[tileY], Tile(tileX, tileY, color, variety, shiny))
        end
    end

    while self:calculateMatches() do
        
        -- recursively initialize if matches were returned so we always have
        -- a matchless board on start
        self:initializeTiles()
    end
end

--[[
    Goes left to right, top to bottom in the board, calculating matches by counting consecutive
    tiles of the same color & variety. Doesn't need to check the last tile in every row or column if the 
    last two haven't been a match.
]]
function Board:calculateMatches()
    local matches = {}

    -- how many of the same color blocks in a row we've found
    local matchNum = 1

    -- horizontal matches first
    for y = 1, 8 do
        local colorToMatch = self.tiles[y][1].color

        matchNum = 1
        
        -- every horizontal tile
        for x = 2, 8 do
            
            -- if this is the same color & variety as the one we're trying to match...
            if (self.tiles[y][x].color == colorToMatch) then
                matchNum = matchNum + 1
            else
                
                -- set them as the new color & variety we want to watch for
                colorToMatch = self.tiles[y][x].color

                -- if we have a match of 3 or more up to now, add it to our matches table
                if matchNum >= 3 then
                    local match = {}
                    local varietyToMatch, varietyMatchNum = 0, 1
                    local blowRow = false

                    for x2 = x - 1, x - matchNum, -1 do
                        if self.tiles[y][x2].shiny then
                            blowRow = true
                        end
                    end
    
                    if blowRow then
                        -- remove whole row
                        for q = 1, 8 do
                            table.insert(match, self.tiles[y][q])
                        end
                    else
                        -- go backwards from here by matchNum
                        for x2 = x - 1, x - matchNum, -1 do

                            -- each consecutive variety matched will increase the multiplier by 1
                            if varietyToMatch == self.tiles[y][x2] then
                                varietyMatchNum = varietyMatchNum + 1
                            else
                                varietyToMatch = self.tiles[y][x2]
                            end

                            -- add each tile to the match that's in that match
                            table.insert(match, self.tiles[y][x2])
                        end
                    end

                    -- add multiplier in each
                    for k, tile in pairs(match) do
                        tile.multiplier = varietyMatchNum
                    end

                    -- add this match to our total matches table
                    table.insert(matches, match)
                end

                matchNum = 1

                -- don't need to check last two if they won't be in a match
                if x >= 7 then
                    break
                end
            end
        end

        -- account for the last row ending with a match
        if matchNum >= 3 then
            local match = {}
            
            -- go backwards from end of last row by matchNum
            for x = 8, 8 - matchNum + 1, -1 do
                table.insert(match, self.tiles[y][x])
            end

            table.insert(matches, match)
        end
    end

    -- vertical matches
    for x = 1, 8 do
        local colorToMatch = self.tiles[1][x].color

        matchNum = 1

        -- every vertical tile
        for y = 2, 8 do
            if (self.tiles[y][x].color == colorToMatch) then
                matchNum = matchNum + 1
            else
                colorToMatch  = self.tiles[y][x].color
                local varietyToMatch = self.tiles[y][x].variety

                if matchNum >= 3 then
                    local match = {}

                    local blowRow = false
                    local rowToBlow = 0

                    for y2 = y - 1, y - matchNum, -1 do
                        if self.tiles[y2][x].shiny then
                            blowRow = true
                            rowToBlow = y2
                        end
                    end
    
                    if blowRow then
                        -- remove whole row
                        for q = 1, 8 do
                            table.insert(match, self.tiles[rowToBlow][q])
                        end
                    else
                        for y2 = y - 1, y - matchNum, -1 do

                            table.insert(match, self.tiles[y2][x])
                        end
                    end

                    table.insert(matches, match)
                end

                matchNum = 1

                -- don't need to check last two if they won't be in a match
                if y >= 7 then
                    break
                end
            end
        end

        -- account for the last column ending with a match
        if matchNum >= 3 then
            local match = {}
            
            -- go backwards from end of last row by matchNum
            for y = 8, 8 - matchNum + 1, -1 do
                table.insert(match, self.tiles[y][x])
            end

            table.insert(matches, match)
        end
    end

    -- store matches for later reference
    self.matches = matches

    -- return matches table if > 0, else just return false
    return #self.matches > 0 and self.matches or false
end

--[[
    Remove the matches from the Board by just setting the Tile slots within
    them to nil, then setting self.matches to nil.
]]
function Board:removeMatches()
    for k, match in pairs(self.matches) do
        for k, tile in pairs(match) do
            self.tiles[tile.gridY][tile.gridX] = nil
        end
    end

    self.matches = nil
end

--[[
    Shifts down all of the tiles that now have spaces below them, then returns a table that
    contains tweening information for these new tiles.
]]
function Board:getFallingTiles()
    -- tween table, with tiles as keys and their x and y as the to values
    local tweens = {}

    -- for each column, go up tile by tile till we hit a space
    for x = 1, 8 do
        local space = false
        local spaceY = 0

        local y = 8
        while y >= 1 do
            
            -- if our last tile was a space...
            local tile = self.tiles[y][x]
            
            if space then
                
                -- if the current tile is *not* a space, bring this down to the lowest space
                if tile then
                    
                    -- put the tile in the correct spot in the board and fix its grid positions
                    self.tiles[spaceY][x] = tile
                    tile.gridY = spaceY

                    -- set its prior position to nil
                    self.tiles[y][x] = nil

                    -- tween the Y position to 32 x its grid position
                    tweens[tile] = {
                        y = (tile.gridY - 1) * 32
                    }

                    -- set Y to spaceY so we start back from here again
                    space = false
                    y = spaceY

                    -- set this back to 0 so we know we don't have an active space
                    spaceY = 0
                end
            elseif tile == nil then
                space = true
                
                -- if we haven't assigned a space yet, set this to it
                if spaceY == 0 then
                    spaceY = y
                end
            end

            y = y - 1
        end
    end

    -- create replacement tiles at the top of the screen
    for x = 1, 8 do
        for y = 8, 1, -1 do
            local tile = self.tiles[y][x]

            -- if the tile is nil, we need to add a new one
            if not tile then

                -- 1/32 chance of getting a shiny
                local shiny = math.random(32)

                -- define color randomly, & variety depending on the level
                local color = getColor()
                local variety = self.level == 1 and 1 or math.random(1,math.min(6,self.level))

                -- new tile with random color and variety
                local tile = Tile(x, y, color, variety, shiny)
                tile.y = -32
                self.tiles[y][x] = tile

                -- create a new tween to return for this tile to fall down
                tweens[tile] = {
                    y = (tile.gridY - 1) * 32
                }
            end
        end
    end

    return tweens
end

function Board:render()
    for y = 1, #self.tiles do
        for x = 1, #self.tiles[1] do
            self.tiles[y][x]:render(self.x, self.y)
        end
    end
end

