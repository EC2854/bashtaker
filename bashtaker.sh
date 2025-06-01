#!/usr/bin/env bash

RESET=$(tput sgr0)

# Colors
BLACK=$(tput setaf 0)
WHITE=$(tput setaf 7)
RED=$(tput setaf 1)
GREEN=$(tput setaf 2)
MAGENTA=$(tput setaf 5)

# Grid config
TILE_SIZE_X=5
TILE_SIZE_Y=3

get_screen_position() {
    local x=$1
    local _y=$2
    row=$((2 + y * TILE_SIZE_Y))
    col=$((x * TILE_SIZE_X))
    echo "$row $col"
}

# Draw a tile
draw_tile() {
    local x=$1
    local y=$2
    local sprite=$3
    local color=$4

    local tile_lines=()
    [ -f "$sprite" ] || sprite="./sprites/blank.txt"
    [ -z "$color" ] && color="$BLACK"
    read -r row col <<<"$(get_screen_position "$x" "$y")"

    mapfile -t tile_lines < "$sprite"

    for ((i = 0; i < TILE_SIZE_Y; i++)); do
        tput cup $((row + i)) "$col"
        printf "%s%s%s" "$color" "${tile_lines[i]:0:TILE_SIZE_X}" "$RESET"
    done
}

draw_grid() {
    clear
    for ((y = 0; y < Y_TILES; y++)); do
        for ((x = 0; x < X_TILES; x++)); do
            draw_tile "$x" "$y" 0
        done
    done
}

is_blocked() {
    local x=$1
    local y=$2

    if (( x < 0 || x >= X_TILES || y < 0 || y >= Y_TILES )); then
        return 0
    fi

    case "${tiles["$x,$y"]}" in
        1|2) return 0 ;;
    esac

    return 1
}

can_push() {
    local x=$1
    local y=$2
    local direction=$3

    local new_x new_y
    case "$direction" in
        left)   new_x=$((x - 1)); new_y=$y ;;
        right)  new_x=$((x + 1)); new_y=$y ;;
        top)    new_x=$x; new_y=$((y - 1)) ;;
        bottom) new_x=$x; new_y=$((y + 1)) ;;
    esac
    if (( new_x < 0 || new_x >= X_TILES || new_y < 0 || new_y >= Y_TILES )); then
        return 1
    fi
    [[ "${tiles["$new_x,$new_y"]}" != 0 && -n "${tiles["$new_x,$new_y"]}" ]] && return 1
    return 0
}

push() {
    local x=$1
    local y=$2
    local direction=$3
    local type=$4

    if ! can_push "$x" "$y" "$direction"; then
        [[ "$type" == 2 ]] && return 1
        [[ "$type" == 3 ]] && {
            tiles["$x,$y"]="0"
            draw_tile "$x" "$y"
            return 0
        }
    fi

    local new_x new_y
    case "$direction" in
        left)   new_x=$((x - 1)); new_y=$y ;;
        right)  new_x=$((x + 1)); new_y=$y ;;
        top)    new_x=$x; new_y=$((y - 1)) ;;
        bottom) new_x=$x; new_y=$((y + 1)) ;;
    esac

    tiles["$x,$y"]="0"
    draw_tile "$x" "$y"

    case "$type" in
        2) sprite=./sprites/rock.txt; color="$WHITE" ;;
        3) sprite=./sprites/skeleton.txt; color="$WHITE" ;;
    esac
    draw_tile "$new_x" "$new_y" "$sprite" "$color"
    tiles["$new_x,$new_y"]="$type"
    return 0
}

draw_status() {
    tput cup 0 0
    printf "Moves left: %s%02d%s" "$RED" "$moves" "$RESET"
}
check_win() {
    local x=$selected_tile_x
    local y=$selected_tile_y

    local neighbors=(
        "$((x - 1)),$y"
        "$((x + 1)),$y"
        "$x,$((y - 1))"
        "$x,$((y + 1))"
    )

    for pos in "${neighbors[@]}"; do
        if [[ "${tiles["$pos"]}" == 5 ]]; then
        tput cup $((Y_TILES * TILE_SIZE_Y + 2)) 0
            message="${GREEN}You Won! ${RESET}"
            exit 0
        fi
    done
}

save_tiles_to_file() {
    local file="$1"
    :> "$file"
    for key in "${!tiles[@]}"; do
        echo "$key:${tiles[$key]}" >> "$file"
    done
}

map="$1"
[ -f "$map" ] || exit 1
. "$map"

old_x=$selected_tile_x
old_y=$selected_tile_y
direction=""
message="bye!"

clear
tput civis
trap 'tput cnorm; tput sgr0; clear; echo -e "$message"; exit' EXIT

draw_grid
draw_tile "$selected_tile_x" "$selected_tile_y" ./sprites/selected.txt "$RED"
draw_status
echo
echo -en "${RED}HJKL${RESET}/${RED}WSAD${RESET}: Movement, ${RED}R${RESET}: Reset, ${RED}Q${RESET}: Quit"

IFS='|' read -ra items <<< "$items_strings"
declare -A tiles
for item in "${items[@]}"; do
    IFS=':' read -r x y type <<< "$item"
    case "$type" in
        1) sprite=./sprites/wall.txt; color="$BLACK" ;;
        2) sprite=./sprites/rock.txt; color="$WHITE" ;;
        3) sprite=./sprites/skeleton.txt; color="$WHITE" ;;
        5) sprite=./sprites/girl.txt; color="$MAGENTA" ;;
    esac
    draw_tile "$x" "$y" "$sprite" "$color"
    tiles["$x,$y"]="$type"
done

# Main Loop
while :; do
    if (( "$moves" <= 0 )); then 
        tput cup $((Y_TILES * TILE_SIZE_Y + 2)) 0
        echo -e "${RED}Out of moves! Restarting...${RESET}"
        sleep 1
        exec "$0" "$@"
    fi
    read -rsn1 key

    old_x=$selected_tile_x
    old_y=$selected_tile_y

    case "$key" in
        h|a) new_x=$((selected_tile_x - 1)); new_y=$selected_tile_y; direction="left" ;;
        l|d) new_x=$((selected_tile_x + 1)); new_y=$selected_tile_y; direction="right" ;;
        k|w) new_x=$selected_tile_x; new_y=$((selected_tile_y - 1)); direction="top" ;;
        j|s) new_x=$selected_tile_x; new_y=$((selected_tile_y + 1)); direction="bottom" ;;
        r) exec "$0" "$@" ;;
        q) exit 0 ;;
        *) continue ;;
    esac

    if [[ "${tiles["$new_x,$new_y"]}" == 2 ]]; then
        push "$new_x" "$new_y" "$direction" "2"
    elif [[ "${tiles["$new_x,$new_y"]}" == 3 ]]; then
        push "$new_x" "$new_y" "$direction" "3"
    elif ! is_blocked "$new_x" "$new_y"; then
        draw_tile "$old_x" "$old_y"
        selected_tile_x=$new_x
        selected_tile_y=$new_y
        draw_tile "$selected_tile_x" "$selected_tile_y" ./sprites/selected.txt "$RED"
    fi
    ((moves--))
    draw_status
    check_win
    # save_tiles_to_file tmp.log # Log
done
