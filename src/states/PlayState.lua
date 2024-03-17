--[[
    GD50
    Match-3 Remake

    -- PlayState Class --

    Author: Colton Ogden
    cogden@cs50.harvard.edu

    State in which we can actually play, moving around a grid cursor that
    can swap two tiles; when two tiles make a legal swap (a swap that results
    in a valid match), perform the swap and destroy all matched tiles, adding
    their values to the player's point score. The player can continue playing
    until they exceed the number of points needed to get to the next level
    or until the time runs out, at which point they are brought back to the
    main menu or the score entry menu if they made the top 10.
]]

PlayState = Class{__includes = BaseState}

function PlayState:init()
    
    -- start our transition alpha at full, so we fade in
    self.transitionAlpha = 1

    -- position in the grid which we're highlighting
    self.boardHighlightX = 0
    self.boardHighlightY = 0

    -- timer used to switch the highlight rect's color
    self.rectHighlighted = false

    -- flag to show whether we're able to process input (not swapping or clearing)half 
    -- !!!! Flag not used 
    self.canInput = true

    -- tile we're currently highlighting (preparing to swap)
    self.highlightedTile = nil

    self.score = 0
    self.timer = 1200

    -- set our Timer class to turn cursor highlight on and off
    Timer.every(0.5, function()
        self.rectHighlighted = not self.rectHighlighted
    end)

    -- subtract 1 from timer every second
    Timer.every(1, function()
        self.timer = self.timer - 1

        -- play warning sound on timer if we get low
        if self.timer <= 5 then
            gSounds['clock']:play()
        end
    end)
end

function PlayState:enter(params)
    
    -- grab level # from the params we're passed
    self.level = params.level

    -- spawn a board and place it toward the right
    self.board = params.board or Board(VIRTUAL_WIDTH - 272, 16, self.level)

    -- grab score from params if it was passed
    self.score = params.score or 0

    -- score we have to reach to get to the next level
    self.scoreGoal = self.level * 2 * 1000
end

-- swap two tiles in the provided board
local function swapTile(tile1, tile2, board)
    -- swap grid positions of tiles
    local tempX = tile1.gridX
    local tempY = tile1.gridY

    tile1.gridX = tile2.gridX
    tile1.gridY = tile2.gridY

    tile2.gridX = tempX
    tile2.gridY = tempY

    -- swap tiles in the tiles table
    board.tiles[tile1.gridY][tile1.gridX] = tile1

    board.tiles[tile2.gridY][tile2.gridX] = tile2
end

-- returns whether swapping two tiles returns a match
local function swapIsMatch(tile1, tile2, board)
    swapTile(tile1, tile2, board)
    -- if we have a match, return false, we are not out of move
    if board:calculateMatches() then
        return true
    end
    -- swap back
    swapTile(tile1, tile2, board)
    return false
end



-- test all possible swaps and return true if there aren't any
-- possible move that can result in a match
function isOutOfMove(board)

    -- -- create a local copy of the board tiles
    -- local tileCopy = {}
    -- for y = 1, 8 do
    --     local row = {}
    --     for x = 1, 8 do
    --         table.insert(row, board[y][x])
    --     end
    --     table.insert(tileCopy, row)
    -- end

    function deepcopy(orig)
        local orig_type = type(orig)
        local copy
        if orig_type == 'table' then
            copy = {}
            for orig_key, orig_value in next, orig, nil do
                copy[orig_key] = deepcopy(orig_value)
            end
        else -- number, string, boolean, etc
            copy = orig
        end
        return copy
    end
    
    -- usage
    local tileCopy = deepcopy(board)


    -- create a copy of the board with our copied tiles
    local boardCopy = Board(VIRTUAL_WIDTH - 272, 16, 1, tileCopy)

    -- traverse the board row by row
    for y = 1, 8 do
        
        -- for each tile 
        for x = 1, 8 do
            local curTile = boardCopy.tiles[y][x]
            -- not the bottom row, can check below
            if y ~= 8 then
                local botTile = boardCopy.tiles[y + 1][x]
                -- not the rightmost tile, can check right
                if x ~= 8 then
                    local rightTile = boardCopy.tiles[y][x + 1]
                    -- if the swap is a match, we aren't out of move
                    if swapIsMatch(curTile, botTile, boardCopy) or swapIsMatch(curTile, rightTile, boardCopy) then
                        return false
                    end
                -- rightmost tile, only check below
                else
                    -- if the swap is a match, we aren't out of move
                    if swapIsMatch(curTile, botTile, boardCopy) then
                        return false
                    end
                end
            -- bottom row, only check right
            else
                -- if we aren't the rightmost tile, check right
                if x ~= 8 then
                    local rightTile = boardCopy.tiles[y][x + 1]
                    -- if the swap is a match, we aren't out of move
                    if swapIsMatch(curTile, rightTile, boardCopy) then
                        return false
                    end
                -- bottom and rightmost tile, do nothing
                else
                    -- do nothing
                end
            end
        end
    end

    -- if we've reached here it means we haven't found any possible move
    -- we are effectively out of moves.
    return true
