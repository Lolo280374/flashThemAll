#!/bin/bash
#lolodotzip - flashthemall.
#released for hackclub!
#simple CLI tool to flash (anything) to (anything)!!

if [[ "$(uname)" == "Darwin" ]]; then
    echo -e ""
    echo -e "macOS is not supported. (or it might, but stuff might crap out, idk)"
    echo -e "u should use Linux if you want this to work."
    echo -e ""
    exit 1
fi

system_arch=$([[ "$(uname -m)" == "x86_64" ]] && printf "amd64" || printf "arm64")

function starthebanner {
    echo -e ""
    echo -e "WELCOME TO FLASHTHEMALL!!"
    echo -e "thanks hackclub - made by lolodotzip"
    echo -e "a simple utility to help you flash anything to any device you want! even god forbid windows!"

    if [[ $EUID -ne 0 ]]; then
        echo -e ""
        echo -e "note: you aren't running as sudo. it is recommanded you run this script as sudo to let the script handle all tasks on it's own, without needing your intervention."
        echo -e ""
    fi

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
        echo -e "curl failed to download the file. please try again!"
        return 1
    fi

    echo "download seems to have succeded, proceeding!"
}

function dl_systemrescue_latest() {
    latest_sysresc_build=$(curl -s https://www.system-rescue.org/Download/ \
    | grep -o "systemrescue-[0-9.]\+-amd64.iso" \
    | head -n 1 \
    | sed 's/systemrescue-\|\-amd64.iso//g')
    
    sysresc_dl_url="https://fastly-cdn.system-rescue.org/releases/$latest_sysresc_build/systemrescue-$latest_sysresc_build-amd64.iso"
    echo -e "now downloading the SystemRescue ISO image!"
    curl -L -o "$tmp_dir/systemrescue-$latest_sysresc_build.iso" "$sysresc_dl_url"

    curl_exit=$?
    echo -e ""

    if [[ $curl_exit -ne 0 ]]; then
        echo -e "curl failed to download the file. please try again!"
        return 1
    fi

    echo -e "download seems to have succeded, proceeding!"
}

function repo_init_driveselector() {
    echo -e "you've selected $repo_osdl_choice!"
    echo -e "what device do you wish to flash the image to? please refer to the 1st option in the main menu for a list of devices on your system. (e.g: sdb)"
    echo -e "this device will be FORMATTED and all DATA ON IT will be ERASED PERMANANTLY."
    read -r -p "what device to flash to? " repo_osdl_device

    if [[ ! -b "/dev/$repo_osdl_device" ]]; then
        echo -e ""
        echo -e "sorry, but the device you provided dosen't seem to exist. please check from the 1st tool in the main menu!"
        echo -e "(for reference, tried checking for: /dev/$nonisohybrid_device_sel)."
        echo -e ""
        break
    fi

    echo -e ""
    echo -e "that device looks like a valid block device!"
}

