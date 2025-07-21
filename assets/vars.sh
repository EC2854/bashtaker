export RESET=$(tput sgr0)

# Colors
export BLACK=$(tput setaf 0)
export WHITE=$(tput setaf 7)
export RED=$(tput setaf 1)
export GREEN=$(tput setaf 2)
export MAGENTA=$(tput setaf 5)
export YELLOW=$(tput setaf 3)

export CONFIG_PATHS=("./assets/config.json" "$XDG_CONFIG_HOME/bashtaker/config.json")
export DEFAULT_CONFIG_URL="https://raw.githubusercontent.com/EC2854/bashtaker/refs/heads/main/assets/config.json"

export FONT_PATHS=("./assets/font.json" "$XDG_CONFIG_HOME/bashtaker/font.json")
export DEFAULT_FONT_URL="https://raw.githubusercontent.com/EC2854/bashtaker/refs/heads/main/assets/config.json"

export has_key=0
