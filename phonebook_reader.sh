#!/bin/bash

SCRIPT_ROOT=$(dirname $0)
MODEM_IO_FILE=$1
MODEM_IO_BAUD=$2
MODEM_IO_MODE=$3
SERIAL_TOOL_ROOT="$SCRIPT_ROOT/serial_tool"
SERIAL_TOOL_BIN="$SERIAL_TOOL_ROOT/out/serial_tool"
MODEM_OUT_ENCODING="UCS2"
MODEM_CONTACTS_IN_BLOCK=10
CONTACT_OUT_FILE="out.txt"

function make_tool {
    if [ ! -x "$SERIAL_TOOL_BIN" ]; then
        echo "Tool binary not found. Compile it"
        make -C "$SERIAL_TOOL_ROOT" all
    fi
}

# $1 => timeout
# $2 => command to send
function modem_io {
    $SERIAL_TOOL_BIN $MODEM_IO_FILE $MODEM_IO_BAUD $1 -at $2
}

# $1 => timeout
# $2 => command to send
function modem_run_with_check {
    local out=`modem_io $1 $2`
    local count_lines=`echo -n out | grep "^OK$" -c`
    if [ "$count_lines" = "0" ]; then
        echo "OK not found. Sent message:"
        echo "$2"
        echo "Receiving:"
        echo "$out"
        echo "Exiting..."
        exit 1
    fi

    # Print output if all is good
    echo "$out"
}

function modem_work_check {
    local out=`modem_run_with_check 1 "AT"`
    if [ -n $? ]; then
        echo "$out"
        exit 1
    fi
}

function modem_read_info {
    # Set output encoding
    modem_run_with_check 1 "AT+CSCS=\"$MODEM_OUT_ENCODING\""

    # get count of records
    local out=`modem_run_with_check 1 "AT+CPBS?"`
    if [ -n $? ]; then
        echo "$out"
        exit 1
    fi
    record_num=`echo "$out" | grep "+CPBS" | sed 's/^.*,\([0-9]\+\),.*$/\1/'`
    echo "Used $record_num records"

    # read contacts
    for (( i=1; i<=$record_num; i+=$MODEM_CONTACTS_IN_BLOCK ))
    do
        local out=`modem_run_with_check $(($MODEM_CONTACTS_IN_BLOCK / 2)) "AT+CPBR=$i,$(($i + $MODEM_CONTACTS_IN_BLOCK - 1))"`
        if [ -n $? ]; then
            echo "$out"
            exit 1
        fi

        contacts=`echo "$out" | grep "+CPBR" | sed 's/+CPBR:/AT+CPBW=/'` >> $CONTACT_OUT_FILE
    done
}

function modem_write_info {
    # Set output encoding
    modem_run_with_check 1 "AT+CSCS=\"$MODEM_OUT_ENCODING\""

    # write contacts
    while IFS= read -r line
    do
        local out=`modem_run_with_check 1 "$line"`
        if [ -n $? ]; then
            echo "$out"
            exit 1
        fi
    done < "$CONTACT_OUT_FILE"
}

make_tool
modem_work_check

if [ "read"="$MODEM_IO_MODE" ]; then
    modem_read_info
elif [ "write"="$MODEM_IO_MODE" ]; then
    modem_write_info
fi