function repo_flashimg_drive() {
    if [[ $EUID -ne 0 ]]; then
        echo -e "the flash process requires elevated privileges to continue, please authenticate:"
        is_elevated="sudo"
    else
        is_elevated=""
    fi

    echo -e ""
    echo -e "just in case, unmounting your device's partitions..."
    $is_elevated umount /dev/${repo_osdl_device}*

    echo -e ""
    echo -e "the flashing process will now begin to '$repo_osdl_device'! (please do NOT DISCONNECT OR UNMOUNT THE DEVICE.)"
    $is_elevated dd if="$tmp_dir/$repo_osdl_choice.iso" of="/dev/$repo_osdl_device" bs=4M status=progress oflag=sync

    echo -e ""
    echo -e "unless an error occured, the flash process has ended and you should be good to go!"
    echo -e ""
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
    echo "6) install SystemRescue to a drive (recovery tool-packed boot drive)"
    echo "7) clean the temp directory (useful if you are encountering errors)"
    echo "q) quit"
        
        read -r -p "your selection: " selection
        case $selection in
            1)
                echo -e ""
                echo -e "here are the list of drives and their partitions avalaible on your system:"
                echo -e ""
                lsblk
                echo -e ""
                echo -e "returning to main menu."
                echo -e ""
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
                echo -e "this device will be FORMATTED and all DATA ON IT will be ERASED PERMANANTLY."
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
                echo -e ""
                echo -e "welcome! this tool will allow you to select an OS of your choice, it's version, and to directly flash it."
                echo -e "for reference, your system's architecture is $system_arch."
                echo -e "currently compatible OSes are: 'ubuntu', 'debian', 'popos', 'arch', 'alpine', 'fedora', 'centOS', 'linuxmint', 'bazzite', 'manjaro'."
                echo -e "more OSes will be compatible in the future, but for now these are the avalaible ones! if you have suggestions, shoot them on github!"
                echo -e ""
                read -r -p "what are you choosing? please input it exactly as written above: " repo_osdl_choice
                echo -e ""

                repo_osdl_choice=$(echo "$repo_osdl_choice" | tr '[:upper:]' '[:lower:]')
                case $repo_osdl_choice in
                ubuntu)
                    repo_init_driveselector
                    echo -e "do you wish to get the LTS version or the latest version (aka. interim)?"
                    read -r -p "your selection (lts/interim): " repo_ubuntu_ver

                    if [[ "$repo_ubuntu_ver" == "lts" || "$repo_ubuntu_ver" == "LTS" ]]; then
                        echo -e "saving the image to '$tmp_dir'."
                        echo -e ""
                        dl_ubuntu_ver=$(curl -sL https://ubuntu.com/download/desktop | grep -o 'version=[0-9.]\+&amp;architecture=amd64&amp;lts=true' | cut -d '=' -f 2 | cut -d '&' -f 1 | head -n 1)
                        curl -L -o "$tmp_dir/$repo_osdl_choice.iso" "https://releases.ubuntu.com/$dl_ubuntu_ver/ubuntu-$dl_ubuntu_ver-desktop-amd64.iso"

                    elif [[ "$repo_ubuntu_ver" == "interim" || "$repo_ubuntu_ver" == "Interim" ]]; then
                        echo -e "saving the image to '$tmp_dir'."
                        echo -e ""
                        dl_ubuntu_ver=$(curl -sL https://ubuntu.com/download/desktop | grep -o 'version=[0-9.]\+&amp;architecture=amd64"' | cut -d '=' -f 2 | cut -d '&' -f 1 | head -n 1)
                        curl -L -o "$tmp_dir/$repo_osdl_choice.iso" "https://releases.ubuntu.com/$dl_ubuntu_ver/ubuntu-$dl_ubuntu_ver-desktop-amd64.iso"

                    else
                        echo -e ""
                        echo -e "sorry, but the version you typed isn't a valid choice. please make sure to enter either 'lts', or 'interim'. (interim corresponds to the latest builds!!)"
                        echo -e ""
                        return 1
                    fi
                    
                    curl_exit=$?
                    echo -e ""

                    if [[ $curl_exit -ne 0 ]]; then
                        echo -e "curl failed to download the image for that OS. please try again!"
                        return 1
                    fi

                    echo -e "download seems to have succeded, proceeding to flashing!"
                    repo_flashimg_drive
                    ;;
                debian)
                    repo_init_driveselector
                    echo -e "the latest version of debian will now be downloaded and flashed to your device."
                    read -r -p "do you wish to get the netinstall version? selecting no will download the full install image. (y/n) " repo_debian_img

                    if [[ "$repo_debian_img" == "y" || "$repo_debian_img" == "Y" ]]; then
                        echo -e "saving the image to '$tmp_dir'."
                        echo -e ""
                        debian_inst_url=$(curl -sL https://www.debian.org/distrib/ | grep -o 'href="[^"]*amd64-netinst.iso"' | cut -d '"' -f 2)
                        curl -L -o "$tmp_dir/$repo_osdl_choice.iso" "$debian_inst_url"

                    else
                        echo -e "saving the image to '$tmp_dir'."
                        echo -e ""
                        debian_inst_url=$(curl -sL https://www.debian.org/distrib/ | grep -o 'href="[^"]*amd64-DVD-1.iso"' | cut -d '"' -f 2)
                        curl -L -o "$tmp_dir/$repo_osdl_choice.iso" "$debian_inst_url"
                    fi 

                    curl_exit=$?
                    echo -e ""

                    if [[ $curl_exit -ne 0 ]]; then
                        echo -e "curl failed to download the image for that OS. please try again!"
                        return 1
                    fi

                    echo -e "download seems to have succeded, proceeding to flashing!"
                    repo_flashimg_drive
                    ;;
                popos)
                    repo_init_driveselector
                    repo_popos_ver=$(curl -sL https://system76.com/pop/download/ | grep -o "fetchRelease('[0-9.]*'" | head -n 1 | cut -d "'" -f 2)
                    echo -e "the latest version of popOS will now be downloaded and flashed to your device."
                    read -r -p "quick question, do you need NVIDIA driver support? (y/n) " repo_popos_nv

                    if [[ "$repo_popos_nv" == "y" || "$repo_popos_nv" == "Y" ]]; then
                        echo -e "saving the image to '$tmp_dir'."
                        echo -e ""
                        popos_inst_url=$(curl -s "https://api.pop-os.org/builds/$repo_popos_ver/nvidia?arch=amd64" | grep -o '"url":"[^"]*"' | cut -d '"' -f 4)
                        curl -L -o "$tmp_dir/$repo_osdl_choice.iso" "$popos_inst_url"

                    else
                        echo -e "saving the image to '$tmp_dir'."
                        echo -e ""
                        popos_inst_url=$(curl -s "https://api.pop-os.org/builds/$repo_popos_ver/intel?arch=amd64" | grep -o '"url":"[^"]*"' | cut -d '"' -f 4)
                        curl -L -o "$tmp_dir/$repo_osdl_choice.iso" "$popos_inst_url"
                    fi

                    curl_exit=$?
                    echo -e ""

                    if [[ $curl_exit -ne 0 ]]; then
                        echo -e "curl failed to download the image for that OS. please try again!"
                        return 1
                    fi

                    echo -e "download seems to have succeded, proceeding to flashing!"
                    repo_flashimg_drive
                    ;;
                arch)
                    repo_init_driveselector
                    echo -e "the latest version of arch will now be downloaded and flashed to your device."
                    echo -e "saving the image to '$tmp_dir'."

                    echo -e ""
                    curl -L -o "$tmp_dir/$repo_osdl_choice.iso" "https://mirrors.edge.kernel.org/archlinux/iso/latest/archlinux-x86_64.iso"
                    curl_exit=$?
                    echo -e ""

                    if [[ $curl_exit -ne 0 ]]; then
                        echo -e "curl failed to download the image for that OS. please try again!"
                        return 1
                    fi

                    echo -e "download seems to have succeded, proceeding to flashing!"
                    repo_flashimg_drive
                    ;;
                alpine)
                    repo_init_driveselector
                    echo -e "the latest version of alpine will now be downloaded and flashed to your device."
                    read -r -p "do you want the standard or extended version of alpine? (standard/extended) " repo_alpine_ver

                    if [[ "$repo_alpine_ver" == "Standard" || "$repo_alpine_ver" == "standard" ]]; then
                        echo -e "saving the image to '$tmp_dir'."
                        echo -e ""
                        alpine_inst_url=$(curl -sL https://www.alpinelinux.org/downloads/ | grep -o 'href="[^"]*alpine-standard-[0-9.]\+-x86_64.iso"' | head -n 1 | cut -d '"' -f 2 | sed 's|&#x2F;|/|g')
                        curl -L -o "$tmp_dir/$repo_osdl_choice.iso" "$alpine_inst_url"

                    elif [[ "$repo_alpine_ver" == "Extended" || "$repo_alpine_ver" == "extended" ]]; then
                        echo -e "saving the image to '$tmp_dir'."
                        echo -e ""
                        alpine_inst_url=$(curl -sL https://www.alpinelinux.org/downloads/ | grep -o 'href="[^"]*alpine-extended-[0-9.]\+-x86_64.iso"' | head -n 1 | cut -d '"' -f 2 | sed 's|&#x2F;|/|g')
                        curl -L -o "$tmp_dir/$repo_osdl_choice.iso" "$alpine_inst_url"

                    else
                        echo -e ""
                        echo -e "sorry, but the version you typed isn't a valid choice. please make sure to enter either 'standard', or 'extended'."
                        echo -e ""
                        return 1
                    fi

                    curl_exit=$?
                    echo -e ""

                    if [[ $curl_exit -ne 0 ]]; then
                        echo -e "curl failed to download the image for that OS. please try again!"
                        return 1
                    fi

                    echo -e "download seems to have succeded, proceeding to flashing!"
                    repo_flashimg_drive
                    ;;
                fedora)
                    repo_init_driveselector
                    echo -e "the latest version of fedora will now be downloaded and flashed to your device."
                    read -r -p "do you want the workstation or desktop version? (desktop/workstation) " repo_fedora_type

                    if [[ "$repo_fedora_type" == "workstation" || "$repo_fedora_type" == "Workstation" ]]; then
                        echo -e "saving the image to '$tmp_dir'."
                        echo -e ""
                        fedora_inst_url=$(curl -sL https://fedoraproject.org/workstation/download | grep -o 'https://[^"]*Fedora-Workstation-Live-[^"]*x86_64[^"]*\.iso' | head -n 1)
                        curl -L -o "$tmp_dir/$repo_osdl_choice.iso" "$fedora_inst_url"

                    elif [[ "$repo_fedora_type" == "desktop" || "$repo_fedora_type" == "Desktop" ]]; then
                        echo -e "saving the image to '$tmp_dir'."
                        echo -e ""
                        fedora_inst_url=$(curl -sL https://fedoraproject.org/kde/download | grep -o 'https://[^"]*Fedora-KDE-Desktop-Live-[^"]*x86_64[^"]*\.iso' | head -n 1)
                        curl -L -o "$tmp_dir/$repo_osdl_choice.iso" "$fedora_inst_url"

                    else
                        echo -e ""
                        echo -e "sorry, but the version you typed isn't a valid choice. please make sure to enter either 'workstation', or 'desktop'."
                        echo -e ""
                        return 1
                    fi

                    curl_exit=$?
                    echo -e ""

                    if [[ $curl_exit -ne 0 ]]; then
                        echo -e "curl failed to download the image for that OS. please try again!"
                        return 1
                    fi

                    echo -e "download seems to have succeded, proceeding to flashing!"
                    repo_flashimg_drive
                    ;;
                centos)
                    repo_init_driveselector
                    echo -e "do you wish to install centOS Stream 9 or 10? 9 is more stable, while 10 uses the newer RHEL bases."
                    read -r -p "which build? (awnser '10' or '9') " repo_centos_ver

                    if [[ "$repo_centos_ver" == "10" ]]; then
                        echo -e "saving the image to '$tmp_dir'."
                        echo -e ""
                        curl -L -o "$tmp_dir/$repo_osdl_choice.iso" "https://mirrors.centos.org/mirrorlist?path=/10-stream/BaseOS/x86_64/iso/CentOS-Stream-10-latest-x86_64-dvd1.iso&redirect=1&protocol=https"

                    elif [[ "$repo_centos_ver" == "9" ]]; then
                        echo -e "saving the image to '$tmp_dir'."
                        echo -e ""
                        curl -L -o "$tmp_dir/$repo_osdl_choice.iso" "https://mirrors.centos.org/mirrorlist?path=/9-stream/BaseOS/x86_64/iso/CentOS-Stream-9-latest-x86_64-dvd1.iso&redirect=1&protocol=https"

                    else
                        echo -e ""
                        echo -e "sorry, but the version you typed isn't a valid choice. please make sure to enter either '10', or '9'."
                        echo -e ""
                        return 1
                    fi

                    curl_exit=$?
                    echo -e ""

                    if [[ $curl_exit -ne 0 ]]; then
                        echo -e "curl failed to download the image for that OS. please try again!"
                        return 1
                    fi

                    echo -e "download seems to have succeded, proceeding to flashing!"
                    repo_flashimg_drive
                    ;;
                linuxmint)
                    repo_init_driveselector
                    echo -e "the latest version of mint will now be downloaded and flashed to your device."
                    read -r -p "do you want the xfce, mate, or cinnamon version? (xfce/mate/cinnamon) " repo_mint_de

                    if [[ "$repo_mint_de" == "xfce" || "$repo_mint_de" == "XFCE" ]]; then
                        echo -e "saving the image to '$tmp_dir'."
                        echo -e ""
                        mint_inst_url=$(curl -sL "https://www.linuxmint.com/edition.php?id=324" | grep -o 'href="[^"]*">Linux Mint</a>' | head -n 1 | cut -d '"' -f 2)
                        curl -L -o "$tmp_dir/$repo_osdl_choice.iso" "$mint_inst_url"

                    elif [[ "$repo_mint_de" == "mate" || "$repo_mint_de" == "MATE" ]]; then
                        echo -e "saving the image to '$tmp_dir'."
                        echo -e ""
                        mint_inst_url=$(curl -sL "https://www.linuxmint.com/edition.php?id=323" | grep -o 'href="[^"]*">Linux Mint</a>' | head -n 1 | cut -d '"' -f 2)
                        curl -L -o "$tmp_dir/$repo_osdl_choice.iso" "$mint_inst_url"

                    elif [[ "$repo_mint_de" == "cinnamon" || "$repo_mint_de" == "Cinnamon" ]]; then
                        echo -e "saving the image to '$tmp_dir'."
                        echo -e ""
                        mint_inst_url=$(curl -sL "https://www.linuxmint.com/edition.php?id=322" | grep -o 'href="[^"]*">Linux Mint</a>' | head -n 1 | cut -d '"' -f 2)
                        curl -L -o "$tmp_dir/$repo_osdl_choice.iso" "$mint_inst_url"

                    else
                        echo -e ""
                        echo -e "sorry, but the DE you typed isn't a valid choice. please make sure to enter either 'xfce', 'mate' or 'cinnamon'."
                        echo -e ""
                        return 1
                    fi

                    curl_exit=$?
                    echo -e ""

                    if [[ $curl_exit -ne 0 ]]; then
                        echo -e "curl failed to download the image for that OS. please try again!"
                        return 1
                    fi

                    echo -e "download seems to have succeded, proceeding to flashing!"
                    repo_flashimg_drive
                    ;;
                bazzite)
                    repo_init_driveselector
                    echo -e "the latest version of bazzite will now be downloaded and flashed to your device."
                    read -r -p "quick question, do you need NVIDIA driver support? (y/n) " repo_bazzite_nv

                    if [[ "$repo_bazzite_nv" == "y" || "$repo_bazzite_nv" == "Y" ]]; then
                        echo -e "saving the image to '$tmp_dir'."
                        echo -e ""
                        curl -L -o "$tmp_dir/$repo_osdl_choice.iso" "https://download.bazzite.gg/bazzite-nvidia-open-stable-amd64.iso"

                    else
                        echo -e "saving the image to '$tmp_dir'."
                        echo -e ""
                        curl -L -o "$tmp_dir/$repo_osdl_choice.iso" "https://download.bazzite.gg/bazzite-stable-amd64.iso"
                    fi

                    curl_exit=$?
                    echo -e ""

                    if [[ $curl_exit -ne 0 ]]; then
                        echo -e "curl failed to download the image for that OS. please try again!"
                        return 1
                    fi

                    echo -e "download seems to have succeded, proceeding to flashing!"
                    repo_flashimg_drive
                    ;;
                manjaro)
                    repo_init_driveselector
                    echo -e "the latest version of manjaro will now be downloaded and flashed to your device."
                    read -r -p "do you want the xfce, kde, or gnome version? (kde/xfce/gnome) " repo_manjaro_de

                    if [[ "$repo_manjaro_de" == "kde" || "$repo_manjaro_de" == "KDE" ]]; then
                        echo -e "saving the image to '$tmp_dir'."
                        echo -e ""
                        manjaro_inst_url=$(curl -sL https://manjaro.org/products/download/x86 | grep -o 'href="[^"]*manjaro-kde[^"]*\.iso"' | head -n 1 | cut -d '"' -f 2)
                        curl -L -o "$tmp_dir/$repo_osdl_choice.iso" "$manjaro_inst_url"

                    elif [[ "$repo_manjaro_de" == "xfce" || "$repo_manjaro_de" == "XFCE" ]]; then
                        echo -e "saving the image to '$tmp_dir'."
                        echo -e ""
                        manjaro_inst_url=$(curl -sL https://manjaro.org/products/download/x86 | grep -o 'href="[^"]*manjaro-xfce[^"]*\.iso"' | head -n 1 | cut -d '"' -f 2)
                        curl -L -o "$tmp_dir/$repo_osdl_choice.iso" "$manjaro_inst_url"

                    elif [[ "$repo_manjaro_de" == "gnome" || "$repo_manjaro_de" == "GNOME" ]]; then
                        echo -e "saving the image to '$tmp_dir'."
                        echo -e ""
                        manjaro_inst_url=$(curl -sL https://manjaro.org/products/download/x86 | grep -o 'href="[^"]*manjaro-gnome[^"]*\.iso"' | head -n 1 | cut -d '"' -f 2)
                        curl -L -o "$tmp_dir/$repo_osdl_choice.iso" "$manjaro_inst_url"

                    else
                        echo -e ""
                        echo -e "sorry, but the DE you typed isn't a valid choice. please make sure to enter either 'xfce', 'kde' or 'gnome'."
                        echo -e ""
                        return 1
                    fi

                    curl_exit=$?
                    echo -e ""

                    if [[ $curl_exit -ne 0 ]]; then
                        echo -e "curl failed to download the image for that OS. please try again!"
                        return 1
                    fi

                    echo -e "download seems to have succeded, proceeding to flashing!"
                    repo_flashimg_drive
                    ;;
                *)
                    echo -e "thats not a valid option!"
                    echo -e ""
                    ;;
                esac
                ;;
            6)
                echo -e ""
                echo -e "this feature will install SystemRescue to your drive, an open-source feature-packed recovery tool. it is based on Linux."
                echo -e "to learn more, please visit 'system-rescue.org'!"

                read -r -p "do you wish to continue? (y/n) " sysresc_confirm_prompt
                if [[ "$sysresc_confirm_prompt" != "y" && "$sysresc_confirm_prompt" != "Y" ]]; then
                    echo -e ""
                    echo -e "okay, exiting!"
                    echo -e ""
                    break
                fi

                echo -e ""
                echo -e "great! please now specify which device do you wish to install SystemRescue to. (e.g: sdb)"
                echo -e "this device will be FORMATTED and all DATA ON IT will be ERASED PERMANANTLY."
                echo -e "to list the devices avalaible on your system, you can use the 1st option in the main menu..."

                read -r -p "which device? " sysresc_device_prompt
                if [[ ! -b "/dev/$sysresc_device_prompt" ]]; then
                    echo -e ""
                    echo -e "sorry, but the device you provided dosen't seem to exist. please check from the 1st tool in the main menu!"
                    echo -e "(for reference, tried checking for: /dev/$sysresc_device_prompt)."
                    echo -e ""
                    break
                fi

                echo -e ""
                echo -e "that device looks like a valid block device!"

                echo -e "the tool will now start downloading the image and flashing it."
                echo -e "note: a prompt to elevate the flash process might appear later!"
                echo -e ""
                dl_systemrescue_latest

                echo -e ""
                echo -e "the image will now be flashed to your device."
                cd "$tmp_dir/"

                echo -e ""
                echo -e "just in case, unmounting your device's partitions..."

                if [[ $EUID -ne 0 ]]; then
                    echo "the flash process requires elevated privileges to continue. please authenticate:"
                    is_elevated="sudo"
                else
                    is_elevated=""
                fi
                $is_elevated umount /dev/${sysresc_device_prompt}*

                echo -e ""
                echo -e "now flashing the image to '$sysresc_device_prompt'!!! (please do NOT DISCONNECT OR UNMOUNT THE DEVICE.)"
                $is_elevated dd if="$tmp_dir/systemrescue-$latest_sysresc_build.iso" of="/dev/$sysresc_device_prompt" bs=4M status=progress oflag=sync
                
                echo -e ""
                echo -e "systemRescue seems to have been successfully flashed to your device! :D"
                echo -e ""
                ;;
            7)
                echo -e ""
                echo -e "this action will completely delete the temp directory for flashThemAll. any saved ISOs, images, and ventoy installers will be erased."
                read -r -p "do you wish to continue? (y/n) " tmp_del_confirm

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
                echo -e ""
                echo -e "exiting..."
                echo -e ""
                break
                ;;
            *)
                echo -e ""
                echo -e "thats not a valid option!"
                echo -e ""
                ;;
        esac
    done
}

starthebanner
maininit_menu