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
    # declare -f runChroot
    arch-chroot /mnt runChroot $(echo "$sudoersFile") $(echo "$mkinitcpioFile") $(echo "$localeFile") $(echo "$grubTopFile") $(echo "$grubBottomFile") $(echo "$desktopVar") $(echo "$userVar") $(echo "$userPasswordVar") $(echo "$rootPasswordVar") $(echo "$isNvmVar") $(echo "$diskVar") $(echo "$encryptionVar") $(echo "$uuidVar")

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

run