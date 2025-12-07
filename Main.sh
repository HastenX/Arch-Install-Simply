function run() {
    echo "Simple Arch Install"
    echo "Version 1.0 :3"
    formatDisk
    if [[ $(echo $disk|grep "nvm") != "" ]]; then
        isNvm=1
    else 
        isNvm=0
    fi


    read -p "Would you like encryption?(Y/n): " encryption
    if [[ $encryption == "Y" ]]; then
        encrypt
    fi

    modprobe dm_mod

    partitionThird
    setDiskTypes

    mkdir /mnt/home
    mkdir /mnt/boot

    mountParts

    {
        echo ""
        echo "Y"
    } | pacstrap -i /mnt base sudo nano

    genfstab -U -p /mnt >> /mnt/etc/fstab

    read -sp "Please enter the root password: " rootPassword
    echo ""
    read -p "Please enter your username: " user
    read -sp "Please enter $user's password: " userPassword
    echo ""
    read -p "Please enter the desktop you want:(g=gnome,p=plasma,h=hyprland) " desktop

    export sudoers=$(<txt/sudoersFile.txt)
    export mkinitcpio=$(<txt/mkinitcpioFile.txt)
    export locale=$(<txt/localeFile.txt)
    export grubTop=$(<txt/grub/grubTop.txt)
    export grubBottom=$(<txt/grub/grubBottom.txt)
    export desktop="$desktop"
    export user="$user"
    export userPassword="$userPassword"
    export rootPassword="$rootPassword"
    export isNvm="$isNvm"
    export disk="$disk"
    export encryption="$encryption"
    export uuid="$uuid"

    echo "Values: $sudoers, $mkinitcpio, $locale, $grubTop, $grubBottom, $desktop, $user, $userPassword, $rootPassword, $isNvm, $disk, $encryption, $uuid"
    read -p "Wait: " wait

    arch-chroot /mnt bash -c "$(declare -f runChroot); runChroot '$sudoers' '$mkinitcpio' '$locale' '$grubTop' '$grubBottom' '$desktop' '$user' '$userPassword' '$rootPassword' '$isNvm' '$disk' '$encryption' '$uuid'"

    umount -a

    if [[ $isNvm == 1 ]]; then
        {
            echo "d" 
            echo "4" 
            echo "w"
        } | fdisk /dev/$disk
    else 
        {
        echo "d" 
        echo "4"
        echo "w" 
        }| fdisk /dev/$disk
    fi 
    reboot
}

function formatDisk() {
    lsblk 
    echo "Please enter the disk you'd like to format:"
    read disk
    echo "p" | fdisk /dev/$disk
    read -p "Are you certain that this is the disk you want to reformat?(Y/n): " response

    if [[ $response == "Y" ]]; then
        cat txt/diskPartitionInput.txt | fdisk /dev/$disk
    else
        formatDisk
    fi
}

function encrypt() {
    if [[ $isNvm == 1  ]]; then
        uuid=$(blkid | grep $disk"p3" | grep -oE '[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}' )
        cryptsetup luksFormat /dev/$disk"p3"
        cryptsetup open --type luks /dev/$disk"p3"
    else
        uuid=$(blkid | grep $disk"3" | grep -oE '[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}' )
        cryptsetup luksFormat /dev/$disk"3"
        cryptsetup open --type luks /dev/$disk"3"
    fi
}

function partitionThird() {
    if [[ $encryption == "Y" ]]; then
        pvcreate -ff /dev/mapper/lvm
        vgcreate volgroup0 /dev/mapper/lvm

    else 
        if [[ $isNvm == 1 ]]; then
            pvcreate -ff /dev/$disk"p3"
            vgcreate volgroup0 /dev/$disk"p3"
        else
            pvcreate -ff /dev/$disk"3"
            vgcreate volgroup0 /dev/$disk"3"
        fi
    fi
    echo "p" | fdisk /dev/$disk
    echo "**The program will not work if home + root > 3rd partition**"
    read -p "Enter root storage(only num in GB): " root
    read -p "Enter home storage(only num in GB): " home
    lvcreate -L $root"GB" volgroup0 -n lv_root
    lvcreate -L  $home"GB" volgroup0 -n lv_home
}

function setDiskTypes() {
    if [[ $isNvm == 1 ]]; then
        mkfs.fat -F32 /dev/$disk"p1"
        mkfs.ext4 /dev/$disk"p2"
    else
        mkfs.fat -F32 /dev/$disk"1"
        mkfs.ext4 /dev/$disk"2"
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
        mount /dev/$disk"p2" /mnt/boot
    else 
        mount /dev/$disk"2" /mnt/boot
    fi
}

function runChroot() {
    echo "root:$9" | chpasswd 
    rootPassword=0

    useradd -m -g users -G wheel "$7"
    echo "$7:$8" | chpasswd  
    user=0
    userPassword=0

    echo $1 > /etc/sudoers

    mkdir /boot/EFI
    if [[ ${10} == 1 ]]; then
        mount /dev/${11}"p1" /boot/EFI
    else
        mount /dev/${11}"1" /boot/EFI
    fi
    
    pacman -Syyu --noconfirmpacman -Syy --noconfirm base-devel dosfstools grub git efibootmgr lvm2 mtools bash-completion networkmanager os-prober linux linux-headers linux-firmware mesa ufw libva-mesa-driver intel-media-drivers
    if [[ $6 == "g" ]]; then
        pacman -Syy --noconfirm gnome-desktop gdm
    fi
    if [[ $6 == "p" ]]; then
        pacman -Syy --noconfirm plasma-desktop sddm
    fi
    if [[ $6 == "h" ]]; then
        pacman -Syy --noconfirm hyprland
    fi
    if [[ $6 != "g" && $6 != "p" && $6 != "h" ]]; then
        echo "None anwsers recieved, default to plasma:"
        pacman -Syy --noconfirm plasma-desktop sddm
    fi

    echo $2 > /etc/mkinitcpio.conf
    mkinitcpio -p linux 

    echo $3 > /etc/locale.gen
    locale-gen

    echo $4 > /etc/default/grub
    if [[ ${12} == "Y" ]]; then
        echo GRUB_CMDLINE_LINUX_DEFAULT="loglevel=3 cryptdevice=UUID=${13}:volgroup0 quiet" >> /etc/default/grub
    else
        echo GRUB_CMDLINE_LINUX_DEFAULT="loglevel=3 quiet" >> /etc/default/grub
    fi
    echo $5 >> /etc/default/grub

    grub-install --target=x86_64-efi --bootloader-id=grub_uefi --recheck
    cp /usr/share/locale/en@quot/LC_MESSAGES/grub.mo /boot/grub/locale/en.mo
    grub-mkconfig -o /boot/grub/grub.cfg

    systemctl enable networkmanager
    systemctl enable ufw
    if [[ $6 == "p" ]]; then
        systemctl enable sddm
    fi
    if [[ $6 == "g" ]]; then
        systemctl enable gdm
    fi 
}

run