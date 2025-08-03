
# Colors
export BLACK=$'\e[30m'
export RED=$'\e[31m'
export GREEN=$'\e[32m'
export YELLOW=$'\e[33m'
export MAGENTA=$'\e[35m'
export WHITE=$'\e[37m'

export RESET=$'\e[0m'

# cursor stuff
export HIDE_CURSOR=$'\e[?25l'
export SHOW_CURSOR=$'\e[?25h'

# Paths 
export CONFIG_PATHS=("./assets/config.json" "$XDG_CONFIG_HOME/bashtaker/config.json")
export DEFAULT_CONFIG_URL="https://raw.githubusercontent.com/EC2854/bashtaker/refs/heads/main/assets/config.json"

export FONT_PATHS=("./assets/font.json" "$XDG_CONFIG_HOME/bashtaker/font.json")
export DEFAULT_FONT_URL="https://raw.githubusercontent.com/EC2854/bashtaker/refs/heads/main/assets/config.json"

export has_key=0
