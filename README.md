# Match-3---GD50

## To implement

- Only allow swapping when it results in a match. If there are no matches available to perform, reset the board.

## Optional

- Add mouse controls.

### Hint

Convert coordinates

push:toGame(x, y) --convert coordinates from screen to game (useful for mouse position)
--push:toGame will return nil for the values that are outside the game - be sure to check that before using them

push:toReal(x, y) --convert coordinates from game to screen

## Implemented

- Implemented time addition on matches, such that scoring a match extends the timer by 1 second per tile in a match.
- Ensured Level 1 starts just with simple flat blocks (the first of each color in the sprite sheet), with later levels generating the blocks with patterns on them (like the triangle, cross, etc.). These are worth more points.
- Create random shiny versions of blocks that will destroy an entire row on match, granting points for each block in the row.

## Custom addition

- Tbd