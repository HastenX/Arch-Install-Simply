source src/ChrootManager.sh

function install_sh() {
    echo "Time to cook >:3c"
    sleep 1
    echo "Enjoy the ride in..."
    sleep 1
    for count in 3 2 1 GO!; do
        echo $count
        sleep 1
    done
    if [[ $test != "y" ]]; then
        (
            echo "g" #1
            echo "n" #2
            echo "1" #3
            echo "" 
            echo "+512M" #4
            echo "Y" #5
            echo "n" #6
            echo "2" #7
            echo "" #8
            echo "+1G" #9
            echo "Y" #10
            echo "n" #11
            echo "3" #12
            echo "" #13
            echo "" #14
            echo "Y" #15
            echo "t" #16
            echo "3" #17
            echo "44" #18
            echo "t" #19
            echo "1" #20
            echo "1" #21
            echo "w" #22
        ) | fdisk "/dev/${UserBuild[disk]}"
        setModprobe
        encrypt
        setUUID

        buildGrubDefaultPkg
        updateGrub
        updateCrypttab

        pvSetup
        formatPartitions
        ensureMountPoints

        downloadPacstrap
        genfstab -U -p /mnt > /mnt/etc/fstab

        runChrootManager
    fi
}

function encrypt() {
    if [[ ${UserBuild[encryption]} != "-1"  ]]; then 
        echo -n ${UserBuild[personalKey]} | cryptsetup luksFormat "/dev/${UserBuild[lvmPartition]}" --key-file /dev/stdin 
        echo ${UserBuild[personalKey]} | cryptsetup open --type luks "/dev/${UserBuild[lvmPartition]}" lvm
    fi
}

function pvSetup() {
    if [[ ${UserBuild[encryption]} == "-1" ]]; then
        vgcreate volgroup0 "/dev/${UserBuild[lvmPartition]}"
    else
        pvcreate /dev/mapper/lvm
        vgcreate volgroup0 /dev/mapper/lvm
    fi
    lvcreate -L "${UserBuild[rootSize]}GB" volgroup0 -n lv_root
    lvcreate -L "${UserBuild[homeSize]}GB" volgroup0 -n lv_home
    vgchange -a y
}

function formatPartitions() {
    mkfs.fat -F32 "/dev/${UserBuild[efiPartition]}"
    mkfs.ext4 "/dev/${UserBuild[bootPartition]}"
    mkfs.ext4 /dev/volgroup0/lv_root
    mkfs.ext4 /dev/volgroup0/lv_home
}

function ensureMountPoints() {
    if [[ $(mount | grep "lv_root") == "" ]]; then 
        mount /dev/volgroup0/lv_root /mnt
        ensureMountPoints
        return
    fi
    if [[ ! -d /mnt/home || $(mount | grep "lv_home") == "" ]]; then 
        mkdir /mnt/home
        mount /dev/volgroup0/lv_home /mnt/home
        ensureMountPoints
        return
    fi
    if [[ ! -d /mnt/boot || $(mount | grep "${UserBuild[bootPartition]}") == "" ]]; then 
        mkdir /mnt/boot
        mount "/dev/${UserBuild[bootPartition]}" /mnt/boot
        ensureMountPoints
        return
    fi
    if [[ ! -d /mnt/boot/efi || $(mount | grep "${UserBuild[efiPartition]}") == "" ]]; then 
        mkdir /mnt/boot/efi
        mount "/dev/${UserBuild[efiPartition]}" /mnt/boot/efi
        ensureMountPoints
        return
    fi
}

function setModprobe() {
    for i in ${UserBuild[modprobePkg]}; do
        modprobe "$i"
    done;
}

function downloadPacstrap() {
    for i in ${UserBuild[pacstrapPkg]}; do
        (echo ""; echo "";) | pacstrap -i /mnt "$i"
    done;
}