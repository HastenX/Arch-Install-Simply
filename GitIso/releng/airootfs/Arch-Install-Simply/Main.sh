source src/ChrootManager.sh
source src/DiskSetup.sh
source src/UserInput.sh

function run() {
    echo "Simple Arch Install"
    echo "Version 2.0 :3"
    echo "-------------------"
    
    read -p "Enter test mode(y/n)? " test
    # setUserInput
    install_sh
}
run