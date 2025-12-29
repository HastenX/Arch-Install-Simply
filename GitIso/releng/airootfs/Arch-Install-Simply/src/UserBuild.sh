#TODO: convert to hashmap with declare -A Userbuild = (...)
declare -A UserBuild
# Userdata
UserBuild[username]="-1" 
UserBuild[userPasswd]="-1" 
UserBuild[rootname]="root"
UserBuild[rootPasswd]="-1"
# Pkg
pacstrapPackages=""base" "nano""
pacmanPackages=""sudo" "base-devel" "mesa" "grub" "git" "mkinitcpio" "base-devel" "dosfstools" "efibootmgr" "mtools" "linux" "networkmanager" "os-prober" "bash-completion" "linux-headers"" 
yayPkg=""""

modprobePackages=""efivarfs" "dm_mod""

UserBuild[pacstrapPkg]="$pacstrapPackages"  
UserBuild[pacmanPkg]="$pacmanPackages"
UserBuild[modprobePkg]="$modprobePackages"

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
UserBuild[lvmUUID]="-1"
UserBuild[homeSize]=-1
UserBuild[rootSize]=-1

UserBuild[fileManager]="-1"

# UI
UserBuild[desktop]="-1"
UserBuild[displsyManager]="-1"
UserBuild[console]="-1"
UserBuild[browser]="-1"
UserBuild[fileManager]="-1"

#Files
UserBuild[locale_file]="$(cat bin/localeFile.bin)"
UserBuild[sudoers_file]="$(cat bin/sudoersFile.bin)"

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

popUserPassword() {
    echo ${UserBuild[userPasswd]}
    UserBuild[userPasswd]="-1"
}

popRootPassword() {
    echo ${UserBuild[rootPasswd]}
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

# Pacman controlled packages:
setDisplsyManager() {
    UserBuild[displsyManager]="$1"
    addPacmanPkg
    # TODO: ADD CONDITIONSadd "${UserBuild[displsy_manager]}"
}

setDesktop() {
    UserBuild[desktop]="$1"
    # TODO: ADD CONDITIONSadd "${UserBuild[desktop]}"
}

setConsole() {
    UserBuild[console]="$1"
    # TODO: ADD CONDITIONSadd "${UserBuild[console]}"
}

setBrowser() {
    UserBuild[browser]="$1"
    # TODO: ADD CONDITIONSadd "${UserBuild[browser]}"
}

setFileManager() {
    UserBuild[fileManager]="$1"
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
        insertModprobePkg "dm_encrypt"
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
    array+=$temp1
    UserBuild[mkinitcpioHOOKS]="${array[@]}"
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
    array+=$temp
    UserBuild[grubDefaultPkg]="${array[@]}"
}

buildGrubDefaultPkg() {
    if [[ ${UserBuild[encryption]} != "-1" ]]; then
        insertGrubDefaultPkg "cryptdevice=${UserBuild[lvmUUID]}:volgroup0"
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
    if [[ "$1" == "" ]]; then 
        echo "Error: input not valid for updateGrubFile"
        exit 1
    fi
    temp=\"${UserBuild[grubDefaultPkg]]}[@]\"
    sed -i -e "s/[[insert]]/$temp/g" bin/grubFile.bin
    UserBuild[grub_file]="$(cat bin/grubFile.bin)"
    UserBuild[grubLock]=1
}

# param: mkinitcpioPkg
updateMkinitcpio() {
    if [[ ${UserBuild[mkinitcpioLock]} != 0 ]]; then 
        echo "Error: mkinitcpio already updated"
        exit 1
    fi
    if [[ $1 == "" ]]; then 
        echo "Error: input not valid for updateMkinitcpio"
        exit 1
    fi
    temp=\"${UserBuild[mkinitcpioHOOKS]}[@]\"
    sed -i -e "s/[[insertHooks]]/$temp/g" bin/grubFile.bin
    temp=\"${UserBuild[mkinitcpioFILES]}[@]\"
    sed -i -e "s/[[insertFiles]]/$temp/g" bin/grubFile.bin
    UserBuild[mkinitcpio_file]="$(cat bin/mkinitcpioFile.bin)"
    UserBuild[mkinitcpioLock]=1
}

updateCrypttab() {
    if [[ ${UserBuild[personalKey]} != "-1" ]]; then
        return
    fi
    if [[ ${UserBuild[crypttabLock]} != 0 ]]; then 
        echo "Error: updateCrypttab already updated"
        exit 1
    fi
    if [[ $1 == "" ]]; then 
        echo "Error: input not valid for updateCrypttab"
        exit 1
    fi
    sed -i -e 's/[[insertName]]/lvm/g' bin/crypttab.bin
    sed -i -e "s/[[insertUUID]]/${UserBuild[lvmUUID]}/g" bin/grubFile.bin
    sed -i -e 's/[[insertName]]/"/secure/securekey.bin"/g' bin/grubFile.bin
    UserBuild[crypttab_file]="$(cat bin/crypttabFile.bin)"
    UserBuild[crypttabLock]=1
}