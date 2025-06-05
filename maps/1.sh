#!/usr/bin/env bash
# 1 - wall
# 2 - rock
# 3 - skeleton 
# 4 - 
# 5 - girl

X_TILES=7
Y_TILES=6

moves=23

player_x=5
player_y=0

declare -A tiles
declare -A spikes

# x:y:type
tiles["0,0"]=1
tiles["1,0"]=1
tiles["2,0"]=1
tiles["3,0"]=1
tiles["6,0"]=1

tiles["0,1"]=1
tiles["3,1"]=3
tiles["6,1"]=1

tiles["0,2"]=1
tiles["2,2"]=3
tiles["4,2"]=3
tiles["5,2"]=1
tiles["6,2"]=1

tiles["2,3"]=1
tiles["3,3"]=1
tiles["4,3"]=1
tiles["5,3"]=1
tiles["6,3"]=1

tiles["1,4"]=2
tiles["4,4"]=2
tiles["6,4"]=1

tiles["1,5"]=2
tiles["3,5"]=2
tiles["6,5"]=5
