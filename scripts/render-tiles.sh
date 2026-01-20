#!/bin/bash

# --- Styles ---
NORMAL="\033[0m"
BOLD="\033[1;37m"
GREEN="\033[32m"
RED="\033[31m"
YELLOW="\033[33m"
CYAN="\033[36m"     

function echo_logo {
    echo -e "${CYAN}${BOLD}$1${NORMAL}"
}

function echo_info {
    echo -e "${BOLD}${CYAN}==>${NORMAL} $1"
} 

function echo_step {
    echo -e "\n${YELLOW}--- STEP $1 ---${NORMAL}"
}

function echo_success {
    echo -e "${GREEN}SUCCESS:${NORMAL} $1"
}

function echo_error {
    echo -e "${RED}ERROR:${NORMAL} $1" >&2
}

function center_logo {
    local term_width=$(tput cols)
    while IFS= read -r line; do
        local line_len=${#line}
        local padding=$(((term_width - line_len) / 2))
        [[ $padding -lt 0 ]] && padding=0
        printf "%${padding}s%b\n" "" "${CYAN}${BOLD}${line}${NORMAL}"
    done <<< "$1"
}

logo=" _____                  _____                         ______ _   _ _____ _   _ 
|  _  |                /  ___|                        |  _  \ | | |_   _| | | |
| | | |_ __   ___ _ __ \ \`--.  ___  _   _ _ __ ___ ___| | | | | | | | | | |_| |
| | | | '_ \ / _ \ '_ \ \`--. \/ _ \| | | | '__/ __/ _ \ | | | | | | | | |  _  |
\ \_/ / |_) |  __/ | | /\__/ / (_) | |_| | | | (_|  __/ |/ /| |_| | | | | | | |
 \___/| .__/ \___|_| |_\____/ \___/ \__,_|_|  \___\___|___/  \___/  \_/ \_| |_/
      | |                                                                      
      |_|                                                                      "

center_logo "$logo"
LOGO_WIDTH=79
TERM_WIDTH=$(tput cols)
PADDING=$(((TERM_WIDTH - LOGO_WIDTH) / 2))
[[ $PADDING -lt 0 ]] && PADDING=0
STR_PAD=$(printf "%${PADDING}s" "")

function echo_padded {
    echo -e "${STR_PAD}$1"
}

echo "" | while read -r line; do
    echo -e "${STR_PAD}${CYAN}${BOLD}${line}${NORMAL}"
done

echo ""
echo_padded "${BOLD}${CYAN}==>${NORMAL} Welcome to the OpenSourceDUTH Environment Setup Tool"
echo_padded "This script will help you automate the setup of this project."
echo_padded "${RED}Warning:${NORMAL} This is for development environments only."
echo ""
echo ""
echo_padded "${BOLD}${YELLOW}Press any key to get started or Ctrl+C to exit...${NORMAL}"

# Get terminal height
rows=$(tput lines)

# Move cursor to the last row, first column. This is only for the first page. Idk I just like it more this way.
tput cup $rows 0
read -n 1 -s
clear

# --- Check OS ---
# If someone wants to port this to Mac/Windows, be my guest.
if [[ "$OSTYPE" != "linux-gnu"* ]]; then
    echo_error "This script requires Linux."
    exit 1
fi

echo_info "Linux OS detected."
sleep 1
clear

echo_info "Before we get started, please specify your linux distribution."

echo "Select your distribution:"
select dist in "Debian/Ubuntu (apt)" "Arch (pacman)" "Exit"; do
    case $dist in
        "Debian/Ubuntu (apt)") pkg_mgr="apt"; break;;
        "Arch (pacman)") pkg_mgr="pacman"; break;;
        "Exit") clear; exit 0;;
        *) echo_error "Invalid choice";;
    esac
done

clear


# --- Basic preparation ---

echo_step "1: Installing Dependencies"

echo "Will implement this later. IDFC." # LEAVE ME ALONE!!!!!

clear


# --- This is to handle different OSes and package managers. Fall back to compile from source ---
# CHORE: This is a good first issue. You may use LLMs here, but be careful and test the code yourself.

# if [ "$pkg_mgr" == "apt" ]; then
#     sudo add-apt-repository -y ppa:m-bartlett/tilemaker
#     sudo apt update
#     sudo apt install -y osmium-tool tilemaker
# elif [ "$pkg_mgr" == "pacman" ]; then
#     # if command -v paru >/dev/null 2>&1; then
#     #     paru -Sy --noconfirm
#     #     paru -S --noconfirm python tippecanoe osmtogeojson
#     # elif command -v yay > /dev/null 2>&1; then
#     #     AUR_HELPER="yay"
#     # else
#         echo_error "No AUR helper found. Either exit (5 seconds) and install an AUR helper or the script will attempt to install the packages from source."
#         sleep 3     
#         echo ""
#         echo "This script will attempt to install the packages from source in 5 seconds."
#         echo "Press Cntrl+C to exit or wait..."
#         sleep 5
#         clear
#         echo_info "Installing git"
#         sudo pacman -S --noconfirm git
#         clear
#         echo_info "Cloning and installing osmium-tool"
#         mkdir tools && cd tools
#         git clone https://aur.archlinux.org/osmtogeojson.git
#         cd osmtogeojson
#         makepkg -si --noconfirm
#         cd ..
#         echo_success "osmtogeojson installed successfully."
#         sudo rm -rf ./osmtogeojson
#         clear
#         echo_info "Cloning and installing tippecanoe"
#         git clone https://aur.archlinux.org/tippecanoe.git
#         cd tippecanoe
#         makepkg -si --noconfirm
#         cd ..
#         echo_success "tippecanoe installed successfully."
#         sudo rm -rf ./tippecanoe
#         cd ..
#         sudo rm -rf ./tools
#         clear
#     # fi
# fi

# echo_success sends a message to signal that everything is installed successfully.
echo_success "All dependencies installed successfully."
sleep 1 
clear


# --- Download Map Data For a specific campus ---
# The list is being generated from the files in the campuses/ directory.

echo_step "2. Downloading Map Data"

# --- Sanity check for dependencies ---
# Should already be installed from previous step, but just in case...
if ! command -v python3 &> /dev/null || ! command -v osmtogeojson &> /dev/null || ! command -v tippecanoe &> /dev/null || ! command -v curl &> /dev/null; then
    echo_error "Missing required tools: python3, osmtogeojson, tippecanoe, or curl."
    echo "Please ensure they are installed and in your PATH."
    exit 1
fi

# --- Directory Setup ---
CAMPUS_DIR="./scripts/campuses"
TILES_DIR="./scripts/tiles"
mkdir -p "$CAMPUS_DIR"
mkdir -p "$TILES_DIR"

# --- Helper: Extract Polygon Python Script ---
cat << 'EOF' > extract_poly.py
import json, sys
try:
    with open(sys.argv[1], 'r') as f:
        data = json.load(f)
    coords = data['features'][0]['geometry']['coordinates'][0]
    # Swap Lon,Lat (GeoJSON) to Lat,Lon (Overpass)
    print(" ".join([f"{lat} {lon}" for lon, lat in coords]))
except Exception:
    sys.exit(1)
EOF

process_campus() {
    local input_path="$1"
    local filename=$(basename -- "$input_path")
    local name="${filename%.*}"
    echo name: $name
    
    exit 0
    echo_padded "Processing: ${BOLD}$name${NORMAL}"

    COORDS=$(python3 extract_poly.py "$input_path")
    if [ $? -ne 0 ] || [ -z "$COORDS" ]; then
        echo_error "Failed to extract coordinates from $input_path"
        return
    fi

    echo_padded "   Fetching raw OSM data (full metadata)..."
    # Query: nwr(poly:"LAT LON...") -> get Nodes, Ways, Relations in polygon
    curl -g -X POST --data-urlencode "data=[out:json][timeout:90];nwr(poly:\"$COORDS\");out meta geom;" "https://overpass-api.de/api/interpreter" -o "${name}_raw.json" --silent
    
    if [ ! -s "${name}_raw.json" ]; then
        echo_error "Download failed or returned empty response."
        return
    fi

    echo_padded "   Converting to GeoJSON..."
    osmtogeojson --meta "${name}_raw.json" > "${name}_geo.json"

    echo_padded "   Generating MBTiles..."
    tippecanoe -o "$TILES_DIR/$name.mbtiles" \
        -zg --drop-densest-as-needed --extend-zooms-if-still-dropping --force \
        --preserve-id \
        "${name}_geo.json" "$input_path" &> /dev/null
    
    # Translate (MBTiles -> PMTiles)
    if command -v pmtiles &> /dev/null; then
        echo_padded "   Translating to PMTiles format..."
        pmtiles convert "$TILES_DIR/$name.mbtiles" "$TILES_DIR/$name.pmtiles" --force &> /dev/null
        echo_success "Created $TILES_DIR/$name.mbtiles and $name.pmtiles"
    else
        echo_success "Created $TILES_DIR/$name.mbtiles"
        echo_padded "   ${YELLOW}Note:${NORMAL} 'pmtiles' CLI not found. Skipping translation to .pmtiles"
    fi

    rm -f "${name}_raw.json" "${name}_geo.json"
}

# --- Selection Menu ---
echo_info "Select a campus to compile:"

options=()
for file in "$CAMPUS_DIR"/*.json "$CAMPUS_DIR"/*.geojson; do
    if [ -e "$file" ]; then
        filename=$(basename "$file")
        options+=("${filename%.*}")
    fi
done

options+=("Custom Path")

PS3="Select option: "
select choice in "${options[@]}"; do
    case "$choice" in
        "Custom Path")
            echo ""
            echo_info "Enter the full path (from /) to your boundary file:"
            read -e -p "Path: " custom_path
            
            custom_path="${custom_path%\"}"
            custom_path="${custom_path#\"}"

            if [ -f "$custom_path" ]; then
                process_campus "$custom_path"
                break
            else
                echo_error "File not found: $custom_path"
            fi
            ;;
        *)
            if [[ -n "$choice" ]]; then
                if [ -f "$CAMPUS_DIR/$choice.json" ]; then
                     process_campus "$CAMPUS_DIR/$choice.json"
                elif [ -f "$CAMPUS_DIR/$choice.geojson" ]; then
                     process_campus "$CAMPUS_DIR/$choice.geojson"
                fi
                break
            else
                echo_error "Invalid selection. Try again."
            fi
            ;;
    esac
done

# --- Cleanup ---
rm -f extract_poly.py
echo ""

# --- License ---
# This project is the monolithic backend API for the OpenSourceDUTH team. Access to open data compiled and provided by the OpenSourceDUTH University Team.
# API Copyright (C) 2025 OpenSourceDUTH
#     This program is free software: you can redistribute it and/or modify
#     it under the terms of the GNU General Public License as published by
#     the Free Software Foundation, either version 3 of the License, or
#     (at your option) any later version.

#     This program is distributed in the hope that it will be useful,
#     but WITHOUT ANY WARRANTY; without even the implied warranty of
#     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#     GNU General Public License for more details.

#     You should have received a copy of the GNU General Public License
#     along with this program.  If not, see <https://www.gnu.org/licenses/>.


# --- Banner ---
# " _____                  _____                         ______ _   _ _____ _   _ "
# "|  _  |                /  ___|                        |  _  \ | | |_   _| | | |"
# "| | | |_ __   ___ _ __ \ \`--.  ___  _   _ _ __ ___ ___| | | | | | | | | | |_| |"
# "| | | | '_ \ / _ \ '_ \ \`--. \/ _ \| | | | '__/ __/ _ \ | | | | | | | | |  _  |"
# "\ \_/ / |_) |  __/ | | /\__/ / (_) | |_| | | | (_|  __/ |/ /| |_| | | | | | | |"
# " \___/| .__/ \___|_| |_\____/ \___/ \__,_|_|  \___\___|___/  \___/  \_/ \_| |_/"
# "      | |                                                                      "
# "      |_|       