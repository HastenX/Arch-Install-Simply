TIME_ZONE="US/Eastern"

function runChrootManager() {
    arch-chroot /mnt bash -c "echo root:${UserBuild[rootPasswd]} | chpasswd"
    arch-chroot /mnt bash -c "useradd -m -g users -G wheel ${UserBuild[username]}"
    arch-chroot /mnt bash -c "echo ${UserBuild[username]}:${UserBuild[userPasswd]} | chpasswd"
    removeUserPassword
    removeRootPassword

    pacmanInstall
    generateFiles
    systemctlSetup
    yayInstall

    echo "${UserBuild[sudoers_file]}" > /mnt/etc/sudoers
    arch-chroot /mnt bash -c "ln -s /usr/share/zoneinfo/$TIME_ZONE /etc/localtime; hwclock --systohc"
    echo "UserBuild[machineName]" > /mnt/etc/hostname
    sed -i "s~ ~~g" /mnt/etc/hostname
}

function pacmanInstall() {
    for pkg in ${UserBuild[pacmanPkg]}; do
        arch-chroot /mnt bash -c "pacman -Sy --noconfirm $pkg"
    done
}

function generateFiles() {
    # if [[ ${UserBuild[doCrypttab]} == "y" ]]; then
    #     echo "${UserBuild[crypttab_file]}" > /mnt/etc/crypttab
    #     secureKeyGen
    # fi
    echo "${UserBuild[mkinitcpio_file]}" > /mnt/etc/mkinitcpio.conf
    arch-chroot /mnt bash -c "mkinitcpio -p linux"
    echo "${UserBuild[locale_file]}" > /mnt/etc/locale.gen
    arch-chroot /mnt bash -c "locale-gen"
    echo LANG=en_US.UTF-8 > /mnt/etc/locale.conf

    echo "${UserBuild[grub_file]}" > /mnt/etc/default/grub
    arch-chroot /mnt bash -c "grub-install --target=x86_64-efi --bootloader-id=grub_uefi --efi-directory=/boot/efi --recheck"
    cp "/mnt/usr/share/locale/en@quot/LC_MESSAGES/grub.mo" "/mnt/boot/grub/locale/en.mo"
    arch-chroot /mnt bash -c "grub-mkconfig -o /boot/grub/grub.cfg"
}

# function secureKeyGen() {
#     # UUID_HOME=$(blkid -o value -s UUID /dev/mapper/volgroup0-lv_home)
#     # UUID_ROOT=$(blkid -o value -s UUID /dev/mapper/volgroup0-lv_root)
#     mkdir /mnt/secure
#     touch /mnt/secure/securekey.bin
#     dd if=/dev/urandom of=/mnt/secure/securekey.bin bs=512 count=4
#     chmod 000 /mnt/secure/securekey.bin
#     arch-chroot /mnt bash -c "echo -n ex | cryptsetup luksAddKey /dev/${UserBuild[lvmPartition]} /secure/securekey.bin"
# }

function systemctlSetup() {
    for pkg in ${UserBuild[systemctlPkg]}; do
        arch-chroot /mnt bash -c "systemctl enable $pkg"
    done
}

function yayInstall() {
    echo "${UserBuild[sudoers_temp_file]}" > /mnt/etc/sudoers
    arch-chroot /mnt bash -c "su -c 'cd /home/${UserBuild[username]}; git clone https://aur.archlinux.org/yay.git; cd yay/; makepkg -sif --noconfirm' ${UserBuild[username]}"
    for pkg in ${UserBuild[yayPkg]}; do
        arch-chroot /mnt bash -c "su -c 'yay -Sy --noconfirm $pkg' ${UserBuild[username]}"
    done
}