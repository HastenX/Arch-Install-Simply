function run() {
    echo "Simple Arch Install"
    echo "Version 1.0 :3"
    formatDisk
    if [[ $(echo "$diskVar"|grep "nvm") != "" ]]; then
        isNvmVar=1
    else 
        isNvmVar=0
    fi

    if [[ $isNvmVar == 1 ]]; then
        uuid=$(blkid | grep $diskVar"p3" | grep -oE '[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}' )
    else
        uuid=$(blkid | grep $diskVar"3" | grep -oE '[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}' )
    fi

    read -p "Would you like encryption?(Y/n): " encryptionVar
    if [[ $encryptionVar == "Y" ]]; then
        encrypt
    fi

    modprobe dm_mod
    modprobe efivarfs

    partitionThird
    setDiskTypes

    mkdir /mnt/home
    mkdir /mnt/boot

    mountParts

    read -sp "Please enter the root password: " rootPasswordVar
    echo ""
    read -p "Please enter your username: " userVar
    read -sp "Please enter $userVar's password: " userPasswordVar
    echo ""
    read -p "Please enter the desktop you want:(g=gnome,p=plasma,h=hyprland) " desktopVar

    {
        echo ""
        echo "Y"
    } | pacstrap -i /mnt base sudo nano

    genfstab -U -p /mnt >> /mnt/etc/fstab

    # export sudoersFile="$(cat txt/sudoersFile.txt)"
    export sudoersFile="$(cat txt/sudoersFile.txt)" 
    export mkinitcpioFile="$(cat txt/mkinitcpioFile.txt)"
    export localeFile="$(cat txt/localeFile.txt)"
    export grubTopFile="$(cat txt/grub/grubTop.txt)"
    export grubBottomFile="$(cat txt/grub/grubBottom.txt)"
    export desktopVar
    export userVar
    export userPasswordVar
    export rootPasswordVar
    export isNvmVar
    export diskVar
    export encryptionVar
    export uuidVar

    # echo "isNvm:$isNvmVar,disk:$diskVar,uuid:$uuidVar"
    # read -p "Vars: " wait

    # arch-chroot /mnt "$(declare -f runChroot); runChroot $(echo "$sudoersFile") $(echo "$mkinitcpioFile") $(echo "$localeFile") $(echo "$grubTopFile") $(echo "$grubBottomFile") $(echo "$desktopVar") $(echo "$userVar") $(echo "$userPasswordVar") $(echo "$rootPasswordVar") $(echo "$isNvmVar") $(echo "$diskVar") $(echo "$encryptionVar") $(echo "$uuidVar")"
    arch-chroot /mnt bash -c "$(declare -f runChroot); runChroot \"$sudoersFile\" \"$mkinitcpioFile\" \"$localeFile\" \"$grubTopFile\" \"$grubBottomFile\" \"$desktopVar\" \"$userVar\" \"$userPasswordVar\" \"$rootPasswordVar\" \"$isNvmVar\" \"$diskVar\" \"$encryptionVar\" \"$uuidVar\""

    if [[ $isNvm == 1 ]]; then
        {
            echo "d" 
            echo "4" 
            echo "w"
        } | fdisk /dev/$diskVar
    else 
        {
        echo "d" 
        echo "4"
        echo "w" 
        }| fdisk /dev/$diskVar
    fi 
    # reboot
}

function formatDisk() {
    lsblk 
    read -p "Please enter the disk you'd like to format: " diskVar
    echo "p" | fdisk /dev/$diskVar
    read -p "Are you certain that this is the disk you want to reformat?(Y/n): " response

    if [[ $response == "Y" ]]; then
        cat txt/diskPartitionInput.txt | fdisk /dev/$diskVar
    else
        formatDisk
    fi
}

function encrypt() {
    if [[ $isNvm == 1  ]]; then
        cryptsetup luksFormat /dev/$diskVar"p3"
        cryptsetup open --type luks /dev/$diskVar"p3"
    else
        cryptsetup luksFormat /dev/$diskVar"3"
        cryptsetup open --type luks /dev/$diskVar"3"
    fi
}

function partitionThird() {
    if [[ $encryptionVar == "Y" ]]; then
        pvcreate -ff /dev/mapper/lvm
        vgcreate volgroup0 /dev/mapper/lvm

    else 
        if [[ $isNvm == 1 ]]; then
            pvcreate -ff /dev/$diskVar"p3"
            vgcreate volgroup0 /dev/$diskVar"p3"
        else
            pvcreate -ff /dev/$diskVar"3"
            vgcreate volgroup0 /dev/$diskVar"3"
        fi
    fi
    echo "p" | fdisk /dev/$diskVar
    echo "**The program will not work if home + root > 3rd partition**"
    read -p "Enter root storage(only num in GB): " root
    read -p "Enter home storage(only num in GB): " home
    lvcreate -L $root"GB" volgroup0 -n lv_root
    lvcreate -L  $home"GB" volgroup0 -n lv_home
}

function setDiskTypes() {
    if [[ $isNvm == 1 ]]; then
        mkfs.fat -F32 /dev/$diskVar"p1"
        mkfs.ext4 /dev/$diskVar"p2"
    else
        mkfs.fat -F32 /dev/$diskVar"1"
        mkfs.ext4 /dev/$diskVar"2"
    fi
    mkfs.ext4 /dev/volgroup0/lv_root
    mkfs.ext4 /dev/volgroup0/lv_home
}

