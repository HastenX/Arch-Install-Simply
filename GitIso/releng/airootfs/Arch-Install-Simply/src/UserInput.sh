source src/UserBuild.sh
function setUserInput() {
    # echo "File controller: ${UserBuild[grubDefaultPkg]}"
    ensureMachine
    ensureDisk
    ensureUsername
    ensurePasswordData
    ensureEncryption
    ensureUI

    # Testing data:
    for key in "${!UserBuild[@]}"
    do
        echo "'$key' : '${UserBuild[$key]}'"
        read -p "Wait: " w
    done

    # Updates after user data is retrieved
    updateMkinitcpio
    
}

function ensureMachine() {
    echo "--------------------------------------------------------------"
    echo "Ensure Machine Type:"
    read -p "Please enter the environment you're installing this in:(u=usb,v=virtual,s=ssd/drive) " machineType

    case $machineType in
        "u")
            setMachineType "usb"
            ;;
        "v")
            setMachineType "virtual"
            ;;
        "s")
            setMachineType "ssd"
            ;;
        *)
            echo "Error: please enter only u, v or s"
            ensureMachine
            return
            ;;
    esac

    echo "Machine: ${UserBuild[machineType]}"
    read -p "Are you sure this is the correct machine type? (YES/n): " verify
    if [[ $verify != "YES" ]]; then
        ensureMachine
        return
    fi
}

function ensureDisk() {
    echo "--------------------------------------------------------------"
    echo "Ensure Disk:"
    lsblk
    read -p "Please enter the hard drive you would like to format: " disk
    setDisk $disk
    if [[ $(lsblk | grep -i ${UserBuild[disk]}) == "" || $(partprobe -d -s /dev/${UserBuild[disk]} | grep "gpt") == "" ]]; then
        echo "Disk does not exist or doesn't have gpt format"
        ensureDisk
        return
    fi

    echo p | fdisk /dev/${UserBuild[disk]}
    read -p "Is this disk correct? (YES/n): " verify
    if [[ $verify != "YES" ]]; then
        ensureDisk
        return
    fi
}



function ensureUsername() {
    echo "--------------------------------------------------------------"
    echo "Ensure Username:"
    read -p "Please enter your username: " username
    if [[ -z "$username" ]]; then
        echo "Error: Please enter a valid username"
        ensureUsername
    else 
        setUsername "$username"
    fi

}

function ensurePasswordData() {
    passwdTemplate "username"
    passwdTemplate "rootname"
}

function passwdTemplate() {
    echo "--------------------------------------------------------------"
    echo "Ensure Passwords:"
    read -sp "Please enter your password for ${UserBuild[$1]}: " passwd
    echo ""
    read -sp "Please verify your password for ${UserBuild[$1]}: " verify
    echo ""
    if [[ "$verify" != "$passwd" ||  -z "$passwd" ]]; then
        echo "Error: password's don't match or null password"
        passwordTemplate "$1"
    else
        case "$1" in 
            "rootname")
                setUserPasswd "$passwd"
                ;;
            "username")
                setRootPasswd "$passwd"
                ;;
            *)
                echo "Error: You coded passwdTemplate wrong :c"
                exit 1
                ;;
        esac
    fi
}

function ensureEncryption() {
    echo "--------------------------------------------------------------"
    echo "Ensure Encryption:"
    read -p "Would you like LUKS encryption? (y/N): " verify
    if [[ $verify == "y" ]]; then
        insertModprobePkg "dm_crypt"
        setEncryption "y"
        insertMkinitcpioHOOKS "encrypt"
        read -p "Would you like to use crypttab? (y/N): " verify
        if [[ $verify != "y" ]]; then
            keyTemplate
            setPersonalKey ${UserBuild[personalKey]}
        fi
    fi
    buildMkinitcpioFILES
}

function keyTemplate() {
    read -sp "Please enter your passphrase: " passphrase
    echo ""
    read -sp "Please veify your passphrase: " verify
    echo ""
    if [[ $passphrase != $verify || -z $passphrase ]]; then
        echo "Error: password's don't match or null password"
        keyTemplate
    else 
        setPersonalKey "$passphrase"
    fi

}

function ensureUI() {
    echo "--------------------------------------------------------------"
    echo "Ensure UI: "
    ensureDesktop
    ensureDisplayManager
    ensureBrowser
    ensureConsole
    ensureFileManager
} 

function ensureDesktop() {
    read -p "Please enter the wanted desktop (gnome=g,kde=k,hyprland=h,none=n): " desktop
    case "$desktop" in 
        "g")
            setDesktop "gnome"
            ;;
        "k")
            setDesktop "kde"
            ;;
        "h")
            setDesktop "hyprland"
            ;;
        "n")
            setDesktop "none"
            ;;
        *)
            echo "Error: please enter a desktop letter"
            ensureDesktop
            ;;
    esac
    
}

function ensureDisplayManager() {
    read -p "Please enter the wanted Display Manager (SDDM=s,GDM=g,none=n): " displayManager
    case "$displayManager" in 
        "g")
            setDisplsyManager "gdm"
            ;;
        "s")
            setDisplsyManager "sddm"
            ;;
        "n")
            setDisplsyManager "none"
            ;;
        *)
            echo "Error: please enter a display letter"
            ensureDisplayManager
            ;;
    esac
    
}

function ensureBrowser() {
    read -p "Please enter the wanted browser (chrome=c,firefox=f,librewolf=l,none=n): " desktop
    case "$desktop" in 
        "c")
            setBrowser "google-chrome"
            ;;
        "f")
            setBrowser "firefox-bin"
            ;;
        "l")
            setBrowser "librewolf-bin"
            ;;
        "n")
            ;;
        *)
            echo "Error: please enter a browser letter"
            ensureBrowser
            ;;
    esac
}

function ensureConsole() {
    read -p "Please enter the wanted console (kitty=k,gnome-shell=g,terminator=t): " desktop
    case "$desktop" in 
        "k")
            setConsole "kitty"
            ;;
        "g")
            setConsole "gnome-shell"
            ;;
        "t")
            setConsole "terminator"
            ;;
        *)
            echo "Error: please enter a console letter"
            ensureConsole
            ;;
    esac
}

function ensureFileManager() {
    read -p "Please enter the wanted file manager (dolphin=d,nautilus=na,krusader=k,none=no): " desktop
    case "$desktop" in 
        "k")
            setFileManager "krusader"
            ;;
        "d")
            setFileManager "dolphin"
            ;;
        "na")
            setFileManager "nautilus"
            ;;
        "no")
            setFileManager "none"
            ;;
        *)
            echo "Error: please enter a file manager letter"
            ensureFileManager
            ;;
    esac
}