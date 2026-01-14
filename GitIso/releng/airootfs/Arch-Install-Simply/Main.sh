source src/ChrootManager.sh
source src/ChrootSetup.sh
source src/UserInput.sh

function run() {
    echo "Simple Arch Install"
    echo "Version 2.0 :3"
    echo "-------------------"
    ping Google.com > bin/ping.bin & sleep 1; pkill ping
    wifiConnected=$(cat bin/ping.bin)
    if [[ $wifiConnected == "" ]]; then
        echo "Error: Wifi is disconnected. Use iwctl to connect first"
        exit 1
    fi
    
    # read -p "Enter test mode(y/N)? " test
    setUserInput
    install_sh

    umount -a
    reboot
}
run

#/home/Hazel/Documents/GitHub/Arch-Install-Simply/GitIsoBuild/archlinux-2026.01.02-x86_64.iso