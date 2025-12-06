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

    cat txt/pacstrapInput.txt | pacstrap -i /mnt base sudo nano

    genfstab -U -p /mnt >> /mnt/etc/fstab

    arch-chroot /mnt ./Chroot.sh

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

run