function mountParts() {
    if [ ! -d /mnt/boot ]; then
        mkdir /mnt/boot
        mountParts
        return
    fi
    if [ ! -d /mnt/home ]; then
        mkdir /mnt/home
        mountParts
        return
    fi

    mount /dev/volgroup0/lv_root /mnt
    mount /dev/volgroup0/lv_home /mnt/home
    if [[ $isNvm == 1 ]]; then
        mount /dev/$diskVar"p2" /mnt/boot
    else 
        mount /dev/$diskVar"2" /mnt/boot
    fi
}

function runChroot() {
    if [ "$#" -lt 13 ]; then
        echo "Error: Minimum of 13 parameters required."
        echo "$1"
        read -p "Wait: " w
        echo "$2"
        read -p "Wait: " w
        echo "$3"
        read -p "Wait: " w
        echo "$4"
        read -p "Wait: " w
        echo "$5"
        read -p "Wait: " w
        echo "$6"
        read -p "Wait: " w
        echo "$7"
        read -p "Wait: " w
        echo "$8"
        read -p "Wait: " w
        echo "$9"
        read -p "Wait: " w
        echo "$10"
        read -p "Wait: " w
        echo "$11"
        read -p "Wait: " w
        echo "$12"
        read -p "Wait: " w
        echo "$13"
        read -p "Wait: " w
        return 1
    fi
    mkdir "/etc/storeRes"
    touch "/etc/storeRes/one"
    touch "/etc/storeRes/two"
    touch "/etc/storeRes/three"
    touch "/etc/storeRes/four"  
    touch "/etc/storeRes/five"
    touch "/etc/storeRes/six"
    touch "/etc/storeRes/seven"
    touch "/etc/storeRes/eight"  
    touch "/etc/storeRes/nine"
    touch "/etc/storeRes/ten"
    touch "/etc/storeRes/eleven"
    touch "/etc/storeRes/twelve"
    touch "/etc/storeRes/thirteen"
    echo "$1" > "/etc/storeRes/one" #about only half of file
    echo "$2" > "/etc/storeRes/two" #only the word "to"
    echo "$3" > "/etc/storeRes/three" #only the word "find "
    echo "$4" > "/etc/storeRes/four" #only the word "commands."
    echo "$5" > "/etc/storeRes/five" #nothing
    echo "$6" > "/etc/storeRes/six" #nothing
    echo "$7" > "/etc/storeRes/seven" #nothing
    echo "$8" > "/etc/storeRes/eight"  #nothing
    echo "$9" > "/etc/storeRes/nine" #nothing
    echo "${10}" > "/etc/storeRes/ten" #nothing
    echo "${11}" > "/etc/storeRes/eleven" #nothing
    echo "${12}" > "/etc/storeRes/twelve" #nothing
    echo "${13}" > "/etc/storeRes/thirteen" #nothing

    echo "root:$9" | chpasswd 

    useradd -m -g users -G wheel "$7"
    echo "$7:$8" | chpasswd  

    echo "$1" > "/etc/sudoers"

    mkdir "/boot/EFI"
    if [[ "${10}" == 1 ]]; then
        mount "/dev/"${11}"p1" "/boot/EFI"
    else
        mount "/dev/"${11}"1" "/boot/EFI"
    fi
    pacman -Syy --noconfirm grub kitty
    pacman -Syy --noconfirm git intel-media-drivers
    pacman -Syy --noconfirm mkinitcpio base-devel dosfstools 
    pacman -Syy --noconfirm efibootmgr mtools linux
    pacman -Syy --noconfirm networkmanager os-prober bash-completion
    pacman -Syy --noconfirm linux-headers linux-firmware mesa 
    pacman -Syy --noconfirm ufw libva-mesa-driver lvm2
    if [[ "$6" == "g" ]]; then
        pacman -Syy --noconfirm gnome-desktop gdm
        systemctl enable gdm
    fi
    if [[ "$6" == "p" ]]; then
        pacman -Syy --noconfirm plasma-desktop sddm
        systemctl enable sddm
    fi
    if [[ "$6" == "h" ]]; then
        pacman -Syy --noconfirm hyprland
    fi
    if [[ "$6" != "g" && "$6" != "p" && "$6" != "h" ]]; then
        echo "None anwsers recieved, default to plasma:"
        pacman -Syy --noconfirm plasma-desktop sddm
        systemctl enable sddm
    fi

    echo "$2" > "/etc/mkinitcpio.conf"
    mkinitcpio -p linux 

    echo "$3" > "/etc/locale.gen"
    locale-gen

    echo "$4" > "/etc/default/grub"
    if [[ ${12} == "Y" ]]; then
        echo 'GRUB_CMDLINE_LINUX_DEFAULT="loglevel=3 cryptdevice=${13}:volgroup0 quiet"' >> "/etc/default/grub"
    else
        echo 'GRUB_CMDLINE_LINUX_DEFAULT="loglevel=3 quiet"' >> "/etc/default/grub"
    fi
    echo 'GRUB_PRELOAD_MODULES="part_gpt part_msdos"' >> "/etc/default/grub"
    echo "$5" >> "/etc/default/grub"

    grub-install --target=x86_64-efi --bootloader-id=grub_uefi --recheck
    cp "/usr/share/locale/en@quot/LC_MESSAGES/grub.mo" "/boot/grub/locale/en.mo"
    grub-mkconfig -o "/boot/grub/grub.cfg"

    systemctl enable NetworkManager
    systemctl enable ufw
}

run