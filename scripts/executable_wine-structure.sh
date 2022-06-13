#!/bin/bash
title=$(basename "$0")
echo -n -e "\033]0;$title\007"

# Colors
c0=$'\e[0m'
c1=$(tput setaf 202)
c2=$(tput setaf 154)
b0=$'\e[25m'
b1=$'\e[5m'

# Force output in english
export LC_ALL=en_US.UTF-8

# OPTIONS
WINE_ROOT="$HOME/.PlayOnLinux"

STRUCTURE=(
    "$WINE_ROOT"
    "$WINE_ROOT/wineprefix"
    "$WINE_ROOT/wine"
    "$WINE_ROOT/wine/linux-amd64"
    "$WINE_ROOT/wine/linux-x86"
)


main() {

    create_structure
}


create_structure() {

    echo
    echo "   ---------------   Create structure   ---------------   "
    echo

    for path in "${STRUCTURE[@]}";
    do
        if [ ! -e "$path" ];
        then
            mkdir -p "$path" \
            && echo "${c2}[+]${c0} ${path}" \
            || echo "${c1}[${b1} ${b0}]${c0} ${path}"
        else
            echo "${c2}[x]${c0} ${path}"
        fi
    done

    echo
    echo "${c2}Script finished!${c0}"
}

main "$@"
