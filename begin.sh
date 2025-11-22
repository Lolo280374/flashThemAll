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
    echo "3) flash a custom ISO on a drive (isohybrid)"
    echo "4) flash a non-isohybrid image on a drive (e.g: windows ISOs)"
    echo "5) download an ISO from the archive list and flash it"
    echo "6) install GRUB bootloader to drive"
    echo "7) clean the temp directory (useful if you are encountering errors)"
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
                echo -e ""
                echo -e "please give the full path of your ISO image to flash. (e.g: /home/lolodotzip/GLaDOS.iso)"
                read -r -p "ISO file path: " custom_iso_path

                if [[ ! -f "$custom_iso_path" ]]; then
                    echo -e ""
                    echo -e "sorry, but the path you provided seems to not lead to a correct image..."
                    break
                fi

                echo -e ""
                echo -e "great! now, please specify the device you wish to install that ISO to. (e.g: 'sda')"
                echo -e "note, you may find out what devices are avalaible on your system using the 1st option in the main menu."
                read -r -p "which device? " device_custom_sel

                if [[ ! -b "/dev/$device_custom_sel" ]]; then
                    echo -e ""
                    echo -e "sorry, but the device you provided dosen't seem to exist. please check from the 1st tool in the main menu!"
                    echo -e "(for reference, tried checking for: /dev/$device_custom_sel)."
                    break
                fi

                echo -e ""
                echo -e "last, are you SURE to erase permanantly and entirely device block '/dev/$device_custom_sel' and it's associated files?"
                read -r -p "are you SURE to delete such device? (y/n) " device_custom_confirm

                if [[ "$device_custom_confirm" != "y" && "$device_custom_confirm" != "Y" ]]; then
                    echo "as you cancelled, the deletion has been aborted."
                    break
                fi

                if [[ $EUID -ne 0 ]]; then
                    echo "this operation requires elevated privileges to continue. please authenticate:"
                    is_elevated="sudo"
                else
                    is_elevated=""
                fi

                echo -e ""
                echo -e "flashing the image will now begin, please DO NOT DISCONNECT/UNMOUNT the device."
                echo -e ""
                $is_elevated dd if="$custom_iso_path" of="/dev/$device_custom_sel" bs=4M status=progress oflag=sync
                echo -e ""
                echo -e "the operation seems to have completed! :D"
                echo -e ""
                ;;
            4)
                echo -e ""
                echo -e "flashing a windows-type ISO image (non-isohybrid) requires using Ventoy (or similar) due to how the ISO image behaves."
                echo -e "using this feature will automatically install Ventoy to your drive, and then put the ISO you wanted to flash on that drive."

                read -r -p "is that okay wit you? (y/n) " nonisohybrid_warn_confirm
                if [[ "$nonisohybrid_warn_confirm" != "y" && "$nonisohybrid_warn_confirm" != "Y" ]]; then
                    echo -e "sorry, but this feature requires the usage of Ventoy to work..."
                    break
                fi

                echo -e ""
                echo -e "great! what ISO image do you wish to flash? please specify it's full path. (e.g: /home/lolodotzip/GLaDOS.iso)"
                read -r -p "ISO file path: " nonisohybrid_file_path

                if [[ ! -f "$nonisohybrid_file_path" ]]; then
                    echo -e ""
                    echo -e "sorry, but the path you provided seems to not lead to a correct image..."
                    break
                fi

                echo -e "looks like a valid file path!"
                echo -e ""
                echo -e "last, what device do you wish to flash that image to? (e.g: 'sda')"
                echo -e "note, you may find out what devices are avalaible on your system using the 1st option in the main menu."
                read -r -p "what device? " nonisohybrid_device_sel

                if [[ ! -b "/dev/$nonisohybrid_device_sel" ]]; then
                    echo -e ""
                    echo -e "sorry, but the device you provided dosen't seem to exist. please check from the 1st tool in the main menu!"
                    echo -e "(for reference, tried checking for: /dev/$nonisohybrid_device_sel)."
                    break
                fi

                echo -e ""
                echo -e "that device looks like a valid block device!"
                echo -e "great! the flash will start now. you will still need to anwser ventoy's confirmation prompts however."
                echo -e ""

                dl_ventoy_latest
                if [[ ! -d "$tmp_dir/ventoy/ventoy-$latest_build/" ]]; then
                    mkdir -p "$tmp_dir/ventoy"
                    tar -xzf "$tmp_dir/ventoy.tar.gz" -C "$tmp_dir/ventoy"
                fi

                cd "$tmp_dir/ventoy/ventoy-$latest_build/"
                if [[ $EUID -ne 0 ]]; then
                    echo "ventoy's installer requires elevated privileges to continue. please authenticate:"
                    is_elevated="sudo"
                else
                    is_elevated=""
                fi
                echo -e ""

                echo -e "just in case, unmounting your device's partitions..."
                $is_elevated umount /dev/${nonisohybrid_device_sel}*

                $is_elevated ./Ventoy2Disk.sh -I /dev/$nonisohybrid_device_sel
                echo -e "ventoy has been installed! your ISO will now be copied to the drive."
                echo -e "the copy process might hang even after reaching 100%, this is normal and might last a bit, stuff are happening in the background. pls wait! :D"

                $is_elevated umount /mnt/flashthemall 2>/dev/null
                $is_elevated mkdir -p "/mnt/flashthemall"
                $is_elevated mount /dev/${nonisohybrid_device_sel}1 /mnt/flashthemall

                $is_elevated rsync -ah --info=progress2 "$nonisohybrid_file_path" /mnt/flashthemall
                sync
                echo -e ""
                echo -e "your ISO has been successfully copied on your new Ventoy drive! you can now simply boot from it, and boot to your ISO!"
                echo -e "note: next time, to add an ISO to your drive, you can just copy it to that drive from your file explorer! no need to remake a whole Ventoy drive!"
                
                echo -e "enjoy! :D"
                echo -e ""
                ;;
            5)
                echo -e "for reference, your architecture is: $system_arch"
                ;;
            6)
                echo -e "hi"
                ;;
            7)
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