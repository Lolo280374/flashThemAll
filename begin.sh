#!/bin/bash
#lolodotzip - flashthemall.
#released for hackclub!
#simple CLI tool to flash (anything) to (anything)!!

system_arch=$([[ "$(uname -m)" == "x86_64" ]] && printf "amd64" || printf "arm64")

function starthebanner{
    echo -e "\eWELCOME TO FLASHTHEMALL!!"
    echo -e "\ethanks hackclub - made by lolodotzip"
    echo -e "\ea simple utility to help you flash anything to any device you want! even god forbid windows!"
    echo -e "\e----- real shi starts here -----"
    echo -e "\e"
}

starthebanner