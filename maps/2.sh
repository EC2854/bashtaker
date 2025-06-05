#!/usr/bin/env bash
# 1 - wall
# 2 - rock
# 3 - skeleton 
# 5 - girl

X_TILES=7
Y_TILES=6

moves=24

player_x=0
player_y=4

declare -A tiles
declare -A spikes

# x:y:type
tiles["0,0"]=1
tiles["5,0"]=1
tiles["6,0"]=1

tiles["0,1"]=1
tiles["1,1"]=3
tiles["2,1"]=1

tiles["2,2"]=1
tiles["3,2"]=1
tiles["4,2"]=2
tiles["5,2"]=2
tiles["6,2"]=2

tiles["2,3"]=1
tiles["3,3"]=1

tiles["2,4"]=1
tiles["3,4"]=1
tiles["5,4"]=3

tiles["0,5"]=1
tiles["1,5"]=1
tiles["2,5"]=1
tiles["3,5"]=1
tiles["4,5"]=5
tiles["6,5"]=3

spikes["3,1"]=1
spikes["4,1"]=1

spikes["1,2"]=1
spikes["4,2"]=1
spikes["5,2"]=1

spikes["5,3"]=1
