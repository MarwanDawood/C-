# Overview
This tetris game is built based on (Simple and Fast Multimedia Library) SFML v.2.5 with below features:
* Provide control to navigate and rotate shapes.
* It can accelerate moving shapes with pressing down arrow key.
* It detects when one row is complete, and removes it from the screen -> game goal.
* Shows differnet image textures (shapes and colors).
* Plays sounds.
* Shows game over image.

## Bugs
* The left most two columns cannot be accessed.
* Grey area is visible on right and bottom sides of the window.

## Dependencies
`sudo apt-get install libopenal-dev`\
Then download SFML v.2.5 and extract its libraries and copy the below libraries to `/usr/lib`

**Graphics**\
`sudo cp SFML-2.5.1/lib/libsfml-graphics.so.2.5 /usr/lib/`\
`sudo cp SFML-2.5.1/lib/libsfml-graphics.so /usr/lib/`

**Audio**\
`sudo cp SFML-2.5.1/lib/libsfml-audio.so.2.5 /usr/lib/`\
`sudo cp SFML-2.5.1/lib/libsfml-audio.so /usr/lib/`

**System**\
`sudo cp SFML-2.5.1/lib/libsfml-system.so.2.5 /usr/lib/`\
`sudo cp SFML-2.5.1/lib/libsfml-system.so /usr/lib/`

**Window**\
`sudo cp SFML-2.5.1/lib/libsfml-window.so.2.5 /usr/lib/`\
`sudo cp SFML-2.5.1/lib/libsfml-window.so /usr/lib/`

#### Inclusions
`sudo cp -r SFML-2.5.1/include/SFML/ /usr/include/`

## Compilation
open Makefile to explore possible options, `make all` is the one used for building.

## Running
`./tetris.bin`

Below is Tetris game playing with game over ending\
![Tetris game playing with game over](./tetris_gameover.gif)
