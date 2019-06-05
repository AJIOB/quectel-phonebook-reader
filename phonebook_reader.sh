#!/bin/bash

SCRIPT_ROOT=$(dirname $0)
MODEM_IO_FILE=$1
MODEM_IO_BAUD=$2
SERIAL_TOOL_ROOT="$SCRIPT_ROOT/serial_tool"
SERIAL_TOOL_BIN="$SERIAL_TOOL_ROOT/out/serial_tool"

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

function modem_check {
    local out=`modem_io 1 AT`
    local count_lines=`echo -n out | grep "^OK$" -c`
    if [ "$count_lines" = "0" ]; then
        echo "OK not found. Receiving:"
        echo "$out"
        echo "Exiting..."
        exit 1
    fi
}

make_tool
modem_check
