function run() {
    echo "Simple Arch Install"
    echo "Version 1.0 :3"
    formatDisk
    if [[ $(echo $disk|grep "nvm") != "" ]]; then
        isNvm=1
    else 
        isNvm=0
    fi


    read -p "Would you like encryption?(Y/n): " ecryption
    if [[ $ecryption == "Y" ]]; then
        encrypt
    fi

    modprobe dm_mod

    partitionThird
    setDiskTypes
    mountParts

    pacstrap -i /mnt base sudo nano

    genfstab -U -p /mnt >> /mnt/etc/fstab

    arch-chroot /mnt
    passwd

    read -p "Please enter your username: " user
    Useradd -m -g users -G wheel $user
    passwd $user
    cat txt/sudoersFile.txt > /etc/sudoers

    mountBoot

    echo Y | pacman -S  base-devel dosfstools grub git efibootmgr lvm2 mtools bash-completion networkmanager os-prober linux linux-headers linux-firmware mesa ufw libva-mesa-driver intel-media-drivers
    read -p "Please enter the desktop you want:(g=gnome,p=plasma,h=hyprland) " $desktop
    setDesktop $desktop

    cat txt/mkinitcpioFile.txt > /etc/mkinitcpio.conf
    mkinitcpio -p linux 

    cat txt/localeFile.txt > /etc/locale.gen
    locale-gen

    generateGrubFile
    cat txt/grub/compiledGrub.txt > etc/default/grub

    grub-install --target=x86_64-efi --bootloader-id=grub_uefi --recheck
    cp /usr/share/locale/en@quot/LC_MESSAGES/grub.mo /boot/grub/locale/en.mo
    grub-mkconfig -o /boot/grub/grub.cfg

    systemctl enable networkmanager
    systemctl enable ufw
    if [[ $desktop == "p" ]]; then
        systemctl enable sddm
    fi
    if [[ $desktop == "g" ]]; then
        systemctl enable gdm
    fi 

    exit
    umount -a
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
        cryptstup open --type luks /dev/$disk"p3"
    else
        uuid=$(blkid | grep $disk"3" | grep -oE '[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}' )
        cryptsetup luksFormat /dev/$disk"3"
        cryptstup open --type luks /dev/$disk"3"
    fi
}

function partitionThird() {
    if [[ $encryption == "Y" ]]; then
        pvcreate /dev/mapper/lvm
        vgcreate volgroup0 /dev/mapper/lvm

    else 
        if [[ $isNvm == 1 ]]; then
            pvcreate /dev/$disk"p3"
            vgcreate volgroup0 /dev/$disk"p3"
        else
            pvcreate /dev/$disk"3"
            vgcreate volgroup0 /dev/$disk"3"
        fi
    fi
    read -p "Enter root storage: " root
    read -p "Enter home storage: " home
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
    mkdir /mnt/home
    mkdir /mnt/boot
    mount /dev/volgroup0/lv_root /mnt
    mount /dev/volgroup0/lv_root /mnt/home
    if [[ $isNvm == 1 ]]; then
        mount /dev/$disk"p2" /mnt/boot
    else 
        mount /dev/$disk"2" /mnt/boot
    fi
}

function mountBoot() {
    mkdir /boot/EFI
    if [[ $isNvm == 1 ]]; then
        mount /dev/$disk"p1" /boot/EFI
    else
        mount /dev/$disk"1" /boot/EFI
    fi
}

function setDesktop() {
    if [[ $1 == "g" ]]; then
        echo Y | pacman -S gnome-desktop gdm
        return
    fi
    if [[ $1 == "p" ]]; then
        echo Y | pacman -S plasma-desktop sddm
        return
    fi
    if [[ $1 == "h" ]]; then
        echo Y | pacman -S hyprland
        return
    fi
    echo "None anwsers recieved, default to plasma:"
    echo Y | pacman -S plasma-desktop sddm
}

function generateGrubFile() {
    cat txt/grub/grubTop.txt > txt/grub/compiledGrub.txt
    if [[ $encryption == 1 ]]; then
        echo GRUB_CMDLINE_LINUX_DEFAULT="loglevel=3 cryptdevice=UUID=$uuid:volgroup0 quiet" >> txt/grub/compiledGrub.txt
    else
        echo GRUB_CMDLINE_LINUX_DEFAULT="loglevel=3 quiet" >> txt/grub/compiledGrub.txt
    fi
    cat txt/grub/grubBottom.txt >> txt/grub/compiledGrub.txt
}

run