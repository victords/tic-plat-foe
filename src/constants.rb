gem 'minigl', '=2.5.3'

require 'minigl'

Vector = MiniGL::Vector

SCREEN_WIDTH = 800
SCREEN_HEIGHT = 600
TILE_SIZE = 40
TILES_X = SCREEN_WIDTH / TILE_SIZE
TILES_Y = SCREEN_HEIGHT / TILE_SIZE
GRID_COLOR = 0x33ffffff
WALL_COLOR = 0xffffffff
MARK_COLOR = {
  circle: 0x3333cc,
  x: 0xcc3333,
  square: 0xffffff,
}.freeze
DEFAULT_TEXT_COLOR = 0xffffffff
DIM_TEXT_COLOR = 0x99ffffff
L_S_TILE_SIZE = 160
