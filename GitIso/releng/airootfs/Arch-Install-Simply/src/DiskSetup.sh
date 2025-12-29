function install_sh() {
    echo "Time to cook >:3c"
    sleep 1
    echo "Enjoy the ride in..."
    sleep 1
    for num in 3 2 1 GO!; do
        echo $num
        sleep 1
    done
    if [[ $test == "y" ]]; then
        for input in "n" "" "+1G" "Y" "n" "" "" "" "+1G" "Y" "n" "" "" "" "Y" "t" "3" "44" "t" "1" "1" "w"; do
                    # 1   2   3    4   5  6  7  8   9    10  11  12 13 14 15  16  17  18   19  20  21  22  
            echo $input
        done 
        # (echo p; echo p ) | fdisk /dev/${UserBuild[disk]}
        # (echo p; echo p ) | fdisk /dev/nvme0n1
    fi
}