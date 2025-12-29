function install_sh() {
    echo "Time to cook >:3c"
    sleep 1
    echo "Enjoy the ride in..."
    sleep 1
    for num in 3 2 1 GO!; do
        echo $num
        sleep 1
    done

    if [[ $test != "y" ]]; then
        (
            echo "g" #1
            echo "n" #2
            echo "" #3
            echo "+512M" #4
            echo "Y" #5
            echo "n" #6
            echo "" #7
            echo "" #8
            echo "+1G" #9
            echo "Y" #10
            echo "n" #11
            echo "" #12
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
        ) | fdisk /dev/${UserBuild[disk]}
        if [[ ${UserBuild[encryption]} != "-1" ]]; then 
            cryptsetup luksFormar "/dev/$disk"
        fi
    fi
}