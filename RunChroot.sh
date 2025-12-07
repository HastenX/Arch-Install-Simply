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
pacman -Syy --noconfirm grub git intel-media-drivers
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
    echo GRUB_CMDLINE_LINUX_DEFAULT="loglevel=3 cryptdevice=UUID=${13}:volgroup0 quiet" >> "/etc/default/grub"
else
    echo GRUB_CMDLINE_LINUX_DEFAULT="loglevel=3 quiet" >> "/etc/default/grub"
fi
echo "$5" >> "/etc/default/grub"

grub-install --target=x86_64-efi --bootloader-id=grub_uefi --recheck
cp "/usr/share/locale/en@quot/LC_MESSAGES/grub.mo" "/boot/grub/locale/en.mo"
grub-mkconfig -o "/boot/grub/grub.cfg"

systemctl enable NetworkManager
systemctl enable ufw