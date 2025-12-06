function runChroot() {
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

runChroot