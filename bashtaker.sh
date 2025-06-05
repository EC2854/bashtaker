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
BAR_HEIGHT=2

mapfile -t blank <<< $'╭───╮\n│   │\n╰───╯'
mapfile -t wall  <<< $'     \n     \n     '

declare -A tiles
declare -A spikes

load_map() {
    local map=$1
    [ -f "$map" ] || exit 1

    moves=$(jq '.moves' "$map")

    Y_TILES=$(jq '.tiles | length' "$map")
    X_TILES=$(jq '.tiles[0] | length' "$map")

    for (( y=0; y<Y_TILES; y++ )); do
        for (( x=0; x<X_TILES; x++ )); do
            char=$(jq -r ".tiles[$y] | .[$x:$((x+1))]" "$map")
                       if [[ "$char" != "_" ]]; then
                case "$char" in
                    "p")
                        player_x=$x
                        player_y=$y
                    ;;
                    *)
                        tiles["$x,$y"]=$char
                    ;;
                esac
            fi
            char=$(jq -r ".spikes[$y] | .[$x:$((x+1))]" "$map")
            if [[ "$char" != "_" ]]; then
                spikes["$x,$y"]=$char
            fi
        done
    done
}
get_screen_position() {
    local x=$1
    local y=$2
    row=$((BAR_HEIGHT + y * TILE_SIZE_Y))
    col=$((x * TILE_SIZE_X))
    echo "$row $col"
}
get_tile_info() {
    local x=$1
    local y=$2
    local type=${tiles["$x,$y"]}
    if [[ "$player_x" == "$x" && "$player_y" == "$y" ]];then 
        char=""
        color="$RED"
    else
        case "$type" in
            1) char=" "; color="$BLACK"   ;; # Wall
            2) char=""; color="$WHITE"   ;; # Rock
            3) char=""; color="$WHITE"   ;; # Skeleton
            5) char="󰋑"; color="$MAGENTA" ;; # Girl
            *) char=" "; color="$BLACK"   ;;
        esac
    fi
    echo "$char,$color,$type"
}
get_spike_info() {
    local x=$1
    local y=$2
    spike=" "
    spike_color="$BLACK"

    if [[ ${spikes["$x,$y"]} ]];then 
        spike=""
        if [[ ${spikes["$x,$y"]} == 1 ]]; then
            spike_color="$WHITE"
        else
            spike_color="$BLACK"
        fi
    fi
    echo "$spike,$spike_color"
}
draw_tile() {
    local x=$1
    local y=$2

    local char color type
    IFS="," read -r char color type <<<"$(get_tile_info "$x" "$y")"

    local spike spike_color
    IFS="," read -r spike spike_color <<<"$(get_spike_info "$x" "$y")"

    local row col
    read -r row col <<<"$(get_screen_position "$x" "$y")"

    local tile=("${blank[@]}")
    [[ $type == 1 ]] && tile=("${wall[@]}")

    for ((i = 0; i < TILE_SIZE_Y; i++)); do
        tput cup $((row + i)) "$col"
        line="${tile[i]:0:TILE_SIZE_X}"
        if [[ $i == 1 ]]; then
            printf "%s%s" "$color" "${line:0:1}"
            printf "%s%s" "$spike_color" "$spike"
            printf "%s%s" "$color" "$char"
            printf "%s%s" "$spike_color" "$spike"
            printf "%s%s%s" "$color" "${line:4:1}" "$RESET"
        else
            printf "%s%s%s" "$color" "$line" "$RESET"
        fi
    done
}
draw_grid() {
    clear
    local x y
    for ((y = 0; y < Y_TILES; y++)); do
        for ((x = 0; x < X_TILES; x++)); do
            draw_tile "$x" "$y"
        done
    done
    for tile in "${!tiles[@]}"; do
        IFS="," read -r x y <<< "$tile"
        draw_tile "$x" "$y"
    done
}

is_blocked() {
    local x=$1
    local y=$2

    # out of bounds
    if (( x < 0 || x >= X_TILES || y < 0 || y >= Y_TILES )); then
        return 0
    fi

    # blocked by wall or rock
    case "${tiles["$x,$y"]}" in
        1|2) return 0 ;;
    esac

    return 1
}
get_coords() {
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

    echo "$new_x $new_y"
}

can_push() {
    local x=$1
    local y=$2
    local direction=$3

    local new_x new_y
    read -r new_x new_y <<<"$(get_coords "$x" "$y" "$direction")"

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
    read -r new_x new_y <<<"$(get_coords "$x" "$y" "$direction")"

    tiles["$x,$y"]="0"
    draw_tile "$x" "$y"

    tiles["$new_x,$new_y"]="$type"
    draw_tile "$new_x" "$new_y"
    return 0
}

draw_status() {
    tput cup 0 0
    printf "Moves left: %s%02d%s" "$RED" "$moves" "$RESET"
}
check_win() {
    local x=$player_x
    local y=$player_y

    local neighbors=(
        "$((x - 1)),$y"
        "$((x + 1)),$y"
        "$x,$((y - 1))"
        "$x,$((y + 1))"
    )

    for pos in "${neighbors[@]}"; do
        if [[ "${tiles["$pos"]}" == 5 ]]; then
        tput cup $((Y_TILES * TILE_SIZE_Y + BAR_HEIGHT)) 0
            message="${GREEN}You Won! ${RESET}"
            exit 0
        fi
    done
}

direction=""
message="bye!"

load_map "$1"

clear
tput civis
trap 'tput cnorm; tput sgr0; clear; echo -e "$message"; exit' EXIT

draw_grid
draw_tile "$player_x" "$player_y"
draw_status
printf "\n%sHJKL%s/%sWSAD%s: Movement, %sR%s: Reset, %sQ%s: Quit" "$RED" "$RESET" "$RED" "$RESET" "$RED" "$RESET" "$RED" "$RESET"

# Main Loop
while :; do
    if (( "$moves" <= 0 )); then 
        tput cup $((Y_TILES * TILE_SIZE_Y + BAR_HEIGHT)) 0
        echo -e "${RED}Out of moves! Restarting...${RESET}"
        sleep 1
        exec "$0" "$@"
    fi
    read -rsn1 key

    old_x=$player_x
    old_y=$player_y

    case "$key" in
        h|a) new_x=$((player_x - 1)); new_y=$player_y; direction="left" ;;
        l|d) new_x=$((player_x + 1)); new_y=$player_y; direction="right" ;;
        k|w) new_x=$player_x; new_y=$((player_y - 1)); direction="top" ;;
        j|s) new_x=$player_x; new_y=$((player_y + 1)); direction="bottom" ;;
        r) exec "$0" "$@" ;;
        q) exit 0 ;;
        *) continue ;;
    esac

    if [[ "${tiles["$new_x,$new_y"]}" == 2 ]]; then
        push "$new_x" "$new_y" "$direction" "2"

    elif [[ "${tiles["$new_x,$new_y"]}" == 3 ]]; then
        push "$new_x" "$new_y" "$direction" "3"

    elif ! is_blocked "$new_x" "$new_y"; then
        player_x=$new_x
        player_y=$new_y
        draw_tile "$old_x" "$old_y"
        draw_tile "$player_x" "$player_y"
    fi

    # Remove move on spike
    if [[ "${spikes["$player_x,$player_y"]}" == 1 ]]; then
        ((moves-=2))
    else
        ((moves--))
    fi
    draw_status
    check_win
done
