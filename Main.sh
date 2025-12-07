function run() {
    echo "Simple Arch Install"
    echo "Version 1.0 :3"
    formatDisk
    if [[ $(echo "$diskVar"|grep "nvm") != "" ]]; then
        isNvmVar=1
    else 
        isNvmVar=0
    fi


    read -p "Would you like encryption?(Y/n): " encryptionVar
    if [[ $encryptionVar == "Y" ]]; then
        encrypt
    fi

    modprobe dm_mod

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

    # echo "isNvm:$isNvmVar,disk:$diskVar,uuid:$uuidVar"
    # read -p "Vars: " wait

    # arch-chroot /mnt bash -c "$(declare -f runChroot); runChroot \
    # "$(printf '%q' "$sudoersFile")" \
    # "$(printf '%q' "$mkinitcpioFile")" \
    # "$(printf '%q' "$localeFile")" \
    # "$(printf '%q' "$grubTopFile")" \
    # "$(printf '%q' "$grubBottomFile")" \
    # "$(printf '%q' "$desktopVar")" \
    # "$(printf '%q' "$userVar")" \
    # "$(printf '%q' "$userPasswordVar")" \
    # "$(printf '%q' "$rootPasswordVar")" \
    # "$(printf '%q' "$isNvmVar")" \
    # "$(printf '%q' "$diskVar")" \
    # "$(printf '%q' "$encryptionVar")" \
    # "$(printf '%q' "$uuidVar")""
    runChroot \
    "$(printf '%q' "$sudoersFile")" \
    "$(printf '%q' "$mkinitcpioFile")" \
    "$(printf '%q' "$localeFile")" \
    "$(printf '%q' "$grubTopFile")" \
    "$(printf '%q' "$grubBottomFile")" \
    "$(printf '%q' "$desktopVar")" \
    "$(printf '%q' "$userVar")" \
    "$(printf '%q' "$userPasswordVar")" \
    "$(printf '%q' "$rootPasswordVar")" \
    "$(printf '%q' "$isNvmVar")" \
    "$(printf '%q' "$diskVar")" \
    "$(printf '%q' "$encryptionVar")" \
    "$(printf '%q' "$uuidVar")"

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
        uuid=$(blkid | grep $diskVar"p3" | grep -oE '[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}' )
        cryptsetup luksFormat /dev/$diskVar"p3"
        cryptsetup open --type luks /dev/$diskVar"p3"
    else
        uuid=$(blkid | grep $diskVar"3" | grep -oE '[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}' )
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
    exportFiles
    arch-chroot /mnt bash -c "
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
    echo "$sudoersFile" > "/etc/storeRes/one" 
    echo "$mkinitcpioFile" > "/etc/storeRes/two"
    echo "$localeFile" > "/etc/storeRes/three" 
    echo "$grubTop" > "/etc/storeRes/four" 
    echo "$grubBottomFile" > "/etc/storeRes/five" 
    echo "$desktop" > "/etc/storeRes/six" 
    echo "$userVar" > "/etc/storeRes/seven" 
    echo "$userPasswordVar" > "/etc/storeRes/eight"  
    echo "$rootPasswordVar" > "/etc/storeRes/nine" 
    echo "$isNvmVar" > "/etc/storeRes/ten" 
    echo "$diskVar" > "/etc/storeRes/eleven" 
    echo "$encryptionVar" > "/etc/storeRes/twelve" 
    echo "$uuidVar" > "/etc/storeRes/thirteen"
    "

    exportFiles
    arch-chroot /mnt bash -c "echo "root:$rootPasswordVar" | chpasswd "
    rootPasswordVar=0

    exportFiles
    arch-chroot /mnt bash -c "useradd -m -g users -G wheel "$userVar""
    exportFiles
    arch-chroot /mnt bash -c "echo "$userVar:$userPasswordVar" | chpasswd "
    userVar=0
    userPasswordVar=0
    exportFiles
    arch-chroot /mnt bash -c "echo "$sudoersFile" > /etc/sudoers"

    arch-chroot /mnt bash -c "mkdir "/boot/EFI""
    if [[ "$isNvmVar" == 1 ]]; then
        exportFiles
        arch-chroot /mnt bash -c "mount /dev/$diskVar'p1' /boot/EFI"
    else
        exportFiles
        arch-chroot /mnt bash -c "mount /dev/$diskVar'1' /boot/EFI"
    fi
    arch-chroot /mnt bash -c "pacman -Syy --noconfirm grub git intel-media-drivers; pacman -Syy --noconfirm mkinitcpio base-devel dosfstools; pacman -Syy --noconfirm efibootmgr mtools linux; pacman -Syy --noconfirm networkmanager os-prober bash-completion; pacman -Syy --noconfirm linux-headers linux-firmware mesa; pacman -Syy --noconfirm ufw libva-mesa-driver lvm2; pacman -Syy --noconfirm grub"
    if [[ "$desktop" == "g" ]]; then
        arch-chroot /mnt bash -c "pacman -Syy --noconfirm gnome-desktop gdm"
        arch-chroot /mnt bash -c "systemctl enable gdm"
    fi
    if [[ "$desktop" == "p" ]]; then
        arch-chroot /mnt bash -c "pacman -Syy --noconfirm plasma-desktop sddm"
        arch-chroot /mnt bash -c "systemctl enable sddm"
    fi
    if [[ "$desktop" == "h" ]]; then
        arch-chroot /mnt bash -c "pacman -Syy --noconfirm hyprland"
    fi
    if [[ "$desktop" != "g" && "$desktop" != "p" && "$desktop" != "h" ]]; then
        echo "None anwsers recieved, default to plasma:"
        arch-chroot /mnt bash -c "pacman -Syy --noconfirm plasma-desktop sddm"
        arch-chroot /mnt bash -c "systemctl enable sddm"
    fi

    exportFiles
    arch-chroot /mnt bash -c "echo "$mkinitcpioFile" > /etc/mkinitcpio.conf"
    arch-chroot /mnt bash -c "mkinitcpio -p linux"

    exportFiles
    arch-chroot /mnt bash -c "echo "$localeFile" > /etc/locale.gen"
    arch-chroot /mnt bash -c "locale-gen"

    exportFiles
    arch-chroot /mnt bash -c "echo "$grubTopFile" > /etc/default/grub"
    exportFiles
    if [[ $encryptionVar == "Y" ]]; then
        arch-chroot /mnt bash -c "echo GRUB_CMDLINE_LINUX_DEFAULT="loglevel=3 cryptdevice=UUID=$uuid:volgroup0 quiet" >> "/etc/default/grub""
    else
        arch-chroot /mnt bash -c "echo GRUB_CMDLINE_LINUX_DEFAULT="loglevel=3 quiet" >> "/etc/default/grub""
    fi
    exportFiles
    arch-chroot /mnt bash -c "echo "$grubBottomFile" >> "/etc/default/grub""
    arch-chroot /mnt bash -c "grub-install --target=x86_64-efi --bootloader-id=grub_uefi --recheck"
    arch-chroot /mnt bash -c "cp "/usr/share/locale/en@quot/LC_MESSAGES/grub.mo" "/boot/grub/locale/en.mo""
    arch-chroot /mnt bash -c "grub-mkconfig -o "/boot/grub/grub.cfg""

    arch-chroot /mnt bash -c "systemctl enable NetworkManager"
    arch-chroot /mnt bash -c "systemctl enable ufw"
}

function exportFiles() {
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
}
runChroot
# run