#!/usr/bin/env bash
# 1 - wall
# 2 - rock
# 3 - skeleton 
# 5 - girl

export X_TILES=7
export Y_TILES=6

export moves=24

export selected_tile_x=0
export selected_tile_y=4

# x:y:type
items=()
items+=("0:0:1")
items+=("5:0:1")
items+=("6:0:1")

items+=("0:1:1")
items+=("1:1:3")
items+=("2:1:1")

items+=("2:2:1")
items+=("3:2:1")
items+=("4:2:2")
items+=("5:2:2")
items+=("6:2:2")

items+=("2:3:1")
items+=("3:3:1")

items+=("2:4:1")
items+=("3:4:1")
items+=("5:4:3")

items+=("0:5:1")
items+=("1:5:1")
items+=("2:5:1")
items+=("3:5:1")
items+=("4:5:5")
items+=("6:5:3")

spike=()
spike+=("3:1:1")
spike+=("4:1:1")

spike+=("1:2:1")
spike+=("4:2:1")
spike+=("5:2:1")

spike+=("5:3:1")


export items_string=$(IFS='|'; echo "${items[*]}")
export spike_string=$(IFS='|'; echo "${spike[*]}")
