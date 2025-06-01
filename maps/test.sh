#!/usr/bin/env bash
# 1 - wall
# 2 - rock
# 3 - skeleton 
# 4 - 
# 5 - girl

export X_TILES=10
export Y_TILES=10

export moves=1000

export selected_tile_x=0
export selected_tile_y=0

# x:y:type
items=()
items+=("1:1:1")
items+=("2:1:2")
items+=("3:1:3")

export items_strings=$(IFS='|'; echo "${items[*]}")
