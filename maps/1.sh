#!/usr/bin/env bash
# 1 - wall
# 2 - rock
# 3 - skeleton 
# 4 - 
# 5 - girl

export X_TILES=7
export Y_TILES=6

export moves=23

export selected_tile_x=5
export selected_tile_y=0

# x:y:type
items=()
items+=("0:0:1")
items+=("1:0:1")
items+=("2:0:1")
items+=("3:0:1")
items+=("6:0:1")

items+=("0:1:1")
items+=("3:1:3")
items+=("6:1:1")

items+=("0:2:1")
items+=("2:2:3")
items+=("4:2:3")
items+=("5:2:1")
items+=("6:2:1")

items+=("2:3:1")
items+=("3:3:1")
items+=("4:3:1")
items+=("5:3:1")
items+=("6:3:1")

items+=("1:4:2")
items+=("4:4:2")
items+=("6:4:1")

items+=("1:5:2")
items+=("3:5:2")
items+=("6:5:5")

export items_strings=$(IFS='|'; echo "${items[*]}")
