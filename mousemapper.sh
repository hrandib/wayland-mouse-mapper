#!/bin/bash

event_type=EV_KEY
action_type=POINTER_BUTTON
pressed="pressed,"

readarray -t devices <<<$(libinput list-devices | grep pointer -B3 | grep -o '/dev/input/event[1-9]*')
target=$(libinput list-devices | grep [Kk]eyboard -A1 | grep -m1 -o 'event[1-9]*')

echo "$target is selected for sending events"

# COMMANDS MAP
BTN_EXTRA=(KEY_LEFTCTRL KEY_TAB)
BTN_SIDE=(KEY_LEFTCTRL KEY_LEFTSHIFT KEY_TAB)
BTN_FORWARD=(KEY_LEFTCTRL KEY_W)

function pressKey(){
    device=$target; key=$2; value=$3
    echo "pressing ${key} ${value}"
    evemu-event /dev/input/${device} --sync --type ${event_type} --code ${key} --value ${value}
}

function pressCommand(){
    device=$1; button=$2; movement=$3
    var=$button[@]
    command=${!var}
    if [ ${movement} = ${pressed} ]; then
        for key in ${command}; do
            pressKey ${device} ${key} 1
        done
    else
        for key in ${command}; do
            pressKey ${device} ${key} 0
        done | tac
    fi
}

function parseEventLine(){
    device=$1
    action=$2
    button=$4
    movement=$6

    # compute only if right action
    if [ ${action} = ${action_type} ]; then
        pressCommand ${device} ${button} ${movement}
    fi
}

function mapDevice(){
    device=$1
    while read line; do
        parseEventLine ${line}
    done < <(stdbuf -oL libinput debug-events --device ${device} & )
}

for device in ${devices[@]}; do
    ( mapDevice ${device} ) &
done

wait