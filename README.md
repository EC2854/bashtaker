# Bashtaker
**bashtaker** is a terminal de-make of [Helltaker](https://store.steampowered.com/app/1289310/Helltaker/), written in Bash.
![screenshot](screenshots/1.png) 

# Requirements
- `bash 4.0+` (associative arrays)
- `jq` (for map loading)

# How to play
## Clone the repository 
```sh
git clone https://github.com/EC2854/bashtaker && cd bashtaker
```
## Run the game
- Run the main script with a map file:
```sh
./bashtaker.sh ./assets/maps/1.json
```

# Maps
Bashtaker includes the first 9 main levels from the original Helltaker game.
All map files are located in the `./assets/maps/` directory.
Each map is stored as a `.json` file.

# Why bash? 
Because it's funny :3
