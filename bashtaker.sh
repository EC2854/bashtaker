#!/usr/bin/env bash

RESET=$(tput sgr0)

# Colors
BLACK=$(tput setaf 0)
WHITE=$(tput setaf 7)
RED=$(tput setaf 1)
GREEN=$(tput setaf 2)
MAGENTA=$(tput setaf 5)
YELLOW=$(tput setaf 3)

# Grid config
TILE_SIZE_X=5
TILE_SIZE_Y=3
BAR_HEIGHT=2

has_key=0

mapfile -t blank <<< $'╭───╮\n│   │\n╰───╯'
mapfile -t wall  <<< $'     \n     \n     '

declare -A tiles
declare -A spikes

# change binds here
declare -A KEYS=(
    [h]="left" 
    [j]="down"
    [k]="up"
    [l]="right"
    [r]="reset"
    [q]="quit"
)

load_map() {
    local map=$1
    [ -f "$map" ] || exit 1

    moves=$(jq '.moves' "$map")
    spikes_move=$(jq '.spikes_move' "$map")

    key_x=$(jq '.key_x' "$map")
    key_y=$(jq '.key_y' "$map")

    local tile_rows=() spike_rows=()
    local tile_row spike_row
    local char

    mapfile -t tile_rows < <(jq -r '.tiles[]' "$map")
    mapfile -t spike_rows < <(jq -r '.spikes[]' "$map")

    X_TILES=${#tile_rows[0]}
    Y_TILES=${#tile_rows[@]}

    for (( y=0; y<Y_TILES; y++ )); do
        tile_row=${tile_rows[$y]}
        spike_row=${spike_rows[$y]}
        for (( x=0; x<X_TILES; x++ )); do
            char=${tile_row:$x:1}
            if [[ "$char" != "_" ]]; then
                if [[ "$char" == "p" ]]; then
                    player_x=$x
                    player_y=$y
                else
                    tiles["$x,$y"]=$char
                fi
            fi

            char=${spike_row:$x:1}
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
    local color char
    if [[ "$player_x" == "$x" && "$player_y" == "$y" ]];then 
        char=""
        color="$RED"
    else
        case "$type" in
            1) char=" "; color="$BLACK"   ;; # Wall
            2) char=""; color="$WHITE"   ;; # Rock
            3) char=""; color="$WHITE"   ;; # Skeleton
            4) char="󰌾"; color="$YELLOW"  ;; # Lock
            5) char="󰋑"; color="$MAGENTA" ;; # Girl
            *) char=" "; color="$BLACK"   ;;
        esac
    fi
    if [[ "$key_x" == "$x" && "$key_y" == "$y" ]];then 
        [[ "$char" == " " ]] && char="󰌆"
        color="$YELLOW"
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
get_coords() {
    local x=$1
    local y=$2
    local direction=$3

    local new_x new_y
    case "$direction" in
        left)   new_x=$((x - 1)); new_y=$y ;;
        right)  new_x=$((x + 1)); new_y=$y ;;
        up)    new_x=$x; new_y=$((y - 1)) ;;
        down) new_x=$x; new_y=$((y + 1)) ;;
    esac

    echo "$new_x $new_y"
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
        4) 
            if [[ "$has_key" == 1 ]]; then
                tiles["$x,$y"]=0
                return 1
            else 
                return 0
            fi
        ;;
    esac

    return 1
}
can_push() {
    local x=$1
    local y=$2
    local direction=$3

    local new_x new_y
    read -r new_x new_y <<<"$(get_coords "$x" "$y" "$direction")"

    (( new_x < 0 || new_x >= X_TILES || new_y < 0 || new_y >= Y_TILES )) && return 1
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
    if ! [[ $type == 3 && ${spikes["$new_x,$new_y"]} == 1 ]];then 
        tiles["$new_x,$new_y"]="$type"
        draw_tile "$new_x" "$new_y"
    fi
    return 0
}
draw_status() {
    tput cup 0 0
    printf "Moves left: %s%02d%s" "$RED" "$moves" "$RESET"
}
draw_keybinds() {
    local left up down right
    local output

    for key in $(printf "%s\n" "${!KEYS[@]}" | sort -r); do
        case "${KEYS[$key]}" in
            "left")  left="${key^^}";;
            "right") right="${key^^}";;
            "up")    up="${key^^}";;
            "down")  down="${key^^}";;
            *)
                output+="$RED${key^^}$RESET: ${KEYS[$key]^}, "
            ;;
        esac
    done
    output="$RED$left$down$up$right$RESET: Movement, $output"
    printf "\n%s\n" "${output%, }"
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
            printf "%sYou Won!%s\n" "$GREEN" "$RESET"
            exit 0
        fi
    done
}
check_key() {
    local x=$1
    local y=$2
    if [[ "$has_key" == 0 && "$x" == "$key_x" && "$y" == "$key_y" ]]; then
        has_key=1
        unset key_x key_y
    fi
}
switch_spikes() {
    if [[ "$spikes_move" == 0 ]]; then 
        return 0
    fi
    local x y
    for spike in "${!spikes[@]}"; do
        spikes["$spike"]=$(( spikes["$spike"] - 1)) 
        spikes["$spike"]=${spikes["$spike"]//-} # make value abs
        [[ ${spikes["$spike"]} == 1 && ${tiles["$spike"]} == 3 ]] && tiles["$spike"]=0 # Remove skeleton
        IFS="," read -r x y <<<"$spike"
        draw_tile "$x" "$y"
    done
}

load_map "$1"

clear
tput civis
trap 'tput cnorm; tput sgr0; exit' EXIT

draw_grid
draw_status
draw_keybinds

# Main Loop
while :; do
    if (( "$moves" <= 0 )); then 
        tput cup $((Y_TILES * TILE_SIZE_Y + BAR_HEIGHT)) 0
        printf "%sOut of moves! Restarting...%s" "$RED" "$RESET"
        sleep 1
        exec "$0" "$@"
    fi

    read -rsn1 key

    switch_spikes
    case "${KEYS[$key]}" in
        "left"|"down"|"up"|"right") 
            direction="${KEYS[$key]}"
            read -r new_x new_y <<<"$(get_coords "$player_x" "$player_y" "$direction")"
        ;;
        "reset") exec "$0" "$@" ;;
        "quit") exit 0 ;;
        *) continue ;;
    esac

    tile="${tiles["$new_x,$new_y"]}"
    case "$tile" in
        2|3) push "$new_x" "$new_y" "$direction" "$tile" ;;
        *)
            if ! is_blocked "$new_x" "$new_y"; then
                old_x=$player_x
                old_y=$player_y
                player_x=$new_x
                player_y=$new_y

                check_key "$player_x" "$player_y"
                draw_tile "$old_x" "$old_y"
                draw_tile "$player_x" "$player_y"
            fi
            ;;
    esac

    # Move cost
    if [[ "${spikes["$player_x,$player_y"]}" == 1 ]]; then
        ((moves -= 2))
    else
        ((moves--))
    fi

    draw_status
    check_win
done
