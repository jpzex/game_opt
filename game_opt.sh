# game_opt.sh
# Version 1.0
# 2021-02-24 @ 16:56 (UTC)
# ID: xxx
# Written by jpzex@XDA
# Use at your own risk, Busybox is required.

#set -xv # debug

##### USER SET VARIABLES #####

# Dump mode (0 or 1): log before and after for every value that is getting applied.
dump=0

# Dry run mode (0 or 1): do not change any value, just dump before and after if dump=1.
dryrun=0

##### DO NOT EDIT BELOW THIS LINE #####

# Aggressive optimizations focused
# on improving device performance.

main_opt(){

M2 # sysctl
M3 # LMK
M5 # kernel modules
M6 # interactive governor
M7 # adreno gpu

} # other modules are present on base_opt

scriptname=game_opt

#===================================================#
#===================================================#
#===================================================#

# Module 2: Sysctl Tweaks

M2(){

sys=/proc/sys

kernel_game(){
wr $sys/kernel/random/read_wakeup_threshold 1024
wr $sys/kernel/random/write_wakeup_threshold 1024
}

vm_game(){
wr $sys/vm/dirty_ratio 90
wr $sys/vm/dirty_background_ratio 1
wr $sys/vm/dirty_expire_centisecs 200
wr $sys/vm/dirty_writeback_centisecs 100
wr $sys/vm/min_free_order_shift 5
wr $sys/vm/page-cluster 12
wr $sys/vm/swappiness 20
wr $sys/vm/vfs_cache_pressure 500
}

kernel_game
vm_game

unset sys kernel_game vm_game
}

#===================================================#
#===================================================#
#===================================================#

# Module 3: LMK Tweaks

M3(){

params=/sys/module/lowmemorykiller/parameters
extramb=$(($msize/4096))
tend=$(($msize/102400))

t(){
echo $((($1*$tend*16)+32*$extramb))
}

lmk(){
echo "$(t $1),$(t $2),$(t $3),$(t $4),$(t $5),$(t $6)"
}

wrl $params/minfree $(lmk 0 1 2 5 9 15)
wrl $params/cost 32

unset params extramb tend t lmk 

}

#===================================================#
#===================================================#
#===================================================#

# Module 5: Kernel modules toggles

M5(){

a="/sys/module/workqueue/parameters"

wrl $a/power_efficient N
wrl $a/disable_numa N

a="/sys/module/msm_thermal"

wrl $a/core_control/enabled 0
wrl $a/parameters/enabled N
wrl $a/vdd_restriction/enabled N

a="/sys/module/msm_performance/parameters"

count="$kernel_max"

while [ "$count" -ge "0" ]; do
cpulist+="$count "; ((count-=1))
done

for x in $cpulist; do
list+=" $x:0"; done

wrl $a/cpu_min_freq "$list"
wrl $a/io_enter_cycles 1
wrl $a/io_exit_cycles 1
wrl $a/ip_evt_trig_thr 0

# now to remove msm_perf irrational bottleneck of max_freq

unset list

for x in $cpulist; do
list+=" $x:10000000"; done # maybe 10GHz is enough

wrl $a/cpu_max_freq "$list"

unset a count cpulist x list

}

#===================================================#
#===================================================#
#===================================================#

# Module 6: Adjust interactive CPU governor tunables

