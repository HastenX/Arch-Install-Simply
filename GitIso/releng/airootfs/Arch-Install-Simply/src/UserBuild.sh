#TODO: convert to hashmap with declare -A Userbuild = (...)
declare -g -A UserBuild
# Userdata
UserBuild[username]="-1" 
UserBuild[userPasswd]="-1" 
UserBuild[rootname]="root"
UserBuild[rootPasswd]="-1"
# Pkg
pacstrapPackages=""base" "nano""
pacmanPackages=""lvm2" "sudo" "ufw" "mkinitcpio" "base-devel" "mesa" "grub" "git" "base-devel" "dosfstools" "efibootmgr" "mtools" "linux" "networkmanager" "os-prober" "bash-completion" "linux-headers"" 
yayPkg=""""
systemctlPackages=""NetworkManager" "ufw""

modprobePackages=""efivarfs" "dm_mod""

UserBuild[pacstrapPkg]="$pacstrapPackages"  
UserBuild[pacmanPkg]="$pacmanPackages"
UserBuild[modprobePkg]="$modprobePackages"
UserBuild[systemctlPkg]="$systemctlPackages"

mkinitcpioHooks=""base" "udev" "autodetect" "microcode" "modconf" "kms" "keyboard" "keymap" "consolefont" "block" "lvm2" "filesystems" "fsck""
mkinitcpioFiles=""

UserBuild[mkinitcpioHOOKS]="$mkinitcpioHooks"
UserBuild[mkinitcpioFILES]="$mkinitcpioFiles"

grubDefaultPackage=""loglevel=3" "quiet""
UserBuild[grubDefaultPkg]="$grubDefaultPackage"
# drive
UserBuild[disk]="-1"
UserBuild[diskType]="-1"
UserBuild[machineType]="-1"

UserBuild[encryption]="-1"
UserBuild[personalKey]="-1"
UserBuild[doCrypttab]="-1"

UserBuild[efiPartition]="-1"
UserBuild[bootPartition]="-1"
UserBuild[lvmPartition]="-1"

UserBuild[lvmUUID]="-1"
UserBuild[homeSize]=-1
UserBuild[rootSize]=-1

# UI
UserBuild[desktop]="-1"
UserBuild[displsyManager]="-1"
UserBuild[console]="-1"
UserBuild[browser]="-1"
UserBuild[fileManager]="-1"

#Files
UserBuild[locale_file]="$(cat bin/localeFile.bin)"
UserBuild[sudoers_file]="$(cat bin/sudoersFile.bin)"
UserBuild[sudoers_temp_file]="ALL ALL=(ALL:ALL) NOPASSWD: ALL"

UserBuild[grub_file]="$(cat bin/grubFile.bin)"
UserBuild[grubLock]=0

UserBuild[mkinitcpio_file]="$(cat bin/mkinitcpioFile.bin)"
UserBuild[mkinitcpioLock]=0

UserBuild[crypttab_file]="$(cat bin/crypttabFile.bin)"
UserBuild[crypttabLock]=0

# Userdata code
setUsername() {
    UserBuild[username]="$1"
}

setUserPasswd() {
    UserBuild[userPasswd]="$1"
}

setRootPasswd() {
    UserBuild[rootPasswd]="$1"
}

removeUserPassword() {
    UserBuild[userPasswd]="-1"
}

removeRootPassword() {
    UserBuild[rootPasswd]="-1"
}

# pkg code
addPacstrapPkg() {
    for arg in "$@"; do
        UserBuild[pacstrapPkg]+=" $arg"
    done
}

addPacmanPkg() {
    for arg in "$@"; do
        UserBuild[pacmanPkg]+=" $arg"
    done
}

addYayPkg() {
    for arg in "$@"; do
        UserBuild[yayPkg]+=" $arg"
    done
}

addSystemctlPkg() {
    for arg in "$@"; do
        UserBuild[systemctlPkg]+=" $arg"
    done
}

# Pacman controlled packages:
setDisplsyManager() {
    UserBuild[displsyManager]="$1"
    addPacmanPkg "${UserBuild[displsyManager]}"
    # TODO: ADD CONDITIONSadd "${UserBuild[displsy_manager]}"
}

setDesktop() {
    UserBuild[desktop]="$1"
    addPacmanPkg "${UserBuild[desktop]}"
    # TODO: ADD CONDITIONSadd "${UserBuild[desktop]}"
}

setConsole() {
    UserBuild[console]="$1"
    addPacmanPkg "${UserBuild[console]}"
    # TODO: ADD CONDITIONSadd "${UserBuild[console]}"
}

setBrowser() {
    UserBuild[browser]="$1"
    addYayPkg "${UserBuild[browser]}"
    # TODO: ADD CONDITIONSadd "${UserBuild[browser]}"
}

setFileManager() {
    UserBuild[fileManager]="$1"
    addPacmanPkg "${UserBuild[fileManager]}"
}

updateHardware() {
    if [[ $(lspci | grep -i "AMD") != "" ]]; then
        addPacmanPkg "libva-mesa-driver"
    fi
    if [[ $(lspci | grep -i "NVIDIA") != "" ]]; then
        addPacmanPkg "nvidia" "nvidia-utils" "nvidia-settings"
    fi
    if [[ $(lspci | grep -i "Intel") != "" ]]; then
        addPacmanPkg "intel-media-driver"
    fi
}

# Modprobe
insertModprobePkg() {
    for arg in "$@"; do
        UserBuild[modprobePkg]+=" $arg"
    done
}

updateModprobePkg() {
    if [[ ${UserBuild[encryption]} != "-1" ]]; then
        insertModprobePkg "dm_crypt"
    fi
}

#mkinit
insertMkinitcpioHOOKS() {
    if [[ $# > 1 ]]; then
        echo "Error: parsing >1 value into insertMkinitcpioHOOKS"
        exit 1
    fi
    read -a array <<< ${UserBuild[mkinitcpioHOOKS]}
    temp1=${array[-1]}
    temp2=${array[-2]}
    array[-2]="$1"
    array[-1]="$temp2"
    result=${array[@]}
    result+=" "$temp1""
    UserBuild[mkinitcpioHOOKS]="$result"
}

insertMkinitcpioFILES() {
    for arg in "$@"; do
        UserBuild[mkinitcpioFILES]+=" $arg"
    done
}

buildMkinitcpioHOOKS() {
    if [[ ${UserBuild[encryption]} != "-1" ]]; then
        insertMkinitcpioHOOKS "encrypt"
    fi
}

buildMkinitcpioFILES() {
    if [[ ${UserBuild[personalKey]} == "-1" && ${UserBuild[encryption]} != "-1" ]]; then
        insertMkinitcpioFILES "/secure/securekey.bin"
    fi
}

#grub
insertGrubDefaultPkg() {
    if [[ $# > 1 ]]; then
        echo "Error: parsing >1 value into insertGrubDefaultPkg"
        exit 1
    fi
    read -a array <<< ${UserBuild[grubDefaultPkg]}
    temp=${array[-1]}
    array[-1]="$1"
    result=${array[@]}
    result+=" "$temp""
    UserBuild[grubDefaultPkg]="$result"
}

buildGrubDefaultPkg() {
    if [[ ${UserBuild[encryption]} != "-1"  ]]; then
        insertGrubDefaultPkg ""root=/dev/mapper/volgroup0-lv_root" "cryptdevice=UUID=${UserBuild[lvmUUID]}:volgroup0""  # "root=/dev/mapper/volgroup0-lv_root"
    fi
}

#Disk data
setDisk() {
    UserBuild[disk]=$1
    generateDiskType
}

generateDiskType() {
    if [[ $(echo $disk | grep "nvm") ]]; then
        UserBuild[diskType]="nvm"
        return
    fi
    if [[ $(echo $disk | grep "sda") ]]; then
        UserBuild[diskType]="sda"
        return
    fi
    echo "Error: undesernable disk type"
}

setMachineType() {
    # TODO: add logic
    UserBuild[machineType]="$1"
}

setEncryption() {
    UserBuild[encryption]="$1"
}

setPersonalKey() {
    UserBuild[personalKey]="$1"
}

setUUID() {
    if [[ ${UserBuild[diskType]} == "-1" ]]; then
        echo "Error: diskType is not set"
        exit 1
    fi
    if [[ ${UserBuild[diskType]}=="sda" ]]; then
        UserBuild[lvmUUID]=$(blkid -o value -s UUID /dev/"${UserBuild[disk]}"3)
    else
        UserBuild[lvmUUID]=$(blkid -o value -s UUID /dev/"${UserBuild[disk]}"p3)
    fi
}

setHomeSize() {
    UserBuild[homeSize]="$1"
}

setRootSize() {
    UserBuild[rootSize]="$1"
}

# FILE MANAGEMENT
updateGrub() {
    if [[ ${UserBuild[grubLock]} != 0 ]]; then 
        echo "Error: grub already updated"
        exit 1
    fi
    sed -i s~"\[\[insert\]\]~${UserBuild[grubDefaultPkg]}"~g bin/grubFile.bin
    UserBuild[grub_file]="$(cat bin/grubFile.bin)"
    UserBuild[grubLock]=1
}

# param: mkinitcpioPkg
updateMkinitcpio() {
    if [[ ${UserBuild[mkinitcpioLock]} != 0 ]]; then 
        echo "Error: mkinitcpio already updated"
        exit 1
    fi
    sed -i s~'\[\[insertHooks\]\]'~"${UserBuild[mkinitcpioHOOKS]}~g" bin/mkinitcpioFile.bin
    sed -i s~'\[\[insertFiles\]\]'~"${UserBuild[mkinitcpioFILES]}~g" bin/mkinitcpioFile.bin
    UserBuild[mkinitcpio_file]="$(cat bin/mkinitcpioFile.bin)"
    UserBuild[mkinitcpioLock]=1
}

updateCrypttab() {
    if [[ ${UserBuild[crypttabLock]} != 0 ]]; then 
        echo "Error: updateCrypttab already updated"
        exit 1
    fi
    sed -i 's~\[\[insertName\]\]'~"volgroup0~g" bin/crypttabFile.bin
    sed -i 's~\[\[insertUUID\]\]'~UUID="${UserBuild[lvmUUID]}~g" bin/crypttabFile.bin
    sed -i 's~\[\[insertFilePath\]\]~/secure/securekey.bin~g' bin/crypttabFile.bin
    UserBuild[crypttab_file]="$(cat bin/crypttabFile.bin)"
    UserBuild[crypttabLock]=1
}