#!/bin/bash

# Define colors
ESC_SEQ="\x1b["
COL_RESET=$ESC_SEQ"39;49;00m"
COL_RED=$ESC_SEQ"31;01m"
COL_GREEN=$ESC_SEQ"32;01m"
COL_YELLOW=$ESC_SEQ"33;01m"
COL_BLUE=$ESC_SEQ"34;01m"
COL_MAGENTA=$ESC_SEQ"35;01m"
COL_CYAN=$ESC_SEQ"36;01m"

# Define echo functions
function ok() {
    echo -e "$COL_GREEN[ \u2714 ]$COL_RESET "$1
}

function bot() {
    echo -e "\n$COL_CYAN[·_·]$COL_RESET - "$1
}

function running() {
    echo -en "$COL_MAGENTA[\u25b6\u25b6\u25b6]$COL_RESET"$1": "
}

function action() {
    echo -e "\n$COL_BLUE[ \u279c ]:$COL_RESET\n ⇒ $1..."
}

function warn() {
    echo -e "$COL_YELLOW[!!!]$COL_RESET "$1
}

function error() {
    echo -e "$COL_RED[[\u00d7\u00d7\u00d7]]$COL_RESET "$1
}