M6(){

cpu="/sys/devices/system/cpu"

for x in $cpu/cpu*; do [ -e $x/cpufreq ] && first_cpu=$x && break; done

search $first_cpu/cpufreq/scaling_available_governors interactive

if [ $? ]; then

lastfreq=0
curfreq=0

x=0; until [ $x == $kernel_max ]; do
if [ -e $cpu/cpu$x/cpufreq/cpuinfo_min_freq ]; then
curfreq=$(read $cpu/cpu$x/cpufreq/cpuinfo_min_freq)
[ ! $curfreq == $lastfreq ] && clusters+="$x ";
lastfreq=$curfreq; fi;((x+=1)); done

counter=0

until [ $counter -gt $kernel_max ]; do
list_of_cores="$list_of_cores $counter"; ((counter+=1))
done

# example output for Moto G5 Qualcomm SD 430:
# $clusters=" 0 4" ( 0-3 big / 4-7 little )
# $list_of_cores=" 0 1 2 3 4 5 6 7" (0 to $kernel_max)

tunecpu(){

# This now is a per cluster function.
# It runs <cluster count> times.

freq=$cpu/cpu$1/cpufreq/scaling_available_frequencies

if [ -e $freq ]; then
# get lowest frequency
minf=$(read $freq | awk '{ print $1 }'); fi

# Clear variable in case the device has
# more than 1 cluster (big.LITTLE or more tiers)

unset rev_list

# create a reversed list of this cluster frequencies

for x in $(read $freq); do
rev_list="$x $rev_list"; done

count=0
for x in $(read $freq); do ((count+=1)); done
numfreq=$count

# this creates a variable that equals the quantity of frequencies

for x in $rev_list; do
ef=$preef
preef=$x
[ $count == $(($numfreq-3)) ] && break; done

for x in "$cpu/cpu$1/cpufreq/interactive" "$cpu/cpufreq/interactive"; do [ -e $x ] && gov=$x; done

#wr $gov/above_hispeed_delay "50000 $preef:50000 $ef:50000"
wrl $gov/above_hispeed_delay 20000
wrl $gov/boost 0
wrl $gov/boostpulse_duration 10000
wrl $gov/fast_ramp_down 0
wrl $gov/go_hispeed_load 1
wrl $gov/hispeed_freq $minf
wrl $gov/io_is_busy 0
wrl $gov/input_boost 0
wrl $gov/min_sample_time 100000 #80000
wrl $gov/timer_rate 100000 #20000
wrl $gov/timer_slack 30000
wrl $gov/use_sched_load 0
wrl $gov/target_loads "1 $minf:75 $preef:80";
}

for x in $clusters; do wrl $cpu/cpu$x/cpufreq/scaling_governor interactive; tunecpu $x; done; fi

unset cpu x first_cpu lastfreq curfreq clusters counter list_of_cores freq minf rev_list ef preef gov

}


#===================================================#
#===================================================#
#===================================================#

# Module 7: Adjust Adreno gpu settings

M7(){

sys=/sys/class/kgsl/kgsl-3d0
if [ -e $sys ]; then
wrl $sys/default_pwrlevel 0
wrl $sys/min_pwrlevel 0
wrl $sys/max_pwrlevel 0
fi
unset sys min


}

#===================================================#
#===================================================#
#===================================================#

prep(){

np=/dev/null

which busybox > $np

[ $? != 0 ] && echo "No busybox found, please install it first. If you just installed, a reboot may be necessary." && exit 1

alias_list="mountpoint awk echo grep chmod fstrim cat mount uniq date"

for x in $alias_list; do
    alias $x="busybox $x";
done

} # end prep

vars(){

# Get max cpu num kernel_max

kernel_max=$(cat /sys/devices/system/cpu/kernel_max)

# Get RAM size in KB 
msize=$(cat /proc/meminfo | grep "MemTotal" | awk '{ print $2 }')

read(){ [ -e $1 ] && cat $1; }

search(){ read $2 | grep $1 > $np ; }

# search <string> <file>
# searches for string in file if it exists and returns
# just an error code, 0 (true) for "string found" or 
# 1 (false) for "not found". Does not print.

#=DUMP=AND=DRY=RUN=START============================#

if [ $dryrun == 0 ]; then
have="have"

wr(){
[ -e $1 ] && $(echo -e $2 > $1 ||\
echo "$1 write error.")
}

wrl(){
[ -e $1 ] && chmod 666 $1 &&\
echo $2 > $1 && chmod 444 $1
}

else
have="have not"
wr(){
[ -e $1 ] && echo -e "$2 > $1" 
}

wrl(){
wr $1 $2
}

fi

if [ $dump == 1 ]; then
    dpath=/data/$scriptname
    for x in $dpath*; do
        [ -e $x ] && rm $x
    done
    dpath="$dpath-$(date +%Y-%m-%d).txt"
    echo "The dump file is located in: $dpath. The values $have been applied, according to the config on the start of the script."

    wr(){
    if [ $dump == 1 ]; then
        if [ -e $1 ]; then
            echo -e "WR - A: $1 = $(cat $1)\nWR - B: $1 = $2\n" >> $dpath
            [ $dryrun == 0 ] && $(echo -e $2 > $1 || echo "$1 write error.");
        fi
     fi
}

    wrl(){
    if [ $dump == 1 ]; then
        if [ -e $1 ]; then
            echo -e "WRL - A: $1 = $(cat $1)\nWRL - B: $1 = $2\n" >> $dpath
             [ $dryrun == 0 ] && chmod 666 $1 && echo $2 > $1 && chmod 444 $1
        fi
    fi
}

fi # end dump

#=DUMP=AND=DRY=RUN=END==============================#

} # end vars

marker="/data/lastrun_$scriptname"

if [ $dryrun == 0 ]; then touch $marker; echo $(date) > $marker; fi
unset marker

prep && vars && main_opt
#if [ -z $dumpinfo ]; then echo $dumpinfo; fi

unset main_opt scriptname alias_list kernel_max msize apply dump dryrun dpath wr wrl read search dumpinfo have np