end

function PlayState:update(dt)
    if love.keyboard.wasPressed('escape') then
        love.event.quit()
    end

    -- triggers an out of move transition, for debugging purposes only
    if love.keyboard.wasPressed('d') then
        gStateMachine:change('reset', {
            level = self.level,
            score = self.score,
            board = self.board
        })
    end

    -- go back to start if time runs out
    if self.timer <= 0 then
        
        -- clear timers from prior PlayStates
        Timer.clear()
        
        gSounds['game-over']:play()

        gStateMachine:change('game-over', {
            score = self.score
        })
    end

    -- go to next level if we surpass score goal
    if self.score >= self.scoreGoal then
        
        -- clear timers from prior PlayStates
        -- always clear before you change state, else next state's timers
        -- will also clear!
        Timer.clear()

        gSounds['next-level']:play()

        -- change to begin game state with new level (incremented)
        gStateMachine:change('begin-game', {
            level = self.level + 1,
            score = self.score
        })
    end

    if self.canInput then
        -- move cursor around based on bounds of grid, playing sounds
        if love.keyboard.wasPressed('up') then
            self.boardHighlightY = math.max(0, self.boardHighlightY - 1)
            gSounds['select']:play()
        elseif love.keyboard.wasPressed('down') then
            self.boardHighlightY = math.min(7, self.boardHighlightY + 1)
            gSounds['select']:play()
        elseif love.keyboard.wasPressed('left') then
            self.boardHighlightX = math.max(0, self.boardHighlightX - 1)
            gSounds['select']:play()
        elseif love.keyboard.wasPressed('right') then
            self.boardHighlightX = math.min(7, self.boardHighlightX + 1)
            gSounds['select']:play()
        end

        -- if we've pressed space, to select or deselect a tile...
        if love.keyboard.wasPressed('space') then
            
            -- new highlighted tiles
            local x = self.boardHighlightX + 1
            local y = self.boardHighlightY + 1
            
            -- if nothing is highlighted, highlight current tile
            if not self.highlightedTile then
                self.highlightedTile = self.board.tiles[y][x]

            -- if we select the position already highlighted, remove highlight
            elseif self.highlightedTile == self.board.tiles[y][x] then
                self.highlightedTile = nil

            -- we haven't selected a tile adjacent to us
            elseif math.abs(self.highlightedTile.gridX - x) + math.abs(self.highlightedTile.gridY - y) > 1 then
                gSounds['error']:play()
                self.highlightedTile = nil
            -- we have selected a tile we could potentially swap with
            else
                --[[ 
                    to only allow swapping if it results in a match we need to perform the swap
                    and check if it results in a match, if yes, we allow the swap and proceed
                    otherwise we swap back and 
                ]]
                local newTile = self.board.tiles[y][x]
                local prevTile = self.highlightedTile

                swapTile(prevTile, newTile, self.board)

                -- if we are returned with a match we can do the tween
                -- else we swap back the tiles
                if self.board:calculateMatches() then
                    -- tween coordinates between the two so they can be visually swapped
                    Timer.tween(0.1, {
                        [self.highlightedTile] = {x = newTile.x, y = newTile.y},
                        [newTile] = {x = self.highlightedTile.x, y = self.highlightedTile.y}
                    })                 
                    -- once the swap is finished, we can tween falling blocks as needed
                    :finish(function()
                        self:calculateMatches()

                        -- check that we are not out of moves, if yes we transition to another state
                        if isOutOfMove(self.board.tiles) then
                            -- change to begin game state with new level (incremented)
                            gStateMachine:change('reset', {
                                level = self.level,
                                score = self.score,
                                board = self.board
                            })
                        end
                    end)

                -- the swap did not return a match, swap back and remove tile highlight
                else
                    swapTile(prevTile, newTile, self.board)
                    self.highlightedTile = nil
                    gSounds['error']:play()
                end
            end
        end
    end

    Timer.update(dt)
