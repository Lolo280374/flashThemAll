#!/bin/bash
#lolodotzip - flashthemall.
#released for hackclub!
#simple CLI tool to flash (anything) to (anything)!!

system_arch=$([[ "$(uname -m)" == "x86_64" ]] && printf "amd64" || printf "arm64")

function starthebanner {
    echo -e "WELCOME TO FLASHTHEMALL!!"
    echo -e "thanks hackclub - made by lolodotzip"
    echo -e "a simple utility to help you flash anything to any device you want! even god forbid windows!"
    echo -e "----- real shi starts here -----"
    echo -e ""
}

function dl_ventoy_latest() {
    latest_build=$(curl -s https://api.github.com/repos/ventoy/Ventoy/releases/latest \
    | grep '"tag_name":' \
    | cut -d '"' -f 4 \
    | sed 's/^v//')

    ven_dl_url="https://github.com/ventoy/Ventoy/releases/download/v$latest_build/ventoy-$latest_build-linux.tar.gz"
    echo -e "now downloading build '$latest_build', please hold on!"
    curl -L -o "$tmp_dir/ventoy.tar.gz" "$ven_dl_url"

    curl_exit=$?
    echo -e ""

    if [[ $curl_exit -ne 0 ]]; then
        echo -e "curl failed to download your file. please try again!"
        return 1
    fi

    echo "download seems to have succeded, proceeding!"
}

function make_tmp_dir() {
    tmp_dir="/tmp/flashthemall"
    mkdir -p "$tmp_dir"
}

function maininit_menu() {
    make_tmp_dir
    while true; do
    echo "what do you wish to do?"
    echo "1) list the avalaible drives on the system"
    echo "2) install ventoy on a drive"
    echo "3) flash a custom ISO on a drive"
    echo "4) download an ISO from the archive list and flash it"
    echo "5) install GRUB bootloader to drive"
    echo "6) clean the temp directory (useful if you are encountering errors)"
    echo "q) quit"
        
        read -r -p "your selection: " selection
        case $selection in
            1)
                echo -e ""
                echo -e "here are the list of drives and their partitions avalaible on your system:"
                echo -e ""
                lsblk
                echo -e "returning to main menu."
                ;;
            2)
                echo -e ""
                echo -e "grabbing the latest release of ventoy..."
                echo -e "the files will be saved in "$tmp_dir"."
                dl_ventoy_latest

                if [[ ! -d "$tmp_dir/ventoy/ventoy-$latest_build/" ]]; then
                    echo "now extracting the ventoy installer!"
                    mkdir -p "$tmp_dir/ventoy"
                    tar -xzf "$tmp_dir/ventoy.tar.gz" -C "$tmp_dir/ventoy"
                else
                    echo "ventoy installer seems to already exist, skipping extraction..."
                fi

                cd "$tmp_dir/ventoy/ventoy-$latest_build/"
                echo -e ""
                echo -e "ventoy installation will now begin. please specify which device do you want to install ventoy on. (e.g: 'sda')"
                read -r -p "which device? " device_sel

                if [[ $EUID -ne 0 ]]; then
                    echo "ventoy requires elevated privileges to continue. please authenticate:"
                    is_elevated="sudo"
                else
                    is_elevated=""
                fi
                
                $is_elevated ./Ventoy2Disk.sh -I /dev/$device_sel
                ;;
            3)
                echo -e "hi"
                ;;
            4)
                echo -e "for reference, your architecture is: $system_arch"
                ;;
            5)
                echo -e "hi"
                ;;
            6)
                echo -e ""
                echo -e "this action will completely delete the temp directory for flashThemAll. any saved ISOs, images, and ventoy installers will be erased."
                read -r -p "are you sure to continue? (y/n) " tmp_del_confirm

                if [[ "$tmp_del_confirm" == "y" || "$tmp_del_confirm" == "Y" ]]; then

                    if [[ $EUID -ne 0 ]]; then
                        echo "this operation requires elevated privileges to continue. please authenticate:"
                        is_elevated="sudo"
                    else
                        is_elevated=""
                    fi
                    
                    $is_elevated rm -rf "$tmp_dir/"
                    echo -e "the temp folder has been deleted!"
                    echo -e ""
                else
                    echo "deletion aborted, as you cancelled..."
                    echo -e ""
                fi
                ;;
            q|Q)
                echo -e "exiting..."
                break
                ;;
            *)
                echo -e "thats not a valid option!"
                ;;
        esac
    done
}

starthebanner
maininit_menu