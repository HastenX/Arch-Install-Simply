function runChrootManager() {
    declare -f setUserPasswd > null; arch-chroot /mnt bash -c "$(setUserPasswd)"
    removeUserPassword
    removeRootPassword
    declare -f pacmanInstall > null; arch-chroot /mnt bash -c "$(pacmanInstall)"
    declare -f generateFiles > null; arch-chroot /mnt bash -c "$(generateFiles)"
    declare -f systemctlSetup > null; arch-chroot /mnt bash -c "$(systemctlSetup)"
}

function setUserPasswd() {
    echo "root:${UserBuild[rootPasswd]}" | chpasswd 

    useradd -m -g users -G wheel "${UserBuild[username]}"
    echo "${UserBuild[username]}":"${UserBuild[userPasswd]}" | chpasswd  
}

function pacmanInstall() {
    for pkg in ${UserBuild[pacmanPkg]}; do
        pacman -Syu --noconfirm "$pkg"
    done
}

function generateFiles() {
    echo "${UserBuild[mkinitcpio_file]}" > /etc/mkinitcpio.conf
    mkinitcpio -p linux 
    echo "${UserBuild[locale_file]}" > /etc/locale.gen
    locale-gen
    echo "${UserBuild[grub_file]}" > /etc/default/grub
    grub-install --target=x86_64-efi --bootloader-id=grub_uefi --efi-directory=/boot/efi --recheck
    cp "/usr/share/locale/en@quot/LC_MESSAGES/grub.mo" "/boot/grub/locale/en.mo"
    grub-mkconfig -o "/boot/grub/grub.cfg"
}

function systemctlSetup() {
    systemctl enable NetworkManager
    systemctl enable ufw
    case "${UserBuild[displayManager]}" in 
        "sddm")
            systemctl enable sddm
        ;;
        "gdm")
            systemctl enable gdm
        ;;
    esac
}