end

--[[
    Calculates whether any matches were found on the board and tweens the needed
    tiles to their new destinations if so. Also removes tiles from the board that
    have matched and replaces them with new randomized tiles, deferring most of this
    to the Board class.
]]
function PlayState:calculateMatches()
    self.highlightedTile = nil

    -- if we have any matches, remove them and tween the falling blocks that result
    local matches = self.board:calculateMatches()
    
    if matches then
        gSounds['match']:stop()
        gSounds['match']:play()

        -- add score for each match array
        for k, match in pairs(matches) do
            -- for each tile in our match
            for j, tile in pairs(match) do
                -- add 1 second per tile
                self.timer = math.min(120, self.timer + 1)
                -- calculate score, make sure it is an integer
                self.score = math.ceil(self.score + ((#match * 20) * (tile.multiplier + (tile.variety / 10))))
            end
        end

        -- remove any tiles that matched from the board, making empty spaces
        self.board:removeMatches()

        -- gets a table with tween values for tiles that should now fall
        local tilesToFall = self.board:getFallingTiles()

        -- tween new tiles that spawn from the ceiling over 0.25s to fill in
        -- the new upper gaps that exist
        Timer.tween(0.25, tilesToFall):finish(function()
            
            -- recursively call function in case new matches have been created
            -- as a result of falling blocks once new blocks have finished falling
            self:calculateMatches()
        end)
    
    -- if no matches, we can continue playing
    else
        self.canInput = true
    end
end

function PlayState:render()
    -- render board of tiles
    self.board:render()

    -- render highlighted tile if it exists
    if self.highlightedTile then
        
        -- multiply so drawing white rect makes it brighter
        love.graphics.setBlendMode('add')

        love.graphics.setColor(1, 1, 1, 96/255)
        love.graphics.rectangle('fill', (self.highlightedTile.gridX - 1) * 32 + (VIRTUAL_WIDTH - 272),
            (self.highlightedTile.gridY - 1) * 32 + 16, 32, 32, 4)

        -- back to alpha
        love.graphics.setBlendMode('alpha')
    end

    -- render highlight rect color based on timer
    if self.rectHighlighted then
        love.graphics.setColor(217/255, 87/255, 99/255, 1)
    else
        love.graphics.setColor(172/255, 50/255, 50/255, 1)
    end

    -- draw actual cursor rect
    love.graphics.setLineWidth(4)
    love.graphics.rectangle('line', self.boardHighlightX * 32 + (VIRTUAL_WIDTH - 272),
        self.boardHighlightY * 32 + 16, 32, 32, 4)

    -- GUI text
    love.graphics.setColor(56/255, 56/255, 56/255, 234/255)
    love.graphics.rectangle('fill', 16, 16, 186, 116, 4)

    love.graphics.setColor(99/255, 155/255, 1, 1)
    love.graphics.setFont(gFonts['medium'])
    love.graphics.printf('Level: ' .. tostring(self.level), 20, 24, 182, 'center')
    love.graphics.printf('Score: ' .. tostring(self.score), 20, 52, 182, 'center')
    love.graphics.printf('Goal : ' .. tostring(self.scoreGoal), 20, 80, 182, 'center')
    love.graphics.printf('Timer: ' .. tostring(self.timer), 20, 108, 182, 'center')
end