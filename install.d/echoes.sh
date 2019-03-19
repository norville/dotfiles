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
COL_WHITE=$ESC_SEQ"97;01m"

# Define echo functions
function bot() {
	echo -en "\n$COL_CYAN|°_°|$COL_RESET $1"
}

function info() {
	echo -en "\n$COL_MAGENTA|...|$COL_RESET $1 "
}

function cmd() {
	echo -en "$COL_BLUE—>$COL_RESET $COL_WHITE $1 $COL_RESET"
}

function success() {
	echo -en "\n$COL_CYAN|°_°|$COL_RESET$COL_GREEN Done:$COL_RESET $1"
}

function alert() {
	echo -en "\n$COL_YELLOW|!!!| $1 $COL_RESET"
}

function error() {
	echo -en "\n$COL_RED|xxx| $1 $COL_RESET"
}

function ok() {
	echo -en "$COL_GREEN ok! $COL_RESET"
}

function try() {
	if [[ $? != 0 ]]; then
		error "$1"
		exit 2
	else
		ok
	fi
}
