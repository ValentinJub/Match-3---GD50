--[[
    GD50
    Match-3 Remake

    -- ResetGameState Class --

    Author: Valentin Wissler
    valentinwissler42@outlook.com

    Represents the state the game is in right after we ran out of moves,
    we display a falling out of move banner then prompts the player to retry or quit

]]

ResetGameState = Class{__includes = BaseState}

function ResetGameState:init()

    -- when prmpt is active we display retry screen
    self.prompt = false

    -- currently selected menu item
    self.currentMenuItem = 1

    -- used to animate our full-screen transition rect
    self.transitionAlpha = 0

    -- if we've selected an option, we need to pause input while we animate out
    self.pauseInput = false

    -- start our level # label off-screen
    self.levelLabelY = -64
end

function ResetGameState:enter(def)
    
    -- grab level # from the def we're passed
    self.level = def.level

    -- spawn a board and place it toward the right
    self.board = def.board
    
    -- Transition our text label to the
    -- center of the screen over 0.5 seconds
    Timer.tween(0.5, {
        [self] = {levelLabelY = VIRTUAL_HEIGHT / 2 - 8}
    })
    
    -- after that, pause for one second with Timer.after
    :finish(function()
        Timer.after(3, function()
            
            -- then, animate the label going down past the bottom edge
            Timer.tween(0.5, {
                [self] = {levelLabelY = VIRTUAL_HEIGHT + 30}
            })
            
            -- once that's complete, prompts the player
            :finish(function()
                self.prompt = true
            end)
        end)
    end)
end

function ResetGameState:update(dt)

    if self.prompt then
        if love.keyboard.wasPressed('escape') then
            love.event.quit()
        end
    end
    -- as long as can still input, i.e., we're not in a transition...
    if not self.pauseInput then
        
        -- change menu selection
        if love.keyboard.wasPressed('up') or love.keyboard.wasPressed('down') then
            self.currentMenuItem = self.currentMenuItem == 1 and 2 or 1
            gSounds['select']:play()
        end

        -- switch to another state via one of the menu options
        if love.keyboard.wasPressed('enter') or love.keyboard.wasPressed('return') then
            if self.currentMenuItem == 1 then
                
                -- tween, using Timer, the transition rect's alpha to 1, then
                -- transition to the BeginGame state after the animation is over
                Timer.tween(1, {
                    [self] = {transitionAlpha = 1}
                }):finish(function()
                    gStateMachine:change('begin-game', {
                        level = self.level
                    })
                end)
            else
                love.event.quit()
            end

            -- turn off input during transition
            self.pauseInput = true
        end
    end
    Timer.update(dt)
end
function ResetGameState:drawTextShadow(text, y)
    love.graphics.setColor(34/255, 32/255, 52/255, 1)
    love.graphics.printf(text, 2, y + 1, VIRTUAL_WIDTH, 'center')
    love.graphics.printf(text, 1, y + 1, VIRTUAL_WIDTH, 'center')
    love.graphics.printf(text, 0, y + 1, VIRTUAL_WIDTH, 'center')
    love.graphics.printf(text, 1, y + 2, VIRTUAL_WIDTH, 'center')
end

function ResetGameState:render()
    
    -- render board of tiles
    self.board:render()

    -- keep the background and tiles a little darker than normal
    love.graphics.setColor(0, 0, 0, 128/255)
    love.graphics.rectangle('fill', 0, 0, VIRTUAL_WIDTH, VIRTUAL_HEIGHT)

    -- out of move banner displayed for the first few seconds
    if not self.prompt then
        -- render Level # label and background rect
        love.graphics.setColor(95/255, 205/255, 228/255, 200/255)
        love.graphics.rectangle('fill', 0, self.levelLabelY - 8, VIRTUAL_WIDTH, 48)
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.setFont(gFonts['large'])
        love.graphics.printf('Out of moves!', 0, self.levelLabelY, VIRTUAL_WIDTH, 'center')
    else

        -- draw rect behind retry and quit game text
        love.graphics.setColor(1, 1, 1, 128/255)
        love.graphics.rectangle('fill', VIRTUAL_WIDTH / 2 - 76, VIRTUAL_HEIGHT / 2 - 58 / 2, 150, 58, 6)

        -- draw Start text
        love.graphics.setFont(gFonts['medium'])
        self:drawTextShadow('Retry', VIRTUAL_HEIGHT / 2 - 50 / 2)
        
        if self.currentMenuItem == 1 then
            love.graphics.setColor(99/255, 155/255, 1, 1)
        else
            love.graphics.setColor(48/255, 96/255, 130/255, 1)
        end
        
        love.graphics.printf('Retry', 0, VIRTUAL_HEIGHT / 2 - 50 / 2, VIRTUAL_WIDTH, 'center')

        -- draw Quit Game text
        love.graphics.setFont(gFonts['medium'])
        self:drawTextShadow('Quit Game', VIRTUAL_HEIGHT / 2)
        
        if self.currentMenuItem == 2 then
            love.graphics.setColor(99/255, 155/255, 1, 1)
        else
            love.graphics.setColor(48/255, 96/255, 130/255, 1)
        end
        
        love.graphics.printf('Quit Game', 0, VIRTUAL_HEIGHT / 2, VIRTUAL_WIDTH, 'center')

        -- draw our transition rect; is normally fully transparent, unless we're moving to a new state
        love.graphics.setColor(1, 1, 1, self.transitionAlpha)
        love.graphics.rectangle('fill', 0, 0, VIRTUAL_WIDTH, VIRTUAL_HEIGHT)
    end
end